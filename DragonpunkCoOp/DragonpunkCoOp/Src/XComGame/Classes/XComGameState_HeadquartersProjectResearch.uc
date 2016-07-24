
//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectResearch.uc
//  AUTHOR:  Mark Nauta  --  04/17/2014
//  PURPOSE: This object represents the instance data for an XCom HQ research project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectResearch extends XComGameState_HeadquartersProject native(Core);

var bool bShadowProject;
var bool bProvingGroundProject;
var bool bForcePaused;

//---------------------------------------------------------------------------------------
// Call when you start a new project
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Tech Tech;

	History = `XCOMHISTORY;

	ProjectFocus = FocusRef;
	AuxilaryReference = AuxRef;
	Tech = XComGameState_Tech(History.GetGameStateForObjectID(FocusRef.ObjectID));

	if (Tech.GetMyTemplate().bShadowProject)
	{
		bShadowProject = true;
	}
	if (Tech.GetMyTemplate().bProvingGround)
	{
		bProvingGroundProject = true;
	}
	bInstant = Tech.IsInstant();

	InitialProjectPoints = Tech.GetProjectPoints();
	ProjectPointsRemaining = InitialProjectPoints;
	UpdateWorkPerHour();
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
	local int iTotalResearch;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(bShadowProject)
	{
		if(bForcePaused && !bAssumeActive)
		{
			return 0;
		}

		iTotalResearch = XComHQ.GetScienceScore(true); // +XComHQ.GetEngineeringScore(true);

		if (iTotalResearch == 0)
		{
			return 0;
		}
		
		return iTotalResearch;
	}
	else
	{
		// Can't make progress when paused or while shadow project is active or paused
		if ((XComHQ.HasActiveShadowProject() || bForcePaused) && !bAssumeActive)
		{
			return 0;
		}

		iTotalResearch = XComHQ.GetScienceScore(true);
		
		if (iTotalResearch == 0)
		{
			return 0;
		}
		else
		{
			// Check for Higher Learning
			iTotalResearch += Round(float(iTotalResearch) * (float(XComHQ.ResearchEffectivenessPercentIncrease) / 100.0));
		}

		return iTotalResearch;
	}
}

//---------------------------------------------------------------------------------------
// Add the tech to XComs list of completed research, and call any OnResearched methods for the tech
function OnProjectCompleted()
{
	local XComGameState_Tech TechState;
	local HeadquartersOrderInputContext OrderInput;
	local StateObjectReference TechRef;

	TechRef = ProjectFocus;

	OrderInput.OrderType = eHeadquartersOrderType_ResearchCompleted;
	OrderInput.AcquireObjectReference = ProjectFocus;

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	`GAME.GetGeoscape().Pause();

	if (bProvingGroundProject)
	{
		TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(TechRef.ObjectID));

		// If the Proving Ground project rewards an item, display all the project popups on the Geoscape
		if (TechState.ItemReward != None)
		{
			TechState.DisplayTechCompletePopups();
			`HQPRES.UIProvingGroundItemReceived(TechState.ItemReward, TechRef);
		}
		else // Otherwise give the normal project complete popup
		{
			`HQPRES.UIProvingGroundProjectComplete(TechRef);
		}
	}
	else if(bInstant)
	{
		TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(TechRef.ObjectID));
		TechState.DisplayTechCompletePopups();

		`HQPRES.ResearchReportPopup(TechRef);
	}
	else
	{
		`HQPRES.UIResearchComplete(TechRef);
	}
}

//---------------------------------------------------------------------------------------
function RushResearch(XComGameState NewGameState)
{
	local XComGameState_Tech TechState;

	TechState = XComGameState_Tech(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));

	UpdateProjectPointsRemaining(GetCurrentWorkPerHour());
	ProjectPointsRemaining -= Round(float(ProjectPointsRemaining) * TechState.TimeReductionScalar);
	ProjectPointsRemaining = Clamp(ProjectPointsRemaining, 0, InitialProjectPoints);

	StartDateTime = `STRATEGYRULES.GameTime;
	if(MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}
