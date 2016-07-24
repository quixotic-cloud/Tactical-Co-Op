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
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE ||
		cmd == class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN)
	{
		OnCancel();
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
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

	if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted(class'UIInventory_BuildItems'.default.WelcomeEngineeringObjective))
	{
		NavHelp.AddBackButton(OnCancel);
	}

	NavHelp.AddGeoscapeButton();
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
}