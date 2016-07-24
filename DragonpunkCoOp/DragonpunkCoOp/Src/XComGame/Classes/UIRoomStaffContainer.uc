//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIRoomStaffContainer.uc
//  AUTHOR:  Joe Weinhoffer
//  PURPOSE: Staff container that will load in and format staff items. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIRoomStaffContainer extends UIStaffContainer;

simulated function UIStaffContainer InitStaffContainer(optional name InitName, optional string NewTitle = DefaultStaffTitle)
{
	return super.InitStaffContainer(InitName, NewTitle);
}

simulated function Refresh(StateObjectReference LocationRef, delegate<UIStaffSlot.OnStaffUpdated> onStaffUpdatedDelegate)
{
	local int i;
	local XComGameState_HeadquartersRoom Room;

	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(LocationRef.ObjectID));
		
	// Show or create slots for the currently requested facility
	for (i = 0; i < Room.BuildSlots.Length; i++)
	{
		if (i < StaffSlots.Length)
			StaffSlots[i].UpdateData();
		else
		{
			StaffSlots.AddItem(Spawn(class'UIRoom_StaffSlot', self).InitStaffSlot(self, LocationRef, i, onStaffUpdatedDelegate));
		}

		// If the room is under construction, only show one staff slot
		if (Room.UnderConstruction)
			break;
	}

	//Hide the box for facilities without any staffers, like the Armory, or for any facilities which have them permanently hidden. 
	if (Room.BuildSlots.Length > 0)
		Show();
	else
		Hide();
}

defaultproperties
{
}
