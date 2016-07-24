//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitEffectsWithAbilitySource extends X2Condition_UnitEffects native(Core);

native function name MeetsCondition(XComGameState_BaseObject kTarget);
native function name MeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource);
