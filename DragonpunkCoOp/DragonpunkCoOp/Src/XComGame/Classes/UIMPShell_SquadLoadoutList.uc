//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadLoadoutList.uc
//  AUTHOR:  Todd Smith  --  6/23/2015
//  PURPOSE: Screen to choose your squad.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadLoadoutList extends UIMPShell_Base
	abstract;

var localized string m_strAddNewSquadButtonText;
var localized string m_strCloneButtonText;
var localized string m_strCloneSquadNameSuffix;
var localized string m_strRenameButtonText;
var localized string m_strRenameSquadDialogHeader;
var localized string m_strDeleteButtonText;
var localized string m_strNextButtonText;
var localized string m_strConfirm;
var XComGameState m_kSquadLoadout;
var XComGameState m_kPreviewingLoadout;
var XComGameState m_kDeletingLoadout;
var XComGameState m_kRenamingLoadout;
var XComGameState m_kCloningLoadout;

var UIMPShell_SquadEditor SquadEditor;
var array<UIMPShell_SquadUnitInfoItem> UnitInfos;

var UIList SquadList;

// BEGIN taken from old UIMultiplayerLoadoutList -tsmith
var localized string m_strTitleLoading;
var localized string m_strPointTotalLabel;
var localized string m_strPointTotalPostfix;
var localized string m_strDeleteSet; 
var localized string m_strCreateNewLoadout;
var localized string m_strCloneSet;
var localized string m_strRenameSet;
var localized string m_strConfirmDeleteTitle;
var localized string m_strConfirmDeleteText;
var localized string m_strLangMismatchText;
var localized string m_strEnterNameHeader;
var localized string m_strDefaultSquadName;
var localized string m_strCloneNameDefaultSuffix;
var localized string m_strHiddenLoadoutTitle;
var localized string m_strHiddenLoadoutText;
var localized string m_strEditSquad;

// @TODO UI: check the old class for these variables and see what they did
var bool m_bSavingProfileSettings;
var bool m_bMismatchedLanguageLoadoutsSkipped;
var bool m_bSeenMismatchLanguageDialog;
// END taken from old UIMultiplayerLoadoutList -tsmith

var bool m_bKeyboardOpen;
var UINavigationHelp AnchoredNavHelp;
var UINavigationHelp IntegratedNavHelp;
var UIButton DeleteButton;
var UIButton RenameButton;
var UIButton CloneButton;
var UIButton ConfirmButton;

// screen to spawn and transition to when the editable squad item is clicked. -tsmith
var class<UIMPShell_SquadEditor> UISquadEditorClass;

