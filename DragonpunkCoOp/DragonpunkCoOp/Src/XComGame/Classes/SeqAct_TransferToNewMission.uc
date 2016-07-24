//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_TransferToNewMission.uc
//  AUTHOR:  David Burchanowski   --  3/11/2016
//  PURPOSE: Displays the hidden movement indicator immediately
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_TransferToNewMission extends SequenceAction
	implements(X2KismetSeqOpVisualizer); 

var() private string MissionType;

event Activated();
function ModifyKismetGameState(out XComGameState GameState);

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local XComGameStateHistory History;
	local VisualizationTrack BuildTrack;
	local X2Action_TransferToNewMission TransferAction;
	local XComGameState_KismetVariable KismetState;

	if(MissionType == "")
	{
		`Redscreen("No mission specified in SeqAct_TransferToNewMission!");
		return;
	}

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetState)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetState;
	BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
	TransferAction = X2Action_TransferToNewMission(class'X2Action_TransferToNewMission'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext()));
	TransferAction.MissionType = MissionType;
	VisualizationTracks.AddItem(BuildTrack);
}

defaultproperties
{
	ObjName="Transfer To New Mission"
	ObjCategory="Level"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Mission Type",PropertyName=MissionType)
}
