//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIShellDifficulty.uc
//  AUTHOR:  Brit Steiner       -- 01/25/12
//           Tronster           -- 04/13/12
//  PURPOSE: Controls the difficulty menu in the shell SP game. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIShellDifficulty extends UIScreen;

var localized string m_strSelectDifficulty;
var localized string m_strChangeDifficulty;

var localized array<string>  m_arrDifficultyTypeStrings;
var localized array<string>  m_arrDifficultyDescStrings;

var localized string m_strDifficultyEnableTutorial;
var localized string m_strDifficultyEnableProgeny;
var localized string m_strDifficultyEnableSlingshot;
var localized string m_strDifficultyEnableIronman;
var localized string m_strDifficultySuppressFirstTimeNarrativeVO;

var localized string m_strDifficultyTutorialDesc;
var localized string m_strDifficultyProgenyDesc;
var localized string m_strDifficultySlingshotDesc;
var localized string m_strDifficultyIronmanDesc;
var localized string m_strDifficultySuppressFirstTimeNarrativeVODesc;

var localized string m_strDifficulty_Back;
var localized string m_strDifficulty_ToggleAdvanced;
var localized string m_strDifficulty_ToggleAdvancedExit;
var localized string m_strDifficulty_Accept;
var localized string m_strDifficulty_SecondWaveButtonLabel;

var localized string m_strControlTitle;
var localized string m_strControlBody;
var localized string m_strControlOK;
var localized string m_strControlCancel;

var localized string m_strFirstTimeTutorialTitle;
var localized string m_strFirstTimeTutorialBody;
var localized string m_strFirstTimeTutorialYes;
var localized string m_strFirstTimeTutorialNo;

var localized string m_strChangeDifficultySettingTitle;
var localized string m_strChangeDifficultySettingBody;
var localized string m_strChangeDifficultySettingYes;
var localized string m_strChangeDifficultySettingNo;

var localized string m_strInvalidTutorialClassicDifficulty;

var localized string m_strIronmanTitle;
var localized string m_strIronmanBody;
var localized string m_strIronmanOK;
var localized string m_strIronmanCancel;

var localized string m_strIronmanLabel;
var localized string m_strTutorialLabel;

var localized string m_strTutorialOnImpossible;
var localized string m_strTutorialNoChangeToImpossible;
var localized string m_strNoChangeInGame;

var localized string m_strWaitingForSaveTitle;
var localized string m_strWaitingForSaveBody;
var UITextTooltip ActiveTooltip;
//</workshop>

var UIList           m_List;
var UIButton         m_FirstTimeVOButton;
var UIButton         m_CancelButton;
var UILargeButton    m_StartButton;

var UIMechaListItem  m_TutorialMechaItem;
var UIMechaListItem  m_FirstTimeVOMechaItem;
var UIMechaListItem  m_SubtitlesMechaItem;
var UIButton		 m_TutorialButton;

var int  m_iSelectedDifficulty;

var bool m_bControlledStart;
var bool m_bIronmanFromShell;
var bool m_bFirstTimeNarrative;

var bool m_bShowedFirstTimeTutorialNotice;
var bool m_bShowedFirstTimeChangeDifficultyWarning;
var bool m_bCompletedControlledGame;
var bool m_bReceivedIronmanWarning;

var bool m_bSaveInProgress;

var bool m_bIsPlayingGame;
var bool m_bViewingAdvancedOptions;

var int m_iOptIronMan;
var int m_iOptTutorial;
var int m_iOptProgeny;
var int m_iOptSlingshot;
var int m_iOptFirstTimeNarrative;

var array<name> EnabledOptionalNarrativeDLC;

var UIShellStrategy DevStrategyShell;
var UINavigationHelp NavHelp;

