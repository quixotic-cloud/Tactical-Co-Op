//---------------------------------------------------------------------------------------
//  FILE:    UIRoom.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIRoom extends UIX2SimpleScreen
	dependson(UIPersonnel);

var public StateObjectReference RoomRef;
var public bool bInstantInterp;

var UIRoomStaffContainer m_kStaffSlotContainer;
var UIText m_kTitle;
var UIPanel ExcavationPanel;

var UINavigationHelp NavHelp;
var UILargeButton ExcavateButton;

var string CameraTag;

var localized string m_strExcavate;
var localized string m_strInfoLabel;
var localized string m_strTimeEstimate;
var localized string m_strTimeRemaining;
var localized string m_strExcavationReady;
var localized string m_strEngineerRequired;
var localized string m_strExcavationReward;
var localized string m_strExcavationRequiresEng;
var localized string m_strNoEngineersAvailable;
var localized string m_strExcavationInProgress;
var localized string m_strExcavationPaused;
var localized string m_strLeaveRoomWithoutClearingTile;
var localized string m_strLeaveRoomWithoutClearingText;
var localized string m_strLeaveRoomWithoutClearingWarning;
var localized string m_strBeginExcavation;
var localized string m_strLeaveRoom;
var localized string m_strConstructionInProgress;
var localized string m_strConstructionPaused;
var localized string m_strFacilityLabel;

var localized string m_sreAvengerLocationName;

var public delegate<OnStaffUpdated> onStaffUpdatedDelegate;
delegate onStaffUpdated();

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;
	local float InterpTime;

	super.InitScreen(InitController, InitMovie, InitName);

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	ExcavationPanel = Spawn(class'UIPanel', self);
	ExcavationPanel.bAnimateOnInit = false; 
	ExcavationPanel.InitPanel('', 'ExcavationStatus');
	
	BuildScreen();
	UpdateData();

	if (!GetRoom().ClearingRoom && !GetRoom().UnderConstruction)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Event Trigger: Enter Excavation");
		if (class'UIUtilities_Strategy'.static.GetXComHQ().GetNumberOfUnstaffedEngineers() == 0)
		{
			`XEVENTMGR.TriggerEvent('NoExcavateEngineers', , , NewGameState);
		}
		else
		{
			`XEVENTMGR.TriggerEvent('ExcavationPossible', , , NewGameState);
		}
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	`HQPRES.m_kAvengerHUD.HideEventQueue();

	InterpTime = `HQINTERPTIME;

	if (bInstantInterp)
	{
		InterpTime = 0;
	}

	if (CameraTag == "")
	{
		`HQPRES.CAMLookAtRoom(GetRoom(), InterpTime);
	}
	else
	{
		`HQPRES.CAMLookAtNamedLocation(CameraTag, InterpTime);
	}
}

simulated function BuildScreen()
{
	RealizeNavHelp();
	RealizeRoom();
}

simulated function UpdateData()
{
	local XComGameState_HeadquartersRoom Room;

	Room = GetRoom();

	ExcavationPanel.MC.BeginFunctionOp("UpdateData");
	ExcavationPanel.MC.QueueString(m_strInfoLabel);						//Header
	ExcavationPanel.MC.QueueString(GetExcavationStatusString());		//Title
	ExcavationPanel.MC.QueueString(GetExcavationTimeEstimateString());	//Subtitle

	if (Room.UnderConstruction)
		ExcavationPanel.MC.QueueString(m_strFacilityLabel);				//Construction Header
	else
		ExcavationPanel.MC.QueueString(m_strExcavationReward);			//RewardsHeader

	ExcavationPanel.MC.QueueString(GetExcavationRewardString());		//Rewards
	ExcavationPanel.MC.EndOp();

	if (GetRoom().HasStaff())
	{
		EnableExcavateButton();
	}
	else
	{
		DisableExcavateButton();
	}
}

simulated function RealizeNavHelp()
{
	local XComGameState_HeadquartersRoom Room;

	Room = GetRoom();

	NavHelp.ClearButtonHelp();
	if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M9_ExcavateRoom'))
	{
		NavHelp.AddBackButton(OnCancel);
		NavHelp.AddGeoscapeButton();
	}

	if (Room.HasSpecialFeature() && !Room.ClearingRoom && !Room.bSpecialRoomFeatureCleared)
		ShowExcavateButton();
	else
		HideExcavateButton();
}

simulated function RealizeRoom()
{
	if (RoomRef.ObjectID > 0)
	{
		CreateRoomContainer();
		RealizeStaffSlots();
	}
}

simulated function CreateRoomContainer()
{
	if (m_kStaffSlotContainer == none)
	{
		m_kStaffSlotContainer = Spawn(class'UIRoomStaffContainer', self);
		m_kStaffSlotContainer.InitStaffContainer();
		m_kStaffSlotContainer.SetMessage("");
	}
}

simulated function RealizeStaffSlots()
{
	onStaffUpdatedDelegate = UpdateData;

	if (m_kStaffSlotContainer != none)
	{
		m_kStaffSlotContainer.Refresh(RoomRef, onStaffUpdatedDelegate);
	}
}

simulated function ClickStaffSlot(int Index)
{
	if (m_kStaffSlotContainer != none)
	{
		UIRoom_StaffSlot(m_kStaffSlotContainer.GetChildAt(Index)).OnClickStaffSlot(none, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
	}
}

simulated function StartExcavation(UIButton Button)
{
	if (GetRoom().GetClearRoomProject() == none)
		GetRoom().StartClearRoom();

	CloseScreen();
}

simulated function ShowExcavateButton()
{
	if (ExcavateButton == none)
	{
		ExcavateButton = Spawn(class'UILargeButton', self);
		ExcavateButton.LibID = 'X2ContinueButton';
		ExcavateButton.bHideUntilRealized = true;
		ExcavateButton.InitLargeButton('ExcavateButton', m_strExcavate, "", StartExcavation);
		ExcavateButton.AnchorTopCenter();
		ExcavateButton.OffsetX = 10;
		ExcavateButton.OffsetY = 150;
	}
	else
	{
		ExcavateButton.Show();
	}
}

simulated function HideExcavateButton()
{
	if (ExcavateButton != none)
	{
		ExcavateButton.Hide();
	}
}

simulated function DisableExcavateButton()
{
	if (ExcavateButton != none)
	{
		ExcavateButton.DisableButton();
	}
}

simulated function EnableExcavateButton()
{
	if (ExcavateButton != none)
	{
		ExcavateButton.EnableButton();
	}
}

simulated function String GetExcavationStatusString()
{	
	local XComGameState_HeadquartersRoom Room;

	Room = GetRoom();

	if (Room.UnderConstruction)
	{
		if (Room.GetBuildFacilityProject().MakingProgress())
			return class'UIUtilities_Text'.static.GetColoredText(m_strConstructionInProgress, eUIState_Good);
		else
			return class'UIUtilities_Text'.static.GetColoredText(m_strConstructionPaused, eUIState_Warning);
	}
	else if (Room.ClearingRoom)
	{
		if (Room.GetClearRoomProject().MakingProgress())
			return class'UIUtilities_Text'.static.GetColoredText(m_strExcavationInProgress, eUIState_Good);
		else
			return class'UIUtilities_Text'.static.GetColoredText(m_strExcavationPaused, eUIState_Warning);
	}
	else if (Room.HasStaff())
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strExcavationReady, eUIState_Good);
	}
	else if (class'UIUtilities_Strategy'.static.GetXComHQ().GetNumberOfUnstaffedEngineers() == 0)
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strNoEngineersAvailable, euiState_Bad);
	}
	else // There are unstaffed engineers available
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strEngineerRequired, euiState_Bad);
	}
}

simulated function String GetExcavationTimeEstimateString()
{
	local XComGameState_HeadquartersRoom Room;
	
	Room = GetRoom();
	
	if (Room.UnderConstruction)
	{
		if (Room.GetBuildFacilityProject().MakingProgress())
		{
			return m_strTimeRemaining @ Caps(class'UIUtilities_Text'.static.GetTimeRemainingString(Room.GetBuildFacilityProject().GetCurrentNumHoursRemaining()));
		}
		else
		{
			return m_strTimeEstimate @ Caps(class'UIUtilities_Text'.static.GetTimeRemainingString(Room.GetBuildFacilityProject().GetProjectedNumHoursRemaining()));
		}
	}
	else if (Room.ClearingRoom)
	{
		if (Room.GetClearRoomProject().MakingProgress())
		{
			return m_strTimeRemaining @ Caps(class'UIUtilities_Text'.static.GetTimeRemainingString(Room.GetClearRoomProject().GetCurrentNumHoursRemaining()));
		}
		else
		{
			return m_strTimeEstimate @ Caps(class'UIUtilities_Text'.static.GetTimeRemainingString(Room.GetClearRoomProject().GetProjectedNumHoursRemaining()));
		}
	}
	else if (Room.HasStaff())
	{
		return m_strTimeEstimate @ class'UIUtilities_Text'.static.GetTimeRemainingString(Room.GetEstimatedClearHours());
	}
	else
	{
		return m_strExcavationRequiresEng;
	}
}

