class SeqAct_AddActorToBuildingVis extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var() Actor TargetActor;
var X2Action_AddActorToBuildingVis AddAction;

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

	if (AddAction == none)
	{
		AddAction = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2Action_AddActorToBuildingVis');
	}

	BuildTrack.TrackActor = `BATTLE;

	class'X2Action_AddActorToBuildingVis'.static.AddActionToVisualizationTrack(AddAction, BuildTrack, GameState.GetContext());

	AddAction.FocusActorToAdd = TargetActor;

	VisualizationTracks.AddItem(BuildTrack);
}

defaultproperties
{
	ObjCategory="CutDown"
	ObjName="Add actor to building vis"
	bAutoActivateOutputLinks=true
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Actor",PropertyName=TargetActor)
}