//----------------------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local string strDifficultyAccept;

	super.InitScreen(InitController, InitMovie, InitName);

	InitCheckboxValues();

	NavHelp = GetNavHelp();
	m_List = Spawn(class'UIList', self);
	m_List.InitList('difficultyListMC');
	m_List.Navigator.LoopSelection = false;
	m_List.Navigator.LoopOnReceiveFocus = true;
	m_List.OnItemClicked = OnDifficultyDoubleClick;
	m_List.Navigator.LoopSelection = false;
	m_List.bPermitNavigatorToDefocus = true; //Another case of the SAFEGUARD_TO_PREVENT_FOCUS_LOSS hack causing problems 

	m_TutorialMechaItem = Spawn(class'UIMechaListItem', self);
	m_TutorialMechaItem.InitListItem();
	Navigator.AddControl(m_TutorialMechaItem);
	m_TutorialMechaItem.SetPosition(-425, 290);

	// Need this here to disable the flash element on the stage. 
	m_TutorialButton = Spawn(class'UIButton', self);
	m_TutorialButton.bIsNavigable = false;
	m_TutorialButton.InitButton('difficultyTutorialButton');
	m_TutorialButton.Hide();
	m_TutorialButton.DisableNavigation();

	m_FirstTimeVOButton = Spawn(class'UIButton', self);
	m_FirstTimeVOButton.InitButton('difficultySecondWaveButton');
	m_FirstTimeVOButton.Hide();
	m_FirstTimeVOButton.DisableNavigation();

	m_FirstTimeVOMechaItem = Spawn(class'UIMechaListItem', self);
	m_FirstTimeVOMechaItem.InitListItem();
	m_FirstTimeVOMechaItem.SetPosition(-425, 330);
	Navigator.AddControl(m_FirstTimeVOMechaItem);

	m_SubtitlesMechaItem = Spawn(class'UIMechaListItem', self);
	m_SubtitlesMechaItem.InitListItem();
	m_SubtitlesMechaItem.SetPosition(-425, 370);
	Navigator.AddControl(m_SubtitlesMechaItem);

	m_CancelButton = Spawn(class'UIButton', self);
	m_CancelButton.InitButton('difficultyCancelButton', m_strDifficulty_Back, OnButtonCancel);
	if( `ISCONTROLLERACTIVE )
		m_CancelButton.Hide();
	m_Cancelbutton.DisableNavigation();

	m_StartButton = Spawn(class'UILargeButton', self);
	strDifficultyAccept = (m_bIsPlayingGame) ? m_strChangeDifficulty : m_strDifficulty_Accept;
	
	if( `ISCONTROLLERACTIVE )
	{
		m_StartButton.InitLargeButton('difficultyLaunchButton', "", "", UIIronMan);
		m_StartButton.SetY(400);
		m_StartButton.DisableNavigation();
	}
	else
	{
		m_StartButton.InitLargeButton('difficultyLaunchButton', strDifficultyAccept, "", UIIronMan);
		m_StartButton.SetY(400);
	}

	m_StartButton.OnSizeRealized = RefreshStartButtonLocation;
	UpdateStartButtonText();

	// These player profile flags will change what options are defaulted when this menu comes up
	// SCOTT RAMSAY/RYAN BAKER: Has the player ever completed the strategy tutorial?
	m_bCompletedControlledGame = true; // `BATTLE.STAT_GetProfileStat(eProfile_TutorialComplete) > 0; // Ryan Baker - Hook up when we are ready.
	// SCOTT RAMSAY: Has the player ever received the ironman warning?
	m_bReceivedIronmanWarning = false;

	`XPROFILESETTINGS.Data.ClearGameplayOptions();

	if (m_bIsPlayingGame)
	{
		m_TutorialMechaItem.DisableNavigation();
		m_FirstTimeVOMechaItem.DisableNavigation();
		m_SubtitlesMechaItem.DisableNavigation();
	}
	//If we came from the dev strategy shell and opted for the cheat start, then just launch into the game after setting our settings
	DevStrategyShell = UIShellStrategy(Movie.Pres.ScreenStack.GetScreen(class'UIShellStrategy'));
	if(DevStrategyShell != none && DevStrategyShell.m_bCheatStart)
	{
		m_bControlledStart = false; // disable the tutorial
		OnDifficultyConfirm(m_StartButton);
	}

	Navigator.SetSelected(m_StartButton);
	m_List.Navigator.SetSelected(m_List.GetItem(m_List.SelectedIndex));
}

simulated function InitCheckboxValues()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	History = `XCOMHISTORY;
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));

	m_bShowedFirstTimeTutorialNotice = `XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting;

	if(CampaignSettingsStateObject != none && CampaignSettingsStateObject.bCheatStart)
	{
		m_bControlledStart = false;
	}
	else
	{
		m_bControlledStart = !`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting;
		m_bIronmanFromShell = false;
		m_bFirstTimeNarrative = false;  //RAM - TODO - enable / disable based on whether the campaign has been played before or not
	}
}

//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	super.OnInit();

	SetX(500);
	BuildMenu();
}

//----------------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	//local UIPanel CurrentSelection;

	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;

	if(m_bSaveInProgress)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return true;
	}

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:

		//CurrentSelection = Navigator.GetSelected();
		//if( CurrentSelection != None )
		//{
		//	bHandled = CurrentSelection.OnUnrealCommand(cmd, arg);
		//}
		UIIronMan(m_StartButton);
		return true;
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		OnUCancel();
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
	case class'UIUtilities_Input'.const.FXS_ARROW_UP:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
	case class'UIUtilities_Input'.const.FXS_KEY_W:
		PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
	case class'UIUtilities_Input'.const.FXS_KEY_S:
		PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
		break;

	default:
		bHandled = false;
	}

	//Refresh data as our selection may have changed
	RefreshDescInfo();

	return bHandled || super.OnUnrealCommand(cmd, arg);
}


//----------------------------------------------------------------------------

