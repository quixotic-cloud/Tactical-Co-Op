//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_RebootRobot extends X2Action_PlayAnimation;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	Params.AnimName = 'HL_RobotBattleSuitStop';
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.bSkipIK = true;

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	UnitPawn.EnableFootIK(true);
	UnitPawn.bSkipIK = false;

	CompleteAction();
}