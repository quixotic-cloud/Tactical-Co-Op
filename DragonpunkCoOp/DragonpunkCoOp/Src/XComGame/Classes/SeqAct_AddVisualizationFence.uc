//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_AddVisualizationFence.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Blocks any visualization after this node from executing until all previous visualization completes
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_AddVisualizationFence extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks);

function ModifyKismetGameState(out XComGameState GameState)
{
	GameState.GetContext().SetVisualizationFence(true);
}

defaultproperties
{
	ObjCategory="Kismet Flow"
	ObjName="Add Visualization Fence"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty
}