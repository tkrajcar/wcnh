/* PennMUSH headers. */
#include "copyrite.h"
#include "config.h"
#include <string.h>
#include "conf.h"
#include "externs.h"

/* System headers. */
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <errno.h>
#include <stddef.h>

/* JSON server headers. */
#include "json-config.h"
#include "json-private.h"

/* Handy macro for handling optional string lengths. Multiple evaluates. */
#define OPT_STRLEN(s,l) ((l) < 0 ? strlen((s)) : (size_t)(l))

/* Handy macro for getting context. */
#define GET_INFO_VAR JSON_Server *const info = (JSON_Server *)ctx

/* Handy macro for trying a JSON generation operation. All errors are fatal. */
#define TRY_GEN(op) \
	do { if ((op) != yajl_gen_status_ok) goto failed; } while (0)

/* Handy macro for writing JSON string. Multiple evaluates. */
#define TRY_GEN_STR(s,l) \
	TRY_GEN(yajl_gen_string(info->encoder, (const unsigned char *)(s), \
	                        OPT_STRLEN((s), (l))))

/*
 * Handy macro for trying a JSON parse operation. All errors are fatal. Note
 * that due to infinite streaming hack, any status other than
 * yajl_status_insufficient_data is considered an error.
 */
#define TRY_PARSE(s,l) \
	do { \
		if (yajl_parse(info->decoder, (const unsigned char *)(s), (l)) \
		    != yajl_status_insufficient_data) { \
			goto failed; \
		} \
	} while (0)

/* YAJL generator configuration. */
static const yajl_gen_config gen_config = {
	0, /* don't beautify */
	"" /* indentation string; not used without beautify */
};

/* YAJL parser configuration. */
static const yajl_parser_config parser_config = {
	0, /* don't accept comments */
	1 /* reject invalid UTF-8 */
};

typedef const char *const Token_Table[];

/* Unknown response token table. */
static Token_Table tok_tab_0 = {
#define TOKEN_0_RESULT 0
	"result",
#define TOKEN_0_METHOD 1
	"method",
#define TOKEN_0_PARAMS 2
	"params",
#define TOKEN_0_CONTEXT 3
	"context",
#define TOKEN_0_ERROR 4
	"error",

	NULL
};

/* Error response token table. */
static Token_Table tok_tab_error = {
#define TOKEN_ERROR_CODE 0
	"code",
#define TOKEN_ERROR_MESSAGE 1
	"message",

	NULL
};

/* Transmits buffered JSON while blocking. */
static int flush_json(JSON_Server *info);

/* Transitions message object to the given type. */
static int message_set_type(JSON_Server_Message *msg,
                            JSON_Server_Message_Type type);

/*
 * Recognizes a token from a table. Tokens should be sorted roughly in order of
 * expected frequency, since we currently use a linear search. Future
 * implementations could try to be more clever and use automata or a hash.
 */
static int
find_token(Token_Table table, const unsigned char *key, unsigned int len)
{
	int ii;

	for (ii = 0; table[ii]; ii++) {
		if (strncmp(table[ii], (const char *)key, len) == 0) {
			return ii;
		}
	}

	return -1;
}

static int
handle_null(void *ctx)
{
	GET_INFO_VAR;

	switch (info->state) {
	case JSON_SERVER_STATE_IGNORING:
		/* Ignore value within ignored container. */
		break;

	case JSON_SERVER_STATE_OBJECT:
		/* Ignore unknown key-value within message object. */
		switch (info->msg_token) {
		case -1:
			break;

		case TOKEN_0_RESULT:
			/* FIXME: Yes, not robust. Just prototyping. */
			info->msg->type = JSON_SERVER_MSG_RESULT;
			info->msg->message = NULL;
			break;

		default:
			return 0;
		}
		break;

	default:
		/* Unexpected value. */
		return 0;
	}

	return 1;
}

