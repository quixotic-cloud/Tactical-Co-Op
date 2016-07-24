//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_RevealAI.uc
//  AUTHOR:  Ryan McFall  --  3/5/2014
//  PURPOSE: This context handles the AI reflex moves that occur when X-Com is noticed
//           by enemies.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_RevealAI extends XComGameStateContext;

enum ERevealAIEvent
{
	eRevealAIEvent_Begin,
	eRevealAIEvent_End
};

var ERevealAIEvent RevealAIEvent;
var array<int> RevealedUnitObjectIDs;
var array<int> SurprisedScamperUnitIDs;
var array<int> ConcealmentBrokenUnits;
var int CausedRevealUnit_ObjectID;

var XComNarrativeMoment FirstSightingMoment;  // When our first sighting is also our pod reveal - Avatar / Codex
var bool bDoSoldierVO;								// If this is true, we should do solider VO because we havn't seen this enemy yet

// If the leader of the revealed group is a type of enemy that has never been encountered before in this campaign, store its
// character template here.
var X2CharacterTemplate FirstEncounterCharacterTemplate;

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	local XComGameState NewGameState;
	local XComGameStateContext_RevealAI NewContext;
	local XComGameState_Unit UnitState;
	local XComGameState_AIGroup GroupState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local X2CharacterTemplate CharacterTemplate;
	local int Index, iEvents;
	local int RevealedUnitObjectID;
	local X2EventManager EventManager;

	History = `XCOMHISTORY;

	switch(RevealAIEvent)
	{
	case eRevealAIEvent_Begin:
		NewGameState = History.CreateNewGameState(true, self);
		NewContext = XComGameStateContext_RevealAI(NewGameState.GetContext());
		for( Index = 0; Index < RevealedUnitObjectIDs.Length; ++Index )
		{
			RevealedUnitObjectID = RevealedUnitObjectIDs[Index];

			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', RevealedUnitObjectID));
			UnitState.ReflexActionState = eReflexActionState_AIScamper;
			UnitState.bTriggerRevealAI = false; //Mark this AI as having already triggered a reveal
			NewGameState.AddStateObject(UnitState);

			`XACHIEVEMENT_TRACKER.OnRevealAI(NewGameState, RevealedUnitObjectID);

			if(GroupState == none)
			{
				GroupState = UnitState.GetGroupMembership();
			}

			CharacterTemplate = UnitState.GetMyTemplate();
			
			// try to find a unit that the player hasn't seen yet to play the reveal on
			if (NewContext.FirstSightingMoment == none)
			{
				XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
				if(XComHQ != none && !XComHQ.HasSeenCharacterTemplate(CharacterTemplate))
				{
					//Update the HQ state to record that we saw this enemy type
					XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));					
					XComHQ.AddSeenCharacterTemplate(CharacterTemplate);
					NewGameState.AddStateObject(XComHQ);

					//Store this in the context for easy access in the visualizer action
					if(`CHEATMGR == none || !`CHEATMGR.DisableFirstEncounterVO)
					{
						NewContext.FirstSightingMoment = CharacterTemplate.SightedNarrativeMoments[0];
						NewContext.FirstEncounterCharacterTemplate = CharacterTemplate;
					}
				}
			}

			// Trigger any sighted events for this unit, this after EverSightedByEnemy is set to true they won't be triggered by sighting the unit
			for (iEvents = 0; iEvents < CharacterTemplate.SightedEvents.Length; iEvents++)
			{
				`XEVENTMGR.TriggerEvent(CharacterTemplate.SightedEvents[iEvents], , , NewGameState);
			}
		}

		//Indicate that this group has processed its scamper
		GroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(GroupState.Class, GroupState.ObjectID));
		GroupState.EverSightedByEnemy = true;
		GroupState.bPendingScamper = false;
		NewGameState.AddStateObject(GroupState);

		EventManager = `XEVENTMGR;
		EventManager.TriggerEvent('ScamperBegin', , , NewGameState);

		break;
	case eRevealAIEvent_End:
		NewGameState = History.CreateNewGameState(true, self);
		NewContext = XComGameStateContext_RevealAI(NewGameState.GetContext());
		NewContext.SetVisualizationFence(true);
		for( Index = 0; Index < RevealedUnitObjectIDs.Length; ++Index )
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', RevealedUnitObjectIDs[Index]));			
			UnitState.ReflexActionState = eReflexActionState_None;
			NewGameState.AddStateObject(UnitState);
		}
		break;
	}

	return NewGameState;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{	
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local XComGameState_BattleData BattleState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	BattleState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	switch(RevealAIEvent)
	{
	case eRevealAIEvent_Begin:
		BuildTrack.StateObject_OldState = BattleState;
		BuildTrack.StateObject_NewState = BattleState;
		BuildTrack.TrackActor = none;
		class'X2Action_RevealAIBegin'.static.AddToVisualizationTrack(BuildTrack, self);

		VisualizationTracks.AddItem(BuildTrack);

		//Add an empty track for each unit that is scampering so that the visualization blocks are sequenced
		foreach AssociatedState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			BuildTrack = EmptyTrack;
			History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
			BuildTrack.TrackActor = History.GetVisualizer(UnitState.ObjectID);
			VisualizationTracks.AddItem(BuildTrack);
		}

		if( CausedRevealUnit_ObjectID > 0 )
		{
			//Add an empty track for the unit that caused the reveal
			BuildTrack = EmptyTrack;
			History.GetCurrentAndPreviousGameStatesForObjectID(CausedRevealUnit_ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
			// Prevent crash on scampering from dropping in units.
			if( BuildTrack.StateObject_OldState == None )
				BuildTrack.StateObject_OldState = BuildTrack.StateObject_NewState;
			`Assert(BuildTrack.StateObject_OldState != None);
			BuildTrack.TrackActor = History.GetVisualizer(CausedRevealUnit_ObjectID);

			VisualizationTracks.AddItem(BuildTrack);
		}

		break;
	case eRevealAIEvent_End:
		BuildTrack.StateObject_OldState = BattleState;
		BuildTrack.StateObject_NewState = BattleState;
		BuildTrack.TrackActor = none;
		class'X2Action_RevealAIEnd'.static.AddToVisualizationTrack(BuildTrack, self);
		VisualizationTracks.AddItem(BuildTrack);

		//Add an empty track for each unit that is scampering so that the visualization blocks are sequenced
		foreach AssociatedState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			BuildTrack = EmptyTrack;
			History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
			BuildTrack.TrackActor = History.GetVisualizer(UnitState.ObjectID);
			VisualizationTracks.AddItem(BuildTrack);
		}

		if(CausedRevealUnit_ObjectID > 0)
		{
			//Add an empty track for the unit that caused the reveal
			BuildTrack = EmptyTrack;
			History.GetCurrentAndPreviousGameStatesForObjectID(CausedRevealUnit_ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
			// Prevent crash on scampering from dropping in units.
			if(BuildTrack.StateObject_OldState == None)
				BuildTrack.StateObject_OldState = BuildTrack.StateObject_NewState;
			`Assert(BuildTrack.StateObject_OldState != None);
			BuildTrack.TrackActor = History.GetVisualizer(CausedRevealUnit_ObjectID);
			VisualizationTracks.AddItem(BuildTrack);
		}

		break;
	}
}

static function XComGameStateContext_ChangeContainer CreateEmptyChangeContainer()
{
	return XComGameStateContext_ChangeContainer(CreateXComGameStateContext());
}

// Debug-only function used in X2DebugHistory screen.
function bool HasAssociatedObjectID(int ID)
{
	if( RevealedUnitObjectIDs.Find(ID) != INDEX_NONE
	   || SurprisedScamperUnitIDs.Find(ID) != INDEX_NONE
	   || ConcealmentBrokenUnits.Find(ID) != INDEX_NONE
	   || CausedRevealUnit_ObjectID == ID)
	   return true;

	return false;
}


function string SummaryString()
{
	return "XComGameStateContext_RevealAI";
}