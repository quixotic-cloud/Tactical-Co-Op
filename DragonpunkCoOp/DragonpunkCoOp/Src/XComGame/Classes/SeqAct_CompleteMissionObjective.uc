//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_CompleteMissionObjective.uc
//  AUTHOR:  Dan Kaplan  --  2/24/2015
//  PURPOSE: Kismet action to mark a named Mission Objective as complete.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_CompleteMissionObjective extends SequenceAction;

// The name of the objective that is to be marked as complete. (This should correspond to a MissionObjectives -> ObjectiveName defined in DefaultMissions.ini).
var() Name ObjectiveName;

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	
	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Completed Objective");
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	BattleData.CompleteObjective(ObjectiveName);
	NewGameState.AddStateObject(BattleData);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Complete Objective"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
}
