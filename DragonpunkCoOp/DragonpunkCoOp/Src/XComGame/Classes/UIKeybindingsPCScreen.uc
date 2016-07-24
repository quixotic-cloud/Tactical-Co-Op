//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIKeybindingsPCScreen
//  AUTHOR:  Sam Batista        -- 07/27/12
//  PURPOSE: Keybindings screen for rebinding of keyboard shortcuts
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIKeybindingsPCScreen extends UIScreen
	native(UI)
	config(UI)
	dependson(UIDialogueBox, XComKeybindingData);

struct native UIKeyBind
{
	var init string UserLabel;

	var KeyBind PrimaryBind;
	var keyBind SecondaryBind;

	var bool    BlockUnbindingPrimaryKey;
};

var localized string m_strTitle;
var localized string m_strGeneralBindingsCategoryLabel;
var localized string m_strTacticalBindingsCategoryLabel;
var localized string m_strGeoscapeBindingsCategoryLabel;
var localized string m_strAvengerBindingsCategoryLabel;
var localized string m_strResetBindingsButtonLabel;
var localized string m_strSaveAndExitButtonLabel;
var localized string m_strCancelButtonLabel;

var localized string m_strPrimaryBindingsColumnHeader;
var localized string m_strSecondaryBindingsColumnHeader;

var localized string m_strPressKeyLabel;

var localized string m_strConfirmResetBindingsDialogTitle;
var localized string m_strConfirmResetBindingsDialogText;

var localized string m_strConfirmDiscardChangesTitle;
var localized string m_strConfirmDiscardChangesText;
var localized string m_strConfirmDiscardChangesAcceptButton;
var localized string m_strConfirmDiscardChangesCancelButton;

var localized string m_strConfirmConflictingBindDialogTitle;
var localized string m_strConfirmConflictingBindDialogText;
var localized string m_strConfirmConflictingBindDialogAcceptButton;
var localized string m_strConfirmConflictingBindDialogCancelButton;

var init array<UIKeyBind> m_arrBindings;
var KeybindCategories     m_eBindingCategory;

var PlayerController       m_kBaseInputController;
var bool      m_kShouldDestroyBaseInputController;
var XComTacticalController m_kTacticalInputController;
var bool      m_kShouldDestroyTacticalInputController;
var XComHeadquartersController m_kHQInputController;
var bool      m_kShouldDestroyHQInputController;
var XComKeybindingData     m_kKeybindingData;

// This array will contain PlayerInput references if the player makes a change to the bindings. 
// This lets us to know whether we need to save the config data before the player exits the screen or not.
var array<PlayerInput> m_arrDirtyPlayerInputs;

var bool    m_bAwaitingInputForBind, m_bAlreadyProcessingRawInput, m_bSecondaryKeyBeingBound, m_bSecondaryKeyConflicting, m_bKeybindindsChanged;
var int     m_iKeySlotBeingBound;
var int     m_iKeySlotConflicting;
var KeyBind m_kCachedKeyBeingBound;

// Commands on this array are searched for and modified across all input classes (Shell, Tactical, Headquarters)
var config array<string> SharedCommands;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_kKeybindingData = Movie.Pres.m_kKeybindingData;

	XComInputBase(PC.PlayerInput).SetRawInputHandler(RawInputHandler);
	m_eBindingCategory = eKC_General;

	InitInputClasses();

	// Hide until all key bindings  are loaded
	Hide();
}

