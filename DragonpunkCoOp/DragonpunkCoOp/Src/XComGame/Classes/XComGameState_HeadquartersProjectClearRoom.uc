//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectBuildFacility.uc
//  AUTHOR:  Mark Nauta  --  05/28/2014
//  PURPOSE: This object represents the instance data for an XCom HQ clear room project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectClearRoom extends XComGameState_HeadquartersProject native(Core);

//---------------------------------------------------------------------------------------
// Call when you start a new project
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameState_HeadquartersRoom Room;

	Room = XComGameState_HeadquartersRoom(NewGameState.GetGameStateForObjectID(FocusRef.ObjectID));

	AuxilaryReference = AuxRef;
	ProjectFocus = FocusRef;
	InitialProjectPoints = Room.GetSpecialFeature().PointsToComplete * Room.BuildSlots.Length;

	if (Room.GridRow == 0) // If in the first row, apply an additional time scalar
	{
		InitialProjectPoints *= class'X2StrategyGameRulesetDataStructures'.default.ClearRoomProjectFirstRow_TimeScalar[`DIFFICULTYSETTING];
	}

	ProjectPointsRemaining = Round(float(InitialProjectPoints) * class'X2StrategyGameRulesetDataStructures'.default.ClearRoomProject_TimeScalar[`DIFFICULTYSETTING]);
	
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
	local int ConstructionRate, NumBuildSlots;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(ProjectFocus.ObjectID));

	if (!bAssumeActive)
	{
		if (!Room.HasStaff())
		{
			return -1;
		}
	}

	ConstructionRate = XComHQ.ConstructionRate;
	if (ConstructionRate == 0)
	{
		ConstructionRate = XComHQ.XComHeadquarters_DefaultConstructionWorkPerHour;
	}

	NumBuildSlots = Room.GetNumFilledBuildSlots();
	if (NumBuildSlots == 0 && bAssumeActive)
	{
		NumBuildSlots = 1;
	}
	
	return ConstructionRate * NumBuildSlots;
}

//---------------------------------------------------------------------------------------
// Add the facility to HQ's list of facilities and handle staffing stuff
function OnProjectCompleted()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersRoom Room;
	local HeadquartersOrderInputContext OrderInput;
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local array<StaffUnitInfo> BuilderInfoList;
	local XComGameState_StaffSlot StaffSlot;
	local int SlotIndex;
	local StaffUnitInfo BuilderInfo;

	History = `XCOMHISTORY;
	Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
	SpecialFeature = Room.GetSpecialFeature();
	for (SlotIndex = 0; SlotIndex < Room.BuildSlots.Length; ++SlotIndex)
	{
		StaffSlot = Room.GetBuildSlot(SlotIndex);
		if (StaffSlot != none)
		{
			BuilderInfo.UnitRef = StaffSlot.GetAssignedStaffRef();
			if( BuilderInfo.UnitRef.ObjectID > 0 )
			{
				if (StaffSlot.IsSlotFilledWithGhost())
					BuilderInfo.bGhostUnit = true;

				BuilderInfoList.AddItem(BuilderInfo);
			}
		}
	}

	OrderInput.OrderType = eHeadquartersOrderType_ClearRoomCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_ProjectComplete");

	`HQPRES.UIClearRoomComplete(Room.GetReference(), SpecialFeature, BuilderInfoList);

	// Actually add the loot which was generated from clearing to the inventory
	class'XComGameStateContext_StrategyGameRule'.static.AddLootToInventory();
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}