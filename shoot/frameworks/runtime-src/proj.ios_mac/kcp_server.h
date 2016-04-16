//
//  kcp_server.h
//  shoot
//
//  Created by 梁清风 on 16/4/16.
//
//

#ifndef kcp_server_h
#define kcp_server_h

#include <stdio.h>
#include "kcp_socket.h"

typedef struct {
    KCP** kcp_array;
    unsigned int kcp_array_len;
    unsigned int kcp_count;
    int fd;
    int use_thread;
    pthread_t thread;
    struct sockaddr_in addr;
    Link* kcp_link;
    Link* send_kcp_link;
    Link* recv_kcp_link;
    Link* free_kcp_link;
}KCP_Server;
void * kcp_create_server(unsigned int maxClient);

#endif /* kcp_server_h */
