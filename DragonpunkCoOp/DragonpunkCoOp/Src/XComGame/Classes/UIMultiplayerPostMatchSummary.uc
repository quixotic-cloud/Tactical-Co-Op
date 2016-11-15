//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMultiplayerPostMatchSummary.uc
//  AUTHOR:  Tronster - 3/6/12
//  PURPOSE: Summary of player's performance after a multiplayer game.
//			 Exists inherits in tactical layer to allow for rematch without loading /
//           unloading shell, etc...
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMultiplayerPostMatchSummary extends UIScreen
	dependson(XComMultiplayerTacticalUI);

var localized string m_strMatchSummary;
var localized string m_strGame;
var localized string m_strPoints;
var localized string m_strMap; 
var localized string m_strTurns; 
var localized string m_strTime; 

var localized string m_strWin;
var localized string m_strLose;
var localized string m_strReadyForRematch;
var localized string m_strContinue;
var localized string m_strRematch;

var int m_iSelectedIndex;
var XComMultiplayerTacticalUI m_kMPInterface;

var UniqueNetId m_TopPlayerUniqueId;
var UniqueNetId m_BottomPlayerUniqueId;

// CTOR
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_kMPInterface = Spawn(class'XComMultiplayerTacticalUI', self);
	m_kMPInterface.Init( PC );

	Hide();
}

simulated function OnInit()
{
	local string strSystemSpecificPlayerLabel;
	local string strIconLabel;
	local string strNameTop;
	local string strNameBottom;

	super.OnInit();

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
		strSystemSpecificPlayerLabel = class'XComMultiplayerUI'.default.m_strViewGamerCard;
	else
		strSystemSpecificPlayerLabel = class'XComMultiplayerUI'.default.m_strViewProfile;


	strIconLabel = "";
	if ( !Movie.IsMouseActive() )
		strIconLabel = class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE;
	else
		strSystemSpecificPlayerlabel = strSystemSpecificPlayerLabel;

	if( WorldInfo.IsConsoleBuild() )
	{
			
	//Check to see if Y info should be displayed
	if(m_kMPInterface.GetTacticalGRI().m_eNetworkType == eMPNetworkType_LAN)
		{
			//Do not set profile labels if offline
			AS_SetLabels(
				m_strMatchSummary,
				m_strGame,
				m_strPoints,
				m_strMap,
				m_strTurns,
				m_strTime,
				"",
				"",
				"",
				"" );
		}
		else
		{
			//Set profile labels if online
			AS_SetLabels(
				m_strMatchSummary,
				m_strGame,
				m_strPoints,
				m_strMap,
				m_strTurns,
				m_strTime,
				strIconLabel,
				strSystemSpecificPlayerLabel,
				"",
				"" );
		}
	}
	else
	{
		//Set as normal for PC
		AS_SetLabels(
		m_strMatchSummary,
		m_strGame,
		m_strPoints,
		m_strMap,
		m_strTurns,
		m_strTime,
		strIconLabel,
		strSystemSpecificPlayerLabel,
		"",
		"" );
	}
	
	AS_SetValues( 	
		m_kMPInterface.GetGameType(), 
		m_kMPInterface.GetPoints(), 
		m_kMPInterface.GetMapName(),
		m_kMPInterface.GetTurns(), 
		FormatTime( m_kMPInterface.GetSeconds() ) );


	strNameTop    = m_kMPInterface.GetTopName();
	strNameBottom = m_kMPInterface.GetBottomName() ;
	class'UIUtilities_Text'.static.SantizeUserName( strNameTop );
	class'UIUtilities_Text'.static.SantizeUserName( strNameBottom );
	AS_SetGamerTags( strNameTop, strNameBottom );	
	
	// Local player is top.
	`log(`ShowVar(m_kMPInterface.DidLosingPlayerDisconnect()), true, 'XCom_Net');
	if ( m_kMPInterface.IsLocalPlayerTheWinner() )
	{
		AS_SetOutcomes( m_strWin, (m_kMPInterface.DidLosingPlayerDisconnect() ? class'XComOnlineEventMgr'.default.m_sSystemMessageTitles[SystemMessage_Disconnected] : m_strLose) );
	}
	else
	{
		AS_SetOutcomes( (m_kMPInterface.DidLosingPlayerDisconnect() ? class'XComOnlineEventMgr'.default.m_sSystemMessageTitles[SystemMessage_Disconnected] : m_strLose), m_strWin );
	}
	
	// BUG 15516: TCR # 071 - The host will be unable to view the clients gamer card if the client quits out of the match and the host attempts to view the gamer card in the match summary screen.
	m_TopPlayerUniqueId = m_kMPInterface.GetTopUID();
	m_BottomPlayerUniqueId = m_kMPInterface.GetBottomUID();

	AS_SetNavigationLabels( m_strContinue, m_strRematch );

	RealizeSelection();	

	XComPresentationLayer(Movie.Pres).UIMPShowPostMatchSummary();

	Show();

	//sometimes the turn overlay shows under this screen, kill it with fire!
	XComPresentationLayer(Movie.Pres).m_kTurnOverlay.Hide();

	// MP HAX: Only show system messages when this screen pops up, so the user sees 
	SubscribeToOnCleanupWorld();
	`ONLINEEVENTMGR.AddSystemMessageAddedDelegate(OnSystemMessageAdd);
	OnSystemMessageAdd("",""); // Trigger any pending messages now.
}

simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
	`ONLINEEVENTMGR.ClearSystemMessageAddedDelegate(OnSystemMessageAdd);
}