simulated function InitInputClasses()
{
	local PlayerController BC;
	local XComTacticalController TC;
	local XComHeadquartersController HQC;

	foreach WorldInfo.AllControllers(class'PlayerController', BC)
	{
		if (XComShellController(BC) != none)
			continue;

		if (XComTacticalController(BC) != none)
			continue;

		if (XComHeadquartersController(BC) != none)
			continue;

		m_kBaseInputController = BC;
		break;
	}

	foreach WorldInfo.AllControllers(class'XComTacticalController', TC)
	{
		m_kTacticalInputController = TC;
		break;
	}

	foreach WorldInfo.AllControllers(class'XComHeadquartersController', HQC)
	{
		m_kHQInputController = HQC;
		break;
	}
	

	// Create player controller objects so we can get the input class and access bindings for the different input sections of the game.
	if (m_kBaseInputController  == none)
	{
		m_kBaseInputController = Spawn(class'PlayerController');
		m_kBaseInputController.InitInputSystem();
		m_kShouldDestroyBaseInputController = true;
	}

	if (m_kTacticalInputController == none)
	{
		m_kTacticalInputController = Spawn(class'XComTacticalController');
		m_kTacticalInputController.InitInputSystem();
		m_kShouldDestroyTacticalInputController = true;
	}

	if (m_kHQInputController == none)
	{
		m_kHQInputController = Spawn(class'XComHeadquartersController');
		m_kHQInputController.InitInputSystem();
		m_kShouldDestroyHQInputController = true;
	}
}

simulated function OnInit()
{
	super.OnInit();

	AS_SetTitle(m_strTitle);
	AS_SetTabLabels(m_strGeneralBindingsCategoryLabel, m_strTacticalBindingsCategoryLabel, m_strAvengerBindingsCategoryLabel);
	AS_SetColumnLabels(m_strPrimaryBindingsColumnHeader, m_strSecondaryBindingsColumnHeader);
	AS_SetButtonLabels(m_strResetBindingsButtonLabel, m_strCancelButtonLabel, m_strSaveAndExitButtonLabel);
	AS_SetPressKeyText(m_strPressKeyLabel);

	UpdateBindingsList();
}

simulated function UpdateBindingsList()
{
	ReadBindings();
	DisplayBindings();
}

simulated function DisplayBindings()
{
	local UIKeyBind kUserFacingBinding;

	AS_ClearBindingsList();
	
	foreach m_arrBindings(kUserFacingBinding)
	{
		AS_AddKeyBindingSlot(kUserFacingBinding.UserLabel, 
							 m_kKeybindingData.GetKeyString(kUserFacingBinding.PrimaryBind),
							 m_kKeybindingData.GetKeyString(kUserFacingBinding.SecondaryBind), 
							 kUserFacingBinding.BlockUnbindingPrimaryKey);
	}
}


//----------------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int ActionMask)
{
	// Ignore releases, only pay attention to presses.
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, ActionMask) || m_bAwaitingInputForBind )
		return true;

	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_KEY_PAGEUP:
			if (!m_bAwaitingInputForBind)
			{
				AS_ActivateTab( KeybindCategories(m_eBindingCategory == 0 ? eKC_MAX - 1 :  m_eBindingCategory - 1) );
				UpdateBindingsList();
			}
			break;

		case class'UIUtilities_Input'.const.FXS_KEY_PAGEDN:
			if (!m_bAwaitingInputForBind)
			{
				AS_ActivateTab( KeybindCategories((m_eBindingCategory + 1) % eKC_MAX) );
				UpdateBindingsList();
			}
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
			OnAccept();
			break;
		
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break;

		default:
			// Do not reset handled, consume input since this
			// is the options menu which stops any other systems.
			break;			
	}

	return super.OnUnrealCommand(cmd, ActionMask);
}


simulated function bool IsBindable( Name Key)
{
	if ( Key == 'LeftMouseButton' ) return false;
	if ( Key == 'F11' ) return false;
	if ( Key == 'F12' ) return false;
	return true;
}

