//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPauseMenu
//  AUTHOR:  Brit Steiner       -- 02/26/09
//           Tronster Hartley   -- 04/14/09
//  PURPOSE: Controls the game side of the pause menu UI screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIPauseMenu extends UIScreen;

var int       m_iCurrentSelection;
var int       MAX_OPTIONS;
var bool      m_bIsIronman;
var bool      m_bAllowSaving;

var UIList List;
var UIText Title;

var localized string m_sPauseMenu;
var localized string m_sSaveGame;
var localized string m_sReturnToGame;
var localized string m_sSaveAndExitGame;
var localized string m_sLoadGame;
var localized string m_sControllerMap;
var localized string m_sInputOptions;
var localized string m_sAbortMission;
var localized string m_sExitGame;
var localized string m_sQuitGame;
var localized string m_sAccept;
var localized string m_sCancel;
var localized string m_sAcceptInvitations;
var localized string m_kExitGameDialogue_title;
var localized string m_kExitGameDialogue_body;
var localized string m_kExitMPRankedGameDialogue_body;
var localized string m_kExitMPUnrankedGameDialogue_body;
var localized string m_kQuitGameDialogue_title;
var localized string m_kQuitGameDialogue_body;
var localized string m_kQuitMPRankedGameDialogue_body;
var localized string m_kQuitMPUnrankedGameDialogue_body;
var localized string m_sRestartLevel;
var localized string m_sRestartConfirm_title;
var localized string m_sRestartConfirm_body;
var localized string m_sChangeDifficulty;
var localized string m_sViewSecondWave;
var localized string m_sUnableToSaveTitle;
var localized string m_sUnableToSaveBody;
var localized string m_sSavingIsInProgress;
var localized string m_sUnableToAbortTitle;
var localized string m_sUnableToAbortBody;
var localized string m_kSaveAndExitGameDialogue_title;
var localized string m_kSaveAndExitGameDialogue_body;

