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
#include "case.h"
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

/* Internal error message. */
#define ERROR_INTERNAL T("#-1 INTERNAL ERROR")

/* Handy macro for getting context. */
#define GET_INFO_VAR JSON_Server_Context *const info = json_server_info()

/* Handy macro for trying a protocol operation. All errors are fatal. */
#define TRY_PROTO(op) do { if (!(op)) goto failed; } while (0)

/* System request prefix. */
#define JSON_SYS_PREFIX "rpc."
#define JSON_SYS_PREFIX_LEN 4

/* Asynchronous solicitation request. */
#define JSON_SYS_ASYNC_REQ "rpc.req"

/*
 * Macro to copy an execution context frame. Multiply evaluates.
 *
 * TODO: If copying overhead becomes significant, may want to consider using a
 * flag to implement a lazy copying strategy. Allocation should still occur
 * from the stack, since that's still faster than trying to malloc() lazily.
 */
#define COPY_CONTEXT_FRAME(d,s) \
	do { \
		(d).pe_info = (s).pe_info; \
	\
		(d).executor = (s).executor; \
		(d).caller = (s).caller; \
		(d).enactor = (s).enactor; \
	} while (0)

/*
 * Context parameters.
 *
 * TODO: May want to define these properties in a table instead.
 */
#define CONTEXT_KEY_EXECUTOR "executor"
#define CONTEXT_KLEN_EXECUTOR 8

#define CONTEXT_KEY_CALLER "caller"
#define CONTEXT_KLEN_CALLER 6

#define CONTEXT_KEY_ENACTOR "enactor"
#define CONTEXT_KLEN_ENACTOR 7

/* Execution context frame. */
typedef struct JSON_Server_Frame_tag {
	NEW_PE_INFO *pe_info; /* NEW_PE_INFO structure */

	dbref executor; /* the executor */
	dbref caller; /* the caller */
	dbref enactor; /* the enactor */
} JSON_Server_Frame;

/* Execution context. */
typedef struct JSON_Server_Context_tag {
	JSON_Server server; /* connection state */
	JSON_Server_Frame current; /* current context frame */

	/* Additional PennMUSH-specific state. */
	int depth; /* call depth */
	int soliciting; /* pending solicitation request */
} JSON_Server_Context;

/* Sends the PennMUSH context frame in the current request. */
static int json_server_send_penn_context(JSON_Server *server,
                                         JSON_Server_Frame *frame);

/* Receives and dispatches incoming messages. */
static int json_server_dispatch(JSON_Server_Message *msg);

/* Dispatches request message. */
static int json_server_dispatch_request(JSON_Server_Message *msg);

/* Calls a PennMUSH function. */
static int json_server_penn_call(JSON_Server_Message *msg);

/*
 * Get the JSON server instance.
 */
static JSON_Server_Context *
json_server_info(void)
{
	static int init = 0;
	static JSON_Server_Context info;

	if (!init) {
		init = 1;

		info.server.fd = -1;
	}

	return &info;
}

/*
 * Starts the JSON server instance. Also resets PennMUSH-specific state.
 */
static int
json_server_penn_start(void)
{
	GET_INFO_VAR;

	/* Check if the server is already started. */
	if (info->server.fd != -1) {
		return 1;
	}

	/* Start the server. */
	json_server_start(&info->server);
	if (info->server.fd == -1) {
		return 0;
	}

	/* Initialize PennMUSH-specific state. */
	info->depth = 0;
	info->soliciting = 0;

	return 1;
}

/*
 * Stops the JSON server instance. Also releases PennMUSH-specific state.
 */
static void
json_server_penn_stop(void)
{
	GET_INFO_VAR;

	/* Check if the server is already stopped. */
	if (info->server.fd == -1) {
		return;
	}

	/* Stop the server. */
	json_server_stop(&info->server);
}

/*
 * Receives incoming solicitation message.
 */
static int
json_server_receive_solicit(void)
{
	GET_INFO_VAR;

	JSON_Server_Message msg;

	/* Receive message. */
	json_server_message_init(&msg);

	if (!json_server_receive(&info->server, &msg)) {
		return 0;
	}

	/* Dispatch asynchronous solicitation requests only. */
	switch (msg.type) {
	case JSON_SERVER_MSG_REQUEST:
		if (strcmp(JSON_SYS_ASYNC_REQ, msg.message) == 0) {
			if (!info->soliciting) {
				/* All solicitation conditions satisfied. */
				info->soliciting = 1;
				json_server_message_clear(&msg);
				return 1;
			}
		}
		break;

	default:
		break;
	}

	json_server_message_clear(&msg);
	return 0;
}