simulated function bool RawInputHandler(Name Key, int ActionMask, bool bCtrl, bool bAlt, bool bShift)
{
	local KeyBind kBind;
	local PlayerInput kPlayerInput;
	local PlayerController kPlayerController;
	local array<PlayerInput> ChangedInputs;

	if(m_bAlreadyProcessingRawInput || !m_bAwaitingInputForBind || ActionMask != class'UIUtilities_Input'.const.FXS_ACTION_RELEASE || !IsBindable( Key ) )
		return false;

	// HAX: Ugly hax because FlushPressedKeys triggers any "key handling" delegates, which will trigger an infinite recursion on this function.
	// Cannot set 'm_bAwaitingInputForBind' to false before calling FlushPressed keys, because that will also trigger an OnUnrealCommand,1
	// and that needs to be ignored (it checks 'm_bAwaitingInputForBind' for early out) - sbatista 8/21/12
	m_bAlreadyProcessingRawInput = true;
	FlushPressedKeys();
	m_bAlreadyProcessingRawInput = false;

	m_bAwaitingInputForBind = false;

	m_iKeySlotConflicting = IsKeyAlreadyBound(Key, bCtrl, bAlt, bShift);
	if(m_iKeySlotConflicting != INDEX_NONE)
	{
		// If the player is trying to bind the same key on a different slot for the same action, just ignore it
		if(m_iKeySlotBeingBound == m_iKeySlotConflicting)
		{
			AS_DeactivateSlot(m_iKeySlotBeingBound, m_bSecondaryKeyBeingBound);
			return true;
		}

		m_kCachedKeyBeingBound.Name = Key;
		m_kCachedKeyBeingBound.Command = GetCommandForKeyBeingBound();
		m_kCachedKeyBeingBound.bPrimaryBinding = !m_bSecondaryKeyBeingBound;
		m_kCachedKeyBeingBound.bSecondaryBinding = m_bSecondaryKeyBeingBound;
		m_kCachedKeyBeingBound.Control = bCtrl;
		m_kCachedKeyBeingBound.Shift = bShift;
		m_kCachedKeyBeingBound.Alt = bAlt;
		DisplayConflictingKeyDialog();
		return true;
	}

	// The key has been released, read the bind and map it.
	if(m_bSecondaryKeyBeingBound)
		kBind = m_arrBindings[m_iKeySlotBeingBound].SecondaryBind;
	else
		kBind = m_arrBindings[m_iKeySlotBeingBound].PrimaryBind;

	
	// Remove it from all player inputs if it's a General or Shared Command
	if(m_eBindingCategory == eKC_General || SharedCommands.Find(kBind.Command) != INDEX_NONE)
	{
		foreach WorldInfo.AllControllers(class'PlayerController', kPlayerController)
		{
			RemoveBind(kPlayerController.PlayerInput, kBind, ChangedInputs);
		}
	}
	else
	{
		RemoveBind(GetPlayerInput(), kBind, ChangedInputs);
	}

	// Update the new bind and add it to the bind list.
	kBind.Name = Key;
	kBind.Command = GetCommandForKeyBeingBound();
	kBind.bPrimaryBinding = !m_bSecondaryKeyBeingBound;
	kBind.bSecondaryBinding = m_bSecondaryKeyBeingBound;

	if (InStr(kBind.Name, "Control") == -1)
	{
		kBind.Control = bCtrl;
	}

	if (InStr(kBind.Name, "Shift") == -1)
	{
		kBind.Shift = bShift;
	}

	if (InStr(kBind.Name, "Alt") == -1)
	{
		kBind.Alt = bAlt;
	}

	if(m_bSecondaryKeyBeingBound)
		m_arrBindings[m_iKeySlotBeingBound].SecondaryBind = kBind;
	else
		m_arrBindings[m_iKeySlotBeingBound].PrimaryBind = kBind;

	foreach ChangedInputs(kPlayerInput)
	{
		kPlayerInput.AddBind(kBind);
		if(m_arrDirtyPlayerInputs.Find(kPlayerInput) == INDEX_NONE)
			m_arrDirtyPlayerInputs.AddItem(kPlayerInput);
	}

	AS_DeactivateSlot(m_iKeySlotBeingBound, m_bSecondaryKeyBeingBound);
	AS_SetNewKey(m_iKeySlotBeingBound, m_bSecondaryKeyBeingBound, m_kKeybindingData.GetKeyString(kBind));
	return true;
}

simulated function RemoveBind(PlayerInput kPlayerInput, KeyBind kBind, out array<PlayerInput> ChangedInputs)
{
	kPlayerInput.RemoveBind(kBind.Name, kBind.Command, kBind.bSecondaryBinding);
	ChangedInputs.AddItem(kPlayerInput);
}

