//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMultiplayerUI.uc
//  AUTHOR:  Tronster
//  PURPOSE: Base class to hold UI data for Multiplayer screens.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class XComMultiplayerTacticalUI extends XComMultiplayerUI;



simulated function Init( XComPlayerController controller )
{	
	super.MPInit( controller ) ;
}

simulated function XComMPTacticalGRI GetTacticalGRI()
{
	return XComMPTacticalGRI(WorldInfo.GRI);
}



simulated function string GetGameType()
{
	local string strGameType;

	if ( GetTacticalGRI().m_eNetworkType == eMPNetworkType_LAN )
	{
		// system link "custom match"
		strGameType= m_strCustomMatch;
	}
	else if ( GetTacticalGRI().m_eNetworkType == eMPNetworkType_Private )
	{
		// unranked private "custom match"
		strGameType= m_strCustomMatch;
	}
	else if ( GetTacticalGRI().m_eNetworkType == eMPNetworkType_Public )
	{
		if ( GetTacticalGRI().m_bIsRanked )
		{
			// public ranked
			strGameType= m_strPublicRanked;
		}
		else
		{
			// public unranked
			strGameType= m_strPublicUnranked;
		}
	}
	return strGameType;
}

simulated function string GetMapName()
{
	return GetTacticalGRI().GetMapDisplayName();
}

simulated function string GetPoints()
{
	local string strValue;

	if ( GetTacticalGRI().m_iMaxSquadCost < 1 )
		strValue = m_strUnlimitedLabel;
	else
		strValue = string( GetTacticalGRI().m_iMaxSquadCost );

	return strValue;
}

simulated function int GetSeconds()
{
	return GetTacticalGRI().m_iTurnTimeSeconds;
}


simulated function String GetTurns()
{
	return string( `BATTLE.m_iTurn );
}

simulated function String GetTopName()
{
	local XComMPTacticalPRI kPRI;
	kPRI = GetTopPlayer();
	return kPRI.PlayerName;
}

simulated function String GetBottomName()
{
	local XComMPTacticalPRI kPRI;
	kPRI = GetBottomPlayer();
	return kPRI.PlayerName;
}

simulated function UniqueNetId GetTopUID()
{
	local XComMPTacticalPRI kPRI;
	kPRI = GetTopPlayer();
	return kPRI.UniqueId;
}

simulated function UniqueNetId GetBottomUID()
{
	local XComMPTacticalPRI kPRI;
	kPRI = GetBottomPlayer();
	return kPRI.UniqueId;
}

simulated function SetCurrentPlayerTop()      {   SetCurrentPlayer( GetTopPlayer() ); }
simulated function SetCurrentPlayerBottom()   {   SetCurrentPlayer( GetBottomPlayer() ); }

simulated private function XComMPTacticalPRI GetTopPlayer()
{
	if ( GetALocalPlayerController().PlayerReplicationInfo == GetTacticalGRI().m_kWinningPRI )
		return GetTacticalGRI().m_kWinningPRI;
	else
		return GetTacticalGRI().m_kLosingPRI;
}

simulated private function XComMPTacticalPRI GetBottomPlayer()
{
	if ( GetALocalPlayerController().PlayerReplicationInfo != GetTacticalGRI().m_kWinningPRI )
		return GetTacticalGRI().m_kWinningPRI;
	else
		return GetTacticalGRI().m_kLosingPRI;
}


simulated function bool IsLocalPlayerTheWinner()
{
	return GetALocalPlayerController().PlayerReplicationInfo == GetTacticalGRI().m_kWinningPRI;
}

simulated function bool DidLosingPlayerDisconnect()
{
	return GetTacticalGRI().m_kLosingPRI.m_bDisconnected;
}

defaultproperties
{
}
