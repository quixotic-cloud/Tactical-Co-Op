//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ShowHiddenMovementIndicator.uc
//  AUTHOR:  Ryan McFall  --  6/27/2015
//  PURPOSE: Displays the hidden movement indicator immediately
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_ShowHiddenMovementIndicator extends SequenceAction
	implements(X2KismetSeqOpVisualizer); 

event Activated();
function ModifyKismetGameState(out XComGameState GameState);

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	class'X2Action_HiddenMovement'.static.AddHiddenMovementActionToBlock(GameState, VisualizationTracks);
}

defaultproperties
{
	ObjName="Show Hidden Movement Indicator"
	ObjCategory="UI/Input"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
}