simulated native function FlushPressedKeys();

function string GetCommandForKeyBeingBound()
{
	switch(m_eBindingCategory)
	{
	case eKC_General:  return m_kKeybindingData.GetCommandStringForGeneralAction(GeneralBindableCommands(m_iKeySlotBeingBound)); break;
	case eKC_Tactical: return m_kKeybindingData.GetCommandStringForTacticalAction(TacticalBindableCommands(m_iKeySlotBeingBound)); break;
	case eKC_Avenger: return m_kKeybindingData.GetCommandStringForAvengerAction(AvengerBindableCommands(m_iKeySlotBeingBound)); break;
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string strCallbackObject;
	local int iSelectedSlot;
	local bool bPrimarySlot;
	local KeyBind kEmptyKey;
	local PlayerInput kPlayerInput;

	strCallbackObject = args[args.Length - 1];

	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		switch(strCallbackObject)
		{
		case "theBackButton":
			OnCancel();
			break;
		case "theAcceptButton":
			OnAccept();
			break;
		case "theResetToDefaultsButton":
			if(m_bAwaitingInputForBind)
			{
				m_bAwaitingInputForBind = false;
				AS_DeactivateSlot(m_iKeySlotBeingBound, m_bSecondaryKeyBeingBound);
			}
			DisplayConfirmResetBindingsDialog();
			break;
		case "Tab0":
			if(m_eBindingCategory != eKC_General && !m_bAwaitingInputForBind)
			{
				AS_ActivateTab(eKC_General);
				UpdateBindingsList();
			}
			break;
		case "Tab1":
			if(m_eBindingCategory != eKC_Tactical && !m_bAwaitingInputForBind)
			{
				AS_ActivateTab(eKC_Tactical);
				UpdateBindingsList();
			}
			break;
		case "Tab2":
			if(m_eBindingCategory != eKC_Avenger && !m_bAwaitingInputForBind)
			{
				AS_ActivateTab(eKC_Avenger);
				UpdateBindingsList();
			}
			break;
		/*case "Tab3":
			if(m_eBindingCategory != eKC_Geoscape && !m_bAwaitingInputForBind)
			{
				AS_ActivateTab(eKC_Geoscape);
				UpdateBindingsList();
			}
			break;*/
		
		// Handle binding of key slot
		case "bgHighlight":
			if(m_bAwaitingInputForBind)
				break;

			bPrimarySlot = args[args.Length - 2] == "primarySlot";
			iSelectedSlot = int(args[args.Length - 3]);

			m_bAwaitingInputForBind = true;
			m_bSecondaryKeyBeingBound = !bPrimarySlot;
			m_iKeySlotBeingBound = iSelectedSlot;

			AS_ActivateSlot(iSelectedSlot, !bPrimarySlot);
			
			break;
		case "clearBindingButton":
			if(m_bAwaitingInputForBind)
				break;

			bPrimarySlot = args[args.Length - 2] == "primarySlot";
			iSelectedSlot = int(args[args.Length - 3]);
			
			kPlayerInput = GetPlayerInput();

			if(m_arrDirtyPlayerInputs.Find(kPlayerInput) == INDEX_NONE)
				m_arrDirtyPlayerInputs.AddItem(kPlayerInput);

			kPlayerInput.RemoveBind(bPrimarySlot ? m_arrBindings[iSelectedSlot].PrimaryBind.Name : m_arrBindings[iSelectedSlot].SecondaryBind.Name, 
									bPrimarySlot ? m_arrBindings[iSelectedSlot].PrimaryBind.Command : m_arrBindings[iSelectedSlot].SecondaryBind.Command, 
									!bPrimarySlot);

			if(bPrimarySlot)
				m_arrBindings[iSelectedSlot].PrimaryBind = kEmptyKey;
			else
				m_arrBindings[iSelectedSlot].SecondaryBind = kEmptyKey;

			AS_ClearSlot(iSelectedSlot, !bPrimarySlot);
			break;
		}
	}
}

