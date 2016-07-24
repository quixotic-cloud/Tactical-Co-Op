//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_YellowAlert.uc
//  AUTHOR:  Ryan McFall  --  1/13/2014
//  PURPOSE: Defines the abilities that form the concealment / alertness mechanics in 
//  X-Com 2. Presently these abilities are only available to the AI.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_YellowAlert extends X2Effect_Persistent;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{	
	local XComGameState_Unit kTargetUnitState;
	//local StateObjectReference PlayerRef;

	kTargetUnitState = XComGameState_Unit(kNewTargetState);
	if( kTargetUnitState != none )
	{
		kTargetUnitState.SetCurrentStat(eStat_AlertLevel, 1);	
		`LogAI("ALERTEFFECTS: X2Effect_YellowAlert::OnEffectAdded- Set Alert Level to 1. Unit#"$kTargetUnitState.ObjectID);
		ApplyStatChangeToSubSystems(kTargetUnitState.GetReference(), eStat_AlertLevel, 1, NewGameState);
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

// Update - Yellow alert no longer reverts to green alert ono a timer.

// Returns true if the associated XComGameSate_Effect should be removed
simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit TargetUnitState;

	//Decrement the turns remaining if no enemies are visible, otherwise we stay at the same alert level and reset our turns remaining
	TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( TargetUnitState != none )
	{
		// Remove if current alert level is not at yellow alert.
		if (TargetUnitState.GetCurrentStat(eStat_AlertLevel) != 1 || TargetUnitState.IsDead())
		{		
			kNewEffectState.iTurnsRemaining = 0;
			bInfiniteDuration = false; // Disable this effect.
			NewGameState.RemoveStateObject(kNewEffectState.ObjectID);// Remove effect.
		}
	}

	return (bInfiniteDuration || kNewEffectState.iTurnsRemaining > 0);
}