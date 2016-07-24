//---------------------------------------------------------------------------------------
// DEPRECATED - HERE FOR SAVED GAME BACKWARDS COMPATIBILITY          
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_ReinforcementSpawner extends XComGameStateContext
	abstract;

enum EReinforcementSpawnEvent
{
	ERSE_SpawnSpawner,
	ERSE_DestroySpawner,
};

var EReinforcementSpawnEvent Event;
var Vector TargetLocation;
var Vector PingLocation;
var StateObjectReference AIPlayerDataID;


function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function UpdatePlayerStateOnSpawn(XComGameState_AIPlayerData AIPlayerDataState, XComGameState NewGameState);

function XComGameState ContextBuildGameState()
{
	//DEPRECATED - HERE FOR SAVED GAME BACKWARDS COMPATIBILITY
	return none;
}

function string SummaryString()
{
	return "ABSTRACT_CLASS_SHOULD_NEVER_BE_SEEN";
}