simulated function String GetExcavationRewardString()
{
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;

	Room = GetRoom();
	
	if (Room.UnderConstruction)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Room.GetBuildFacilityProject().ProjectFocus.ObjectID));
		return class'UIUtilities_Text'.static.GetColoredText(Caps(Facility.GetMyTemplate().DisplayName), eUIState_Good);		
	}
	else
	{
		return class'UIUtilities_Text'.static.GetColoredText(GetRoom().GetLootString(true), eUIState_Good);
	}	
}

simulated function EUIState GetExcavateColor()
{
	local XComGameState_HeadquartersRoom Room;

	Room = GetRoom();

	if (Room.UnderConstruction)
	{
		if (Room.GetBuildFacilityProject().MakingProgress())
			return eUIState_Good;
		else
			return eUIState_Bad;
	}
	else if (Room.ClearingRoom)
	{
		if (Room.GetClearRoomProject().MakingProgress())
			return eUIState_Good;
		else
			return eUIState_Bad;
	}
	else if (!Room.HasStaff())
	{
		return eUIState_Bad;
	}
	else
	{
		return eUIState_Warning;
	}
}

// override for custom behavior
simulated function OnAccept();

simulated function OnCancel()
{
	if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M9_ExcavateRoom'))
	{
		CloseScreen();
	}
}

simulated function CloseScreen()
{
	local XComGameState_HeadquartersRoom Room;

	Room = GetRoom();

	if (!Room.UnderConstruction && Room.GetClearRoomProject() == none && Room.HasStaff())
	{
		// the player has staffed people into the room to clear it, but did not start excavation
		LeaveRoomWithoutClearingPopup();
	}
	else
	{
		//The camera and transition effects are done, can fully exit the facility UI
		SetTimer(`HQINTERPTIME, false, nameof(UIRoom_FinishTransitionExit));
	}
}

//---------------------------------------------------------------------------------------
function LeaveRoomWithoutClearingPopup()
{
	local TDialogueBoxData DialogData;
	
	DialogData.eType = eDialog_Warning;
	DialogData.strTitle = m_strLeaveRoomWithoutClearingTile;
	DialogData.strText = m_strLeaveRoomWithoutClearingText;
	DialogData.strText $= "\n\n" $ m_strLeaveRoomWithoutClearingWarning;
	
	DialogData.fnCallback = ClearRoomCB;

	DialogData.strAccept = m_strBeginExcavation;
	DialogData.strCancel = m_strLeaveRoom;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuOpen");

	`HQPRES.UIRaiseDialog(DialogData);
}

simulated function ClearRoomCB(EUIAction eAction)
{
	local XComGameState NewGameState;

	if (eAction == eUIAction_Accept)
	{
		StartExcavation(ExcavateButton);
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Empty clear room staffing slots");
		GetRoom().EmptyAllBuildSlots(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClose");

		CloseScreen();
	}
}

function UIRoom_FinishTransitionExit()
{
	Movie.Stack.PopFirstInstanceOfClass(class'UIRoom');
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	bHandled = true;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		OnCancel();
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		OnAccept();
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	if (!bIsFocused)
	{
		super.OnReceiveFocus();
		NavHelp.ClearButtonHelp();
		RealizeNavHelp();
		RealizeRoom();
		UpdateData();
		if (CameraTag != "")
			`HQPRES.CAMLookAtNamedLocation(CameraTag, `HQINTERPTIME);
		else
			`HQPRES.CAMLookAtRoom(GetRoom(), `HQINTERPTIME);
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	NavHelp.ClearButtonHelp();
	HideExcavateButton();
}

simulated function OnRemoved()
{
	super.OnRemoved();

	NavHelp.ClearButtonHelp();
	HideExcavateButton();

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_AvengerNoRoom");
}

simulated function XComGameState_HeadquartersRoom GetRoom()
{
	return XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomRef.ObjectID));
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxFacilityHUD/FacilityHUD";
	//bShowFacilityBG = true;
}
