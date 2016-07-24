//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_StartMissionSoundtrack extends X2Action;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:
	// Let the audio guys have their fun with the map
	`BATTLE.TriggerGlobalEventClass(class'SeqEvent_SetupAmbientAudio', `BATTLE); 
	Sleep(0.1f);

	CompleteAction();
}

DefaultProperties
{
}
