//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultStaffSlots.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultStaffSlots extends X2StrategyElement;

//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> StaffSlots;

	StaffSlots.AddItem(CreateBuildStaffSlotTemplate());
	StaffSlots.AddItem(CreateEngineeringStaffSlotTemplate());
	StaffSlots.AddItem(CreateResearchStaffSlotTemplate());
	StaffSlots.AddItem(CreateWorkshopStaffSlotTemplate());
	StaffSlots.AddItem(CreateLaboratoryStaffSlotTemplate());
	StaffSlots.AddItem(CreateProvingGroundStaffSlotTemplate());
	StaffSlots.AddItem(CreateResCommsStaffSlotTemplate());
	StaffSlots.AddItem(CreateResCommsBetterStaffSlotTemplate());
	StaffSlots.AddItem(CreatePowerRelayStaffSlotTemplate());
	StaffSlots.AddItem(CreatePsiChamberEngineerStaffSlotTemplate());
	StaffSlots.AddItem(CreatePsiChamberSoldierStaffSlotTemplate());
	StaffSlots.AddItem(CreateUFODefenseStaffSlotTemplate());
	StaffSlots.AddItem(CreateOTSStaffSlotTemplate());
	StaffSlots.AddItem(CreateAWCEngineerStaffSlotTemplate());
	StaffSlots.AddItem(CreateAWCSoldierStaffSlotTemplate());
	StaffSlots.AddItem(CreateShadowChamberShenStaffSlotTemplate());
	StaffSlots.AddItem(CreateShadowChamberTyganStaffSlotTemplate());
	
	return StaffSlots;
}

//#############################################################################################
//----------------   ROOM BUILD SLOT   --------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateBuildStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'BuildStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillSlotDefault;
	Template.EmptyFn = EmptySlotDefault;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetBuildSlotAvengerBonus;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetBuildSlotBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetBuildSlotLocationDisplayString;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsBuildSlotBusy;
	Template.MatineeSlotName = "Build";

	return Template;
}

static function int GetBuildSlotAvengerBonus(XComGameState_Unit UnitState, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local float PercentIncrease;
	local int NewWorkPerHour;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	// Need to return the percent increase in overall construction speed provided by this unit
	NewWorkPerHour = GetContributionDefault(UnitState) + XComHQ.XComHeadquarters_DefaultConstructionWorkPerHour;
	PercentIncrease = (GetContributionDefault(UnitState) * 100.0) / NewWorkPerHour;

	return Round(PercentIncrease);
}

static function string GetBuildSlotBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
	local string Contribution;
	local string BonusStr;
	local int SlotOrder, StaffContribution;
	local float PercentIncrease;

	Room = SlotState.GetRoom();
	SlotOrder = Room.GetOrderAmongFilledBuildSlots(SlotState, bPreview);

	if (Room.HasSpecialFeature() && !Room.bSpecialRoomFeatureCleared)
	{
		if (SlotState.IsSlotFilled())
		{
			if (SlotOrder == 1) // If this is the first slot to be filled for this excavation
			{
				if (!Room.ClearingRoom) // If excavation hasn't started, display "Begin Excavation"
				{
					BonusStr = SlotState.GetMyTemplate().BonusEmptyText;
				}
				else if (Room.GetNumFilledBuildSlots() == 0) // If excavation has started, but no engineers are present, display "Resume Excavation"
				{
					BonusStr = class'XGLocalizedData'.default.BuildSlotPausedBonusEmptyText;
				}
				else // Otherwise display "Excavating"
				{
					BonusStr = class'XGBuildUI'.default.m_strLabelExcavating;
				}
			}
			else // All slots other than the first display the numeric speed increase provided
			{
				XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

				StaffContribution = SlotState.GetMyTemplate().GetContributionFromSkillFn(SlotState.GetAssignedStaff());
				PercentIncrease = (StaffContribution * 100) / (SlotOrder * XComHQ.XComHeadquarters_DefaultConstructionWorkPerHour);
				Contribution = string(Round(PercentIncrease));
				BonusStr = SlotState.GetMyTemplate().BonusText;
				BonusStr = Repl(BonusStr, "%AVENGERBONUS", Contribution);
			}
		}
		else
		{
			if (Room.GetNumFilledBuildSlots() == 0 && Room.ClearingRoom)
			{
				BonusStr = class'XGLocalizedData'.default.BuildSlotPausedBonusEmptyText;
			}
			else if (Room.GetNumFilledBuildSlots() > 0)
			{
				BonusStr = class'XGLocalizedData'.default.BuildSlotInProgressBonusEmptyText;
			}
			else
			{
				BonusStr = SlotState.GetMyTemplate().BonusEmptyText;
			}
		}
	}
	else
	{
		if (SlotState.IsSlotFilled())
		{
			Contribution = string(GetBuildSlotAvengerBonus(SlotState.GetAssignedStaff(), bPreview));
			BonusStr = class'XGLocalizedData'.default.ConstructionSlotFilled;
			BonusStr = Repl(BonusStr, "%AVENGERBONUS", Contribution);
		}
		else
		{
			BonusStr = class'XGLocalizedData'.default.ConstructionSlotEmpty;
		}
	}

	return BonusStr;
}

