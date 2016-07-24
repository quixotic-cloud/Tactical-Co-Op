class X2Action_StopSuppression extends X2Action;

var private XGUnit              SourceUnit;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	SourceUnit = XGUnit(Track.TrackActor);
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:

	SourceUnit.ConstantCombatSuppressArea(false);
	SourceUnit.ConstantCombatSuppress(false, none);
	//This action should _not_ trigger anything involving the IdleAnimationStateMachine - it may cause the following X2Action_EnterCover to be clobbered by an idle anim.
	//Instead, wait for the vis block to end, or X2Action_EnterCover to handle it.

	CompleteAction();
}