var UILargeButton LaunchButton;
var localized string ConfirmMPAccountTitle;
var localized string ConfirmMPAccountMessage;
var int SelectedIndex;
var transient XComGameState SquadToEdit; //m_kSquadLoadout gets stomped when we gain/lose focus - need to cache this here
var localized string m_strLoadingSquadDataTitle;
var localized string m_strLoadingSquadDataText;
var localized string m_strCreatingNewSquadTitle;
var localized string m_strCreatingNewLoadoutText;
var bool bWaitingToCreateNewLoadout;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	SquadList = Spawn(class'UIList', self);
	SquadList.InitList('MPSquadList');
	SquadList.bStickyHighlight = false;
	SquadList.OnItemClicked = SquadListItemClicked;
	if(`ISCONTROLLERACTIVE)
	{
		SquadList.OnSelectionChanged = SetSelected;
	}
	SquadList.OnItemDoubleClicked = SquadListItemDoubleClicked;
	SquadList.Navigator.LoopOnReceiveFocus = true;
	SquadList.Navigator.LoopSelection = false;
	SquadList.Navigator.SelectFirstAvailable();

	AnchoredNavHelp = m_kMPShellManager.NavHelp;
	IntegratedNavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp('integratedHelpBarMC');
	IntegratedNavHelp.MC.FunctionNum("SetCenterHelpPadding", 100);

	Movie.UpdateHighestDepthScreens();
	
	//clear out the input repeat timers to prevent menu navigation from selecting items before the menu is fully initialized
	Movie.Pres.ClearInput();
}

simulated function OnInit()
{
	super.OnInit();

	UpdateNavHelp();
	
	CreateSquadList();
	CreateSquadInfoPanel();
	SelectFirstLoadout();
	InitLaunchButton();
	UpdateGamepadFocus();
	m_bKeyboardOpen = false;
}

//A child class can override this if there is no 'launch' functionality
//further use of 'LaunchButton' should always check to see if it exists
simulated function InitLaunchButton()
{
	LaunchButton = Spawn(class'UILargeButton', self);
	LaunchButton.bAnimateOnInit = true;
	LaunchButton.InitLargeButton('ContinueButton',class'UIUtilities_Text'.static.InjectImage(
	class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -13) @ m_strConfirm);
	
	LaunchButton.AnchorBottomRight();
	LaunchButton.SetVisible(false);
	LaunchButton.ShowBG(true);
}
function EditSquadButtonCallback()
{
	//Override
}
simulated function UpdateNavHelp()
{
	AnchoredNavHelp.ClearButtonHelp();
	AnchoredNavHelp.AddBackButton(BackButtonCallback);
	if(!Movie.IsMouseActive())
		return;

	if(DeleteButton == none)
	{
		DeleteButton = IntegratedNavHelp.AddLeftButton(m_strDeleteSet, , DeleteButtonCallback, m_kSquadLoadout == none);
		DeleteButton.OnClickedDelegate = DeleteClickedButtonCallback;

		Navigator.AddControl(DeleteButton);
	}

	if(CloneButton == none)
	{
		CloneButton = IntegratedNavHelp.AddCenterButton(m_strCloneSet, , CloneButtonCallback, m_kSquadLoadout == none, , class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
		CloneButton.OnClickedDelegate = CloneClickedButtonCallback;
		Navigator.AddControl(CloneButton);
	}

	if(RenameButton == none)
	{
		RenameButton = IntegratedNavHelp.AddCenterButton(m_strRenameSet, , RenameButtonCallback, m_kSquadLoadout == none, , class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
		RenameButton.OnClickedDelegate = RenameClickedButtonCallback;
		Navigator.AddControl(RenameButton);
	}

	if(ConfirmButton == none)
	{
		ConfirmButton = IntegratedNavHelp.AddRightButton(m_strConfirm, , NextButton, m_kSquadLoadout == none);
		ConfirmButton.OnClickedDelegate = NextClickedButton;
		
	}

	 UpdateNavHelpState();
}

//updates the navigation as 'help' instead of 'buttons'
simulated function UpdateNavHelpInGamepadMode()
{
	IntegratedNavHelp.ClearButtonHelp();
	if(m_kSquadLoadout != none)
	{
		//These are only visible when the list has a squad selected
		IntegratedNavHelp.AddCenterHelp(m_strEditSquad, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
		IntegratedNavHelp.AddCenterHelp(m_strCloneSet, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
		IntegratedNavHelp.AddCenterHelp(m_strDeleteSet, class'UIUtilities_Input'.const.ICON_RSCLICK_R3);		
	}
	else 
	{
		IntegratedNavHelp.AddCenterHelp(m_strCreateNewLoadout, class'UIUtilities_Input'.static.GetAdvanceButtonIcon()); //MP_SELECT_NAVHELP, BET, 2016-05-23
	}

	if (LaunchButton != None)
	{
		LaunchButton.SetVisible(m_kSquadLoadout != None && CanJoinGame());
	}
}
simulated function UpdateNavHelpState()
{
	//<workshop> GAMEPAD_NAV_HELP - JTA 2015/11/15
	if(!Movie.IsMouseActive())
	{
		UpdateNavHelpInGamepadMode();
		return;
	}
	DeleteButton.SetDisabled(m_kSquadLoadout == none);
	CloneButton.SetDisabled(m_kSquadLoadout == none);
	RenameButton.SetDisabled(m_kSquadLoadout == none);

	if(m_kSquadLoadout != none)
	{
		ConfirmButton.SetDisabled(!CanJoinGame());
		
		if(CanJoinGame())
			Navigator.AddControl(ConfirmButton);
		else
			Navigator.RemoveControl(ConfirmButton);
	}
	else
	{
		ConfirmButton.SetDisabled(true);
		Navigator.RemoveControl(ConfirmButton);
	}
}

function AddNewSquadButtonCallback()
{
	//`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	OpenNameNewSquadInputInterface();
}

function CloseSquadCompleteProgressDialog()
{
	local XComPresentationLayerBase Presentation;
	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
	Presentation.UICloseProgressDialog();
}

function AddNewSquadCompleteCallback()
{
	CloseSquadCompleteProgressDialog();
}
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if (m_bKeyboardOpen)
	{
		return false;
	}
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_KEY_DELETE:
			DeleteButtonCallback();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_R3:
			if(m_kSquadLoadout != none)
				DeleteButtonCallback();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			if(m_kSquadLoadout != none)
				CloneButtonCallback();
			return true;
		//case class'UIUtilities_Input'.const.FXS_BUTTON_R3:
		//	if(m_kSquadLoadout != none)
		//		RenameButtonCallback();
		//	return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			NextButton();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			SquadListItemClicked(SquadList, SquadList.SelectedIndex); //this function sorts out the 'on press' behavior' - JTA 2016/3/16
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

function BackButtonCallback()
{
	CloseScreen();
}

function CloneClickedButtonCallback(UIButton button)
{
	CloneButtonCallback();
}

function RenameClickedButtonCallback(UIButton button)
{
	RenameButtonCallback();
}

function DeleteClickedButtonCallback(UIButton button)
{
	DeleteButtonCallback();
}

function NextClickedButton(UIButton button)
{
	NextButton();
}

function CloneButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(m_kSquadLoadout != none)
	{
		m_kCloningLoadout = m_kSquadLoadout;
		OpenCloneSquadInputInterface();
	}
}

function RenameButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(m_kSquadLoadout != none)
	{
		m_kRenamingLoadout = m_kSquadLoadout;
		OpenRenameSquadInputInterface();
	}
}

function DeleteButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(SelectedIndex >= 0 && `ISCONTROLLERACTIVE)
	{
		m_kDeletingLoadout = XComGameState(UIMechaListItem(SquadList.GetItem(SelectedIndex)).metadataObject);
	}
	else if(m_kSquadLoadout != none)
	{
		m_kDeletingLoadout = m_kSquadLoadout;
	}

	if(m_kDeletingLoadout != none)
		DisplayConfirmDeleteDialog();
}

function NextButton()
{
	if(!Movie.IsMouseActive())
		//'Next' Button functionality is handled in child classes - Removing functionality here to ensure there is no unexpected behavior
		return;
	if(m_kSquadLoadout != none)
		CreateSquadEditor(m_kSquadLoadout);
}

function NextButtonCallback(UIButton Button)
{
	//button is disabled without gamepad, so we need to do the check here again
	local int pointTotal;
	pointTotal = UIMechaListItem(SquadList.GetItem(SelectedIndex)).metadataInt;
	if(m_kMPShellManager.OnlineGame_GetMaxSquadCost() < 0 ||
		pointTotal > m_kMPShellManager.OnlineGame_GetMaxSquadCost())
		return;
	if(m_kSquadLoadout != none)
		CreateSquadEditor(m_kSquadLoadout);
}

function CreateSquadList()
{
	UpdateSquadListItems();
}

function CreateSquadInfoPanel()
{
	local int i;
	local UIMPShell_SquadUnitInfoItem UnitInfo;
	local XComGameState_Unit kUnit;

	i = 0;

	foreach m_kSquadLoadout.IterateByClassType(class'XComGameState_Unit', kUnit)
	{
		if(i < eMPNumUnitsPerSquad_MAX)
		{
			UnitInfo = Spawn(class'UIMPShell_SquadUnitInfoItem', self);
			UnitInfo.bIsNavigable = false;
			UnitInfo.InitSquadUnitInfoItem(m_kMPShellManager, m_kSquadLoadout, kUnit, , name("SquadUnit"$i));
			UnitInfos.AddItem(UnitInfo);
			i++;
		}
		else
		{
			`REDSCREEN("too many units in loadout"@m_kSquadLoadout);
			m_kSquadLoadout.RemoveStateObject(kUnit.GetReference().ObjectID);
		}
	}

	while(i < eMPNumUnitsPerSquad_MAX)
	{
		UnitInfo = Spawn(class'UIMPShell_SquadUnitInfoItem', self);
		UnitInfo.bIsNavigable = false;
		UnitInfo.InitSquadUnitInfoItem(m_kMPShellManager, m_kSquadLoadout, , , name("SquadUnit"$i));
		UnitInfos.AddItem(UnitInfo);
		i++;
	}
}