simulated function BuildMenu()
{
	local UIMechaListItem SpawnedItem;
	local string strDifficultyTitle, strDifficultyAccept;
	local int i;

	// Title
	strDifficultyTitle = (m_bIsPlayingGame) ? m_strChangeDifficulty : m_strSelectDifficulty;
	strDifficultyAccept = (m_bIsPlayingGame) ? m_strChangeDifficulty : m_strDifficulty_Accept;
	AS_SetDifficultyMenu(strDifficultyTitle, m_strDifficulty_ToggleAdvanced, m_strDifficulty_SecondWaveButtonLabel, strDifficultyAccept, m_strDifficulty_Back);

	if(Movie.Pres.m_eUIMode == eUIMode_Shell)
		m_iSelectedDifficulty = 1; //Default to normal 
	else
		m_iSelectedDifficulty = `DIFFICULTYSETTING;  //Get the difficulty from the game

	while(m_List.itemCount < m_arrDifficultyTypeStrings.Length)
	{
		SpawnedItem = Spawn(class'UIMechaListItem', m_List.ItemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.SetWidgetType(EUILineItemType_Checkbox);
	}

	// DIFFICULTY CHECKBOXES
	for(i = 0; i < m_arrDifficultyTypeStrings.Length; ++i)
	{
		UIMechaListItem(m_List.GetItem(i)).UpdateDataCheckbox(m_arrDifficultyTypeStrings[i], "", m_iSelectedDifficulty == i, OnCheckboxChanged);
		UIMechaListItem(m_List.GetItem(i)).Checkbox.SetReadOnly(i >= eDifficulty_Classic && `REPLAY.bInTutorial);
		UIMechaListItem(m_List.GetItem(i)).SetDisabled(i >= eDifficulty_Classic && `REPLAY.bInTutorial);
	}

	Navigator.SetSelected(m_List);
	m_List.SetSelectedIndex(0);
	m_List.GetItem(0).Navigator.SelectFirstAvailable();
	Navigator.OnSelectedIndexChanged = OnSelectedIndexChanged;
	m_FirstTimeVOMechaItem.UpdateDataCheckbox(m_strDifficultySuppressFirstTimeNarrativeVO, "", m_bFirstTimeNarrative, UpdateFirstTimeNarrative, OnClickFirstTimeVO);
	//m_FirstTimeVOMechaItem.UpdateDataCheckbox(m_strDifficultySuppressFirstTimeNarrativeVO, "", m_bFirstTimeNarrative, UpdateFirstTimeNarrative);
	m_FirstTimeVOMechaItem.Checkbox.SetReadOnly(m_bIsPlayingGame);
	m_FirstTimeVOMechaItem.BG.SetTooltipText(m_strDifficultySuppressFirstTimeNarrativeVODesc, , , 10, , , , 0.0f);
	UpdateFirstTimeNarrative(m_FirstTimeVOMechaItem.Checkbox);

	m_TutorialMechaItem.UpdateDataCheckbox(m_strDifficultyEnableTutorial, "", m_bControlledStart, ConfirmControlDialogue, OnClickedTutorial);
	//m_TutorialMechaItem.UpdateDataCheckbox(m_strDifficultyEnableTutorial, "", m_bControlledStart, ConfirmControlDialogue);
	m_TutorialMechaItem.Checkbox.SetReadOnly(m_bIsPlayingGame);
	m_TutorialMechaItem.BG.SetTooltipText(m_strDifficultyTutorialDesc, , , 10, , , , 0.0f);

	m_SubtitlesMechaItem.UpdateDataCheckbox(class'UIOptionsPCScreen'.default.m_strInterfaceLabel_ShowSubtitles,"", `XPROFILESETTINGS.Data.m_bSubtitles, UpdateSubtitles, OnClickSubtitles);
	//m_SubtitlesMechaItem.UpdateDataCheckbox(class'UIOptionsPCScreen'.default.m_strInterfaceLabel_ShowSubtitles,"", `XPROFILESETTINGS.Data.m_bSubtitles, UpdateSubtitles);
	m_SubtitlesMechaItem.BG.SetTooltipText(class'UIOptionsPCScreen'.default.m_strInterfaceLabel_ShowSubtitles_Desc, , , 10, , , , 0.0f);

	if(m_bIsPlayingGame)
	{
		//m_FirstTimeVOMechaItem.SetDisabled(true, m_strNoChangeInGame);
		//m_TutorialMechaItem.SetDisabled(true, m_strNoChangeInGame);
		m_FirstTimeVOMechaItem.Hide();
		m_TutorialMechaItem.Hide();
		m_SubtitlesMechaItem.Hide();
		m_FirstTimeVOMechaItem.DisableNavigation();
		m_TutorialMechaItem.DisableNavigation();
	}

	//m_List.SetSelectedIndex(1);

	RefreshDescInfo();
	UpdateNavHelp();
}

