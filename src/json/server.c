/* PennMUSH headers */
#include "copyrite.h"
#include "config.h"
#include <string.h>
#include "conf.h"
#include "externs.h"
#include "parse.h"
#include "confmagic.h"
#include "command.h"
#include "function.h"
#include "log.h"

/* System headers. */
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>

/* JSON server headers */
#include "json-config.h"
#include "json-net.h"
#include "json-call.h"
#include "json-private.h"

/* Communication failure error message. */
#define ERROR_COMM_FAILURE T("#-1 COMMUNICATION FAILURE")

/* Handy macro for getting context. */
#define GET_INFO_VAR JSON_Server *const info = json_server_info()

/* Handy macro for trying a protocol operation. All errors are fatal. */
#define TRY_PROTO(op) do { if (!(op)) goto failed; } while (0)

/*
 * Get the JSON server instance.
 */
static JSON_Server *
json_server_info(void)
{
	static int init = 0;
	static JSON_Server info;

	if (!init) {
		init = 1;

		info.fd = -1;
	}

	return &info;
}

/*
 * Simple error logging facility.
 */
void
json_server_log(JSON_Server *info, const char *message, int code)
{
	/* Log error. */
	if (code) {
		fprintf(stderr, "JSON server[%d]: %s: %s\n",
		        info->fd, message, strerror(code));
	} else {
		fprintf(stderr, "JSON server[%d]: %s\n",
		        info->fd, message);
	}
}

/*
 * Shuts down JSON sever.
 */
void
json_server_shutdown(int reboot)
{
	GET_INFO_VAR;

	/* TODO: Preserve server across reboots? */
	json_server_stop(info);
}

/*
 * Sets the input file descriptor.
 */
void
json_server_setfd(fd_set *input_set)
{
	GET_INFO_VAR;

	if (info->fd == -1) {
		return;
	}

	FD_SET(info->fd, input_set);
}

/*
 * Processes the input file descriptor if selected.
 *
 * Note that this method is only called from the event loop.
 */
void
json_server_issetfd(fd_set *input_set)
{
	GET_INFO_VAR;

	if (info->fd == -1) {
		return;
	}

	if (FD_ISSET(info->fd, input_set)) {
		/* TODO: Dispatch incoming request. */
		ssize_t len;

		len = recv(info->fd, info->in_buf, sizeof(info->in_buf), 0);
		if (len < 1) {
			json_server_stop(info);
		}
	}
}

/*
 * Administrative command.
 *
 * arg_left: (subcommand) (subcommand arguments)
 */
COMMAND(cmd_json_rpc)
{
	GET_INFO_VAR;

	const char *subcmd = arg_left;

	if (!*subcmd) {
		/* Report usage information. */
		notify(executor, "RPC: Commands: STATUS START STOP");
	} else if (strcasecmp(subcmd, "STATUS") == 0) {
		/* Report status information. */
		if (info->fd == -1) {
			notify(executor, "RPC: Disconnected.");
		} else {
			notify(executor, "RPC: Connected.");
		}
	} else if (strcasecmp(subcmd, "START") == 0) {
		/* Start the JSON server instance. */
		notify(executor, "RPC: Starting.");
		json_server_start(info);
	} else if (strcasecmp(subcmd, "STOP") == 0) {
		/* Stop the JSON server instance. */
		notify(executor, "RPC: Stopping.");
		json_server_stop(info);
	} else {
		/* Unknown command. */
		notify_format(executor, "RPC: Unknown command: %s", subcmd);
	}
}

/*
 * Initiates call from MUSHcode to JSON server.
 *
 * args[0]: function identifier
 * args[1 .. (nargs - 1)]: function arguments
 */
FUNCTION(fun_json_rpc)
{
	GET_INFO_VAR;

	JSON_Server_Message msg;
	int ii;

	/* Restrict to wizards using Hard coded permission check. */
	if (!Wizard(executor)) {
		safe_str(T(e_perm), buff, bp);
		return;
	}

	/* Ensure the server is started. */
	json_server_start(info);
	if (info->fd == -1) {
		safe_str(ERROR_COMM_FAILURE, buff, bp);
		return;
	}

	/* Send request. */
	TRY_PROTO(json_server_start_request(info, args[0], arglens[0]));

	for (ii = 1; ii < nargs; ii++) {
		TRY_PROTO(json_server_add_param(info, args[ii], arglens[ii]));
	}

	TRY_PROTO(json_server_add_context(info, "executor", 8, "#3", -1));
	TRY_PROTO(json_server_add_context(info, "caller", 6, "#2", -1));
	TRY_PROTO(json_server_add_context(info, "enactor", 7, "#1", -1));

	TRY_PROTO(json_server_send_request(info));

	/* Dispatch response. */
	msg.type = JSON_SERVER_MSG_NONE;

	if (!json_server_receive(info, &msg)) {
		goto failed;
	}

	switch (msg.type) {
	case JSON_SERVER_MSG_REQUEST:
		/* TODO: Handle recursive requests. */
		json_server_message_clear(&msg);
		goto failed;

	case JSON_SERVER_MSG_RESULT:
		if (msg.message) {
			safe_str(msg.message, buff, bp);
		}
		break;

	case JSON_SERVER_MSG_ERROR:
		safe_format(buff, bp, T("#-1 %ld (%s)"),
		            msg.error_code, msg.message);
		break;

	default:
		/* This shouldn't happen. */
		json_server_message_clear(&msg);
		goto failed;
	}

	json_server_message_clear(&msg);
	return;

failed:
	/* Recover from protocol failure. */
	json_server_stop(info);
	safe_str(ERROR_COMM_FAILURE, buff, bp);
}

/*
 * Dispatches recursive call from JSON server to MUSHcode.
 */
/* TODO: Not implemented yet. */