function PlayerInput GetPlayerInput()
{
	switch(m_eBindingCategory)
	{
	case eKC_General:  return m_kBaseInputController.PlayerInput; 
	case eKC_Tactical: return m_kTacticalInputController.PlayerInput;
	case eKC_Avenger:  return m_kHQInputController.PlayerInput; 
	//	case eKC_Geoscape: return m_kHQInputController.PlayerInput;
	}
}
function DisplayConfirmResetBindingsDialog()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.strTitle = m_strConfirmResetBindingsDialogTitle;
	kConfirmData.strText = m_strConfirmResetBindingsDialogText;
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericConfirm;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;

	kConfirmData.fnCallback = OnDisplayConfirmResetBindingsDialogAction;
		
	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDisplayConfirmResetBindingsDialogAction(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		ResetPlayerInputBindings();
		ReloadPlayerInputBindings();
		UpdateBindingsList();
	}
}

function DisplayConfirmCancelDialog()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.eType = eDialog_Warning;
	kConfirmData.strTitle = m_strConfirmDiscardChangesTitle;
	kConfirmData.strText = m_strConfirmDiscardChangesText;
	kConfirmData.strAccept = m_strConfirmDiscardChangesAcceptButton;
	kConfirmData.strCancel = m_strConfirmDiscardChangesCancelButton;

	kConfirmData.fnCallback = OnDisplayConfirmCancelDialog;
		
	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDisplayConfirmCancelDialog(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		ReloadPlayerInputBindings();
		Movie.Stack.Pop(self);
	}
}

