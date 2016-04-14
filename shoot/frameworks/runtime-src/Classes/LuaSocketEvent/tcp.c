                                                                                                                                          //
//  socketevent.c
//  LuaSocketEvent
//
//  Created by dotcoo on 2015/03/01.
//  Copyright (c) 2015 dotcoo. All rights reserved.
//

#define lsocketeventlib_c
#define LUA_LIB

//#include "lprefix.h"
#include "tcp.h"




#ifdef _WIN32

void socketevent_tcp_data_win(void *psock);

#pragma comment(lib,"ws2_32.lib")

#endif

// ==========

 void * socketevent_tcp() {
	// create tcp sock handle
	LSocketEventTCP *sock = (LSocketEventTCP *)malloc( sizeof(LSocketEventTCP));

	// state
	sock->state = 0;

	// pthread
	// sock->thread = -1;

	// socket
	sock->socket = -1;
	sock->host = NULL;
	sock->ip = NULL;
	sock->port = -1;

	// tcp option
	sock->keepalive = 1;
	sock->keepidle = 120;
	sock->keepintvl = 20;
	sock->keepcnt = 3;

	// action
	sock->connect_sync = 0;
	sock->close_type = 2;

	// data buffer
    sock->data_buffer_size = LUA_SOCKETEVENT_TCP_BUFFER_SIZE;
    sock->data_buffer_use = 0;
    sock->data_buffer = (char *)malloc(sock->data_buffer_size + 1);
    memset(sock->data_buffer, 0, sock->data_buffer_size + 1);
    sock->data_link = link_new(1);

	// message buffer
    sock->mssage_link =link_new(1);

    sock->free_link = link_new(1);
    sock->temp_node = NULL;

	return sock;
}





