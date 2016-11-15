//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_Storage.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_Storage extends UIFacility;

var public localized string m_strListEngineering;
var public localized string m_strBuildItems;
var public localized string m_strEngineers; 
var public localized string m_strStaffTooltip; 
var public localized string m_strAccessStaffing; 

var UIList ShortcutsSubMenu;
var bool bFocusOnShortcuts; 

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ, NewXComHQState;

	super.InitScreen(InitController, InitMovie, InitName);

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
				
	if (XComHQ != none && !XComHQ.bHasVisitedEngineering)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("First Visit to Storage");
		NewXComHQState = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewXComHQState.bHasVisitedEngineering = true;
		NewGameState.AddStateObject(NewXComHQState);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else if(XComHQ.IsObjectiveCompleted('T0_M5_WelcomeToEngineering') && !XComHQ.HasActiveShadowProject())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Shen Greeting");
		`XEVENTMGR.TriggerEvent('ShenGreeting', , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	BuildScreen();

	ShortcutsSubMenu = XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.Shortcuts.List;

	ClearFocusOffofFacilityButtons();
	bFocusOnShortcuts = true;
	//XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.Shortcuts.List.bLoopSelection = false;
	ShortcutsSubMenu.bLoopSelection = false;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE ||
		cmd == class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN)
	{
		if( m_kStaffSlotContainer.m_kPersonnelDropDown != none && m_kStaffSlotContainer.m_kPersonnelDropDown.bIsVisible )
		{
			m_kStaffSlotContainer.m_kPersonnelDropDown.OnUnrealCommand(cmd, arg);
			return true;
		}
		else
		{
			OnCancel();
			return true;
		}
	}
	
	if (cmd == class'UIUtilities_Input'.const.FXS_ARROW_UP ||
		cmd == class'UIUtilities_Input'.const.FXS_DPAD_UP ||
		cmd == class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP )
	{
		if (m_kStaffSlotContainer.StaffSlots.Length > 0)
		{
			if( m_kStaffSlotContainer.m_kPersonnelDropDown != none && m_kStaffSlotContainer.m_kPersonnelDropDown.bIsVisible )
			{
				m_kStaffSlotContainer.m_kPersonnelDropDown.OnUnrealCommand(cmd, arg);
				return true;
			}
			else if( ShortcutsSubMenu.SelectedIndex == 0 )
			{
				if( bFocusOnShortcuts )
				{
					SelectStaffing();
					return true;
				}
			}
			else if( ShortcutsSubMenu.SelectedIndex == -1 )
			{
				DeselectStaffing(false);
				//Allow to drop through
			}
		}
	}


	if (cmd == class'UIUtilities_Input'.const.FXS_ARROW_DOWN ||
		cmd == class'UIUtilities_Input'.const.FXS_DPAD_DOWN ||
		cmd == class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN )
	{
		if (m_kStaffSlotContainer.StaffSlots.Length > 0 )
		{
			if( m_kStaffSlotContainer.m_kPersonnelDropDown != none && m_kStaffSlotContainer.m_kPersonnelDropDown.bIsVisible )
			{
				m_kStaffSlotContainer.m_kPersonnelDropDown.OnUnrealCommand(cmd, arg);
				return true;
			}
			else if( ShortcutsSubMenu.SelectedIndex >= ShortcutsSubMenu.Navigator.Size - 1 )
			{
				if( bFocusOnShortcuts )
				{
					SelectStaffing();
					return true;
				}
			}
			else if( ShortcutsSubMenu.SelectedIndex == -1 )
			{
				DeselectStaffing(true);
				//Allow to drop through
			}

		}
	}

	return super.OnUnrealCommand(cmd, arg);
}
simulated function SelectStaffing()
{

	bFocusOnShortcuts = false;
	m_kStaffSlotContainer.SetSelectedNavigation();
	m_kStaffSlotContainer.Navigator.SelectFirstAvailableIfNoCurrentSelection();
	m_kStaffSlotContainer.OnReceiveFocus();

	ShortcutsSubMenu.ClearSelection();
	ShortcutsSubMenu.SetSelectedIndex(-1);
}

simulated function DeselectStaffing(bool bPressedDown)
{
	bFocusOnShortcuts = true;
	ClearFocusOffofFacilityButtons();
	if( bPressedDown )
		ShortcutsSubMenu.SetSelectedIndex(ShortcutsSubMenu.Navigator.Size);
	else
		ShortcutsSubMenu.SetSelectedIndex(-1);
}

simulated function RealizeStaffSlots()
{
	super.RealizeStaffSlots();
	UIStaffSlot(m_kStaffSlotContainer.Navigator.GetSelected()).OnLoseFocus();
}
simulated function BuildScreen()
{
	// Only display the Engineer count if there aren't any staff slots
	if( m_kStaffSlotContainer.StaffSlots.Length == 0 )
	{
		m_kStaffSlotContainer.SetTitle(m_strEngineers);
	}
	m_kStaffSlotContainer.SetStaffSkill(class'UIUtilities_Image'.const.AlertIcon_Engineering, String(XCOMHQ().GetNumberOfEngineers()));
	
	//Don't add this tooltip if we have staffslots up simultaneously. 
	if( m_kStaffSlotContainer.StaffSlots.Length == 0 )
		m_kStaffSlotContainer.SetTooltipText(m_strStaffTooltip);
	
}

simulated function RealizeNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;

	if( m_kStaffSlotContainer.StaffSlots.length > 0 && !m_kStaffSlotContainer.IsEmpty() )
		NavHelp.AddLeftHelp(m_strAccessStaffing, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);

	if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted(class'UIInventory_BuildItems'.default.WelcomeEngineeringObjective))
	{
		NavHelp.AddBackButton(OnCancel);
	}

	NavHelp.AddGeoscapeButton();
	NavHelp.AddSelectNavHelp();
}

simulated function OnCancel()
{
	if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted(class'UIInventory_BuildItems'.default.WelcomeEngineeringObjective))
	{
		super.OnCancel();
	}
}

simulated function TutorialForceExit()
{
	super.OnCancel();
}

simulated function OnRemoved()
{
	super.OnRemoved();
	
	`GAME.GetGeoscape().m_kBase.m_kAmbientVOMgr.TriggerShenVOEvent();
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Evaluate;
	bHideOnLoseFocus = false;
	//bIgnoreSuperInput = true;
	bAutoSelectFirstNavigable = false;
}