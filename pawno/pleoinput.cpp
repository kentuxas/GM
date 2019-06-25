
#include <Windows.h>
#include "SDK\amx\amx.h"
#include "SDK\plugincommon.h"

typedef void (*logprintf_t)(char* format, ...);

logprintf_t logprintf;
extern void *pAMXFunctions;

cell* Buff;
POINT Cursor;
RECT Screen;

cell AMX_NATIVE_CALL GetVirtualKeyState(AMX* amx, cell* params)
{
	return GetAsyncKeyState(params[1]);
}

cell AMX_NATIVE_CALL GetScreenSize(AMX* amx, cell* params)
{
	GetWindowRect(GetDesktopWindow(), &Screen);
	amx_GetAddr(amx, params[1], &Buff);
	*Buff = amx_ftoc(Screen.right);
	amx_GetAddr(amx, params[2], &Buff);
	*Buff = amx_ftoc(Screen.bottom);
	return true;
}

cell AMX_NATIVE_CALL GetMousePos(AMX* amx, cell* params)
{
	GetCursorPos(&Cursor);
	amx_GetAddr(amx, params[1], &Buff);
	*Buff = amx_ftoc(Cursor.x);
	amx_GetAddr(amx, params[2], &Buff);
	*Buff = amx_ftoc(Cursor.y);
    return true;
}

PLUGIN_EXPORT unsigned int PLUGIN_CALL Supports() 
{
    return SUPPORTS_VERSION | SUPPORTS_AMX_NATIVES;
}

PLUGIN_EXPORT bool PLUGIN_CALL Load(void **ppData) 
{
    pAMXFunctions = ppData[PLUGIN_DATA_AMX_EXPORTS];
    logprintf = (logprintf_t) ppData[PLUGIN_DATA_LOGPRINTF];

    logprintf("\n* iTD Plugin loaded. (Support for textdraw editor mouse/keyboard)\n");
    return true;
}

PLUGIN_EXPORT void PLUGIN_CALL Unload()
{
    logprintf("* iTD Plugin unloaded.");
}

AMX_NATIVE_INFO PluginNatives[] =
{
	{"GetVirtualKeyState", GetVirtualKeyState},
	{"GetScreenSize", GetScreenSize},
    {"GetMousePos", GetMousePos},
    {0, 0}
};

PLUGIN_EXPORT int PLUGIN_CALL AmxLoad( AMX *amx ) 
{
    return amx_Register(amx, PluginNatives, -1);
}


PLUGIN_EXPORT int PLUGIN_CALL AmxUnload( AMX *amx ) 
{
    return AMX_ERR_NONE;
}