simulated function OnSelectedIndexChanged(int Index)
{
	local UIMechaListItem ListItem;

	if (ActiveTooltip != none)
	{
		XComPresentationLayerBase(Owner).m_kTooltipMgr.DeactivateTooltip(ActiveTooltip, true);
		ActiveTooltip = none;
	}

	ListItem = UIMechaListItem(Navigator.GetSelected());
	if (ListItem != none)
	{
		if (ListItem.BG.bHasTooltip)
		{
			ActiveTooltip = UITextTooltip(XComPresentationLayerBase(Owner).m_kTooltipMgr.GetTooltipByID(ListItem.BG.CachedTooltipId));
			if (ActiveTooltip != none)
			{
				ActiveTooltip.SetFollowMouse(false);
				ActiveTooltip.SetDelay(0.6);
				ActiveTooltip.SetTooltipPosition(150.0, 720.0);
				XComPresentationLayerBase(Owner).m_kTooltipMgr.ActivateTooltip(ActiveTooltip);
			}
		}
	}

	PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
}
simulated function UINavigationHelp GetNavHelp()
{
	local UINavigationHelp Result;
	Result = PC.Pres.GetNavHelp();
	if(Result == None)
	{
		if (`PRES != none) // Tactical
			Result = Spawn(class'UINavigationHelp', Movie.Stack.GetScreen(class'UIMouseGuard')).InitNavHelp();
		
		else if (`HQPRES != none) // Strategy
			Result = `HQPRES.m_kAvengerHUD.NavHelp;
	}
	return Result;
}
simulated function UpdateNavHelp()
{
	//it is possible to lose focus before the flash assets are initialized -JTA 2016/6/13
	if(!bIsFocused)
		return;

	if(NavHelp == None)
		NavHelp = Movie.Pres.GetNavHelp();
	NavHelp.ClearButtonHelp();
	//<bsg> TTP_4868_HELP_BUTTON_ALIGNMENT_INCONSISTENT_PAUSE_MENUS jneal 06/22/16
	//INS:
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	//</bsg>
	NavHelp.AddBackButton();
	NavHelp.AddSelectNavHelp();
}

//This function modifies the start button to say "next" if the next screen will give you more options
//Start button (displayed on consoles as a navhelp) doesn't always pull you directly into a game
simulated function UpdateStartButtonText()
{
	local String strLabel;

	if(m_bIsPlayingGame)
		strLabel = m_strChangeDifficulty;
	else if(!m_TutorialMechaItem.Checkbox.bChecked)
		strLabel = class'UIUtilities_Text'.default.m_strGenericNext;
	else
		strLabel = m_strDifficulty_Accept;

	if( `ISCONTROLLERACTIVE )
		strLabel = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -2) @ strLabel;

	m_StartButton.SetText(strLabel);
}

simulated function OnClickedTutorial()
{
	if(m_iSelectedDifficulty < eDifficulty_Classic)
	{
		m_TutorialMechaItem.Checkbox.SetChecked(!m_TutorialMechaItem.Checkbox.bChecked);
	}
}

simulated function OnClickFirstTimeVO()
{
	m_FirstTimeVOMechaItem.Checkbox.SetChecked(!m_FirstTimeVOMechaItem.Checkbox.bChecked);
}

simulated function OnClickSubtitles()
{
	m_SubtitlesMechaItem.Checkbox.SetChecked(!m_SubtitlesMechaItem.Checkbox.bChecked);
}

// Lower pause screen
simulated public function OnUCancel()
{
	if (ActiveTooltip != none)
	{
		XComPresentationLayerBase(Owner).m_kTooltipMgr.DeactivateTooltip(ActiveTooltip, true);
		ActiveTooltip = none;
	}
	if(bIsInited && !IsTimerActive(nameof(StartIntroMovie)))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		`XPROFILESETTINGS.Data.ClearGameplayOptions();  // These are set on the player profile, so we should clear them for next time...
		Movie.Stack.Pop(self);
	}
}

simulated public function OnButtonCancel(UIButton ButtonControl)
{
	if (ActiveTooltip != none)
	{
		XComPresentationLayerBase(Owner).m_kTooltipMgr.DeactivateTooltip(ActiveTooltip, true);
		ActiveTooltip = none;
	}
	if(bIsInited && !IsTimerActive(nameof(StartIntroMovie)))
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		`XPROFILESETTINGS.Data.ClearGameplayOptions();  // These are set on the player profile, so we should clear them for next time...
		Movie.Stack.Pop(self);
	}
}

simulated function ConfirmTutorialDialogue(UIButton ButtonControl)
{
	if(m_iSelectedDifficulty >= eDifficulty_Classic)
	{
		if(ButtonControl.IsSelected && !m_bIsPlayingGame)
			ShowSimpleDialog(m_strInvalidTutorialClassicDifficulty);

		ForceTutorialOff();
		return;
	}
	else
	{
		GrantTutorialReadAccess();
	}

	m_bControlledStart = !ButtonControl.IsSelected;
	ButtonControl.SetSelected(m_bControlledStart);
	if(m_bControlledStart)
	{
		`XPROFILESETTINGS.Data.SetGameplayOption(eGO_Marathon, false);    // Marathon and tutorial don't play nice
	}
	else
	{
		if(`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting == false)
		{
			`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting = true; //Only allow this to be activate for this profile, never toggled back. 
			SaveSettings();
		}
	}
}

simulated function ConfirmFirstTimeVODialogue(UIButton ButtonControl)
{
	m_bFirstTimeNarrative = !m_bFirstTimeNarrative;
	ButtonControl.SetSelected(m_bFirstTimeNarrative);
}

/*simulated function OnShowGameplayToggles()
{
XComPresentationLayerBase(Owner).UISecondWave();
}*/

simulated function OnCheckboxChanged(UICheckbox Checkbox)
{
	OnDifficultyDoubleClick(m_List, m_List.SelectedIndex);
}

simulated function OnDifficultyDoubleClick(UIList ContainerList, int ItemIndex)
{
	local UICheckbox checkedBox;
	if(`ONLINEEVENTMGR.bTutorial && ItemIndex >= eDifficulty_Classic)
	{
		return;
	}
	if (UIMechaListItem(m_List.GetItem(ItemIndex)).bDisabled || 
		UIMechaListItem(m_List.GetItem(ItemIndex)).Checkbox.bReadOnly)
	{
		return;
	}
	checkedBox = UIMechaListItem(m_List.GetItem(ItemIndex)).Checkbox;
	checkedBox.SetChecked(true);
	OnDifficultySelect(checkedBox);
}

