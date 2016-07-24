//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveFlying extends X2Action_Move;

var float Distance;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function ParsePathSetParameters(const out vector InDestination, float InDistance, const out vector InCurrentDirection, const out vector InNewDirection, bool ShouldSkipStop)
{
	Distance = InDistance;
}

simulated state Executing
{
	function PlayFlightAnim()
	{
		local CustomAnimParams AnimParams;

		UnitPawn.bShouldRotateToward = false;
		UnitPawn.EnableRMA(true, false);
		UnitPawn.EnableRMAInteractPhysics(false);

		AnimParams.AnimName = 'MV_RunFwd';
		AnimParams.Looping = true;
		AnimParams.PlayRate = GetMoveAnimationSpeed();
		UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}

Begin:
	PlayFlightAnim();

	while(UnitPawn.m_fDistanceMovedAlongPath < Distance)
	{
		Sleep(0.0);
	}

	// need to set these to be at the destination exactly. Phys_Walking will kick in and continue updating the path before
	// the next move action is able to get these values setup, so make sure to set the exact distance to prevent it from
	// either going too far ahead, or else clamping the move distance to whatever the last m_fDistanceToStopExactly value was
	UnitPawn.m_fDistanceToStopExactly = Distance;
	UnitPawn.m_fDistanceMovedAlongPath = Distance;

	CompleteAction();
}

DefaultProperties
{
}