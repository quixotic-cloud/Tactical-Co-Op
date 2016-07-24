//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectBuildFacility.uc
//  AUTHOR:  Mark Nauta  --  04/22/2014
//  PURPOSE: This object represents the instance data for an XCom HQ build facility project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectBuildFacility extends XComGameState_HeadquartersProject native(Core);

//---------------------------------------------------------------------------------------
// Call when you start a new project
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameState_FacilityXCom FacilityState;

	AuxilaryReference = AuxRef;
	ProjectFocus = FocusRef;
	FacilityState = XComGameState_FacilityXCom(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	InitialProjectPoints = FacilityState.GetMyTemplate().PointsToComplete;
	ProjectPointsRemaining = Round(float(FacilityState.GetMyTemplate().PointsToComplete) * class'X2StrategyGameRulesetDataStructures'.default.BuildFacilityProject_TimeScalar[`DIFFICULTYSETTING]);
	UpdateWorkPerHour(NewGameState);
	StartDateTime = `STRATEGYRULES.GameTime;
	if(MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_Unit Builder;
	local XComGameState_StaffSlot SlotState;
	local int iTotalWork;
	local bool bHaveState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	iTotalWork = XComHQ.ConstructionRate; //Always start with the current construction rate
	
	bHaveState = (StartState != none);
	
	if(bHaveState)
	{
		Room = XComGameState_HeadquartersRoom(StartState.GetGameStateForObjectID(AuxilaryReference.ObjectID));
	}

	if(Room == none)
	{
		Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(AuxilaryReference.ObjectID));
	}
		
	if(Room != none)
	{
		if(bHaveState)
		{
			SlotState = XComGameState_StaffSlot(StartState.GetGameStateForObjectID(Room.BuildSlots[0].ObjectID));
		}

		if(SlotState == none)
		{
			SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(Room.BuildSlots[0].ObjectID));
		}
		Builder = Room.GetBuildSlot().GetAssignedStaff();

		if(SlotState != none)
		{
			if(bHaveState)
			{
				Builder = XComGameState_Unit(StartState.GetGameStateForObjectID(SlotState.AssignedStaff.ObjectID));
			}

			if(Builder == none)
			{
				Builder = XComGameState_Unit(History.GetGameStateForObjectID(SlotState.AssignedStaff.ObjectID));
			}

			if(Builder != none)
			{
				iTotalWork += Builder.GetSkillLevel();
			}
		}
	}

	return iTotalWork;
}

//---------------------------------------------------------------------------------------
// Add the facility to HQ's list of facilities and handle staffing stuff
function OnProjectCompleted()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_StaffSlot BuildSlotState, StaffSlotState;
	local X2FacilityTemplate FacilityTemplate;
	local StateObjectReference FacilityRef;
	local StaffUnitInfo BuilderInfo;
	local HeadquartersOrderInputContext OrderInput;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(AuxilaryReference.ObjectID));
	BuildSlotState = Room.GetBuildSlot();
	BuilderInfo.UnitRef = BuildSlotState.GetAssignedStaffRef();
	if (BuildSlotState.IsSlotFilledWithGhost())
		BuilderInfo.bGhostUnit = true;

	Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
	FacilityTemplate = Facility.GetMyTemplate();
	FacilityRef = Facility.GetReference();

	// Place Headquarters order
	OrderInput.OrderType = eHeadquartersOrderType_FacilityConstructionCompleted;
	OrderInput.AcquireObjectReference = Room.GetReference();
	OrderInput.FacilityReference = Facility.GetReference();
	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	// Call on built function
	if(FacilityTemplate.OnFacilityBuiltFn != none)
	{
		FacilityTemplate.OnFacilityBuiltFn(FacilityRef);
	}

	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
		
	`GAME.GetGeoscape().Pause();

	if (Facility.GetNumEmptyStaffSlots() > 0 && !Facility.GetMyTemplate().bHideStaffSlotOpenPopup)
	{
		StaffSlotState = Facility.GetStaffSlot(Facility.GetEmptyStaffSlotIndex());

		if ((StaffSlotState.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
			(StaffSlotState.IsEngineerSlot() && (XComHQ.GetNumberOfUnstaffedEngineers() > 0 || StaffSlotState.HasAvailableAdjacentGhosts())))
		{
			`HQPRES.UIStaffSlotOpen(Facility.GetReference(), StaffSlotState.GetMyTemplate());
		}
	}

	`HQPRES.UIFacilityComplete(FacilityRef, BuilderInfo);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}