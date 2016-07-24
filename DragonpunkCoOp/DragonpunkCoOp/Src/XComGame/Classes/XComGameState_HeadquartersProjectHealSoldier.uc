//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectHealSoldier.uc
//  AUTHOR:  Mark Nauta  --  04/22/2014
//  PURPOSE: This object represents the instance data for an XCom HQ heal soldier project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectHealSoldier extends XComGameState_HeadquartersProject native(Core);

var int PointsPerBlock;
var TDateTime TrueStart; // An unmodified start time that won't change based on pausing or starts & stops.  Used for analytics computations

//---------------------------------------------------------------------------------------
// Call when you start a new project, NewGameState should be none if not coming from tactical
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef;
	bIncremental = true;

	if(NewGameState != none)
	{
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	}
	else
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
	}
	
	ProjectPointsRemaining = GetWoundPoints(UnitState);
	BlocksRemaining = UnitState.GetBaseStat(eStat_HP) - UnitState.GetCurrentStat(eStat_HP);
	PointsPerBlock = Round(float(ProjectPointsRemaining) / float(BlocksRemaining));

	// Get rid of possible differences caused by rounding
	BlockPointsRemaining = PointsPerBlock;
	ProjectPointsRemaining = PointsPerBlock * BlocksRemaining;
	InitialProjectPoints = ProjectPointsRemaining;

	UpdateWorkPerHour(NewGameState);
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (TrueStart.m_fTime == 0.0f)
	{
		TrueStart = StartDateTime;
	}

	if(`STRATEGYRULES != none)
	{
		if(class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}
	
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
function int GetWoundPoints(XComGameState_Unit UnitState, optional int MinimumPoints)
{
	local array<WoundSeverity> WoundSeverities;
	local int idx, WoundPoints, MinPoints, MaxPoints;
	local float HealthPercent;

	HealthPercent = (UnitState.GetCurrentStat(eStat_HP) / UnitState.GetBaseStat(eStat_HP)) * 100.0;
	WoundSeverities = GetWoundSeverities();

	for(idx = 0; idx < WoundSeverities.Length; idx++)
	{
		if(HealthPercent >= WoundSeverities[idx].MinHealthPercent && HealthPercent <= WoundSeverities[idx].MaxHealthPercent)
		{
			MinPoints = max(WoundSeverities[idx].MinPointsToHeal, MinimumPoints);
			MaxPoints = WoundSeverities[idx].MaxPointsToHeal;

			WoundPoints = MinPoints + `SYNC_RAND(MaxPoints - MinPoints + 1);
			return (WoundPoints * class'X2StrategyGameRulesetDataStructures'.default.HealSoldierProject_TimeScalar[`DIFFICULTYSETTING]);
		}
	}

	`Redscreen("Error in calculating wound time.");
	return 0;
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	return max(XComHQ.HealingRate, XComHQ.XComHeadquarters_BaseHealRate);
}

//---------------------------------------------------------------------------------------
// Heal the unit by one block, and check if the healing is complete
function OnBlockCompleted()
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Healed - 1 Block");
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));

	if(UnitState != none)
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		UnitState.SetCurrentStat(eStat_HP, UnitState.GetCurrentStat(eStat_HP) + 1);
		NewGameState.AddStateObject(UnitState);

		HealProject = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateStateObject(class' XComGameState_HeadquartersProjectHealSoldier', self.ObjectID));
		NewGameState.AddStateObject(HealProject);

		HealProject.BlocksRemaining = UnitState.GetBaseStat(eStat_HP) - UnitState.GetCurrentStat(eStat_HP);

		if(HealProject.BlocksRemaining > 0)
		{
			HealProject.BlockPointsRemaining = HealProject.PointsPerBlock;
			HealProject.ProjectPointsRemaining = HealProject.BlocksRemaining * HealProject.BlockPointsRemaining;
			HealProject.UpdateWorkPerHour();
			HealProject.StartDateTime = `STRATEGYRULES.GameTime;

			if(HealProject.MakingProgress())
			{
				HealProject.SetProjectedCompletionDateTime(HealProject.StartDateTime);
			}
			else
			{
				// Set completion time to unreachable future
				HealProject.CompletionDateTime.m_iYear = 9999;
				HealProject.BlockCompletionDateTime.m_iYear = 9999;
			}
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
// Remove the project and the engineer from the room's repair slot
function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState; 
	local XComHeadquartersCheatManager CheatMgr;
		
	OrderInput.OrderType = eHeadquartersOrderType_UnitHealingCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));

	CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);
	if (CheatMgr == none || !CheatMgr.bGamesComDemo)
	{
		`HQPRES.Notify(Repl(ProjectCompleteNotification, "%UNIT", UnitState.GetName(eNameType_RankFull)), class'UIUtilities_Image'.const.EventQueue_Staff);
	}
}

//---------------------------------------------------------------------------------------
function array<WoundSeverity> GetWoundSeverities()
{
	local array<WoundSeverity> WoundSeverities, AllSeverities;
	local int Difficulty, idx;
	
	AllSeverities = class'X2StrategyGameRulesetDataStructures'.default.WoundSeverities;
	Difficulty = `DifficultySetting;

	for(idx = 0; idx < AllSeverities.Length; idx++)
	{
		if(AllSeverities[idx].Difficulty == Difficulty)
		{
			WoundSeverities.AddItem(AllSeverities[idx]);
		}
	}

	if(WoundSeverities.Length == 0)
	{
		`RedScreen("Couldn't find wound data for campaign difficulty. @gameplay -mnauta");
	}

	return WoundSeverities;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}
