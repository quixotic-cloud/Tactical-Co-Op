//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_FacilityXCom.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for an X-Com facility
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_FacilityXCom extends XComGameState_BaseObject native(Core) dependson(XGTacticalScreenMgr);

var() protected name                   m_TemplateName;
var() protected X2FacilityTemplate     m_Template;

var() StateObjectReference Room;        //The room this facility occupies
var() array<StateObjectReference> StaffSlots; //List of slots that staff can be assigned to
var() array<StateObjectReference> BuildQueue; // Item Project References
var() array<StateObjectReference> Upgrades;
var() array<StateObjectReference> HiddenUpgrades; // Upgrades which are hidden from the player. Used for visual changes only.
var() TDateTime ConstructionDateTime;
var() StateObjectReference Builder;  // Unit that built the room
var() bool bPlayFlyIn;
var() private bool bNeedsAttention;

var() bool bTutorialLocked; // room is locked due to tutorial state

// Upgrade Vars
var() int PowerOutput;
var() bool DistributedPower;
var() int DistributedPowerPercent;
var() int RefundPercent;
var() int CommCapacity;
var() int InterceptionBonus;
var() int UpkeepCost;

delegate LeaveFacilityInterruptCallback(bool bContinueNavigation);

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
simulated function X2FacilityTemplate GetMyTemplate()
{
	if (m_Template == none)
	{
		m_Template = X2FacilityTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
function OnCreation(X2FacilityTemplate Template, XComGameState NewGameState)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
	PowerOutput = GetMyTemplate().iPower;
	CommCapacity = GetMyTemplate().CommCapacity;
	InterceptionBonus = GetMyTemplate().InterceptionBonus;
	UpkeepCost = GetMyTemplate().UpkeepCost;
	CreateStaffSlots(NewGameState);
}

//---------------------------------------------------------------------------------------
function CreateStaffSlots(XComGameState NewGameState)
{
	local X2StaffSlotTemplate StaffSlotTemplate;
	local XComGameState_StaffSlot StaffSlotState;
	local int i, LockThreshold;
	
	StaffSlots.Length = 0;

	LockThreshold = GetMyTemplate().StaffSlots.Length - GetMyTemplate().StaffSlotsLocked;

	for (i = 0; i < GetMyTemplate().StaffSlots.Length; i++)
	{
		StaffSlotTemplate = X2StaffSlotTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(GetMyTemplate().StaffSlots[i]));

		if (StaffSlotTemplate != none)
		{
			StaffSlotState = StaffSlotTemplate.CreateInstanceFromTemplate(NewGameState);
			StaffSlotState.Facility = GetReference(); //make sure the staff slot knows what facility it is in
			if (i >= LockThreshold)
			{
				StaffSlotState.LockSlot();
			}
			
			NewGameState.AddStateObject(StaffSlotState);

			StaffSlots.AddItem(StaffSlotState.GetReference());
		}
	}
}

//---------------------------------------------------------------------------------------
function UnlockStaffSlot(XComGameState NewGameState)
{
	local XComGameState_StaffSlot StaffSlotState;
	local int i;

	for (i = 0; i < StaffSlots.Length; i++)
	{
		StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlots[i].ObjectID));
		if (StaffSlotState.IsLocked())
		{
			StaffSlotState = XComGameState_StaffSlot(NewGameState.CreateStateObject(class'XComGameState_StaffSlot', StaffSlots[i].ObjectID));
			StaffSlotState.UnlockSlot();
			NewGameState.AddStateObject(StaffSlotState);
			return;
		}
	}	
}