static function string GetBuildSlotLocationDisplayString(XComGameState_StaffSlot SlotState)
{
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local string BuildingString;

	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(SlotState.Room.ObjectID));
	
	if (Room.UnderConstruction)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Room.GetBuildFacilityProject().ProjectFocus.ObjectID));

		BuildingString = class'XGLocalizedData'.default.BuildingStatusLabel;
		BuildingString = Repl(BuildingString, "%FACILITYNAME", Facility.GetMyTemplate().DisplayName);

		return BuildingString;
	}
	else if (Room.ClearingRoom)
	{		
		return Room.GetSpecialFeature().ClearingInProgressText;
	}
	else
	{
		return class'XGLocalizedData'.default.RoomAwaitingExcavationLabel;
	}
}

static function bool IsBuildSlotBusy(XComGameState_StaffSlot SlotState)
{
	return true;
}

//#############################################################################################
//----------------   ENGINEERING   ------------------------------------------------------------
//                    (Unused)
//#############################################################################################

static function X2DataTemplate CreateEngineeringStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'EngineeringStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillSlotDefault;
	Template.EmptyFn = EmptySlotDefault;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetBonusDisplayStringDefault;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "";  // none because tygan and shen are special models and matinees in their respective rooms

	Template.LockedText = "";

	return Template;
}

//#############################################################################################
//----------------   RESEARCH   ---------------------------------------------------------------
//                   (Unused)
//#############################################################################################

static function X2DataTemplate CreateResearchStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'ResearchStaffSlot');
	Template.bScientistSlot = true;
	Template.FillFn = FillSlotDefault;
	Template.EmptyFn = EmptySlotDefault;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetBonusDisplayStringDefault;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "";  // none because tygan and shen are special models and matinees in their respective rooms

	Template.LockedText = "";

	return Template;
}

//#############################################################################################
//----------------   WORKSHOP   ---------------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateWorkshopStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;
	
	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'WorkshopStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillWorkshopSlot;
	Template.EmptyFn = EmptyWorkshopSlot;
	Template.CanStaffBeMovedFn = CanStaffBeMovedWorkshop;
	Template.GetContributionFromSkillFn = GetWorkshopContribution;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetWorkshopBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsWorkshopBusy;
	Template.MatineeSlotName = "Engineer";

	Template.CreatesGhosts = true;
	
	return Template;
}

static function int GetWorkshopContribution(XComGameState_Unit Unit)
{
	return (GetContributionDefault(Unit) - 3);
}

static function FillWorkshopSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;
	
	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);

	// Add special staffing gremlins
	NewSlotState.MaxAdjacentGhostStaff = GetWorkshopContribution(NewUnitState);
	NewSlotState.AvailableGhostStaff = NewSlotState.MaxAdjacentGhostStaff;
}

static function EmptyWorkshopSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;
	
	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);

	// Should never enter this function if special staffing gremlins are still active
	// Set the number of available staffing gremlins to 0
	NewSlotState.MaxAdjacentGhostStaff = 0;
	NewSlotState.AvailableGhostStaff = 0;
}

