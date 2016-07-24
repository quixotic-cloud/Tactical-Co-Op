//-----------------------------------------------------------
// Delays the visualizer for a specified amount of time
//-----------------------------------------------------------
class SeqAct_DelayGameState extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var() float Duration;
var() bool bIgnoreZipMode;

function ModifyKismetGameState(out XComGameState GameState);

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local X2Action_Delay DelayAction;
	local XComGameStateHistory History;
	local XComGameState_KismetVariable KismetStateObject;

	History = `XComHistory;
	foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetStateObject;
	BuildTrack.StateObject_NewState = KismetStateObject;

	DelayAction = X2Action_Delay( class'X2Action_Delay'.static.AddToVisualizationTrack( BuildTrack, GameState.GetContext() ) );
	DelayAction.Duration = Duration;
	DelayAction.bIgnoreZipMode = bIgnoreZipMode;
	
	VisualizationTracks.AddItem(BuildTrack);
}

defaultproperties
{
	ObjName="Delay (GameState)"
	ObjCategory="Kismet Flow"

	Duration=1.f

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Float',LinkDesc="Duration",PropertyName=Duration)
}
