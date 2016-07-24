//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMultiplayerPlayerStats.uc
//  AUTHOR:  Tronster - 3/6/12
//  PURPOSE: A player's statistics for Multiplayer games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMultiplayerPlayerStats extends UIScreen
	dependson(XComMultiplayerTacticalUI);

var localized string m_strPlayerStats;
var localized string m_strWins;
var localized string m_strLosses;
var localized string m_strDisconnects;
var localized string m_strFavoriteUnit;
var localized string m_strTotalDamageDone;
var localized string m_strTotalDamageTaken;
var localized string m_strUnitWithMostKills;
var localized string m_strUnitWithMostDamage;
var localized string m_strFavoriteMap;
var localized string m_strFavoriteAbility;
var localized string m_strBack;


var public XGPlayer m_kPlayer;
var bool m_bShowBackButton;
var XComMultiplayerUI m_kMPInterface;
simulated function XComMultiplayerUI GetMgr() { return m_kMPInterface; }


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	Hide();
}

simulated function OnInit()
{
	local string strBack;
	local string strSystemSpecificPlayerLabel;

	super.OnInit();

	AS_SetLabels(
		m_strPlayerStats,
		m_strWins,
		m_strLosses,
		m_strDisconnects,
		m_strFavoriteUnit,
		m_strTotalDamageDone,
		m_strTotalDamageTaken,
		m_strUnitWithMostKills,
		m_strUnitWithMostDamage,
		m_strFavoriteMap,
		m_strFavoriteAbility
		);

	AS_SetValues(
		m_kMPInterface.GetGamerName(), 
		m_kMPInterface.GetWins(), 
		m_kMPInterface.GetLosses(), 
		m_kMPInterface.GetDisconnect(), 
		m_kMPInterface.GetFavoriteUnit(), 
		m_kMPInterface.GetTotalDamageDone(), 
		m_kMPInterface.GetTotalDamageTaken(), 
		m_kMPInterface.GetUnitWithMostKills(), 
		m_kMPInterface.GetUnitWithMostDamage(), 
		m_kMPInterface.GetFavoriteMap(), 
		m_kMPInterface.GetFavoriteAbility()
		);

	strBack = m_bShowBackButton ? m_strBack : "";
	

	if(WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))
		strSystemSpecificPlayerLabel = class'XComMultiplayerUI'.default.m_strViewGamerCard;
	else
		strSystemSpecificPlayerLabel = class'XComMultiplayerUI'.default.m_strViewProfile;
	
	AS_SetNavigation( strBack, strSystemSpecificPlayerLabel );

	Show();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{	
	// Only pay attention to presses or repeats; ignoring other input types
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch( cmd )
	{
		// Back out
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:	
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:			
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
		case class'UIUtilities_Input'.const.FXS_KEY_Y:
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_START:			
			//DO NOTHING 
			break;

		default:
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function bool OnCancel( optional string strOption = "")
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	Movie.Stack.Pop(self);
	return true;
}

simulated function bool OnAltSelect()
{	
	`ONLINEEVENTMGR.ShowGamerCardUI(m_kMPInterface.m_kPRI.UniqueId);
	return true;
}



//==============================================================================
//		FLASH COMMUNICATION:
//==============================================================================
simulated function AS_SetLabels( string title, string label0, string label1, string label2, string label3, string label4, string label5, string label6, string label7, string label8, string label9 )
{ Movie.ActionScriptVoid( MCPath $ ".SetLabels" ); }

simulated function AS_SetValues( string playerName, string data0, string data1, string data2, string data3, string data4, string data5, string data6, string data7, string data8, string data9 )
{ Movie.ActionScriptVoid( MCPath $ ".SetValues" ); }

simulated function AS_SetNavigation( string back, string gamerCard)
{ Movie.ActionScriptVoid( MCPath $ ".SetNavigation" ); }



//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxMultiplayerPlayerStats/MultiplayerPlayerStats";
	MCName = "thePlayerStatsScreen";
	InputState = eInputState_Consume; 
}