static function bool CanStaffBeMovedWorkshop(StateObjectReference SlotRef)
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot SlotState;

	History = `XCOMHISTORY;
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));

	if (SlotState.AvailableGhostStaff == SlotState.MaxAdjacentGhostStaff)
		return true;
	else
		return false;
}

static function string GetWorkshopBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		Contribution = string(GetWorkshopContribution(SlotState.GetAssignedStaff()));
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

static function bool IsWorkshopBusy(XComGameState_StaffSlot SlotState)
{
	return (SlotState.AvailableGhostStaff < SlotState.MaxAdjacentGhostStaff);
}

//#############################################################################################
//----------------   LABORATORY   -------------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateLaboratoryStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'LaboratoryStaffSlot');
	Template.bScientistSlot = true;
	Template.FillFn = FillLaboratorySlot;
	Template.EmptyFn = EmptyLaboratorySlot;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetLaboratoryBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Scientist";

	return Template;
}

static function FillLaboratorySlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);

	NewUnitState.SkillLevelBonus = NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function EmptyLaboratorySlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);

	NewUnitState.SkillLevelBonus = 0;
}

static function string GetLaboratoryBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local string Contribution;
	local float PercentIncrease;
	local int UnitSkill, SlotOrder, SciScore;

	FacilityState = SlotState.GetFacility();
	SlotOrder = FacilityState.GetReverseOrderAmongFilledStaffSlots(SlotState, bPreview);

	if (SlotState.IsSlotFilled())
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

		UnitSkill = SlotState.GetMyTemplate().GetContributionFromSkillFn(SlotState.GetAssignedStaff());
		SciScore = XComHQ.GetScienceScore(true);
		SciScore -= SlotOrder * UnitSkill;

		// Need to return the percent increase in overall research speed provided by this unit
		PercentIncrease = (UnitSkill * 100.0) / SciScore;
		Contribution = string(Round(PercentIncrease));
	}

	return GetBonusDisplayString(SlotState, "%AVENGERBONUS", Contribution);
}

//#############################################################################################
//----------------   PROVING GROUND   -------------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateProvingGroundStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'ProvingGroundStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillProvingGroundSlot;
	Template.EmptyFn = EmptyProvingGroundSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayProvingGroundToDoWarning;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetProvingGroundAvengerBonus;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetProvingGroundBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

static function int GetProvingGroundAvengerBonus(XComGameState_Unit Unit, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local float PercentIncrease;
	local int NewWorkPerHour;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Need to return the percent increase in overall project speed provided by this unit
	NewWorkPerHour = GetContributionDefault(Unit) + XComHQ.XComHeadquarters_DefaultProvingGroundWorkPerHour;
	PercentIncrease = (GetContributionDefault(Unit) * 100.0) / NewWorkPerHour;

	return Round(PercentIncrease);
}

static function FillProvingGroundSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);
	
	NewXComHQ.ProvingGroundRate += NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function EmptyProvingGroundSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);
	
	NewXComHQ.ProvingGroundRate -= NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function bool ShouldDisplayProvingGroundToDoWarning(StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot SlotState;

	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));
	
	return (SlotState.GetFacility().BuildQueue.Length > 0);
}

static function string GetProvingGroundBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		Contribution = string(GetProvingGroundAvengerBonus(SlotState.GetAssignedStaff(), bPreview));
	}

	return GetBonusDisplayString(SlotState, "%AVENGERBONUS", Contribution);
}

//#############################################################################################
//----------------   RESISTANCE COMMS   -------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateResCommsStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'ResCommsStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillResCommsSlot;
	Template.EmptyFn = EmptyResCommsSlot;
	Template.CanStaffBeMovedFn = CanStaffBeMovedResComms;
	Template.GetContributionFromSkillFn = GetResCommsContribution;
	Template.GetAvengerBonusAmountFn = GetResCommsAvengerBonus;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetResCommsBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

static function X2DataTemplate CreateResCommsBetterStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'ResCommsBetterStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillResCommsSlot;
	Template.EmptyFn = EmptyResCommsSlot;
	Template.CanStaffBeMovedFn = CanStaffBeMovedResComms;
	Template.GetContributionFromSkillFn = GetResCommsBetterContribution;
	Template.GetAvengerBonusAmountFn = GetResCommsAvengerBonus;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetResCommsBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

static function int GetResCommsContribution(XComGameState_Unit Unit)
{
	return (GetContributionDefault(Unit) - 3);
}

static function int GetResCommsBetterContribution(XComGameState_Unit Unit)
{
	return (GetContributionDefault(Unit) - 1);
}

static function int GetResCommsAvengerBonus(XComGameState_Unit Unit, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	return XComHQ.GetPossibleResContacts();
}

static function FillResCommsSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_FacilityXCom NewFacilityState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewFacilityState = GetNewFacilityState(NewGameState, NewSlotState);
	
	NewFacilityState.CommCapacity += NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function EmptyResCommsSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;
	local XComGameState_FacilityXCom NewFacilityState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	NewFacilityState = GetNewFacilityState(NewGameState, NewSlotState);

	NewFacilityState.CommCapacity -= NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function bool CanStaffBeMovedResComms(StateObjectReference SlotRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot SlotState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));	
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));
	
	if ((XComHQ.GetPossibleResContacts() - SlotState.GetMyTemplate().GetContributionFromSkillFn(SlotState.GetAssignedStaff())) < XComHQ.GetCurrentResContacts())
		return false;
	else
		return true;
}

static function string GetResCommsBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		Contribution = string(SlotState.GetMyTemplate().GetContributionFromSkillFn(SlotState.GetAssignedStaff()));
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

//#############################################################################################
//----------------   POWER RELAY   ------------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreatePowerRelayStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'PowerRelayStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillPowerRelaySlot;
	Template.EmptyFn = EmptyPowerRelaySlot;
	Template.CanStaffBeMovedFn = CanStaffBeMovedPowerRelay;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetPowerRelayAvengerBonus;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetBonusDisplayStringDefault;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

static function int GetPowerRelayAvengerBonus(XComGameState_Unit Unit, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	return XComHQ.GetPowerProduced();
}

static function FillPowerRelaySlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_FacilityXCom NewFacilityState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewFacilityState = GetNewFacilityState(NewGameState, NewSlotState);
	
	NewFacilityState.PowerOutput += NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function EmptyPowerRelaySlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;
	local XComGameState_FacilityXCom NewFacilityState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	NewFacilityState = GetNewFacilityState(NewGameState, NewSlotState);
	
	NewFacilityState.PowerOutput -= NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function bool CanStaffBeMovedPowerRelay(StateObjectReference SlotRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot SlotState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));

	if ((XComHQ.GetPowerProduced() - SlotState.GetMyTemplate().GetContributionFromSkillFn(SlotState.GetAssignedStaff())) < XComHQ.GetPowerConsumed())
		return false;
	else
		return true;
}

//#############################################################################################
//----------------   PSI CHAMBER   ------------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreatePsiChamberEngineerStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'PsiChamberScientistStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillPsiChamberEngSlot;
	Template.EmptyFn = EmptyPsiChamberEngSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayPsiChamberEngToDoWarning;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetPsiChamberScientistAvengerBonus;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetPsiChamberScientistBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

static function int GetPsiChamberScientistAvengerBonus(XComGameState_Unit Unit, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local float PercentIncrease;
	local int NewWorkPerHour;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Need to return the percent increase in overall training speed provided by this unit
	NewWorkPerHour = GetContributionDefault(Unit) + XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour;
	PercentIncrease = (GetContributionDefault(Unit) * 100.0) / NewWorkPerHour;

	return Round(PercentIncrease);
}

static function FillPsiChamberEngSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	NewXComHQ.PsiTrainingRate += NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function EmptyPsiChamberEngSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	NewXComHQ.PsiTrainingRate -= NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function bool ShouldDisplayPsiChamberEngToDoWarning(StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot SlotState;
	
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));

	return (SlotState.GetFacility().HasFilledSoldierSlot());
}

static function string GetPsiChamberScientistBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		Contribution = string(GetPsiChamberScientistAvengerBonus(SlotState.GetAssignedStaff(), bPreview));
	}

	return GetBonusDisplayString(SlotState, "%AVENGERBONUS", Contribution);
}

static function X2DataTemplate CreatePsiChamberSoldierStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'PsiChamberSoldierStaffSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.AssociatedProjectClass = class'XComGameState_HeadquartersProjectPsiTraining';
	Template.FillFn = FillPsiChamberSoldierSlot;
	Template.EmptyFn = EmptyPsiChamberSoldierSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectPsiChamberSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayPsiChamberSoldierToDoWarning;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetPsiChamberSoldierSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetPsiChamberSoldierBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForPsiChamberSoldierSlot;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Soldier";

	return Template;
}

static function FillPsiChamberSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectPsiTraining ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);

	if (NewUnitState.GetRank() == 0) // If the Unit is a rookie, start the project to train them as a Psi Operative
	{
		NewUnitState.SetStatus(eStatus_PsiTesting);

		NewXComHQ = GetNewXComHQState(NewGameState);

		ProjectState = XComGameState_HeadquartersProjectPsiTraining(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectPsiTraining'));
		NewGameState.AddStateObject(ProjectState);
		ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

		NewXComHQ.Projects.AddItem(ProjectState.GetReference());

		// Remove their gear
		NewUnitState.MakeItemsAvailable(NewGameState, false);

		// If the unit undergoing training is in the squad, remove them
		SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
		if (SquadIndex != INDEX_NONE)
		{
			// Remove them from the squad
			NewXComHQ.Squad[SquadIndex] = EmptyRef;
		}
	}
	else // The unit is either starting or resuming an ability training project, so set their status appropriately
	{
		NewUnitState.SetStatus(eStatus_PsiTraining);
	}
}

static function EmptyPsiChamberSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);

	NewUnitState.SetStatus(eStatus_Active);
}

static function EmptyStopProjectPsiChamberSoldierSlot(StateObjectReference SlotRef)
{
	local XComGameState NewGameState;
	local HeadquartersOrderInputContext OrderInput;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersProjectPsiTraining PsiTrainingProject;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));
	Unit = SlotState.GetAssignedStaff();

	PsiTrainingProject = XComHQ.GetPsiTrainingProject(SlotState.GetAssignedStaffRef());
	if (PsiTrainingProject != none)
	{
		// If the unit is undergoing initial Psi Op training, cancel the project
		if (Unit.GetStatus() == eStatus_PsiTesting)
		{
			OrderInput.OrderType = eHeadquartersOrderType_CancelPsiTraining;
			OrderInput.AcquireObjectReference = PsiTrainingProject.GetReference();

			class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
		}
		else if (Unit.GetStatus() == eStatus_PsiTraining)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pause Psi Ability Training");

			PsiTrainingProject = XComGameState_HeadquartersProjectPsiTraining(NewGameState.CreateStateObject(PsiTrainingProject.Class, PsiTrainingProject.ObjectID));
			NewGameState.AddStateObject(PsiTrainingProject);
			PsiTrainingProject.bForcePaused = true;

			SlotState.EmptySlot(NewGameState);

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

static function bool ShouldDisplayPsiChamberSoldierToDoWarning(StateObjectReference SlotRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit Unit;
	local StaffUnitInfo UnitInfo;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));

	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		UnitInfo.UnitRef = XComHQ.Crew[i];
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));

		if (Unit.GetSoldierClassTemplateName() == 'PsiOperative' && IsUnitValidForPsiChamberSoldierSlot(SlotState, UnitInfo))
		{
			return true;
		}
	}

	return false;
}

static function bool IsUnitValidForPsiChamberSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit; 
	local X2SoldierClassTemplate SoldierClassTemplate;
	local SCATProgression ProgressAbility;
	local name AbilityName;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.CanBeStaffed()
		&& Unit.IsASoldier()
		&& !Unit.IsInjured()
		&& !Unit.IsTraining()
		&& !Unit.IsPsiTraining()
		&& !Unit.IsPsiAbilityTraining()
		&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
		if (Unit.GetRank() == 0 && !Unit.CanRankUpSoldier()) // All rookies who have not yet ranked up can be trained as Psi Ops
		{
			return true;
		}
		else if (Unit.GetSoldierClassTemplateName() == 'PsiOperative') // But Psi Ops can only train until they learn all abilities
		{
			SoldierClassTemplate = Unit.GetSoldierClassTemplate();
			foreach Unit.PsiAbilities(ProgressAbility)
			{
				AbilityName = SoldierClassTemplate.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);
				if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName))
				{
					return true; // If we find an ability that the soldier hasn't learned yet, they are valid
				}
			}
		}
	}

	return false;
}

static function string GetPsiChamberSoldierBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectPsiTraining TrainProject;
	local XComGameState_Unit Unit;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		TrainProject = XComHQ.GetPsiTrainingProject(SlotState.GetAssignedStaffRef());
		Unit = SlotState.GetAssignedStaff();

		if (Unit.GetSoldierClassTemplateName() == 'PsiOperative' && TrainProject != none)
		{
			AbilityName = Unit.GetSoldierClassTemplate().GetAbilityName(TrainProject.iAbilityRank, TrainProject.iAbilityBranch);
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
			Contribution = Caps(AbilityTemplate.LocFriendlyName);
		}
		else
		{
			Contribution = SlotState.GetMyTemplate().BonusDefaultText;
		}
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

static function string GetPsiChamberSoldierSkillDisplayString(XComGameState_StaffSlot SlotState)
{
	return "";
}

//#############################################################################################
//----------------   UFO DEFENSE   ------------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateUFODefenseStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'UFODefenseStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillUFODefenseSlot;
	Template.EmptyFn = EmptyUFODefenseSlot;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetBonusDisplayStringDefault;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

static function FillUFODefenseSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	
	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);
		
	if (NewXComHQ.TacticalGameplayTags.Find('AvengerDefenseTurrets') != INDEX_NONE)
	{
		NewXComHQ.TacticalGameplayTags.RemoveItem('AvengerDefenseTurrets');
		NewXComHQ.TacticalGameplayTags.AddItem('AvengerDefenseTurretsMk2');
	}

	if (NewXComHQ.TacticalGameplayTags.Find('AvengerDefenseTurrets_Upgrade') != INDEX_NONE)
	{
		NewXComHQ.TacticalGameplayTags.RemoveItem('AvengerDefenseTurrets_Upgrade');
		NewXComHQ.TacticalGameplayTags.AddItem('AvengerDefenseTurretsMk2_Upgrade');
	}
}

static function EmptyUFODefenseSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;
	local XComGameState_HeadquartersXCom NewXComHQ;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	if (NewXComHQ.TacticalGameplayTags.Find('AvengerDefenseTurretsMk2') != INDEX_NONE)
	{
		NewXComHQ.TacticalGameplayTags.RemoveItem('AvengerDefenseTurretsMk2');
		NewXComHQ.TacticalGameplayTags.AddItem('AvengerDefenseTurrets');
	}

	if (NewXComHQ.TacticalGameplayTags.Find('AvengerDefenseTurretsMk2_Upgrade') != INDEX_NONE)
	{
		NewXComHQ.TacticalGameplayTags.RemoveItem('AvengerDefenseTurretsMk2_Upgrade');
		NewXComHQ.TacticalGameplayTags.AddItem('AvengerDefenseTurrets_Upgrade');
	}
}

//#############################################################################################
//----------------   OFFICER TRAINING SCHOOL   ------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateOTSStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'OTSStaffSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.FillFn = FillOTSSlot;
	Template.EmptyFn = EmptySlotDefault;
	Template.EmptyStopProjectFn = EmptyStopProjectOTSSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayOTSSoldierToDoWarning;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetOTSSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetOTSBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForOTSSoldierSlot;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Soldier";

	return Template;
}

static function FillOTSSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectTrainRookie ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);
	
	ProjectState = XComGameState_HeadquartersProjectTrainRookie(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectTrainRookie'));
	NewGameState.AddStateObject(ProjectState);
	ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

	NewUnitState.SetStatus(eStatus_Training);
	NewXComHQ.Projects.AddItem(ProjectState.GetReference());

	// Remove their gear
	NewUnitState.MakeItemsAvailable(NewGameState, false);
	
	// If the unit undergoing training is in the squad, remove them
	SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		// Remove them from the squad
		NewXComHQ.Squad[SquadIndex] = EmptyRef;
	}
}

static function EmptyStopProjectOTSSoldierSlot(StateObjectReference SlotRef)
{
	local HeadquartersOrderInputContext OrderInput;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectTrainRookie TrainRookieProject;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));

	TrainRookieProject = XComHQ.GetTrainRookieProject(SlotState.GetAssignedStaffRef());
	if (TrainRookieProject != none)
	{		
		OrderInput.OrderType = eHeadquartersOrderType_CancelTrainRookie;
		OrderInput.AcquireObjectReference = TrainRookieProject.GetReference();

		class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
	}
}

static function bool ShouldDisplayOTSSoldierToDoWarning(StateObjectReference SlotRef)
{
	return false;
}

static function bool IsUnitValidForOTSSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	
	if (Unit.CanBeStaffed()
		&& Unit.IsASoldier()
		&& !Unit.IsInjured()
		&& !Unit.IsTraining()
		&& !Unit.IsPsiTraining()
		&& Unit.GetRank() == 0
		&& !Unit.CanRankUpSoldier()
		&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
		return true;
	}

	return false;
}

static function string GetOTSSkillDisplayString(XComGameState_StaffSlot SlotState)
{
	return "";
}

static function string GetOTSBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectTrainRookie TrainProject;
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		TrainProject = XComHQ.GetTrainRookieProject(SlotState.GetAssignedStaffRef());

		if (TrainProject.GetTrainingClassTemplate().DisplayName != "")
			Contribution = Caps(TrainProject.GetTrainingClassTemplate().DisplayName);
		else
			Contribution = SlotState.GetMyTemplate().BonusDefaultText;
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

//#############################################################################################
//----------------   ADVANCED WARFARE CENTER   ------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateAWCEngineerStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'AWCScientistStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillAWCEngSlot;
	Template.EmptyFn = EmptyAWCEngSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayAWCEngToDoWarning;
	Template.GetContributionFromSkillFn = GetAWCContribution;
	Template.GetAvengerBonusAmountFn = GetAWCAvengerBonus;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetAWCBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

static function int GetAWCContribution(XComGameState_Unit UnitState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	return GetContributionDefault(UnitState) * (XComHQ.XComHeadquarters_BaseHealRate / 5);
}

static function int GetAWCAvengerBonus(XComGameState_Unit UnitState, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local float PercentIncrease;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Need to return the percent increase in overall healing speed provided by this unit
	PercentIncrease = (GetAWCContribution(UnitState) * 100.0) / (XComHQ.XComHeadquarters_BaseHealRate);

	return Round(PercentIncrease);
}

static function FillAWCEngSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);
	
	NewXComHQ.HealingRate += GetAWCContribution(NewUnitState);
}

static function EmptyAWCEngSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	NewXComHQ.HealingRate -= GetAWCContribution(NewUnitState);

	if (NewXComHQ.HealingRate < NewXComHQ.XComHeadquarters_BaseHealRate)
	{
		NewXComHQ.HealingRate = NewXComHQ.XComHeadquarters_BaseHealRate;
	}
}

static function bool ShouldDisplayAWCEngToDoWarning(StateObjectReference SlotRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	return (XComHQ.GetNumberOfInjuredSoldiers() > 0);
}

static function string GetAWCBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		Contribution = string(GetAWCAvengerBonus(SlotState.GetAssignedStaff(), bPreview));
	}

	return GetBonusDisplayString(SlotState, "%AVENGERBONUS", Contribution);
}

static function X2DataTemplate CreateAWCSoldierStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'AWCSoldierStaffSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.FillFn = FillAWCSoldierSlot;
	Template.EmptyFn = EmptySlotDefault;
	Template.EmptyStopProjectFn = EmptyStopProjectAWCSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayAWCSoldierToDoWarning;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetAWCSoldierSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetAWCSoldierBonusDisplayString;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForAWCSoldierSlot;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Soldier";
	Template.ExcludeClasses.AddItem('PsiOperative');

	return Template;
}

static function FillAWCSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectRespecSoldier ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	ProjectState = XComGameState_HeadquartersProjectRespecSoldier(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectRespecSoldier'));
	NewGameState.AddStateObject(ProjectState);
	ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

	NewUnitState.SetStatus(eStatus_Training);
	NewXComHQ.Projects.AddItem(ProjectState.GetReference());

	// If the unit undergoing training is in the squad, remove them
	SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		// Remove them from the squad
		NewXComHQ.Squad[SquadIndex] = EmptyRef;
	}
}

static function EmptyStopProjectAWCSoldierSlot(StateObjectReference SlotRef)
{
	local HeadquartersOrderInputContext OrderInput;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectRespecSoldier RespecSoldierProject;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));

	RespecSoldierProject = XComHQ.GetRespecSoldierProject(SlotState.GetAssignedStaffRef());
	if (RespecSoldierProject != none)
	{
		OrderInput.OrderType = eHeadquartersOrderType_CancelRespecSoldier;
		OrderInput.AcquireObjectReference = RespecSoldierProject.GetReference();
		
		class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
	}
}

static function bool ShouldDisplayAWCSoldierToDoWarning(StateObjectReference SlotRef)
{
	return false;
}

static function bool IsUnitValidForAWCSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.CanBeStaffed()
		&& Unit.IsASoldier()
		&& !Unit.IsInjured()
		&& !Unit.IsTraining()
		&& !Unit.IsPsiTraining()
		&& Unit.GetRank() >= 2 //only include soldiers who have reached Corporal, and therefore know at least one ability
		&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE) // Certain classes can't retrain their abilities (Psi Ops)
	{
		return true;
	}

	return false;
}

static function string GetAWCSoldierSkillDisplayString(XComGameState_StaffSlot SlotState)
{
	return "";
}

static function string GetAWCSoldierBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_Unit UnitState;
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		UnitState = SlotState.GetAssignedStaff();
		Contribution = Caps(UnitState.GetSoldierClassTemplate().DisplayName);
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

//#############################################################################################
//----------------   SHADOW CHAMBER    --------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreateShadowChamberShenStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'ShadowChamberShenStaffSlot');
	Template.bEngineerSlot = true;
	Template.FillFn = FillSlotDefault;
	Template.EmptyFn = EmptySlotDefault;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetBonusDisplayStringDefault;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Shen";

	Template.LockedText = "";

	return Template;
}

static function X2DataTemplate CreateShadowChamberTyganStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	`CREATE_X2TEMPLATE(class'X2StaffSlotTemplate', Template, 'ShadowChamberTyganStaffSlot');
	Template.bScientistSlot = true;
	Template.FillFn = FillSlotDefault;
	Template.EmptyFn = EmptySlotDefault;
	Template.GetContributionFromSkillFn = GetContributionDefault;
	Template.GetAvengerBonusAmountFn = GetAvengerBonusDefault;
	Template.GetNameDisplayStringFn = GetNameDisplayStringDefault;
	Template.GetSkillDisplayStringFn = GetSkillDisplayStringDefault;
	Template.GetBonusDisplayStringFn = GetBonusDisplayStringDefault;
	Template.GetLocationDisplayStringFn = GetLocationDisplayStringDefault;
	Template.IsUnitValidForSlotFn = IsUnitValidForSlotDefault;
	Template.IsStaffSlotBusyFn = IsStaffSlotBusyDefault;
	Template.MatineeSlotName = "Tygan";

	Template.LockedText = "";

	return Template;
}

