//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTarget_Path.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityTarget_Path extends X2AbilityTargetStyle native(Core);

simulated native function bool IsFreeAiming(const XComGameState_Ability Ability);