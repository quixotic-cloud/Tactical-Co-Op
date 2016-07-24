//---------------------------------------------------------------------------------------
//  FILE:    X2StaffSlotTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StaffSlotTemplate extends X2StrategyElementTemplate;

// Data
var (Display) bool					bHideStaffSlot; // Do not show this staff slot on the facility screen
var (Display) bool					bRequireConfirmToEmpty; // Flag to require confirmation from the player before emptying this slot
var (Display) bool					bScientistSlot;
var (Display) bool					bEngineerSlot;
var (Display) bool					bSoldierSlot;
var (Display) bool					CreatesGhosts; // Does this staff slot create ghost units
var (Display) class<XComGameState_HeadquartersProject> AssociatedProjectClass; // Headquarters Project class associated with this staff slot, used for displaying time previews
var (Display) array<name>			ExcludeClasses; // List of soldier classes which are not allowed in this staff slot
var (Display) string				MatineeSlotName; // used with avenger crew population matinee's to pick an appropriate matinee seqvar to assign staff too

// Text
var localized string	EmptyText;
var localized string	BonusText;
var localized string	BonusDefaultText;			// Used by staff slots which don't rely on a numeric bonus to have a default yet potentially dynamic string
var localized string	BonusEmptyText;
var localized string	FilledText;
var localized string	GhostName;					// If this staff slot can provide ghost units, this is what they will be called
var localized string	LockedText;

// Functions
var (Display) delegate<Fill> FillFn; // Call to fill the slot
var (Display) delegate<Empty> EmptyFn; // Call to empty the slot
var (Display) delegate<EmptyStopProject> EmptyStopProjectFn; // Call to empty the slot through stopping the associated headquarters project
var (Display) delegate<CanStaffBeMovedDelegate> CanStaffBeMovedFn;
var (Display) delegate<ShouldDisplayToDoWarning> ShouldDisplayToDoWarningFn;
var (Display) delegate<GetContributionFromSkill> GetContributionFromSkillFn; // Call to get the unit's numeric contribution for the specific staff slot
var (Display) delegate<GetAvengerBonusAmount> GetAvengerBonusAmountFn; // Call to get the value of the bonus this unit's staffing provides to the avenger - unique and different for each staff slot
var (Display) delegate<GetNameDisplayString> GetNameDisplayStringFn; // Call to get display name as text
var (Display) delegate<GetSkillDisplayString> GetSkillDisplayStringFn; // Call to get display skill as text
var (Display) delegate<GetBonusDisplayString> GetBonusDisplayStringFn; // Call to get staffing bonus as text
var (Display) delegate<GetLocationDisplayString> GetLocationDisplayStringFn; // Call to get the location of the staff slot
var (Display) delegate<IsUnitValidForSlot> IsUnitValidForSlotFn; // Is the unit allowed to be placed in this staff slot
var (Display) delegate<IsStaffSlotBusy> IsStaffSlotBusyFn; // Is the unit in this slot busy contributing to a project or task. Used for reassigning staffers.

delegate Fill(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo);
delegate Empty(XComGameState NewGameState, StateObjectReference SlotRef);
delegate EmptyStopProject(StateObjectReference SlotRef);
delegate bool CanStaffBeMovedDelegate(StateObjectReference SlotRef);
delegate bool ShouldDisplayToDoWarning(StateObjectReference SlotRef);
delegate int GetContributionFromSkill(XComGameState_Unit UnitState);
delegate int GetAvengerBonusAmount(XComGameState_Unit UnitState, optional bool bPreview);
delegate string GetNameDisplayString(XComGameState_StaffSlot SlotState);
delegate string GetSkillDisplayString(XComGameState_StaffSlot SlotState);
delegate string GetBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview);
delegate string GetLocationDisplayString(XComGameState_StaffSlot SlotState);
delegate bool IsUnitValidForSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo);
delegate bool IsStaffSlotBusy(XComGameState_StaffSlot SlotState);

//---------------------------------------------------------------------------------------
function XComGameState_StaffSlot CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_StaffSlot SlotState;

	SlotState = XComGameState_StaffSlot(NewGameState.CreateStateObject(class'XComGameState_StaffSlot'));
	SlotState.OnCreation(self);

	return SlotState;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}