//#############################################################################################
//----------------   DEFAULTS   ---------------------------------------------------------------
//#############################################################################################

static function FillSlotDefault(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
}

static function EmptySlotDefault(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;
	
	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
}

static function int GetContributionDefault(XComGameState_Unit UnitState)
{
	return UnitState.GetSkillLevel();
}

static function int GetAvengerBonusDefault(XComGameState_Unit UnitState, optional bool bPreview)
{
	return -1; //Not implemented, no bonus defined for this facility
}

static function string GetNameDisplayStringDefault(XComGameState_StaffSlot SlotState)
{
	local XComGameState_StaffSlot GhostOwnerSlot;
	local XComGameState_Unit UnitState;
	
	if (SlotState.IsSlotFilled())
	{
		if (SlotState.IsSlotFilledWithGhost(GhostOwnerSlot))
		{
			return GhostOwnerSlot.GetMyTemplate().GhostName;
		}
		else
		{
			UnitState = SlotState.GetAssignedStaff();

			if (UnitState.IsASoldier())
				return UnitState.GetName(eNameType_RankFull);
			else
				return UnitState.GetFullName();
		}
	}
	else if (SlotState.IsLocked())
	{
		return SlotState.GetMyTemplate().LockedText;
	}
	else
		return SlotState.GetMyTemplate().EmptyText;
}

