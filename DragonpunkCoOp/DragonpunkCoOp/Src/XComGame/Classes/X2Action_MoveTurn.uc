//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveTurn extends X2Action_Move;

var transient vector m_vFacePoint; // Not a direction, its a location
var transient vector m_vFaceDir; // a Direction, computed at execution time
var transient bool UpdateAimTarget;
var transient bool ForceSetPawnRotation; //If true, will snap the pawn's rotation to exactly the desired direction after playing the animation.

function ParsePathSetParameters(const out vector FacePoint)
{
	m_vFacePoint = FacePoint;
}

simulated state Executing
{
	simulated function bool PerformingInterruptedMove()
	{
		local X2Action_Move ExistingMoveAction;

		ExistingMoveAction = X2Action_Move(`XCOMVISUALIZATIONMGR.GetCurrentTrackActionForVisualizer(Unit, true));
		if (ExistingMoveAction != None && ExistingMoveAction != self)
			return true;
		else
			return false;
	}

	simulated function bool ShouldTurn()
	{
		local float fDot;

		m_vFaceDir = m_vFacePoint - UnitPawn.Location;
		m_vFaceDir.Z = 0;
		m_vFaceDir = normal(m_vFaceDir);

		fDot = m_vFaceDir dot vector(UnitPawn.Rotation);

		return fDot < 0.9f;
	}

Begin:
	Unit = XGUnit(Track.TrackActor);
	UnitPawn = Unit.GetPawn();

	//Check to see whether we are in the middle of a run that has been interrupted
	if (!PerformingInterruptedMove())
	{
		if(UpdateAimTarget && UnitPawn.GetAnimTreeController().GetAllowNewAnimations())
		{
			UnitPawn.TargetLoc = m_vFacePoint;
		}

		if(ShouldTurn())
		{
			FinishAnim(UnitPawn.StartTurning(UnitPawn.Location + m_vFaceDir*vect(1000, 1000, 0)));
		}

		if (ForceSetPawnRotation)
		{
			UnitPawn.SetRotation(Rotator(m_vFaceDir));
		}

		UnitPawn.Acceleration = vect(0, 0, 0);

		if(!Unit.IsMine()) // Debug code to show alien's last facing direction before action completed.
			Unit.m_kBehavior.SetDebugDir(Vector(UnitPawn.Rotation), , true);
		// done!
	}
	
	CompleteAction();
}

defaultproperties
{
	ForceSetPawnRotation=false
}
