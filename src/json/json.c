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

/* Initial items array allocation. Must be a power of 2. */
#define JSON_ITEMS_INITIAL 16

/* Initial data buffer allocation. Must be a power of 2. */
#define JSON_DATA_INITIAL 65536

/* Value returned by alloc_json_string() to indicate a failed allocation. */
#define JSON_ALLOC_FAILED ((size_t)-1)

/* Logging macro. */
#define JSON_LOG(msg) (json_server_log(server, (msg), 0))

/* Logging macro using errno. */
#define JSON_LOG_ERRNO(msg) (json_server_log(server, (msg), errno))

/* Wrapper macro for malloc. */
#define JSON_MALLOC(t,s) ((t *)mush_malloc((s), "json"))

/* Wrapper macro for malloc of a single item of a type. */
#define JSON_MALLOC_1(t) (JSON_MALLOC(t, sizeof(t)))

/* Wrapper macro for malloc of multiple items of a type. */
#define JSON_MALLOC_N(t,n) (JSON_MALLOC(t, (n) * sizeof(t)))

/* Wrapper macro for realloc of multiple items of a type. */
#define JSON_REALLOC_N(t,p,n) ((t *)mush_realloc((p), (n) * sizeof(t), "json"))

/* Wrapper macro for free. */
#define JSON_FREE(p) (mush_free((p), "json"))

/* Handy macro for handling optional string lengths. Multiple evaluates. */
#define OPT_STRLEN(s,l) ((l) < 0 ? strlen((s)) : (size_t)(l))

/* Handy macro for getting context. */
#define GET_SERVER_VAR JSON_Server *const server = (JSON_Server *)ctx

/* Handy macro for getting allocation pool from server. */
#define GET_SERVER_POOL(s) ((JSON_Server_Alloc_Pool *)(s)->internal)

/* Handy macro for getting allocator from message. */
#define GET_MESSAGE_ALLOC(m) ((JSON_Server_Alloc *)(m)->internal)

/* Handy macro to convert a pointer into an item offset. */
#define GET_ALLOC_OFF(s) ((s) - alloc->data)

/* Handy macro to convert an item offset into a pointer. */
#define GET_ALLOC_PTR(i) (alloc->data + (i))

/* Handy macro for trying a JSON generation operation. All errors are fatal. */
#define TRY_GEN(op) \
	do { if ((op) != yajl_gen_status_ok) goto failed; } while (0)

/* Handy macro for writing JSON string. Multiple evaluates. */
#define TRY_GEN_STR(s,l) \
	TRY_GEN(yajl_gen_string(server->encoder, \
	                        (const unsigned char *)(s), \
	                        OPT_STRLEN((s), (l))))

/*
 * Handy macro for trying a JSON parse operation. All errors are fatal. Note
 * that due to infinite streaming hack, any status other than
 * yajl_status_insufficient_data is considered an error.
 */
#define TRY_PARSE(s,l) \
	do { \
		if (yajl_parse(server->decoder, \
		               (const unsigned char *)(s), (l)) \
		    != yajl_status_insufficient_data) { \
			goto failed; \
		} \
	} while (0)

/* Handy macro for safely setting message type. */
#define PARSER_SET_TYPE(t) \
	do { \
		if (!parser_mark(server, (t))) { \
			return 0; \
		} \
	} while (0)

/* Handy macro for safely setting part of message type. */
#define PARSER_SET_TYPE_PART(t,p) \
	do { \
		if (!parser_mark_part(server, (t), (p))) { \
			return 0; \
		} \
	} while (0)

/* Tests whether is missing. */
#define HAS_PART(p) (server->parts_seen[(p)])

/* Handy macro to raise a local error. */
#define PARSER_RAISE_LOCAL \
	do { \
		server->msg->local_error = JSON_SERVER_ERROR_INTERNAL; \
	} while (0)

/*
 * Handy macro for skipping work if in a local error state. Parsing should
 * proceed normally when in a local error state, in order to catch fatal
 * errors, but the result will ultimately be thrown away, so guard any costly
 * optional work with this macro.
 */
