//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_AbilityProperty.uc
//  AUTHOR:  Timothy Talley
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_AbilityProperty extends X2Condition native(Core);

var array<name> OwnerHasSoldierAbilities;
var bool TargetMustBeInValidTiles;

native function name AbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget);
