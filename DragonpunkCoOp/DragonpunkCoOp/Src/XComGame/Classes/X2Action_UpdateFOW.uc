//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_UpdateFOW extends X2Action;

var bool Remove;

simulated state Executing
{
Begin:
	if( Remove )
	{
		Unit.UnregisterAsViewer();
	}

	CompleteAction();
}

DefaultProperties
{

}
