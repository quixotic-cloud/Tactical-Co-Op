//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMultiplayerHUD_TurnTimer.uc
//  AUTHOR:  Sam Batista
//  PURPOSE: Displays the remaining turn time for each player for multiplayer games
//
//  Plan of action:
//    - Setup a timer to react to the switching of turns
//    - Whenever a new turn starts, switch the UI to represent that player's time
//    - Start the timer whenever the ruleset is waiting for player input
//    - Pause the timer whenever the ruleset is no longer waiting for input
//    - Whenever the timer expires, activate the end-turn ability automatically
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class UIMultiplayerHUD_TurnTimer extends UIPanel;

//
// Labels
var localized string        m_strTurnTimerLabel;
var localized string        m_strPlayerTurnLabel;
var localized string        m_strOpponentTurnLabel;

//
// Run-time Data
var float                   m_fLastUpdateTime;
var float                   m_fTimeElapsed;
var int                     m_ResetCount;
var bool                    m_bSetupEvents;
var bool                    m_bTimeEnded;

//
// Cached Objects
var XComGameStateHistory    m_kHistory;
var bool					m_bTimeDataAvailable;    //This will be set to TRUE if the timer data state object can be found. Since this
													 //state object is added to the start state for the modes in which it is used, a failure
													 //to find it indicates that further processing is pointless

simulated function UIMultiplayerHUD_TurnTimer InitTurnTimer()
{
	
	InitPanel();
	return self;
}

// Flash side is initialized.
simulated function OnInit()
{		
	super.OnInit();
	UpdateCache();
}

simulated event Tick(float DeltaTime)
{
	local bool bTimeExpired;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameState_TimerData Timer;

	if (m_bTimeEnded)
		return;

	Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if (CheckDependencies())
	{
		TacticalRules = `TACTICALRULES;
		if (TacticalRules.IsWaitingForNewStates())
		{
			m_fTimeElapsed += DeltaTime;
			RefreshCounter();

			bTimeExpired = m_fTimeElapsed > Timer.TimeLimit;
			if (bTimeExpired)
			{
				ExpireTimer();
			}
		}
	}
	else if (m_bTimeDataAvailable)
	{
		m_fLastUpdateTime += DeltaTime;
		if (m_fLastUpdateTime >= 0.5) // Update only every half-second
		{
			UpdateCache();
			m_fLastUpdateTime = 0;
		}
	}
}

simulated function UpdateCache()
{
	local XComGameState_TimerData Timer;

	m_kHistory = `XCOMHISTORY;
	Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if (Timer == none)
	{
		Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
		if (Timer != none)
		{
			Timer = Timer;
			SetupTimerEvents();
			OnTurnChange();
		}
		else
		{
			m_bTimeDataAvailable = false;
		}
	}
}

simulated function OnTurnChange()
{
	local bool bIsLocalTurn;

	bIsLocalTurn = IsLocalPlayerTurn();

	if(bIsLocalTurn)
		AS_SetCounterText(m_strTurnTimerLabel, m_strPlayerTurnLabel);
	else
		AS_SetCounterText(m_strTurnTimerLabel, m_strOpponentTurnLabel);
	RefreshCounter();
}

simulated function RefreshCounter()
{
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if( Timer != none )
	{
		AS_SetCounterTimer(Timer.GetCurrentTime());
		AS_SetCounterTimer(1337);
		Show();
	}
	else
	{
		AS_HideCounter();
		Hide();
	}
}

// Delays call to OnInit until this function returns true
simulated function bool CheckDependencies()
{
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	return m_bSetupEvents && `TACTICALRULES != none && Timer != none && m_kHistory != none;
}

//--------------------------------------------------------------------------------------- 
// Timer Helper Functionality
//--------------------------------------------------------------------------------------- 
simulated function bool IsLocalPlayerTurn()
{
	local X2TacticalGameRuleset TacticalRules;
	TacticalRules = `TACTICALRULES;
	return TacticalRules.GetCachedUnitActionPlayerRef().ObjectID == TacticalRules.GetLocalClientPlayerObjectID();
}

function bool IsLocalPlayer(int PlayerObjectID)
{
	local X2TacticalGameRuleset TacticalRules;
	TacticalRules = `TACTICALRULES;
	return PlayerObjectID == TacticalRules.GetLocalClientPlayerObjectID();
}

//--------------------------------------------------------------------------------------- 
// Timer Events & Callbacks
//--------------------------------------------------------------------------------------- 
function ExpireTimer()
{
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));;

	switch (Timer.ResetType)
	{
		case EGSTRT_ResetCount:
			ResetTimer();
			break;
		case EGSTRT_TimeEnd:
			EndTimer();
			break;
		case EGSTRT_PerTurn:
			ResetTimer();
			break;
		case EGSTRT_None:
		default:
			EndTimer();
			break;
	}
}

function ResetTimer()
{
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));;

	++m_ResetCount;
	if ((Timer.ResetCount != 0) && (m_ResetCount >= Timer.ResetCount))
	{
		EndTimer();
	}
	else
	{
		switch(Timer.TimerType)
		{
		case EGSTT_RealTime:
			m_fTimeElapsed = 0;
			break;
		case EGSTT_StrategyTime:
		case EGSTT_TurnCount:
		default:
			break;
		}
	}
}

function EndTimer()
{
	m_bTimeEnded = true;
}

function SetupTimerEvents()
{
	local X2EventManager  EventManager;
	local Object ThisObj;
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));;

	if (!m_bSetupEvents && Timer.ResetType == EGSTRT_PerTurn)
	{
		EventManager = `XEVENTMGR;
		ThisObj = self;
		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', PlayerTurnBegin, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnEnded', PlayerTurnEnd, ELD_OnStateSubmitted);
	}
	m_bSetupEvents = true;
}

function EventListenerReturn PlayerTurnBegin(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Player EventPlayer;

	EventPlayer = XComGameState_Player(EventData);
	if( IsLocalPlayer(EventPlayer.ObjectID) )
	{
	}

	OnTurnChange();

	return ELR_NoInterrupt;
}

function EventListenerReturn PlayerTurnEnd(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Player EventPlayer;
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));;

	EventPlayer = XComGameState_Player(EventData);
	if( IsLocalPlayer(EventPlayer.ObjectID) )
	{
	}

	if (Timer.ResetType == EGSTRT_PerTurn)
	{
		ResetTimer();
	}

	OnTurnChange();

	return ELR_NoInterrupt;
}


//--------------------------------------------------------------------------------------- 
// Actionscript Interface
//--------------------------------------------------------------------------------------- 
simulated function AS_HideCounter()
{ Movie.ActionScriptVoid( MCPath $ ".HideCounter" ); }

simulated function AS_SetCounterText( string title, string label )
{ Movie.ActionScriptVoid( MCPath $ ".SetCounterText" ); }

simulated function AS_SetCounterTimer( int iTurns )
{ Movie.ActionScriptVoid( MCPath $ ".SetCounterTimer" ); }


//--------------------------------------------------------------------------------------- 
// Default Properties
//--------------------------------------------------------------------------------------- 
defaultproperties
{
	MCName="countdown"
	bAnimateOnInit=false
	Height=80 // used for objectives placement beneath this element as well. 
	m_bTimeDataAvailable=true //We start out assuming this state object *might* be available
}

