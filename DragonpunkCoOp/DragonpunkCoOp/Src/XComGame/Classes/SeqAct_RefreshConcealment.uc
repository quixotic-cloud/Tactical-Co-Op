//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_RefreshConcealment.uc
//  AUTHOR:  Dan Kaplan
//  PURPOSE: Implements a Kismet sequence action that can refresh the concealment tile markup
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_RefreshConcealment extends SequenceAction 
	implements(X2KismetSeqOpVisualizer);


event Activated()
{
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local X2Action_UpdateUI UpdateUIAction;
	local VisualizationTrack BuildTrack;
	local XComGameState_KismetVariable KismetStateObject;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetStateObject;
	BuildTrack.StateObject_NewState = KismetStateObject;

	UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext()));
	UpdateUIAction.UpdateType = EUIUT_Pathing_Concealment;

	VisualizationTracks.AddItem(BuildTrack);
}

function ModifyKismetGameState(out XComGameState GameState);


defaultproperties
{
	ObjCategory="Concealment"
	ObjName="Concealment Markup - Refresh"
	bCallHandler=false
	
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty

	OutputLinks(1)=(LinkDesc="Completed")
}
