//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ModifyStats.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    5/29/2015
//  PURPOSE: Base class for effects that want to modify unit stats. Handles applying and
//           unapplying the stat mods. Child classes should update the XComGameState_Effect's
//           StatChanges array inside of their own OnEffectAdded, before calling the one here.
//           See X2Effect_PersistentStatChange for an example.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Effect_ModifyStats extends X2Effect_Persistent abstract;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit kTargetUnitState;
	local int OriginalHP, NewHP;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	if (NewEffectState.StatChanges.Length == 0)
	{
		`RedScreenOnce("Effect" @ EffectName @ "has no stat modifiers. Author: jbouscher / @gameplay");
		return;
	}
	kTargetUnitState = XComGameState_Unit(kNewTargetState);

	if( kTargetUnitState != None )
	{
		OriginalHP = kTargetUnitState.GetCurrentStat(eStat_HP);
		kTargetUnitState.ApplyEffectToStats(NewEffectState, NewGameState);
		NewHP = kTargetUnitState.GetCurrentStat(eStat_HP);
		if (NewHP > OriginalHP)
		{
			if(kTargetUnitState.LowestHP == OriginalHP)
			{
				kTargetUnitState.LowestHP = NewHP;              //  a persistent HP increase is allowed to bump the lowest known HP value
			}

			if(kTargetUnitState.HighestHP == OriginalHP)
			{
				kTargetUnitState.HighestHP = NewHP;				//  a persistent HP increase is allowed to bump the highest known HP value
			}
			
		}
	}
}

//Occurs once per turn during the Unit Effects phase
simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit kOldTargetUnitState, kNewTargetUnitState;	

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	kOldTargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( kOldTargetUnitState != None )
	{
		kNewTargetUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', kOldTargetUnitState.ObjectID));
		kNewTargetUnitState.UnApplyEffectFromStats(RemovedEffectState, NewGameState);
		NewGameState.AddStateObject(kNewTargetUnitState);
	}
}

function UnitEndedTacticalPlay(XComGameState_Effect EffectState, XComGameState_Unit UnitState)
{
	UnitState.UnApplyEffectFromStats(EffectState);
}