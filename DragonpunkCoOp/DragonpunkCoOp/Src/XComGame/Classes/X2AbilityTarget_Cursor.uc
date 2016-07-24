//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTarget_Cursor.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityTarget_Cursor extends X2AbilityTargetStyle native(Core);

var bool    bRestrictToWeaponRange;
var int     IncreaseWeaponRange;
var bool    bRestrictToSquadsightRange;
var int     FixedAbilityRange;

simulated native function bool IsFreeAiming(const XComGameState_Ability Ability);

simulated function float GetCursorRangeMeters(XComGameState_Ability AbilityState)
{
	local XComGameState_Item SourceWeapon;
	local int RangeInTiles;
	local float RangeInMeters;

	if (bRestrictToWeaponRange)
	{
		SourceWeapon = AbilityState.GetSourceWeapon();
		if (SourceWeapon != none)
		{
			RangeInTiles = SourceWeapon.GetItemRange(AbilityState);

			if( RangeInTiles == 0 )
			{
				// This is melee range
				RangeInMeters = class'XComWorldData'.const.WORLD_Melee_Range_Meters;
			}
			else
			{
				RangeInMeters = `UNITSTOMETERS(`TILESTOUNITS(RangeInTiles));
			}

			return RangeInMeters;
		}
	}
	return FixedAbilityRange;
}

DefaultProperties
{
	FixedAbilityRange = -1
}