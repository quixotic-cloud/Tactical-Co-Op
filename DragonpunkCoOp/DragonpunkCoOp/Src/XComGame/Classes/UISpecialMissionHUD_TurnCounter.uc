//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISpecialMissionHUD_TurnCounters.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Displays the remaining turn time for each player for special mission maps
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISpecialMissionHUD_TurnCounter extends UIPanel
	implements(X2VisualizationMgrObserverInterface);

var int m_iState;
var string m_sLabel;
var string m_sSubLabel;
var string m_sCounter;

var bool m_bLocked;
var bool m_bExpired;
var bool m_bInfinity;

var float                   m_fLastUpdateTime;
var float                   m_fTimeElapsed;
var int                     m_iLastTime;
var int                     m_ResetCount;
var bool                    m_bSetupEvents;
var bool                    m_bTimeEnded;

//
// Cached Objects
var XComGameStateHistory    m_kHistory;
var bool					m_bTimeDataAvailable;

var int m_iCounter;

var UITextContainer TurnText; 
var UITextContainer CounterText; 
var UITextContainer SubText; 

// Pseudo-Ctor
simulated function InitTurnCounter(name InitName)
{
	InitPanel(InitName);
	Hide();
	XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).VisualizationMgr.RegisterObserver(self);
}

// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();
	
	if (MCName == 'counter1')
	{
		UpdateCache();
		`XCOMNETMANAGER.AddReceiveRemoteCommandDelegate(OnRemoteCommand);

		SubscribeToOnCleanupWorld();
	}

	//DEBUG fields 

	TurnText = Spawn(class'UITextContainer', self);
	TurnText.InitTextContainer(, "", 300, 20, 300, 100);
	SubText = Spawn(class'UITextContainer', self);
	SubText.InitTextContainer(, "", 300, 40, 300, 100);
	CounterText = Spawn(class'UITextContainer', self);
	CounterText.InitTextContainer(, "", 300, 60, 300, 100);


	// If any value was set before onInit triggers, set it immediately
	if( m_iState != class'UISpecialMissionHUD_TurnCounter'.default.m_iState )
		SetUIState(m_iState, true);

	if( m_sLabel != class'UISpecialMissionHUD_TurnCounter'.default.m_sLabel )
		SetLabel(m_sLabel, true);

	if( m_sSubLabel != class'UISpecialMissionHUD_TurnCounter'.default.m_sSubLabel )
		SetSubLabel(m_sSubLabel, true);

	if( m_sCounter != class'UISpecialMissionHUD_TurnCounter'.default.m_sCounter )
		SetCounter(m_sCounter, true);

	if( m_bExpired )
		ExpireCounter(true);

	if( m_bLocked )
		LockCounter(true);

	if( m_bInfinity )
		ShowInfinity(true);
}

event Destroyed()
{
	Cleanup();
	super.Destroyed();
}

simulated event OnCleanupWorld( )
{
	Cleanup( );

	super.OnCleanupWorld( );
}

function Cleanup()
{
	`XCOMNETMANAGER.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState_UITimer UiTimer;
	local XComTActicalController TacticalController;

	foreach AssociatedGameState.IterateByClassType(class'XComGameState_UITimer', UiTimer)
		break;

	if (UiTimer == none)
		return;

	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	if (TacticalController != none)
		XComPresentationLayer(TacticalController.Pres).UITimerMessage(UiTimer.DisplayMsgTitle, UiTimer.DisplayMsgSubtitle, string(UiTimer.TimerValue), UiTimer.UiState, UiTimer.ShouldShow);
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle();

// Valid SetUIState params:
//
// eUIState_Normal
// eUIState_Bad
// eUIState_Warning
// eUIState_Good
// eUIState_Disabled
//
// NOTE: Call SetState before calling SetLabel or SetCounter to have the label and counter text properly colored
simulated function SetUIState( int iState, optional bool forceUIUpdate = false )
{
	if( bIsInited )
	{
		// Only update things if it actually changed
		if( forceUIUpdate || iState != m_iState )
			 AS_SetColor( class'UIUtilities_Colors'.static.GetHexColorFromState( iState ) );
	}
	
	m_iState = iState;
}

simulated function SetLabel(string sLabel, optional bool forceUIUpdate = false)
{
	local string sColoredText;

	//commenting out text color setting for design request, it may come back
	sColoredText = sLabel;//class'UIUtilities_Text'.static.GetColoredText(sLabel, m_iState);

	if( bIsInited )
	{
		// Only update things if it actually changed
		if( forceUIUpdate || sColoredText != m_sLabel )
		{
			AS_SetLabel(sColoredText);
			TurnText.SetHTMLText(sLabel);
		}
	}

	m_sLabel = sColoredText;
}

simulated function SetSubLabel( string sSubLabel, optional bool forceUIUpdate = false  )
{
	local string sColoredText;

	//commenting out text color setting for design request, it may come back
	sColoredText = sSubLabel;//class'UIUtilities_Text'.static.GetColoredText(sSubLabel, m_iState);

	if( bIsInited )
	{
		// Only update things if it actually changed
		if(forceUIUpdate || sColoredText != m_sSubLabel)
		{
			AS_SetSubLabel(sColoredText);
			SubText.SetHTMLText(sSubLabel);
		}
	}

	m_sSubLabel = sColoredText;
}

simulated function SetCounter( string sCounter, optional bool forceUIUpdate = false  )
{
	local string sColoredText;

	m_iCounter = int(sCounter);
	//commenting out text color setting for design request, it may come back
	sColoredText = sCounter;//class'UIUtilities_Text'.static.GetColoredText(sCounter, m_iState);

	if( bIsInited )
	{
		if(forceUIUpdate || sColoredText != m_sCounter)
		{
			CounterText.SetHTMLText(sCounter);
			AS_SetCounter(sColoredText);
		}
	}

	m_sCounter = sColoredText;
}

simulated function ExpireCounter(optional bool forceUIUpdate = false)
{
	if( bIsInited )
	{
		if(forceUIUpdate || m_bExpired == false)
			Invoke("Expire");
	}
	m_bExpired = true;
}

simulated function ShowInfinity(optional bool forceUIUpdate = false)
{
	if( bIsInited )
	{
		if(forceUIUpdate || m_bInfinity == false)
			Invoke("ShowInfinity");
	}
	m_bInfinity = true;
}

// CONTROL POINT SPECIFIC FUNCTIONALITY
simulated function LockCounter(optional bool forceUIUpdate = false) // Show lock icon
{
	if( bIsInited )
	{
		if(forceUIUpdate || m_bLocked == false)
			Invoke("Lock");
	}
	m_bLocked = true;
}
simulated function UnlockCounter(optional bool forceUIUpdate = false) // Hide lock icon
{
	if( bIsInited )
	{
		if(forceUIUpdate || m_bLocked == true)
			Invoke("Unlock");
	}
	m_bLocked = false;
}

//==============================================================================
//		FLASH INTERFACE:
//==============================================================================

// Valid AS_SetColor params:
//
// cyan
// red
// green
// grey
//
function AS_SetColor(string newColor) {
	Movie.ActionScriptVoid(MCPath$".SetColor");
	Show(); // don't show panel unless data is pumped into it - sbatista 1/18/2013
}
function AS_SetLabel(string newLabel) {
	Movie.ActionScriptVoid(MCPath$".SetLabel");
	Show(); // don't show panel unless data is pumped into it - sbatista 1/18/2013
}
function AS_SetSubLabel(string newSubLabel) {
	Movie.ActionScriptVoid(MCPath$".SetSubLabel");
	Show(); // don't show panel unless data is pumped into it - sbatista 1/18/2013
}
function AS_SetCounter(string newCount) {
	Movie.ActionScriptVoid(MCPath$".SetTimer");
	Show(); // don't show panel unless data is pumped into it - sbatista 1/18/2013
}

simulated event Tick(float DeltaTime)
{
	if (m_bTimeEnded || m_kHistory == none)
		return;

	if (CheckDependencies())
	{
		RefreshCounter();

		if (m_iState == eUIState_Good && `TACTICALRULES.GetStateName() == 'TurnPhase_MPUnitActions')
		{
			//Using m_iState instead of IsLocalPlayerTurn() to avoid restarting the timer before the UI state is updated.
			//The local player checks if the timer should stop
			AddPauseTime(DeltaTime);
		}
	}
}

simulated function AddPauseTime(float DeltaTime)
{
	local XComGameState_TimerData Timer;
	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if ((Timer != none) && !Timer.bIsChallengeModeTimer)
	{
		if (class'XComGameStateVisualizationMgr'.static.VisualizerBusy() && !`Pres.UIIsBusy())
		{
			//Pause the timer when the player does not have control.
			if (!Timer.bStopTime)
			{
				//Let the other player know the timer has stopped.
				SendStopTime();
			}
			Timer.bStopTime = true;
			Timer.AddPauseTime(DeltaTime);
		}
		else if (Timer.bStopTime)
		{
			Timer.bStopTime = false;
			//Let the other player know the timer has started again and send the amount of time paused.
			SendPauseTime(byte(Timer.TotalPauseTime));
		}
	}
}

simulated function UpdateCache()
{
	local XComGameState_TimerData Timer;

	m_kHistory = `XCOMHISTORY;
	if(m_kHistory == none)
		return;
	
	Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if ((Timer != none) && !Timer.bIsChallengeModeTimer)
	{
		SetupTimerEvents();
		OnTurnChange(IsLocalPlayerTurn());
	}
	else
	{
		m_bTimeDataAvailable = false;
	}
}

simulated function OnTurnChange(bool bLocalTurn)
{
	local XComGameState_TimerData Timer;
	Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if ((Timer != none) && !Timer.bIsChallengeModeTimer)
	{
		if(bLocalTurn)
		{
			SetUIState(eUIState_Good);
			AS_SetLabel( class'UIMultiplayerHUD_TurnTimer'.default.m_strPlayerTurnLabel);
		}
		else
		{
			SetUIState(eUIState_Bad);
			AS_SetLabel( class'UIMultiplayerHUD_TurnTimer'.default.m_strOpponentTurnLabel);
		}
		AS_SetSubLabel(" ");
	
		RefreshCounter();
	}
}

simulated function RefreshCounter()
{
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if(( Timer != none ) && !Timer.bIsChallengeModeTimer)
	{
		if (!Timer.bStopTime && (m_iLastTime != Timer.GetCurrentTime()))
		{
			AS_SetCounter(string(Timer.GetCurrentTime()));
			m_iLastTime = Timer.GetCurrentTime();
			if(m_iLastTime <= 5)
			{
				PlayAKEvent(AkEvent'SoundX2Multiplayer.MP_Timer_Beep' );
			}
		}
		Show();
	}
	else
	{
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

function SetupTimerEvents()
{
// 	local X2EventManager  EventManager;
// 	local Object ThisObj;
// 	local XComGameState_TimerData Timer;
// 
// 	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));;
// 
// 	if (!m_bSetupEvents && Timer.ResetType == EGSTRT_PerTurn)
// 	{
// 		EventManager = `XEVENTMGR;
// 		ThisObj = self;
// 		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', PlayerTurnBegin, ELD_OnStateSubmitted);
// 	}
	m_bSetupEvents = true;
}

function EventListenerReturn PlayerTurnBegin(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Player EventPlayer;

	EventPlayer = XComGameState_Player(EventData);
	OnTurnChange(IsLocalPlayer(EventPlayer.ObjectID));

	return ELR_NoInterrupt;
}

function SendPauseTime(byte PauseTime)
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	Parms.AddItem(PauseTime);
	`log("Send Pause Time"@PauseTime, , 'XCom_Online');
	`XCOMNETMANAGER.SendRemoteCommand("UpdateTime", Parms);
}

function SendStopTime()
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`log("Send Stop Time", , 'XCom_Online');
	`XCOMNETMANAGER.SendRemoteCommand("StopTime", Parms);
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	local XComGameState_TimerData Timer;
	Timer = XComGameState_TimerData(m_kHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if ((Timer != none) && !Timer.bIsChallengeModeTimer)
	{
		if (Command ~= "UpdateTime")
		{
			`log("Receive Pause Time"@RawParams[0], , 'XCom_Online');
			Timer.SetPauseTime(RawParams[0]);
			Timer.bStopTime = false;
		}
		else if (Command ~= "StopTime")
		{
			`log("Receive Stop Time", , 'XCom_Online');
			Timer.bStopTime = true;
		}
		else if (Command ~= "ResetTime")
		{
			`log("Receive Reset Time", , 'XCom_Online');
			Timer.ResetTimer();
		}
	}
}

defaultproperties
{
	m_sLabel    = "";
	m_sSubLabel = "";
	m_sCounter  = "";
	m_iState    = -1;
	m_bLocked   = false;
	m_bExpired  = false;
	bAnimateOnInit = false;
}