simulated public function OnDifficultySelect(UICheckbox CheckboxControl)
{
	local int i;
	i = m_List.GetItemIndex(CheckboxControl);

	// we found the checkbox in our list
	if(i != -1)
	{
		//we just checked on a new difficulty
		if(i != m_iSelectedDifficulty && CheckboxControl.bChecked)
		{
			if(`REPLAY.bInTutorial && i >= eDifficulty_Classic)
			{
				//Stop that! We don't let you switch to classic mode while the tutorial is in progress 				
				UIMechaListItem(m_List.GetItem(m_iSelectedDifficulty)).Checkbox.SetChecked(true);
				UIMechaListItem(m_List.GetItem(i)).Checkbox.SetChecked(false);
				Movie.Pres.PlayUISound(eSUISound_MenuClose);
				return;
			}
			else
			{
				UIMechaListItem(m_List.GetItem(m_iSelectedDifficulty)).Checkbox.SetChecked(false, false);

				m_iSelectedDifficulty = i;
				if (m_iSelectedDifficulty >= eDifficulty_Classic)
				{
					ForceTutorialOff();
				}
				else
				{
					GrantTutorialReadAccess();
				}
			}
		}
	}

	RefreshDescInfo();

	// If we get here the user tried to disable an option, make sure to re-enable it
	UIMechaListItem(m_List.GetItem(m_iSelectedDifficulty)).Checkbox.SetChecked(true);
}
simulated public function OnDifficultyConfirm(UIButton ButtonControl)
{
	local TDialogueBoxData kDialogData;
	local XComGameStateHistory History;
	local XComGameState StrategyStartState, NewGameState;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_Objective ObjectiveState;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local bool EnableTutorial;
	local int idx;

	//BAIL if the save is in progress. 
	if(m_bSaveInProgress && Movie.Pres.m_kProgressDialogStatus == eProgressDialog_None)
	{
		WaitingForSaveToCompletepProgressDialog();
		return;
	}

	History = `XCOMHISTORY;
	EventManager = `ONLINEEVENTMGR;

	//This popup should only be triggered when you are in the shell == not playing the game, and difficulty set to less than classic. 
	if(!m_bIsPlayingGame && !m_bShowedFirstTimeTutorialNotice && !m_TutorialMechaItem.Checkbox.bChecked && !m_bIronmanFromShell  && m_iSelectedDifficulty < eDifficulty_Classic)
	{
		if(DevStrategyShell == none || !DevStrategyShell.m_bCheatStart)
		{
			PlaySound(SoundCue'SoundUI.HUDOnCue');

			kDialogData.eType = eDialog_Normal;
			kDialogData.strTitle = m_strFirstTimeTutorialTitle;
			kDialogData.strText = m_strFirstTimeTutorialBody;
			kDialogData.strAccept = m_strFirstTimeTutorialYes;
			kDialogData.strCancel = m_strFirstTimeTutorialNo;
			kDialogData.fnCallback = ConfirmFirstTimeTutorialCheckCallback;

			Movie.Pres.UIRaiseDialog(kDialogData);
			return;
		}
	}

	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));

	// Warn if the difficulty level is changing, that this could invalidate the ability to earn certain achievements.
	if(CampaignSettingsStateObject != none && m_bIsPlayingGame && !m_bShowedFirstTimeChangeDifficultyWarning &&
	   (CampaignSettingsStateObject.LowestDifficultySetting >= 2 || m_iSelectedDifficulty >= 2)) // is Classic or will become Classic or higher difficulty (where achievements based on difficulty kick-in)
	{
		PlaySound(SoundCue'SoundUI.HUDOnCue');

		kDialogData.eType = eDialog_Warning;
		kDialogData.strTitle = m_strChangeDifficultySettingTitle;
		kDialogData.strText = m_strChangeDifficultySettingBody;
		kDialogData.strAccept = m_strChangeDifficultySettingYes;
		kDialogData.strCancel = m_strChangeDifficultySettingNo;
		kDialogData.fnCallback = ConfirmChangeDifficultySettingCallback;

		Movie.Pres.UIRaiseDialog(kDialogData);
		return;
	}

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	if(m_bIsPlayingGame)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Changing User-Selected Difficulty to " $ m_iSelectedDifficulty);

		CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		CampaignSettingsStateObject = XComGameState_CampaignSettings(NewGameState.CreateStateObject(class'XComGameState_CampaignSettings', CampaignSettingsStateObject.ObjectID));
		CampaignSettingsStateObject.SetDifficulty(m_iSelectedDifficulty, m_bIsPlayingGame);
		NewGameState.AddStateObject(CampaignSettingsStateObject);

		`GAMERULES.SubmitGameState(NewGameState);
		
		// Perform any DLC-specific difficulty updates
		DLCInfos = EventManager.GetDLCInfos(false);
		for (idx = 0; idx < DLCInfos.Length; ++idx)
		{
			DLCInfos[idx].OnDifficultyChanged();
		}

		Movie.Stack.Pop(self);
	}
	else
	{
		EnableTutorial = m_iSelectedDifficulty < eDifficulty_Classic && m_bControlledStart;

		//bsg-mfawcett(08.21.16): fix for TTP 6733 - reset cached cards so that all our missions can be found/used again
		`TACTICALMISSIONMGR.ResetCachedCards();

		//If we are NOT going to do the tutorial, we setup our campaign starting state here. If the tutorial has been selected, we wait until it is done
		//to create the strategy start state.
		if(!EnableTutorial || (DevStrategyShell != none && DevStrategyShell.m_bSkipFirstTactical))
		{
			//We're starting a new campaign, set it up
			StrategyStartState = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(, , EnableTutorial, m_iSelectedDifficulty, m_bFirstTimeNarrative, EnabledOptionalNarrativeDLC, , m_bIronmanFromShell);

			// The CampaignSettings are initialized in CreateStrategyGameStart, so we can pull it from the history here
			CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

			//Since we just created the start state above, the settings object is still writable so just update it with the settings from the new campaign dialog
			CampaignSettingsStateObject.SetStartTime(StrategyStartState.TimeStamp);

			//See if we came from the dev strategy shell. If so, set the dev shell options...		
			if(DevStrategyShell != none)
			{
				CampaignSettingsStateObject.bCheatStart = DevStrategyShell.m_bCheatStart;
				CampaignSettingsStateObject.bSkipFirstTactical = DevStrategyShell.m_bSkipFirstTactical;
			}

			CampaignSettingsStateObject.SetDifficulty(m_iSelectedDifficulty);
			CampaignSettingsStateObject.SetIronmanEnabled(m_bIronmanFromShell);

			// on Debug Strategy Start, disable the intro movies on the first objective
			if(CampaignSettingsStateObject.bCheatStart)
			{
				foreach StrategyStartState.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
				{
					if(ObjectiveState.GetMyTemplateName() == 'T1_M0_FirstMission')
					{
						ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_GameIntro");
						ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_WelcomeToHQ");
						ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_WelcomeToTheResistance");
					}
				}
			}
		}

		X2ImageCaptureManager(`XENGINE.GetImageCaptureManager()).ClearStore();
		//Hide the UI as the user confirms, so that it doesn't flash up as everything gets popped off the stack.
		//INS:
		Movie.Pres.HideUIForCinematics();

		//Let the screen fade into the intro
		SetTimer(0.6f, false, nameof(StartIntroMovie));
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.5);

		if(EnableTutorial && !((DevStrategyShell != none && DevStrategyShell.m_bSkipFirstTactical)))
		{
			//Controlled Start / Demo Direct
			`XCOMHISTORY.ResetHistory();
			EventManager.bTutorial = true;
			EventManager.bInitiateReplayAfterLoad = true;

			// Save campaign settings			
			EventManager.CampaignDifficultySetting = m_iSelectedDifficulty;
			EventManager.CampaignLowestDifficultySetting = m_iSelectedDifficulty;
			EventManager.CampaignbIronmanEnabled = m_bIronmanFromShell;
			EventManager.CampaignbTutorialEnabled = true;
			EventManager.CampaignbSuppressFirstTimeNarrative = m_bFirstTimeNarrative;
			EventManager.CampaignOptionalNarrativeDLC = EnabledOptionalNarrativeDLC;

			for(idx = EventManager.GetNumDLC() - 1; idx >= 0; idx--)
			{
				EventManager.CampaignRequiredDLC.AddItem(EventManager.GetDLCNames(idx));
			}


			SetTimer(1.0f, false, nameof(LoadTutorialSave));
		}
		else
		{
			SetTimer(1.0f, false, nameof(DeferredConsoleCommand));
		}
	}
}

function StartIntroMovie()
{
	local XComEngine Engine;

	Engine = `XENGINE;
		Engine.PlaySpecificLoadingMovie("CIN_TP_Intro.bk2", "X2_001_Intro"); //Play the intro movie as a loading screen
	Engine.PlayLoadMapMovie(-1);
}

function DeferredConsoleCommand()
{
	ConsoleCommand("open Avenger_Root?game=XComGame.XComHeadQuartersGame");
}

function LoadTutorialSave()
{
	`ONLINEEVENTMGR.LoadSaveFromFile(class'UIShell'.default.strTutorialSave);
}

simulated function WaitingForSaveToCompletepProgressDialog()
{
	local TProgressDialogData kDialog;

	kDialog.strTitle = m_strWaitingForSaveTitle;
	kDialog.strDescription = m_strWaitingForSaveBody;
	Movie.Pres.UIProgressDialog(kDialog);
}

simulated function CloseSaveProgressDialog()
{
	Movie.Pres.UICloseProgressDialog();
	OnDifficultyConfirm(m_StartButton);
}


//------------------------------------------------------
function UIIronMan(UIButton ButtonControl)
{
	if( m_bIsPlayingGame )
	{
		OnDifficultyConfirm(ButtonControl);
	}
	else 
	{
		if( m_bControlledStart ) // Ironman and tutorial do not mix
		{
			Movie.Pres.UIShellNarrativeContent();
		}
		else
		{
			Movie.Pres.UIIronMan();
		}
	}
}


function ConfirmIronmanDialogue(UIButton ButtonControl)
{
	local TDialogueBoxData kDialogData;

	PlaySound(SoundCue'SoundUI.HUDOnCue');

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strIronmanTitle;
	kDialogData.strText = m_strIronmanBody;
	kDialogData.strAccept = m_strIronmanOK;
	kDialogData.strCancel = m_strIronmanCancel;
	kDialogData.fnCallback = ConfirmIronmanCallback;

	Movie.Pres.UIRaiseDialog(kDialogData);
	Show();
}

simulated public function ConfirmIronmanCallback(eUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		PlaySound(SoundCue'SoundUI.OverWatchCue');

	}
	else if(eAction == eUIAction_Cancel)
	{
		PlaySound(SoundCue'SoundUI.HUDOffCue');
	}

	UpdateIronman(eAction == eUIAction_Accept);
	OnDifficultyConfirm(m_StartButton);
}

//------------------------------------------------------
function ConfirmControlDialogue(UICheckbox CheckboxControl)
{
	local TDialogueBoxData kDialogData;
	UpdateStartButtonText();

	// Can't enable any of the tutorial options with classic difficulty selected
	if(m_iSelectedDifficulty >= eDifficulty_Classic)
	{
		ForceTutorialOff();
		return;
	}
	else
	{
		GrantTutorialReadAccess();
	}

	//Only trigger the message when turning this off.
	if(!CheckboxControl.bChecked)
	{
		PlaySound(SoundCue'SoundUI.HUDOnCue');

		kDialogData.eType = eDialog_Normal;
		kDialogData.strTitle = m_strControlTitle;
		kDialogData.strText = m_strControlBody;
		kDialogData.strAccept = m_strControlOK;
		kDialogData.strCancel = m_strControlCancel;
		kDialogData.fnCallback = ConfirmControlCallback;

		Movie.Pres.UIRaiseDialog(kDialogData);
	}
	else
	{
		UpdateTutorial(CheckboxControl);
	}
}

simulated public function ConfirmControlCallback(eUIAction eAction)
{
	local UICheckbox kCheckbox;
	local array<string> mouseOutArgs;

	PlaySound(SoundCue'SoundUI.HUDOffCue');
	kCheckBox = m_TutorialMechaItem.Checkbox;

	mouseOutArgs.AddItem("");

	kCheckbox.OnMouseEvent(class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT, mouseOutArgs);
	//Only trigger the message when turning this off.
	if(!kCheckBox.bChecked)
	{
		if(eAction == eUIAction_Cancel)
		{
			kCheckbox.SetChecked(true);
			`XPROFILESETTINGS.Data.SetGameplayOption(eGO_Marathon, false);    // Marathon and tutorial don't play nice
			Movie.Pres.m_kGameToggles.UpdateData();
		}

		UpdateTutorial(kCheckBox);
	}
	else
	{
		UpdateTutorial(kCheckBox);
	}
}

simulated public function ConfirmFirstTimeTutorialCheckCallback(eUIAction eAction)
{
	PlaySound(SoundCue'SoundUI.HUDOffCue');

	if(eAction == eUIAction_Accept)
	{
		if(!m_TutorialMechaItem.Checkbox.bChecked)
			OnClickedTutorial();

		m_bControlledStart = true;
		`XPROFILESETTINGS.Data.SetGameplayOption(eGO_Marathon, false);    // Marathon and tutorial don't play nice
		if(Movie.Pres.m_kGameToggles != none)
			Movie.Pres.m_kGameToggles.UpdateData();
	}
	else
	{
		m_bControlledStart = false;
	}
	// Don't need to set Checkbox to false, this popup won't show up if it's set to true - sbatista 6/26/13

	m_bShowedFirstTimeTutorialNotice = true;
	OnDifficultyConfirm(m_StartButton);
}

simulated public function ConfirmChangeDifficultySettingCallback(eUIAction eAction)
{
	PlaySound(SoundCue'SoundUI.HUDOffCue');

	if(eAction == eUIAction_Accept)
	{
		m_bShowedFirstTimeChangeDifficultyWarning = true;
		OnDifficultyConfirm(m_StartButton);
	}
}

// UPDATE CHECKBOX FUNCTIONS

simulated function ForceTutorialOff()
{
	m_bControlledStart = false;

	//Refresh check this way, to not trigger the popups
	m_TutorialMechaItem.Checkbox.SetChecked(false);

	if(!m_bIsPlayingGame)
	{
		m_TutorialMechaItem.Checkbox.SetReadOnly(true);
	}
}

simulated function GrantTutorialReadAccess()
{
	if(!m_bIsPlayingGame)
	{
		m_TutorialMechaItem.Checkbox.SetReadOnly(false);
	}
}

simulated function UpdateTutorial(UICheckbox CheckboxControl)
{
	// Can't enable any of the tutorial options with classic difficulty selected
	if(m_iSelectedDifficulty >= eDifficulty_Classic)
	{
		if(CheckboxControl.bChecked && !m_bIsPlayingGame)
			ShowSimpleDialog(m_strInvalidTutorialClassicDifficulty);

		ForceTutorialOff();
		return;
	}
	else
	{
		GrantTutorialReadAccess();
	}

	m_bControlledStart = CheckboxControl.bChecked;
	if(m_bControlledStart)
	{
		`XPROFILESETTINGS.Data.SetGameplayOption(eGO_Marathon, false);    // Marathon and tutorial don't play nice
	}
	else
	{
		if(`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting == false)
		{
			`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting = true; //Only allow this to be activate for this profile, never toggled back. 
			SaveSettings();
		}
	}
}

