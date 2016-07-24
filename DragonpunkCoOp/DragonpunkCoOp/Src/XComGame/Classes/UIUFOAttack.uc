//---------------------------------------------------------------------------------------
//  FILE:    UIUFOAttack.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIUFOAttack extends UIX2SimpleScreen;

var public localized String m_strTitle;
var public localized String m_strBody;
var public localized String m_strConfirmMission;
var public localized String m_strUFOAttackObjective;
var public localized String m_strUFOAttackObjectiveDesc;

var StateObjectReference MissionRef;

var UIPanel LibraryPanel;
var UIPanel ShadowChamber;
var UIPanel DefaultPanel;
var UIButton Button1, Button2, Button3, ConfirmButton;
var UIPanel ButtonGroup;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On UFO Attack");
	`XEVENTMGR.TriggerEvent('OnUFOAttack', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	super.InitScreen(InitController, InitMovie, InitName);
	
	BindLibraryItem();

	BuildScreen();
}

simulated function BindLibraryItem()
{

	LibraryPanel = Spawn(class'UIPanel', self);
	LibraryPanel.bAnimateOnInit = false;
	LibraryPanel.InitPanel('', 'Alert_GoldenPath');

	DefaultPanel = Spawn(class'UIPanel', LibraryPanel);
	DefaultPanel.bAnimateOnInit = false;
	DefaultPanel.InitPanel('DefaultPanel');

	ConfirmButton = Spawn(class'UIButton', DefaultPanel);
	ConfirmButton.SetResizeToText(false);
	ConfirmButton.InitButton('ConfirmButton', "", OnLaunchClicked);

	ButtonGroup = Spawn(class'UIPanel', DefaultPanel);
	ButtonGroup.InitPanel('ButtonGroup', '');

	Button1 = Spawn(class'UIButton', ButtonGroup);
	Button1.SetResizeToText(false);
	Button1.InitButton('Button0', "");

	Button2 = Spawn(class'UIButton', ButtonGroup);
	Button2.SetResizeToText(false);
	Button2.InitButton('Button1', "");

	Button3 = Spawn(class'UIButton', ButtonGroup);
	Button3.SetResizeToText(false);
	Button3.InitButton('Button2', "");

	ShadowChamber = Spawn(class'UIPanel', LibraryPanel);
	ShadowChamber.InitPanel('ShadowChamber');
	ShadowChamber.Hide();
}

simulated function RefreshNavigation()
{
	if( ConfirmButton.bIsVisible )
	{
		ConfirmButton.EnableNavigation();
	}
	else
	{
		ConfirmButton.DisableNavigation();
	}

	if( Button1.bIsVisible )
	{
		Button1.EnableNavigation();
	}
	else
	{
		Button1.DisableNavigation();
	}

	if( Button2.bIsVisible )
	{
		Button2.EnableNavigation();
	}
	else
	{
		Button2.DisableNavigation();
	}
	if( Button3.bIsVisible )
	{
		Button3.EnableNavigation();
	}
	else
	{
		Button3.DisableNavigation();
	}

	LibraryPanel.bCascadeFocus = false;
	LibraryPanel.SetSelectedNavigation();
	DefaultPanel.bCascadeFocus = false;
	DefaultPanel.SetSelectedNavigation();
	ButtonGroup.bCascadeFocus = false;
	ButtonGroup.SetSelectedNavigation();

	if( Button1.bIsNavigable )
		Button1.SetSelectedNavigation();
	else if( Button2.bIsNavigable )
		Button2.SetSelectedNavigation();
	else if( Button3.bIsNavigable )
		Button3.SetSelectedNavigation();
	else if( ConfirmButton.bIsNavigable )
		ConfirmButton.SetSelectedNavigation();

	if( ShadowChamber != none )
		ShadowChamber.DisableNavigation();
}

simulated function BuildScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_UFO_Inbound");

	BuildMissionPanel();

	BuildOptionsPanel();

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
}

simulated function BuildMissionPanel()
{
	// Send over to flash ---------------------------------------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateGoldenPathInfoBlade");
	LibraryPanel.MC.QueueString(GetMission().GetMissionSource().MissionPinLabel);
	LibraryPanel.MC.QueueString(m_strTitle);
	LibraryPanel.MC.QueueString("img:///UILibrary_StrategyImages.X2StrategyMap.Alert_UFO_Attack");
	LibraryPanel.MC.QueueString(GetOpName());
	LibraryPanel.MC.QueueString(m_strUFOAttackObjective);
	LibraryPanel.MC.QueueString(m_strUFOAttackObjectiveDesc);
	LibraryPanel.MC.QueueString(m_strBody);
	if( GetMission().GetRewardAmountString() != "" )
	{
		LibraryPanel.MC.QueueString(class'UIMission'.default.m_strReward $":");
		LibraryPanel.MC.QueueString(GetMission().GetRewardAmountString());
	}
	LibraryPanel.MC.EndOp();
}

simulated function BuildOptionsPanel()
{
	LibraryPanel.MC.BeginFunctionOp("UpdateGoldenPathIntel");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.EndOp();

	// ---------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateGoldenPathButtonBlade");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strConfirmMission);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.default.m_strGenericCancel);
	LibraryPanel.MC.EndOp();

	// ---------------------

	Button1.SetBad(true);
	Button1.OnClickedDelegate = OnLaunchClicked;

	Button2.Hide();
	Button3.Hide();
	ConfirmButton.Hide();
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnLaunchClicked(UIButton button)
{
	GetMission().SelectSquad();
	CloseScreen();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local UIButton CurrentButton;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	bHandled = true;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		
		CurrentButton = UIButton(ButtonGroup.Navigator.GetSelected());
		if( CurrentButton.bIsVisible && !CurrentButton.IsDisabled )
		{
			CurrentButton.Click();
			return true;
		}
		//If you don't have a current button, fall down and hit the Navigation system. 
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function String GetOpName()
{
	local GeneratedMissionData MissionData;

	MissionData = XCOMHQ().GetGeneratedMissionData(MissionRef.ObjectID);

	return MissionData.BattleOpName;
}
simulated function XComGameState_MissionSite GetMission()
{
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	return XComGameState_MissionSite(History.GetGameStateForObjectID(MissionRef.ObjectID));
}

//==============================================================================
defaultproperties
{
	Package = "/ package/gfxAlerts/Alerts";
	InputState = eInputState_Consume;
}}