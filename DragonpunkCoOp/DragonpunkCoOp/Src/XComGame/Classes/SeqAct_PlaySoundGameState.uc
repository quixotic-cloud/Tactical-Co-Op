//-----------------------------------------------------------
// Gamestate safe version of SeqAct_PlaySoundGameState
//-----------------------------------------------------------
class SeqAct_PlaySoundGameState extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

/** Sound cue to play on the targeted actor(s) */
var() SoundCue PlaySound;

/** Various parameters to config the sound */
var()	float	FadeInTime;
var()	float	VolumeMultiplier;
var()	float	PitchMultiplier;
var()	bool	bSuppressSubtitles;

function ModifyKismetGameState(out XComGameState GameState);

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local X2Action_StartStopSound SoundAction;
	local XComGameStateHistory History;
	local XComGameState_KismetVariable KismetStateObject;

	History = `XComHistory;
	foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetStateObject;
	BuildTrack.StateObject_NewState = KismetStateObject;

	SoundAction = X2Action_StartStopSound( class'X2Action_StartStopSound'.static.AddToVisualizationTrack( BuildTrack, GameState.GetContext() ) );

	SoundAction.Sound = PlaySound;
	SoundAction.FadeInTime = FadeInTime;
	SoundAction.VolumeMultiplier = VolumeMultiplier;
	SoundAction.PitchMultiplier = PitchMultiplier;
	SoundAction.bSuppressSubtitles = bSuppressSubtitles;
	SoundAction.WaitForCompletion = OutputLinks[1].Links.Length > 0;
	
	VisualizationTracks.AddItem(BuildTrack);
}

defaultproperties
{
	VolumeMultiplier=1
	PitchMultiplier=1
	ObjName="Play Sound (GameState)"
	ObjCategory="Sound"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Play")

	VariableLinks.Empty

	OutputLinks(0)=(LinkDesc="Out")
	OutputLinks(1)=(LinkDesc="Finished")
}
