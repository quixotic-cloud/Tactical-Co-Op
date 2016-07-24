//---------------------------------------------------------------------------------------
//  FILE:    KismetGameRulesetEventObserver.uc
//  AUTHOR:  David Burchanowski  --  1/27/2014
//  PURPOSE: GameState change observer listener for Kismet
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class KismetGameRulesetEventObserver extends Object
	implements(X2GameRulesetEventObserverInterface)
	dependson(X2TacticalGameRulesetDataStructures);

const UNIT_REMOVED_EVENTPRIORITY = 44; // Lowered priority below that of the Andromedon SwitchToRobot ability trigger (45).

// data that is cached exactly once (first access)
var private array<SeqEvent_UnitTouchedVolume> UnitTouchedVolumeEvents;
var private array<SeqEvent_UnitTouchedExit> UnitTouchedExitEvents;
var private array<SeqEvent_TeamHasNoPlayableUnitsRemaining> NoPlayableUnitsRemainingEvents;
var private array<SeqEvent_UnitAcquiredItem> UnitAcquiredItemEvents;
var private bool HasCachedData;
var private bool bInPostBuildGameState;

//Prevents the calls that detect this condition from triggering multiple times for the same game state frame.
var private array<XGPlayer> TriggeredNoPlayableUnits_PlayerList; 

event Initialize()
{	
	local X2EventManager EventManager;
	local Object ThisObj;

	ThisObj = self;

	EventManager = `XEVENTMGR;
	EventManager.RegisterForEvent(ThisObj, 'UnitUnconscious', CheckForUnconsciousUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	EventManager.RegisterForEvent(ThisObj, 'UnitDied', CheckForDeadUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	EventManager.RegisterForEvent(ThisObj, 'UnitBleedingOut', CheckForBleedingOutUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	EventManager.RegisterForEvent(ThisObj, 'UnitRemovedFromPlay', CheckForTeamHavingNoPlayableUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
	EventManager.RegisterForEvent(ThisObj, 'UnitChangedTeam', CheckForTeamHavingNoPlayableUnits, ELD_OnStateSubmitted, UNIT_REMOVED_EVENTPRIORITY);
}

event CacheGameStateInformation()
{
	TriggeredNoPlayableUnits_PlayerList.Length = 0;
}

event PreBuildGameStateFromContext(XComGameStateContext NewGameStateContext)
{

}

event InterruptGameState(XComGameState NewGameState)
{
	CacheEvents();

	CheckForUnitTouchedVolumeEvents(NewGameState);
	CheckForUnitTouchedExitEvents(NewGameState);
	CheckForCombatChangeEvents(NewGameState);
	CheckForSquadVisiblePoints(NewGameState);
}

event PostBuildGameState(XComGameState NewGameState)
{
	if (!bInPostBuildGameState)
	{
		bInPostBuildGameState = true;
		CacheEvents();

		CheckForPlayerChangeEvents(NewGameState);
		CheckForCombatChangeEvents(NewGameState);
		CheckForUnitAcquiredItem(NewGameState);
		bInPostBuildGameState = false;
	}
}

private function CacheEvents()
{
	local array<SequenceObject> Events;
	local SeqEvent_TeamHasNoPlayableUnitsRemaining NoPlayableUnitsEvent;
	local SeqEvent_UnitAcquiredItem UnitAcquiredItemEvent;
	local Sequence GameSeq;
	local int Index;

	if (HasCachedData) return;

	if (UnitTouchedVolumeEvents.Length > 0)
	{
		UnitTouchedVolumeEvents.Remove(0, UnitTouchedVolumeEvents.Length - 1);
	}	

	// Get the gameplay sequence.
	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	if (GameSeq == None) return;
	

	// find and cache all SeqEvent_TeamHasNoPlayableUnitsRemaining events
	GameSeq.FindSeqObjectsByClass(class'SeqEvent_TeamHasNoPlayableUnitsRemaining', true, Events);
	for (Index = 0; Index < Events.length; Index++)
	{
		NoPlayableUnitsEvent = SeqEvent_TeamHasNoPlayableUnitsRemaining(Events[Index]);
		NoPlayableUnitsRemainingEvents.AddItem(NoPlayableUnitsEvent);
	}

	// find and cache all SeqEvent_TeamHasNoPlayableUnitsRemaining events
	GameSeq.FindSeqObjectsByClass(class'SeqEvent_UnitAcquiredItem', true, Events);
	for (Index = 0; Index < Events.length; Index++)
	{
		UnitAcquiredItemEvent = SeqEvent_UnitAcquiredItem(Events[Index]);
		UnitAcquiredItemEvents.AddItem(UnitAcquiredItemEvent);
	}

	HasCachedData = true;
}

private function CheckForUnitTouchedVolumeEvents(XComGameState NewGameState)
{
	local array<MovedObjectStatePair> MovedStateObjects;
	local MovedObjectStatePair StateObject;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;
	local Box UnitExtents;
	local Box PrevUnitExtents;
	local SeqEvent_UnitTouchedVolume Event;

	if(UnitTouchedVolumeEvents.Length == 0) return; // nothing to do

	// check every moved object. If it's a unit, check to see if it touched anything we have an event for
	class'X2TacticalGameRulesetDataStructures'.static.GetMovedStateObjectList(NewGameState, MovedStateObjects);
	if(MovedStateObjects.Length == 0) return;

	foreach MovedStateObjects(StateObject)
	{
		PreviousUnit = XComGameState_Unit(StateObject.PreMoveState);
		Unit = XComGameState_Unit(StateObject.PostMoveState);
		if(Unit != none && PreviousUnit != none)
		{
			// get the location of this unit
			Unit.GetVisibilityExtents(UnitExtents);
			PreviousUnit.GetVisibilityExtents(PrevUnitExtents);
				
			// see if this unit's location is now inside of any volumes
			foreach UnitTouchedVolumeEvents(Event)
			{
				if(Event.TouchedVolume != none 
					&& Event.TouchedVolume.EncompassesPointExtent(UnitExtents.Min, UnitExtents.Max - UnitExtents.Min)
					&& !Event.TouchedVolume.EncompassesPointExtent(PrevUnitExtents.Min, PrevUnitExtents.Max - PrevUnitExtents.Min))
				{
					// we're inside this volume but weren't before. Touch!
					Event.FireEvent(Unit);
				}
			}
		}
	}
}

private function CheckForUnitTouchedExitEvents(XComGameState NewGameState)
{
	local array<MovedObjectStatePair> MovedStateObjects;
	local MovedObjectStatePair StateObject;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;
	local Box UnitExtents;
	local Box PrevUnitExtents;
	local SeqEvent_UnitTouchedExit Event;
	local XComGroupSpawn Exit;
	local bool bPreviousContains;
	local bool bCurrentContains;

	if(UnitTouchedExitEvents.Length == 0) return; // nothing to do

	Exit = `PARCELMGR.LevelExit;
	if(Exit == none || !Exit.IsVisible()) return; // nothing to do

	// check every moved object. If it's a unit, check to see if it touched the level exit
	class'X2TacticalGameRulesetDataStructures'.static.GetMovedStateObjectList(NewGameState, MovedStateObjects);
	if(MovedStateObjects.Length == 0) return;

	foreach MovedStateObjects(StateObject)
	{
		PreviousUnit = XComGameState_Unit(StateObject.PreMoveState);
		Unit = XComGameState_Unit(StateObject.PostMoveState);
		if(Unit != none && PreviousUnit != none)
		{
			// get the location of this unit
			Unit.GetVisibilityExtents(UnitExtents);
			PreviousUnit.GetVisibilityExtents(PrevUnitExtents);	

			bPreviousContains = Exit.IsBoxInside(PrevUnitExtents.Min, PrevUnitExtents.Max - PrevUnitExtents.Min);
			bCurrentContains = Exit.IsBoxInside(UnitExtents.Min, UnitExtents.Max - UnitExtents.Min);
			if( bCurrentContains && !bPreviousContains )
			{
				// we're inside the exit but weren't before. Touch!
				foreach UnitTouchedExitEvents(Event)
				{
					Event.FireEvent(Unit);
				}
			}
		}
	}
}

private function CheckForCombatChangeEvents(XComGameState NewGameState)
{	
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_BaseObject PreviousBaseState;
	local XComGameState_BaseObject CurrentBaseState;
	local XComGameState_Unit CurrentUnitState;
	local XComGameState_Unit PreviousUnitState;
	local int NumRedAlertUnitsPrevious;
	local int NumRedAlertUnitsCurrent;
	local XGBattle Battle;

	History = `XCOMHISTORY;
	Battle = `BATTLE;

	if( Battle != none && NewGameState.HistoryIndex > 0 )
	{


		//Count the number of red alert units immediately prior to NewGameState, and for NewGameState
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{

			History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, PreviousBaseState, CurrentBaseState, eReturnType_Reference, NewGameState.HistoryIndex);

			if( PreviousBaseState != none )
			{
				PreviousUnitState = XComGameState_Unit(PreviousBaseState);
				if (PreviousUnitState.GetCurrentStat(eStat_AlertLevel) > 1 && PreviousUnitState.IsAlive())
				{
					++NumRedAlertUnitsPrevious;
				}

			}
			
			if( CurrentBaseState != none )
			{
				CurrentUnitState = XComGameState_Unit(CurrentBaseState);
				if (CurrentUnitState.GetCurrentStat(eStat_AlertLevel) > 1 && CurrentUnitState.IsAlive())
				{
					++NumRedAlertUnitsCurrent;
				}
			}
		}

		if(NumRedAlertUnitsPrevious == 0 && NumRedAlertUnitsCurrent > 0)
		{
			Battle.TriggerGlobalEventClass(class'SeqEvent_OnCombatBegin', Battle);
		}
		else if(NumRedAlertUnitsPrevious > 0 && NumRedAlertUnitsCurrent == 0)
		{
			Battle.TriggerGlobalEventClass(class'SeqEvent_OnCombatEnd', Battle);
		}
	}	
}

private function CheckForPlayerChangeEvents(XComGameState NewGameState)
{
	local XComGameStateContext_TacticalGameRule Context;
	local XGBattle Battle;

	Context = XComGameStateContext_TacticalGameRule(NewGameState.GetContext());
	if(Context == none) return;

	Battle = `BATTLE;
	if(Battle == none) return;

	if(Context.GameRuleType == eGameRule_PlayerTurnBegin)
	{
		Battle.TriggerGlobalEventClass(class'SeqEvent_OnTurnBegin', Battle);
	}
	else if(Context.GameRuleType == eGameRule_PlayerTurnEnd)
	{
		Battle.TriggerGlobalEventClass(class'SeqEvent_OnTurnEnd', Battle);
	}
}

//Uses the event manager
private function EventListenerReturn CheckForBleedingOutUnits(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;

	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if(Unit.IsBleedingOut())
		{
			PreviousUnit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID,, NewGameState.HistoryIndex - 1));
			if(PreviousUnit != none && !PreviousUnit.IsBleedingOut())
			{
				class'SeqEvent_OnUnitBleedingOut'.static.FireEvent(Unit);
			}
		}
	}

	CheckForTeamHavingNoPlayableUnits(EventData, EventSource, NewGameState, '');

	return ELR_NoInterrupt;
}

//Uses the event manager
private function EventListenerReturn CheckForUnconsciousUnits(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;

	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if(Unit.IsUnconscious())
		{
			PreviousUnit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID,, NewGameState.HistoryIndex - 1));
			if(PreviousUnit != none && !PreviousUnit.IsUnconscious())
			{
				class'SeqEvent_OnUnitUnconscious'.static.FireEvent(Unit);
			}
		}
	}

	CheckForTeamHavingNoPlayableUnits(EventData, EventSource, NewGameState, '');

	return ELR_NoInterrupt;
}

//Uses the event manager
private function EventListenerReturn CheckForDeadUnits(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;
	local XComGameState_Unit SourceUnit;

	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(EventSource);

	foreach NewGameState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		// Make sure we only trigger the event on the source unit, because CheckForDeadUnits is called for every dead unit.
		if(Unit.IsDead() && SourceUnit != none && Unit.ObjectID == SourceUnit.ObjectID)
		{
			PreviousUnit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID,, NewGameState.HistoryIndex - 1));
			if(PreviousUnit != none && PreviousUnit.IsAlive())
			{
				if (PreviousUnit.GetMyTemplateName() != 'MimicBeacon') // Don't fire off event if its a MimicBeacon dieing so we prevent narrative about losing units from playing.
				{
					class'SeqEvent_OnUnitKilled'.static.FireEvent(Unit);
				}
			}
		}
	}

	CheckForTeamHavingNoPlayableUnits(EventData, EventSource, NewGameState, '');

	return ELR_NoInterrupt;
}

//Uses the event manager, but may also be called manually. If NewGameState is specified as 'none', then the system simply 
//checks whether the specified player has playable units rather than being edge triggered. This is used as a failsafe by
//the tactical game ruleset.
private function bool DidPlayerRunOutOfPlayableUnits(XGPlayer InPlayer, XComGameState NewGameState)
{	
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Unit PreviousUnit;
	local XComGameState_Unit RemovedUnit;
	local int ExamineHistoryFrameIndex;

	History = `XCOMHISTORY;	

	if(NewGameState != none)
	{
		ExamineHistoryFrameIndex = NewGameState.HistoryIndex;

		// find any unit on this team that was in play the previous state but not this one
		foreach NewGameState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			// Don't count turrets, ever.  Also ignore unselectable units (mimic beacons).
			if( Unit.IsTurret() || Unit.GetMyTemplate().bNeverSelectable )
				continue;

			//For units on our team, check if they recently died or became incapacitated.
			if (Unit.ControllingPlayer.ObjectID == InPlayer.ObjectID)
			{
				if (!Unit.IsAlive() || Unit.bRemovedFromPlay || Unit.IsIncapacitated())
				{
					// this unit is no longer playable. See if it was playable in the previous state
					PreviousUnit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID, , ExamineHistoryFrameIndex - 1));
					if (PreviousUnit.IsAlive() && !PreviousUnit.bRemovedFromPlay && !PreviousUnit.IsIncapacitated())
					{
						RemovedUnit = Unit;
						break;
					}
				}
			}
			else
			{
				//For units on the other team, check if they were stolen from our team (via mind-control, typically)
				PreviousUnit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID, , ExamineHistoryFrameIndex - 1));
				if (PreviousUnit.ControllingPlayer.ObjectID == InPlayer.ObjectID)
				{
					//This unit was taken by another team, but used to be on our team.
					RemovedUnit = Unit;
					break;
				}
			}

		}

		// no unit was removed for this player, so no need to continue checking the entire team
		if(RemovedUnit == none)
		{
			return false;
		}
	}	
	else
	{
		ExamineHistoryFrameIndex = -1;
	}

	// at least one unit was removed from play for this player on this state. If all other units
	// for this player are also out of play on this state, then this must be the state where
	// the last unit was removed.
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.ControllingPlayer.ObjectID == InPlayer.ObjectID && !Unit.GetMyTemplate().bIsCosmetic && !Unit.IsTurret() && !Unit.GetMyTemplate().bNeverSelectable )
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID, , ExamineHistoryFrameIndex));
			if( Unit == None || (Unit.IsAlive() && !Unit.bRemovedFromPlay && !Unit.IsIncapacitated()) )
			{
				return false;
			}
		}
	}

	// the alien team has units remaining if they have reinforcements already queued up
	if( InPlayer.m_eTeam == eTeam_Alien && AnyPendingReinforcements() )
	{
		return false;
	}

	// this player had a unit removed from play and all other units are also out of play.
	return true;
}

