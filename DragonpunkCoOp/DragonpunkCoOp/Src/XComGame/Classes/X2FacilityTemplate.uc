//---------------------------------------------------------------------------------------
//  FILE:    X2FacilityTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2FacilityTemplate extends X2StrategyElementTemplate dependson(XGNarrative);

var(Display) config int				PointsToComplete;
var(Display) config int				iPower;
var(Display) config int				ScienceBonus;			// the bonus to science score provided by this facility
var(Display) config int				EngineeringBonus;		// the bonus to engineering score provided by this facility
var(Display) config int				CommCapacity;			// the number of additional resistance comms this facility allows
var(Display) config int				InterceptionBonus;		// the percent decrease to UFO interception provided by this facility
var(Display) int					StaffingXP;				// XP granted to a staffer of this facility (when working on project)
var(Display) config int				UpkeepCost;
var(Display) bool					bIsCoreFacility;
var(Display) bool					bIsUniqueFacility;
var(Display) bool					bIsIndestructible;
var(Display) bool					bPriority;
var(Display) array<Name>			StaffSlots;
var(Display) int					StaffSlotsLocked;		// Number of staff slots locked by default for the facility
var(Display) bool					bHideStaffSlots;		// Should the staff slots for this facility be hidden from the player (ex: research, engineering)
var(Display) bool					bHideStaffSlotOpenPopup; // Should this facility not display a StaffSlotOpen popup immediately upon completion
var(Display) array<Name>			FillerSlots;            // Array containing the template names of unit types to populate the facility. when the avenger ispopulated this list will be used to choose the types and numbers of filler units to spawn
var(Display) array<Name>			MatineeSlotsForUpgrades;// This array contains the names of matinee slots that can only be used if the facility is upgraded
var(Display) array<Name>			Upgrades;
var(Display) array<name>            SoldierUnlockTemplates;            // ability unlocks that can be purchased from this facility

var(Display) int					ForcedMapIndex;
var(Display) string					MapName;
var(Display) string					AnimMapName;
var(Display) array<AuxMapInfo>      AuxMaps;
var(Display) string					FlyInMapName;
var(Display) name					FlyInRemoteEvent;
var(Display) string					strImage;						 //  image associated with this ability for popups

// Sounds
var(Display) string					NeedsAttentionNarrative;
var(Display) string					FacilityEnteredAkEvent;
var(Display) string					FacilityCompleteNarrative;
var(Display) string					FacilityUpgradedNarrative;
var(Display) string					ConstructionStartedNarrative;

// UI
var(Display) name					UIFacilityGridID;		  //Flash asset library ID
var(Display) bool					UIFacilityGridAlignRight; //Flash asset library setting
var(Display) bool					UIFacilityGridAlignCenter;//Flash asset library setting
var(Display) class<UIFacility>		UIFacilityClass;			// UI class for this facility

// Requirements and Cost
var config StrategyRequirement		Requirements;
var config StrategyCost				Cost;

// Avenger population control
var (Display) int BaseMinFillerCrew;
var (Display) int MinFillerCrew;
var (Display) int MaxFillerCrew;

// Text
var localized string				DisplayName;
var localized string				CompletedSummary;
var localized string				Summary;
var localized string				CantBeRemovedText;

var (Display) Delegate<SelectFacilityDelegate> SelectFacilityFn;
var (Display) Delegate<LeaveFacilityInterruptDelegate> OnLeaveFacilityInterruptFn;
var (Display) Delegate<OnFacilityBuiltDelegate> OnFacilityBuiltFn;
var (Display) Delegate<OnFacilityRemovedDelegate> OnFacilityRemovedFn;
var (Display) Delegate<CanFacilityBeRemovedDelegate> CanFacilityBeRemovedFn;
var (Display) Delegate<GetFacilityInherentValue> GetFacilityInherentValueFn;
var (Display) Delegate<CalculateStaffingRequirement> CalculateStaffingRequirementFn; // Warning: can't be used to lower staff requirement to lower than template value
var (Display) Delegate<IsFacilityProjectActive> IsFacilityProjectActiveFn; // Is this facility running a timed project
var (Display) Delegate<GetQueueMessage> GetQueueMessageFn; // What is the current status of the facility
var (Display) Delegate<NeedsAttentionDelegate> NeedsAttentionFn;
var (Display) Delegate<UpdateFacilityPropsDelegate> UpdateFacilityPropsFn;

delegate SelectFacilityDelegate(StateObjectReference FacilityRef, optional bool bForceInstant = false);
delegate OnFacilityBuiltDelegate(StateObjectReference FacilityRef);
delegate OnFacilityRemovedDelegate(StateObjectReference FacilityRef);
delegate bool CanFacilityBeRemovedDelegate(StateObjectReference FacilityRef);
delegate int GetFacilityInherentValue(StateObjectReference FacilityRef);
delegate CalculateStaffingRequirement(X2FacilityTemplate FacilityTemplate, out int RequiredScience, out int RequiredEngineering);
delegate LeaveFacilityInterruptDelegate(StateObjectReference FacilityRef);
delegate bool IsFacilityProjectActive(StateObjectReference FacilityRef);
delegate string GetQueueMessage(StateObjectReference FacilityRef);
delegate bool NeedsAttentionDelegate(StateObjectReference FacilityRef);
delegate UpdateFacilityPropsDelegate(StateObjectReference FacilityRef, XGBase Base);


