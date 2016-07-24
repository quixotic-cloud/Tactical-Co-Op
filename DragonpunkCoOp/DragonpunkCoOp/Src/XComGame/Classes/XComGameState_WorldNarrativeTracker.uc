//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_WorldNarrativeTracker.uc
//  AUTHOR:  David Burchanowski  --  6/2/2015
//  PURPOSE: Singleton game state that records which world narrative actors have played in
//           in a given playthrough
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameState_WorldNarrativeTracker extends XComGameState_BaseObject
	config(GameCore);

// How many turns must elapse before another narrative can play?
var private const config int TurnCooldown;

// How many missions must be played before another narrative can play?
var private const config int MissionCooldown;

// How many turns until we can play another narrative?
var private int RemainingTurnCooldown;

// How many missions until we can play another narrative?
var private int RemainingMissionCooldown;

// list of pathnames for the narrative objects that we have seen
var private array<name> SeenNarratives;

function OnBeginTacticalPlay()
{
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameState NewGameState;
	local XComGameState_WorldNarrativeTracker NewTrackerState;

	super.OnBeginTacticalPlay();

	ThisObj = self;

	// register for an event to check visibility when units stop moving
	EventManager = `XEVENTMGR;
	EventManager.RegisterForEvent(ThisObj, 'UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted);

	// register the player turn event to do the turn cooldown if needed
	if(TurnCooldown > 0)
	{
		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted);
	}

	// and decrement the mission cooldown
	if(RemainingMissionCooldown > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("XComGameState_WorldNarrativeTracker: RemainingMissionCooldown tick.");
		NewTrackerState = XComGameState_WorldNarrativeTracker(NewGameState.CreateStateObject(class'XComGameState_WorldNarrativeTracker', ObjectID));
		NewTrackerState.RemainingMissionCooldown = RemainingMissionCooldown - 1;
		NewGameState.AddStateObject(NewTrackerState);
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
}

function OnEndTacticalPlay()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnEndTacticalPlay();

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.UnRegisterFromEvent(ThisObj, 'UnitMoveFinished');
	EventManager.UnRegisterFromEvent(ThisObj, 'PlayerTurnBegun');
}

private function BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameState_WorldNarrativeActor NarrativeActorState;
	local VisualizationTrack BuildTrack;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldNarrativeActor', NarrativeActorState)
	{
		BuildTrack.StateObject_OldState = NarrativeActorState;
		BuildTrack.StateObject_NewState = NarrativeActorState;
		class'X2Action_PlayWorldNarrative'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
		OutVisualizationTracks.AddItem(BuildTrack);
	}
}

private function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_WorldNarrativeTracker NewTrackerState;

	if(XComGameState_Player(EventSource).GetTeam() == eTeam_XCom && RemainingTurnCooldown > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("XComGameState_WorldNarrativeTracker: RemainingTurnCooldown tick.");
		NewTrackerState = XComGameState_WorldNarrativeTracker(NewGameState.CreateStateObject(class'XComGameState_WorldNarrativeTracker', ObjectID));
		NewTrackerState.RemainingTurnCooldown = RemainingTurnCooldown - 1;
		NewGameState.AddStateObject(NewTrackerState);
		`TACTICALRULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

private function bool IsWithinSightRadiusPercentage(XComGameState_WorldNarrativeActor NarrativeState, XComGameState_Unit UnitState)
{
	local XComWorldData WorldData;
	local Vector NarrativeLocation;
	local Vector UnitLocation;
	local float MaxDistance;
	
	WorldData = `XWORLD;

	NarrativeLocation = WorldData.GetPositionFromTileCoordinates(NarrativeState.TileLocation);
	UnitLocation = WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation);

	MaxDistance = UnitState.GetVisibilityRadius() * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER * NarrativeState.GetSightRangePct();

	return (MaxDistance * MaxDistance) > VSizeSq(NarrativeLocation - UnitLocation);
}

// handler to check if a narrative actor has been seen, and build the game state and visualization if so
private function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2GameRulesetVisibilityManager VisManager;
	local XComGameStateHistory History;
	local X2TacticalGameRuleset Rules;

	local X2WorldNarrativeActor Visualizer;

	local XComGameState NewGameState;
	local XComGameState_Unit SourceUnit;
	local GameRulesCache_VisibilityInfo CurrentVisibility;
	local XComGameState_WorldNarrativeActor NarrativeActorState;
	local XComGameState_WorldNarrativeActor BestNarrativeActorState;
	local int BestNarrativeActorStatePriority;
	local XComGameState_WorldNarrativeTracker NewTrackerState;

	// not if we are still on cooldown
	if(RemainingTurnCooldown > 0 || RemainingMissionCooldown > 0)
	{
		return ELR_NoInterrupt;
	}

	// make sure the unit that moved is an xcom unit. The aliens already know all about their nefarious deeds.
	SourceUnit = XComGameState_Unit(EventSource);
	if(SourceUnit == none || SourceUnit.GetTeam() != eTeam_XCom)
	{
		return ELR_NoInterrupt;
	}

	// now iterate over each of the narrative actor stats on the current map, and see which, if any of them,
	// can be fired. If more than one can fire, play the one with the highest priority
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_WorldNarrativeActor', NarrativeActorState)
	{
		Visualizer = X2WorldNarrativeActor(NarrativeActorState.GetVisualizer());
		if(Visualizer == none || Visualizer.NarrativeMoment == none)
		{
			continue;
		}

		// check to see if this narrative has already been seen
		if(SeenNarratives.Find(Visualizer.NarrativeMoment.Name) != INDEX_NONE)
		{
			continue;
		}

		// if this actor is lower priority than the current best, ignore it
		if(BestNarrativeActorState != None && BestNarrativeActorStatePriority >= Visualizer.NarrativePriority)
		{
			continue;
		}

		if (!Visualizer.bPlayEvenIfInterrupted && GameState.GetContext().InterruptionStatus != eInterruptionStatus_None)
		{
			continue;
		}

		if (Visualizer.bPlayOnlyIfConcealed && !SourceUnit.IsConcealed())
		{
			continue;
		}

		if (!SomeUnitHasAbility(Visualizer.SomeUnitHasRequiredAbilityName))
		{
			continue;
		}

		// if the just moved unit can see this state, then this is our new best
		VisManager = `TACTICALRULES.VisibilityMgr;
		VisManager.GetVisibilityInfo(SourceUnit.ObjectID, NarrativeActorState.ObjectID, CurrentVisibility, GameState.HistoryIndex);
		if(CurrentVisibility.bVisibleGameplay && IsWithinSightRadiusPercentage(NarrativeActorState, SourceUnit))
		{
			BestNarrativeActorState = NarrativeActorState;
			BestNarrativeActorStatePriority = Visualizer.NarrativePriority;
		}
	}

	if(BestNarrativeActorState != none) // we have selected a narrative moment to play
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("World Narrative Seen");
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualization;

		// we don't actually need to change this state, but we do need to include it so that the game knows which
		// state to visualize
		// Update: Now we store the source unit - for SoldierVO type XComNarrativeMoments  mdomowicz 2015_10_08
		NarrativeActorState = XComGameState_WorldNarrativeActor(NewGameState.CreateStateObject(class'XComGameState_WorldNarrativeActor', BestNarrativeActorState.ObjectID));
		NarrativeActorState.UnitThatSawMeRef = SourceUnit.GetReference();
		NewGameState.AddStateObject(NarrativeActorState);

		// also mark this narrative as having been seen in the tracker so we don't see it again this playthrough
		NewTrackerState = XComGameState_WorldNarrativeTracker(NewGameState.CreateStateObject(class'XComGameState_WorldNarrativeTracker', ObjectID));
		NewTrackerState.SeenNarratives.AddItem(X2WorldNarrativeActor(BestNarrativeActorState.GetVisualizer()).NarrativeMoment.Name);
		NewTrackerState.RemainingTurnCooldown = TurnCooldown;
		NewTrackerState.RemainingMissionCooldown = MissionCooldown;
		NewGameState.AddStateObject(NewTrackerState);

		Rules = `TACTICALRULES;
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("XComGameState_WorldNarrativeActor: Unable to submit game state.");
		}
	}

	return ELR_NoInterrupt;
}

function bool SomeUnitHasAbility(Name AbilityName)
{
	local XComGameState_Unit UnitState;

	if (AbilityName == '')
		return true;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
	{
		if (UnitState.GetTeam() == eTeam_XCom)
		{
			if (UnitState.HasSoldierAbility(AbilityName))
			{
				return true;
			}
		}
	}

	return false;
}