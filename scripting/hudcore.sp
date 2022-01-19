#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

Event
	g_hPanelEvent;
bool
	g_bIsPanelReplaced,
	g_bIsPanelBusy[MAXPLAYERS+1],
	g_bIsPBBusy[MAXPLAYERS+1];
char
	g_sPanelToken[1024];

Handle
	g_hTimers[MAXPLAYERS+1],
	g_hTimers2[MAXPLAYERS+1];

int
	m_flSimulationTime,
	m_flProgressBarStartTime,
	m_iProgressBarDuration,
	m_iBlockingUseActionInProgress;

//int m_hBombDefuser;


public Plugin myinfo =
{
	name = "Hud Core",
	author = "NickFox",
	description = "Core for hud text messages and not only.",
	version = "0.3",
	url = "https://vk.com/nf_dev"
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{
	CreateNative("HC_AddEndPanelInfo", Native_AddEndPanelInfo);
	CreateNative("HC_ShowPanelInfo", Native_ShowPanelInfo);
	CreateNative("HC_ShowPanelStatus", Native_ShowPanelStatus);
	
	CreateNative("HC_ShowTimer", Native_ShowTimer);
	CreateNative("HC_ResetTimer", Native_ResetTimer);
	CreateNative("HC_IsPBBusy", Native_IsPBBusy);

	RegPluginLibrary("hudcore");

	return APLRes_Success;
}

public int Native_AddEndPanelInfo(Handle hPlugin, int iNumParams)
{
	char text[1024];	
	GetNativeString(1,text,sizeof(text));
	AddEndPanelInfo(text);
}

public int Native_ShowPanelInfo(Handle hPlugin, int iNumParams)
{
	char text[1024];
	GetNativeString(2,text,sizeof(text));
	ShowPanelInfo(GetNativeCell(1), text,GetNativeCell(3));
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
	
	m_flSimulationTime = FindSendPropInfo("CBaseEntity", "m_flSimulationTime");
	m_flProgressBarStartTime = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime");
	m_iProgressBarDuration = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration");
	m_iBlockingUseActionInProgress = FindSendPropInfo("CCSPlayer", "m_iBlockingUseActionInProgress");
}

public void OnPluginEnd()
{
	//UnhookEvent("cs_win_panel_round",OnPanelEvent,EventHookMode_Pre);
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
			if(g_bIsPanelBusy[i]) delete g_hTimers[i];
			else g_bIsPanelBusy[i] = true;
			g_hTimers[i] = CreateTimer(duration, Timer_DelayHide, i);
		}
	}
	else
	{
		hPanelEvent.FireToClient(client);
		if(g_bIsPanelBusy[client]) delete g_hTimers[client];
		else g_bIsPanelBusy[client] = true;
		g_hTimers[client] = CreateTimer(duration, Timer_DelayHide, client);
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

void AddEndPanelInfo(const char[] sText)
{	
	if(!g_bIsPanelReplaced)
	{
		FormatEx(g_sPanelToken, sizeof(g_sPanelToken),"%s", sText);
		g_bIsPanelReplaced = true;
	}
	else Format(g_sPanelToken, sizeof(g_sPanelToken),"%s\n%s", sText, g_sPanelToken);	
}


public Action OnPanelEvent(Event hEvent,const char[] name, bool dontBroadcast)
{
	g_hPanelEvent = CreateEvent("cs_win_panel_round", true);
	
	g_hPanelEvent.SetBool("show_timer_defend", hEvent.GetBool("show_timer_defend"));
	g_hPanelEvent.SetBool("show_timer_attack", hEvent.GetBool("show_timer_attack"));
	g_hPanelEvent.SetInt("timer_time",hEvent.GetInt("timer_time"));
	g_hPanelEvent.SetInt("final_event",hEvent.GetInt("final_event"));
		
	hEvent.GetString("funfact_token", g_sPanelToken, sizeof(g_sPanelToken));
	
	g_hPanelEvent.SetInt("funfact_player", hEvent.GetInt("funfact_player"));
	g_hPanelEvent.SetInt("funfact_data1", hEvent.GetInt("funfact_data1"));
	g_hPanelEvent.SetInt("funfact_data2", hEvent.GetInt("funfact_data2"));
	g_hPanelEvent.SetInt("funfact_data3", hEvent.GetInt("funfact_data3"));	
		
	CreateTimer(0.3,Timer_DelayPanel);
	dontBroadcast = true;
	return Plugin_Handled;
}

Action Timer_DelayPanel(Handle timer)
{
	g_hPanelEvent.SetString("funfact_token", g_sPanelToken);
	
	for(int i = 1; i < MAXPLAYERS; i++) if(IsClientInGame(i) && !IsFakeClient(i)) g_hPanelEvent.FireToClient(i);
	
	g_bIsPanelReplaced = false;
	
	g_hPanelEvent.Cancel();
}

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
	SetEntData(iClient, m_iBlockingUseActionInProgress, 0, 4, true);
	SetEntDataFloat(iClient, m_flSimulationTime, flGameTime + fTime, true);
	SetEntData(iClient, m_iProgressBarDuration, RoundToCeil(fTime),  4, true);
	SetEntDataFloat(iClient, m_flProgressBarStartTime, flGameTime, true);
	
	//SetEntData(iClient, m_hBombDefuser, 0, 4, true);
}

public bool ShowPB(int iClient, float fTime){

	if(g_bIsPBBusy[iClient]) return false;	
	
	SetInfoPB(iClient,fTime);
	
	g_hTimers2[iClient] = CreateTimer(fTime,Timer_Reset,iClient);
	
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
	
	delete g_hTimers2[iClient];
	
	return true;

}
