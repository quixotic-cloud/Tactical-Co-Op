//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveClimbOnto extends X2Action_Move;

var vector  Destination;
var float   Distance;

var CustomAnimParams AnimParams;
var bool  bStoredSkipIK;
var Rotator DesiredRotation;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
	PathTileIndex = FindPathTileIndex();
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
	UnitPawn.Acceleration = vect(0,0,0);
	UnitPawn.vMoveDirection = vect(0,0,0);
	UnitPawn.EnableRMA(false, false);
	Sleep(0);

	UnitPawn.SetFocalPoint(UnitPawn.Location + Vector(UnitPawn.Rotation) * 16.0f);

	`BATTLE.m_bSkipVisUpdate = true;
	
	bStoredSkipIK = UnitPawn.bSkipIK;
	UnitPawn.bSkipIK = true;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	
	AnimParams.AnimName = 'MV_ClimbLowObject_Up';
	AnimParams.PlayRate = GetMoveAnimationSpeed();
	AnimParams.HasDesiredEndingAtom = true;
	AnimParams.DesiredEndingAtom.Translation = Destination;
	AnimParams.DesiredEndingAtom.Translation.Z = Unit.GetDesiredZForLocation(Destination);
	AnimParams.DesiredEndingAtom.Scale = 1.0f;
	DesiredRotation = Normalize(Rotator(Destination - UnitPawn.Location));
	DesiredRotation.Pitch = 0;
	DesiredRotation.Roll = 0;
	AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(DesiredRotation);

	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	UnitPawn.bSkipIK = bStoredSkipIK;
	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.SnapToGround();

	UnitPawn.Acceleration = Vect(0, 0, 0);
	UnitPawn.vMoveDirection = Vect(0, 0, 0);

	UnitPawn.m_fDistanceMovedAlongPath = Distance;
	CompleteAction();
}

DefaultProperties
{
}
