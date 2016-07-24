//---------------------------------------------------------------------------------------
//  FILE:    UIRoom_StaffSlot.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIRoom_StaffSlot extends UIStaffSlot;

var localized string BuildingFacilityLabel;
//-----------------------------------------------------------------------------

simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	local XComGameState_HeadquartersRoom Room;
	
	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(LocationRef.ObjectID));
	StaffSlotRef = Room.GetBuildSlot(SlotIndex).GetReference();

	return super.InitStaffSlot(OwningContainer, LocationRef, SlotIndex, onStaffUpdatedDel);
}

simulated function string GetNewLocationString(XComGameState_StaffSlot StaffSlotState)
{
	local XComGameStateHistory History;
	local XGParamTag kTag;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_HeadquartersProjectBuildFacility ProjectState;
	local XComGameState_FacilityXCom FacilityState;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Room = StaffSlotState.GetRoom();

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectBuildFacility', ProjectState)
	{
		if(ProjectState.AuxilaryReference == Room.GetReference())
		{
			FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

			if(FacilityState != none)
			{
				kTag.StrValue0 = FacilityState.GetMyTemplate().DisplayName;
				return `XEXPAND.ExpandString(default.BuildingFacilityLabel);
			}
		}
	}
	return Room.GetClearingInProgressLabel();
}

//==============================================================================

defaultproperties
{
}
