class SeqAct_RemoveActorFromBuildingVis extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var() Actor TargetActor;
var X2Action_RemoveActorFromBuildingVis RemoveAction;

function ModifyKismetGameState(out XComGameState GameState)
{
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	local XComGameState_KismetVariable KismetStateObject;

	History = `XComHistory;
		foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetStateObject;
	BuildTrack.StateObject_NewState = KismetStateObject;

	if (RemoveAction == none)
	{
		RemoveAction = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2Action_RemoveActorFromBuildingVis');
	}

	BuildTrack.TrackActor = `BATTLE;

	class'X2Action_RemoveActorFromBuildingVis'.static.AddActionToVisualizationTrack(RemoveAction, BuildTrack, GameState.GetContext());

	RemoveAction.FocusActorToRemove = TargetActor;

	VisualizationTracks.AddItem(BuildTrack);
}

defaultproperties
{
	ObjCategory="CutDown"
	ObjName="Remove actor from building vis"
	bAutoActivateOutputLinks=true
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Actor",PropertyName=TargetActor)
}