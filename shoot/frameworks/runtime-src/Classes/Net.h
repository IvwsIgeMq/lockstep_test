//
//  Net.hpp
//  shoot
//
//  Created by 梁清风 on 16/4/1.
//
//

#ifndef Net_hpp
#define Net_hpp

#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef __cplusplus
}
#endif

#include "thread_safe_link.h"
#include "tcp.h"
//extern "C++"{
    #include "udt.h"
//}


typedef int (sendFunc)(void * netObject, const char* buff, unsigned int len);
typedef M_Node *(recvFunc)(void * netObject);
typedef int (connectFunc)(void * netObject,const char* ip, unsigned int port);
typedef int (closeFunc)(void * netObject);

typedef enum {
    S_close,
    S_connecting,
    S_connected,
    S_closing,
}netState;

typedef struct {
    char netType[32];
    char ip[32];
    unsigned int port ;
    netState stat;
    void * netObject;
    sendFunc* send;
    recvFunc* recv;
    connectFunc* connect;
    closeFunc* close;
    long long time_ms;
    
}Net;

int luaopen_Net(lua_State *L);


#endif /* Net_hpp */
