//---------------------------------------------------------------------------------------
//  FILE:    XComSectopod.uc
//  AUTHOR:  Alex Cheng  --  4/28/2015
//  PURPOSE: Provides custom pawn definition for Sectopod, with additional editable
//           vars for specifying animsets for the High and Low states.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComSectopod extends XComAlienPawn;

var() AnimSet HighStateAnimset;		// Animset to use when Sectopod is in its High state.
var() AnimSet LowStateAnimset;	    // Animset to use when Sectopod is in its Low state.

// Override default animsets with either High or Low animset list, depending on current unit state.
simulated event bool RestoreAnimSetsToDefault()
{
	local XGUnitNativeBase GameUnit;
	local XComGameState_Unit UnitState;
	local UnitValue HighLowValue;

	// Clear default anim set list
	DefaultUnitPawnAnimsets.Length = 0;

	// Custom Sectopod anim mod - only add High or Low animset depending on the existing state.
	GameUnit = GetGameUnit();
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GameUnit.ObjectID));
	if( UnitState.GetUnitValue(class'X2Ability_Sectopod'.default.HighLowValueName, HighLowValue) )
	{
		if( HighLowValue.fValue == class'X2Ability_Sectopod'.const.SECTOPOD_HIGH_VALUE )
		{
			DefaultUnitPawnAnimsets.AddItem(HighStateAnimset);
		}
		else
		{
			DefaultUnitPawnAnimsets.AddItem(LowStateAnimset);
		}
	}
	else // If this unit value does not exist, the default state is Low.
	{
		DefaultUnitPawnAnimsets.AddItem(LowStateAnimset);
	}

	return super.RestoreAnimSetsToDefault();
}

defaultproperties
{
	// DO NOT SET ASSETS HERE, instead put them in the archetype in the editor so they work with dynamic loading.
}
