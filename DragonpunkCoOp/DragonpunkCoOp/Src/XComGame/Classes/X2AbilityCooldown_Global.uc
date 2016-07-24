//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCooldown_Global.uc
//  For cooldowns that are shared among all users of this ability for one player.
//  (Set up with CallReinforcements in mind)
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCooldown_Global extends X2AbilityCooldown;

// NOTE: The Global cooldown is not using AditionalAbilityCooldowns currently. If desired in the future, use that to give
// additional abilities global cooldowns.

simulated function ApplyCooldown(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Unit kUnitState;
	local XComGameState_Player kPlayerState;
	kUnitState = XComGameState_Unit(AffectState);
	kPlayerState = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player', kUnitState.ControllingPlayer.ObjectID));
	kPlayerState.SetCooldown(kAbility.GetMyTemplateName(), iNumTurns);
	NewGameState.AddStateObject(kPlayerState);
}