function CreateSquadEditor(XComGameState kSquad)
{

	AnchoredNavHelp.ClearButtonHelp();
	UIMPShell_SquadEditor(`SCREENSTACK.Push(Spawn(UISquadEditorClass, Movie.Pres))).InitSquadEditor(kSquad);
}
simulated function CreateSquadEditor_HitchDialog()
{
	local TProgressDialogData kDialogData;
	kDialogData.strTitle = m_strLoadingSquadDataTitle;
	kDialogData.strDescription = m_strLoadingSquadDataText;
	Movie.Pres.UIProgressDialog(kDialogData);

	SetTimer(0.5f, false, nameof(CreateSquadEditor_PostHitchDialog));

	//<bsg> TTP_5451_NONFUNCTIONAL_NAV_BUTTON_MP_LOAD_SQUAD_DATA jneal 06/27/16
	//INS:
	AnchoredNavHelp.ClearButtonHelp();
	//</bsg>
}

simulated function CreateSquadEditor_PostHitchDialog()
{
	Movie.Pres.UICloseProgressDialog();
	UIMPShell_SquadEditor(`SCREENSTACK.Push(Spawn(UISquadEditorClass, Movie.Pres))).InitSquadEditor(SquadToEdit);
}

function SquadListItemDoubleClicked(UIList listControl, int itemIndex)
{
	if(itemIndex == 0)
	{
		AddNewSquadButtonCallback();
	}
	else
	{
		`log(self $ "::" $ GetFuncName() @ "itemIndex=" $ itemIndex,, 'uixcom_mp');
		m_kSquadLoadout = XComGameState(UIMechaListItem(listControl.GetItem(itemIndex)).metadataObject);
		NextButton();
	}
}

function SquadListItemClicked(UIList listControl, int itemIndex)
{
	local UIMechaListItem MechaListItem;

	if(itemIndex == 0)
	{
		AddNewSquadButtonCallback();
	}
	else
	{
		//checkboxes are gone in the console version, so now we always edit the squad on press
		if(!Movie.IsMouseActive())
		{
			EditSquadButtonCallback();
			return;
		}
		
		MechaListItem = UIMechaListItem(listControl.GetItem(itemIndex));
		if(MechaListItem != none)
			OnCheckboxClicked(MechaListItem.Checkbox);
	}
}

function SetSelected(UIList listControl, int itemIndex)
{
	SetSelectedIndex(itemIndex);

	`log(self $ "::" $ GetFuncName() @ "itemIndex=" $ itemIndex @ `ShowVar(UIMechaListItem(listControl.GetItem(itemIndex)).metadataObject),, 'uixcom_mp');
	m_kSquadLoadout = XComGameState(UIMechaListItem(listControl.GetItem(itemIndex)).metadataObject);
	UpdateSquadInfoPanel();
}

function SetSquad(XComGameState kLoadout)
{
	m_kSquadLoadout = kLoadout;
	UpdateData();
}

// ADD NEW -tsmith
function OpenNameNewSquadInputInterface()
{
	local TInputDialogData kData;
	local int MAX_CHARS;

	MAX_CHARS = 50;

//	if(!WorldInfo.IsConsoleBuild() || `ISCONTROLLERACTIVE )
// 	{
		// on PC, we have a real keyboard, so use that instead
		kData.fnCallbackAccepted = PCTextField_OnAccept_NameNewSquad;
		kData.fnCallbackCancelled = PCTextField_OnCancel_NameNewSquad;
		kData.strTitle = m_strEnterNameHeader;
		kData.iMaxChars = MAX_CHARS;
		kData.strInputBoxText = m_strDefaultSquadName;
		Movie.Pres.UIInputDialog(kData);
/*	}
	else
	{
		//`log("+++ Loading the VirtualKeyboard", ,'uixcom');
		Movie.Pres.UIKeyboard( m_strEnterNameHeader, 
										 m_strDefaultSquadName, 
										 VirtualKeyboard_OnAccept_NameNewSquad, 
										 VirtualKeyboard_OnCancel_NameNewSquad,
										 false, // Do not need to validate these names -ttalley
										 MAX_CHARS);
		bWaitingToCreateNewLoadout = true;
	}*/
}

function PCTextField_OnAccept_NameNewSquad( string userInput )
{
	VirtualKeyboard_OnAccept_NameNewSquad(userInput, true);
}
function PCTextField_OnCancel_NameNewSquad( string userInput )
{
	VirtualKeyboard_OnCancel_NameNewSquad();
}

function VirtualKeyboard_OnAccept_NameNewSquad( string userInput, bool bWasSuccessful )
{
	bWaitingToCreateNewLoadout = false;
	if( userInput == "" ) bWasSuccessful = false; 

	if(!bWasSuccessful)
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true ); 
		VirtualKeyboard_OnCancel_NameNewSquad();
		return;
	}

	class'UIUtilities_Text'.static.StripUnsupportedCharactersFromUserInput(userInput);

	m_kSquadLoadout = m_kMPShellManager.CreateEmptyLoadout(userInput);
	m_kMPShellManager.AddLoadoutToList(m_kSquadLoadout);
	m_kMPShellManager.WriteSquadLoadouts();
	m_kMPShellManager.SaveProfileSettings();
	CreateSquadEditor(m_kSquadLoadout);
}

