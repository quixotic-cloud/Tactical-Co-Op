//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Fire_OpenUnfinishedAnim extends X2Action_Fire;

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);	

	CompleteAction();
}