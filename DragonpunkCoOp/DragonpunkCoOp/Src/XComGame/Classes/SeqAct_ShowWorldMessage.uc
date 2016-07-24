//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ShowWorldMessage.uc
//  AUTHOR:  David Burchanowski  --  6/16/2016
//  PURPOSE: Displays a message in the corner of the screen
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_ShowWorldMessage extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var string Message; // the message to display

function ModifyKismetGameState(out XComGameState GameState);

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local X2Action_PlayWorldMessage MessageAction;
	local XComGameState_KismetVariable KismetVar;
	local VisualizationTrack BuildTrack;

	if(Message != "")
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_KismetVariable', KismetVar)
		{
			BuildTrack.StateObject_OldState = KismetVar;
			BuildTrack.StateObject_NewState = KismetVar;
			MessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext()));
			MessageAction.AddWorldMessage(Message);

			VisualizationTracks.AddItem(BuildTrack);
			break;
		}
	}
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Show World Message"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Message",PropertyName=Message)
}