static int
handle_boolean(void *ctx, int value)
{
	GET_INFO_VAR;

	switch (info->state) {
	case JSON_SERVER_STATE_IGNORING:
		/* Ignore value within ignored container. */
		break;

	case JSON_SERVER_STATE_OBJECT:
		/* Ignore unknown key-value within message object. */
		if (info->msg_token != -1) {
			return 0;
		}
		break;

	default:
		/* Unexpected value. */
		return 0;
	}

	return 1;
}

static int
handle_integer(void *ctx, long int value)
{
	GET_INFO_VAR;

	switch (info->state) {
	default:
		/* Unexpected parser state. */
		return 0;
	}

	return 1;
}

static int
handle_double(void *ctx, double value)
{
	GET_INFO_VAR;

	return 1;
}

static int
handle_string(void *ctx, const unsigned char *value, unsigned int len)
{
	GET_INFO_VAR;

	switch (info->state) {
	case JSON_SERVER_STATE_OBJECT:
		if (info->msg_token == TOKEN_0_RESULT) {
			/* FIXME: Yes, not robust. Just prototyping. */
			info->msg->type = JSON_SERVER_MSG_RESULT;
			info->msg->message = mush_strndup((const char *)value, len, "json");
		}
		break;

	default:
		/* Unexpected parser state. */
		return 0;
	}

	return 1;
}

static int
handle_start_map(void *ctx)
{
	GET_INFO_VAR;

	++info->msg_nesting;

	switch (info->state) {
	case JSON_SERVER_STATE_WAITING:
		if (info->msg_nesting == 1) {
			/* Entered message object. */
			info->state = JSON_SERVER_STATE_OBJECT;
		}
		break;

	case JSON_SERVER_STATE_OBJECT:
		if (info->msg_nesting == 2) {
			switch (info->msg_token) {
			case TOKEN_0_RESULT:
				break;
			}
		} else {
			/* Deeper nesting of ignored object. */
		}

		if (info->msg_token == 0) {
		}
		break;

	default:
		/* Unexpected parser state. */
		return 0;
	}

	return 1;
}

static int
handle_map_key(void *ctx, const unsigned char *key, unsigned int len)
{
	GET_INFO_VAR;

	switch (info->state) {
	case JSON_SERVER_STATE_OBJECT:
		/* Message object key. */
		info->msg_token = find_token(tok_tab_0, key, len);
		break;

	case JSON_SERVER_STATE_CONTEXT:
		/* TODO: Save context parameters. */
		break;

	case JSON_SERVER_STATE_IGNORING:
		/* Ignored object key. */
		break;

	default:
		/* Not allowed in this state. */
		return 0;
	}

	return 1;
}

static int
handle_end_map(void *ctx)
{
	GET_INFO_VAR;

	--info->msg_nesting;

	switch (info->state) {
	case JSON_SERVER_STATE_OBJECT:
		/* End of message object. */
		info->state = JSON_SERVER_STATE_READY;
		break;

	case JSON_SERVER_STATE_IGNORING:
		/* End of ignored object? */
		if (info->msg_nesting == info->restore_nesting) {
			info->state = info->restore_state;
		}
		break;

	default:
		/* Unexpected parser state. */
		return 0;
	}

	return 1;
}

static int
handle_start_array(void *ctx)
{
	GET_INFO_VAR;

	++info->msg_nesting;

	return 1;
}

static int
handle_end_array(void *ctx)
{
	GET_INFO_VAR;

	--info->msg_nesting;

	switch (info->state) {
	case JSON_SERVER_STATE_IGNORING:
		/* End of ignored object? */
		if (info->msg_nesting == info->restore_nesting) {
			info->state = info->restore_state;
		}
		break;

	default:
		/* Unexpected parser state. */
		return 0;
	}

	return 1;
}

static const yajl_callbacks callbacks = {
	handle_null, /* yajl_null */
	handle_boolean, /* yajl_boolean */
	handle_integer, /* yajl_integer */
	handle_double, /* yajl_double */
	NULL, /* yajl_number */
	handle_string, /* yajl_string */
	handle_start_map, /* yajl_start_map */
	handle_map_key, /* yajl_map_key */
	handle_end_map, /* yajl_end_map */
	handle_start_array, /* yajl_start_array */
	handle_end_array /* yajl_end_array */
};

