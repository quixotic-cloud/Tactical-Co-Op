//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SendInterTrackMessageRandomTime extends X2Action;

var StateObjectReference        SendTrackMessageToRef;
var float						StartAnimationMinDelaySec;
var float						StartAnimationMaxDelaySec;
//*************************************

simulated state Executing
{
	private function float GetAnimationDelay()
	{
		local float RandTimeAmount;

		RandTimeAmount = 0.0f;
		if( (StartAnimationMinDelaySec >= 0.0f) && 
			(StartAnimationMaxDelaySec > 0.0f) && 
			(StartAnimationMinDelaySec < StartAnimationMaxDelaySec) )
		{
			RandTimeAmount = StartAnimationMinDelaySec + (`SYNC_FRAND() * (StartAnimationMaxDelaySec - StartAnimationMinDelaySec));
		}

		return RandTimeAmount;
	}

Begin:
	Sleep(GetAnimationDelay() * GetDelayModifier());

	if( SendTrackMessageToRef.ObjectID != 0 )
	{
		VisualizationMgr.SendInterTrackMessage(SendTrackMessageToRef);
	}

	CompleteAction();
}