simulated function OnSystemMessageAdd(string sMessage, string sTitle)
{
	Movie.Pres.SanitizeSystemMessages();
	`ONLINEEVENTMGR.ActivateAllSystemMessages();
}

simulated function string FormatTime( int seconds )
{
	local int hours;
	local int minutes;

	if ( seconds < 1 )
		return class'XComMultiplayerUI'.default.m_strUnlimitedLabel;

	hours = seconds / 3600;
	minutes =  ((hours * 3600) - seconds) / 60;
	if ( minutes < 0 ) minutes = -minutes;
	
	seconds = seconds - (hours * 3600) - (minutes * 60);

	return ((hours < 10) ? "0" : "") $ hours $ ":" $
		   ((minutes < 10) ? "0" : "") $ minutes $ ":" $
		   ((seconds < 10) ? "0" : "") $ seconds;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{	
	// Only pay attention to presses or repeats; ignoring other input types
	if ( !((arg & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 || ( arg & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0))
		return false;

	switch( cmd )
	{
		// Back out
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:	
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:			
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:			
			return true;

		// REMOVED!
		//case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		//	return OnAltXSelect();

		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			return true;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			PlaySound( SoundCue'SoundUI.MenuScrollCue', true ); 
			return true;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			PlaySound( SoundCue'SoundUI.MenuScrollCue', true ); 
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_START:			
			//DO NOTHING 
			break;

		default:
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function bool OnAccept( optional string strOption = "")
{
	if ( m_iSelectedIndex == 0 || m_iSelectedIndex == 1 )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}

	// Continue
	if ( m_iSelectedIndex == 2 )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		XComPresentationLayer(Movie.Pres).PopState();
	}

	// Rematch
	if ( m_iSelectedIndex == 3 )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		XComPresentationLayer(Movie.Pres).PopState();
	}

	return true;
}

simulated function bool OnAltYSelect()
{
	local UniqueNetId playerUniqueId;

	if( m_kMPInterface.GetTacticalGRI().m_eNetworkType != eMPNetworkType_LAN )
	{
		if ( m_iSelectedIndex == 0 || m_iSelectedIndex == 1 )
		{
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);

			if (m_iSelectedIndex == 0)
			{
				m_kMPInterface.SetCurrentPlayerTop();
				playerUniqueId = m_TopPlayerUniqueId;
			}
			else
			{
				m_kMPInterface.SetCurrentPlayerBottom();
				playerUniqueId = m_BottomPlayerUniqueId;
			}
			`ONLINEEVENTMGR.ShowGamerCardUI(playerUniqueId);
		}
		else
		{
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
		}
	}

	return true;
}

