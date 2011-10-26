#ifndef JSON_PRIVATE_H
#define JSON_PRIVATE_H

#include <yajl/yajl_gen.h>
#include <yajl/yajl_parse.h>

/* Internal declarations for the JSON server */

/* I/O buffer size. */
#define JSON_SERVER_BUFFER_SIZE 32768

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

  JSON_SERVER_STATE_IGNORING, /* parsing ignored */
  JSON_SERVER_STATE_OBJECT, /* parsing message object */
  JSON_SERVER_STATE_PARAMS, /* parsing method parameters */
  JSON_SERVER_STATE_CONTEXT, /* parsing context parameters */
  JSON_SERVER_STATE_ERROR /* parsing error object */
} JSON_Server_State;

/*
 * Received message type.
 */
typedef enum JSON_Server_Message_Type_tag {
  JSON_SERVER_MSG_NONE, /* no message */
  JSON_SERVER_MSG_REQUEST, /* request */
  JSON_SERVER_MSG_RESULT, /* successful response */
  JSON_SERVER_MSG_ERROR /* error response */
} JSON_Server_Message_Type;

/*
 * Received message. This structure is meant to be preallocated by the caller,
 * then filled in with the results of an incoming message.
 */
typedef struct JSON_Server_Message_tag {
  JSON_Server_Message_Type type; /* message type */

  /* Method descriptor/result/error message. */
  char *message;

  /* Additional request information. */
  int param_size; /* allocated number of parameters */
  int param_nargs; /* actual number of parameters */
  char **param_args; /* parameter strings; may contain embedded nulls */
  int *param_arglens; /* parameter string lengths */

  /* TODO: Handle context information? */

  /* Additional error information. */
  long int error_code; /* error code */
} JSON_Server_Message;

/*
 * Type for holding information about a JSON server instance. For the first
 * connection attempt, fd should be set to -1. Subsequent requests should use
 * the same JSON_Server object, until a disconnect. Check for failure by
 * whether or not fd is still -1 after return.
 */
typedef struct JSON_Server_tag {
  int fd; /* file descriptor; initialize to -1 for first connect */

  JSON_Server_State state; /* protocol state */

  unsigned int in_off; /* offset to data in temporary read buffer */
  unsigned int in_len; /* length of data in temporary read buffer */
  unsigned char in_buf[JSON_SERVER_BUFFER_SIZE]; /* temporary read buffer */

  yajl_gen encoder; /* JSON encoder */
  yajl_handle decoder; /* JSON decoder */

  JSON_Server_Message *msg; /* current message */
  int msg_nesting; /* current nesting depth */
  int msg_token; /* current key token */
  int valid_error_code; /* flag indicating if error code is valid */

  int restore_nesting; /* nesting level to restore at */
  JSON_Server_State restore_state; /* protocol state to restore */
} JSON_Server;

/* Simple logging facility. Use 0 or errno-style for code parameter. */
extern void json_server_log(JSON_Server *info, const char *message, int code);

/* Lazily starts a JSON server instance. */
extern void json_server_start(JSON_Server *info);

/* Stops a JSON server instance. */
extern void json_server_stop(JSON_Server *info);

/* Allocate JSON encoder/decoder. */
extern int json_server_json_alloc(JSON_Server *info);

/* Deallocate JSON encoder/decoder. */
extern void json_server_json_free(JSON_Server *info);

/* Starts a request message. */
extern int json_server_start_request(JSON_Server *info, const char *method,
                                     int len);

/* Add parameter. Must come after json_server_start_request. */
extern int json_server_add_param(JSON_Server *info, const char *value, int len);

/* Add context value. Must come after any parameters. */
extern int json_server_add_context(JSON_Server *info, const char *key, int klen,
                                   const char *value, int vlen);

/* Sends a request message started by json_server_start_request(). */
extern int json_server_send_request(JSON_Server *info);

/* Sends a result message. */
extern int json_server_send_result(JSON_Server *info, const char *result,
                                   int len);

/* Sends an error message. */
extern int json_server_send_error(JSON_Server *info, long int code,
                                  const char *error, int len);

/* Receives a message. */
extern int json_server_receive(JSON_Server *info, JSON_Server_Message *msg);

/* Clears received message, releasing any allocated memory. */
extern void json_server_message_clear(JSON_Server_Message *msg);

#endif /* undef JSON_PRIVATE_H */
