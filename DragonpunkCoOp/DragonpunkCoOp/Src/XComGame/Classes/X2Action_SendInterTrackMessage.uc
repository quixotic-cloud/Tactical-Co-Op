//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SendInterTrackMessage extends X2Action;

var StateObjectReference                    SendTrackMessageToRef;
//*************************************

simulated state Executing
{
Begin:
	if( SendTrackMessageToRef.ObjectID != 0 )
	{
		VisualizationMgr.SendInterTrackMessage(SendTrackMessageToRef);
	}

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}
