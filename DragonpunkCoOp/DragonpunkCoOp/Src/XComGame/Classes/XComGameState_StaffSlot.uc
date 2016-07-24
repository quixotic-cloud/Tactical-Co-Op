//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_StaffSlot.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_StaffSlot extends XComGameState_BaseObject;

var() protected name                   m_TemplateName;
var() protected X2StaffSlotTemplate    m_Template;

var StateObjectReference			   Facility;
var StateObjectReference			   Room; // Use for staff slots that don't have a facility (Build Slot)
var StateObjectReference			   AssignedStaff;

var int								   MaxAdjacentGhostStaff; // the maximum number of ghost staff units this slot can create
var int								   AvailableGhostStaff; // the current number of possible ghost units which can be staffed in adjacent rooms

var() bool							   bIsLocked; // If the staff slot is locked and cannot be staffed

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

//---------------------------------------------------------------------------------------
simulated function X2StaffSlotTemplate GetMyTemplate()
{
	if(m_Template == none)
	{
		m_Template = X2StaffSlotTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
function OnCreation(X2StaffSlotTemplate Template)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
}

//#############################################################################################
//----------------   ACCESS   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function LockSlot()
{
	bIsLocked = true;
}

//---------------------------------------------------------------------------------------
function UnlockSlot()
{
	bIsLocked = false;
}

//---------------------------------------------------------------------------------------
function bool IsLocked()
{
	return bIsLocked;
}

//#############################################################################################
//----------------   FILLING/EMPTYING   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool ValidUnitForSlot(StaffUnitInfo UnitInfo)
{
	if (GetMyTemplate().IsUnitValidForSlotFn != None)
	{
		return GetMyTemplate().IsUnitValidForSlotFn(self, UnitInfo);
	}

	// If there is no function to check if the unit is valid, assume all staff are allowed
	return true;
}

//---------------------------------------------------------------------------------------
function bool CanStaffBeMoved()
{
	// If slot is filled, check if the staffer can be moved without breaking anything
	if (IsSlotFilled())
	{
		if (GetMyTemplate().CanStaffBeMovedFn != None)
		{
			return GetMyTemplate().CanStaffBeMovedFn(self.GetReference());
		}
	}
	
	// If the slot is empty or no slot check function, no issue
	return true;
}

//---------------------------------------------------------------------------------------
function bool IsStaffSlotBusy()
{
	// If slot is filled, check if the staffer is currently busy working on something
	if (IsSlotFilled())
	{
		if (GetMyTemplate().IsStaffSlotBusyFn != None)
		{
			return GetMyTemplate().IsStaffSlotBusyFn(self);
		}
	}

	// If the slot is empty or no function exists, it is not busy
	return false;
}

//---------------------------------------------------------------------------------------
function bool IsSlotFilled()
{
	local StateObjectReference EmptyRef;

	return (AssignedStaff != EmptyRef);
}

//---------------------------------------------------------------------------------------
function bool IsSlotFilledWithGhost(optional out XComGameState_StaffSlot GhostOwnerSlot)
{
	local array<XComGameState_StaffSlot> AdjacentGhostStaffSlots;
	local XComGameState_StaffSlot AdjacentGhostStaffSlot;
	local int iSlot;

	if (IsSlotFilled())
	{
		// First get any adjacent slots which could produce ghosts
		AdjacentGhostStaffSlots = GetAdjacentGhostCreatingStaffSlots();
		for (iSlot = 0; iSlot < AdjacentGhostStaffSlots.Length; iSlot++)
		{
			AdjacentGhostStaffSlot = AdjacentGhostStaffSlots[iSlot];

			// If the owner of the ghost-creating staff slot is also staffed here, this unit is duplicated and therefore a ghost
			if (AdjacentGhostStaffSlot.GetAssignedStaffRef().ObjectID == GetAssignedStaffRef().ObjectID)
			{
				GhostOwnerSlot = AdjacentGhostStaffSlot;
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_StaffSlot> GetAdjacentStaffSlots()
{
	if (Facility.ObjectID == 0)
		return GetRoom().GetAdjacentStaffSlots();
	else
		return GetFacility().GetRoom().GetAdjacentStaffSlots();
}

//---------------------------------------------------------------------------------------
function array<XComGameState_StaffSlot> GetAdjacentGhostCreatingStaffSlots()
{
	if (Facility.ObjectID == 0)
		return GetRoom().GetAdjacentGhostCreatingStaffSlots();
	else
		return GetFacility().GetRoom().GetAdjacentGhostCreatingStaffSlots();
}

//---------------------------------------------------------------------------------------
function bool HasOpenAdjacentStaffSlots(StaffUnitInfo UnitInfo)
{
	if (Facility.ObjectID == 0)
		return GetRoom().HasOpenAdjacentStaffSlots(UnitInfo);
	else
		return GetFacility().GetRoom().HasOpenAdjacentStaffSlots(UnitInfo);
}

//---------------------------------------------------------------------------------------
function bool HasAvailableAdjacentGhosts()
{
	if (Facility.ObjectID == 0)
		return GetRoom().HasAvailableAdjacentGhosts();
	else
		return GetFacility().GetRoom().HasAvailableAdjacentGhosts();
}

//---------------------------------------------------------------------------------------
// Get any adjacent staff slots which are filled with ghosts created by this staff slot
function array<XComGameState_StaffSlot> GetAdjacentGhostFilledStaffSlots()
{
	local array<XComGameState_StaffSlot> GhostFilledStaffSlots;
	
	// Check that this slot creates ghosts and is filled
	if (GetMyTemplate().CreatesGhosts && IsSlotFilled())
	{
		if (Facility.ObjectID == 0)
			GhostFilledStaffSlots = GetRoom().GetAdjacentGhostFilledStaffSlots(GetAssignedStaffRef());
		else
			GhostFilledStaffSlots = GetFacility().GetRoom().GetAdjacentGhostFilledStaffSlots(GetAssignedStaffRef());
	}

	return GhostFilledStaffSlots;
}

//---------------------------------------------------------------------------------------
function bool IsSlotEmpty()
{
	return (!IsSlotFilled());
}

//---------------------------------------------------------------------------------------
function XComGameState_Unit GetAssignedStaff()
{
	if (IsSlotFilled())
	{
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AssignedStaff.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function StateObjectReference GetAssignedStaffRef()
{
	return AssignedStaff;
}

//---------------------------------------------------------------------------------------
// This function assumes that all validation on whether the unit can actually be placed
// into this staff slot (ValidUnitForSlot) has already been completed!
// 
function bool FillSlot(XComGameState NewGameState, StaffUnitInfo UnitInfo)
{
	EmptySlot(NewGameState);

	if(GetMyTemplate() != none && GetMyTemplate().FillFn != none)
	{
		GetMyTemplate().FillFn(NewGameState, self.GetReference(), UnitInfo);

		`XEVENTMGR.TriggerEvent('StaffUpdated', self, self, NewGameState);
		
		return true;
	}
	else
	{
		`RedScreen("StaffSlot Template," @ string(GetMyTemplateName()) $ ", has no FillFn.");
		return false;
	}
}

//---------------------------------------------------------------------------------------
function EmptySlot(XComGameState NewGameState)
{
	if(IsSlotFilled())
	{
		`XEVENTMGR.TriggerEvent('StaffUpdated', self, self, NewGameState);

		if(GetMyTemplate().EmptyFn != none)
		{
			GetMyTemplate().EmptyFn(NewGameState, self.GetReference());			
		}
		else
		{
			`RedScreen("StaffSlot Template," @ string(GetMyTemplateName()) $ ", has no EmptyFn.");
		}
	}
}

//---------------------------------------------------------------------------------------
function EmptySlotStopProject()
{
	if (IsSlotFilled())
	{
		`XEVENTMGR.TriggerEvent('StaffUpdated', self, self, none);

		if (GetMyTemplate().EmptyStopProjectFn != none)
		{
			GetMyTemplate().EmptyStopProjectFn(self.GetReference());
		}
		else
		{
			`RedScreen("StaffSlot Template," @ string(GetMyTemplateName()) $ ", has no EmptyStopProjectFn.");
		}
	}
}

//#############################################################################################
//----------------   DISPLAY   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool ShouldDisplayToDoWarning()
{
	if (GetMyTemplate().ShouldDisplayToDoWarningFn != none)
	{
		return GetMyTemplate().ShouldDisplayToDoWarningFn(self.GetReference());
	}

	return true;
}

//---------------------------------------------------------------------------------------
function string GetNameDisplayString()
{
	if(GetMyTemplate().GetNameDisplayStringFn != none)
	{
		return GetMyTemplate().GetNameDisplayStringFn(self);
	}

	return "MISSING DISPLAY INFO";
}

//---------------------------------------------------------------------------------------
function string GetSkillDisplayString()
{
	if (GetMyTemplate().GetSkillDisplayStringFn != none)
	{
		return GetMyTemplate().GetSkillDisplayStringFn(self);
	}

	return "MISSING DISPLAY INFO";
}

//---------------------------------------------------------------------------------------
function string GetBonusDisplayString(optional bool bPreview)
{
	if (GetMyTemplate().GetBonusDisplayStringFn != none)
	{
		return GetMyTemplate().GetBonusDisplayStringFn(self, bPreview);
	}

	return "MISSING BONUS DISPLAY INFO";
}

//---------------------------------------------------------------------------------------
function string GetLocationDisplayString()
{
	if (GetMyTemplate().GetLocationDisplayStringFn != None)
	{
		return GetMyTemplate().GetLocationDisplayStringFn(self);
	}

	return "MISSING DISPLAY INFO";
}

//#############################################################################################
//----------------   TYPE   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool IsHidden()
{
	return GetMyTemplate().bHideStaffSlot;
}

//---------------------------------------------------------------------------------------
function bool IsEngineerSlot()
{
	return GetMyTemplate().bEngineerSlot;
}

//---------------------------------------------------------------------------------------
function bool IsScientistSlot()
{
	return GetMyTemplate().bScientistSlot;
}

//---------------------------------------------------------------------------------------
function bool IsSoldierSlot()
{
	return GetMyTemplate().bSoldierSlot;
}

//#############################################################################################
//----------------   HELPERS   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacility()
{
	local StateObjectReference EmptyRef;

	if (Facility != EmptyRef)
	{
		return XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facility.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersRoom GetRoom()
{
	local StateObjectReference EmptyRef;

	if (Room != EmptyRef)
	{
		return XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Room.ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}