function VirtualKeyboard_OnCancel_NameNewSquad()
{
	bWaitingToCreateNewLoadout = false;
	CloseSquadCompleteProgressDialog();
}

// CLONE -tsmith
function OpenCloneSquadInputInterface()
{
	local TInputDialogData kData;
	local int MAX_CHARS;

	MAX_CHARS = 50;

//	if( `ISCONTROLLERACTIVE == false)
//	{
		// on PC, we have a real keyboard, so use that instead
		kData.fnCallbackAccepted = PCTextField_OnAccept_CloneSquad;
		kData.fnCallbackCancelled = PCTextField_OnCancel_CloneSquad;
		kData.strTitle = m_strEnterNameHeader;
		kData.iMaxChars = MAX_CHARS;
		kData.strInputBoxText = XComGameStateContext_SquadSelect(m_kCloningLoadout.GetContext()).strLoadoutName $ m_strCloneSquadNameSuffix;
		Movie.Pres.UIInputDialog(kData);
/*	}
	else
	{
		m_bKeyboardOpen = true;
		//`log("+++ Loading the VirtualKeyboard", ,'uixcom');
		Movie.Pres.UIKeyboard( m_strEnterNameHeader, 
										 XComGameStateContext_SquadSelect(m_kCloningLoadout.GetContext()).strLoadoutName $ m_strCloneSquadNameSuffix, 
										 VirtualKeyboard_OnAccept_CloneSquad, 
										 VirtualKeyboard_OnCancel_CloneSquad,
										 false, // Do not need to validate these names -ttalley
										 MAX_CHARS);
	}*/
}

function PCTextField_OnAccept_CloneSquad( string userInput )
{
	VirtualKeyboard_OnAccept_CloneSquad(userInput, true);
}
function PCTextField_OnCancel_CloneSquad( string userInput )
{
	VirtualKeyboard_OnCancel_CloneSquad();
}

function VirtualKeyboard_OnAccept_CloneSquad( string userInput, bool bWasSuccessful )
{
	local XComGameState kNewLoadout;
	m_bKeyboardOpen = false;

	if( userInput == "" ) bWasSuccessful = false; 

	if(!bWasSuccessful)
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true ); 
		VirtualKeyboard_OnCancel_CloneSquad();
		return;
	}

	class'UIUtilities_Text'.static.StripUnsupportedCharactersFromUserInput(userInput);

	kNewLoadout = m_kMPShellManager.CloneSquadLoadoutGameState(m_kCloningLoadout, true);
	XComGameStateContext_SquadSelect(kNewLoadout.GetContext()).strLoadoutName = userInput;
	m_kCloningLoadout = kNewLoadout;
	m_kMPShellManager.AddLoadoutToList(m_kCloningLoadout);
	m_kMPShellManager.WriteSquadLoadouts();
	m_kMPShellManager.SaveProfileSettings();
	CreateSquadEditor(m_kCloningLoadout);

	m_kCloningLoadout = none;
}

function VirtualKeyboard_OnCancel_CloneSquad()
{
	m_bKeyboardOpen = false;
	m_kCloningLoadout = none;
}


