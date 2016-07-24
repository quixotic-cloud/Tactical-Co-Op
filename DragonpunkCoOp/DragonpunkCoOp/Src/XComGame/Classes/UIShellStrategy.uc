//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIShellStrategy
//  AUTHOR:  Brit Steiner       -- 06-8-10
//  PURPOSE: Controls the game side of the strategy shell menu UI screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIShellStrategy extends UIPauseMenu;

enum EStratShellOptions
{
	eSSO_UncontrolledStart,	
	eSSO_LoadGame,
	eSSO_DebugStart,
	eSSO_DebugNonCheatStart,
};

var bool m_bCompletedControlledGame;
var bool m_bReceivedIronmanWarning;
var bool m_bSkipFirstTactical;
var bool m_bCheatStart;

var localized string m_strTitle;
var localized string m_strNewGame;
var localized string m_strLoadGame;
var localized string m_strDebugStrategyStart;

var localized string m_strDifficultyTitle;
var localized string m_strDifficultyEasy;
var localized string m_strDifficultyNormal;
var localized string m_strDifficultyHard;
var localized string m_strDifficultyImpossible;

var localized string m_strControlTitle;
var localized string m_strControlBody;
var localized string m_strControlOK;
var localized string m_strControlCancel;

var localized string m_strIronmanTitle;
var localized string m_strIronmanBody;
var localized string m_strIronmanOK;
var localized string m_strIronmanCancel;

var localized string m_strEasyDesc;
var localized string m_strNormalDesc;
var localized string m_strHardDesc;
var localized string m_strClassicDesc;

var localized string m_strIronmanLabel;
var localized string m_strTutorialLabel;

var UINavigationHelp   NavHelp;

//----------------------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	PushState('ShellMenu');

	// These player profile flags will change what options are defaulted when this menu comes up
	// SCOTT RAMSAY/RYAN BAKER: Has the player ever completed the strategy tutorial?
	m_bCompletedControlledGame = true; // `BATTLE.STAT_GetProfileStat(eProfile_TutorialComplete) > 0; // Ryan Baker - Hook up when we are ready.
	// SCOTT RAMSAY: Has the player ever received the ironman warning?
	m_bReceivedIronmanWarning = false;

	// Toggle the controlled start option based on whether the player has either played a controlled game, or turned the option off previously
	//`GAME.m_bControlledStart = !m_bCompletedControlledGame;       //jbouscher: `GAME does not exist at this point, I believe it is set in UIShellDifficulty
	NavHelp = InitController.Pres.GetNavHelp();
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(CloseScreen);

	Show();
}

simulated function DisconnectGame()
{
	XComHeadquartersGame(WorldInfo.Game).Uninit();
	ConsoleCommand("disconnect");
}

//----------------------------------------------------------------------------

