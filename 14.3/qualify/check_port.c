/*
 **
 * BEGIN_COPYRIGHT
 *
 * This file is part of SciDB.
 * Copyright (C) 2008-2014 SciDB, Inc.
 *
 * SciDB is free software: you can redistribute it and/or modify
 * it under the terms of the AFFERO GNU General Public License as published by
 * the Free Software Foundation.
 *
 * SciDB is distributed "AS-IS" AND WITHOUT ANY WARRANTY OF ANY KIND,
 * INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY,
 * NON-INFRINGEMENT, OR FITNESS FOR A PARTICULAR PURPOSE. See
 * the AFFERO GNU General Public License for the complete license terms.
 *
 * You should have received a copy of the AFFERO GNU General Public License
 * along with SciDB.  If not, see <http://www.gnu.org/licenses/agpl-3.0.html>
 *
 * END_COPYRIGHT
 */

/****************************************************************************
 * This routine will check access to the specified port on the specified host
 *
 * check_port <2host> <port>
 ****************************************************************************/

#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/un.h>
#include <bits/local_lim.h>

char hostname[HOST_NAME_MAX+1];

int check_port (char *host, char *service) {
  struct addrinfo hints, *res;
  int status;
  int sockfd;
  int flags;

  // load up address structs with getaddrinfo():

  memset(&hints, 0, sizeof hints);
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  if ((status = getaddrinfo(host, service, &hints, &res)) != 0) {
    fprintf(stderr, "%s GETADDRINFO %s:%s %s\n", hostname, host, service, gai_strerror(status));
    return(-1);
  }

  // make a socket:

  sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
  if (sockfd < 0) {
    fprintf(stderr, "%s SOCKET %s:%s %s\n", hostname, host, service, strerror(errno));
    return(-1);
  }

  // non-blocking socket

  flags = fcntl(sockfd, F_GETFL, 0);
  fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

  // connect

  if ( connect(sockfd, res->ai_addr, res->ai_addrlen) < 0) {
    if (errno != EINPROGRESS) {
      fprintf(stderr, "%s CONNECT %s:%s %s\n", hostname, host, service, strerror(errno));
      close(sockfd);
      return(-1);
    } else {
      // timeout
      sleep(1);
      if ( connect(sockfd, res->ai_addr, res->ai_addrlen) < 0) {
	fprintf(stderr, "%s CONNECT %s:%s %s\n", hostname, host, service, strerror(errno));
	close(sockfd);
	return(-1);
      }
    }
  }
  fprintf(stderr, "%s OK %s:%s\n", hostname, host, service);
  close(sockfd);
  return(0);
}

// USAGE

void usage (char *name, char *msg) {
  fprintf(stderr, "\n%s\n", msg);
  fprintf(stderr, "  %s <host> <port>\n", name);
  return;
}

// MAIN

main (int argc, char *argv[]) {

  char host[HOST_NAME_MAX+1];
  char port[5];

  if (argc != 3) {
    usage(argv[0], "Incorrect number of arguments.");
    exit(-1);
  }
  strcpy(host, argv[1]);
  strcpy(port, argv[2]);

  // this machine's hostname

  gethostname(hostname, HOST_NAME_MAX);

  check_port(host, port);
}