// RENAME -tsmith
function OpenRenameSquadInputInterface()
{
	local TInputDialogData kData;
	local int MAX_CHARS;

	MAX_CHARS = 50;

//	if(`ISCONTROLLERACTIVE == false )
//	{
		// on PC, we have a real keyboard, so use that instead
		kData.fnCallbackAccepted = PCTextField_OnAccept_RenameSquad;
		kData.fnCallbackCancelled = PCTextField_OnCancel_RenameSquad;
		kData.strTitle = m_strRenameSquadDialogHeader;
		kData.iMaxChars = MAX_CHARS;
		kData.strInputBoxText = XComGameStateContext_SquadSelect(m_kRenamingLoadout.GetContext()).strLoadoutName;
		Movie.Pres.UIInputDialog(kData);
/*	}
	else
	{
		//`log("+++ Loading the VirtualKeyboard", ,'uixcom');
		Movie.Pres.UIKeyboard( m_strEnterNameHeader, 
										 XComGameStateContext_SquadSelect(m_kRenamingLoadout.GetContext()).strLoadoutName, 
										 VirtualKeyboard_OnAccept_RenameSquad, 
										 VirtualKeyboard_OnCancel_RenameSquad,
										 false, // Do not need to validate these names -ttalley
										 MAX_CHARS);
	}*/
}

function PCTextField_OnAccept_RenameSquad( string userInput )
{
	VirtualKeyboard_OnAccept_RenameSquad(userInput, true);
}
function PCTextField_OnCancel_RenameSquad( string userInput )
{
	VirtualKeyboard_OnCancel_RenameSquad();
}

function VirtualKeyboard_OnAccept_RenameSquad( string userInput, bool bWasSuccessful )
{
	if( userInput == "" ) bWasSuccessful = false; 

	if(!bWasSuccessful)
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true ); 
		VirtualKeyboard_OnCancel_RenameSquad();
		return;
	}

	class'UIUtilities_Text'.static.StripUnsupportedCharactersFromUserInput(userInput);

	XComGameStateContext_SquadSelect(m_kRenamingLoadout.GetContext()).strLoadoutName = userInput;
	m_kMPShellManager.WriteSquadLoadouts();
	m_kMPShellManager.SaveProfileSettings();
	UpdateData();

	m_kRenamingLoadout = none;
}

function VirtualKeyboard_OnCancel_RenameSquad()
{
	m_kRenamingLoadout = none;
}

function DisplayConfirmDeleteDialog()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.eType = eDialog_Warning;
	kConfirmData.strTitle = m_strConfirmDeleteTitle;
	kConfirmData.strText = m_strConfirmDeleteText;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericConfirm;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;

	kConfirmData.fnCallback = OnDisplayConfirmDeleteDialogAction;

	Movie.Pres.UIRaiseDialog(kConfirmData);
	AnchoredNavHelp.ClearButtonHelp();
}

function OnDisplayConfirmDeleteDialogAction(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		m_kMPShellManager.DeleteLoadoutFromList(m_kDeletingLoadout);
		m_kMPShellManager.WriteSquadLoadouts();
		m_kMPShellManager.SaveProfileSettings(true);
		UpdateSquadListItems();
		SelectFirstLoadout();
		UpdateGamepadFocus();
	}

	m_kDeletingLoadout = none;
	UpdateNavHelp();
}

function SelectFirstLoadout()
{
	if(SquadList.NumChildren() > 0)
	{
		m_kSquadLoadout = XComGameState(UIMechaListItem(SquadList.GetItem(0)).metadataObject);
		UpdateSquadInfoPanel();
	}
}

function UpdateData()
{	
	UpdateSquadListItems();
	UpdateSquadInfoPanel();
}