var int m_optReturnToGame;
var int m_optSave;
var int m_optLoad;
var int m_optRestart;
var int m_optChangeDifficulty;
var int m_optViewSecondWave;
var int m_optControllerMap;
var int m_optOptions;
var int m_optExitGame;
var int m_optQuitGame;
var int m_optAcceptInvite;
var bool bWasInCinematicMode;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	bWasInCinematicMode = InitMovie.Stack.bCinematicMode;
	InitMovie.Stack.bCinematicMode = false;
	super.InitScreen(InitController, InitMovie, InitName);
	
	Movie.Pres.OnPauseMenu(true);
	Movie.Pres.StopDistort(); 

	if( `XWORLDINFO.GRI != none && `TACTICALGRI != none && `BATTLE != none )
		`BATTLE.m_bInPauseMenu = true;

	if (!IsA('UIShellStrategy') && !`XENGINE.IsMultiplayerGame())
	{
		PC.SetPause(true);
	}
	
	List = Spawn(class'UIList', self);
	List.InitList('ItemList', , , 415, 450);
	List.OnItemClicked = OnChildClicked;
	List.OnSelectionChanged = SetSelected; 
	List.OnItemDoubleClicked = OnChildClicked;

	XComTacticalController(PC).GetCursor().SetForceHidden(false);
	`PRES.m_kUIMouseCursor.Show();
}

//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	local bool bInputBlocked; 
	local bool bInputGateRaised;

	super.OnInit();	
	
	BuildMenu();
	
	SetHelp( 0, m_sCancel, 	 class'UIUtilities_Input'.static.GetBackButtonIcon());

	SetSelected(List, 0);

	//If you've managed to fire up the pause menu while the state was transitioning to block input, get back out of here. 
	bInputBlocked = XComTacticalInput(PC.PlayerInput) != none && XComTacticalInput(PC.PlayerInput).m_bInputBlocked;
	bInputGateRaised = Movie != none && Movie.Stack != none &&  Movie.Stack.IsInputBlocked;
	if( bInputBlocked || bInputGateRaised )
	{
		`log("UIPauseMenu: you've got in to a bad state where the input is blocked but the pause menu just finished async loading in. Killing the pause menu now. -bsteiner");
		OnUCancel();
	}
}

simulated event ModifyHearSoundComponent(AudioComponent AC)
{
	AC.bIsUISound = true;
}

simulated function bool OnUnrealCommand(int ucmd, int ActionMask)
{
	// Ignore releases, only pay attention to presses.
	if ( !CheckInputIsReleaseOrDirectionRepeat(ucmd, ActionMask) )
		return true;

	switch(ucmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnChildClicked(List, m_iCurrentSelection);
			break;
		
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnUCancel();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			OnUDPadUp();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			OnUDPadDown();
			break;

		default:
			// Do not reset handled, consume input since this
			// is the pause menu which stops any other systems.
			break;			
	}

	return super.OnUnrealCommand(ucmd, ActionMask);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			//Update the selection based on what the mouse rolled over
			//SetSelected( int(Split( args[args.Length - 1], "option", true)) );
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			//Update the selection based on what the mouse clicked
			m_iCurrentSelection = int(Split( args[args.Length - 1], "option", true));
			OnChildClicked(List, m_iCurrentSelection);
			break;
	}
}

simulated public function OnChildClicked(UIList ContainerList, int ItemIndex)
{		
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetSelected(ContainerList, ItemIndex);

	switch( m_iCurrentSelection )
	{
		case m_optReturnToGame:
			OnUCancel();
			break; 
		case m_optSave: //Save Game
			if (`TUTORIAL == none)
			{
				if (Movie.Pres.PlayerCanSave() && !`ONLINEEVENTMGR.SaveInProgress())
				{
					if (m_bIsIronman)
						IronmanSaveAndExitDialogue();
					else
					{
						Movie.Pres.UISaveScreen();
					}
				}
				else
				{
					UnableToSaveDialogue(`ONLINEEVENTMGR.SaveInProgress());
				}
			}
			break;

		case m_optLoad: //Load Game 
			if( m_bIsIronman )
				`AUTOSAVEMGR.DoAutosave();

			Movie.Pres.UILoadScreen();
			break;

		case m_optChangeDifficulty:
			Movie.Pres.UIDifficulty( true );
			break;

		case m_optViewSecondWave:
			Movie.Pres.UISecondWave( true );
			break;

		case m_optRestart: // Restart Mission (only valid in tactical)
			if (`BATTLE != none && WorldInfo.NetMode == NM_Standalone && !m_bIsIronman)
				RestartMissionDialogue();				
			break;

		case m_optControllerMap: //Controller Map
			Movie.Pres.UIControllerMap();
			break;

		case m_optOptions: // Input Options
			//`log(self @"OnUnrealCommand does not have game data designed and implemented for option #3.");
			//Movie.Pres.GetAnchoredMessenger().Message("Edit Settings option is not available.", 0.55f, 0.8f, BOTTOM_CENTER, 4.0f);
			Movie.Pres.UIPCOptions();
			return;

			break;
			
		case m_optExitGame: //Exit Game
			if( m_bIsIronman )
				`AUTOSAVEMGR.DoAutosave();

			ExitGameDialogue();
			break;

		case m_optQuitGame: //Quit Game
			if( m_bIsIronman )
				`AUTOSAVEMGR.DoAutosave();
				
			QuitGameDialogue();
			break;
			
		case m_optAcceptInvite: // Show Invitations UI
			Movie.Pres.UIInvitationsMenu();
			break;

		default:
			`warn("Pause menu cannot accept an unexpected index of:" @ m_iCurrentSelection);
			break;
	}	
}


simulated function OnReceiveFocus() 
{
	super.OnReceiveFocus();
	SetSelected(List, 0);
}

simulated event Destroyed()
{
	super.Destroyed();
	PC.SetPause(false);
}

function SaveAndExit()
{
	`AUTOSAVEMGR.DoAutosave(OnSaveGameComplete);

	XComPresentationLayer(Movie.Pres).GetTacticalHUD().Hide();
	Hide();

	Movie.RaiseInputGate();
}