#define PARSER_CHECK_LOCAL \
	do { \
		if (server->msg->local_error) { \
			return 1; \
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
static Token_Table tok_tab_root = {
#define TOKEN_RESULT 0
	"result",
#define TOKEN_METHOD 1
	"method",
#define TOKEN_PARAMS 2
	"params",
#define TOKEN_CONTEXT 3
	"context",
#define TOKEN_ERROR 4
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

/*
 * Internal allocator. These are pooled and reused to avoid reallocating memory
 * for every method invocation. Memory will only be fully released when the
 * conversation server stops, so be careful about using large parameters or
 * deep levels of recursion.
 *
 * Note that if json_server_stop() is called before all messages are cleared,
 *
 * TODO: Consider enforcing resource limits.
 * TODO: Consider releasing memory earlier based on hysteresis.
 */
typedef struct JSON_Server_Alloc_tag {
  int capacity; /* allocated size (in elements) */
  int size; /* occupied size (in elements) */

  char **items; /* array of strings pointers into data; realloc invalidates */
  size_t *itemoffs; /* array of string offsets into data */
  int *itemlens; /* array of string lengths */

  size_t data_capacity; /* allocated data size (in char) */
  size_t data_size; /* occupied data size (in char) */
  char *data; /* string data */

  struct JSON_Server_Alloc_tag *next; /* next allocator */
  struct JSON_Server_Alloc_Pool_tag *pool; /* owning pool */
} JSON_Server_Alloc;

/*
 * Internal allocator pool. Internal allocators cannot be released if they have
 * been assigned to message objects that have not yet been cleared, so the
 * internal allocator pool manages the internal allocators separately from the
 * server instance.
 */
typedef struct JSON_Server_Alloc_Pool_tag {
  int refs; /* reference count; does not include freed allocators */

  JSON_Server_Alloc *available; /* free allocator list */
} JSON_Server_Alloc_Pool;

/* Transmits buffered JSON while blocking. */
static int flush_json(JSON_Server *server);

/*
 * Allocates an allocator for the current message.
 */
static JSON_Server_Alloc *
alloc_json_alloc(JSON_Server *server)
{
	JSON_Server_Alloc_Pool *pool;
	JSON_Server_Alloc *alloc;

	/* Check if the current message already has an allocator. */
	if (server->msg->internal) {
		return GET_MESSAGE_ALLOC(server->msg);
	}

	/* Create the pool, if necessary. */
	if (server->internal) {
		pool = GET_SERVER_POOL(server);
	} else {
		pool = JSON_MALLOC_1(JSON_Server_Alloc_Pool);
		if (!pool) {
			return NULL;
		}

		pool->refs = 1;
		pool->available = NULL;

		server->internal = pool;
	}

	/* Get the allocator, using one from the pool if available. */
	if (pool->available) {
		alloc = pool->available;
		pool->available = alloc->next;
	} else {
		alloc = JSON_MALLOC_1(JSON_Server_Alloc);
		if (!alloc) {
			/* Note that we don't need to release the pool. */
			return NULL;
		}

		alloc->items = JSON_MALLOC_N(char *, JSON_ITEMS_INITIAL);
		if (!alloc->items) {
			JSON_FREE(alloc);
			return NULL;
		}

		alloc->itemoffs = JSON_MALLOC_N(size_t, JSON_ITEMS_INITIAL);
		if (!alloc->itemoffs) {
			JSON_FREE(alloc->items);
			JSON_FREE(alloc);
			return NULL;
		}

		alloc->itemlens = JSON_MALLOC_N(int, JSON_ITEMS_INITIAL);
		if (!alloc->itemlens) {
			JSON_FREE(alloc->itemoffs);
			JSON_FREE(alloc->items);
			JSON_FREE(alloc);
			return NULL;
		}

		alloc->data = JSON_MALLOC_N(char, JSON_DATA_INITIAL);
		if (!alloc->data) {
			JSON_FREE(alloc->itemlens);
			JSON_FREE(alloc->itemoffs);
			JSON_FREE(alloc->items);
			JSON_FREE(alloc);
			return NULL;
		}

		alloc->capacity = JSON_ITEMS_INITIAL;
		alloc->data_capacity = JSON_DATA_INITIAL;
		alloc->pool = pool;
	}

	alloc->size = 0;
	alloc->data_size = 0;
	alloc->next = NULL;

	++pool->refs;

	server->msg->internal = alloc;
	return alloc;
}

/*
 * Adds a string to the allocator. Returns an offset into the data buffer,
 * rather than a pointer, since the data buffer can be reallocated at any time.
 * Returns JSON_ALLOC_FAILED if the allocation fails.
 */
static size_t
alloc_json_string(JSON_Server_Alloc *alloc, const unsigned char *str, int len)
{
	char *cp;

	int capacity = alloc->data_capacity;
	int size = alloc->data_size + len + 1;

	/* Expand the data buffer if necessary. */
	/* TODO: Consider cache-friendly alignment. */
	if (size > capacity) {
		char *data;

		while (size > capacity) {
			capacity <<= 1; /* hopefully we won't wrap around */
		}

		data = JSON_REALLOC_N(char, alloc->data, capacity);
		if (data) {
			alloc->data = data;
		} else {
			return JSON_ALLOC_FAILED;
		}

		alloc->data_capacity = capacity;
	}

	/* Add the string. */
	cp = alloc->data + alloc->data_size;
	alloc->data_size = size;

	memcpy(cp, str, len);
	cp[len] = '\0';

	return GET_ALLOC_OFF(cp);
}

/*
 * Adds an item string to the allocator. Returns an offset into the data
 * buffer, rather than a pointer, since the data buffer can be reallocated at
 * any time. Returns JSON_ALLOC_FAILED if the allocation fails.
 */
static size_t
alloc_json_item_string(JSON_Server_Alloc *alloc,
                       const unsigned char *str, int len)
{
	size_t itemoff;

	int capacity = alloc->capacity;
	int size = alloc->size + 1;

	/* Expand the items arrays if necessary. */
	if (size > capacity) {
		char **items;
		size_t *itemoffs;
		int *itemlens;

		capacity <<= 1; /* hopefully we won't wrap around */

		items = JSON_REALLOC_N(char *, alloc->items, capacity);
		if (items) {
			alloc->items = items;
		} else {
			return JSON_ALLOC_FAILED;
		}

		itemoffs = JSON_REALLOC_N(size_t, alloc->itemoffs, capacity);
		if (itemoffs) {
			alloc->itemoffs = itemoffs;
		} else {
			/* No need to shrink items back. */
			return JSON_ALLOC_FAILED;
		}

		itemlens = JSON_REALLOC_N(int, alloc->itemlens, capacity);
		if (itemlens) {
			alloc->itemlens = itemlens;
		} else {
			/* No need to shrink items or itemoffs back. */
			return JSON_ALLOC_FAILED;
		}

		alloc->capacity = capacity;
	}

	/* Add the item. */
	itemoff = alloc_json_string(alloc, str, len);
	if (itemoff == JSON_ALLOC_FAILED) {
		return JSON_ALLOC_FAILED;
	}

	size = alloc->size++;
	/* only fix up items pointers at the end */
	alloc->itemoffs[size] = itemoff;
	alloc->itemlens[size] = len;

	return itemoff;
}

/*
 * Releases a reference on the allocator pool.
 */
static void
release_json_pool(JSON_Server_Alloc_Pool *pool)
{
	JSON_Server_Alloc *tmp, *next;

	if (--pool->refs > 0) {
		return;
	}

	/* Release allocators. */
	next = pool->available;
	while (next) {
		tmp = next;
		next = tmp->next;

		JSON_FREE(tmp->items);
		JSON_FREE(tmp->itemoffs);
		JSON_FREE(tmp->itemlens);
		JSON_FREE(tmp->data);
		JSON_FREE(tmp);
	}

	/* Release pool. */
	JSON_FREE(pool);
}

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

/*
 * YAJL won't parse more than one document; a new YAJL parser has to be created
 * to parse each document. To get around this, we implemented the "infinite
 * stream" hack. However, this requires that we identify the end of each
 * message object in advance, so we can insert a comma before YAJL can scan the
 * next object.
 *
 * TODO: We may want to replace YAJL with our own lexer, or bundle YAJL so we
 * can take advantage of its lexer. JSON isn't a very complicated format, and
 * we have simple needs.
 */
static void
lexer_prescan(JSON_Server *server)
{
	unsigned char *cp, *endp;
	int ctx, depth;

	if (server->in_off < server->lex_off) {
		/* Current JSON message hasn't been consumed yet. */
		return;
	}

	/* Restore lexer state. */
	ctx = server->lex_ctx;
	depth = server->lex_depth;

	/*
	 * Continue lexing JSON message. We will make the assumption that the
	 * input is well-formed; the parser will catch and report a fatal error
	 * if it is not.
	 */
	endp = server->in_buf + server->in_len;

	for (cp = server->in_buf + server->lex_off; cp != endp; cp++) {
		switch (ctx) {
		case 0:
			/* In raw text. */
			switch (*cp) {
			case '{':
				depth++;
				break;

			case '}':
				if (--depth == 0) {
					++cp;
					goto done;
				}
				break;

			case '"':
				ctx = '"';
				break;
			}
			break;

		case '"':
			/* Inside quoted string. */
			switch (*cp) {
			case '"':
				ctx = 0;
				break;

			case '\\':
				ctx = '\\';
				break;
			}
			break;

		case '\\':
			/* Following escape in string. */
			ctx = '"';
			break;
		}
	}

done:
	/* Save lexer state. */
	server->lex_off = cp - server->in_buf;
	server->lex_ctx = ctx;
	server->lex_depth = depth;
}

/*
 * Marks a message part as parsed for messages with only a single part. This
 * helps detect malformed messages.
 *
 * This check is likely to be a bit conservative, since we parse everything as
 * if every distinct key can be parsed in a unique way. In theory, how a key is
 * parsed could depend on other keys, but we're not going to do that.
 */
static int
parser_mark(JSON_Server *server, JSON_Server_Message_Type type)
{
	if (server->msg->type == JSON_SERVER_MSG_NONE) {
		/* Message does not have an existing type. */
		server->msg->type = type;
		return 1;
	} else {
		/* Message already has a type. */
		return 0;
	}
}

/*
 * Marks a message part as parsed. This helps detect malformed messages.
 *
 * This check is likely to be a bit conservative, since we parse everything as
 * if every distinct key can be parsed in a unique way. In theory, how a key is
 * parsed could depend on other keys, but we're not going to do that.
 */
static int
parser_mark_part(JSON_Server *server, JSON_Server_Message_Type type, int part)
{
	/* Check if message types are compatible. */
	if (parser_mark(server, type)) {
		/* Message does not have an existing type. */
		int ii;

		for (ii = 0; ii < JSON_SERVER_MAX_PARSE_PARTS; ii++) {
			server->parts_seen[ii] = 0;
		}
	} else if (server->msg->type != type || server->parts_seen[part]) {
		/* Existing message type is incompatible. */
		return 0;
	}

	/* Mark the message part. */
	server->parts_seen[part] = 1;
	return 1;
}

/*
 * Sets the message body.
 */
static int
parser_set_message(JSON_Server *server, const unsigned char *message, int len)
{
	JSON_Server_Alloc *alloc;

	PARSER_CHECK_LOCAL;

	alloc = alloc_json_alloc(server);
	if (alloc) {
		server->msg->int_off = alloc_json_string(alloc, message, len);
		if (server->msg->int_off != JSON_ALLOC_FAILED) {
			return 1;
		}
	}

	PARSER_RAISE_LOCAL;
	return 1;
}

/*
 * Sets a context parameter.
 */
static int
parser_set_context(JSON_Server *server, const unsigned char *value, int len)
{
	PARSER_CHECK_LOCAL;

	if (server->key_len == -1) {
		/* Ignore excessively long key. */
		return 1;
	}

	switch (json_server_context_callback(server->key_buf, server->key_len,
	                                     (const char *)value, len)) {
	case 1:
		/* Success. */
		return 1;

	case -1:
		/* Non-fatal error. */
		PARSER_RAISE_LOCAL;
		return 1;

	default:
		/* Fatal error. */
		return 0;
	}
}

/*
 * Parses a value using default rules.
 */
static int
parse_value(JSON_Server *server)
{
	switch (server->state) {
	case JSON_SERVER_STATE_COMPOSITE:
		/* Ignoring unknown composite value component. */
		break;

	case JSON_SERVER_STATE_MESSAGE:
		switch (server->key_idx) {
		case -1:
			/* Ignore value of unknown key. */
			break;

		case TOKEN_RESULT:
			/* Unsupported type. */
			PARSER_RAISE_LOCAL;
			break;

		default:
			/* Type not allowed here. */
			return 0;
		}
		break;

	case JSON_SERVER_STATE_PARAMS:
		/* Unsupported type. */
		PARSER_RAISE_LOCAL;
		break;

	case JSON_SERVER_STATE_CONTEXT:
		/* Invoke context parameter callback. */
		if (!parser_set_context(server, NULL, -2)) {
			PARSER_RAISE_LOCAL;
		}
		break;

	case JSON_SERVER_STATE_ERROR:
		switch (server->key_idx) {
		case -1:
			/* Ignore value of unknown key. */
			break;

		default:
			/* Type not allowed here. */
			return 0;
		}
		break;

	default:
		/* Unexpected parser state. */
		return 0;
	}

	return 1;
}

/*
 * Parses entry into a composite value using default rules.
 */
static int
parse_enter(JSON_Server *server)
{
	/* Check if a composite value would even be allowed. */
	if (!parse_value(server)) {
		return 0;
	}

	/* Start ignoring. */
	if (server->state == JSON_SERVER_STATE_COMPOSITE) {
		++server->nesting_depth;
	} else {
		server->saved_state = server->state;
		server->state = JSON_SERVER_STATE_COMPOSITE;
	}

	return 1;
}

/*
 * Parses exit from a composite value using default rules.
 */
static int
parse_exit(JSON_Server *server)
{
	switch (server->state) {
	case JSON_SERVER_STATE_COMPOSITE:
		/* Stop ignoring. */
		if (server->nesting_depth) {
			--server->nesting_depth;
		} else {
			server->state = server->saved_state;
		}
		break;

	default:
		/* Unexpected parser state. */
		return 0;
	}

	return 1;
}

/*
 * Parses a "null". Currently, "null" is meaningful as a "result", and as a
 * "context" parameter.
 */
static int
handle_null(void *ctx)
{
	GET_SERVER_VAR;

	switch (server->state) {
	case JSON_SERVER_STATE_MESSAGE:
		switch (server->key_idx) {
		case TOKEN_RESULT:
			/* Results are allowed to be null. */
			PARSER_SET_TYPE(JSON_SERVER_MSG_RESULT);
			server->msg->int_off = JSON_ALLOC_FAILED;
			return 1;
		}
		break;

	case JSON_SERVER_STATE_CONTEXT:
		/* Invoke context parameter callback. */
		return parser_set_context(server, NULL, -1);

	default:
		break;
	}

	/* Fall back to default value parsing rules. */
	return parse_value(server);
}

/*
 * Parses a "true" or "false". Currently not supported.
 */
static int
handle_boolean(void *ctx, int value)
{
	GET_SERVER_VAR;

	/* Fall back to default value parsing rules. */
	return parse_value(server);
}

/*
 * Parses an integer number. Currently, integers are only meaningful for the
 * "code" of an error response.
 */
static int
handle_integer(void *ctx, long int value)
{
	GET_SERVER_VAR;

	switch (server->state) {
	case JSON_SERVER_STATE_ERROR:
		switch (server->key_idx) {
		case TOKEN_ERROR_CODE:
			/* Error codes must be integers. */
			PARSER_SET_TYPE_PART(JSON_SERVER_MSG_ERROR, 1);
			server->msg->error_code = value;
			return 1;
		}
		break;

	default:
		break;
	}

	/* Fall back to default value parsing rules. */
	return parse_value(server);
}

/*
 * Parses a floating point number. Currently not supported.
 */
static int
handle_double(void *ctx, double value)
{
	GET_SERVER_VAR;

	/* Fall back to default value parsing rules. */
	return parse_value(server);
}

/*
 * Parses a UTF-8 string. Currently, strings are meaningful as a "result", as
 * method "params", as a "context" parameter, and as an "error" message.
 */
static int
handle_string(void *ctx, const unsigned char *value, unsigned int len)
{
	GET_SERVER_VAR;
	JSON_Server_Alloc *alloc;

	switch (server->state) {
	case JSON_SERVER_STATE_MESSAGE:
		switch (server->key_idx) {
		case TOKEN_RESULT:
			/* Results are allowed to be strings. */
			PARSER_SET_TYPE(JSON_SERVER_MSG_RESULT);
			return parser_set_message(server, value, len);

		case TOKEN_METHOD:
			/* Methods must be strings. */
			PARSER_SET_TYPE_PART(JSON_SERVER_MSG_REQUEST, 0);
			return parser_set_message(server, value, len);
		}
		break;

	case JSON_SERVER_STATE_PARAMS:
		/* Method parameters are allowed to be strings. */
		PARSER_CHECK_LOCAL;

		alloc = alloc_json_alloc(server);
		if (alloc) {
			if (alloc_json_item_string(alloc, value, len)
			    != JSON_ALLOC_FAILED) {
				return 1;
			}
		}

		PARSER_RAISE_LOCAL;
		return 1;

	case JSON_SERVER_STATE_CONTEXT:
		/* Invoke context parameter callback. */
		return parser_set_context(server, value, len);

	case JSON_SERVER_STATE_ERROR:
		switch (server->key_idx) {
		case TOKEN_ERROR_MESSAGE:
			/* Error messages must be strings. */
			PARSER_SET_TYPE_PART(JSON_SERVER_MSG_ERROR, 2);
			return parser_set_message(server, value, len);
		}
		break;

	default:
		break;
	}

	/* Fall back to default value parsing rules. */
	return parse_value(server);
}

/*
 * Parses the start of an object. Interesting objects are the root message
 * object, the error response object, and the context parameters object.
 */
static int
handle_start_map(void *ctx)
{
	GET_SERVER_VAR;

	switch (server->state) {
	case JSON_SERVER_STATE_WAITING:
		/* Entering message object. */
		server->state = JSON_SERVER_STATE_MESSAGE;
		return 1;

	case JSON_SERVER_STATE_MESSAGE:
		switch (server->key_idx) {
		case TOKEN_PARAMS:
			/* Unsupported type. */
			PARSER_SET_TYPE_PART(JSON_SERVER_MSG_REQUEST, 1);
			PARSER_RAISE_LOCAL;
			server->key_idx = -1;
			break;

		case TOKEN_CONTEXT:
			/* Entering context object. */
			PARSER_SET_TYPE_PART(JSON_SERVER_MSG_REQUEST, 2);
			server->state = JSON_SERVER_STATE_CONTEXT;
			return 1;

		case TOKEN_ERROR:
			/* Entering error object. */
			PARSER_SET_TYPE_PART(JSON_SERVER_MSG_ERROR, 0);
			server->state = JSON_SERVER_STATE_ERROR;
			return 1;
		}
		break;

	default:
		break;
	}

	/* Fall back to default ccomposite value entry parsing rules. */
	return parse_enter(server);
}

/*
 * Parses an object key. Interesting keys are in the root message object, the
 * error response object, and the context parameters object.
 */
static int
handle_map_key(void *ctx, const unsigned char *key, unsigned int len)
{
	GET_SERVER_VAR;

	switch (server->state) {
	case JSON_SERVER_STATE_COMPOSITE:
		/* Ignoring unknown composite value. */
		break;

	case JSON_SERVER_STATE_MESSAGE:
		/* Message object key. */
		server->key_idx = find_token(tok_tab_root, key, len);
		break;

	case JSON_SERVER_STATE_CONTEXT:
		/* Context parameter key. */
		PARSER_CHECK_LOCAL;

		if (len < JSON_SERVER_BUFFER_SIZE) {
			/* Copy key for later use. */
			server->key_len = len;

			memcpy(server->key_buf, key, len);
			server->key_buf[len] = '\0';
		} else {
			/* Ignore excessively long keys. */
			server->key_len = -1;
		}
		break;

	case JSON_SERVER_STATE_ERROR:
		/* Error object key. */
		server->key_idx = find_token(tok_tab_error, key, len);
		break;

	default:
		/* Unexpected parser state. */
		return 0;
	}

	return 1;
}

/*
 * Parses the end of an object.
 */
static int
handle_end_map(void *ctx)
{
	GET_SERVER_VAR;

	switch (server->state) {
	case JSON_SERVER_STATE_MESSAGE:
		/* End of message. Sadly, can't terminate parse. */
		server->state = JSON_SERVER_STATE_READY;
		return 1;

	case JSON_SERVER_STATE_CONTEXT:
	case JSON_SERVER_STATE_ERROR:
		/* Continue parsing message object. */
		server->state = JSON_SERVER_STATE_MESSAGE;
		return 1;

	default:
		break;
	}

	/* Fall back to default composite value exit parsing rules. */
	return parse_exit(server);
}

/*
 * Parses the start of an array.
 */
static int
handle_start_array(void *ctx)
{
	GET_SERVER_VAR;

	switch (server->state) {
	case JSON_SERVER_STATE_MESSAGE:
		switch (server->key_idx) {
		case TOKEN_PARAMS:
			/* Entering parameter array. */
			PARSER_SET_TYPE_PART(JSON_SERVER_MSG_REQUEST, 1);
			server->state = JSON_SERVER_STATE_PARAMS;
			return 1;
		}
		break;

	default:
		break;
	}

	/* Fall back to default composite value entry parsing rules. */
	return parse_enter(server);
}

/*
 * Parses the end of an array.
 */
static int
handle_end_array(void *ctx)
{
	GET_SERVER_VAR;

	switch (server->state) {
	case JSON_SERVER_STATE_PARAMS:
		/* Continue parsing message object. */
		server->state = JSON_SERVER_STATE_MESSAGE;
		return 1;

	default:
		break;
	}

	/* Fall back to default composite value exit parsing rules. */
	return parse_exit(server);
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
json_server_json_alloc(JSON_Server *server)
{
	server->internal = NULL;

	server->encoder = yajl_gen_alloc(&gen_config, NULL);
	if (!server->encoder) {
		JSON_LOG("json_alloc: yajl_gen_alloc");
		return 0;
	}

	server->decoder = yajl_alloc(&callbacks, &parser_config, NULL, server);
	if (!server->decoder) {
		/* Not fatal, but will prevent operation. */
		JSON_LOG("json_alloc: yajl_alloc");
		yajl_gen_free(server->encoder);
		server->decoder = NULL;
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
	TRY_GEN(yajl_gen_array_open(server->encoder));
	TRY_GEN(yajl_gen_null(server->encoder));
	yajl_gen_clear(server->encoder);

	server->state = JSON_SERVER_STATE_COMPOSITE;
	server->nesting_depth = 0; /* for safety, if we add overflow check */
	TRY_PARSE("[null", 5);
	server->state = JSON_SERVER_STATE_READY;
	server->nesting_depth = 0;

	server->lex_ctx = 0;
	server->lex_depth = 0;

	return 1;

failed:
	JSON_LOG("json_alloc: yajl");
	json_server_json_free(server);
	return 0;
}

/*
 * Deallocate JSON encoder/decoder.
 */
void
json_server_json_free(JSON_Server *server)
{
	if (server->internal) {
		release_json_pool(GET_SERVER_POOL(server));
		server->internal = NULL; /* not needed; for safety */
	}

	if (server->encoder) {
		yajl_gen_free(server->encoder);
		server->encoder = NULL; /* not needed; for safety */
	}

	if (server->decoder) {
		yajl_free(server->decoder);
		server->decoder = NULL; /* not needed; for safety */
	}
}

/*
 * Starts request.
 */
int
json_server_start_request(JSON_Server *server, const char *method, int len)
{
	switch (server->state) {
	case JSON_SERVER_STATE_READY:
		/* GENERATE: {"method":method[len] */
		TRY_GEN(yajl_gen_map_open(server->encoder));
		TRY_GEN_STR("method", 6);
		TRY_GEN_STR(method, len);

		server->state = JSON_SERVER_STATE_REQ;
		break;

	default:
		JSON_LOG("start_request: invalid state");
		return 0;
	}

	return 1;

failed:
	JSON_LOG("start_request: yajl_gen");
	return 0;
}

/*
 * Adds positional parameter to current request.
 */
int
json_server_add_param(JSON_Server *server, const char *value, int len)
{
	switch (server->state) {
	case JSON_SERVER_STATE_REQ:
		/* GENERATE: "param":[ */
		TRY_GEN_STR("params", 6);
		TRY_GEN(yajl_gen_array_open(server->encoder));

		server->state = JSON_SERVER_STATE_REQ_ARGS;
		/* FALLTHROUGH */
	case JSON_SERVER_STATE_REQ_ARGS:
		/* GENERATE: value[len] */
		TRY_GEN_STR(value, len);
		break;

	default:
		JSON_LOG("add_param: invalid state");
		return 0;
	}

	return 1;

failed:
	JSON_LOG("add_param: yajl_gen");
	return 0;
}

/*
 * Adds context parameter to current request.
 */
int
json_server_add_context(JSON_Server *server,
                        const char *key, int klen,
                        const char *value, int vlen)
{
	switch (server->state) {
	case JSON_SERVER_STATE_REQ_ARGS:
		/* GENERATE: ] */
		TRY_GEN(yajl_gen_array_close(server->encoder));

		/* FALLTHROUGH */
	case JSON_SERVER_STATE_REQ:
		/* GENERATE: "context":{ */
		TRY_GEN_STR("context", 7);
		TRY_GEN(yajl_gen_map_open(server->encoder));

		server->state = JSON_SERVER_STATE_REQ_CTX;
		/* FALLTHROUGH */
	case JSON_SERVER_STATE_REQ_CTX:
		/* GENERATE: key:value */
		TRY_GEN_STR(key, klen);
		TRY_GEN_STR(value, vlen);
		break;

	default:
		JSON_LOG("add_context: invalid state");
		return 0;
	}

	return 1;

failed:
	JSON_LOG("add_context: yajl_gen");
	return 0;
}

/*
 * Sends complete request.
 */
int
json_server_send_request(JSON_Server *server)
{
	switch (server->state) {
	case JSON_SERVER_STATE_REQ:
		/* GENERATE: */
		break;

	case JSON_SERVER_STATE_REQ_ARGS:
		/* GENERATE: ] */
		TRY_GEN(yajl_gen_array_close(server->encoder));
		break;

	case JSON_SERVER_STATE_REQ_CTX:
		/* GENERATE: } */
		TRY_GEN(yajl_gen_map_close(server->encoder));
		break;

	default:
		JSON_LOG("send_request: invalid state");
		return 0;
	}

	/* GENERATE: } */
	TRY_GEN(yajl_gen_map_close(server->encoder));

	/* Transmit complete request. Block until complete. */
	if (!flush_json(server)) {
		return 0;
	}

	server->state = JSON_SERVER_STATE_WAITING;
	return 1;

failed:
	JSON_LOG("send_request: yajl_gen");
	return 0;
}

/*
 * Sends result. The result may be NULL.
 */
int
json_server_send_result(JSON_Server *server, const char *result, int len)
{
	if (server->state != JSON_SERVER_STATE_READY) {
		JSON_LOG("send_result: invalid state");
		return 0;
	}

	/* GENERATE: {"result": */
	TRY_GEN(yajl_gen_map_open(server->encoder));
	TRY_GEN_STR("result", 6);

	if (result) {
		/* GENERATE: result[len] */
		TRY_GEN_STR(result, len);
	} else {
		/* GENERATE: null */
		TRY_GEN(yajl_gen_null(server->encoder));
	}

	/* GENERATE: } */
	TRY_GEN(yajl_gen_map_close(server->encoder));

	/* Transmit result. Block until complete. */
	if (!flush_json(server)) {
		return 0;
	}

	server->state = JSON_SERVER_STATE_WAITING;
	return 1;

failed:
	JSON_LOG("send_result: yajl_gen");
	return 0;
}

/*
 * Sends error.
 */
int
json_server_send_error(JSON_Server *server, long int code,
                       const char *error, int len)
{
	if (server->state != JSON_SERVER_STATE_READY) {
		JSON_LOG("send_error: invalid state");
		return 0;
	}

	/* GENERATE: {"error":{"code":code,"message":error[len]}} */
	TRY_GEN(yajl_gen_map_open(server->encoder));
	TRY_GEN_STR("error", 5);

	TRY_GEN(yajl_gen_map_open(server->encoder));
	TRY_GEN_STR("code", 4);
	TRY_GEN(yajl_gen_integer(server->encoder, code));

	TRY_GEN_STR("message", 7);
	TRY_GEN_STR(error, len);
	TRY_GEN(yajl_gen_map_close(server->encoder));

	TRY_GEN(yajl_gen_map_close(server->encoder));

	/* Transmit error. Block until complete. */
	if (!flush_json(server)) {
		return 0;
	}

	server->state = JSON_SERVER_STATE_WAITING;
	return 1;

failed:
	JSON_LOG("send_error: yajl_gen");
	return 0;
}

/*
 * Initializes a received message for first use.
 */
void
json_server_message_init(JSON_Server_Message *msg)
{
	/* Mark this message as having no internal bookkeeping information. */
	msg->internal = NULL;

	/* Clear the message. */
	json_server_message_clear(msg);
}

/*
 * Clears a received message, releasing any allocated memory.
 */
void
json_server_message_clear(JSON_Server_Message *msg)
{
	JSON_Server_Alloc *alloc = GET_MESSAGE_ALLOC(msg);

	/* Release the internal bookkeeping information. */
	if (alloc) {
		JSON_Server_Alloc_Pool *pool = alloc->pool;

		alloc->next = pool->available;
		pool->available = alloc;

		release_json_pool(pool);

		msg->internal = NULL;
	}

	/* Mark this message as having an unknown type. */
	msg->type = JSON_SERVER_MSG_NONE;

	/* Clear the local error state. */
	msg->local_error = 0;
}

/*
 * Receives next message. Due to the structure of the PennJSON protocol, we
 * must receive one complete JSON message before continuing. (We may also
 * receive up to one asynchronous polling request message.)
 *
 * The message must be cleared before calling this function. The message will
 * remain cleared in the event of an error.
 *
 * A local error state is still considered the successful receipt of a message.
 * A local error indicates an implementation limitation. However, only the
 * message type and local error state are guaranteed to be valid in this
 * situation.
 */
int
json_server_receive(JSON_Server *server, JSON_Server_Message *msg)
{
	JSON_Server_Alloc *alloc;
	ssize_t result;
	int ii;

	switch (server->state) {
	case JSON_SERVER_STATE_READY:
		/* Receiving asynchronous request. */
		server->state = JSON_SERVER_STATE_WAITING;
		break;

	case JSON_SERVER_STATE_WAITING:
		/* Waiting for response after request. */
		break;

	default:
		/* Unexpected state. */
		return 0;
	}

	/* Parse virtual comma for streaming hack. */
	TRY_PARSE(",", 1);

	/* Receive message. */
	server->msg = msg;

	do {
		if (server->in_off == server->in_len) {
			/* Fill buffer. */
			if ((result = read(server->fd, server->in_buf,
			                   JSON_SERVER_BUFFER_SIZE)) == -1) {
				JSON_LOG_ERRNO("receive: read");
				goto failed;
			}

			if (result == 0) {
				JSON_LOG("receive: closed");
				goto failed;
			}

			server->in_off = 0;
			server->in_len = result;

			server->lex_off = 0;
		}

		/* Parse from buffer. */
		lexer_prescan(server);

		TRY_PARSE(server->in_buf + server->in_off,
		          server->lex_off - server->in_off);

		server->in_off += yajl_get_bytes_consumed(server->decoder);
	} while (server->state != JSON_SERVER_STATE_READY);

	/*
	 * Validate received message.
	 *
	 * TODO: We may want to zero out unused fields.
	 */
	if (msg->local_error) {
		/* Local error; ignore result. */
		return 1;
	}

	switch (msg->type) {
	case JSON_SERVER_MSG_REQUEST:
		if (!HAS_PART(0)) {
			/* Malformed request message. */
			goto failed;
		}

		alloc = GET_MESSAGE_ALLOC(msg); /* must exist */
		msg->message = GET_ALLOC_PTR(msg->int_off);

		for (ii = 0; ii < alloc->size; ii++) {
			alloc->items[ii] = GET_ALLOC_PTR(alloc->itemoffs[ii]);
		}

		msg->param_nargs = alloc->size;
		msg->param_args = alloc->items;
		msg->param_arglens = alloc->itemlens;
		break;

	case JSON_SERVER_MSG_RESULT:
		if (msg->int_off == JSON_ALLOC_FAILED) {
			/* Indicates null result. */
			msg->message = NULL;
			break;
		}

		alloc = GET_MESSAGE_ALLOC(msg); /* must exist */
		msg->message = GET_ALLOC_PTR(msg->int_off);
		break;

	case JSON_SERVER_MSG_ERROR:
		if (!(HAS_PART(0) && HAS_PART(1) && HAS_PART(2))) {
			/* Malformed error message. */
			goto failed;
		}

		alloc = GET_MESSAGE_ALLOC(msg); /* must exist */
		msg->message = GET_ALLOC_PTR(msg->int_off);
		break;

	default:
		/* Unexpected message type. */
		goto failed;
	}

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
flush_json(JSON_Server *server)
{
	const unsigned char *buf;
	unsigned int len;

	ssize_t result;

	TRY_GEN(yajl_gen_get_buf(server->encoder, &buf, &len));

	/*
	 * Our infinite stream hack (see json_server_json_alloc) introduces a
	 * spurious comma that we need to skip.
	 */
	buf += 1;
	len -= 1;

	while (len > 0) {
		if ((result = write(server->fd, buf, len)) == -1) {
			JSON_LOG_ERRNO("flush_json: write");
			return 0;
		}

		buf += result;
		len -= result;
	}

	yajl_gen_clear(server->encoder);
	return 1;

failed:
	JSON_LOG("flush_json: yajl_gen");
	return 0;
}
