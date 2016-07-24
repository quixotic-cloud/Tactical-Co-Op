//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCooldown_Global.uc
//  Allows for cooldowns on an individual unit as well as shared among all units of this 
//  ability for one player.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCooldown_LocalAndGlobal extends X2AbilityCooldown;

var int NumGlobalTurns;

simulated function ApplyCooldown(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Unit kUnitState;
	local XComGameState_Player kPlayerState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	super.ApplyCooldown(kAbility, AffectState, AffectWeapon, NewGameState);

	kUnitState = XComGameState_Unit(AffectState);
	kPlayerState = XComGameState_Player(History.GetGameStateForObjectID(kUnitState.ControllingPlayer.ObjectID));

	if( (kPlayerState != none) && kPlayerState.IsAIPlayer() )
	{
		// If the player state is AI (alien or civilian) then use the NumGlobalTurns value
		// Player units don't use Global cooldowns
		kPlayerState = XComGameState_Player(NewGameState.CreateStateObject(kPlayerState.Class, kPlayerState.ObjectID));
		kPlayerState.SetCooldown(kAbility.GetMyTemplateName(), NumGlobalTurns);
		NewGameState.AddStateObject(kPlayerState);
	}
}