function OnSaveGameComplete(bool bWasSuccessful)
{
	Movie.LowerInputGate();

	if( bWasSuccessful )
	{
		Disconnect();
	}
	else
	{
		`RedScreen("[@Systems] Save failed to complete");
	}
}

function Disconnect()
{
	if (`REPLAY.bInTutorial)
	{
		`FXSLIVE.AnalyticsGameTutorialExited( );
	}

	Movie.Pres.UIEndGame();
	`XCOMHISTORY.ResetHistory();
	ConsoleCommand("disconnect");
}

function ExitGameDialogue() 
{
	local TDialogueBoxData      kDialogData;
	local XComMPTacticalGRI     kMPGRI;

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);

	kDialogData.eType = eDialog_Warning;

	if(kMPGRI != none)
	{
		if(kMPGRI.m_bIsRanked)
		{
			kDialogData.strText = m_kExitMPRankedGameDialogue_body; 
		}
		else
		{
			kDialogData.strText = m_kExitMPUnrankedGameDialogue_body; 
		}
		kDialogData.fnCallback = ExitMPGameDialogueCallback;
	}
	else
	{
		kDialogData.strText = m_kExitGameDialogue_body; 
		kDialogData.fnCallback = ExitGameDialogueCallback;
	}

	kDialogData.strTitle = m_kExitGameDialogue_title;
	kDialogData.strAccept = m_sAccept; 
	kDialogData.strCancel = m_sCancel; 

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function ExitGameDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);

		// Hide the UI so the user knows their input was accepted
		XComPresentationLayer(Movie.Pres).GetTacticalHUD().Hide();
		Hide();

		SetTimer(0.15, false, 'Disconnect'); // Give time for the UI to hide before disconnecting
	}
	else if( eAction == eUIAction_Cancel )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

simulated public function ExitMPGameDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		Movie.Pres.UIEndGame();
		XComTacticalController(PC).AttemptExit();
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}

function IronmanSaveAndExitDialogue()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_kSaveAndExitGameDialogue_title;
	kDialogData.strText     = m_kSaveAndExitGameDialogue_body; 
	kDialogData.strAccept   = m_sAccept; 
	kDialogData.strCancel   = m_sCancel; 
	kDialogData.fnCallback  = IronmanSaveAndExitDialogueCallback;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function IronmanSaveAndExitDialogueCallback(EUIAction eAction)
{	
	if (eAction == eUIAction_Accept)
	{
		SaveAndExit();
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}


function UnableToSaveDialogue(bool bSavingInProgress)
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_sUnableToSaveTitle;
	if( bSavingInProgress )
	{
		kDialogData.strText = m_sSavingIsInProgress;
	}
	else
	{
		kDialogData.strText = m_sUnableToSaveBody;
	}
	kDialogData.strAccept   = m_sAccept;	

	Movie.Pres.UIRaiseDialog( kDialogData );
}

function UnableToAbortDialogue()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_sUnableToAbortTitle;
	kDialogData.strText     = m_sUnableToAbortBody; 
	kDialogData.strAccept   = m_sAccept;	

	Movie.Pres.UIRaiseDialog( kDialogData );
}