/*
 * Executes an asynchronous callback.
 */
static int
json_server_execute_callback(void)
{
	GET_INFO_VAR;

	JSON_Server_Message msg;
	int result;

	/* Initialize first context frame. */
	info->current.pe_info = make_pe_info("json");
	if (!info->current.pe_info) {
		/* Note that make_pe_info() doesn't check NULL; for shame. */
		return 0;
	}

	info->current.executor = JSON_SERVER_CALLBACK_EXECUTOR;
	info->current.caller = JSON_SERVER_CALLBACK_EXECUTOR;
	info->current.enactor = JSON_SERVER_CALLBACK_EXECUTOR;

	/* Send solicitation acknowledgment. */
	TRY_PROTO(json_server_start_request(&info->server, "rpc.ack", 7));

	if (!json_server_send_penn_context(&info->server, &info->current)) {
		goto failed;
	}

	TRY_PROTO(json_server_send_request(&info->server));

	/* Dispatch response. Callback responses are ignored. */
	info->depth++; /* TODO: check recursion depth */
	json_server_message_init(&msg);
	result = json_server_dispatch(&msg);
	info->depth--;

	if (!result) {
		goto failed;
	}

	json_server_message_clear(&msg);

	/* Release first context frame. */
	free_pe_info(info->current.pe_info);
	info->current.pe_info = NULL; /* for safety only */
	return 1;

failed:
	/* Release first context frame. */
	free_pe_info(info->current.pe_info);
	info->current.pe_info = NULL; /* for safety only */
	return 0;
}

/*
 * Simple error logging facility.
 */
void
json_server_log(JSON_Server *server, const char *message, int code)
{
	/* Log error. */
	if (code) {
		fprintf(stderr, "JSON server[%d]: %s: %s\n",
		        server->fd, message, strerror(code));
	} else {
		fprintf(stderr, "JSON server[%d]: %s\n",
		        server->fd, message);
	}
}

/*
 * Shuts down JSON sever.
 */
void
json_server_shutdown(int reboot)
{
	/* TODO: Preserve server across reboots? */
	json_server_penn_stop();
}

/*
 * Sets the input file descriptor.
 */
void
json_server_setfd(int *maxd, fd_set *input_set)
{
	GET_INFO_VAR;

	if (info->server.fd == -1) {
		return;
	}

	/* Drain buffered asynchronous message. */
	if (info->server.in_off != info->server.in_len) {
		if (!json_server_receive_solicit()) {
			goto failed;
		}
	}

	/* Transmit pending asynchronous acknowledgement. */
	if (info->soliciting) {
		info->soliciting = 0;

		if (!json_server_execute_callback()) {
			goto failed;
		}
	}

	/* Configure socket for select. */
	if (*maxd <= info->server.fd) {
		*maxd = info->server.fd + 1;
	}

	FD_SET(info->server.fd, input_set);
	return;

failed:
	/* Recover from protocol failure. */
	json_server_penn_stop();
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

	if (info->server.fd == -1 || !FD_ISSET(info->server.fd, input_set)) {
		return;
	}

	/* Receive asynchronous message. */
	if (!json_server_receive_solicit()) {
		goto failed;
	}

	return;

failed:
	/* Recover from protocol failure. */
	json_server_penn_stop();
}

/*
 * Administrative command.
 *
 * arg_left: (subcommand) (subcommand arguments)
 */