static function string GetSkillDisplayStringDefault(XComGameState_StaffSlot SlotState)
{
	local XComGameState_Unit UnitState;

	if (SlotState.IsSlotFilled())
	{
		UnitState = SlotState.GetAssignedStaff();
		return string(GetContributionDefault(UnitState));
	}
	else
		return "";
}

static function string GetBonusDisplayStringDefault(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		Contribution = string(GetContributionDefault(SlotState.GetAssignedStaff()));
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

static function string GetLocationDisplayStringDefault(XComGameState_StaffSlot SlotState)
{
	return SlotState.GetFacility().GetMyTemplate().DisplayName;
}

static function bool IsUnitValidForSlotDefault(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot UnitCurrentSlot;
	local X2StaffSlotTemplate SlotTemplate;
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	// Make sure that the unit is:
	// 1) Can be staffed
	// 2) Not the unit already staffed in the slot
	// 3) Of the correct type for this slot
	// 4) Can the staffer be moved out of their current slot, if they are in one
	// 5) The unit's soldier class is not in an exclusion list for this slot
	if (UnitState.CanBeStaffed() &&
		UnitState.GetReference().ObjectID != SlotState.GetAssignedStaffRef().ObjectID)
	{
		SlotTemplate = SlotState.GetMyTemplate();

		if ((SlotTemplate.ExcludeClasses.Find(UnitState.GetSoldierClassTemplateName()) == INDEX_NONE) &&
			((SlotTemplate.bSoldierSlot && UnitState.IsSoldier()) ||
			(SlotTemplate.bEngineerSlot && UnitState.IsAnEngineer()) ||
			(SlotTemplate.bScientistSlot && UnitState.IsAScientist())))
		{
			// If the player is attempting to move a ghost, make sure to get their current slot instead of the ghost-creators slot
			if (UnitInfo.bGhostUnit && UnitInfo.GhostLocation.ObjectID != 0)
			{
				UnitCurrentSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.GhostLocation.ObjectID));
			}
			else
			{
				UnitCurrentSlot = UnitState.GetStaffSlot();
			}

			if (UnitCurrentSlot != none)
			{
				// If the "unit" we are trying to staff is in a ghost-creation slot, and this unit is a ghost, it can be staffed here
				// Can't use the normal CanStaffBeMoved, since it would return false if any other ghosts have already been staffed
				if (UnitCurrentSlot.GetMyTemplate().CreatesGhosts && UnitInfo.bGhostUnit)
				{
					return true;
				}
				else if ((UnitCurrentSlot.Room.ObjectID > 0 && UnitCurrentSlot.Room == SlotState.Room) || 
					(UnitCurrentSlot.Facility.ObjectID > 0 && UnitCurrentSlot.Facility == SlotState.Facility))
				{
					// The unit is already staffed in this room or facility, so they aren't valid
					return false;
				}
				else
				{
					return UnitCurrentSlot.CanStaffBeMoved();
				}
			}
			else // The unit isn't staffed, so they can be moved
			{
				return true;
			}
		}
	}

	return false;
}

