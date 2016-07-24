//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProject.uc
//  AUTHOR:  Mark Nauta  --  04/10/2014
//  PURPOSE: This object represents the instance data for XCom HQ's projects
//           (research, item, facility, etc.) in the XCom 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProject extends XComGameState_BaseObject native(Core);

// State vars
var() StateObjectReference	ProjectFocus; // Reference to the GameState of the Tech, Item, or Facility in progress
var() StateObjectReference  AuxilaryReference; // facility where the project is taking place (not always used)
var() TDateTime             StartDateTime; // When the project was started, updates w/staffing changes, pausing, and resuming of research
var() TDateTime			    CompletionDateTime; // When the project will be completed, will update based on events
var() int					ProjectPointsRemaining; // Used with staffers' points/hr to determine time left on project
var() int					InitialProjectPoints; // Used to calculate percent complete.
var() int					WorkPerHour;
var() bool					bInstant;

var() int					SavedDiscountPercent; // Save a discount percent at time of creation, used to give the correct refund if the project is canceled

// Incremental project vars
var() bool					bIncremental;
var() int					BlocksRemaining;
var() int					BlockPointsRemaining;
var() TDateTime				BlockCompletionDateTime;

var() localized string		ProjectCompleteNotification; 

//---------------------------------------------------------------------------------------
// Subclasses will handle most of the implementation of this function
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	ProjectFocus = FocusRef;
}

//---------------------------------------------------------------------------------------
// Sets the project completion time under the current conditions
function SetProjectedCompletionDateTime(TDateTime StartTime)
{
	// start time + hours remaining
	CompletionDateTime = StartTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(CompletionDateTime, GetProjectedNumHoursRemaining());

	// Check if this project overlaps with any others in the queue, and offset its time by a small amount if it does
	CheckForProjectOverlap();

	// if incremental project, need to update block projected time as well
	if(bIncremental)
	{
		BlockCompletionDateTime = StartTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(BlockCompletionDateTime, GetBlockNumHoursRemaining());
	}
}

private function CheckForProjectOverlap()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProject ProjectState;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local StateObjectReference ProjectRef;
	local bool bModified;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	foreach XComHQ.Projects(ProjectRef)
	{
		if (ProjectRef.ObjectID != ObjectID) // make sure we don't check against ourself
		{
			ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(ProjectRef.ObjectID));
			HealProject = XComGameState_HeadquartersProjectHealSoldier(ProjectState);

			// Heal projects can overlap since they don't give popups on the Geoscape
			if (HealProject == none)
			{
				if (ProjectState.CompletionDateTime == CompletionDateTime)
				{
					// If the projects' completion date and time is the same as another project in the event queue, subtract an hour so the events don't stack
					// An hour is subtracted instead of added so the total "Days Remaining" does not change because of the offset.
					class'X2StrategyGameRulesetDataStructures'.static.AddHours(CompletionDateTime, -1);
					bModified = true;
				}
			}
		}
	}

	if (bModified)
	{
		CheckForProjectOverlap(); // Recursive to check if the new offset time overlaps with anything
	}
}

