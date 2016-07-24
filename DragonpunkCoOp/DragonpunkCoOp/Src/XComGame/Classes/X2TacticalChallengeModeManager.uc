//---------------------------------------------------------------------------------------
//  FILE:    X2TacticalChallengeModeManager.uc
//  AUTHOR:  Timothy Talley  --  11/24/2014
//  PURPOSE: Created for the Tactical Game. Responds to ruleset events to tell the player
//           where they stand in relation to other players.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TacticalChallengeModeManager extends Actor
	implements(X2VisualizationMgrObserverInterface)
	dependson(X2ChallengeModeDataStructures)
	native(Core);

struct native PendingEventType
{
	var EChallengeModeEventType         EventType;
	var int								Turn;
	var int								NumPlayersPrior;
	var int								NumPlayersCurrent;
	var int								NumPlayersSubsequent;
};
var array<PendingEventType>				m_SeenEvents;	                // List of Events that have been experienced in this challenge mode.
var int									m_LastViewedEvent;              // Index of the last event in the m_SeenEvents array.

//
// Event Data
var int									m_LastTurnUpdated;              // The turn in which the combined turns has been added together
var int									m_CurrentTurn;                  // The combined map should be additive up to this point
var array<int>							m_TurnEventMap;                 // Entries of Event (index) and Turn (value) filled in when an event occurs.
var array<int>							m_CurrentCombinedTurnEventMap;  // Entries of Event (index) and Number of players (value), cumulative update of all previous turns
var array<int>							m_CurrentTotalTurnEventMap;     // Entries of Event (index) and Number of players (value), total number of players to have this event on any turn

//
// Cached References
var XComGameStateHistory                History;
var XComOnlineEventMgr                  OnlineMgr;
var X2EventManager                      EventManager;

//==============================================================================
//		INIT:
//==============================================================================
function Init()
{
	local Object ThisObj;

	SubscribeToOnCleanupWorld();

	ThisObj = self;
	History = `XCOMHISTORY;
	EventManager = `XEVENTMGR;
	OnlineMgr = `ONLINEEVENTMGR;

	EventManager.RegisterForEvent( ThisObj, 'UnitDied', OnUnitDied, ELD_OnStateSubmitted );
	EventManager.RegisterForEvent( ThisObj, 'PlayerTurnEnded', OnPlayerTurnEnded, ELD_OnStateSubmitted );
	EventManager.RegisterForEvent( ThisObj, 'MissionObjectiveMarkedCompleted', OnObjectiveCompleted, ELD_OnStateSubmitted );

	//And subscribe to any future changes 
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	ResetAllData();
}

// --------------------------------------

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle();

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	if (AssociatedGameState.HistoryIndex == History.GetCurrentHistoryIndex())
	{
		`log(`location @ `ShowVar(m_SeenEvents.Length) @ `ShowVar(m_LastViewedEvent), , 'XCom_Online');
		if (m_SeenEvents.Length > m_LastViewedEvent)
		{
			XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres.UIChallengeModeEventNotify();
		}
	}
}


//==============================================================================
//		EXTERNAL INTERFACE:
//==============================================================================
function ResetAllData()
{
	m_SeenEvents.Length = 0;
	m_LastViewedEvent = 0;

	m_TurnEventMap.Length = 0;
	m_TurnEventMap.Add(ECME_MAX);

	m_CurrentCombinedTurnEventMap.Length = 0;
	m_CurrentCombinedTurnEventMap.Add(ECME_MAX);

	m_LastTurnUpdated = 0;
	m_CurrentTurn = class'XComGameState_ChallengeData'.static.CalcCurrentTurnNumber();
	UpdateTotalEventModeMap();
	UpdateEventModeMap();
}

function int NumSeenEvents()
{
	return m_SeenEvents.Length;
}

function bool HasUnviewedEvents()
{
	return m_LastViewedEvent < m_SeenEvents.Length - 1;
}

function bool GetCurrentEvent(out PendingEventType PendingEvent)
{
	if (m_LastViewedEvent >= 0 && m_LastViewedEvent < m_SeenEvents.Length)
	{
		PendingEvent = m_SeenEvents[m_LastViewedEvent];
		return true;
	}
	return false;
}

function bool HasPreviousEvent()
{
	return (m_LastViewedEvent > 0);
}

function bool PreviousEvent()
{
	if (HasPreviousEvent())
	{
		--m_LastViewedEvent;
		return true;
	}
	return false;
}

function bool HasNextEvent()
{
	return (m_LastViewedEvent < m_SeenEvents.Length-1);
}

function bool NextEvent()
{
	if (HasNextEvent())
	{
		++m_LastViewedEvent;
		return true;
	}
	return false;
}

function bool GetSeenEvent(int index, out PendingEventType PendingEvent)
{
	if ((index >= 0) && (index < m_SeenEvents.Length))
	{
		PendingEvent = m_SeenEvents[index];
		return true;
	}
	return false;
}

function ViewAllPendingEvents()
{
	m_LastViewedEvent = m_SeenEvents.Length;
}

//==============================================================================
//		HELPER FUNCTIONALITY:
//==============================================================================
function UpdateTotalEventModeMap()
{
	local int UpdateTurn, UpdateEvent, MaxTurns;

	m_CurrentTotalTurnEventMap.Length = 0;
	m_CurrentTotalTurnEventMap.Add(ECME_MAX);
	MaxTurns = OnlineMgr.m_ChallengeModeEventMap.Length / ECME_MAX;
	for (UpdateTurn = 0; UpdateTurn < MaxTurns; ++UpdateTurn)
	{
		// Build Current Map
		for (UpdateEvent = 0; UpdateEvent < ECME_MAX; ++UpdateEvent)
		{
			m_CurrentTotalTurnEventMap[UpdateEvent] += OnlineMgr.m_ChallengeModeEventMap[(UpdateEvent * MaxTurns) + UpdateTurn];
		}
	}
}

function UpdateEventModeMap()
{
	local int UpdateTurn, UpdateEvent, MaxTurns;

	MaxTurns = OnlineMgr.m_ChallengeModeEventMap.Length / ECME_MAX;
	`log(`location @ `ShowVar(m_CurrentTurn) @ `ShowVar(m_LastTurnUpdated) @ `ShowVar(MaxTurns),,'XCom_Online');

	if (m_LastTurnUpdated > m_CurrentTurn)
	{
		// Countdown until m_CurrentTurn is > m_LastTurnUpdated by only 1
		for (UpdateTurn = m_LastTurnUpdated; UpdateTurn >= m_CurrentTurn && UpdateTurn >= 0; --UpdateTurn)
		{
			for (UpdateEvent = 0; UpdateEvent < ECME_MAX; ++UpdateEvent)
			{
				m_CurrentCombinedTurnEventMap[UpdateEvent] -= OnlineMgr.m_ChallengeModeEventMap[(UpdateEvent * MaxTurns) + UpdateTurn];
			}
		}
	}
	else
	{
		for (UpdateTurn = m_LastTurnUpdated; UpdateTurn < m_CurrentTurn; ++UpdateTurn)
		{
			for (UpdateEvent = 0; UpdateEvent < ECME_MAX; ++UpdateEvent)
			{
				m_CurrentCombinedTurnEventMap[UpdateEvent] += OnlineMgr.m_ChallengeModeEventMap[(UpdateEvent * MaxTurns) + UpdateTurn];
			}
		}
	}
	m_LastTurnUpdated = m_CurrentTurn;
}

function OnEventTriggered(EChallengeModeEventType EventType, int Turn, optional bool bOverrideValue=false)
{
	local int MaxTurns, EventIdx, SeenIdx;
	local bool bAddNew;

	SeenIdx = -1;

	bAddNew = (m_TurnEventMap[EventType] == 0);
	if ((!bAddNew) && bOverrideValue)
	{
		for(EventIdx = 0; EventIdx < m_SeenEvents.Length; ++EventIdx)
		{
			if (m_SeenEvents[EventIdx].EventType == EventType)
			{
				m_LastViewedEvent = EventIdx;
				SeenIdx = EventIdx;
				break;
			}
		}
	}
	else if (bAddNew)
	{
		SeenIdx = m_SeenEvents.Length;
		m_SeenEvents.Add(1);
	}

	if (SeenIdx != -1)
	{
		m_CurrentTurn = Max(Turn - 1, 0);
		UpdateEventModeMap(); // update the Combined Map for the Prior / Current /Subsequent data

		MaxTurns = OnlineMgr.m_ChallengeModeEventMap.Length / ECME_MAX;
		m_SeenEvents[SeenIdx].EventType = EventType;
		m_SeenEvents[SeenIdx].Turn = Turn;
		m_SeenEvents[SeenIdx].NumPlayersPrior = m_CurrentCombinedTurnEventMap[EventType];
		m_SeenEvents[SeenIdx].NumPlayersCurrent = OnlineMgr.m_ChallengeModeEventMap[(EventType * MaxTurns) + Turn];
		m_SeenEvents[SeenIdx].NumPlayersSubsequent = m_CurrentTotalTurnEventMap[EventType] - (m_SeenEvents[SeenIdx].NumPlayersCurrent + m_SeenEvents[SeenIdx].NumPlayersPrior);
		`log(`location @ `ShowEnum(EChallengeModeEventType, m_SeenEvents[SeenIdx].EventType, EventType) @ `ShowVar(m_SeenEvents[SeenIdx].Turn) @ `ShowVar(m_SeenEvents[SeenIdx].NumPlayersPrior) @ `ShowVar(m_SeenEvents[SeenIdx].NumPlayersCurrent) @ `ShowVar(m_SeenEvents[SeenIdx].NumPlayersSubsequent),,'XCom_Online');

		// Update the Event Map to include the turn in which the event was seen - only do it once.
		m_TurnEventMap[EventType] = Turn + 1; // Adding 1 here, since people typically do not see the first turn as turn 0.
	}
}

//==============================================================================
//		EVENT HANDLERS:
//==============================================================================
function EventListenerReturn OnUnitDied(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit Unit, IterUnit;
	local int DeadUnitCount;
	local ETeam UnitTeam;

	Unit = XComGameState_Unit(EventData);
	UnitTeam = Unit.GetTeam();
	foreach History.IterateByClassType(class'XComGameState_Unit', IterUnit)
	{
		if (IterUnit.IsDead() && IterUnit.GetTeam() == UnitTeam)
		{
			++DeadUnitCount;
		}
	}
	switch(UnitTeam)
	{
	case eTeam_XCom:
		if (DeadUnitCount >= 1)
		{
			OnEventTriggered(ECME_FirstXComKIA, m_CurrentTurn);
		}
		break;
	case eTeam_Alien:
		if (DeadUnitCount >= 10)
		{
			OnEventTriggered(ECME_10EnemiesKIA, m_CurrentTurn);
		}
		else if (DeadUnitCount >= 1)
		{
			OnEventTriggered(ECME_FirstAlienKill, m_CurrentTurn);
		}
		break;
	default:
		break;
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn OnPlayerTurnEnded(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_Player PlayerState;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	PlayerState = XComGameState_Player(EventData);
	// Last player's turn ended
	if (BattleData.PlayerTurnOrder[BattleData.PlayerTurnOrder.Length-1].ObjectID == PlayerState.ObjectID)
	{
		++m_CurrentTurn;
		UpdateEventModeMap();
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn OnObjectiveCompleted(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	OnEventTriggered(ECME_MissionObjectiveComplete, m_CurrentTurn);
	return ELR_NoInterrupt;
}

//==============================================================================
//		CLEANUP:
//==============================================================================
simulated event OnCleanupWorld()
{
	Cleanup();

	super.OnCleanupWorld();
}

simulated event Destroyed() 
{
	UnsubscribeFromOnCleanupWorld();
	Cleanup();

	super.Destroyed();
}

simulated private function Cleanup()
{
	local Object ThisObj;

	ThisObj = self;	
	EventManager.UnRegisterFromEvent( ThisObj, 'UnitDied' );
	EventManager.UnRegisterFromEvent( ThisObj, 'PlayerTurnEnded' );
	EventManager.UnRegisterFromEvent( ThisObj, 'MissionObjectiveStatusUpdated' );
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
defaultproperties
{

}