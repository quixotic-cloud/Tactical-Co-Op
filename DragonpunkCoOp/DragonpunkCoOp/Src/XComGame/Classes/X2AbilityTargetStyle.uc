//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTargetStyle.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityTargetStyle extends Object
	abstract
	dependson(X2TacticalGameRuleset)
	native(Core);

// Allows entire classes of targeting styles to suppress the targeting icons in the shot hud
simulated function bool SuppressShotHudTargetIcons()
{
	return false;
}

simulated native function bool IsFreeAiming(const XComGameState_Ability Ability);

/**
 * GetPrimaryTargetOptions
 * @return Result code based on getting an initial (unfiltered) list of targets - generally those that are within visibility ranges
 *         Targets list should be populated with PrimaryTarget filled out for each element        
 */
simulated native function name GetPrimaryTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets);

simulated native function bool ValidatePrimaryTargetOption(const XComGameState_Ability Ability, XComGameState_Unit SourceUnit, XComGameState_BaseObject TargetObject);

/**
 * CheckFilteredPrimaryTargets
 * @return Result code based on the now filtered list of targets (GetPrimaryTargetOptions does not apply any filtering)
 *         For example, an ability that requires a target but has none after filtering would return a failure code
 */
simulated native function name CheckFilteredPrimaryTargets(const XComGameState_Ability Ability, const out array<AvailableTarget> Targets);
simulated native function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles);