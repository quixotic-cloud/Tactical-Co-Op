///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_UnitHasItem.uc
//  AUTHOR:  David Burchanowski  --  9/16/2014
//  PURPOSE: Action to get the quest item for the mission script this action instance belongs to
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_GetQuestItemTemplate extends SequenceAction;

var private string ItemTemplate;

event Activated()
{
	local XComTacticalMissionManager MissionManager;

	// determine if we are the mission or subobjective and then grab the appropriate quest item template
	MissionManager = `TACTICALMISSIONMGR;

	ItemTemplate = string(MissionManager.MissionQuestItemTemplate);

	`log("SeqAct_GetQuestItemTemplate: " $ ItemTemplate);
}

defaultproperties
{
	ObjName="Get Quest Item Template"
	ObjCategory="Procedural Missions"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_String', LinkDesc="Item Template", PropertyName=ItemTemplate, bWriteable=true)
}