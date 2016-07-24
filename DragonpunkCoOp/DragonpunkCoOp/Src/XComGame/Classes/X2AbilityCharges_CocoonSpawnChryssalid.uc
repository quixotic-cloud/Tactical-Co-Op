//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCharges_CocoonSpawnChryssalid extends X2AbilityCharges
	config(GameData_SoldierSkills);

var config int SPAWN_CHARGES;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit)
{
	return default.SPAWN_CHARGES;
}