static function bool IsStaffSlotBusyDefault(XComGameState_StaffSlot SlotState)
{
	local XComGameState_FacilityXCom Facility;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(SlotState.Facility.ObjectID));
	if (Facility != None)
	{
		return Facility.FacilityHasActiveProjects();
	}
	
	return false;
}

//#############################################################################################
//----------------   HELPER FUNCTIONS  --------------------------------------------------------
//#############################################################################################

static function FillSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, out XComGameState_StaffSlot NewSlotState, out XComGameState_Unit NewUnitState)
{
	local XComGameState_StaffSlot GhostOwnerSlot;

	NewSlotState = XComGameState_StaffSlot(NewGameState.CreateStateObject(class'XComGameState_StaffSlot', SlotRef.ObjectID));
	NewSlotState.AssignedStaff = UnitInfo.UnitRef;
	NewGameState.AddStateObject(NewSlotState);
	
	// If the assigned unit is a ghost, do not update the owning unit's reference
	if (UnitInfo.bGhostUnit)
	{
		// We just staffed a ghost for the first time, so update the allowed count in the owner's staff slot
		// Still need to return a unit state, even if it isn't actually new
		NewUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
		GhostOwnerSlot = NewUnitState.GetStaffSlot(); // the staff slot where the ghost owner is living
		GhostOwnerSlot = XComGameState_StaffSlot(NewGameState.CreateStateObject(class'XComGameState_StaffSlot', GhostOwnerSlot.ObjectID));
		NewGameState.AddStateObject(GhostOwnerSlot);
		GhostOwnerSlot.AvailableGhostStaff -= 1;

		if (GhostOwnerSlot.AvailableGhostStaff < 0)
			GhostOwnerSlot.AvailableGhostStaff = 0;
	}
	else
	{
		// Only update the unit if they aren't a ghost
		NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitInfo.UnitRef.ObjectID));
		NewGameState.AddStateObject(NewUnitState);
		NewUnitState.StaffingSlot = SlotRef;
	}
}

