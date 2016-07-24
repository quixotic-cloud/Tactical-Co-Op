//---------------------------------------------------------------------------------------
//  FILE:    XComMPReplayMgr.uc
//  AUTHOR:  Timothy Talley  --  05/22/2015
//  PURPOSE: Overrides the base Replay Manager functionality to accept a full history file
//           from another machine and visualize the differences since the last action.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComMPReplayMgr extends XComReplayMgr;

//******** Cached systems variables
var XComGameStateNetworkManager NetworkMgr; //Cached reference to the network manager to support MP
var XComGameStateHistory CachedHistory;

var bool PauseReplayRequested;

//******** General purpose variables
//var int LastSeenHistoryIndex;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	CachedHistory = `XCOMHISTORY;

	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.AddReceiveHistoryDelegate(ReceiveHistory);
}

simulated function Cleanup()
{
	NetworkMgr.ClearReceiveHistoryDelegate(ReceiveHistory);
}

simulated event Destroyed() 
{
	Cleanup();
	super.Destroyed();
}

simulated event StopReplay()
{
	local XComTacticalController TacticalController;

	// Make sure to set the current history frame here, before the EndReplay of the Tactical Rules, since that will advance the History by changing Phases.
	`XCOMVISUALIZATIONMGR.SetCurrentHistoryFrame(`XCOMHISTORY.GetNumGameStates() - 1);
	`XCOMHISTORY.SetCurrentHistoryIndex(-1);

	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());

	if (TacticalController != none)
	{
		TacticalController.SetInputState('ActiveUnit_Moving');
		bInReplay = false;
		`TACTICALRULES.EndReplay();
	}
}

simulated function SetInputState()
{
	local XComTacticalController TacticalController;	
	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	TacticalController.SetInputState('Multiplayer_Inactive');
}

simulated function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	// Update the world data to be in alignment with the new history data.
	//`XWORLD.SyncVisualizers();
	//`XWORLD.UpdateTileDataCache();
}

simulated function ResumeReplay()
{
	`TACTICALRULES.ResumeReplay();

// 	if (CurrentHistoryFrame <= 0)
// 	{
// 		CurrentHistoryFrame = `XCOMHISTORY.FindStartStateIndex();
// 	}
// 	else
// 	{
		// Resuming replay, we've locally played all of the game state we have, so set the replay to be the end.
		CurrentHistoryFrame = `XCOMHISTORY.GetNumGameStates() - 1;
//	}

	StartReplay(CurrentHistoryFrame);
	GotoState('PlayingReplay');
}

/// <summary>
/// Switches the running tactical game into a replay mode, where the visualization is driven by frames already in the
/// game state history.
/// </summary>
simulated event StartReplay(int SessionStartStateIndex)
{	
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	StepForwardStopFrame = (History.GetNumGameStates() - 1);
	StepBackwardStopFrame = SessionStartStateIndex;

	SetInputState();
	bInReplay = true;
	CurrentHistoryFrame = SessionStartStateIndex;
	History.SetCurrentHistoryIndex(CurrentHistoryFrame);

	// move the camera to it's initial start location, if this mission has a fixed orientation
	class'X2Action_InitCamera'.static.InitCamera();

	StepReplayForward();
}

simulated function RequestPauseReplay()
{
	PauseReplayRequested = true;
}

state PlayingReplay
{
	event BeginState(Name PreviousStateName)
	{
		// Must set this otherwise SteppingForward might step just a tad too far because it steps past things that don't
		// have visualization, etc.
		
	}

	event Tick(float DeltaTime)
	{
		StepForwardStopFrame = `XCOMHISTORY.GetNumGameStates() - 1;

		if (CurrentHistoryFrame < StepForwardStopFrame)
		{
			StepReplayForward();
			UpdateUIWithFrame(CurrentHistoryFrame);
		}
		else if (PauseReplayRequested && !class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
		{
			PauseReplay();
		}
	}

	simulated function PauseReplay()
	{
		PauseReplayRequested = false;
		GotoState('PausedReplay');
		//LastSeenHistoryIndex = CachedHistory.GetCurrentHistoryIndex();
		StopReplay();
	}

Begin:
}

state PausedReplay
{
	event BeginState(Name PreviousStateName)
	{
	}

	event Tick(float DeltaTime)
	{
	}

Begin:
}

defaultproperties
{
	bSingleStepMode=false
	bInReplay=false
}