//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_FacilityXCom FacilityState;

	FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom'));
	FacilityState.OnCreation(self, NewGameState);

	return FacilityState;
}

function bool ValidateTemplate(out string strError)
{
	local name AbilityUnlock;
	local X2StrategyElementTemplateManager Manager;

	Manager = GetMyTemplateManager();
	foreach SoldierUnlockTemplates(AbilityUnlock)
	{
		if (Manager.FindStrategyElementTemplate(AbilityUnlock) == none)
		{
			strError = "SoldierUnlockTemplates references invalid template" @ AbilityUnlock;
			return false;
		}
	}
	return super.ValidateTemplate(strError);
}

function int GetMaxCrewOfTemplate(name TemplateName)
{
	local int MaxCrew;
	local name TheTmpl;

	MaxCrew = 0;
	foreach FillerSlots(TheTmpl)
	{
		if (TheTmpl == TemplateName)
		{
			++MaxCrew;
		}
	}

	return MaxCrew;
}

function PopulateImportantFacilityCrew(XGBaseCrewMgr Mgr, StateObjectReference FacilityRef);

function bool PlaceCrewMember(XGBaseCrewMgr Mgr, StateObjectReference FacilityRef, StateObjectReference CrewMemberRef, bool bStaffSlot)
{
	local int RoomIdx;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_Unit Unit;
	local vector RoomOffset;
	local int NumStaffSlots;

	History = `XCOMHISTORY;

	Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	RoomIdx = Facility.GetRoom().MapIndex;

	if(Mgr.IsAlreadyPlaced(CrewMemberRef))
	{
		return true;
	}	

	RoomOffset = Facility.GetRoom().GetLocation();
	NumStaffSlots = StaffSlots.Length;

	Unit = XComGameState_Unit(History.GetGameStateForObjectID(CrewMemberRef.ObjectID));
	if(Unit.CanAppearInBase())
	{
			if(Unit.GetMyTemplateName() == 'Soldier')
			{	
				if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Soldier", RoomOffset, bStaffSlot))
				{
					return true;
				}				
				else if(Mgr.CurrentGrievers < Mgr.MaxGrievers && Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Griever", RoomOffset, bStaffSlot))
				{
					++Mgr.CurrentGrievers;
					return true;
				}
				else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Any", RoomOffset, bStaffSlot))
				{
					return true;
				}
				else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Drinker", RoomOffset, bStaffSlot))
				{
					return true;
				}								
			}
			else if(Unit.GetMyTemplateName() == 'Engineer' && NumStaffSlots == 0) //Engineers cannot be filler in any room with staff slots ( confusing, visually )
			{
				if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Engineer", RoomOffset, bStaffSlot))
				{
					return true;
				}
				else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Crew", RoomOffset, bStaffSlot))
				{
					return true;
				}
				else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Any", RoomOffset, bStaffSlot))
				{
					return true;
				}
			}
			else if(Unit.GetMyTemplateName() == 'Scientist' && NumStaffSlots == 0)
			{
				if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Scientist", RoomOffset, bStaffSlot))
				{
					return true;
				}
				else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Crew", RoomOffset, bStaffSlot))
				{
					return true;
				}
				else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Any", RoomOffset, bStaffSlot))
				{
					return true;
				}
			}
		else if(Unit.GetMyTemplateName() == 'Clerk') //Clerks can fit in any slot
		{
			if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Engineer", RoomOffset, bStaffSlot))
			{
				return true;
			}
			else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Scientist", RoomOffset, bStaffSlot))
			{
				return true;
			}
			else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Crew", RoomOffset, bStaffSlot))
			{
				return true;
			}
			else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Any", RoomOffset, bStaffSlot))
			{
				return true;
			}
		}
		else if(Unit.GetMyTemplateName() == 'StrategyCentral') //Bradford can go anywhere soldiers can, and also counts as crew
		{			
			if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Crew", RoomOffset, bStaffSlot))
			{
				return true;
			}
			else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Soldier", RoomOffset, bStaffSlot))
			{
				return true;
			}
			else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Drinker", RoomOffset, bStaffSlot))
			{
				return true;
			}
			else if(Mgr.CurrentGrievers < Mgr.MaxGrievers && Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Griever", RoomOffset, bStaffSlot))
			{
				++Mgr.CurrentGrievers;
				return true;
			}
			else if(Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Any", RoomOffset, bStaffSlot))
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	BaseMinFillerCrew = 0;
	MinFillerCrew = 0;
	MaxFillerCrew = 3;
	bShouldCreateDifficultyVariants = true
}
