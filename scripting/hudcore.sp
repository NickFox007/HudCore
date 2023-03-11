#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

bool
	g_bIsPanelBusy[MAXPLAYERS+1],
	g_bIsPBBusy[MAXPLAYERS+1];

Handle
	g_hPanelTimers[MAXPLAYERS+1],
	g_hBarTimers[MAXPLAYERS+1];

int
	m_flSimulationTime,
	m_flProgressBarStartTime,
	m_iProgressBarDuration,
	m_iBlockingUseActionInProgress;
	
Handle
	g_hFwdOnPanel;
	
char
	g_sNewText[8096];
	
//int m_hBombDefuser;

public Plugin myinfo =
{
	name = "Hud Core",
	author = "NickFox",
	description = "Core for hud text messages and not only.",
	version = "0.4",
	url = "https://vk.com/nf_dev"
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{
	CreateNative("HC_AddEndPanelText", Native_AddEndPanelText);
	CreateNative("HC_ShowPanelInfo", Native_ShowPanelInfo);
	CreateNative("HC_ShowPanelStatus", Native_ShowPanelStatus);
	
	CreateNative("HC_ShowTimer", Native_ShowTimer);
	CreateNative("HC_ResetTimer", Native_ResetTimer);
	CreateNative("HC_IsPBBusy", Native_IsPBBusy);
	
	g_hFwdOnPanel = CreateGlobalForward("HC_OnPanel", ET_Hook, Param_String, Param_Cell);

	RegPluginLibrary("hudcore");

	return APLRes_Success;
}

public int Native_ShowPanelInfo(Handle hPlugin, int iNumParams)
{
	char text[1024];
	GetNativeString(2,text,sizeof(text));
	ShowPanelInfo(GetNativeCell(1), text,GetNativeCell(3));
}

public int Native_AddEndPanelText(Handle hPlugin, int iNumParams)
{
	char text[4096];
	GetNativeString(1,text,sizeof(text));
	if(g_sNewText[0] == '\0') FormatEx(g_sNewText, sizeof(g_sNewText), "%s", text);
	else Format(g_sNewText, sizeof(g_sNewText), "%s<br>%s", g_sNewText, text);
}

public int Native_ShowPanelStatus(Handle hPlugin, int iNumParams)
{
	char text[1024];
	GetNativeString(2,text,sizeof(text));
	ShowPanelStatus(GetNativeCell(1), text,GetNativeCell(3));
}

public void OnPluginStart()
{
	HookEvent("cs_win_panel_round",OnPanelEvent,EventHookMode_Pre);
	HookEvent("player_death",OnDeathEvent,EventHookMode_Pre);
	
	m_flSimulationTime = FindSendPropInfo("CBaseEntity", "m_flSimulationTime");
	m_flProgressBarStartTime = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime");
	m_iProgressBarDuration = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration");
	m_iBlockingUseActionInProgress = FindSendPropInfo("CCSPlayer", "m_iBlockingUseActionInProgress");
}

void ShowPanelInfo(int client, const char[] text, float duration)
{
	Event hPanelEvent = CreateEvent("cs_win_panel_round", true);
	
	hPanelEvent.SetString("funfact_token", text);
	
	if(client == -1)
	{
		for(int i = 1; i < MAXPLAYERS; i++) if(IsClientInGame(i) && !IsFakeClient(i))
		{
			hPanelEvent.FireToClient(i);
			if(g_bIsPanelBusy[i]) delete g_hPanelTimers[i];
			else g_bIsPanelBusy[i] = true;
			g_hPanelTimers[i] = CreateTimer(duration, Timer_DelayHide, i);
		}
	}
	else
	{
		hPanelEvent.FireToClient(client);
		if(g_bIsPanelBusy[client]) delete g_hPanelTimers[client];
		else g_bIsPanelBusy[client] = true;
		g_hPanelTimers[client] = CreateTimer(duration, Timer_DelayHide, client);
	}	
	hPanelEvent.Cancel();	
}

void ShowPanelStatus(int client, const char[] text, int duration)
{
	Event hEvent = CreateEvent("show_survival_respawn_status", true);
	hEvent.SetString("loc_token", text);
	hEvent.SetInt("duration", duration);
	//hEvent.SetInt("userid", GetClientUserId(1));
	
	if(client == -1)
	{
		for(int i = 1; i < MAXPLAYERS; i++) if(IsClientInGame(i) && !IsFakeClient(i))
		{
			hEvent.SetInt("userid", GetClientUserId(i));
			hEvent.FireToClient(i);
		}
	}
	else
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.FireToClient(client);
	}	
	hEvent.Cancel();	
}

public void OnClientDisconnect(int iClient)
{
	if(g_hBarTimers[iClient] != INVALID_HANDLE) KillTimer(g_hBarTimers[iClient]);
	g_hBarTimers[iClient] = INVALID_HANDLE;
}