state ShellMenu
{
	event BeginState( name p )
	{
		if( p == 'DifficultyMenu' )
			BuildMenu();
	}

	simulated public function OnChildClicked(UIList ContainerList, int ItemIndex)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);

		SetSelected(ContainerList, ItemIndex);
		NavHelp.ClearButtonHelp();
		
		switch( m_iCurrentSelection )
		{
			case eSSO_UncontrolledStart:
				XComShellPresentationLayer(Owner).UIDifficulty();				
				break;

			case eSSO_LoadGame: //Load game 
				XComShellPresentationLayer(Owner).UILoadScreen();
				break;

			case eSSO_DebugStart:
				m_bCheatStart = true;
				XComShellPresentationLayer(Owner).UIDifficulty();
				break;

			case eSSO_DebugNonCheatStart:
				m_bSkipFirstTactical = true;
				XComShellPresentationLayer(Owner).UIDifficulty();				
				break;

			default:
				`warn("Pause menu cannot accept an unexpected index of:" @ m_iCurrentSelection);
				break;
		}	
	}

	simulated function BuildMenu()
	{
		local int iOption;
			
		MAX_OPTIONS = eSSO_MAX;
		//AS_SetTitle(m_strTitle);

		MC.FunctionString("SetTitle", m_strTitle);
		SetHelp( 0, "", "");

		//AS_Clear();
		List.ClearItems();

		for( iOption = 0; iOption < eSSO_MAX; iOption++ )
		{
			switch( iOption )
			{
			case eSSO_UncontrolledStart:
				//AS_AddOption(iOption, m_strNewGame, 0);
				UIListItemString(List.CreateItem()).InitListItem(m_strNewGame);
				break;
			case eSSO_LoadGame:
				//AS_AddOption(iOption, m_strLoadGame, 0);
				UIListItemString(List.CreateItem()).InitListItem(m_strLoadGame);
				break;
			case eSSO_DebugStart:
				//AS_AddOption(iOption, m_strDebugStrategyStart, 0);
				UIListItemString(List.CreateItem()).InitListItem(m_strDebugStrategyStart);
				break;
			case eSSO_DebugNonCheatStart:
				//AS_AddOption(iOption, "Debug NonCheat Start", 0);
				UIListItemString(List.CreateItem()).InitListItem("Debug NonCheat Start");
			}
		}
		MC.FunctionVoid("AnimateIn");
	}
	
	simulated function OnUCancel()
	{
		Movie.Stack.Pop(self); 
	}
}

simulated function bool OnUnrealCommand(int ucmd, int ActionMask)
{
	// Ignore releases, only pay attention to presses.
	if ( !CheckInputIsReleaseOrDirectionRepeat(ucmd, ActionMask) )
		return true;

`if(`notdefined(FINAL_RELEASE))
	if(ucmd == class'UIUtilities_Input'.const.FXS_KEY_TAB)
	{
		m_iCurrentSelection = eSSO_DebugStart; // debug strategy
		SetSelected(List, m_iCurrentSelection);
		return true;
	}
`endif

	// Assume input is handled unless told otherwise (unlikely
	// because this is the pause menu; it handles alllllllll.)
	return super.OnUnrealCommand(ucmd, ActionMask);
}

function ToggleIronman()
{
	if( !m_bReceivedIronmanWarning )
	{
		ConfirmIronmanDialogue();
	}
	else
	{
		`GAME.m_bIronman = !`GAME.m_bIronman;

		if( `GAME.m_bIronman )
			PlaySound( SoundCue'SoundUI.OverWatchCue' );
		else
			PlaySound( SoundCue'SoundUI.PositiveUISelctionCue' );
	}
}

function ToggleControlledStart()
{
	if( !m_bCompletedControlledGame )
	{
		ConfirmControlDialogue();
	}
	else
	{
		`GAME.m_bControlledStart = !`GAME.m_bControlledStart;
		PlaySound( SoundCue'SoundUI.PositiveUISelctionCue' );
	}
}

//------------------------------------------------------
function ConfirmIronmanDialogue() 
{
	local TDialogueBoxData kDialogData;

	PlaySound( SoundCue'SoundUI.HUDOnCue' );

	kDialogData.eType       = eDialog_Normal;
	kDialogData.strTitle    = m_strIronmanTitle;
	kDialogData.strText     = m_strIronmanBody;
	kDialogData.strAccept   = m_strIronmanOK;
	kDialogData.strCancel   = m_strIronmanCancel;
	kDialogData.fnCallback  = ConfirmIronmanCallback;

	`HQPRES.UIRaiseDialog( kDialogData );
	Show();
}

simulated public function ConfirmIronmanCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		PlaySound( SoundCue'SoundUI.OverWatchCue' );
		`GAME.m_bIronman = true;
	}
	else if( eAction == eUIAction_Cancel )
	{
		PlaySound( SoundCue'SoundUI.HUDOffCue' ); 
	}

	// SCOTT RAMSAY: Player has now received warning, so record that in profile
}

//------------------------------------------------------
function ConfirmControlDialogue() 
{
	local TDialogueBoxData kDialogData;

	PlaySound( SoundCue'SoundUI.HUDOnCue' );

	kDialogData.eType       = eDialog_Normal;
	kDialogData.strTitle    = m_strControlTitle;
	kDialogData.strText     = m_strControlBody;
	kDialogData.strAccept   = m_strControlOK;
	kDialogData.strCancel   = m_strControlCancel;
	kDialogData.fnCallback  = ConfirmControlCallback;

	`HQPRES.UIRaiseDialog( kDialogData );
	Show();
}

simulated public function ConfirmControlCallback(eUIAction eAction)
{
	PlaySound( SoundCue'SoundUI.HUDOffCue' ); 
	if (eAction == eUIAction_Accept)
	{
		`GAME.m_bControlledStart = false;
	}
	else if( eAction == eUIAction_Cancel )
	{
	}

	// SCOTT RAMSAY: Player has actively turned off "Controlled start", so mark that in profile
}

simulated function CloseScreen()
{
	super.CloseScreen();

	NavHelp.ClearButtonHelp();
}
simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(CloseScreen);
}

DefaultProperties
{
	m_iCurrentSelection = 0;
	MAX_OPTIONS = -1;
	m_bIsIronman = false;

	//Package   = "/ package/gfxPauseMenu/PauseMenu";
	//MCName      = "thePauseMenu";

	InputState= eInputState_Consume;
}