/*
 * Allocate JSON encoder/decoder.
 */
int
json_server_json_alloc(JSON_Server *info)
{
	JSON_Server_State old_state;

	info->encoder = yajl_gen_alloc(&gen_config, NULL);
	if (!info->encoder) {
		json_server_log(info, "json_alloc: yajl_gen_alloc", 0);
		return 0;
	}

	info->decoder = yajl_alloc(&callbacks, &parser_config, NULL, info);
	if (!info->decoder) {
		/* Not fatal, but will prevent operation. */
		json_server_log(info, "json_alloc: yajl_alloc", 0);
		yajl_gen_free(info->encoder);
		info->decoder = NULL;
		return 0;
	}

	/*
	 * Hack to allow YAJL to generate/parse a stream of JSON documents.
	 * Normally, YAJL only allows a single JSON document, but we add an
	 * invisible [ to the beginning to stream a sequence.
	 *
	 * Note that this hack requires spurious commas, so we insert an
	 * initial null and skip/add leading commas as needed.
	 */
	TRY_GEN(yajl_gen_array_open(info->encoder));
	TRY_GEN(yajl_gen_null(info->encoder));
	yajl_gen_clear(info->encoder);

	old_state = info->state;
	info->state = JSON_SERVER_STATE_IGNORING;
	TRY_PARSE("[null", 5);
	info->msg_nesting--; /* reverse handle_start_array */
	info->state = old_state;

	return 1;

failed:
	json_server_log(info, "json_alloc: yajl", 0);
	json_server_json_free(info);
	return 0;
}

/*
 * Deallocate JSON encoder/decoder.
 */
void
json_server_json_free(JSON_Server *info)
{
	if (info->encoder) {
		yajl_gen_free(info->encoder);
		info->encoder = NULL;
	}

	if (info->decoder) {
		yajl_free(info->decoder);
		info->decoder = NULL;
	}
}

/*
 * Starts request.
 */
int
json_server_start_request(JSON_Server *info, const char *method, int len)
{
	switch (info->state) {
	case JSON_SERVER_STATE_READY:
		/* GENERATE: {"method":method[len] */
		TRY_GEN(yajl_gen_map_open(info->encoder));
		TRY_GEN_STR("method", 6);
		TRY_GEN_STR(method, len);

		info->state = JSON_SERVER_STATE_REQ;
		break;

	default:
		json_server_log(info, "start_request: invalid state", 0);
		return 0;
	}

	return 1;

failed:
	json_server_log(info, "start_request: yajl_gen", 0);
	return 0;
}

/*
 * Adds positional parameter to current request.
 */
int
json_server_add_param(JSON_Server *info, const char *value, int len)
{
	switch (info->state) {
	case JSON_SERVER_STATE_REQ:
		/* GENERATE: "param":[ */
		TRY_GEN_STR("params", 6);
		TRY_GEN(yajl_gen_array_open(info->encoder));

		info->state = JSON_SERVER_STATE_REQ_ARGS;
		/* FALLTHROUGH */
	case JSON_SERVER_STATE_REQ_ARGS:
		/* GENERATE: value[len] */
		TRY_GEN_STR(value, len);
		break;

	default:
		json_server_log(info, "add_param: invalid state", 0);
		return 0;
	}

	return 1;

failed:
	json_server_log(info, "add_param: yajl_gen", 0);
	return 0;
}

/*
 * Adds context parameter to current request.
 */
