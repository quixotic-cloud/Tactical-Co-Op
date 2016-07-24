//-----------------------------------------------------------
//Makes a unit speak a line of voice over
//-----------------------------------------------------------
class SeqAct_PlayUnitVoiceover extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var XComGameState_Unit Unit;
var name AudioCue;

function ModifyKismetGameState(out XComGameState GameState);

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationTrack BuildTrack;

	BuildTrack.TrackActor = Unit.GetVisualizer();
	BuildTrack.StateObject_OldState = Unit;
	BuildTrack.StateObject_NewState = Unit;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext()));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AudioCue, eColor_Good);

	VisualizationTracks.AddItem(BuildTrack);
}

defaultproperties
{
	ObjCategory="Sound"
	ObjName="Play Unit Voiceover"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Name',LinkDesc="AudioCue",PropertyName=AudioCue)
}
