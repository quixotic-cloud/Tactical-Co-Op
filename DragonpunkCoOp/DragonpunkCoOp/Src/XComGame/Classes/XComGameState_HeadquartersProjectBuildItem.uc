//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectBuildItem.uc
//  AUTHOR:  Mark Nauta  --  04/29/2014
//  PURPOSE: This object represents the instance data for an XCom HQ build item project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectBuildItem extends XComGameState_HeadquartersProject native(Core);

//---------------------------------------------------------------------------------------
// Call when you start a new project
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	
	History = `XCOMHISTORY;

	ProjectFocus = FocusRef;
	AuxilaryReference = AuxRef;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(FocusRef.ObjectID));

	InitialProjectPoints = ItemState.GetMyTemplate().PointsToComplete; 
	bInstant = (InitialProjectPoints == 0);
	ProjectPointsRemaining = Round(float(ItemState.GetMyTemplate().PointsToComplete) * class'X2StrategyGameRulesetDataStructures'.default.BuildItemProject_TimeScalar[`DIFFICULTYSETTING]);
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
	local int iTotalWork;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	iTotalWork = XComHQ.XComHeadquarters_DefaultConstructionWorkPerHour; //Always start with the default construction rate

	if (!FrontOfBuildQueue() && !bAssumeActive)
	{
		return 0;
	}
	else
	{
		// Check for Higher Learning
		iTotalWork += Round(float(iTotalWork) * (float(XComHQ.EngineeringEffectivenessPercentIncrease) / 100.0));
	}

	return iTotalWork;
}

//---------------------------------------------------------------------------------------
// Is it currently at the front of the build queue
function bool FrontOfBuildQueue()
{
	local XComGameState_FacilityXCom Facility;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(AuxilaryReference.ObjectID));

	if(Facility != none)
	{
		if(Facility.BuildQueue.length > 0 && Facility.BuildQueue[0].ObjectID == self.ObjectID)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// Add the facility to HQ's list of facilities and handle staffing stuff
function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	local X2ItemTemplate ItemTemplate;
	
	ItemTemplate = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID)).GetMyTemplate();

	OrderInput.OrderType = eHeadquartersOrderType_ItemConstructionCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
	
	`GAME.GetGeoscape().Pause();

	`HQPRES.UIItemComplete(ItemTemplate);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}