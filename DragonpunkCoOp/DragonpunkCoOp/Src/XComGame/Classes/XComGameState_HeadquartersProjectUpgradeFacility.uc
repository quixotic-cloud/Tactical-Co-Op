//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectUpgradeFacility.uc
//  AUTHOR:  Mark Nauta  --  06/17/2014
//  PURPOSE: This object represents the instance data for an upgrade facility project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectUpgradeFacility extends XComGameState_HeadquartersProject native(Core);

//---------------------------------------------------------------------------------------
// Call when you start a new project
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameState_FacilityUpgrade UpgradeState;

	ProjectFocus = FocusRef;
	AuxilaryReference = AuxRef;
	UpgradeState = XComGameState_FacilityUpgrade(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	UpgradeState.Facility = AuxilaryReference;
	
	InitialProjectPoints = UpgradeState.GetMyTemplate().PointsToComplete; 
	bInstant = (InitialProjectPoints == 0);
	ProjectPointsRemaining = Round(float(UpgradeState.GetMyTemplate().PointsToComplete) * class'X2StrategyGameRulesetDataStructures'.default.UpgradeFacilityProject_TimeScalar[`DIFFICULTYSETTING]);
	UpdateWorkPerHour(NewGameState);
	StartDateTime = `STRATEGYRULES.GameTime;
	if(MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_Unit Builder;
	local int iTotalWork;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	iTotalWork = XComHQ.XComHeadquarters_DefaultConstructionWorkPerHour; //Always start with the default construction rate
	
	if(StartState != none)
	{
		Facility = XComGameState_FacilityXCom(StartState.GetGameStateForObjectID(AuxilaryReference.ObjectID));
	}
	else
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(AuxilaryReference.ObjectID));
	}
	
	if(Facility != none)
	{
		if(StartState != none)
		{
			Room = XComGameState_HeadquartersRoom(StartState.GetGameStateForObjectID(Facility.Room.ObjectID));
		}
		else
		{
			Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(Facility.Room.ObjectID));
		}
		
		if(Room != none)
		{
			Builder = Room.GetBuildSlot().GetAssignedStaff();

			if(Builder != none)
			{
				iTotalWork += Builder.GetSkillLevel();
			}
		}

	}

	return iTotalWork;
}

//---------------------------------------------------------------------------------------
// Add to facilities list of upgrades and call on added function
function OnProjectCompleted()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityUpgrade UpgradeState;
	local HeadquartersOrderInputContext OrderInput;
	
	History = `XCOMHISTORY;
	UpgradeState = XComGameState_FacilityUpgrade(History.GetGameStateForObjectID(ProjectFocus.ObjectID));

	OrderInput.OrderType = eHeadquartersOrderType_UpgradeFacilityCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();
	
	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
		
	`HQPRES.UIUpgradeComplete(UpgradeState.GetMyTemplate());
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}