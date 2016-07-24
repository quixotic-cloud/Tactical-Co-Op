//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCost_Charges.uc
//  AUTHOR:  Joshua Bouscher -- 2/5/2015
//  PURPOSE: Deduct charges from an ability when activated.
//           Note that many abilities with "charges" rely instead on weapon ammo
//           e.g. grenades, medikits
//           This is for abilities that are not associated with a weapon, or that
//           have charges separate from ammo.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCost_Charges extends X2AbilityCost;

var int NumCharges;
var array<name> SharedAbilityCharges;       //  names of other abilities which should all have their charges deducted as well. not checked in CanAfford, only modified in ApplyCost.
var bool bOnlyOnHit;                        //  only expend charges when the ability hits the target

simulated function name CanAfford(XComGameState_Ability kAbility, XComGameState_Unit ActivatingUnit)
{
	if (kAbility.GetCharges() >= NumCharges)
		return 'AA_Success';

	return 'AA_CannotAfford_Charges';
}

simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local name SharedAbilityName;
	local StateObjectReference SharedAbilityRef;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_Ability SharedAbilityState;

	if (bOnlyOnHit && AbilityContext.IsResultContextMiss())
	{
		return;
	}
	kAbility.iCharges -= NumCharges;

	if (SharedAbilityCharges.Length > 0)
	{
		History = `XCOMHISTORY;
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
		if (UnitState == None)
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));

		foreach SharedAbilityCharges(SharedAbilityName)
		{
			if (SharedAbilityName != kAbility.GetMyTemplateName())
			{
				SharedAbilityRef = UnitState.FindAbility(SharedAbilityName);
				if (SharedAbilityRef.ObjectID > 0)
				{
					SharedAbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', SharedAbilityRef.ObjectID));
					SharedAbilityState.iCharges -= NumCharges;
					NewGameState.AddStateObject(SharedAbilityState);
				}
			}
		}
	}
}

DefaultProperties
{
	NumCharges = 1
}