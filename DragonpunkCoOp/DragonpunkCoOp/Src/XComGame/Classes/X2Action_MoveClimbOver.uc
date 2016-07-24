//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveClimbOver extends X2Action_Move;

var vector  Destination;
var float   Distance;
var CustomAnimParams AnimParams;
var vector LandingLocation;
var bool    bStoredSkipIK;
var Rotator DesiredRotation;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	PathTileIndex = FindPathTileIndex();
}

function ParsePathSetParameters(int InPathIndex, const out vector InDestination, float InDistance)
{
	local XComWorldData WorldData;
	local TTile kTile;

	PathIndex = InPathIndex;	
	Destination = InDestination;
	Distance = InDistance;

	WorldData = `XWORLD;
	kTile = WorldData.GetTileCoordinatesFromPosition(Destination);
	LandingLocation = WorldData.GetPositionFromTileCoordinates(kTile);
}

simulated state Executing
{
Begin:
	UnitPawn.Acceleration = vect(0,0,0);
	UnitPawn.vMoveDirection = vect(0,0,0);
	UnitPawn.EnableRMA(false, false);
	Sleep(0);

	bStoredSkipIK = UnitPawn.bSkipIK;
	UnitPawn.bSkipIK = true;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.EnableFootIK(UnitPawn.bSkipIK != true);
	if( VSizeSq2D(LandingLocation - UnitPawn.Location) >= `TILESTOUNITS(1.5f) * `TILESTOUNITS(1.5f) )
	{
		AnimParams.AnimName = 'MV_ClimbLowObject_Over2Tiles';
	}
	else
	{
		AnimParams.AnimName = 'MV_ClimbLowObject_Over1Tile';
	}

	AnimParams.PlayRate = GetMoveAnimationSpeed();
	AnimParams.HasDesiredEndingAtom = true;
	LandingLocation.Z = Unit.GetDesiredZForLocation(LandingLocation);
	AnimParams.DesiredEndingAtom.Translation = LandingLocation;
	AnimParams.DesiredEndingAtom.Scale = 1.0f;
	DesiredRotation = Normalize(Rotator(Destination - UnitPawn.Location));
	DesiredRotation.Pitch = 0;
	DesiredRotation.Roll = 0;
	AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(DesiredRotation);
	
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	UnitPawn.bSkipIK = bStoredSkipIK;
	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.EnableFootIK(UnitPawn.bSkipIK != true);

	UnitPawn.Acceleration = Vect(0, 0, 0);
	UnitPawn.vMoveDirection = Vect(0, 0, 0);

	UnitPawn.m_fDistanceMovedAlongPath = Distance;

	CompleteAction();
}

DefaultProperties
{
}
