#ifndef JSON_NET_H
#define JSON_NET_H

/* Interface with PennMUSH host environment's networking logic */

/* Shut down JSON server instance. */
void json_server_shutdown(int reboot);

/* Set input file descriptor. */
void json_server_setfd(int *maxd, fd_set *input_set);

/* Process input file descriptor. */
void json_server_issetfd(fd_set *input_set);

#endif /* undef JSON_NET_H */
