//---------------------------------------------------------------------------------------
//  FILE:    XComGatekeeper.uc
//  AUTHOR:  Alex Cheng  --  3/11/2015
//  PURPOSE: Provides custom pawn definition for Gatekeeper, with additional editable
//           vars for specifying animsets for the Open and Closed states.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGatekeeper extends XComAlienPawn;

var() AnimSet OpenStateAnimset;		// Animset to use when Gatekeeper is in its open state.
var() AnimSet ClosedStateAnimset;	// Animset to use when Gatekeeper is in its closed state.

// Effects that can be used when this pawn is shot (closed DamageTypeHitEffectContainer will use XComUnitPawn::DamageEffectContainer)
var() protected DamageTypeHitEffectContainer OpenDamageEffectContainer;

simulated function DamageTypeHitEffectContainer GetDamageTypeHitEffectContainer()
{
	local XComGameState_Unit UnitState;
	local UnitValue OpenCloseValue;

	// If the unit is open, then the open damage effects should be used. Otherwise return the default
	// damage effect container (closed).
	UnitState = GetGameUnit().GetVisualizedGameState();
	if( UnitState.GetUnitValue(class'X2Ability_GateKeeper'.default.OpenCloseAbilityName, OpenCloseValue) )
	{
		if( OpenCloseValue.fValue == class'X2Ability_Gatekeeper'.const.GATEKEEPER_OPEN_VALUE )
		{
			return OpenDamageEffectContainer;
		}
	}

	return DamageEffectContainer;
}

// Override default animsets with either open or closed animset list, depending on current unit state.
simulated event bool RestoreAnimSetsToDefault()
{
	local XGUnitNativeBase GameUnit;
	local XComGameState_Unit UnitState;
	local UnitValue OpenCloseValue;

	GameUnit = GetGameUnit();
	UnitState = GameUnit.GetVisualizedGameState();
	
	// Clear default anim set list
	DefaultUnitPawnAnimsets.Length = 0;

	// Custom Gatekeeper anim mod - only add Open or Closed animset depending on the existing state.
	if( UnitState.GetUnitValue(class'X2Ability_GateKeeper'.default.OpenCloseAbilityName, OpenCloseValue) )
	{
		if( OpenCloseValue.fValue == class'X2Ability_Gatekeeper'.const.GATEKEEPER_CLOSED_VALUE )
		{
			DefaultUnitPawnAnimsets.AddItem(ClosedStateAnimset);
		}
		else
		{
			DefaultUnitPawnAnimsets.AddItem(OpenStateAnimset);
		}
	}
	else // If this unit value does not exist, the default state is closed.
	{
		DefaultUnitPawnAnimsets.AddItem(ClosedStateAnimset);
	}

	return super.RestoreAnimSetsToDefault();
}

defaultproperties
{
	// DO NOT SET ASSETS HERE, instead put them in the archetype in the editor so they work with dynamic loading.
}
