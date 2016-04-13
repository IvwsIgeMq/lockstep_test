//
//  tcp.h
//  shoot
//
//  Created by 梁清风 on 16/4/8.
//
//

#ifndef tcp_h
#define tcp_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#ifdef __APPLE__
//#include <sys/malloc.h>
#else
#include <malloc.h>
#endif
#ifdef _WIN32
#include <winsock2.h>
#include <windows.h>
#include <process.h>
#include <ws2tcpip.h>
#else

#include <sys/time.h>
#include <netinet/tcp.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <pthread.h>
#endif
#include <sys/socket.h>

#include "thread_safe_link.h"

extern "C"{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}



#define LUA_SOCKETEVENT_TCP_BUFFER_SIZE			0x4000
#define LUA_SOCKETEVENT_TCP_MESSAGE_HEAD_SIZE		sizeof(Msg_Head)
#define LUA_SOCKETEVENT_TCP_MESSAGE_MAX_SIZE		0x100000
#define LUA_SOCKETEVENT_TCP_STATE_CONNECT		0x1
#define LUA_SOCKETEVENT_TCP_STATE_THREAD		0x2
#define LUA_SOCKETEVENT_TCP_STATE_CLOSE			0x4

#if defined(__APPLE__)
#define SOL_TCP IPPROTO_TCP
#endif

#ifdef _WIN32
#define pthread_t int
#endif
#pragma pack(1)
typedef struct msg_head{
    char	 head;
    short 	versions_id;//版本
    short 	SN; //顺序号
    int 	session_id;
    int		len;
    int 	msg_type;
}Msg_Head;
#pragma pack()




typedef struct lua_SocketEventTCP {
    // lua State
    lua_State *L;
    
    // state
    int state;
    
    // pthread
    pthread_t thread;
    
    // socket
    int socket;
    const char *host;
    const char *ip;
    lua_Integer port;
    
    // tcp option
    int keepalive;
    int keepidle;
    int keepintvl;
    int keepcnt;
    
    // action
    int connect_sync;
    int close_type;
    
    // data buffer
    
    int data_buffer_size;
    int data_buffer_use;
    char *data_buffer;
    
    Link* data_link;
    M_Node* temp_node;
    // message buffer
    Link* mssage_link;
    
    Link* free_link;
    
    // event
    int event_connect;
    int event_data;
    int event_close;
    int event_error;
    int event_message;
    
} LSocketEventTCP;

 void * socketevent_tcp();

void *socketevent_tcp_data(void* psock);


int socketevent_tcp_connect(void* psock ,const char * ip ,unsigned int port );


int socketevent_tcp_send_message(void* psock,const char* buff, unsigned int len);

int socketevent_tcp_close(void* psock);


M_Node* socketevent_recv(void* psock);


#endif /* tcp_h */
