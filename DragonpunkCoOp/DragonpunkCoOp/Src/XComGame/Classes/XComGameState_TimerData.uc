//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_TimerData.uc
//  AUTHOR:  Timothy Talley  --  12/05/2014
//  PURPOSE: Stores a time snapshot to keep track of real-time, strategy-time, or turns.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_TimerData extends XComGameState_BaseObject
	native(Core);

enum ETimerType
{
	EGSTT_None,
	EGSTT_RealTime,
	EGSTT_AppRelativeTime,
	EGSTT_StrategyTime,
	EGSTT_TurnCount
};

enum EDirectionType
{
	EGSTDT_None,
	EGSTDT_Up,
	EGSTDT_Down
};

enum EResetType
{
	EGSTRT_None,
	EGSTRT_PerTurn,
	EGSTRT_TimeEnd,
	EGSTRT_ResetCount
};

//
// Configuration Data
//
var protectedwrite ETimerType		TimerType;
var protectedwrite EDirectionType	TimerDirection;
var protectedwrite EResetType		ResetType;
var protectedwrite int              EpochTimeAdded;         // Epoch time in seconds of when this gamestate was added to the history.
var protectedwrite int				EpochStartTime;         // Time in seconds when this timer was started
var protectedwrite int			    TimeLimit;              // Number of seconds to expiration (0 = infinite)
var protectedwrite int				ResetCount;             // Number of times this timer should be reset
var protectedwrite bool             bTimerEnded;

//
// Multiplayer Data
//
var bool							bStopTime;				// Should the timer stop running
var float							TotalPauseTime;			// The total time in seconds the timer has been paused.

var bool							bIsChallengeModeTimer;


//=======================================================================================
//
// Real-Time Countdown Timer
//
//=======================================================================================

/// <summary>
/// Creates a timer for a full game - useful for Challenge Mode
/// </summary>
static function XComGameState CreateRealtimeGameTimer(int _TimeLimit, optional XComGameState _NewGameState, optional int _EpochStartTime=-1 /*Current Time*/, optional EDirectionType _TimerDirection=EGSTDT_Down, optional EResetType _ResetType=EGSTRT_None)
{
	local XComGameState_TimerData Timer;
	local XComGameState NewGameState;

	NewGameState = (_NewGameState == none) ? CreateNewTimerGameStateChange() : _NewGameState;

	Timer = XComGameState_TimerData(NewGameState.CreateStateObject(class'XComGameState_TimerData'));

	Timer.SetTimerData(EGSTT_RealTime, _TimerDirection, _ResetType);
	Timer.SetRealTimeTimer(_TimeLimit, _EpochStartTime);

	Timer.EpochTimeAdded = GetUTCTimeInSeconds();
	NewGameState.AddStateObject(Timer);

	if (_NewGameState == none)
	{
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}

	return NewGameState;
}

//=======================================================================================
//
// Relative Countdown Timer
//
//=======================================================================================

/// <summary>
/// Creates a timer for relative use. meaning that it counts down relative to AppTime 
/// and can be reset to countdown/up from the reset time.
/// </summary>
static function XComGameState CreateAppRelativeGameTimer(int _TimeLimit, optional XComGameState _NewGameState, optional int _EpochStartTime=-1 /*Current Time*/, optional EDirectionType _TimerDirection=EGSTDT_Down, optional EResetType _ResetType=EGSTRT_None)
{
	local XComGameState_TimerData Timer;
	local XComGameState NewGameState;

	NewGameState = (_NewGameState == none) ? CreateNewTimerGameStateChange() : _NewGameState;

	Timer = XComGameState_TimerData(NewGameState.CreateStateObject(class'XComGameState_TimerData'));

	Timer.SetTimerData(EGSTT_AppRelativeTime, _TimerDirection, _ResetType);
	Timer.SetRealTimeTimer(_TimeLimit, _EpochStartTime);
	Timer.bStopTime = true;

	Timer.EpochTimeAdded = GetUTCTimeInSeconds();
	NewGameState.AddStateObject(Timer);

	if (_NewGameState == none)
	{
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}

	return NewGameState;
}

function SetRealTimeTimer(int _TimeLimit, optional int _EpochStartTime=-1 /*Current Time*/, optional int _ResetCount=0)
{
	EpochStartTime = (_EpochStartTime < 0) ? GetUTCTimeInSeconds() : _EpochStartTime;
	ResetCount	   = _ResetCount;
	TimeLimit      = _TimeLimit;
}

function SetRelativeTimer(int _TimeLimit, optional int _EpochStartTime=-1, optional int _ResetCount=0)
{
	EpochStartTime = (_EpochStartTime < 0) ? GetAppSeconds() : _EpochStartTime;
	ResetCount	   = _ResetCount;
	TimeLimit      = _TimeLimit;
}

function ResetTimer()
{
	if (TimerType == EGSTT_AppRelativeTime)
	{
		EpochStartTime = GetUTCTimeInSeconds();
	}
	TotalPauseTime = 0;
	bStopTime = false;
	ResetCount++;
}

//=======================================================================================
//
// Helper Functionality
//
//=======================================================================================
static native function INT GetAppSeconds();
static native function INT GetUTCTimeInSeconds(); // Returns seconds since UNIX Epoch (1 Jan 1970)

static function XComGameState CreateNewTimerGameStateChange()
{
	local XComGameState NewGameState;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
	return NewGameState;
}

function SetTimerData(ETimerType _TimerType, EDirectionType _TimerDirection, EResetType _ResetType)
{
	TimerType       = _TimerType;
	TimerDirection  = _TimerDirection;
	ResetType       = _ResetType;
}

function bool HasTimeExpired()
{
	local bool bTimeExpired;

	// Has real-time expired?
	bTimeExpired = false;
	switch (TimerType)
	{
	case EGSTT_RealTime:
	case EGSTT_AppRelativeTime:
		bTimeExpired = (TimeLimit != 0) && (GetElapsedTime() >= TimeLimit);
		break;
	default:
		break;
	}

	return bTimeExpired;
}

function int GetElapsedTime()
{
	local int TimeElapsed;
	switch (TimerType)
	{
	case EGSTT_AppRelativeTime:
	case EGSTT_RealTime:
		TimeElapsed = GetUTCTimeInSeconds() - EpochStartTime - int(TotalPauseTime);
		break;
	default:
		TimeElapsed = -1;
		break;
	}
	return TimeElapsed;
}

function int GetCurrentTime()
{
	local int TimeElapsed, CurrentTime;
	TimeElapsed = GetElapsedTime();
	switch (TimerDirection)
	{
	case EGSTDT_Down:
		CurrentTime = Max(TimeLimit - TimeElapsed, 0);
		break;
	case EGSTDT_Up:
		CurrentTime = Min(TimeElapsed, TimeLimit);
		break;
	default:
		break;
	}
	return CurrentTime;
}

function AddPauseTime(float DeltaTime)
{
	TotalPauseTime += DeltaTime;
}

function SetPauseTime(byte PauseTime)
{
	TotalPauseTime = float(PauseTime);
}

defaultproperties
{
	bIsChallengeModeTimer = false
}