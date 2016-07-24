//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyObjectives.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Displays objectives for Special Missions
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyObjectives extends UIPanel;

var localized string m_strTitle;
var localized string m_strObjectivesCompleteTitle;
var localized string m_strObjectivesCompleteBody;

//----------------------------------------------------------------------------
// UI INITIALIZATION
//
simulated function UIStrategyObjectives InitObjectives()
{
	InitPanel();
	SetTitle(m_strTitle);
	UpdateData();
	return self;
}

simulated function UpdateData()
{
}

simulated function ShowCompletedObjectivesDialogue(XComGameState NewGameState)
{
}



//----------------------------------------------------------------------------
// FLASH INTERFACE
//
function SetTitle(string title) {
	mc.FunctionString("SetTitle", title);
}
function AddObjective(string id, 
							  string title, 
							  string description, 
							  bool showCheckmark, 
							  bool bShowCompleted, 
							  bool bShowFailed,
							  optional int queuePos = -1) {
	mc.BeginFunctionOp("AddObjective");
	mc.QueueString(id);
	mc.QueueString(title);
	mc.QueueString(description);
	mc.QueueBoolean(showCheckmark);
	mc.QueueBoolean(bShowCompleted);
	mc.QueueBoolean(bShowFailed);
	mc.QueueNumber(queuePos);
	mc.EndOp();
}
function CompleteObjective(string id) {
	mc.FunctionString("CompleteObjective", id);
}
function FailObjective(string id) {
	mc.FunctionString("FailObjective", id);
}
function RemoveObjective(string id) {
	mc.FunctionString("RemoveObjective", id);
}
function ClearObjectives() {
	mc.FunctionVoid("clear");
}

defaultproperties
{
	//MCName = "theObjectivesList";
	LibID = "ObjectiveList";
}