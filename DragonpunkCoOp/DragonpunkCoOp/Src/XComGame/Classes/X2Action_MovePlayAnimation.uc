//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MovePlayAnimation extends X2Action_Move;

var vector      Destination;
var float       Distance;
var Name        AnimName;
var Actor       InteractWithActor;
var StateObjectReference InteractiveObjectReference;
var CustomAnimParams AnimParams;
var Rotator DesiredRotation;
var bool    bStoredSkipIK;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	FindActorByIdentifier(Unit.CurrentMoveData.MovementData[PathIndex].ActorId, InteractWithActor);
	if( XComInteractiveLevelActor(InteractWithActor) != none )
	{
		InteractiveObjectReference = `XCOMHISTORY.GetGameStateForObjectID(XComInteractiveLevelActor(InteractWithActor).ObjectID).GetReference();
	}

	PathTileIndex = FindPathTileIndex();
}

function ParsePathSetParameters(int InPathIndex, const out vector InDestination, float InDistance, Name InAnim)
{
	PathIndex = InPathIndex;	
	Destination = InDestination;
	Distance = InDistance;
	AnimName = InAnim;	
}

event OnAnimNotify(AnimNotify ReceiveNotify)
{
	local AnimNotify_KickDoor KickDoorNotify;

	super.OnAnimNotify(ReceiveNotify);

	KickDoorNotify = AnimNotify_KickDoor(ReceiveNotify);
	if( KickDoorNotify != none && InteractiveObjectReference.ObjectID > 0 )
	{
		VisualizationMgr.SendInterTrackMessage(InteractiveObjectReference);
	}
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true,true);
	UnitPawn.EnableRMAInteractPhysics(true);
	bStoredSkipIK = UnitPawn.bSkipIK;
	UnitPawn.bSkipIK = true;

	Destination.Z = Unit.GetDesiredZForLocation(Destination);

	// Start the animation
	AnimParams.AnimName = AnimName;
	AnimParams.PlayRate = GetMoveAnimationSpeed();
	AnimParams.HasDesiredEndingAtom = true;
	AnimParams.DesiredEndingAtom.Scale = 1.0f;
	AnimParams.DesiredEndingAtom.Translation = Destination;
	DesiredRotation = Normalize(Rotator(Destination - UnitPawn.Location));
	DesiredRotation.Pitch = 0;
	DesiredRotation.Roll = 0;
	AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(DesiredRotation);

	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	UnitPawn.bSkipIK = bStoredSkipIK;
	UnitPawn.EnableRMA(false,false);
	UnitPawn.EnableRMAInteractPhysics(false);

	UnitPawn.Acceleration = vect(0,0,0);
	UnitPawn.vMoveDirection = vect(0,0,0);
	// Tell the pawn he's moved
	if (Distance != 0.0f)
	{
		UnitPawn.m_fDistanceMovedAlongPath = Distance;
	}

	CompleteAction();
}

DefaultProperties
{
}