function RestartMissionDialogue()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_sRestartConfirm_title;
	kDialogData.strText     = m_sRestartConfirm_body; 
	kDialogData.strAccept   = m_sAccept; 
	kDialogData.strCancel   = m_sCancel; 
	kDialogData.fnCallback  = RestartMissionDialgoueCallback;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function RestartMissionDialgoueCallback(EUIAction eAction)
{	
	if (eAction == eUIAction_Accept)
	{
		`PRES.m_kNarrative.RestoreNarrativeCounters();
		PC.RestartLevel();
	}
}

function QuitGameDialogue() 
{
	local TDialogueBoxData kDialogData; 
	local XComMPTacticalGRI     kMPGRI;

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);

	if(kMPGRI != none && kMPGRI.m_bIsRanked)
	{
		kDialogData.strText     = m_kQuitMPRankedGameDialogue_body; 
		kDialogData.fnCallback  = QuitGameMPRankedDialogueCallback;
	}
	else
	{
		if(kMPGRI != none )
			kDialogData.strText     = m_kQuitMPUnrankedGameDialogue_body; 
		else
			kDialogData.strText     = m_kQuitGameDialogue_body; 
		kDialogData.fnCallback  = QuitGameDialogueCallback;
	}

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_kQuitGameDialogue_title;
	kDialogData.strAccept   = m_sAccept; 
	kDialogData.strCancel   = m_sCancel; 

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function QuitGameDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Movie.Pres.UIEndGame();
		ConsoleCommand("exit");
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}

simulated public function QuitGameMPRankedDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Movie.Pres.UIEndGame();
		ConsoleCommand("exit");
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}

// Lower pause screen
simulated public function OnUCancel()
{
	if( !bIsInited )
		return;

	if( `XWORLDINFO.GRI != none && `TACTICALGRI != none && `BATTLE != none )
		`BATTLE.m_bInPauseMenu = false;

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	Movie.Stack.Pop(self);
}

simulated public function OnUDPadUp()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	--m_iCurrentSelection;
	if (m_iCurrentSelection < 0)
		m_iCurrentSelection = MAX_OPTIONS-1;

	SetSelected(List, m_iCurrentSelection);
}


simulated public function OnUDPadDown()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	++m_iCurrentSelection;
	if (m_iCurrentSelection >= MAX_OPTIONS)
		m_iCurrentSelection = 0;

	SetSelected( List, m_iCurrentSelection );
}

simulated function SetSelected(UIList ContainerList, int ItemIndex)
{
	m_iCurrentSelection = ItemIndex;
}


simulated function int GetSelected()
{
	return  m_iCurrentSelection; 
}

simulated function BuildMenu()
{
	local int iCurrent; 
	local XComMPTacticalGRI kMPGRI;
	local UIListItemString SaveGameListItem;

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);

	MC.FunctionString("SetTitle", m_sPauseMenu);

	//AS_Clear();
	List.ClearItems();

	iCurrent = 0; 

	//set options to -1 so they don't interfere with the switch statement on selection
	m_optSave = -1;
	m_optLoad = -1; 

	//Return to game option is always 0 
	m_optReturnToGame = iCurrent++;
	//AS_AddOption(m_optReturnToGame, m_sReturnToGame, 0);
	UIListItemString(List.CreateItem()).InitListItem(m_sReturnToGame);

	// no save/load in multiplayer -tsmith 
	if (kMPGRI == none && !`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		if( m_bAllowSaving )
		{
			m_optSave = iCurrent++; 
			//AS_AddOption(m_optSave, m_sSaveAndExitGame, 0);
			SaveGameListItem = UIListItemString(List.CreateItem()).InitListItem(m_bIsIronman ? m_sSaveAndExitGame : m_sSaveGame);
			if (`TUTORIAL != None)
			{
				SaveGameListItem.DisableListItem(class'XGLocalizedData'.default.SaveDisabledForTutorial);
			}
		}
		
		// in ironman, you cannot load at any time that saving would normally be disabled
		if( m_bAllowSaving || !m_bIsIronman )
		{
			m_optLoad = iCurrent++;
			//AS_AddOption(m_optLoad, m_sLoadGame, 0);
			UIListItemString(List.CreateItem()).InitListItem(m_sLoadGame);
		}
	}

	if( Movie.IsMouseActive() )
	{
		m_optControllerMap = -1; 
	}
	else
	{
		m_optControllerMap = iCurrent++; 
		//AS_AddOption(m_optControllerMap, m_sControllerMap, 0);
		UIListItemString(List.CreateItem()).InitListItem(m_sControllerMap);
	}

	m_optOptions = iCurrent++; 
	//AS_AddOption(m_optOptions, m_sInputOptions, 0);
	UIListItemString(List.CreateItem()).InitListItem(m_sInputOptions);

	// no restart in multiplayer -tsmith 
	if( kMPGRI == none &&
		!m_bIsIronman &&
		XComPresentationLayer(Movie.Pres) != none &&
		XGBattle_SP(`BATTLE).m_kDesc != None &&
		(XGBattle_SP(`BATTLE).m_kDesc.m_iMissionType == eMission_Final || XGBattle_SP(`BATTLE).m_kDesc.m_bIsFirstMission || XGBattle_SP(`BATTLE).m_kDesc.m_iMissionType == eMission_HQAssault) && //Only visible in temple ship or first mission, per Jake. -bsteiner 6/12/12
		!`ONLINEEVENTMGR.bIsChallengeModeGame )
	{
		m_optRestart = iCurrent++; 
		//AS_AddOption(m_optRestart, m_sRestartLevel, 0);
		UIListItemString(List.CreateItem()).InitListItem(m_sRestartLevel);
	}
	else
		m_optRestart = -1;  //set options to -1 so they don't interfere with the switch statement on selection

	// Only allow changing difficulty if in an active single player game and only at times where saving is permitted
	if( Movie.Pres.m_eUIMode != eUIMode_Shell && kMPGRI == none && m_bAllowSaving && !`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		m_optChangeDifficulty = iCurrent++; 
		//AS_AddOption(m_optChangeDifficulty, m_sChangeDifficulty, 0);
		UIListItemString(List.CreateItem()).InitListItem(m_sChangeDifficulty);
	}
	else
		m_optChangeDifficulty = -1;  //set options to -1 so they don't interfere with the switch statement on selection

	// Only show second wave options in single player
	if ( `XPROFILESETTINGS.Data.IsSecondWaveUnlocked() && Movie.Pres.m_eUIMode != eUIMode_Shell && kMPGRI == none )
	{
		m_optViewSecondWave = iCurrent++; 
		//AS_AddOption(m_optViewSecondWave, m_sViewSecondWave, 0);
		UIListItemString(List.CreateItem()).InitListItem(m_sViewSecondWave);
	}
	else
		m_optViewSecondWave = -1;  //set options to -1 so they don't interfere with the switch statement on selection
	
	// Remove the invite option -ttalley
	//m_optAcceptInvite = iCurrent++;
	//AS_AddOption( m_optAcceptInvite, m_sAcceptInvitations, 0);

	m_optExitGame = iCurrent++; 
	//AS_AddOption(m_optExitGame, m_sExitGame, 0); 
	UIListItemString(List.CreateItem()).InitListItem(m_sExitGame);

	// no quit game on console or in MP. MP we only want exit so it will record a loss for you. -tsmith 
	if( !WorldInfo.IsConsoleBuild() && kMPGRI == none )
	{
		m_optQuitGame= iCurrent++; 
		//AS_AddOption(m_optQuitGame, m_sQuitGame, 0);
		UIListItemString(List.CreateItem()).InitListItem(m_sQuitGame);
	}

	MAX_OPTIONS = iCurrent;

	MC.FunctionVoid("AnimateIn");
}


/// ========== FLASH calls ========== 

//Set the info in the standard help bar along the bottom of the screen 
simulated function SetHelp(int index, string text, string buttonIcon)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = text;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = buttonIcon;
	myArray.AddItem( myValue );

	Invoke("SetHelp", myArray);
}

//simulated function AS_SetTitle( string Title )
//{ Movie.ActionScriptVoid(MCPath$".SetTitle"); }

//simulated  function AS_AddOption( int Index, string DisplayText, int iState )
//{ Movie.ActionScriptVoid(MCPath$".AddOption"); }

//simulated function AS_Selected( int iTarget )
//{ Movie.ActionScriptVoid(MCPath$".SetListSelection"); }

//simulated function AS_Clear()
//{ Invoke("clear"); }

simulated function OnRemoved()
{
	Movie.Stack.bCinematicMode = bWasInCinematicMode;
	Movie.Pres.OnPauseMenu(false);
}

simulated function OnExitButtonClicked(UIButton button)
{
	CloseScreen();
}

event Tick( float deltaTime )
{
	local XComTacticalController XTC;

	super.Tick( deltaTime );

	XTC = XComTacticalController(PC);
	if (XTC != none && XTC.GetCursor().bHidden)
	{
		XTC.GetCursor().SetVisible(true);
	}
	
}

DefaultProperties
{
	m_iCurrentSelection = 0;
	MAX_OPTIONS = -1;
	m_bIsIronman = false;

	Package   = "/ package/gfxPauseMenu/PauseMenu";
	MCName      = "thePauseMenu";

	InputState= eInputState_Consume;
	bConsumeMouseEvents = true;

	bAlwaysTick = true
	bShowDuringCinematic = true
}
