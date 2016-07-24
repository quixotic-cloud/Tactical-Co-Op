//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_RunBehaviorTree extends X2Effect_Persistent;

var int NumActions;
var name BehaviorTreeName;
var bool bInitFromPlayer; // True to reset more behavior tree vars on each run as if it is the start of the player turn. BTVars & ErrorChecking.

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));	

	// Kick off panic behavior tree.
	// Delayed behavior tree kick-off.  Points must be added and game state submitted before the behavior tree can 
	// update, since it requires the ability cache to be refreshed with the new action points.
	UnitState.AutoRunBehaviorTree(BehaviorTreeName, NumActions, `XCOMHISTORY.GetCurrentHistoryIndex() + 1, false, bInitFromPlayer);

	// Mark the last event chain history index when the behavior tree was kicked off, 
	// to prevent multiple BTs from kicking off from a single event chain.
	UnitState.SetUnitFloatValue('LastChainIndexBTStart', `XCOMHISTORY.GetEventChainStartIndex(), eCleanup_BeginTurn);
	NewGameState.AddStateObject(UnitState);
}

defaultproperties
{
	NumActions=1
	bInitFromPlayer = false
}