//---------------------------------------------------------------------------------------
// Power state and staffing changes have the potential to affect the completion time, true if state updates
function bool OnPowerStateOrStaffingChange()
{
	local int iCurrentWorkPerHour;

	iCurrentWorkPerHour = GetCurrentWorkPerHour();
	UpdateWorkPerHour();

	// Has anything changed
	if(iCurrentWorkPerHour == WorkPerHour)
	{
		return false;;
	}

	if(!MakingProgress())
	{
		PauseProject(iCurrentWorkPerHour);
		return true;
	}
	else
	{
		UpdateProjectPointsRemaining(iCurrentWorkPerHour);
		StartDateTime = `STRATEGYRULES.GameTime;
		SetProjectedCompletionDateTime(StartDateTime);
		return true;
	}
}

//---------------------------------------------------------------------------------------
// Called in the event that work isn't being conducted (Avenger takes off, no staffers etc.)
function PauseProject(optional int iCurrentWorkPerHour = -1)
{
	// Store points remaining
	if(iCurrentWorkPerHour != -1)
	{
		UpdateProjectPointsRemaining(iCurrentWorkPerHour);
	}
	else
	{
		UpdateProjectPointsRemaining(GetCurrentWorkPerHour());
	}

	// Set completion time to unreachable future
	CompletionDateTime.m_iYear = 9999;

	if(bIncremental)
	{
		BlockCompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
// Call when work should continue (Avenger lands, restaffed, etc.)
function ResumeProject()
{
	StartDateTime = `STRATEGYRULES.GameTime;

	UpdateWorkPerHour();

	if(MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
		BlockCompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
// In the event of a work pause we need to store progress
function UpdateProjectPointsRemaining(int iCurrentWorkPerHour)
{
	if(iCurrentWorkPerHour > 0)
	{
		ProjectPointsRemaining -= (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(`STRATEGYRULES.GameTime, StartDateTime) * iCurrentWorkPerHour);

		if(bIncremental)
		{
			BlockPointsRemaining -= (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(`STRATEGYRULES.GameTime, StartDateTime) * iCurrentWorkPerHour);
		}
	}
}

//---------------------------------------------------------------------------------------
// Used for percent complete functions
function int GetCurrentProjectPointsRemaining()
{
	local int PointsToReturn;

	PointsToReturn = ProjectPointsRemaining;

	if (GetCurrentWorkPerHour() > 0)
	{
		PointsToReturn -= (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(`STRATEGYRULES.GameTime, StartDateTime) * GetCurrentWorkPerHour());
	}

	return PointsToReturn;
}

//---------------------------------------------------------------------------------------
// Sets WorkPerHour
function UpdateWorkPerHour(optional XComGameState StartState = none)
{
	WorkPerHour = CalculateWorkPerHour(StartState);
}

//---------------------------------------------------------------------------------------
// Subclasses will handle implementation, if StartState then use that instead of History
// if bAssumeActive will calculate WorkPerHour as if this item, or whatever, is current project, front of queue, and unpaused
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return 0;
}

//---------------------------------------------------------------------------------------
// Get the work per hour under the current conditions
function int GetCurrentWorkPerHour()
{
	return WorkPerHour;
}

//---------------------------------------------------------------------------------------
// Should call UpdateWorkPerHour first
function bool MakingProgress()
{
	return (GetCurrentWorkPerHour() > 0);
}

//---------------------------------------------------------------------------------------
// Estimate of time based on current conditions (typically called after some kind of event)
function int GetProjectedNumHoursRemaining()
{
	local int iPseudoWorkPerHour;

	if(MakingProgress())
	{
		return (ProjectPointsRemaining / GetCurrentWorkPerHour());
	}
	else
	{
		iPseudoWorkPerHour = CalculateWorkPerHour(,true);

		if(iPseudoWorkPerHour > 0)
		{
			return (ProjectPointsRemaining / iPseudoWorkPerHour);
		}
		else
		{
			// something (such as power or damage) is causing no progress to be made on this project
			return -1;
		}
	}
}

//---------------------------------------------------------------------------------------
function int GetProjectNumDaysRemaining()
{
	return (GetProjectedNumHoursRemaining()/24);
}

//---------------------------------------------------------------------------------------
// Estimate of time for current block, based on current conditions
function int GetBlockNumHoursRemaining()
{
	local int iPseudoWorkPerHour;

	if(MakingProgress())
	{
		return (BlockPointsRemaining / GetCurrentWorkPerHour());
	}
	else
	{
		iPseudoWorkPerHour = CalculateWorkPerHour(,true);

		if(iPseudoWorkPerHour > 0)
		{
			return (BlockPointsRemaining / iPseudoWorkPerHour);
		}
		else
		{
			// something (such as power or damage) is causing no progress to be made on this project
			return -1;
		}
	}
}

//---------------------------------------------------------------------------------------
// UI should use this call. Gives exact hours remaining assuming no conditions change
function int GetCurrentNumHoursRemaining()
{
	if(MakingProgress())
	{
		return (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(CompletionDateTime, `STRATEGYRULES.GameTime));
	}
	else
	{
		// Not Making progress currently
		return -1;
	}
}

//---------------------------------------------------------------------------------------
// UI should use this call. Gives percent complete of this current project, using points 
// completed, not time. (Time may change with personnel changes) 
function float GetPercentComplete()
{
	if (InitialProjectPoints == 0) return -1.0; 

	return float(InitialProjectPoints-GetCurrentProjectPointsRemaining()) / float(InitialProjectPoints);
}

//---------------------------------------------------------------------------------------
// UI should use this call. Gives exact days remaining assuming no conditions change
function int GetCurrentNumDaysRemaining()
{
	if(MakingProgress())
	{
		return (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInDays(CompletionDateTime, `STRATEGYRULES.GameTime));
	}
	else
	{
		// Not Making progress currently
		return -1;
	}
}

//---------------------------------------------------------------------------------------
// Helper for Hack Rewards to modify remaining duration
function ModifyProjectPointsRemaining(float Modifier)
{
	ProjectPointsRemaining = float(ProjectPointsRemaining) * Modifier;
	BlockPointsRemaining = float(BlockPointsRemaining) * Modifier;
}

//---------------------------------------------------------------------------------------
// Subclasses will handle implementation, call when block timer is completed
function OnBlockCompleted()
{
}

//---------------------------------------------------------------------------------------
// Subclasses will handle implementation, called when project timer is completed
function OnProjectCompleted()
{
}


DefaultProperties
{
}