function bool AnyPendingReinforcements()
{
	local XComGameState_AIReinforcementSpawner AISPawnerState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISPawnerState)
	{
		break;
	}

	// true if there are any active reinforcement spawners
	return (AISPawnerState != None);
}

//Uses the event manager
private function EventListenerReturn CheckForTeamHavingNoPlayableUnits(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID)
{	
	local SeqEvent_TeamHasNoPlayableUnitsRemaining Event;
	local XComGameStateHistory History;
	local XComGameState_Player PlayerObject;
	local XGPlayer PlayerVisualizer;
	local bool bFired;

	if(NoPlayableUnitsRemainingEvents.Length == 0) return ELR_NoInterrupt; // nothing to do
	
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerObject)
	{
		PlayerVisualizer = XGPlayer(PlayerObject.GetVisualizer());		
		if( TriggeredNoPlayableUnits_PlayerList.Find(PlayerVisualizer) == -1 ) //See if we have already triggered for this player
		{
			bFired = DidPlayerRunOutOfPlayableUnits(PlayerVisualizer, NewGameState);
			if( bFired )		
			{
				TriggeredNoPlayableUnits_PlayerList.AddItem(PlayerVisualizer);
				foreach NoPlayableUnitsRemainingEvents(Event)
				{
					Event.FireEvent(PlayerVisualizer);
				}
			}
		}		
	}

	return ELR_NoInterrupt;
}

//Called by the tactical game rule set as a failsafe, once each time the unit actions phase ends
function CheckForTeamHavingNoPlayableUnitsExternal()
{
	CheckForTeamHavingNoPlayableUnits(none, none, none, '');
}

private function CheckForUnitAcquiredItem(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Unit PreviousUnitState;
	local StateObjectReference CurrentStateItemReference;
	local XComGameState_Item CurrentStateItem;
	local SeqEvent_UnitAcquiredItem Event;

	if(UnitAcquiredItemEvents.Length == 0) return; // nothing to do
	
	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		PreviousUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID,, NewGameState.HistoryIndex - 1));
		if(PreviousUnitState == none) continue;

		// check if any items weren't in their state on the previous frame
		foreach UnitState.InventoryItems(CurrentStateItemReference)
		{
			if(PreviousUnitState.InventoryItems.Find('ObjectID', CurrentStateItemReference.ObjectID) == INDEX_NONE)
			{
				// this item is new this frame, so fire all events with it's info
				CurrentStateItem = XComGameState_Item(History.GetGameStateForObjectID(CurrentStateItemReference.ObjectID,, NewGameState.HistoryIndex));
				`assert(CurrentStateItem != none);
				
				foreach UnitAcquiredItemEvents(Event)
				{
					Event.FireEvent(UnitState, CurrentStateItem);
				}
			}
		}
	}
}

private function CheckForSquadVisiblePoints(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_SquadVisiblePoint SquadVisiblePoint; 

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_SquadVisiblePoint', SquadVisiblePoint)
	{
		SquadVisiblePoint = XComGameState_SquadVisiblePoint(History.GetGameStateForObjectID(SquadVisiblePoint.ObjectID));
		SquadVisiblePoint.CheckForVisibilityChanges(NewGameState);
	}
}