simulated function bool OnAltXSelect()
{
	if ( m_iSelectedIndex == 0 )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);		

		if (m_iSelectedIndex == 0)
			m_kMPInterface.SetCurrentPlayerTop();
		else
			m_kMPInterface.SetCurrentPlayerBottom();

		XComPresentationLayer(Movie.Pres).UIMPShowPlayerStats( m_kMPInterface );
	}
	else if ( m_iSelectedIndex == 1 )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}

	return true;
}


simulated function bool OnUp()
{
	m_iSelectedIndex--;
	if ( m_iSelectedIndex < 0 )
		m_iSelectedIndex = 0;
	RealizeSelection();
	
	return true;
}

simulated function bool OnDown()
{
	m_iSelectedIndex++;
	if ( m_iSelectedIndex > 2 )
		m_iSelectedIndex = 2;
	RealizeSelection();

	return true;
}

//==============================================================================
//    ______
//   /  |  \\  Mouse support
//  |  / \  ||  By the special Mouse/PC team
//  |  \ /  ||
//  |___|___||
//  |       ||
//  |       ||
//  |       ||
//   \_____//
//==============================================================================
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string targetCallback;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			if ( args.Find( "thePlayerBoxTop" ) != INDEX_NONE )
			{
				m_iSelectedIndex = 0;
				RealizeSelection();
			}
			else
			if ( args.Find( "thePlayerBoxBottom" ) != INDEX_NONE )
			{
				m_iSelectedIndex = 1;
				RealizeSelection();
			}
			else
			if ( args.Find( "navButtonContinue" ) != INDEX_NONE )
			{
				m_iSelectedIndex = 2;
				RealizeSelection();
			}
			break;  


		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:

			targetCallback = args[args.Length - 1];
			switch ( targetCallback )
			{
				case "thePlayerBoxTop":
					m_iSelectedIndex = 0;
					OnAltYSelect();
					break;
				
				case "thePlayerBoxBottom":
					m_iSelectedIndex = 1;
					OnAltYSelect();
					break;
				
				case "navButtonContinue":
					m_iSelectedIndex = 2;
					OnAccept();
					break;
			}
			break;
	}
}




simulated function RealizeSelection()
{
	AS_SetSelected( m_iSelectedIndex );
}

simulated function OnRemoved()
{
	XComPresentationLayer(Movie.Pres).UILeaveMultiplayerMatch();
}
simulated function OnReceiveFocus()
{
	Show();
}
simulated function OnLoseFocus()
{
	Hide();
}


//==============================================================================
//		FLASH COMMUNICATION:
//==============================================================================
simulated function AS_SetLabels( string title, string game, string points, string map, string turnslabel, string time, string iconCard, string viewGamerCard, string iconStats, string playerStats )
{ Movie.ActionScriptVoid( MCPath $ ".SetLabels" ); }

simulated function AS_SetValues( string game, string points, string map, string turnsLabel, string time  )
{ Movie.ActionScriptVoid( MCPath $ ".SetValues" ); }

simulated function AS_SetNavigationLabels( string continueButton, string rematchButton )
{ Movie.ActionScriptVoid( MCPath $ ".SetNavigationLabels" ); }

simulated function AS_SetGamerTags( string nameTop, string nameBottom )
{ Movie.ActionScriptVoid( MCPath $ ".SetGamerTags" ); }

simulated function AS_SetOutcomes( string outcomeTop, string outcomeBottom )
{ Movie.ActionScriptVoid( MCPath $ ".SetOutcomes" ); }

simulated function AS_SetSelected( int index )
{ Movie.ActionScriptVoid( MCPath $ ".SetSelected" ); }

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxMultiplayerPostMatchSummary/MultiplayerPostMatchSummary";
	
	InputState = eInputState_Consume; 
	bConsumeMouseEvents = true; 
}
