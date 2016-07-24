//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPersonnel_ChooseResearch
//  AUTHOR:  Sam Batista
//  PURPOSE: Provides custom behavior for personnel selection screen when
//           selecting research.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIPersonnel_ChooseResearch extends UIPersonnel;

// GAME DATA
var public StateObjectReference StaffSlotRef; // set in XComHQPresentationLayer

simulated function UpdateData()
{
	local int i, iFound; 
	local XComGameState_StaffSlot StaffSlotState;
	local int StaffID; 

	super.UpdateData();
	
	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	// Remove scientists currently staffed here, since you can't assign them if they are already here. 
	for(i = 0; i < StaffSlotState.GetFacility().StaffSlots.Length; i++)
	{		
		StaffID = StaffSlotState.GetFacility().GetStaffSlot(i).GetAssignedStaffRef().ObjectID;
		iFound = m_arrScientists.Find('ObjectID', StaffID);
		if( iFound > -1 )
			m_arrScientists.Remove(iFound, 1);
	}
}

defaultproperties
{
	m_eListType = eUIPersonnel_Scientists;
	m_bRemoveWhenUnitSelected = true;
}