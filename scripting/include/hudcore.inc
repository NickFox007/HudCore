#if defined _hudcore_included
    #endinput
#endif
#define _hudcore_included  


native void HC_AddEndPanelText(const char[] text);

native void HC_ShowPanelInfo(int client, const char[] text, float duration);
native void HC_ShowPanelStatus(int client, const char[] text, int duration);

native bool HC_ShowTimer(int iClient, float fTime);
native bool HC_ResetTimer(int iClient);
native bool HC_IsBusy(int iClient);

forward Action HC_OnPanel();

public SharedPlugin __pl_hudcore = 
{
	name = "hudcore",
	file = "hudcore.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};


#if !defined REQUIRE_PLUGIN
public void __pl_hudcore_SetNTVOptional()
{
	MarkNativeAsOptional("HC_AddEndPanelInfo");
	MarkNativeAsOptional("HC_ShowPanelInfo");
	MarkNativeAsOptional("HC_ShowPanelStatus");
	MarkNativeAsOptional("HC_ShowTimer");
	MarkNativeAsOptional("HC_ResetTimer");
	MarkNativeAsOptional("HC_IsBusy");
}
#endif