function UpdateSquadListItems()
{
	local UIMechaListItem kListItem;
	local XComGameState kSquadLodoutState;
	local int pointTotal;
	local XComGameStateContext_SquadSelect kSquadLoadoutContext;
	local XComGameState_Unit kLoadoutUnit;

	SquadList.ClearItems();

	UIListItemString(SquadList.CreateItem(class'UIListItemString')).InitListItem(m_strCreateNewLoadout);

	foreach m_kMPShellManager.m_arrSquadLoadouts(kSquadLodoutState)
	{
		kSquadLoadoutContext = XComGameStateContext_SquadSelect(kSquadLodoutState.GetContext());
		`assert(kSquadLoadoutContext != none);
		`log(self $ "::" $ GetFuncName() @ `ShowVar(kSquadLoadoutContext.strLoadoutName) @ `ShowVar(kSquadLoadoutContext.iLoadoutId),, 'uixcom_mp');
		
		kListItem = UIMechaListItem(SquadList.CreateItem(class'UIMechaListItem'));

		pointTotal = 0;
		foreach kSquadLodoutState.IterateByClassType(class'XComGameState_Unit', kLoadoutUnit)
		{
			pointTotal += kLoadoutUnit.GetUnitPointValue();
		}

		kListItem.InitListItem();
		if( `ISCONTROLLERACTIVE )
		{
			kListItem.SetWidgetType(EUILineItemType_Description);
			kListItem.UpdateDataDescription(kSquadLoadoutContext.strLoadoutName@"-"@pointTotal@m_strPointTotalPostfix);
		}
		else
		{
			kListItem.SetWidgetType(EUILineItemType_Checkbox);
			kListItem.UpdateDataCheckbox(kSquadLoadoutContext.strLoadoutName@"-"@pointTotal@m_strPointTotalPostfix, "", false, OnCheckboxClicked);
		}
		kListItem.metadataObject = kSquadLodoutState;
		kListItem.metadataInt = pointTotal;

		if(pointTotal <= 0)
		{
			kListItem.SetBad(true);
		}
		else if(m_kMPShellManager.OnlineGame_GetMaxSquadCost() > 0)
		{
			kListItem.SetBad(pointTotal > m_kMPShellManager.OnlineGame_GetMaxSquadCost() || (pointTotal == 0 && (m_kMPShellManager.OnlineGame_GetIsRanked() || m_kMPShellManager.OnlineGame_GetAutomatch())));
		}
		
		kListItem.Show();
	}

	SelectFirstLoadout();
}
function ShowAttemptingToConnectToGameRanked()
{
	local XComPresentationLayerBase Presentation;
	local XComShellPresentationLayer ShellPresentation;
	local TProgressDialogData kDialogBoxData;

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
	ShellPresentation = XComShellPresentationLayer(Presentation);

	if (ShellPresentation != none)
	{
		kDialogBoxData.strTitle = ShellPresentation.m_strOnlineSearchForRankedAutomatch_Title;
		kDialogBoxData.strDescription = ShellPresentation.m_strOnlineReadRankedStats_Text;
		kDialogBoxData.fnCallback = ShellPresentation.OSSAutomatchRankedWaitDialogAbortCallback;
		Presentation.UIProgressDialog(kDialogBoxData);
	}
}

function ShowAttemptingToConnectToGameUnranked()
{
	local XComPresentationLayerBase Presentation;
	local XComShellPresentationLayer ShellPresentation;
	local TProgressDialogData kDialogBoxData;

	Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
	ShellPresentation = XComShellPresentationLayer(Presentation);

	if (ShellPresentation != none)
	{
		kDialogBoxData.strTitle = ShellPresentation.m_strOnlineSearchForUnrankedAutomatch_Title;
		kDialogBoxData.strDescription = ShellPresentation.m_strOnlineSearchForUnrankedAutomatch_Text;
		kDialogBoxData.fnCallback = ShellPresentation.OSSAutomatchUnrankedWaitDialogAbortCallback;
		Presentation.UIProgressDialog(kDialogBoxData);
	}
}

simulated function bool CanJoinGame()
{
	local int pointTotal;
	local XComGameState_Unit kLoadoutUnit;

	pointTotal = 0;
	foreach m_kSquadLoadout.IterateByClassType(class'XComGameState_Unit', kLoadoutUnit)
	{
		pointTotal += kLoadoutUnit.GetUnitPointValue();
	}
	if(pointTotal <= 0)
	{
		return false;
	}

	return m_kMPShellManager.OnlineGame_GetMaxSquadCost() < 0 || !(pointTotal > m_kMPShellManager.OnlineGame_GetMaxSquadCost() || (pointTotal == 0 && (m_kMPShellManager.OnlineGame_GetIsRanked() || m_kMPShellManager.OnlineGame_GetAutomatch())));
}

simulated function OnCheckboxClicked(UICheckBox Checkbox)
{
	local int Index;

	Index = SquadList.GetItemIndex(Checkbox);

	if(Checkbox.bChecked)
	{
		Checkbox.SetChecked(false, false);
		SetSelected(SquadList, -1);
		return;
	}

	// unselect previously selected index
	if(SelectedIndex >= 0 && SelectedIndex < SquadList.ItemCount)
		UIMechaListItem(SquadList.GetItem(SelectedIndex)).Checkbox.SetChecked(false, false);

	if(Index > 0 && Index < SquadList.ItemCount)
		UIMechaListItem(SquadList.GetItem(Index)).Checkbox.SetChecked(true, false);

	SetSelected(SquadList, Index);
}

simulated function SetSelectedIndex(int Index)
{
	SelectedIndex = Index;

	if(SelectedIndex != -1)
		m_kSquadLoadout = XComGameState(UIMechaListItem(SquadList.GetItem(SelectedIndex)).metadataObject);
	else
		m_kSquadLoadout = none;

	UpdateNavHelpState();
}

function UpdateSquadInfoPanel()
{
	local int i;
	local XComGameState_Unit kUnit;

	i = 0;

	UpdateSquadNameHeader();

	if(m_kSquadLoadout == m_kPreviewingLoadout) return;
	
	m_kPreviewingLoadout = m_kSquadLoadout;
	
	if(m_kSquadLoadout != none)
	{	
		foreach m_kSquadLoadout.IterateByClassType(class'XComGameState_Unit', kUnit)
		{
			`log(self $ "::" $ GetFuncName() @ kUnit.GetFullName(),, 'uixcom_mp');
			if(UnitInfos.Length > i)
			{
				UnitInfos[i].RemoveTweens();
				UnitInfos[i].AnimateIn((i + 1) * 0.1);
				UnitInfos[i].SetUnit(kUnit);
				i++;
			}
		}
	}
	
	while( i < UnitInfos.Length)
	{
		UnitInfos[i].SetUnit(none);
		i++;
	}
}


