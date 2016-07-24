//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadCostPanel_LocalPlayer.uc
//  AUTHOR:  Todd Smith  --  8/17/2015
//  PURPOSE: Functionality/UI for X2 that was taken from the old UIMultiplayerLoadout_LocalPlayerInfo
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadCostPanel_LocalPlayer extends UIMPShell_SquadCostPanel
	dependson(XComOnlineStatsUtils);


var XComMPLobbyPRI              m_kLocalPRI;
var XComMPLobbyGRI              m_kGRI;
var XComGameStateHistory                History;
var X2MPShellManager            m_kMPShellManager;
var XComGameState               m_kLoadoutGameState;            // Stores everything (units, items, etc) for the loadout.
var XComGameState_Player        m_kLoadoutPlayerGameState;      // GameState data for the temporarily generated player for Loadouts.
var StateObjectReference        m_kLocalPlayerGameStateRef;     // GameState Ref for the current player
//var array<XComGameState_Unit>   m_arrUnitLoadouts;              // GameState Ref for every unit, still need to look at the LoadoutGameState for all information.

function InitLocalPlayerSquadCostPanel(X2MPShellManager kShellManager, XComGameState kLoadoutGameState)
{
	local XComOnlineEventMgr kEventMgr;
	local int maxSquadCost;
	m_kMPShellManager = kShellManager;
	m_kLoadoutGameState = kLoadoutGameState;

	kEventMgr = `ONLINEEVENTMGR;
	History = `XCOMHISTORY;

	m_kLocalPRI = XComMPLobbyPRI(GetALocalPlayerController().PlayerReplicationInfo);
	kEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_kUniqueID = m_kLocalPRI.UniqueId;
	kEventMgr.FillPRIFromLastMatchPlayerInfo(kEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo, m_kLocalPRI);
	m_kLocalPRI.SetPlayerLanguageSettings(GetLanguage(),`XPROFILESETTINGS.Data.m_bForeignLanguages);
	m_kGRI = XComMPLobbyGRI(WorldInfo.GRI);

	if(m_kGRI != none)
	{
		maxSquadCost = m_kGRI.m_iMPMaxSquadCost;
		if( m_kGRI.m_iMPMaxSquadCost < 0)
			maxSquadCost = class'X2MPData_Common'.const.INFINITE_VALUE;
	}
	else
	{
		maxSquadCost = class'X2MPData_Common'.const.INFINITE_VALUE;
	}

	super.InitSquadCostPanel(maxSquadCost, m_kLoadoutGameState, m_kLocalPRI.PlayerName);
}

simulated function OnInit()
{
	super.OnInit();

	MC.FunctionVoid("setPlayerColor");
}

function bool TogglePlayerReady()
{
	m_kLoadoutPlayerGameState.bPlayerReady = !m_kLoadoutPlayerGameState.bPlayerReady;
	if(m_kLoadoutPlayerGameState.bPlayerReady)
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

	return m_kLoadoutPlayerGameState.bPlayerReady;
}

function bool GetPlayerReady()
{
	if(m_kLoadoutPlayerGameState != none)
		return m_kLoadoutPlayerGameState.bPlayerReady;

	return false;
}

function XComGameState GetLoadoutGameState()
{
	return m_kLoadoutGameState;
}

function InitPlayer(ETeam eTeamRegister, XComGameState kLoadoutState)
{
	local XComGameState_Player kPlayerState;

	m_kLocalPlayerGameStateRef.ObjectID = 0;
	foreach History.IterateByClassType(class'XComGameState_Player', kPlayerState)
	{
		if (kPlayerState.GetTeam() == eTeamRegister)
		{
			m_kLocalPlayerGameStateRef = kPlayerState.GetReference();
			m_kLoadoutPlayerGameState = kPlayerState;
			SetLoadoutGameState(kLoadoutState);
			UpdateLocalPlayerDataToGameState(kPlayerState);
			ConvertRankedStatsFromPRIToGameState(m_kLocalPRI, kPlayerState);
			break;
		}
	}
	m_kLoadoutPlayerGameState.PlayerName = m_kLocalPRI.PlayerName;
	SetPlayerName(m_kLoadoutPlayerGameState.PlayerName);
}

function UpdateLocalPlayerDataToGameState(XComGameState_Player kPlayerState)
{
	ConvertRankedStatsFromPRIToGameState(m_kLocalPRI, kPlayerState);
	kPlayerState.SetGameStatePlayerNetId(m_kLocalPRI.UniqueId);
	kPlayerState.SetGameStatePlayerName(m_kLocalPRI.PlayerName);
	kPlayerState.CalcSquadPointValueFromGameState(m_kLoadoutGameState);
	kPlayerState.bPlayerReady = m_kLoadoutPlayerGameState.bPlayerReady;
	kPlayerState.MicAvailable = m_bMicAvailable;
}

function SetLoadoutGameState(XComGameState NewLoadoutState)
{
	if (XComGameStateContext_SquadSelect(NewLoadoutState.GetContext()) != none)
	{
		m_kLoadoutGameState = NewLoadoutState;
	}
	
	SetPlayerLoadout(m_kLoadoutGameState);
}

function setPointMeters(string strPlayerGamertag, string strPlayerTotal, string strPlayerMax, string strPlayerpointTotal, int numPlayerMeter)
{
	MC.FunctionVoid("setPlayerColor");
	super.setPointMeters( strPlayerGamertag, strPlayerTotal, strPlayerMax, strPlayerpointTotal, numPlayerMeter );
}

function XComGameState CreateUpdateGameStatePlayer()
{
	local XComGameState NewGameState;
	local XComGameState_Player NewPlayerState;
	local UniqueNetId NewPlayerStateId;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Network Player Update");
	`log(`location @ `ShowVar(NewGameState) @ `ShowVar(m_kLocalPRI.PlayerName) @ `ShowVar(m_kLocalPRI.m_iTotalSquadCost) @ `ShowVar(m_kLocalPRI.m_bPlayerReady),,'XCom_Online');
	if (NewGameState != None)
	{
		NewPlayerState = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player', m_kLocalPlayerGameStateRef.ObjectID));
		UpdateLocalPlayerDataToGameState(NewPlayerState);
		NewGameState.AddStateObject(NewPlayerState);
	}
		NewPlayerStateId = NewPlayerState.GetGameStatePlayerNetId();
	`log(`location @ `ShowVar(NewPlayerState.ObjectID, ObjectID) @ `ShowVar(NewGameState) @ `ShowVar(m_kLocalPRI.PlayerName) @ `ShowVar(m_kLocalPRI.m_iTotalSquadCost) @ `ShowVar(m_kLocalPRI.m_bPlayerReady) @ `ShowVar(class'OnlineSubsystem'.static.UniqueNetIdToString(m_kLocalPRI.UniqueId), UniqueId) @ `ShowVar(class'OnlineSubsystem'.static.UniqueNetIdToString(NewPlayerStateId),NewPlayerStateId),,'XCom_Online');
	return NewGameState;
}

function XComGameState_Player GetPlayerGameState()
{
	local XComGameState_Player PlayerState;
	local UniqueNetId PlayerNetId;
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(m_kLocalPlayerGameStateRef.ObjectID));
	PlayerNetId = PlayerState.GetGameStatePlayerNetId();
	`log(`location @ `ShowVar(PlayerState.ObjectID, ObjectID) @ `ShowVar(PlayerState.PlayerName) @ `ShowVar(class'OnlineSubsystem'.static.UniqueNetIdToString(PlayerNetId), PlayerNetId) @ `ShowVar(PlayerState.TeamFlag) @ `ShowVar(PlayerState.SquadPointValue) @ `ShowVar(PlayerState.bPlayerReady),, 'XCom_Online');
	return PlayerState;
}

function ConvertRankedStatsFromPRIToGameState(XComMPLobbyPRI PRI, XComGameState_Player Player)
{
	local XComOnlineGameSettings kGameSettings;
	local MatchData Data;

	kGameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
	`log(`location @ PRI.ToString(),,'XCom_Online');

	Data.MatchesWon = PRI.m_iRankedDeathmatchMatchesWon;
	Data.MatchesLost = PRI.m_iRankedDeathmatchMatchesLost;
	Data.Disconnects = PRI.m_iRankedDeathmatchDisconnects + (PRI.m_bRankedDeathmatchLastMatchStarted ? 1 : 0); // if this flag is still set, we had a disconnect
	Data.SkillRating = PRI.m_iRankedDeathmatchSkillRating;
	Data.Rank = PRI.m_iRankedDeathmatchRank;
	Data.LastMatchStarted = PRI.m_bRankedDeathmatchLastMatchStarted;

	if( kGameSettings.GetIsRanked() )
	{
		m_kLoadoutPlayerGameState.SetMatchData(Data, 'Ranked');
	}

}

function UpdateData()
{
	// @TODO tsmith: get player name and squad costs...
}