static function EmptySlot(XComGameState NewGameState, StateObjectReference SlotRef, out XComGameState_StaffSlot NewSlotState, out XComGameState_Unit NewUnitState)
{
	local XComGameState_StaffSlot GhostOwnerSlot;
	local StateObjectReference EmptyRef;

	NewSlotState = XComGameState_StaffSlot(NewGameState.CreateStateObject(class'XComGameState_StaffSlot', SlotRef.ObjectID));
		
	// When a ghost gets unstaffed, it accesses the ghost-creating staff slot and increases the available ghosts counter.
	if (NewSlotState.IsSlotFilledWithGhost(GhostOwnerSlot))
	{
		// Still need to return a unit state, even if it isn't actually new
		NewUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(NewSlotState.AssignedStaff.ObjectID));
		GhostOwnerSlot = XComGameState_StaffSlot(NewGameState.CreateStateObject(class'XComGameState_StaffSlot', GhostOwnerSlot.ObjectID));
		NewGameState.AddStateObject(GhostOwnerSlot);
		GhostOwnerSlot.AvailableGhostStaff += 1;

		if (GhostOwnerSlot.AvailableGhostStaff > GhostOwnerSlot.MaxAdjacentGhostStaff)
			GhostOwnerSlot.AvailableGhostStaff = GhostOwnerSlot.MaxAdjacentGhostStaff;
	}
	else
	{
		// Only update the unit if they aren't a ghost
		NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', NewSlotState.AssignedStaff.ObjectID));
		NewGameState.AddStateObject(NewUnitState);
		NewUnitState.StaffingSlot = EmptyRef;
	}

	NewSlotState.AssignedStaff = EmptyRef;
	NewGameState.AddStateObject(NewSlotState);
}