function UpdateSquadNameHeader()
{
	local bool bInPreset;
	bInPreset = `SCREENSTACK.GetScreen(class'UIMPShell_SquadLoadoutList_Preset') != none;
	
	MC.FunctionString("SetTitle", m_kMPShellManager.GetMatchString(!bInPreset));
	
	if(m_kMPShellManager.OnlineGame_GetMaxSquadCost() > -1)
	{
		MC.FunctionString("SetPointTotal", m_kMPShellManager.GetPointsString()@m_strPointTotalPostfix);
	}
	else
	{
		if(bInPreset)
		{
			MC.FunctionString("SetPointTotal", " ");
		}
		else
		{
			MC.FunctionString("SetPointTotal", m_kMPShellManager.GetPointsString());
		}
	}
	if(bInPreset)
	{
		MC.FunctionString("SetPointLabel", " ");
	}
	else
	{
		MC.FunctionString("SetPointLabel", m_strPointTotalLabel);
	}

	MC.FunctionString("SetTitleLabel", m_strTitleLoading);
}

function ShowHideUnitInfos()
{
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	SelectedIndex = -1;
	m_kSquadLoadout = none;
	
	UpdateNavHelp();
	UpdateData();
	UpdateGamepadFocus();
}
simulated function OnLoseFocus()
{
	if(AnchoredNavHelp != None)
	{
		AnchoredNavHelp.ClearButtonHelp();
	}
	super.OnLoseFocus();
}
simulated function UpdateGamepadFocus()
{
	if(!Movie.IsMouseActive())
	{
		if(SelectedIndex < 0 || SelectedIndex >= SquadList.ItemCount)
			SelectedIndex = 0;

		SquadList.SetSelectedIndex(SelectedIndex);
		Navigator.SetSelected(SquadList);
	}	
}
simulated function DisplayConfirmMPAccountDialog()
{
	local TDialogueBoxData kConfirmData;
	local string PlayerName;

	PlayerName = class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.GetPlayerNickname(0);
	kConfirmData.strTitle = Repl(ConfirmMPAccountTitle,"%USERNAME",class'UIUtilities_Text'.static.GetColoredText(PlayerName, eUIState_Highlight));
	kConfirmData.strText = ConfirmMPAccountMessage;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericContinue;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericBack;
	kConfirmData.fnCallback = OnDisplayConfirmMPAccountDialogAction;

	Movie.Pres.UIRaiseDialog(kConfirmData);
}

simulated function OnDisplayConfirmMPAccountDialogAction(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		//Nothing happens
	}
	else
	{	
		BackButtonCallback(); //bsg-cballinger (7.12.16): Need to reset pending invites when backing out of confirmation dialog, or player will always be taken directly to the squad loadout view when first entering MP
		ConsoleCommand("disconnect"); //should bring the player back to the main menu
	}

	//<bsg> TTP_5750_NONFUNCTIONAL_NAV_BUTTON_MP_INVITE jneal 06/28/16
	//INS:
	UpdateNavHelp();
	//</bsg>
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
	TEMP_strSreenNameText="";

	Package   = "/ package/gfxMultiplayerLoadoutList/MultiplayerLoadoutList";
	MCName      = "theScreen";

	SelectedIndex = -1;
	bWaitingToCreateNewLoadout = false;
}