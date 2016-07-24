//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_StaffSlot.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_StaffSlot extends UIStaffSlot;

//-----------------------------------------------------------------------------

simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	local XComGameState_FacilityXCom Facility;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(LocationRef.ObjectID));
	StaffSlotRef = Facility.GetStaffSlot(SlotIndex).GetReference();
	
	super.InitStaffSlot(OwningContainer, LocationRef, SlotIndex, onStaffUpdatedDel);

	return self;
}

simulated function string GetNewLocationString(XComGameState_StaffSlot StaffSlotState)
{
	return StaffSlotState.GetFacility().GetMyTemplate().DisplayName;
}

//==============================================================================

defaultproperties
{
}