simulated function UpdateIronman(bool bIronMan)
{
	m_bIronmanFromShell = bIronMan;
}

simulated function UpdateFirstTimeNarrative(UICheckbox CheckboxControl)
{
	m_bFirstTimeNarrative = CheckboxControl.bChecked; //bool(m_hAdvancedWidgetHelper.GetCurrentValue(m_iOptFirstTimeNarrative));
}

simulated function UpdateSubtitles(UICheckbox CheckboxControl)
{
	`XPROFILESETTINGS.Data.m_bSubtitles = CheckboxControl.bChecked;
	`XPROFILESETTINGS.ApplyUIOptions();
	Movie.Pres.GetUIComm().RefreshSubtitleVisibility();
}

simulated function RefreshDescInfo()
{
	local string sDesc;

	sDesc = m_arrDifficultyDescStrings[m_iSelectedDifficulty];

	if(m_iSelectedDifficulty >= eDifficulty_Classic)
	{
		if(m_bIsPlayingGame && Movie.Pres.ISCONTROLLED())
			sDesc = sDesc @ class'UIUtilities_Text'.static.GetColoredText(m_strTutorialNoChangeToImpossible, eUIState_Warning);
		else if(Movie.Pres.m_eUIMode == eUIMode_Shell && m_iSelectedDifficulty == eDifficulty_Classic)
			sDesc = sDesc @ class'UIUtilities_Text'.static.GetColoredText(m_strTutorialOnImpossible, eUIState_Warning);
	}

	AS_SetDifficultyDesc(sDesc);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Show();
	UpdateNavHelp();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Hide();
	if(NavHelp != None)
		NavHelp.ClearButtonHelp();
}

