//
//  pbc-lua.h
//  shoot
//
//  Created by 梁清风 on 16/3/17.
//
//

#ifndef pbc_lua_h
#define pbc_lua_h

#ifdef __cplusplus
extern "C" {
#endif
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#ifdef __cplusplus
}
#endif

int luaopen_protobuf_c(lua_State *L);

#endif /* pbc_lua_h */
