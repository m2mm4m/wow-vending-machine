#include lua.ahk
#include lua_ahkfunctions.ahk
#SingleInstance, force

if (A_IsUnicode) {
	MsgBox This script can only be used with AutoHotKey_L ANSI
	ExitApp
}

hDll := lua_loadDll("lua51.dll")
L := luaL_newstate()
OnExit, OnExit
luaL_openlibs(L)
lua_registerAhkFunction(L)

luaL_dofile(L, "..\WoWDriver.lua")
if lua_isstring(L,-1) {
	MsgBox % "Error: " . lua_tostring(L,-1)
}
; ExitApp
return

OnExit:
	lua_close(L)
	lua_UnloadDll(hDll)
	ExitApp
Return

WoWDrv_LuaCallback(ref) {
	Global L
	lua_getglobal(L,"AHKCallbackFunc")
	lua_pushstring(L,ref)
	lua_call(L,1,0)
	ret:=lua_tointeger(L,-1)
	lua_pop(L, 1)
	return ret
}

WoWDrv_Timer1:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer2:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer3:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer4:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer5:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer6:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer7:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer8:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer9:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer10:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer11:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer12:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer13:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer14:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer15:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer16:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer17:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer18:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer19:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
WoWDrv_Timer20:
	WoWDrv_LuaCallback(A_ThisLabel)
Return