simulated function UpdateTacticalHUD()
{
	local UITacticalHUD HUD;
	HUD = `PRES.GetTacticalHUD();
	if (HUD == none)
		return;

	HUD.m_kAbilityHUD.PopulateFlash();
}

function DisplayConflictingKeyDialog()
{
	local XGParamTag kTag;
	local TDialogueBoxData kConfirmData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = m_kKeybindingData.GetKeyString(m_kCachedKeyBeingBound);
	kTag.StrValue1 = m_arrBindings[m_iKeySlotConflicting].UserLabel;

	kConfirmData.eType = eDialog_Warning;
	kConfirmData.strTitle = m_strConfirmConflictingBindDialogTitle;
	kConfirmData.strText = `XEXPAND.ExpandString(m_strConfirmConflictingBindDialogText);
	kConfirmData.strAccept = m_strConfirmConflictingBindDialogAcceptButton;
	kConfirmData.strCancel = m_strConfirmConflictingBindDialogCancelButton;

	kConfirmData.fnCallback = OnDisplayConflictingKeyDialog;
		
	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDisplayConflictingKeyDialog(eUIAction eAction)
{
	local PlayerInput kPlayerInput;
	local PlayerController kPlayerController;
	local KeyBind kBind;

	if (eAction == eUIAction_Accept)
	{
		foreach WorldInfo.AllControllers(class'PlayerController', kPlayerController)
		{
			kPlayerInput = kPlayerController.PlayerInput;
		
			if(m_arrDirtyPlayerInputs.Find(kPlayerInput) == INDEX_NONE)
				m_arrDirtyPlayerInputs.AddItem(kPlayerInput);

			// Remove the conflicting key
			if(m_arrBindings[m_iKeySlotConflicting].PrimaryBind.Name == m_kCachedKeyBeingBound.Name)
				kBind = m_arrBindings[m_iKeySlotConflicting].PrimaryBind;
			else
				kBind = m_arrBindings[m_iKeySlotConflicting].SecondaryBind;

			if(kBind.Name != '')
				kPlayerInput.RemoveBind(kBind.Name, kBind.Command, kBind.bSecondaryBinding);
			// --

			// Remove the key that was on the slot being bound previously (if any)
			if(m_bSecondaryKeyBeingBound)
				kBind = m_arrBindings[m_iKeySlotBeingBound].SecondaryBind;
			else
				kBind = m_arrBindings[m_iKeySlotBeingBound].PrimaryBind;

			if(kBind.Name != '')
				kPlayerInput.RemoveBind(kBind.Name, kBind.Command, m_bSecondaryKeyBeingBound);
			//--

			if(m_bSecondaryKeyBeingBound)
				m_arrBindings[m_iKeySlotBeingBound].SecondaryBind = m_kCachedKeyBeingBound;
			else
				m_arrBindings[m_iKeySlotBeingBound].PrimaryBind = m_kCachedKeyBeingBound;

			kPlayerInput.AddBind(m_kCachedKeyBeingBound);
		}

		AS_DeactivateSlot(m_iKeySlotBeingBound, m_bSecondaryKeyBeingBound);
		AS_SetNewKey(m_iKeySlotBeingBound, m_bSecondaryKeyBeingBound, m_kKeybindingData.GetKeyString(m_kCachedKeyBeingBound));
		AS_ClearSlot(m_iKeySlotConflicting, !IsKeyPrimaryBinding(m_iKeySlotConflicting, m_kCachedKeyBeingBound.Name));	
	}
	else
	{
		AS_DeactivateSlot(m_iKeySlotBeingBound, m_bSecondaryKeyBeingBound);
	}
}

simulated function OnCommand(string cmd, string arg)
{
	switch(cmd)
	{
	case "AllBindingsLoaded":
		Show();
		break;
	}
}

simulated function bool OnAccept(optional string arg = "")
{
	local PlayerInput kPlayerInput;
	
	m_bKeybindindsChanged = true;
	foreach m_arrDirtyPlayerInputs(kPlayerInput)
	{
		kPlayerInput.SaveConfig();
	}
	ReloadPlayerInputBindings();
	UpdateTacticalHUD();
	Movie.Stack.Pop(self);
	return true;
}

simulated function bool OnCancel(optional string arg = "") 
{
	// If the player is inputting a command, cancel the input prompt
	if(m_bAwaitingInputForBind)
	{
		AS_DeactivateSlot(m_iKeySlotBeingBound, m_bSecondaryKeyBeingBound);
		m_bAwaitingInputForBind = false;
		return true;
	}

	if(m_arrDirtyPlayerInputs.Length > 0)
	{
		DisplayConfirmCancelDialog();
	}
	else
	{
		ReloadPlayerInputBindings();
		Movie.Stack.Pop(self);
	}

	return true;
}

//----------------------------------------------------------------------------------------------------
// NATIVE FUNCTIONS
simulated native function ReadBindings();

simulated native function ReloadPlayerInputBindings();
simulated native function ResetPlayerInputBindings();

// Returns the index into the m_arrBindings array if the key is already bound, 
simulated native function int  IsKeyAlreadyBound(name key, bool bCtrl, bool bAlt, bool bShift);
simulated native function bool IsKeyPrimaryBinding(int binding, name key);
simulated native function bool BlockUnbindingOfPrimaryKey(int enumIndex);

//----------------------------------------------------------------------------------------------------
// FLASH COMMUNICATION FUNCTIONS
simulated protected function AS_SetTitle( string txt ) 
{
	MC.BeginFunctionOp( "SetTitle" );
	MC.QueueString(txt);
	MC.EndOp();
}
simulated protected function AS_SetTabLabels( string tab1, string tab2, optional string tab3, optional string tab4) 
{
	MC.BeginFunctionOp( "SetTabLabels" );
	MC.QueueString(tab1);
	MC.QueueString(tab2);
	MC.QueueString(tab3);
	MC.QueueString(tab4);
	MC.EndOp();
}
simulated protected function AS_SetColumnLabels( string primaryColumn, string secondaryColumn ) 
{
	MC.BeginFunctionOp( "SetColumnLabels" );
	MC.QueueString(primaryColumn);
	MC.QueueString(secondaryColumn);
	MC.EndOp();
}
simulated protected function AS_SetButtonLabels( string resetToDefaultsButtonLabel, string backButtonLabel, string acceptButtonLabel ) 
{
	MC.BeginFunctionOp( "SetButtonLabels" );
	MC.QueueString(resetToDefaultsButtonLabel);
	MC.QueueString(backButtonLabel);
	MC.QueueString(acceptButtonLabel);
	MC.EndOp();
}
simulated protected function AS_SetPressKeyText( string txt ) 
{
	MC.BeginFunctionOp( "SetPressKeyText" );
	MC.QueueString(txt);
	MC.EndOp();
}
// BINDINGS LIST MANIPULATION FUNCTIONS
simulated protected function AS_AddKeyBindingSlot( string label, string primaryKey, string secondaryKey, bool blockUnbindingPrimaryKey ) 
{
	MC.BeginFunctionOp( "AddKeyBindingSlot" );
	MC.QueueString(label);
	MC.QueueString(primaryKey);
	MC.QueueString(secondaryKey);
	MC.QueueBoolean(blockUnbindingPrimaryKey);
	MC.EndOp();
}
simulated protected function AS_ClearBindingsList() 
{
	MC.FunctionVoid( "ClearBindingsList" );
}
// INDIVIDUAL LIST ITEM MANIPULATION FUNCTIONS
simulated protected function AS_ActivateSlot(int index, bool secondarySlot) 
{
	MC.BeginFunctionOp( "ActivateSlot" );
	MC.QueueNumber(index);
	MC.QueueBoolean(secondarySlot);
	MC.EndOp();
}
simulated protected function AS_DeactivateSlot(int index, bool secondarySlot) 
{
	MC.BeginFunctionOp( "DeactivateSlot" );
	MC.QueueNumber(index);
	MC.QueueBoolean(secondarySlot);
	MC.EndOp();
}
simulated protected function AS_SetNewKey(int index, bool secondarySlot, string newKey) 
{
	MC.BeginFunctionOp( "SetNewKey" );
	MC.QueueNumber(index);
	MC.QueueBoolean(secondarySlot);
	MC.QueueString(newKey);
	MC.EndOp();
}
simulated protected function AS_ClearSlot(int index, bool secondarySlot) 
{
	MC.BeginFunctionOp( "ClearSlot" );
	MC.QueueNumber(index);
	MC.QueueBoolean(secondarySlot);
	MC.EndOp();
}
// TAB CATEGORIES MANUIPULAITON FUNCTIONS
simulated protected function AS_ActivateTab( KeybindCategories eCat ) 
{
	m_eBindingCategory = eCat;
	MC.FunctionNum( "SetSelectedTab", int(eCat) );
}

// CLEANUP FUNCTION
simulated function Remove()
{
	super.Remove();

	DestroyInputClasses();
	XComInputBase(PC.PlayerInput).ClearAllRepeatTimers();
	XComInputBase(PC.PlayerInput).RemoveRawInputHandler(RawInputHandler);
}

event DestroyInputClasses()
{
	if(m_kBaseInputController != none && m_kShouldDestroyBaseInputController)
	{
		m_kBaseInputController.Destroy();
		m_kBaseInputController = none;
		m_kShouldDestroyBaseInputController = false;
	}

	if(m_kTacticalInputController != none && m_kShouldDestroyTacticalInputController)
	{
		m_kTacticalInputController.Destroy();
		m_kTacticalInputController = none;
		m_kShouldDestroyTacticalInputController = false;
	}

	if(m_kHQInputController != none && m_kShouldDestroyTacticalInputController)
	{
		m_kHQInputController.Destroy();
		m_kHQInputController = none;
		m_kShouldDestroyHQInputController = false;
	}
}

simulated function OnRemoved()
{
	if(m_bKeybindindsChanged)
		Movie.Pres.UpdateShortcutText();
}

defaultProperties
{
	Package = "/ package/gfxPCKeybindingsScreen/PCKeybindingsScreen";
	InputState = eInputState_Consume;
	m_kShouldDestroyBaseInputController = false;
	m_kShouldDestroyTacticalInputController = false;
}
