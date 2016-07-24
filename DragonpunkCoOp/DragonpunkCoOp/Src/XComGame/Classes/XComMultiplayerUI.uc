//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMultiplayerUI.uc
//  AUTHOR:  Tronster
//  PURPOSE: Base class to hold UI data for Multiplayer screens.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class XComMultiplayerUI extends Actor;

// ENUMS
//----------------------------------------------------------------------------
enum EMPMainMenuOptions
{
	eMPMainMenu_Ranked,
	eMPMainMenu_QuickMatch,
	eMPMainMenu_CustomMatch,
	eMPMainMenu_Leaderboards,
	eMPMainMenu_EditSquad,
	eMPMainMenu_AcceptInvite
//	eMPMainMenu_PlayerStats
};

var localized string m_aMainMenuOptionStrings[EMPMainMenuOptions.EnumCount]<BoundEnum=EMPMainMenuOptions>;
var localized string m_strMPCustomMatchPointsValue;
var localized string m_strCustomMatch;
var localized string m_strPublicRanked;
var localized string m_strPublicUnranked;

var localized string m_strUnlimitedLabel;

var localized string m_strViewGamerCard;
var localized string m_strViewProfile;

var bool m_bPassedNetworkConnectivityCheck;
var bool m_bPassedOnlineConnectivityCheck;
var bool m_bPassedOnlinePlayPermissionsCheck;
var bool m_bPassedOnlineChatPermissionsCheck;


var XComPlayerController       m_kControllerRef;
var XComPlayerReplicationInfo  m_kPRI;

simulated function MPInit(XComPlayerController controller)
{	
	m_kControllerRef = controller;
}


simulated function SetCurrentPlayer( XComPlayerReplicationInfo kPRI )
{
	m_kPRI = kPRI;
}



simulated function string GetGamerName( )
{
	//if ( GetTacticalGRI().m_kWinningPlayer.m_kPlayerController.IsLocalPlayerController() )
	//	return ;
	return "??? Network Support";
}


simulated function string GetWins()
{
	return string( m_kPRI.m_iRankedDeathmatchMatchesWon );
}

simulated function string GetLosses()
{
	return string( m_kPRI.m_iRankedDeathmatchMatchesLost );
}

simulated function string GetDisconnect()
{
	return "??? Network Support";
}

simulated function string GetFavoriteUnit()
{
	return "??? Network Support";
}

simulated function string GetTotalDamageDone() 
{
	return "??? Network Support";
}

simulated function string GetTotalDamageTaken() 
{
	return "??? Network Support";
}

simulated function string GetUnitWithMostKills()
{
	return "??? Network Support";
}

simulated function string GetUnitWithMostDamage()
{
	return "??? Network Support";
}

simulated function string GetFavoriteMap()
{
	return "??? Network Support";
}

simulated function string GetFavoriteAbility()
{
	return "??? Network Support";
}





defaultproperties
{
	m_bPassedNetworkConnectivityCheck = false;
	m_bPassedOnlineConnectivityCheck = false;
	m_bPassedOnlinePlayPermissionsCheck = false;
	m_bPassedOnlineChatPermissionsCheck = false;
}