public Action OnDeathEvent(Event hEvent,const char[] name, bool dontBroadcast)
{
	int iClient = GetClientUserId(hEvent.GetBool("userid"));
	if(g_hBarTimers[iClient] != INVALID_HANDLE) TriggerTimer(g_hBarTimers[iClient]);
}


public Action OnPanelEvent(Event hEvent,const char[] name, bool dontBroadcast)
{	
	g_sNewText[0] = '\0';
	if (CallGlobalPanelForward())	
	{
		/*
		Event hPanelEvent = CreateEvent("cs_win_panel_round", true);
	
		hPanelEvent.SetBool("show_timer_defend", hEvent.GetBool("show_timer_defend"));
		hPanelEvent.SetBool("show_timer_attack", hEvent.GetBool("show_timer_attack"));
		hPanelEvent.SetInt("timer_time",hEvent.GetInt("timer_time"));
		hPanelEvent.SetInt("final_event",hEvent.GetInt("final_event"));
			
		hPanelEvent.SetString("funfact_token", g_sNewText);
		
		hPanelEvent.SetInt("funfact_player", hEvent.GetInt("funfact_player"));
		hPanelEvent.SetInt("funfact_data1", hEvent.GetInt("funfact_data1"));
		hPanelEvent.SetInt("funfact_data2", hEvent.GetInt("funfact_data2"));
		hPanelEvent.SetInt("funfact_data3", hEvent.GetInt("funfact_data3"));	
		
		hPanelEvent.Fire(true);		
		
		//dontBroadcast = true;
		hEvent.BroadcastDisabled = true;
		*/
		Format(g_sNewText, sizeof(g_sNewText), "<pre>%s</pre>", g_sNewText);
		hEvent.SetString("funfact_token", g_sNewText);
		return Plugin_Changed;
	}
	else
		return Plugin_Continue;
}


bool CallGlobalPanelForward()
{
	Action iResult;
	
	Call_StartForward(g_hFwdOnPanel);
	Call_Finish(iResult);
	
	if(iResult == Plugin_Changed) return true;
	else return false;
}

/*
Action Timer_DelayPanel(Handle timer)
{
	g_hPanelEvent.SetString("funfact_token", g_sPanelToken);
	
	for(int i = 1; i < MAXPLAYERS; i++) if(IsClientInGame(i) && !IsFakeClient(i)) g_hPanelEvent.FireToClient(i);
	
	g_bIsPanelReplaced = false;
	
	g_hPanelEvent.Cancel();
}
*/

Action Timer_DelayHide(Handle timer, int client)
{
	g_bIsPanelBusy[client] = false;
	
	Event hPanelEvent = CreateEvent("cs_win_panel_round", true);
	
	hPanelEvent.SetString("funfact_token", "");
	
	hPanelEvent.FireToClient(client);
	
	hPanelEvent.Cancel();
}


public int Native_ShowTimer(Handle hPlugin, int iNumParams)
{   
	int iClient = GetNativeCell(1);
	float fTime = GetNativeCell(2);
	return ShowPB(iClient,fTime);
}

public int Native_ResetTimer(Handle hPlugin, int iNumParams)
{   
    int iClient = GetNativeCell(1);
    return ResetPB(iClient);
}

public int Native_IsPBBusy(Handle hPlugin, int iNumParams)
{   
    int iClient = GetNativeCell(1);
    return g_bIsPBBusy[iClient];
}

void SetInfoPB(int iClient, float fTime){

	float flGameTime = GetGameTime();	
	SetEntDataFloat(iClient, m_flSimulationTime, flGameTime + fTime, true);
	SetEntData(iClient, m_iBlockingUseActionInProgress, 0, 4, true);
	SetEntData(iClient, m_iProgressBarDuration, RoundToCeil(fTime),  4, true);
	SetEntDataFloat(iClient, m_flProgressBarStartTime, flGameTime, true);	
	
	
	
	//ChangeEdictState(iClient, m_iBlockingUseActionInProgress);
	
	//SetEntData(iClient, m_hBombDefuser, 0, 4, true);
}

public bool ShowPB(int iClient, float fTime){

	if(g_bIsPBBusy[iClient]) return false;	
	
	SetInfoPB(iClient,fTime);
	
	g_hBarTimers[iClient] = CreateTimer(fTime,Timer_Reset,iClient);
	
	g_bIsPBBusy[iClient] = true;
	return true;
}

Action Timer_Reset(Handle hTimer, int iClient){
	ResetPB(iClient);
}

public bool ResetPB(int iClient){
	
	if(!g_bIsPBBusy[iClient]) return false;
	
	SetInfoPB(iClient,0.0);
	
	g_bIsPBBusy[iClient] = false;
	
	//delete g_hBarTimers[iClient];
	
	g_hBarTimers[iClient] = INVALID_HANDLE;
	
	return true;

}