simulated public function SaveSettings()
{
	m_bSaveInProgress = true;
	`ONLINEEVENTMGR.AddSaveProfileSettingsCompleteDelegate(SaveComplete);
	`ONLINEEVENTMGR.SaveProfileSettings(true);
}
simulated public function SaveComplete(bool bWasSuccessful)
{
	if(!bWasSuccessful)
	{
		SaveProfileFailedDialog();
	}

	`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate(SaveComplete);
	m_bSaveInProgress = false;

	if(Movie.Pres.m_kProgressDialogStatus != eProgressDialog_None)
	{
		CloseSaveProgressDialog();
	}
}

simulated public function SaveProfileFailedDialog()
{
	local TDialogueBoxData kDialogData;

	kDialogData.strText = (WorldInfo.IsConsoleBuild(CONSOLE_Xbox360)) ? class'UIOptionsPCScreen'.default.m_strSavingOptionsFailed360 : class'UIOptionsPCScreen'.default.m_strSavingOptionsFailed;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	XComPresentationLayerBase(Owner).UIRaiseDialog(kDialogData);
}

simulated function ShowSimpleDialog(string txt)
{
	local TDialogueBoxData kDialogData;

	kDialogData.strText = txt;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	XComPresentationLayerBase(Owner).UIRaiseDialog(kDialogData);
}

// FLASH COMMUNICATION
simulated function AS_InitBG(bool hasSecondWaveOption)
{
	Movie.ActionScriptVoid(MCPath$".InitBG");
}
simulated function AS_SetTitle(string title)
{
	Movie.ActionScriptVoid(MCPath$".SetTitle");
}
simulated function AS_SetDifficultyDesc(string desc)
{
	Movie.ActionScriptVoid(MCPath$".SetDifficultyDesc");
}
simulated function AS_SetAdvancedDesc(string desc)
{
	Movie.ActionScriptVoid(MCPath$".SetAdvancedDesc");
}
simulated function AS_SetAdvancedOptionsButton(string label, string icon)
{
	Movie.ActionScriptVoid(MCPath$".SetAdvancedOptionsButton");
}
simulated function AS_ToggleAdvancedOptions()
{
	Movie.ActionScriptVoid(MCPath$".ToggleAdvancedOptions");
}

simulated function AS_SetDifficultyMenu(string title, string tutorialLabel, string secondWaveLabel, string launchLabel, string CancelLabel)
{
	Movie.ActionScriptVoid(MCPath$".UpdateDifficultyMenu");
}

simulated function RefreshStartButtonLocation()
{
	m_StartButton.SetX(320 - m_StartButton.Width);
	m_StartButton.Show();
}

simulated function OnRemoved()
{
	super.OnRemoved();
	if(NavHelp != none)
		NavHelp.ClearButtonHelp();
}

//==============================================================================
//		CLEANUP:
//==============================================================================

event Destroyed()
{
	super.Destroyed();
}

DefaultProperties
{
	Package = "/ package/gfxDifficultyMenu/DifficultyMenu";
	LibID = "DifficultyMenu_Options"

		InputState = eInputState_Consume;
	m_bSaveInProgress = false;
	bConsumeMouseEvents = true

}
