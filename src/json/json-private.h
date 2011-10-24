#ifndef JSON_PRIVATE_H
#define JSON_PRIVATE_H

/* Internal declarations for the JSON server */

/* I/O buffer size. */
#define JSON_SERVER_BUFFER_SIZE 32768

/*
 * Type for holding information about a JSON server instance. For the first
 * connection attempt, fd should be set to -1. Subsequent requests should use
 * the same JSON_Server object, until a disconnect. Check for failure by
 * whether or not fd is still -1 after return.
 */
typedef struct JSON_Server_tag {
  int fd; /* file descriptor; initialize to -1 for first connect */

  size_t in_off; /* offset to data in temporary read I/O buffer */
  size_t in_len; /* length of data in temporary read I/O buffer */
  char in_buf[JSON_SERVER_BUFFER_SIZE]; /* temporary read I/O buffer */
  char out_buf[JSON_SERVER_BUFFER_SIZE]; /* temporary write I/O buffer */
} JSON_Server;

/* Simple logging facility. Use 0 or errno-style for code parameter. */
extern void json_server_log(JSON_Server *info, const char *message, int code);

/* Lazily starts a JSON server instance. */
extern void json_server_start(JSON_Server *info);

/* Stops a JSON server instance. */
extern void json_server_stop(JSON_Server *info);

#endif /* undef JSON_PRIVATE_H */
