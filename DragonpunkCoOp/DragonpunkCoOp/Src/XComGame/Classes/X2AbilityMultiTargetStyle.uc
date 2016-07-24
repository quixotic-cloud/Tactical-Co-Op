//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityMultiTargetStyle.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityMultiTargetStyle extends Object
	abstract
	native(Core)
	dependson(X2TacticalGameRuleset);

var bool bAllowSameTarget;
var bool bUseSourceWeaponLocation;
var int NumTargetsRequired;

/**
 * GetMultiTargetOptions
 * @param Targets will have valid PrimaryTarget filled out already
 * @return Targets with AdditionalTargets filled out given the PrimaryTarget in each element
 */
simulated native function GetMultiTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets);

simulated native function GetMultiTargetsForLocation(const XComGameState_Ability Ability, const vector Location, out AvailableTarget Target);

/**
* CheckFilteredMultiTargets
* @param Target will contain a filtered primary target with its filtered multi-targets
* @return Return value should indicate if this primary target is valid, given the list of multi-targets (used to further filter the primary targets).
*/
simulated native function name CheckFilteredMultiTargets(const XComGameState_Ability Ability, const AvailableTarget Target);

simulated native function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles);

// Used to collect TargetLocations for an Ability
simulated native function bool CalculateValidLocationsForLocation(const XComGameState_Ability Ability, const vector Location, AvailableTarget AvailableTargets, out array<vector> ValidLocations);