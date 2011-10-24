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
#include <sys/select.h>

/* JSON server headers */
#include "json-config.h"
#include "json-net.h"
#include "json-call.h"
#include "json-private.h"

/*
 * Get the JSON server instance.
 */
static JSON_Server *
json_server_info(void)
{
	static int init = 0;
	static JSON_Server info;

	if (!init) {
		info.fd = -1;
		init = 1;
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
	JSON_Server *const info = json_server_info();

	/* TODO: Preserve server across reboots? */
	json_server_stop(info);
}

/*
 * Sets the input file descriptor.
 */
void
json_server_setfd(fd_set *input_set)
{
	JSON_Server *const info = json_server_info();

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
	JSON_Server *const info = json_server_info();

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
	JSON_Server *const info = json_server_info();

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
	JSON_Server *const info = json_server_info();

	/* Restrict to wizards using Hard coded permission check. */
	if (!Wizard(executor)) {
		safe_str(T(e_perm), buff, bp);
		return;
	}

	/* Ensure the server is started. */
	json_server_start(info);
	if (info->fd == -1) {
		safe_str(T("#-1 CONNETION FAILED"), buff, bp);
		return;
	}

	/* Send request. */

	/* Return response. */

	safe_format(buff, bp, "Not implemented yet: %s", args[0]);
}

/*
 * Dispatches recursive call from JSON server to MUSHcode.
 */
