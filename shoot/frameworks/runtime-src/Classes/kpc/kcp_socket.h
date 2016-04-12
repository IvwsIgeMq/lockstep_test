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
}KCP;

void * create_kcp();
int kcp_connect(void * netObject,const char* ip, unsigned int port);
int kcp_send(void * netObject, const char* buff, unsigned int len);
M_Node* kcp_recv(void * netObject);
int kcp_close(void * netObject);





#endif /* kcp_socket_h */
