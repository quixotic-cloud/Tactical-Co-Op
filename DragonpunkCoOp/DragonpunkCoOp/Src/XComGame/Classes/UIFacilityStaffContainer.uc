//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIFacilityStaffContainer.uc
//  AUTHOR:  Joe Weinhoffer
//  PURPOSE: Staff container that will load in and format staff items. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIFacilityStaffContainer extends UIStaffContainer;

simulated function UIStaffContainer InitStaffContainer(optional name InitName, optional string NewTitle = DefaultStaffTitle)
{
	return super.InitStaffContainer(InitName, NewTitle);
	Navigator.HorizontalNavigation = true;
}

simulated function Refresh(StateObjectReference LocationRef, delegate<UIStaffSlot.OnStaffUpdated> onStaffUpdatedDelegate)
{
	local XComGameState_FacilityXCom Facility;
	local XComGameState_StaffSlot StaffSlot;
	local bool bSlotVisible;
	local int i;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(LocationRef.ObjectID));

	if (Facility.StaffSlots.Length == 0 || Facility.GetMyTemplate().bHideStaffSlots)
	{
		//Hide the box for facilities without any staffers, like the Armory, or for any facilities which have them permanently hidden. 
		Hide();
	}
	else 
	{
		// Show or create slots for the currently requested facility
		for (i = 0; i < Facility.StaffSlots.Length; i++)
		{
			// If the staff slot is locked and no upgrades are available, or it is always hidden, do not initialize or show the staff slot
			StaffSlot = Facility.GetStaffSlot(i);
			if ((StaffSlot.IsLocked() && !Facility.CanUpgrade()) || StaffSlot.IsHidden())
				continue;
			else
				bSlotVisible = true;

			if (i < StaffSlots.Length)
				StaffSlots[i].UpdateData();
			else
			{
				switch (Movie.Stack.GetCurrentClass())
				{
				case class'UIFacility_Academy':
					StaffSlots.AddItem(Spawn(class'UIFacility_AcademySlot', self).InitStaffSlot(self, LocationRef, i, onStaffUpdatedDelegate));
					break;
				case class'UIFacility_AdvancedWarfareCenter':
					if (StaffSlot.IsSoldierSlot())
						StaffSlots.AddItem(Spawn(class'UIFacility_AdvancedWarfareCenterSlot', self).InitStaffSlot(self, LocationRef, i, onStaffUpdatedDelegate));
					else
						StaffSlots.AddItem(Spawn(class'UIFacility_StaffSlot', self).InitStaffSlot(self, LocationRef, i, onStaffUpdatedDelegate));
					break;
				case class'UIFacility_PsiLab':
					if (StaffSlot.IsSoldierSlot())
						StaffSlots.AddItem(Spawn(class'UIFacility_PsiLabSlot', self).InitStaffSlot(self, LocationRef, i, onStaffUpdatedDelegate));
					else
						StaffSlots.AddItem(Spawn(class'UIFacility_StaffSlot', self).InitStaffSlot(self, LocationRef, i, onStaffUpdatedDelegate));
					break;
				default:
					StaffSlots.AddItem(Spawn(class'UIFacility_StaffSlot', self).InitStaffSlot(self, LocationRef, i, onStaffUpdatedDelegate));
					break;
				}
			}
		}
		
		if (bSlotVisible) // Show the container only if at least one slot is visible
			Show();
		else
			Hide();
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int SlotIdx;
	local UIStaffSlot StaffSlot;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if (cmd >= class'UIUtilities_Input'.const.FXS_KEY_F2 && cmd <= class'UIUtilities_Input'.const.FXS_KEY_F4)
	{
		SlotIdx = cmd - class'UIUtilities_Input'.const.FXS_KEY_F2;
		if (SlotIdx < StaffSlots.Length)
		{
			StaffSlot = StaffSlots[SlotIdx];
			StaffSlot.HandleClick();
			return true;
		}
	}
	
	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	bCascadeFocus = false;
}
