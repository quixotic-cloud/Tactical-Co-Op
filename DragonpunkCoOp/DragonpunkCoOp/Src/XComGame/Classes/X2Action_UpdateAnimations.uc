//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_UpdateAnimations extends X2Action;

simulated state Executing
{

Begin:
	UnitPawn.UpdateAnimations();
	CompleteAction();
}