int
json_server_add_context(JSON_Server *info, const char *key, int klen,
                        const char *value, int vlen)
{
	switch (info->state) {
	case JSON_SERVER_STATE_REQ_ARGS:
		/* GENERATE: ] */
		TRY_GEN(yajl_gen_array_close(info->encoder));

		/* FALLTHROUGH */
	case JSON_SERVER_STATE_REQ:
		/* GENERATE: "context":{ */
		TRY_GEN_STR("context", 7);
		TRY_GEN(yajl_gen_map_open(info->encoder));

		info->state = JSON_SERVER_STATE_REQ_CTX;
		/* FALLTHROUGH */
	case JSON_SERVER_STATE_REQ_CTX:
		/* GENERATE: key:value */
		TRY_GEN_STR(key, klen);
		TRY_GEN_STR(value, vlen);
		break;

	default:
		json_server_log(info, "add_context: invalid state", 0);
		return 0;
	}

	return 1;

failed:
	json_server_log(info, "add_context: yajl_gen", 0);
	return 0;
}

/*
 * Sends complete request.
 */
int
json_server_send_request(JSON_Server *info)
{
	switch (info->state) {
	case JSON_SERVER_STATE_REQ:
		/* GENERATE: */
		break;

	case JSON_SERVER_STATE_REQ_ARGS:
		/* GENERATE: ] */
		TRY_GEN(yajl_gen_array_close(info->encoder));
		break;

	case JSON_SERVER_STATE_REQ_CTX:
		/* GENERATE: } */
		TRY_GEN(yajl_gen_map_close(info->encoder));
		break;

	default:
		json_server_log(info, "send_request: invalid state", 0);
		return 0;
	}

	/* GENERATE: } */
	TRY_GEN(yajl_gen_map_close(info->encoder));

	/* Transmit complete request. Block until complete. */
	if (!flush_json(info)) {
		return 0;
	}

	info->state = JSON_SERVER_STATE_WAITING;
	return 1;

failed:
	json_server_log(info, "send_request: yajl_gen", 0);
	return 0;
}

/*
 * Sends result. The result may be NULL.
 */
int
json_server_send_result(JSON_Server *info, const char *result, int len)
{
	if (info->state != JSON_SERVER_STATE_READY) {
		json_server_log(info, "send_result: invalid state", 0);
		return 0;
	}

	/* GENERATE: {"result": */
	TRY_GEN(yajl_gen_map_open(info->encoder));
	TRY_GEN_STR("result", 6);

	if (result) {
		/* GENERATE: result[len] */
		TRY_GEN_STR(result, len);
	} else {
		/* GENERATE: null */
		TRY_GEN(yajl_gen_null(info->encoder));
	}

	/* GENERATE: } */
	TRY_GEN(yajl_gen_map_close(info->encoder));

	/* Transmit result. Block until complete. */
	if (!flush_json(info)) {
		return 0;
	}

	info->state = JSON_SERVER_STATE_WAITING;
	return 1;

failed:
	json_server_log(info, "send_result: yajl_gen", 0);
	return 0;
}

/*
 * Sends error.
 */
int
json_server_send_error(JSON_Server *info, long int code, const char *error,
                       int len)
{
	if (info->state != JSON_SERVER_STATE_READY) {
		json_server_log(info, "send_error: invalid state", 0);
		return 0;
	}

	/* GENERATE: {"error":{"code":code,"message":error[len]}} */
	TRY_GEN(yajl_gen_map_open(info->encoder));
	TRY_GEN_STR("error", 5);

	TRY_GEN(yajl_gen_map_open(info->encoder));
	TRY_GEN_STR("code", 4);
	TRY_GEN(yajl_gen_integer(info->encoder, code));

	TRY_GEN_STR("message", 7);
	TRY_GEN_STR(error, len);
	TRY_GEN(yajl_gen_map_close(info->encoder));

	TRY_GEN(yajl_gen_map_close(info->encoder));

	/* Transmit error. Block until complete. */
	if (!flush_json(info)) {
		return 0;
	}

	info->state = JSON_SERVER_STATE_WAITING;
	return 1;

failed:
	json_server_log(info, "send_error: yajl_gen", 0);
	return 0;
}

/*
 * Clears message, releasing any allocated memory.
 */
