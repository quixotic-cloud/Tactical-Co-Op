//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_MakeObjective.uc
//  AUTHOR:  Mark Nauta  --  06/8/2016
//  PURPOSE: Allows an arbitrary unit or interactive object to become an objective
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_MakeObjective extends SequenceAction;

var private XComGameState_Unit Unit;
var private XComGameState_InteractiveObject InteractiveObject;

event Activated()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Making Objective");

	AddObjectiveInfo(NewGameState, Unit);
	AddObjectiveInfo(NewGameState, InteractiveObject);

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	else
	{
		`Redscreen("SeqAct_MakeObjective called without providing a unit or interactive object.");
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

private function AddObjectiveInfo(XComGameState NewGameState, XComGameState_BaseObject Object)
{
	local XComTacticalMissionManager MissionManager;
	local XComGameState_ObjectiveInfo ObjectiveInfo;

	if(Object == none)
	{
		return;
	}

	MissionManager = `TACTICALMISSIONMGR;

	// create the objective state
	ObjectiveInfo = XComGameState_ObjectiveInfo(NewGameState.CreateStateObject(class'XComGameState_ObjectiveInfo'));
	ObjectiveInfo.MissionType = MissionManager.ActiveMission.sType;
	NewGameState.AddStateObject(ObjectiveInfo);

	// link it to the object
	Object = NewGameState.CreateStateObject(Object.Class, Object.ObjectId);
	Object.AddComponentObject(ObjectiveInfo);
	NewGameState.AddStateObject(Object);
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Make Objective"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="Interactive Object",PropertyName=InteractiveObject)
}