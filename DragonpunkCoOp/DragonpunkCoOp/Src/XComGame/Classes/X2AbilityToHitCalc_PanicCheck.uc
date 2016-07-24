//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2AbilityToHitCalc_PanicCheck.uc    
//  AUTHOR:  Alex Cheng  --  2/12/2015
//  PURPOSE: Panic hit/miss calculations, Panic Events strength vs Unit Will stat.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2AbilityToHitCalc_PanicCheck extends X2AbilityToHitCalc_StatCheck config(GameData_SoldierSkills);

var config array<Name> PanicImmunityAbilities;      //  list of abilities which provide panic immunity all of the time

function int GetAttackValue(XComGameState_Ability kAbility, StateObjectReference TargetRef)
{
	return kAbility.PanicEventValue;
}

function int GetDefendValue(XComGameState_Ability kAbility, StateObjectReference TargetRef)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
	return UnitState.GetCurrentStat(eStat_Will);
}

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local name ImmuneName;

	if (`CHEATMGR != None)
	{
		if (`CHEATMGR.bDisablePanic)        //  shouldn't even make it into here as the ability should never get activated, but just in case
		{
			`log("Cheat DisablePanic forcing panic to miss",,'XCom_HitRolls');
			ResultContext.HitResult = eHit_Miss;
			return;
		}
		if (`CHEATMGR.bAlwaysPanic)
		{
			`log("Cheat AlwaysPanic forcing panic to succeed",,'XCom_HitRolls');
			ResultContext.HitResult = eHit_Success;
			return;
		}
	}
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	foreach default.PanicImmunityAbilities(ImmuneName)
	{
		if (UnitState.FindAbility(ImmuneName).ObjectID != 0)
		{
			`log("Unit has ability" @ ImmuneName @ "which provides panic immunity. No panic allowed.",,'XCom_HitRolls');
			ResultContext.HitResult = eHit_Miss;
			return;
		}
	}
	if (kAbility.PanicFlamethrower)
	{		
		ResultContext.HitResult = eHit_Miss;
		if (kTarget.PrimaryTarget.ObjectID > 0)
		{		
			if (UnitState != None && UnitState.IsAfraidOfFire())
			{
				ResultContext.HitResult = eHit_Success;
			}
		}
		return;
	}

	super.RollForAbilityHit(kAbility, kTarget, ResultContext);
}