static function string GetBonusDisplayString(XComGameState_StaffSlot SlotState, String ToReplace, String Replacement)
{
	local string BonusStr;

	if (SlotState.IsSlotFilled())
	{
		BonusStr = SlotState.GetMyTemplate().BonusText;
		BonusStr = Repl(BonusStr, ToReplace, Replacement);
	}
	else
	{
		BonusStr = SlotState.GetMyTemplate().BonusEmptyText;
	}

	return BonusStr;
}

static function XComGameState_HeadquartersRoom GetNewRoomState(XComGameState NewGameState, XComGameState_StaffSlot SlotState)
{
	local XComGameState_HeadquartersRoom NewRoomState;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersRoom', NewRoomState)
	{
		if (NewRoomState.ObjectID == SlotState.Room.ObjectID)
		{
			break;
		}
	}

	if (NewRoomState == none)
	{
		NewRoomState = SlotState.GetRoom();
		NewRoomState = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', NewRoomState.ObjectID));
		NewGameState.AddStateObject(NewRoomState);
	}

	return NewRoomState;
}

static function XComGameState_FacilityXCom GetNewFacilityState(XComGameState NewGameState, XComGameState_StaffSlot SlotState)
{
	local XComGameState_FacilityXCom NewFacilityState;

	foreach NewGameState.IterateByClassType(class'XComGameState_FacilityXCom', NewFacilityState)
	{
		if (NewFacilityState.ObjectID == SlotState.Facility.ObjectID)
		{
			break;
		}
	}

	if (NewFacilityState == none)
	{
		NewFacilityState = SlotState.GetFacility();
		NewFacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', NewFacilityState.ObjectID));
		NewGameState.AddStateObject(NewFacilityState);
	}

	return NewFacilityState;
}

static function XComGameState_HeadquartersXCom GetNewXComHQState(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom NewXComHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', NewXComHQ)
	{
		break;
	}

	if (NewXComHQ == none)
	{
		NewXComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', NewXComHQ.ObjectID));
		NewGameState.AddStateObject(NewXComHQ);
	}

	return NewXComHQ;
}