void *socketevent_tcp_data(void *psock) {
	// tcp sock struct
	LSocketEventTCP *sock = (LSocketEventTCP *)psock;

	// create new thread State
   
	// server address
	struct sockaddr_in server_addr;
	memset(&server_addr, 0, sizeof(server_addr));
	server_addr.sin_family = AF_INET;
	if (inet_pton(AF_INET, (const char *)sock->ip, &server_addr.sin_addr) <= 0) {
		return 0;
	}

	server_addr.sin_port = htons((u_short)sock->port);

	// connect to server
	if (connect(sock->socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
		return NULL;
	}
    M_Node* node = link_new_node(strlen("connected"));
    link_append_to_node(node,"connected", strlen("connected"));
    link_push(sock->mssage_link,  node);
    

	// recv data
	while (1) {

		sock->data_buffer_use += recv(sock->socket, sock->data_buffer+sock->data_buffer_use, sock->data_buffer_size-sock->data_buffer_use, 0);
		// check error
		if (sock->data_buffer_use == 0) {
			break;
		}
		if (sock->data_buffer_use < 0) {
//			socketevent_tcp_trigger_error(sock, L, __LINE__, errno, strerror(errno));
            printf("socket 断开");
			break;
		}

        int message_raw_len = 0; //总长含包头
        int break_while = 0;
        int message_len = 0; // 包体长
        int last_len = 0;
        int buff_pos = 0;
		// check message handle
		if (sock->event_message >= 0) {
			// packet splicing

			while (1) {
				// message len
                if (sock->data_buffer_use-buff_pos < LUA_SOCKETEVENT_TCP_MESSAGE_HEAD_SIZE) {
                    break;
                }

                if (!sock->temp_node ) {  //没有全接收完

                    message_len = ((Msg_Head*)(sock->data_buffer+buff_pos))->len;
                    message_raw_len = LUA_SOCKETEVENT_TCP_MESSAGE_HEAD_SIZE +message_len;
                    sock->temp_node = link_new_node(message_raw_len);
                    sock->temp_node->data_buffer_len = message_raw_len;
                }
                last_len =sock->temp_node->data_buffer_len-sock->temp_node->data_buffer_use;
                if (last_len > sock->data_buffer_use-buff_pos) {  //数据不够了
                    last_len = sock->data_buffer_use-buff_pos;

                }
                memcpy(sock->temp_node->data_buffer+sock->temp_node->data_buffer_use, sock->data_buffer+buff_pos,last_len);
                sock->temp_node->data_buffer_use += last_len;
                buff_pos+= last_len;
                if (sock->temp_node->data_buffer_use == sock->temp_node->data_buffer_len) {
                    int len =sock->temp_node->data_buffer_use;
                    M_Node* newNode = link_new_node(len);
                    link_append_to_node(newNode, sock->temp_node->data_buffer+LUA_SOCKETEVENT_TCP_MESSAGE_HEAD_SIZE, len);
                   link_push(sock->mssage_link, newNode);
                    link_free_node(sock->temp_node);
                    sock->temp_node = NULL;
                }

			}
			if (break_while) {
				break;
			}
            if (buff_pos>0) {
                memmove(sock->data_buffer, sock->data_buffer+buff_pos, sock->data_buffer_use-buff_pos);
                sock->data_buffer_use =sock->data_buffer_use-buff_pos;
            }
		}

	}

	// socket state
	sock->state = 2;

	return NULL;
}





#if defined(_WIN32)
void socketevent_tcp_data_win(void *psock) {
	socketevent_tcp_data(psock);
}
#endif

static int socketevent_tcp_setopt(void * psock) {
	// sock struct
	LSocketEventTCP *sock = (LSocketEventTCP *)psock;

	// get params

	return 1;
}

 int socketevent_tcp_connect(void* psock,const char* ip ,unsigned int port ) {
	// sock struct
    LSocketEventTCP *sock = (LSocketEventTCP*)psock;

	// check connect state
	if (sock->state != 0) {
		return 0;
	}
	sock->state++;

#if defined(_WIN32)
	WSADATA wsa;
	// WinSock Startup
	if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
		return 0;
	}
#endif

	sock->host = ip;
	if (-1 == inet_addr(ip)) {
		struct hostent *hostinfo;
		if ((hostinfo = (struct hostent*)gethostbyname(ip)) == NULL) {
			return 0;
		}
		if (hostinfo->h_addrtype == AF_INET && hostinfo->h_addr_list != NULL) {
#if defined(_WIN32)
			char ipstr[16];
			char * ipbyte = *(hostinfo->h_addr_list);
			sprintf(ipstr, "%d.%d.%d.%d", *ipbyte, *(ipbyte++), *(ipbyte+2), *(ipbyte+3));
			sock->ip = ipstr;
#else
			char ipstr[16];
			inet_ntop(hostinfo->h_addrtype, *(hostinfo->h_addr_list), ipstr, sizeof(ipstr));
			sock->ip = ipstr;
#endif
		} else {
			return 0;
		}
	} else {
		sock->ip = ip;
	}
	sock->port = port;

	// create socket
	if ((sock->socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		return 0;
	}
    int on = 1;
     setsockopt( sock->socket, IPPROTO_TCP, TCP_NODELAY, (void *)&on, sizeof(on));
     int reuse=1024*1024;
     socklen_t len=4;
     int size = 0;
     setsockopt(sock->socket, SOL_SOCKET, SO_RCVBUF,(void*)& reuse, sizeof(reuse));
     setsockopt(sock->socket, SOL_SOCKET, SO_SNDBUF,(void*)& reuse, sizeof(reuse));

     getsockopt(sock->socket, SOL_SOCKET, SO_SNDBUF,(void*)&size, &len);
     printf("send buff len = %d M",size);

//     getsockopt(sock->socket,SOL_SOCKET,SO_SNDBUF,(const char *)&reuse,sizeof(reuse));
#if defined(__linux__) || defined(__ANDROID__)
	// tcp option set
	if (sock->keepalive == 1) {
		if (setsockopt(sock->socket, SOL_SOCKET, SO_KEEPALIVE, (void *)&(sock->keepalive), sizeof(sock->keepalive)) < 0) {
			return 0;
		}
		if (setsockopt(sock->socket, SOL_TCP, TCP_KEEPIDLE, (void *)&(sock->keepidle), sizeof(sock->keepidle)) < 0) {
			return 0;
		}
		if (setsockopt(sock->socket, SOL_TCP, TCP_KEEPINTVL, (void *)&(sock->keepintvl), sizeof(sock->keepintvl)) < 0) {
			return 0;
		}
		if (setsockopt(sock->socket, SOL_TCP, TCP_KEEPCNT, (void *)&(sock->keepcnt), sizeof(sock->keepcnt)) < 0) {
			return 0;
		}
	}
#endif

	// start thread
#if defined(_WIN32)
	_beginthread(socketevent_tcp_data_win, 0, sock);
#else
	int retval = pthread_create(&sock->thread, NULL, socketevent_tcp_data, sock);
	if (retval != 0) {
		return 0;
	}
#endif

	return 1;
}



 int socketevent_tcp_send_message(void* psock,const char* buff, unsigned int len) {
	// sock struct
	LSocketEventTCP *sock = (LSocketEventTCP *)psock;

	// check connect state
	if (sock->state != 1) {
		return 0;
	}

	size_t message_raw_len = LUA_SOCKETEVENT_TCP_MESSAGE_HEAD_SIZE +len;
	char *message_buffer = (char *)malloc(message_raw_len + 1);
    ((Msg_Head*)message_buffer)->len =len;
    ((Msg_Head*)message_buffer)->head = '|';
    ((Msg_Head*)message_buffer)->msg_type = 10000;
     ((Msg_Head*)message_buffer)->session_id =0 ;
     ((Msg_Head*)message_buffer)->versions_id=0;//版本
     ((Msg_Head*)message_buffer)->SN=0; //顺序号


	message_buffer[message_raw_len] = 0;
	memcpy(message_buffer + LUA_SOCKETEVENT_TCP_MESSAGE_HEAD_SIZE, buff, len);

	// send message
	int retval = send(sock->socket, message_buffer, message_raw_len, 0);
	if (retval == -1) {
		free(message_buffer);
        
        
        
		return 0;
	}
     

	// free message_buffer
	free(message_buffer);

	return 1;
}

 int socketevent_tcp_close(void* psock) {
	// sock struct
	LSocketEventTCP *sock = (LSocketEventTCP *)psock;

	// check connect state
	if (sock->state != 1) {
		return 0;
	}

	// close socket
	switch (sock->close_type) {
#ifdef _WIN32
		case 1:
			shutdown(sock->socket, SD_RECEIVE);
			break;
		case 2:
			shutdown(sock->socket, SD_SEND);
			break;
		case 3:
			shutdown(sock->socket, SD_BOTH);
			break;
		default :
			closesocket(sock->socket);
			break;
#else
		case 1:
			shutdown(sock->socket, SHUT_RD);
			break;
		case 2:
			shutdown(sock->socket, SHUT_WR);
			break;
		case 3:
			shutdown(sock->socket, SHUT_RDWR);
			break;
		default :
			close(sock->socket);
			break;
#endif
	}

	return 1;
}


//static int socketevent_tcp_gc(lua_State *L) {
//	// sock struct
//	LSocketEventTCP *sock = (LSocketEventTCP *)luaL_checkudata(L, 1, LUA_SOCKETEVENT_TCP_HANDLE);
//
//	// close socket
//#ifdef _WIN32
//	closesocket(sock->socket);
//#else
//	close(sock->socket);
//	// shutdown(sock->socket, SHUT_RD);
//#endif
//
//	// exit thread
//#ifndef _WIN32
////	pthread_cancel(sock->thread);
//#endif
//
//	// free buffer
//	free((void *)sock->data_buffer);
//    link_free(sock->mssage_link);
//    link_free(sock->data_link);
//
//
//	return 0;
//}


 M_Node* socketevent_recv(void* psock){
    LSocketEventTCP *sock = (LSocketEventTCP *)psock;
//    printf("message_link node_count %d\n",sock->mssage_link->node_count);
     if (sock->mssage_link->node_count) {
         
        return link_pop(sock->mssage_link);
    }
    return NULL;
}




