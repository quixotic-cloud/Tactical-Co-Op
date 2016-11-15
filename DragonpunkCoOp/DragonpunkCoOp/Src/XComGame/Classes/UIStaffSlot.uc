//---------------------------------------------------------------------------------------
//  FILE:    UIStaffSlot.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIStaffSlot extends UIPanel
	dependson(UIPersonnel);

var public StateObjectReference StaffSlotRef;

var UIText m_kStaffName;
var UIText m_kStaffStatus;
var UIBGBox m_kBG;

var localized string m_strOpenSlot;
var localized string m_strCannotEmptySlotTitle;
var localized string m_strCannotEmptySlotText;
var localized string m_strCannotMoveStaffTitle;
var localized string m_strCannotMoveStaffText;

var UIStaffContainer StaffContainer;
var StaffUnitInfo m_PendingStaff; // used when reassigning staff
var bool m_QueuedDropDown;
var bool bSizeRealized;
var bool  IsDisabled;

var public delegate<OnStaffUpdated> onStaffUpdatedDelegate;

delegate OnStaffUpdated();

//-----------------------------------------------------------------------------

simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	// Subclasses need to initialize StaffSlotRef

	InitPanel();
	
	StaffContainer = OwningContainer;
	onStaffUpdatedDelegate = onStaffUpdatedDel;

	ProcessMouseEvents(OnClickStaffSlot);

	UpdateData();

	return self;
}

simulated function OnCommand(string cmd, string arg)
{
	local array<string> sizeData;
	if (cmd == "RealizeDimensions")
	{
		sizeData = SplitString(arg, ",");
		X = float(sizeData[0]);
		Y = float(sizeData[1]);
		Width = float(sizeData[2]);
		Height = float(sizeData[3]);
		bSizeRealized = true;

		// update location of dropdown that might be attached to this Staff Slot
		if(m_QueuedDropDown || (StaffContainer.m_kPersonnelDropDown != none && StaffContainer.m_kPersonnelDropDown.bIsVisible &&  StaffContainer.m_kPersonnelDropDown.SlotRef == StaffSlotRef))
		{
			ShowDropDown();
			m_QueuedDropDown = false;
		}
	}
}

simulated function QueueDropDownDisplay()
{
	m_QueuedDropDown = true;
}

simulated function UIStaffSlot SetDisabled(bool disabled)
{
	if(IsDisabled != disabled)
	{
		IsDisabled = disabled;
		mc.FunctionVoid(IsDisabled ? "disable" : "enable");
	}
	return self;
}

simulated function UpdateData()
{
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_Unit Unit;
	local string UnitTypeImage;

	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
	Unit = StaffSlotState.GetAssignedStaff();

	if (Unit != none)
	{
		if (Unit.IsAnEngineer())
		{
			UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Engineer;
		}
		else if (Unit.IsAScientist())
		{
			UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Science;
		}
		else if (Unit.IsSoldier())
		{
			UnitTypeImage = class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName());
		}
	}
	else
	{
		UnitTypeImage = "";
	}

	Update(StaffSlotState.GetNameDisplayString(),
		Caps(StaffSlotState.GetBonusDisplayString()),
		UnitTypeImage);
	
	SetDisabled(!IsUnitAvailableForThisSlot());
}

simulated function Update(string StaffName, string StaffBonus, string StaffTypeIcon)
{
	MC.BeginFunctionOp("update");
	MC.QueueString(StaffName);
	MC.QueueString(StaffBonus);
	MC.QueueString(StaffTypeIcon);
	MC.EndOp();
}

simulated function bool IsUnitAvailableForThisSlot()
{
	local int i;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot SlotState;
	local StaffUnitInfo UnitInfo;
	local XComGameState_HeadquartersXCom HQState;

	local int GhostSlot;
	local array<XComGameState_StaffSlot> AdjacentGhostStaffSlots;

	History = `XCOMHISTORY;
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (SlotState.IsSlotFilled())
	{
		return true;
	}

	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();
	for (i = 0; i < HQState.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(HQState.Crew[i].ObjectID));

		UnitInfo.UnitRef = Unit.GetReference();
		UnitInfo.bGhostUnit = false;
		UnitInfo.GhostLocation.ObjectID = 0;

		if (SlotState.ValidUnitForSlot(UnitInfo))
		{
			return true;
		}
	}
	// Need to check for ghost staff (Gremlins) because if the player's only engineer is staffing
	// the workshop the staffing button of adjacent buildings will remain inactive even if there are
	// available Gremlins.
	AdjacentGhostStaffSlots = SlotState.GetAdjacentGhostCreatingStaffSlots();
	for (GhostSlot = 0; GhostSlot < AdjacentGhostStaffSlots.Length; GhostSlot++)
	{
		Unit = AdjacentGhostStaffSlots[GhostSlot].GetAssignedStaff();

		// Failsafe check to ensure that ghosts are only displayed for matching unit and staff slot references
		if (Unit.StaffingSlot.ObjectID == AdjacentGhostStaffSlots[GhostSlot].ObjectID)
		{
			// Create ghosts duplicating the unit who is staffed in the ghost-creating slot
			UnitInfo.UnitRef = Unit.GetReference();
			UnitInfo.bGhostUnit = true;
			UnitInfo.GhostLocation.ObjectID = 0;

			// Check if they are valid for the slot
			if (SlotState.ValidUnitForSlot(UnitInfo))
			{
				return true;
			}
		}
	}
	return false;
}

simulated function HandleClick()
{
	local XComGameState_StaffSlot StaffSlotState;
	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
	if (StaffSlotState.IsLocked())
	{
		ShowUpgradeFacility();
	}
	else
	{
		`SOUNDMGR.PlaySoundEvent("Play_MenuOpenSmall");
		ShowDropDown();
	}
}

// This will be overwritten in specific staff slot subclasses
simulated function ShowDropDown()
{
	StaffContainer.ShowDropDown(self);
}

simulated function HideDropDown()
{
	local XComGameState_StaffSlot StaffSlotState;
	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
	if (!StaffSlotState.IsLocked())
	{
		StaffContainer.HideDropDown(self);
	}
}


simulated function OnClickStaffSlot(UIPanel kControl, int cmd)
{
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		HandleClick();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
		HideDropDown();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER: 
		`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
		break;
	}
}

simulated function ShowUpgradeFacility()
{
	local XComGameState_StaffSlot StaffSlotState;

	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
	if (StaffSlotState.GetFacility().CanUpgrade())
	{
		StaffContainer.HideDropDown();
		`HQPRES.UIFacilityUpgrade(StaffSlotState.Facility);
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

// This popup is called by specialized staffing slot subclasses that need to perform special functions when removing staffers (ex: PsiLabSlot)
simulated function ConfirmEmptyProjectSlotPopup(string DialogTitle, string DialogText, optional bool bWarning = true)
{
	local TDialogueBoxData DialogData;

	DialogData.eType = bWarning ? eDialog_Warning : eDialog_Alert;
	DialogData.strTitle = DialogTitle;
	DialogData.strText = DialogText;

	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

	DialogData.fnCallback = ConfirmEmptyProjectSlotPopupCallback;

	`HQPRES.UIRaiseDialog(DialogData);
}

simulated function ConfirmEmptyProjectSlotPopupCallback(eUIAction eAction)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot StaffSlotState;

	if (eAction == eUIAction_Accept)
	{
		StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
		StaffSlotState.EmptySlotStopProject(); // Calls a HQ Order which will perform the Empty staff slot function included as part of additional functionality

		class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		XComHQ.HandlePowerOrStaffingChange();
		
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Remove");

		UpdateData();

		if (onStaffUpdatedDelegate != none)
			onStaffUpdatedDelegate();

		// Most personnel screens remove themselves from the stack, but check just to be sure -sbatista
		if (Movie.Stack.HasInstanceOf(class'UIPersonnel'))
			Movie.Stack.PopFirstInstanceOfClass(class'UIPersonnel');
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameState_StaffSlot StaffSlotState;

	OnLoseFocus();
	m_PendingStaff = UnitInfo;
	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
	
	// The user clicked on an "Empty" staff slot, so empty this slot
	if (UnitInfo.UnitRef.ObjectID == 0 && StaffSlotState.IsSlotFilled())
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Remove");
		EmptyStaffSlot(StaffSlotState);
	}
	else if (StaffSlotState.GetAssignedStaffRef() != UnitInfo.UnitRef) // do nothing if attempting to assign the same staffer again
	{
		if (class'UIUtilities_Strategy'.static.CanReassignStaff(UnitInfo, GetNewLocationString(StaffSlotState), ReassignStaffCallback))
			ReassignStaffCallback(eUIAction_Accept);
	}
}

simulated function bool IsSlotFilled()
{
	local XComGameState_StaffSlot StaffSlot;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	return StaffSlot.IsSlotFilled();
}

simulated function string GetNewLocationString(XComGameState_StaffSlot StaffSlotState)
{
	// Should be implemented by subclass
	return "";
}

simulated function ReassignStaffCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		ReassignStaff(m_PendingStaff);
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function ReassignStaff(StaffUnitInfo UnitInfo)
{
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot StaffSlotState, OldStaffSlot;
	local XComGameStateHistory History;
	local StateObjectReference EmptyRef;

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID)); // the new unit attempting to fill the staff slot
	
	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID)); // the staff slot being filled
	if (StaffSlotState.MaxAdjacentGhostStaff > 0 && !EmptyStaffSlot(StaffSlotState)) // if the slot provides ghosts, make sure that it can be emptied first
		return;

	// Then check the unit or ghosts current staffing slot and try to empty it
	if (UnitInfo.bGhostUnit)
	{
		OldStaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(UnitInfo.GhostLocation.ObjectID));
	}
	else if (Unit.StaffingSlot != EmptyRef)
	{
		OldStaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(Unit.StaffingSlot.ObjectID));
	}

	if (OldStaffSlot != none)
	{
		// if users are trying to assign a staff to the same slot they were previously on, bail out (do nothing).
		if (StaffSlotState.ObjectID == OldStaffSlot.ObjectID)
		{
			return;
		}
		else
		{
			if (!EmptyStaffSlot(OldStaffSlot))
				return; // If emptying fails
		}
	}

	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID)); // need to update gamestate in case it was emptied earlier
	FillStaffSlot(StaffSlotState, UnitInfo);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event On Staff Select");
	`XEVENTMGR.TriggerEvent('OnStaffSelected', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function bool EmptyStaffSlot(XComGameState_StaffSlot StaffSlotState)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	if (StaffSlotState.IsSlotFilled())
	{
		if (!StaffSlotState.CanStaffBeMoved()) // If the unit is providing a critical function at their current slot, they can't be moved
		{
			if (StaffSlotState.GetReference().ObjectID == StaffSlotRef.ObjectID)
				SlotCantBeEmptiedPopup(StaffSlotState);
			else
				StafferCantBeMovedPopup(StaffSlotState);

			return false;
		}

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Empty Staff Slot");
		StaffSlotState.EmptySlot(NewGameState);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		XComHQ.HandlePowerOrStaffingChange();

		`HQPRES.m_kAvengerHUD.UpdateResources();
		
		if (Movie.Pres.ScreenStack.HasInstanceOf(class'UIRoom'))
			UIRoom(Movie.Pres.ScreenStack.GetScreen(class'UIRoom')).RealizeStaffSlots();
		else if (Movie.Pres.ScreenStack.HasInstanceOf(class'UIFacility'))
			UIFacility(Movie.Pres.ScreenStack.GetFirstInstanceOf(class'UIFacility')).RealizeStaffSlots();
		else
			UpdateData();

		if (onStaffUpdatedDelegate != none)
			onStaffUpdatedDelegate();
	}

	return true;
}

simulated function FillStaffSlot(XComGameState_StaffSlot StaffSlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
		
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fill Staff Slot");
	StaffSlotState.FillSlot(NewGameState, UnitInfo);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	// If the unit just added is a ghost, update its location to its new staff slot before passing to the Alerts
	if (UnitInfo.bGhostUnit)
	{
		UnitInfo.GhostLocation = StaffSlotState.GetReference();
	}

	// Trigger the appropriate popup to tell the player about the benefit they have received by filling this staff slot
	Room = StaffSlotState.GetRoom();
	if (Room != none)
	{
		if (Room.ClearingRoom)
		{
			`HQPRES.UIClearRoomSlotFilled(Room.GetReference(), UnitInfo);
		}
		else if (Room.UnderConstruction)
		{
			`HQPRES.UIConstructionSlotFilled(Room.GetReference(), UnitInfo);
		}
	}
	else
	{
		`HQPRES.UIStaffSlotFilled(StaffSlotState.GetFacility().GetReference(), StaffSlotState.GetMyTemplate(), UnitInfo);
	}

	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.HandlePowerOrStaffingChange();

	`HQPRES.m_kAvengerHUD.UpdateResources();

	if (Movie.Pres.ScreenStack.HasInstanceOf(class'UIRoom'))
		UIRoom(Movie.Pres.ScreenStack.GetScreen(class'UIRoom')).RealizeStaffSlots();
	else
		UpdateData();

	if (onStaffUpdatedDelegate != none)
		onStaffUpdatedDelegate();
}

simulated function SlotCantBeEmptiedPopup(XComGameState_StaffSlot StaffSlotState)
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Warning;
	DialogData.strTitle = m_strCannotEmptySlotTitle;
	DialogData.strText = m_strCannotEmptySlotText;
	DialogData.strText = Repl(DialogData.strText, "%ENGNAME", StaffSlotState.GetNameDisplayString());

	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	`HQPRES.UIRaiseDialog(DialogData);
}

simulated function StafferCantBeMovedPopup(XComGameState_StaffSlot StaffSlotState)
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Warning;
	DialogData.strTitle = m_strCannotMoveStaffTitle;
	DialogData.strText = m_strCannotMoveStaffText;
	DialogData.strText = Repl(DialogData.strText, "%ENGNAME", StaffSlotState.GetNameDisplayString());

	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	`HQPRES.UIRaiseDialog(DialogData);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	if( cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_ENTER )
	{
		if (!IsDisabled)
		{
			OnClickStaffSlot(none, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
		}

		return true;
	}
	
	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	bIsFocused = true;
	if( `ISCONTROLLERACTIVE )
		MC.FunctionVoid("mouseIn");
}

simulated function OnLoseFocus()
{
	bIsFocused = false;
	if( `ISCONTROLLERACTIVE )
		MC.FunctionVoid("mouseOut");
}

//==============================================================================

defaultproperties
{
	LibID = "StaffSlot";
	bShouldPlayGenericUIAudioEvents = false;
	m_QueuedDropDown = false;
}
