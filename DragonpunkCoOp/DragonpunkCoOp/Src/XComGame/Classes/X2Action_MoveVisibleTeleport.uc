//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MoveVisibleTeleport extends X2Action_Move;

//Cached info for the unit performing the action
//*************************************
var vector  Destination;
var float   Distance;

var	private	CustomAnimParams Params;
//*************************************

function ParsePathSetParameters(int InPathIndex, const out vector InDestination, float InDistance)
{
	PathIndex = InPathIndex;	
	Destination = InDestination;
	Distance = InDistance;
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	// Play the teleport start animation
	Params.AnimName = 'HL_TeleportStart';
	Params.PlayRate = GetMoveAnimationSpeed();
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	// Move the pawn to the end position
	Destination.Z = UnitPawn.GetDesiredZForLocation(Destination, true) + UnitPawn.GetAnimTreeController().ComputeAnimationRMADistance('HL_TeleportStop');	
	UnitPawn.SetLocation(Destination);		
	Unit.ProcessNewPosition( );

	// Play the teleport stop animation
	Params.AnimName = 'HL_TeleportStop';
	Params.BlendTime = 0;
	Params.HasDesiredEndingAtom = true;
	Params.DesiredEndingAtom.Translation = UnitPawn.Location;
	Params.DesiredEndingAtom.Translation.Z = UnitPawn.GetDesiredZForLocation(UnitPawn.Location);
	Params.DesiredEndingAtom.Rotation = QuatFromRotator(UnitPawn.Rotation);
	Params.DesiredEndingAtom.Scale = 1.0f;

	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);

	UnitPawn.Acceleration = Vect(0, 0, 0);
	UnitPawn.vMoveDirection = Vect(0, 0, 0);

	UnitPawn.m_fDistanceMovedAlongPath = Distance;

	CompleteAction();
}