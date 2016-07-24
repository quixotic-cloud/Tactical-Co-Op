//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_TimedWait extends X2Action;

var float DelayTimeSec;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	if( DelayTimeSec < 0.0f )
	{
		DelayTimeSec = 0.0f;
	}
}

function bool IsTimedOut()
{
	// This won't time out. It has a timer set that controlls when it ends
	return false;
}

//------------------------------------------------------------------------------------------------

simulated state Executing
{
Begin:
	sleep(DelayTimeSec * GetDelayModifier());

	CompleteAction();
}

DefaultProperties
{
	TimeoutSeconds = 15.0;
}
