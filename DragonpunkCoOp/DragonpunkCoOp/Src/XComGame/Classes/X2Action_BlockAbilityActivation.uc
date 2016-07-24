//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_BlockAbilityActivation extends X2Action;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return true;
}
