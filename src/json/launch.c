/*
 * JSON server launcher. Responsible for launching JSON server instances.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "json-config.h"
#include "json-private.h"

/* Maximum 32-bit integer string length is 1 + 11 + 1 = 13. */
#define ARG_BUF_SIZE 13

/* Log file open mode. */
#define LOG_MODE (O_CREAT|O_WRONLY|O_APPEND)

/* Log file permissions. */
#define LOG_PERMS (0644)

/* Launch JSON server instance. */
static void json_server_launch(JSON_Server *info);

/* Close excess file descriptors. */
static int json_server_close_all(JSON_Server *info);
static int json_server_close_all_loop(JSON_Server *info, DIR *dir);

/* Recreate the standard file descriptors. */
static int json_server_init_fds(JSON_Server *info);

/*
 * Lazily starts a JSON server instance.
 *
 * Current PennMUSH client only uses a single instance, since PennMUSH is
 * essentially single threaded anyway, but future clients may want to use a
 * pool of JSON server instances.
 */
void
json_server_start(JSON_Server *const info)
{
	int pair[2];
	int flags;

	if (info->fd != -1) {
		/* Already started. */
		return;
	}

	/* Reset data structure. */
	if (!json_server_json_alloc(info)) {
		return;
	}

	info->state = JSON_SERVER_STATE_READY;
	info->in_off = 0;
	info->in_len = 0;

	/* Create socket pair. */
	if (socketpair(AF_LOCAL, SOCK_STREAM, 0, pair) == -1) {
		json_server_log(info, "start: socketpair", errno);
		json_server_json_free(info);
		return;
	}

	/* Fork. */
	switch (fork()) {
	case -1:
		/* Failed. */
		json_server_log(info, "start: fork", errno);
		break;

	case 0:
		/* Prepare file descriptors. */
		info->fd = pair[1];

		if (!json_server_close_all(info)) {
			_Exit(EXIT_FAILURE);
		}

		if (!json_server_init_fds(info)) {
			_Exit(EXIT_FAILURE);
		}

		/* Launch JSON server instance. */
		info->fd = pair[1];

		json_server_launch(info);

		/* Never returns, normally. */
		_Exit(EXIT_FAILURE);
		break;

	default:
		/* Prepare parent socket. */
		if ((flags = fcntl(pair[0], F_GETFD)) == -1) {
			json_server_log(info, "start: fcntl[F_GETFD]", errno);
			break;
		}

		if (fcntl(pair[0], F_SETFD, flags | FD_CLOEXEC) == -1) {
			json_server_log(info, "start: fcntl[F_SETFD]", errno);
			break;
		}

		info->fd = pair[0];
		break;
	}

	/* Clean up parent. */
	if (close(pair[1]) == -1) {
		json_server_log(info, "start: close[1]", errno);
		info->fd = -1; /* note info->fd == -1 or pair[0] */
	}

	if (info->fd == -1) {
		if (close(pair[0]) == -1) {
			json_server_log(info, "start: close[0]", errno);
		}
	}

	if (info->fd == -1) {
		json_server_json_free(info);
	}
}

/*
 * Stops a JSON server instance.
 */
void
json_server_stop(JSON_Server *const info)
{
	if (info->fd == -1) {
		/* Already stopped. */
		return;
	}

	/* Close the file descriptor. This should initiate shutdown. */
	if (close(info->fd) == -1) {
		json_server_log(info, "stop: close", errno);
	}

	/* Clean up other resources. */
	json_server_json_free(info);

	/* Indicate data structure can be reused. */
	info->fd = -1;
}

/*
 * Launch JSON server instance.
 */
static void
json_server_launch(JSON_Server *info)
{
	char arg1[ARG_BUF_SIZE];

	/* Change working directory. */
	if (chdir(JSON_SERVER_DIR) == -1) {
		json_server_log(info, "launch: chdir", errno);
		return;
	}

	/* Initialize arguments. */
	if (snprintf(arg1, ARG_BUF_SIZE, "%d", info->fd) >= ARG_BUF_SIZE) {
		json_server_log(info, "launch: snprintf truncated", 0);
		return;
	}

	/* Execute JSON server instance. Does not normally return. */
	json_server_log(info, "Launching JSON server...", 0);
	execl(JSON_SERVER, JSON_SERVER, arg1, (char *)NULL);

	json_server_log(info, "launch: execl", errno);
}

/*
 * Close excess file descriptors. All descriptors except for the child half of
 * the socket pair and stderr will be closed.
 */
static int
json_server_close_all(JSON_Server *info)
{
	/*
	 * Note that this code is non-portable; it relies on UNIX-specific
	 * behavior on systems with a /dev file system. A portable (but less
	 * elegant) solution is to simply close all file descriptors up to
	 * sysconf(_SC_OPEN_MAX).
	 */

	DIR *dir;

	int result = 1;

	/* Open directory listing file descriptors for self. */
	if (!(dir = opendir("/dev/fd"))) {
		json_server_log(info, "close_all: opendir", errno);
		return 0;
	}

	/* Close listed file descriptors. */
	result = json_server_close_all_loop(info, dir);

	/* Clean up. */
	if (closedir(dir) == -1) {
		json_server_log(info, "close_all: closedir", errno);
		result = 0;
	}

	return result;
}

static int
json_server_close_all_loop(JSON_Server *info, DIR *dir)
{
	int dfd;

	struct dirent *ent;
	char *endp;

	/* Don't close the DIR file descriptor while we're still using it. */
	if ((dfd = dirfd(dir)) == -1) {
		json_server_log(info, "close_all: dirfd", errno);
		return 0;
	}

	errno = 0;

	while ((ent = readdir(dir))) {
		int fd;

		/* Parse file descriptor number. */
		fd = strtol(ent->d_name, &endp, 10);

		if (*endp || endp == ent->d_name || errno != 0) {
			/* Ignore unparseable file descriptors. */
			errno = 0;
			continue;
		}

		/* Close all file descriptor. */
		if (fd == STDERR_FILENO || fd == dfd || fd == info->fd) {
			/* Except for certain file descriptors. */
			continue;
		}

		if (close(fd) == -1) {
			json_server_log(info, "close_all: close", errno);
			return 0;
		}
	}

	if (errno != 0) {
		json_server_log(info, "close_all: readdir", errno);
	}

	return 1;
}

/*
 * Recreate the standard file descriptors. (That is, stdin (0), stdout (1), and
 * stderr (2).) The standard file descriptors should be closed at this point,
 * except for stderr.
 */
static int
json_server_init_fds(JSON_Server *info)
{
	/* Recreate stdin. */
	if (open("/dev/null", O_RDONLY) != STDIN_FILENO) {
		json_server_log(info, "init_fds: open", errno);
		return 0;
	}

	/* Recreate stdout. */
	if (open(JSON_SERVER_LOG, LOG_MODE, LOG_PERMS) != STDOUT_FILENO) {
		json_server_log(info, "init_fds: creat", errno);
		return 0;
	}

	/* Replace stderr. */
	if (close(STDERR_FILENO) == -1) {
		/* Can't report errors at this point. */
		return 0;
	}

	if (dup(STDOUT_FILENO) != STDERR_FILENO) {
		/* Can't report errors at this point. */
		return 0;
	}

	return 1;
}
