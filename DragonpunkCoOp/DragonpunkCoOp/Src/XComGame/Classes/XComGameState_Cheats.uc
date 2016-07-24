//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Cheats.uc
//  AUTHOR:  David Burchanowski  --  12/17/2013
//  PURPOSE: Tracks changes to game cheats.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Cheats extends XComGameState_BaseObject
	implements(X2VisualizedInterface)
	native(Core);

enum EConcealmentShaderOverride
{
	eConcealmentShaderOverride_None,
	eConcealmentShaderOverride_On,
	eConcealmentShaderOverride_Off,
};

// if true, the hidden movement indicator will not appear
var bool SuppressHiddenMovementIndicator;

// if true, will prevent loot from being usable by the player and remove all looting ai
var bool DisableLooting;

// if true, will suppress the UI turn overlay
var bool DisableTurnOverlay;

// if true, the player will not be able to tab/switch between units
var bool DisableUnitSwitching;

// if true, will prevent rush cams from firing
var bool DisableRushCams;

// if true, forces a cinescript cut to happen if the dice roll for it fails
var bool AlwaysDoCinescriptCut;

var EConcealmentShaderOverride ConcealmentShaderOverride;

// if set, will play this music set instead of the normal set
var name TacticalMusicSetOverride;

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

static event XComGameState_Cheats GetVisualizedCheatsObject()
{
	local XComGameStateVisualizationMgr VisualizationManager;

	VisualizationManager = `XCOMVISUALIZATIONMGR;
	return GetCheatsObject(VisualizationManager.LastStateHistoryVisualized);
}

static event XComGameState_Cheats GetCheatsObject(optional int HistoryIndex = -1)
{
	local XComGameStateHistory History;
	local XComGameState_Cheats CheatState;
	local XComGameState StartState;

	History = `XCOMHISTORY;

	// start with the most recent version of the cheats in the history. One should be in the default start state
	// so it should never be null, unless the game is old

	StartState = History.GetStartState();
	if(StartState == none)
	{
		CheatState = XComGameState_Cheats(History.GetSingleGameStateObjectForClass(class'XComGameState_Cheats', true));
	}
	else
	{
		// start state hasn't been submitted yet, so grab the cheats directly from it
		foreach StartState.IterateByClassType(class'XComGameState_Cheats', CheatState)
		{
			break;
		}
	}


	if(HistoryIndex > -1 && CheatState != none)
	{
		// we are not requesting the most recent version of the cheats, so get the one we want
		CheatState = XComGameState_Cheats(History.GetGameStateForObjectID(CheatState.ObjectID,, HistoryIndex));
	}

	// existing games (made prior to the cheat object) won't have a cheat state, so return a default object as a fallback
	return CheatState != none ? CheatState : new class'XComGameState_Cheats';
}

static event XComGameState CreateCheatChangeState()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Updating Cheat Settings");
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = XComGameStateContext_ChangeContainer(NewGameState.GetContext()).XComGameState_Cheats_BuildVisualization;
	return NewGameState;
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
}

function SyncVisualizer(optional XComGameState GameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_Cheats PreviousCheatState;
	local XComGameState_Unit UnitState;
	local XComGameState_InteractiveObject InteractiveObjectState;
	local int HistoryIndex;

	History = `XCOMHISTORY;
	PreviousCheatState = XComGameState_Cheats(History.GetPreviousGameStateForObject(self));
	if(PreviousCheatState == none)
	{
		// if no previous state, just create a default to compare against
		PreviousCheatState = new class'XComGameState_Cheats';
	}

	// do any visualization of cheat changes here

	if(PreviousCheatState.ConcealmentShaderOverride != ConcealmentShaderOverride)
	{
		`Pres.UpdateConcealmentShader();
	}

	if(PreviousCheatState.DisableLooting != DisableLooting)
	{
		// update the visuals of all lootables to react to the change
		HistoryIndex = History.GetCurrentHistoryIndex();
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState, , , HistoryIndex)
		{
			UnitState.UpdateLootSparklesEnabled(false);
		}

		foreach History.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObjectState, , , HistoryIndex)
		{
			InteractiveObjectState.UpdateLootSparklesEnabled(false);
		}
	}

	// update the music set
	if(PreviousCheatState.TacticalMusicSetOverride != TacticalMusicSetOverride)
	{
		`XTACTICALSOUNDMGR.SelectRandomTacticalMusicSet();
	}
}

function AppendAdditionalSyncActions( out VisualizationTrack BuildTrack )
{
}
