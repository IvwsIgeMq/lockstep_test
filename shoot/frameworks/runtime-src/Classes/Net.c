//
//  Net.cpp
//  shoot
//
//  Created by 梁清风 on 16/4/1.
//
//

#include "Net.h"



#define NetLib "Net*"

/* get system time */
static inline void itimeofday(long *sec, long *usec)
{
#if defined(__unix)|| defined(__linux__) || defined(__ANDROID__) || defined(__APPLE__)
    struct timeval time;
    gettimeofday(&time, NULL);
    if (sec) *sec = time.tv_sec;
    if (usec) *usec = time.tv_usec;
#else
    static long mode = 0, addsec = 0;
    BOOL retval;
    static IINT64 freq = 1;
    IINT64 qpc;
    if (mode == 0) {
        retval = QueryPerformanceFrequency((LARGE_INTEGER*)&freq);
        freq = (freq == 0) ? 1 : freq;
        retval = QueryPerformanceCounter((LARGE_INTEGER*)&qpc);
        addsec = (long)time(NULL);
        addsec = addsec - (long)((qpc / freq) & 0x7fffffff);
        mode = 1;
    }
    retval = QueryPerformanceCounter((LARGE_INTEGER*)&qpc);
    retval = retval * 2;
    if (sec) *sec = (long)(qpc / freq) + addsec;
    if (usec) *usec = (long)((qpc % freq) * 1000000 / freq);
#endif
}

static int l_net_Net(lua_State* L)
{
    int argc = lua_gettop(L);
    if (argc != 1 ) {
        luaL_error(L, "请设置联接类型['tcp','udt','kcp']");
        return 0;
    }
    const char * type =luaL_checkstring(L, 1);
    Net* pNet = (Net*)lua_newuserdata(L,sizeof(Net));
#if LUA_VERSION_NUM == 501
    luaL_getmetatable(L,NetLib);
    lua_setmetatable(L, -2);
#else
    luaL_setmetatable(L, NetLib);
#endif
    
    if (strcmp(type , "tcp") == 0) {
        pNet->netObject = socketevent_tcp();
        pNet->connect = socketevent_tcp_connect;
        pNet->send = socketevent_tcp_send_message;
        pNet->recv = socketevent_recv;
        pNet->close = socketevent_tcp_close;
        
    }else if (strcmp(type , "udt")== 0 ) {
    
    }else if (strcmp(type, "kcp")==0){
        
    }else{
        luaL_error(L, "没有指定联接类型 %s",type);
        return 0;
    }
    memcpy(pNet->netType,type,strlen(type));
    return 1;
}
static int l_net_setopt(lua_State* L)
{
    return 0;
}

static int l_net_connect(lua_State* L)
{
    int argc = lua_gettop(L);
    if (argc != 3 ) {
        luaL_error(L, "net.connect 参数个数不对 net.connect(type,ip,port)");
    }
    Net* pNet = (Net*)luaL_checkudata(L, 1, "Net*");
    const char *ip = luaL_checkstring(L, 2);
    lua_Integer port = luaL_checkinteger(L, 3);
    pNet->connect(pNet->netObject,ip,port);
    return 0;
}
static int l_net_send(lua_State* L)
{
    int argc = lua_gettop(L);
    if (argc <2 ) {
        luaL_error(L, "net.connect 参数个数不对 net.connect(type,ip,port)");
        return 0;
    }
    Net* pNet = (Net*)luaL_checkudata(L, 1, "Net*");
    unsigned int len = lua_strlen(L, 2);
    const char*  buff = luaL_checkstring(L, 2);
    pNet->send(pNet->netObject,buff,len);
    return 0;

}
static int l_net_recv(lua_State* L)
{
    int argc = lua_gettop(L);
    if (argc >2 ) {
        luaL_error(L, "net:recv() 参数个数不对 net:recv()");
        return 0;
    }
    
     Net* pNet = (Net*)luaL_checkudata(L, 1, "Net*");
    long interval_ms = 0;
    if (argc ==2){
        interval_ms = luaL_checkinteger(L, 2);
    }
    long now_sec,now_usec;
    itimeofday(&now_sec,&now_usec);
    long long now_time_ms = ((long long)now_sec) * 1000 + (now_usec / 1000);
    if((now_time_ms-pNet->time_ms )< interval_ms)
        return 0;

    M_Node* node = pNet->recv(pNet->netObject);
    if (!node) {
        return 0;
    }
    pNet->time_ms = now_time_ms;
    lua_pushlstring(L,node->data_buffer,node->data_buffer_use);
    return 1;

}
static int l_net_close(lua_State* L)
{
    int argc = lua_gettop(L);
    if (argc !=1 ) {
        luaL_error(L, "net:close() 参数个数不对 net:close()");
        return 0;
    }
    Net* pNet = (Net*)luaL_checkudata(L, 1, "Net*");
    pNet->close(pNet->netObject);
    return 0;
}
static int l_net_gc(lua_State* L)
{
    Net* pNet = (Net*)luaL_checkudata(L, 1, "Net*");
    pNet->close(pNet->netObject);
    return 0;
}
static int l_net_tostring(lua_State* L)
{
    return 0;
}

static const luaL_Reg net[] = {
	{ "Net", l_net_Net },
	{ NULL, NULL }
};

static const luaL_Reg netlib[] = {
	{ "setopt", l_net_setopt },
	{ "connect", l_net_connect },
	{ "send", l_net_send },
    {"recv",l_net_recv},
	{ "close", l_net_close },
	{ "__gc", l_net_gc },
	{ "__tostring", l_net_tostring },
	{ NULL, NULL }
};

int luaopen_Net(lua_State *L)
{
	#if LUA_VERSION_NUM == 501
		// create tcp metatable
		luaL_newmetatable(L, NetLib);
		lua_pushvalue(L, -1);
		lua_setfield(L, -2, "__index");
		luaL_register(L, NULL, netlib);

		// create lib
		luaL_register(L, "Net", net);
	#else
		// create lib
		luaL_newlib(L, net);

		// create tcp metatable
		luaL_newmetatable(L, NetLib);
		lua_pushvalue(L, -1);
		lua_setfield(L, -2, "__index");
		luaL_setfuncs(L, netlib, 0);
		lua_pop(L, 1);
	#endif

		return 1;
}