//#############################################################################################
//----------------   POWER   ------------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetPowerOutput()
{
	if (IsUnderConstruction() && PowerOutput > 0)
	{
		return 0; // Facilities which produce power do not grant it until construction is completed
	}

	if (BuiltOnPowerCell())
	{
		// If a power generator is built on a power cell, double its output
		if (PowerOutput > 0)
		{
			return (PowerOutput + class'UIUtilities_Strategy'.static.GetXComHQ().PowerRelayOnCoilBonus[`DIFFICULTYSETTING]);
		}
		else // Otherwise any other facility costs no power
		{
			return 0;
		}
	}

	// Most facilities will return negative number, power core returns positive value
	return PowerOutput;
}

//---------------------------------------------------------------------------------------
function bool BuiltOnPowerCell()
{
	if(Room.ObjectID > 0)
	{
		if(GetRoom().HasShieldedPowerCoil())
		{
			return true;
		}
	}

	return false;
}

//#############################################################################################
//----------------   FACILITY STATUS   --------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool FacilityHasActiveProjects()
{
	if (GetMyTemplate().IsFacilityProjectActiveFn != None)
	{
		return GetMyTemplate().IsFacilityProjectActiveFn(self.GetReference());
	}
}

//---------------------------------------------------------------------------------------
function TriggerNeedsAttention(optional bool bPlayNarrImmediately = true)
{
	bNeedsAttention = true;
	`GAME.GetGeoscape().m_kBase.m_kAmbientVOMgr.TriggerNeedAttentionVO(GetReference(), bPlayNarrImmediately);
}

//---------------------------------------------------------------------------------------
function ClearNeedsAttention()
{
	`GAME.GetGeoscape().m_kBase.m_kAmbientVOMgr.ClearNeedAttentionVO(GetReference());
	bNeedsAttention = false;
}

//---------------------------------------------------------------------------------------
function bool NeedsAttention()
{
	return (bNeedsAttention || (GetMyTemplate().NeedsAttentionFn != none && GetMyTemplate().NeedsAttentionFn(GetReference()))) ;
}


simulated function string GetQueueMessage()
{
	if (GetMyTemplate().GetQueueMessageFn != None)
	{
		return GetMyTemplate().GetQueueMessageFn(self.GetReference());
	}
	return "";
}

simulated function string GetStatusMessage( optional bool bIncludeLabel = true )
{
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;
	local string strStatus;

	strStatus = ""; 

	if(IsUnderConstruction())
	{
		strStatus = class'UIFacilitySummary_ListItem'.default.m_strUnderConstructionLabel;
	}
	else
	{
		UpgradeProject = class'UIUtilities_Strategy'.static.GetUpgradeProject(GetReference());

		if(UpgradeProject != none)
		{
			if(bIncludeLabel)
				strStatus = class'UIFacilityUpgrade'.default.FacilityStatus_UpgradeLabel $": ";

			strStatus $= class'UIUtilities_Text'.static.GetTimeRemainingString(UpgradeProject.GetCurrentNumHoursRemaining());
		}
	}

	return strStatus;
}

//#############################################################################################
//----------------   STAFFING   ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool IsStaffedHere(StateObjectReference UnitRef)
{
	local int i;
	for(i = 0; i < StaffSlots.Length; ++i)
	{
		if (GetStaffSlot(i).GetAssignedStaffRef() == UnitRef)
			return true;		
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool HasStaff()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for(i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function int GetNumEmptyStaffSlots()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i, openStaffSlots;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty())
			openStaffSlots++;
	}
	return openStaffSlots;
}

//---------------------------------------------------------------------------------------
function int GetNumFilledStaffSlots()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i, assignedStaff;

	for(i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
			assignedStaff++;
	}
	return assignedStaff;
}

//---------------------------------------------------------------------------------------
function int GetNumLockedStaffSlots()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i, lockedSlots;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.IsLocked())
			lockedSlots++;
	}
	return lockedSlots;
}

//---------------------------------------------------------------------------------------
function int GetEmptyStaffSlotIndex()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty())
			return i;
	}
	return -1;
}

//---------------------------------------------------------------------------------------
function int GetEmptyEngStaffSlotIndex()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty() && StaffSlot.IsEngineerSlot())
			return i;
	}
	return -1;
}

//---------------------------------------------------------------------------------------
function int GetEmptySciStaffSlotIndex()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty() && StaffSlot.IsScientistSlot())
			return i;
	}
	return -1;
}

//---------------------------------------------------------------------------------------
function int GetEmptySoldierStaffSlotIndex()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty() && StaffSlot.IsSoldierSlot())
			return i;
	}
	return -1;
}

//---------------------------------------------------------------------------------------
function int GetLockedStaffSlotIndex()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.IsLocked())
			return i;
	}
	return -1;
}

//---------------------------------------------------------------------------------------
// Returns the index of this build slot out of the group of slots which are filled.
// Used for displaying different values in build slot bonus strings in the same room
function int GetReverseOrderAmongFilledStaffSlots(XComGameState_StaffSlot SlotState, bool bPreview)
{
	local XComGameState_StaffSlot StaffSlot;
	local int i, iOrder, NumFilledStaffSlots;

	NumFilledStaffSlots = GetNumFilledStaffSlots();
	iOrder = NumFilledStaffSlots;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);

		if (StaffSlot.IsSlotFilled())
			iOrder--;

		if (StaffSlot.ObjectID == SlotState.ObjectID)
		{
			if (bPreview)
			{
				iOrder--; // Assuming that this slot is filled, so decrease the order
			}

			return iOrder;
		}
	}
	return -1;
}

//---------------------------------------------------------------------------------------
function EmptyAllStaffSlots(XComGameState NewGameState)
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			StaffSlot.EmptySlot(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
function bool IsEngineeringCategory()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for( i = 0; i < StaffSlots.Length; ++i )
	{
		StaffSlot = GetStaffSlot(i);
		if( StaffSlot.IsEngineerSlot() )
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool IsScienceCategory()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for( i = 0; i < StaffSlots.Length; ++i )
	{
		StaffSlot = GetStaffSlot(i);
		if( StaffSlot.IsScientistSlot() )
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool IsSoldierCategory()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for( i = 0; i < StaffSlots.Length; ++i )
	{
		StaffSlot = GetStaffSlot(i);
		if( StaffSlot.IsSoldierSlot() )
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool HasEmptyEngineerSlot()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty() && StaffSlot.IsEngineerSlot())
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool HasEmptyScientistSlot()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty() && StaffSlot.IsScientistSlot())
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool HasEmptySoldierSlot()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty() && StaffSlot.IsSoldierSlot())
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool HasFilledEngineerSlot()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotFilled() && StaffSlot.IsEngineerSlot())
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool HasFilledScientistSlot()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotFilled() && StaffSlot.IsScientistSlot())
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
function bool HasFilledSoldierSlot()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSlotFilled() && StaffSlot.IsSoldierSlot())
			return true;
	}
	return false;
}

function bool DisplayStaffingInfo()
{
	return (!GetMyTemplate().bHideStaffSlots);
}

//---------------------------------------------------------------------------------------
function GetScientistSlots(out int iStaffed, out int iEmpty, optional bool bIncludeHidden)
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for( i = 0; i < StaffSlots.Length; ++i )
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsScientistSlot() && (bIncludeHidden || !StaffSlot.IsHidden()))
		{
			if( StaffSlot.IsSlotFilled() )
				iStaffed++;
			else
				iEmpty++;
		}
	}
}
//---------------------------------------------------------------------------------------
function GetEngineerSlots(out int iStaffed, out int iEmpty, optional bool bIncludeHidden)
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for( i = 0; i < StaffSlots.Length; ++i )
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsEngineerSlot() && (bIncludeHidden || !StaffSlot.IsHidden()))
		{
			if( StaffSlot.IsSlotFilled() )
				iStaffed++;
			else
				iEmpty++;
		}
	}
}

//---------------------------------------------------------------------------------------
function GetSoldierSlots(out int iStaffed, out int iEmpty, optional bool bIncludeHidden)
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for( i = 0; i < StaffSlots.Length; ++i )
	{
		StaffSlot = GetStaffSlot(i);
		if (!StaffSlot.IsLocked() && StaffSlot.IsSoldierSlot() && (bIncludeHidden || !StaffSlot.IsHidden()))
		{
			if( StaffSlot.IsSlotFilled() )
				iStaffed++;
			else
				iEmpty++;
		}
	}
}

//---------------------------------------------------------------------------------------
function bool HasIdleStaff()
{	
	if (HasStaff() && GetMyTemplate().IsFacilityProjectActiveFn != None)
	{
		return !GetMyTemplate().IsFacilityProjectActiveFn(self.GetReference());
	}

	return false;
}

//---------------------------------------------------------------------------------------
function int GetIdleStaffSlotIndex()
{
	local XComGameState_StaffSlot StaffSlot;
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		StaffSlot = GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled() && !StaffSlot.IsStaffSlotBusy())
		{
			return i;
		}
	}
	return -1;
}

//#############################################################################################
//----------------   UPGRADES   ---------------------------------------------------------------
//#############################################################################################

function bool CanUpgrade()
{
	local array<X2FacilityUpgradeTemplate> UpgradeTemplates;

	if( GetRoom().UnderConstruction || IsBuildingUpgrade() )
	{
		return false;
	}
	else
	{
		UpgradeTemplates = GetBuildableUpgrades();
		return UpgradeTemplates.Length > 0;
	}
}

function bool IsBuildingUpgrade()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;
	local int i;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for (i = 0; i < XComHQ.Projects.Length; ++i)
	{
		UpgradeProject = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[i].ObjectID));
		if (UpgradeProject != None && UpgradeProject.AuxilaryReference == GetReference())
		{
			return true;
		}
	}

	return false;
}

function bool HasUpgrade(name DataName)
{
	local StateObjectReference UpgradeRef;
	local XComGameState_FacilityUpgrade Upgrade;

	foreach Upgrades(UpgradeRef)
	{
		Upgrade = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(UpgradeRef.ObjectID));
		if (Upgrade != none && Upgrade.GetMyTemplateName() == DataName)
		{
			return true;
		}
	}

	foreach HiddenUpgrades(UpgradeRef)
	{
		Upgrade = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(UpgradeRef.ObjectID));
		if (Upgrade != none && Upgrade.GetMyTemplateName() == DataName)
		{
			return true;
		}
	}

	return false;
}

function bool HasBeenUpgraded()
{
	return (Upgrades.Length > 0);
}

//---------------------------------------------------------------------------------------
function array<X2FacilityUpgradeTemplate> GetBuildableUpgrades()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local XComGameState_FacilityUpgrade UpgradeState;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;
	local array<X2FacilityUpgradeTemplate> UpgradeTemplates;
	local int i, j, k, Count;
	local bool CanBuild;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	UpgradeTemplates.Length = 0;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// First check that the upgrade has been unlocked and that it's not already under construction
	for(i = 0; i < GetMyTemplate().Upgrades.Length; i++)
	{
		UpgradeTemplate = X2FacilityUpgradeTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(GetMyTemplate().Upgrades[i]));

		if(UpgradeTemplate != none)
		{
			CanBuild = true;

			if (UpgradeTemplate.bHidden)
			{
				CanBuild = false;
			}

			if(!XComHQ.MeetsEnoughRequirementsToBeVisible(UpgradeTemplate.Requirements))
			{
				CanBuild = false;
			}

			for(k = 0; k < XComHQ.Projects.Length; ++k)
			{
				UpgradeProject = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[k].ObjectID));
				if(UpgradeProject != None && UpgradeProject.AuxilaryReference == GetReference())
				{
					UpgradeState = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(UpgradeProject.ProjectFocus.ObjectID));
					if(UpgradeState.GetMyTemplateName() == UpgradeTemplate.DataName)
						CanBuild = false;
				}
			}

			if(CanBuild)
			{
				UpgradeTemplates.AddItem(UpgradeTemplate);
			}
		}
	}

	// Check if you have under the max number of the upgrade
	for(i = 0; i < UpgradeTemplates.Length; i++)
	{
		Count = 0;

		for(j = 0; j < Upgrades.Length; j++)
		{
			UpgradeState = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(Upgrades[j].ObjectID));

			if(UpgradeState != none)
			{
				if(UpgradeState.GetMyTemplateName() == UpgradeTemplates[i].DataName)
				{
					Count++;
				}
			}
		}

		if(Count >= UpgradeTemplates[i].MaxBuild)
		{
			UpgradeTemplates.Remove(i, 1);
			i--;
		}
	}

	return UpgradeTemplates;
}

//#############################################################################################
//------------------   REMOVE FACILITY  -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool CanRemove()
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlot;
	local X2FacilityTemplate FacilityTemplate;
	local StateObjectReference StaffSlotRef;
	local bool bCanRemove;

	History = `XCOMHISTORY;
	FacilityTemplate = GetMyTemplate();

	bCanRemove = !FacilityTemplate.bIsCoreFacility && !FacilityTemplate.bIsIndestructible && !GetRoom().UnderConstruction;

	if (GetMyTemplate().CanFacilityBeRemovedFn != none)
	{
		bCanRemove = (bCanRemove && GetMyTemplate().CanFacilityBeRemovedFn(self.GetReference()));
	}

	if (bCanRemove)
	{
		foreach StaffSlots(StaffSlotRef)
		{
			StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID));
			if (!StaffSlot.CanStaffBeMoved())
			{
				// If the staff slot is providing a critical Avenger function, the facility cannot be deleted
				bCanRemove = false;
				break;
			}
		}
	}

	return bCanRemove;
}

//---------------------------------------------------------------------------------------
function RemoveEntity()
{
	if (GetMyTemplate().OnFacilityRemovedFn != none)
	{
		GetMyTemplate().OnFacilityRemovedFn(self.GetReference());
	}
	else
	{
		`RedScreen("Facility Template," @ string(GetMyTemplateName()) $ ", has no OnFacilityRemovedFn.");
	}
}

//#############################################################################################
//----------------   HELPER FUNCTIONS   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool IsUnderConstruction()
{
	return (Room.ObjectID == 0);
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersRoom GetRoom()
{
	return XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Room.ObjectID));
}

//---------------------------------------------------------------------------------------
function XComGameState_StaffSlot GetStaffSlot(int i)
{
	if (i >= 0 && i < StaffSlots.Length)
	{
		return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlots[i].ObjectID));
	}
	else
		return None;
}

//---------------------------------------------------------------------------------------
function XComGameState_StaffSlot GetStaffSlotByTemplate(name TemplateName)
{
	local XComGameState_StaffSlot SlotState;
	local int idx;

	for (idx = 0; idx < StaffSlots.Length; idx++)
	{
		SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlots[idx].ObjectID));
		if (SlotState.GetMyTemplateName() == TemplateName)
		{
			return SlotState;
		}
	}
	
	return None;
}

DefaultProperties
{
}