COMMAND(cmd_json_rpc)
{
	const char *subcmd = arg_left;

	if (!*subcmd) {
		/* Report usage information. */
		notify(executor, "RPC: Commands: STATUS START STOP");
	} else if (strcasecmp(subcmd, "STATUS") == 0) {
		/* Report status information. */
		GET_INFO_VAR;

		if (info->server.fd == -1) {
			notify(executor, "RPC: Disconnected.");
		} else {
			notify(executor, "RPC: Connected.");
		}
	} else if (strcasecmp(subcmd, "START") == 0) {
		/* Start the JSON server instance. */
		notify(executor, "RPC: Starting.");
		json_server_penn_start();
	} else if (strcasecmp(subcmd, "STOP") == 0) {
		/* Stop the JSON server instance. */
		notify(executor, "RPC: Stopping.");
		json_server_penn_stop();
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

	JSON_Server_Frame old_frame;
	JSON_Server_Message msg;
	int ii, result;

	/* Restrict to wizards using hard coded permission check. */
	if (!Wizard(executor)) {
		safe_str(T(e_perm), buff, bp);
		return;
	}

	/* Deny attempts to invoke system functions directly. */
	/* TODO: args[0] is always terminated, right? */
	if (strncmp(args[0], JSON_SYS_PREFIX, JSON_SYS_PREFIX_LEN) == 0) {
		safe_str(T(e_perm), buff, bp);
		return;
	}

	/* Ensure the server is started. */
	if (!json_server_penn_start()) {
		safe_str(ERROR_COMM_FAILURE, buff, bp);
		return;
	}

	/* Save call state. */
	COPY_CONTEXT_FRAME(old_frame, info->current);

	/* Send request. */
	TRY_PROTO(json_server_start_request(&info->server,
	                                    args[0], arglens[0]));

	for (ii = 1; ii < nargs; ii++) {
		TRY_PROTO(json_server_add_param(&info->server,
	                                        args[ii], arglens[ii]));
	}

	info->current.pe_info = pe_info;
	info->current.executor = executor;
	info->current.caller = caller;
	info->current.enactor = enactor;

	if (!json_server_send_penn_context(&info->server, &info->current)) {
		goto failed;
	}

	TRY_PROTO(json_server_send_request(&info->server));

	/* Dispatch response. */
	info->depth++; /* TODO: check recursion depth */
	json_server_message_init(&msg);
	result = json_server_dispatch(&msg);
	info->depth--;

	if (!result) {
		goto failed;
	}

	if (msg.local_error) {
		/* Report local error. */
		json_server_message_clear(&msg);
		safe_str(ERROR_INTERNAL, buff, bp);
		goto success;
	}

	switch (msg.type) {
	case JSON_SERVER_MSG_RESULT:
		/* Report result response. */
		if (msg.message) {
			safe_str(msg.message, buff, bp);
		}
		break;

	case JSON_SERVER_MSG_ERROR:
		/* Report error response. */
		safe_format(buff, bp, T("#-1 %ld|%s"),
		            msg.error_code, msg.message);
		break;

	default:
		/* This shouldn't happen. */
		json_server_message_clear(&msg);
		goto failed;
	}

	json_server_message_clear(&msg);
	goto success;

failed:
	/* Recover from protocol failure. */
	json_server_penn_stop();
	safe_str(ERROR_COMM_FAILURE, buff, bp);

	/* FALLTHROUGH */
success:
	/* Restore call state. */
	COPY_CONTEXT_FRAME(info->current, old_frame);
}

/*
 * Sends the PennMUSH context in the current request.
 */
static int
json_server_send_penn_context(JSON_Server *server, JSON_Server_Frame *frame)
{
	TRY_PROTO(json_server_add_context(server, "executor", 8,
	                                  unparse_dbref(frame->executor), -1));

	TRY_PROTO(json_server_add_context(server, "caller", 6,
	                                  unparse_dbref(frame->caller), -1));

	TRY_PROTO(json_server_add_context(server, "enactor", 7,
	                                  unparse_dbref(frame->enactor), -1));

	return 1;

failed:
	return 0;
}

/*
 * Receives and dispatches incoming messages.
 */
static int
json_server_dispatch(JSON_Server_Message *msg)
{
	GET_INFO_VAR;

	for (;;) {
		if (!json_server_receive(&info->server, msg)) {
			return 0;
		}

		switch (msg->type) {
		case JSON_SERVER_MSG_REQUEST:
			/* Dispatch recursive request. */
			if (!json_server_dispatch_request(msg)) {
				goto failed;
			}
			break;

		default:
			/* Return response. */
			return 1;
		}

		json_server_message_clear(msg);
	}

failed:
	json_server_message_clear(msg);
	return 0;
}

/*
 * Dispatches request message. This method should not be used to dispatch at
 * depth 0, in which only the JSON_SYS_ASYNC_REQ message is allowed.
 */
static int
json_server_dispatch_request(JSON_Server_Message *msg)
{
	GET_INFO_VAR;

	int result;

	/*
	 * Apologize to caller, we broke.
	 *
	 * TODO: It's conceivable we could have a local error while receiving a
	 * JSON_SYS_ASYNC_REQ message, which should never be responded to. This
	 * is very unlikely, and will probably usually result in a protocol
	 * error, but it's something to keep in mind. If we're really worried
	 * about it, we can change json_server_receive() to never fail for this
	 * particular message, but it doesn't really seem worth it.
	 */
	if (msg->local_error) {
		return json_server_send_error(&info->server, msg->local_error,
		                              ERROR_INTERNAL, -1);
	}

	/* TODO: Check recursion depth. */

	/* Dispatch PennMUSH requests. Note that msg->message is terminated. */
	if (strncmp(msg->message, JSON_SYS_PREFIX, JSON_SYS_PREFIX_LEN) != 0) {
		info->depth++;
		result = json_server_penn_call(msg);
		info->depth--;

		return result;
	}

	/* Dispatch asynchronous solicitation. */
	if (strcmp(JSON_SYS_ASYNC_REQ, msg->message) == 0) {
		if (!info->soliciting) {
			/* All solicitation conditions satisfied. */
			info->soliciting = 1;
			return 1;
		}
	}

	/* No such method. */
	return json_server_send_error(&info->server, JSON_SERVER_ERROR_METHOD,
	                              T("#-1 SYSTEM FUNCTION NOT FOUND"), -1);
}

/*
 * Calls a PennMUSH soft code function in response to an incoming request. This
 * code is based on parse.c:process_expression(), specifically the lines around
 * the func_hash_lookup() call.
 */
static int
json_server_penn_call(JSON_Server_Message *msg)
{
	static char name[BUFFER_LEN];

	char buff[BUFFER_LEN], *buffp, **bp;
	char *sp, *tp;

	FUN *fp;
	int tmp;

	GET_INFO_VAR;

	/* Prepare result buffer. */
	buffp = buff;
	bp = &buffp;

	/* Find the function. Note that msg->message is terminated. */
	tp = name;

	for (sp = msg->message; *sp; sp++) {
		safe_chr(UPCASE(*sp), name, &tp);
	}

	*tp = '\0';

	fp = builtin_func_hash_lookup(name);
	if (!fp) {
		/* Function was not found. */
		safe_format(buff, bp, T("#-1 FUNCTION (%s) NOT FOUND"), name);
		return json_server_send_error(&info->server,
		                              JSON_SERVER_ERROR_METHOD,
		                              buff, buffp - buff);
	}

	/* Check that the number of arguments is valid. */
	tmp = (fp->maxargs < 0) ? -fp->maxargs : fp->maxargs;
	if (msg->param_nargs < fp->minargs || tmp < msg->param_nargs) {
		safe_format(buff, bp,
		            T("#-1 FUNCTION (%s) EXPECTS %d TO %d ARGUMENTS"),
		            fp->name, fp->minargs, tmp);
		return json_server_send_error(&info->server,
		                              JSON_SERVER_ERROR_PARAMS,
		                              buff, buffp - buff);
	}

	/* Call the function. Note that we skipped a lot of safety checks! */
	fp->where.fun(fp, buff, bp,
	              msg->param_nargs, msg->param_args, msg->param_arglens,
	              info->current.executor, info->current.caller,
	              info->current.enactor, fp->name, info->current.pe_info,
	              PE_DEFAULT);

	/* Return the result. */
	if (buffp == buff) {
		return json_server_send_result(&info->server, NULL, -1);
	} else {
		return json_server_send_result(&info->server,
		                               buff, buffp - buff);
	}
}

/*
 * Updates context parameters. Note that the previous context parameter values
 * are saved, so we do not need to do any special recovery for fatal errors.
 */
int
json_server_context_callback(const char *key, int klen,
                             const char *value, int vlen)
{
	/* TODO: Implement context callback. */
	/*fprintf(stderr, "DEBUG(%.*s=%.*s)\n", klen, key, vlen, value);*/
	return 1;
}
