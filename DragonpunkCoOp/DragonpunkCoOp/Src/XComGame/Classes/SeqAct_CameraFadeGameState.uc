//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_CameraFadeGameState.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Fades the camera out in a game state safe way
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_CameraFadeGameState extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

// Color to use as the fade 
var() color FadeColor;

// The opacity that the camera will fade to
var() float FadeOpacity<ClampMin=0.0 | ClampMax=1.0>;

// How long to fade to FadeOpacity from the camera's current fade opacity
var() float FadeTime<ClampMin=0.0>;

event Activated()
{
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameState_KismetVariable KismetStateObject;
	local VisualizationTrack BuildTrack;
	local X2Action_CameraFade FadeAction;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetStateObject;
	BuildTrack.StateObject_NewState = KismetStateObject;

	FadeAction = X2Action_CameraFade(class'X2Action_CameraFade'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext()));
	FadeAction.EnableFade = InputLinks[0].bHasImpulse;
	FadeAction.FadeColor = FadeColor;
	FadeAction.FadeOpacity = FadeOpacity;
	FadeAction.FadeTime = FadeTime;

	VisualizationTracks.AddItem(BuildTrack);
}

function ModifyKismetGameState(out XComGameState GameState);

defaultproperties
{
	ObjCategory="Camera"
	ObjName="Game Camera - Camera Fade"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")

	VariableLinks.Empty
}