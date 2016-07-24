/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class SeqAct_SetMaterialGameState extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

/** Material to apply to target when action is activated. */
var() private MaterialInterface	NewMaterial;

/** Index in the Materials array to replace with NewMaterial when this action is activated. */
var() private int MaterialIndex;

/** Index in the Materials array to replace with NewMaterial when this action is activated. */
var private XComGamestate_InteractiveObject InteractiveObject;

event Activated()
{
	local X2TacticalGameRuleset Rules;
	local XComGameState NewGameState;
	local XComGameState_InteractiveObject ObjectState;
	local XComGameState_MaterialSwaps MaterialState;

	Rules = `TACTICALRULES;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SeqAct_SetMaterialGameState: (" @ InteractiveObject.ObjectID @ ")");

	MaterialState = XComGameState_MaterialSwaps(InteractiveObject.FindComponentObject(class'XComGameState_MaterialSwaps', true));
	if(MaterialState == none)
	{
		// create a new material state and attach it to the interactive actor
		MaterialState = XComGameState_MaterialSwaps(NewGameState.CreateStateObject(class'XComGameState_MaterialSwaps'));

		// add it as a component on the interactive object
		ObjectState = XComGameState_InteractiveObject(NewGameState.CreateStateObject(class'XComGameState_InteractiveObject', InteractiveObject.ObjectID));
		ObjectState.AddComponentObject(MaterialState);
		NewGameState.AddStateObject(ObjectState);
	}
	else
	{
		// create a newer version of the existing material state
		MaterialState = XComGameState_MaterialSwaps(NewGameState.CreateStateObject(class'XComGameState_MaterialSwaps', MaterialState.ObjectID));
	}

	MaterialState.SetMaterialSwap(NewMaterial, MaterialIndex);
	NewGameState.AddStateObject(MaterialState);

	Rules.SubmitGameState(NewGameState);
}

function ModifyKismetGameState(out XComGameState GameState);

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local XComGameStateHistory History;
	local VisualizationTrack BuildTrack;
	local XComGameState ChangeState;
	local XComGameState_MaterialSwaps SwapState;
	local XComGameState_InteractiveObject SwapObject;

	History = `XCOMHISTORY;

	// get state of the object we modified. This is the game state immediately after ours
	ChangeState = History.GetGameStateFromHistory(GameState.HistoryIndex - 1);

	foreach ChangeState.IterateByClassType(class'XComGameState_MaterialSwaps', SwapState)
	{
		SwapObject = XComGameState_InteractiveObject(SwapState.FindComponentObject(class'XComGameState_InteractiveObject', true));

		if(SwapObject != none)
		{
			BuildTrack.StateObject_OldState = SwapObject;
			BuildTrack.StateObject_NewState = SwapObject;
			BuildTrack.TrackActor = History.GetVisualizer(SwapObject.ObjectID);
			class'X2Action_SyncVisualizer'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext());	

			VisualizationTracks.AddItem(BuildTrack);
		}
	}
}


defaultproperties
{
	ObjName="Set Material GameState"
	ObjCategory="Level"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="InteractiveObject",PropertyName=InteractiveObject)
}
