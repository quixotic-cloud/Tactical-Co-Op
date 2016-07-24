//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTarget_MovingMelee.uc
//  AUTHOR:  David Burchanowski
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityTarget_MovingMelee extends X2AbilityTarget_Single native(Core);

cpptext
{
	// helper to accelerate the sort in SelectAttackTile
	struct TileSortHelper
	{
		FTTile Tile; // a tile we can melee from
		FLOAT DistanceFromSource; // the distance from this tile to the source unit 
		UBOOL IsFlanked; // true if this tile is flanked
		UBOOL IsHighCover; // true if this tile is in high cover
		UBOOL IsCover; // true if this tile in cover
	};
}

// Effective melee distance will be limited to NumMovementPoints - MovementRangeAdjustment. i.e., if you have a MovementRangeAdjustment
// of 1, and 2 movement points, you will be able to melee any target within 1 standard move range of that unit. If the adjustment is 2,
// only adjacent targets will be able to be hit.
var int MovementRangeAdjustment;

simulated native function bool ValidatePrimaryTargetOption(const XComGameState_Ability Ability, XComGameState_Unit SourceUnit, XComGameState_BaseObject TargetObject);

// Finds the melee tiles available to the unit, if any are available to the source unit. If IdealTile is specified,
// it will select the closest valid attack tile to the ideal (and will simply return the ideal if it is valid). If no array us provided for
// SortedPossibleTiles, will simply return true or false based on whether or not a tile is available
simulated static native function bool SelectAttackTile(XComGameState_Unit UnitState, 
														   XComGameState_BaseObject TargetState, 
														   X2AbilityTemplate MeleeAbilityTemplate,
														   optional out array<TTile> SortedPossibleTiles, // index 0 is the best option.
														   optional out TTile IdealTile, // If this tile is available, will just return it
														   optional bool Unsorted = false) const; // if unsorted is true, just returns the list of possible tiles

// returns true the given unit can perform a melee attack from SourceTile to TargetTile. Only checks spatial considerations, such as distance
// and walls. You still need to check if the melee ability is valid at all by validating its conditions.
simulated static native function bool IsValidAttackTile(XComGameState_Unit UnitState, const out TTile SourceTile, const out TTile TargetTile) const;

defaultproperties
{
	bAllowDestructibleObjects=true
}