//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCooldown_Global.uc
//  Allows for cooldowns on an individual unit as well as shared among all units of this 
//  ability for one player.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCooldown_PerPlayerType extends X2AbilityCooldown_LocalAndGlobal;

// X2AbilityCooldown::iNumTurns is what non-AI controlled units use as the cooldown
var int iNumTurnsForAI;     // If this unit is controlled by the AI then it uses this value as its cooldown

simulated function int GetNumTurns(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Player PlayerState;
	local int NumTurns;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(AffectState);
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));

	NumTurns = iNumTurns;
	if( PlayerState.IsAIPlayer() )
	{
		// If the player state is AI (alien or civilian) then use the iNumTurnsForAI value
		// Player units don't use Global cooldowns
		NumTurns = iNumTurnsForAI;
	}

	return NumTurns;
}