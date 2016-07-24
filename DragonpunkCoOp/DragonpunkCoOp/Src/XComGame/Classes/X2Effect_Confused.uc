//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_Confused extends X2Effect_PersistentStatChange;

//Occurs once per turn during the Unit Effects phase
simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit EffectTargetUnit;
	local bool bContinueTicking;
	local XComGameStateHistory History;
	local X2EventManager EventManager;

	bContinueTicking = super.OnEffectTicked(ApplyEffectParameters, kNewEffectState, NewGameState, FirstApplication);

	if(FullTurnComplete(kNewEffectState))
	{
		History = `XCOMHISTORY;
		EventManager = `XEVENTMGR;

		EffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		EventManager.TriggerEvent('ConfusedMovement', EffectTargetUnit, EffectTargetUnit);
	}

	return bContinueTicking;
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit EffectTargetUnit;
	local XComGameStateHistory History;
	local Object EffectObj;

	History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	EffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	// Register for the required events
	EventMgr.RegisterForEvent(EffectObj, 'ConfusedMovement', EffectGameState.OnConfusedMovement, ELD_OnStateSubmitted,, EffectTargetUnit);
}