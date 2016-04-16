//
//  kcp_client.h
//  shoot
//
//  Created by 梁清风 on 16/4/16.
//
//

#ifndef kcp_client_h
#define kcp_client_h

#include <stdio.h>
#include "kcp_socket.h"
int kcp_client_send(void * netObject, const char* buff, unsigned int len);
M_Node* kcp_client_recv(void * netObject);

#endif /* kcp_client_h */
