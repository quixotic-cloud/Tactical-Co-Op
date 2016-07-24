//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTarget_Single.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityTarget_Single extends X2AbilityTargetStyle native(Core);

var bool OnlyIncludeTargetsInsideWeaponRange;
var bool bAllowInteractiveObjects;
var bool bAllowDestructibleObjects;
var bool bIncludeSelf;
var bool bShowAOE;

simulated native function name GetPrimaryTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets);
simulated native function bool ValidatePrimaryTargetOption(const XComGameState_Ability Ability, XComGameState_Unit SourceUnit, XComGameState_BaseObject TargetObject);
simulated native function name CheckFilteredPrimaryTargets(const XComGameState_Ability Ability, const out array<AvailableTarget> Targets);
simulated native function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles);