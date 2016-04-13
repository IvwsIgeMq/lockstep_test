//
//  kcp_socket.h
//  shoot
//
//  Created by 梁清风 on 16/4/8.
//
//

#ifndef kcp_socket_h
#define kcp_socket_h

#include <stdio.h>

#ifdef _WIN32
#include <winsock2.h>
#include <windows.h>
#include <process.h>
#include <ws2tcpip.h>
#else

#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <pthread.h>
#endif
#include <sys/socket.h>


//extern "C" {
#include "thread_safe_link.h"
#include "ikcp.h"
//}

typedef struct {
    ikcpcb *kcp;
    int fd;
    pthread_t thread;
    struct sockaddr_in addr;
    Link* recv_link;
    Link* send_link;
    void * kcp_server;
}KCP;


typedef struct {
    KCP** kcp_array;
    unsigned int kcp_array_len;
    unsigned int kcp_count;
    int fd;
    struct sockaddr_in addr;
    Link* kcp_link;
    Link* send_kcp_link;
    Link* recv_kcp_link;
    Link* free_kcp_link;
}KCP_Server;

void * create_kcp_client(unsigned int kcp_fd = 0);
void * create_kcp_server(unsigned int maxClient);

int kcp_connect(void * netObject,const char* ip, unsigned int port);
int kcp_listen(void * netObject, unsigned int port );
int kcp_send(void * netObject, const char* buff, unsigned int len);
M_Node* kcp_recv(void * netObject);
int kcp_close(void * netObject);





#endif /* kcp_socket_h */
