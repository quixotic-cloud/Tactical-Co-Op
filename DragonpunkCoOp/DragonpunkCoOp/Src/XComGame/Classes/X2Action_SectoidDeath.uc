//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SectoidDeath extends X2Action_PlayAnimation;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	Params.AnimName = 'HL_Psi_ExplosionStart';
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	Params.AnimName = 'HL_Psi_ExplosionLoop';
	Params.Looping = true;
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	CompleteAction();
}