void
json_server_message_clear(JSON_Server_Message *msg)
{
	switch (msg->type) {
	case JSON_SERVER_MSG_NONE:
		/* Unused message. */
		break;

	case JSON_SERVER_MSG_REQUEST:
		/* Request message. */
		if (msg->param_args) {
			int ii, nargs;

			nargs = msg->param_nargs;
			for (ii = 0; ii < nargs; ii++) {
				mush_free(msg->param_args[ii], "json");
			}

			mush_free(msg->param_args, "json");
			mush_free(msg->param_arglens, "json");
		}

		/* FALLTHROUGH */
	case JSON_SERVER_MSG_RESULT:
	case JSON_SERVER_MSG_ERROR:
		/* Response message. */
		if (msg->message) {
			mush_free(msg->message, "json");
		}

		msg->type = JSON_SERVER_MSG_NONE;
		break;

	default:
		/* Invalid type. */
		break;
	}
}

/*
 * Receives next message. Due to the structure of the PennJSON protocol, we
 * must receive one complete JSON message before continuing. (We may also
 * receive up to one asynchronous polling request message.)
 */
int
json_server_receive(JSON_Server *info, JSON_Server_Message *msg)
{
	unsigned int remaining;

	ssize_t result;
	yajl_status status;

	if (info->state != JSON_SERVER_STATE_WAITING) {
		/* TODO: Except when handling async poll request? */
		return 0;
	}

	info->msg = msg;
	info->msg_nesting = 0;
	info->msg_token = -1;

	/* Parse virtual comma for streaming hack. */
	TRY_PARSE(",", 1);

	do {
		if (info->in_off == info->in_len) {
			/* Fill buffer. */
			if ((result = read(info->fd, info->in_buf,
			                   JSON_SERVER_BUFFER_SIZE)) == -1) {
				json_server_log(info, "receive: read", errno);
				goto failed;
			}

			if (result == 0) {
				json_server_log(info, "receive: closed", 0);
				goto failed;
			}

			info->in_off = 0;
			info->in_len = result;
		}

		/* Parse from buffer. */
		TRY_PARSE(info->in_buf + info->in_off,
		          info->in_len - info->in_off);

		info->in_off += yajl_get_bytes_consumed(info->decoder);
	} while (info->state != JSON_SERVER_STATE_READY);

	return 1;

failed:
	json_server_message_clear(msg);
	return 0;
}

/*
 * Flushes buffered JSON. Due to the structure of the PennJSON protocl, we must
 * send one complete JSON message before continuing. (We could have transmitted
 * incrementally, but messages we send are unlikely to make that worthwhile.)
 */
static int
flush_json(JSON_Server *info)
{
	const unsigned char *buf;
	unsigned int len;

	ssize_t result;

	TRY_GEN(yajl_gen_get_buf(info->encoder, &buf, &len));

	/*
	 * Our infinite stream hack (see json_server_json_alloc) introduces a
	 * spurious comma that we need to skip.
	 */
	buf += 1;
	len -= 1;

	while (len > 0) {
		if ((result = write(info->fd, buf, len)) == -1) {
			json_server_log(info, "flush_json: write", errno);
			return 0;
		}

		buf += result;
		len -= result;
	}

	yajl_gen_clear(info->encoder);
	return 1;

failed:
	json_server_log(info, "flush_json: yajl_gen", 0);
	return 0;
}

/*
 * Initializes a message object to the given type.
 */
static int
message_set_type(JSON_Server_Message *msg, JSON_Server_Message_Type type)
{
	if (msg->type == type) {
		/* Message is already that type. */
		return 1;
	} else if (msg->type != JSON_SERVER_MSG_NONE) {
		/* Cannot change message type. */
		return 0;
	}

	/* Clear the old message. */
	json_server_message_clear(msg);

	/* Initialize the new message. */
	msg->type = type;

	switch (type) {
	case JSON_SERVER_MSG_NONE:
		/* No initialization required. */
		break;

	case JSON_SERVER_MSG_REQUEST:
		/* Reset parameters. */
		msg->message = NULL;
		msg->param_size = 0;

	case JSON_SERVER_MSG_RESULT:
		msg->error_code = 0;
		break;

	case JSON_SERVER_MSG_ERROR:
	default:
		msg->message = NULL;
		break;
	}
}
