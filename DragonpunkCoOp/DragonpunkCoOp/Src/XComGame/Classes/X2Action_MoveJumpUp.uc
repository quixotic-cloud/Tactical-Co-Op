//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveJumpUp extends X2Action_Move;

var vector				Destination;
var float				Distance;
var CustomAnimParams	AnimParams;
var AnimNodeSequence	PlayingSequence;
var BoneAtom			StartingAtom;
var float				fPawnHalfHeight;
var bool				bStoredSkipIK;
var vector				StopStartingLocation;
var vector				DesiredFacing;
var bool				bClimbOver;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	PathTileIndex = FindPathTileIndex();
	fPawnHalfHeight = UnitPawn.CylinderComponent.CollisionHeight;
}

function ParsePathSetParameters(int InPathIndex, const out vector InDestination, float InDistance)
{
	PathIndex = InPathIndex;	
	Destination = InDestination;
	Distance = InDistance;
}

simulated state Executing
{
Begin:
	bStoredSkipIK = UnitPawn.bSkipIK;
	UnitPawn.bSkipIK = true;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	Destination.Z = Unit.GetDesiredZForLocation(Destination);

	DesiredFacing = Destination - UnitPawn.Location;
	DesiredFacing.Z = 0;
	DesiredFacing = Normal(DesiredFacing);

	AnimParams.AnimName = 'MV_ClimbHighJump_Start';
	AnimParams.PlayRate = GetMoveAnimationSpeed();
	StartingAtom.Translation = UnitPawn.Location;
	StartingAtom.Rotation = QuatFromRotator(Rotator(DesiredFacing));
	StartingAtom.Scale = 1.0f;
	UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(AnimParams, StartingAtom);
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

	while( UnitPawn.Location.Z <= Destination.Z )
	{
		if( !PlayingSequence.bRelevant || !PlayingSequence.bPlaying || PlayingSequence.AnimSeq == None )
		{
			`RedScreen("JumpUp never made it to the destination");
			UnitPawn.SetLocation(Destination);
			break;
		}
		Sleep(0.0f);
	}

	// Make sure we didn't go past 
	StopStartingLocation.X = UnitPawn.Location.X;
	StopStartingLocation.Y = UnitPawn.Location.Y;
	StopStartingLocation.Z = Destination.Z;
	UnitPawn.SetLocation(StopStartingLocation);

	// Do the climb over check once we are at the right z height
	bClimbOver = Unit.DoClimbOverCheck(Destination);

	if( bClimbOver )
	{
		AnimParams.AnimName = 'MV_ClimbHighJump_StopWall';
	}
	else
	{
		AnimParams.AnimName = 'MV_ClimbHighJump_Stop';
	}
	AnimParams.HasDesiredEndingAtom = true;
	AnimParams.DesiredEndingAtom.Translation = Destination;
	AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(Destination - UnitPawn.Location));
	AnimParams.DesiredEndingAtom.Scale = 1.0f;
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	
	UnitPawn.Acceleration = Vect(0, 0, 0);
	UnitPawn.vMoveDirection = Vect(0, 0, 0);
	UnitPawn.m_fDistanceMovedAlongPath = Distance;
	UnitPawn.bSkipIK = bStoredSkipIK;

	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.SnapToGround();

	CompleteAction();
}

DefaultProperties
{
}
