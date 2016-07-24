//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadCostPanel_RemotePlayer.uc
//  AUTHOR:  Todd Smith  --  8/17/2015
//  PURPOSE: Functionality/UI for X2 that was taken from the old UIMultiplayerLoadout_RemotePlayerInfo
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadCostPanel_RemotePlayer extends UIMPShell_SquadCostPanel;

var XComMPLobbyGRI              m_kGRI;

var X2MPShellManager            m_kMPShellManager;
var XComGameStateNetworkManager NetworkMgr;
var XComGameStateHistory                History;
var XComGameState               m_kLoadoutGameState;            // Stores everything (units, items, etc) for the loadout.
var StateObjectReference        m_kRemotePlayerGameStateRef;    // GameState Ref for the current player



function InitRemotePlayerSquadCostPanel(X2MPShellManager kShellManager)
{
	m_kMPShellManager = kShellManager;
	History = `XCOMHISTORY;

	InitSquadCostPanel( m_kMPShellManager.OnlineGame_GetMaxSquadCost(), m_kLoadoutGameState, "");

	SubscribeToOnCleanupWorld();

	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.AddReceiveGameStateDelegate(OnReceiveGameState);
	NetworkMgr.AddReceiveMergeGameStateDelegate(OnReceiveMergeGameState);
	NetworkMgr.AddNotifyConnectionClosedDelegate(OnConnectionClosed);

	Hide();
}

function setPointMeters(string strPlayerGamertag, string strPlayerTotal, string strPlayerMax, string strPlayerpointTotal, int numPlayerMeter)
{
	MC.FunctionVoid("setOpponentColor");
	super.setPointMeters( strPlayerGamertag, strPlayerTotal, strPlayerMax, strPlayerpointTotal, numPlayerMeter );
}

simulated function OnInit()
{
	`log(`location,,'XCom_Online');
	super.OnInit();
	
	m_kGRI = XComMPLobbyGRI(WorldInfo.GRI);

	RefreshData();
}

function InitPlayer(ETeam TeamRegister)
{
	local XComGameState_Player kPlayerState;

	m_kRemotePlayerGameStateRef.ObjectID = 0;
	foreach History.IterateByClassType(class'XComGameState_Player', kPlayerState)
	{
		if (kPlayerState.GetTeam() == TeamRegister)
		{
			m_kRemotePlayerGameStateRef = kPlayerState.GetReference();
			break;
		}
	}
}

function XComGameState_Player GetPlayerGameState()
{
	return XComGameState_Player(History.GetGameStateForObjectID(m_kRemotePlayerGameStateRef.ObjectID));
}

function XComGameState GetLoadoutGameState()
{
	return m_kLoadoutGameState;
}

function SetLoadoutGameState(XComGameState NewLoadoutState)
{
	if (XComGameStateContext_SquadSelect(NewLoadoutState.GetContext()) != none)
	{
		m_kLoadoutGameState = NewLoadoutState;
	}
}

function OnReceiveGameState(XComGameState GameState)
{
	`log(`location @ `ShowVar(GameState),,'XCom_Online');
	Show();
	SetLoadoutGameState(GameState);
	RefreshData();
}

function OnReceiveMergeGameState(XComGameState GameState)
{
	`log(`location @ `ShowVar(GameState) @ GetPlayerGameState().ToString(),,'XCom_Online');
	Show();
	SetLoadoutGameState(GameState);
	RefreshDisplay();
}

function OnConnectionClosed(int ConnectionIdx)
{
	Hide();
}


function ResetRemotePRI()
{
	m_kRemotePlayerGameStateRef.ObjectID = 0;
	RefreshData();
}

function RefreshData()
{
	RefreshDisplay();
}

function RefreshDisplay()
{
	local XComGameState_Player RemotePlayerState;
	RemotePlayerState = GetPlayerGameState();

	if(NetworkMgr.Connections.Length > 0 && RemotePlayerState != none)
	{
		`log( `location @ `ShowVar(RemotePlayerState.PlayerName) @ `ShowVar(RemotePlayerState.bPlayerReady) @ `ShowVar(RemotePlayerState.SquadPointValue)@ `ShowVar(RemotePlayerState.SquadName),,'XCom_Online');
	
		SetPlayerName(RemotePlayerState.PlayerName);
		m_bMicAvailable = RemotePlayerState.MicAvailable;
		
		SetPlayerLoadout(m_kLoadoutGameState);
		m_iSquadCost = RemotePlayerState.SquadPointValue;
		if(RemotePlayerState.SquadName != "")
			m_strLoadoutName = RemotePlayerState.SquadName;
		if(RemotePlayerState.bPlayerReady)
		{
			StatusText.SetText(m_strMPLoadout_RemotePlayerInfo_Ready);
			
			MC.BeginFunctionOp("setReady");
			MC.QueueBoolean(true);
			MC.QueueString(m_strMPLoadout_RemotePlayerInfo_Ready);
			MC.EndOp();
		}
		else
		{
			StatusText.SetText(m_strMPLoadout_RemotePlayerInfo_NotReady);
			
			MC.BeginFunctionOp("setReady");
			MC.QueueBoolean(false);
			MC.QueueString(m_strLoadoutName);
			MC.EndOp();
		}

		Show();
	}
	else
	{
		Hide();
	}

	UpdateSquadCostText();
}


simulated event OnCleanupWorld()
{
	Cleanup();

	super.OnCleanupWorld();
}

simulated event Destroyed() 
{
	UnsubscribeFromOnCleanupWorld();
	Cleanup();

	super.Destroyed();
}

function Cleanup()
{
	NetworkMgr.ClearReceiveGameStateDelegate(OnReceiveGameState);
	NetworkMgr.ClearReceiveMergeGameStateDelegate(OnReceiveMergeGameState);
	NetworkMgr.ClearNotifyConnectionClosedDelegate(OnConnectionClosed);
}
