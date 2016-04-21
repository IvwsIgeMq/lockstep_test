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
#include <fcntl.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <pthread.h>
#endif
#include <sys/socket.h>

#define CONNECTING  1
#define CONNECTED   1<<1
#define SENDDATA    1<<2
#define RECVDATA    1<<3
#define KCPSEND     1<<4
#define KCPRECV     1<<5



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
    IUINT32 update_time;
    int state ;
}KCP;


typedef struct {
    KCP** kcp_array;
    unsigned int kcp_array_len;
    unsigned int kcp_count;
    unsigned int max_kcp_fd;
    int fd;
    char * recv_buff;
    size_t recv_buff_len;
    struct sockaddr_in addr;
}KCP_Server;

void * kcp_create_client(unsigned int kcp_fd);
void * kcp_create_server(unsigned int maxClient);

int kcp_connect(void * netObject,const char* ip, unsigned int port);
int kcp_listen(void * netObject, unsigned int port);
int kcp_send(void * netObject, const char* buff, unsigned int len);
M_Node* kcp_recv(void * netObject);
int kcp_close(void * netObject);
void kcp_server_update(void * p);
void kcp_server_send(void * p);
void* kcp_server_recv(void * p);
void kcp_free(void * p);




#endif /* kcp_socket_h */
