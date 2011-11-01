#ifndef JSON_PRIVATE_H
#define JSON_PRIVATE_H

#include <yajl/yajl_gen.h>
#include <yajl/yajl_parse.h>

/* Internal declarations for the JSON server */

/* I/O buffer size. */
#define JSON_SERVER_BUFFER_SIZE 32768

/*
 * Maximum parse parts. This value is sufficient to handle messages with up to
 * 3 parts. Any useful value can be parsed with only this many parts.
 */
#define JSON_SERVER_MAX_PARSE_PARTS 3

/* Error code for method not found. */
#define JSON_SERVER_ERROR_METHOD -32601

/* Error code for invalid method parameters. */
#define JSON_SERVER_ERROR_PARAMS -32602

/* Error code for (non-fatal) internal error. */
#define JSON_SERVER_ERROR_INTERNAL -32603

/*
 * Context parameter callback. Currently defined statically, but we may want to
 * allow different implementations, or explicit context parameters at a future
 * date. But not needed for now.
 *
 * No assumptions should be made about the lifetime of the parameters. An
 * explicit copy should be made if the parameters need to be retained. The
 * strings are not necessarily null-terminated.
 *
 * The value may be NULL, to indicate a special value. If the value length is
 * -1, the parameter should be removed. If the value length is -2, the value
 * type is not supported.
 *
 * The return value should normally be non-zero to indicate that the parameter
 * was handled successfully. Zero should be returned if an internal error
 * prevents the parameter from being handled.
 */
extern int json_server_context_callback(const char *key, int klen,
                                        const char *value, int vlen);

/*
 * Protocol state.
 */
typedef enum JSON_Server_State_tag {
  /* Send states. */
  JSON_SERVER_STATE_READY, /* ready to send */

  JSON_SERVER_STATE_REQ, /* started request */
  JSON_SERVER_STATE_REQ_ARGS, /* started request parameters */
  JSON_SERVER_STATE_REQ_CTX, /* started request context */

  /* Receive states. */
  JSON_SERVER_STATE_WAITING, /* waiting to receive */

  JSON_SERVER_STATE_COMPOSITE, /* parsing composite value */
  JSON_SERVER_STATE_MESSAGE, /* parsing message object */
  JSON_SERVER_STATE_PARAMS, /* parsing method parameters array */
  JSON_SERVER_STATE_CONTEXT, /* parsing context object */
  JSON_SERVER_STATE_ERROR /* parsing error object */
} JSON_Server_State;

/*
 * Received message type.
 */
typedef enum JSON_Server_Message_Type_tag {
  JSON_SERVER_MSG_NONE, /* unknown */
  JSON_SERVER_MSG_REQUEST, /* request */
  JSON_SERVER_MSG_RESULT, /* successful response */
  JSON_SERVER_MSG_ERROR /* error response */
} JSON_Server_Message_Type;

/*
 * Received message. This structure is meant to be preallocated by the caller,
 * then filled in with the results of an incoming message.
 *
 * TODO: Consider making this data structure opaque. On the other hand, the
 * PennJSON code is the only code that is ever going to see it.
 */
typedef struct JSON_Server_Message_tag {
  JSON_Server_Message_Type type; /* message type */

  /* Method descriptor/result/error message. */
  char *message;

  /* Additional request information. */
  int param_nargs; /* number of parameters */
  char **param_args; /* parameter strings; may contain embedded nulls */
  int *param_arglens; /* parameter string lengths */

  /* Additional error information. */
  long int error_code; /* error code */
  long int local_error; /* local error code; check if non-zero */

  /* Internal bookkeeping information. */
  void *internal;
  size_t int_off;
} JSON_Server_Message;

/*
 * Type for holding information about a JSON server instance. For the first
 * connection attempt, fd should be set to -1. Subsequent requests should use
 * the same JSON_Server object, until a disconnect. Check for failure by
 * whether or not fd is still -1 after return.
 */
typedef struct JSON_Server_tag {
  /* I/O state. */
  int fd; /* file descriptor; initialize to -1 for first connect */

  JSON_Server_State state; /* protocol state */

  unsigned int in_off; /* offset to data in temporary read buffer */
  unsigned int in_len; /* length of data in temporary read buffer */
  unsigned char in_buf[JSON_SERVER_BUFFER_SIZE]; /* temporary read buffer */

  yajl_gen encoder; /* JSON encoder */
  yajl_handle decoder; /* JSON decoder */

  /* Lexer state. */
  unsigned int lex_off; /* lexer offset */
  int lex_ctx; /* context character */
  int lex_depth; /* brace depth */

  /* Parser state. */
  JSON_Server_Message *msg; /* current message */

  int parts_seen[JSON_SERVER_MAX_PARSE_PARTS]; /* parts seen */

  int key_idx; /* current key token index */
  int key_len; /* temporary context key length */
  char key_buf[JSON_SERVER_BUFFER_SIZE]; /* temporary context key buffer */

  JSON_Server_State saved_state; /* saved state when parsing composite */
  int nesting_depth; /* nesting depth when parsing composite; starts at 0 */

  /* Internal bookkeeping information. */
  void *internal;
} JSON_Server;

/* Simple logging facility. Use 0 or errno-style for code parameter. */
extern void json_server_log(JSON_Server *server, const char *message, int code);

/* Lazily starts a JSON server instance. */
extern void json_server_start(JSON_Server *server);

/* Stops a JSON server instance. */
extern void json_server_stop(JSON_Server *server);

/* Allocate JSON encoder/decoder. */
extern int json_server_json_alloc(JSON_Server *server);

/* Deallocate JSON encoder/decoder. */
extern void json_server_json_free(JSON_Server *server);

/* Starts a request message. */
extern int json_server_start_request(JSON_Server *server,
                                     const char *method, int len);

/* Add parameter. Must come after json_server_start_request. */
extern int json_server_add_param(JSON_Server *server,
                                 const char *value, int len);

/* Add context value. Must come after any parameters. */
extern int json_server_add_context(JSON_Server *server,
                                   const char *key, int klen,
                                   const char *value, int vlen);

/* Sends a request message started by json_server_start_request(). */
extern int json_server_send_request(JSON_Server *server);

/* Sends a result message. */
extern int json_server_send_result(JSON_Server *server,
                                   const char *result, int len);

/* Sends an error message. */
extern int json_server_send_error(JSON_Server *server, long int code,
                                  const char *error, int len);

/* Initializes a received message for first use. */
extern void json_server_message_init(JSON_Server_Message *msg);

/*
 * Clears a received message, releasing any allocated memory.
 *
 * Note that this does not actually overwrite any memory. If for some terrible
 * reason you're actually passing secure data over the RPC mechanism, you
 * should make sure to explicitly zero out any sensitive data to minimize the
 * chance of compromise. (There are still a lot of potential attack vectors,
 * but it's better than nothing.)
 */
extern void json_server_message_clear(JSON_Server_Message *msg);

/* Receives a message. */
extern int json_server_receive(JSON_Server *server, JSON_Server_Message *msg);

#endif /* undef JSON_PRIVATE_H */
