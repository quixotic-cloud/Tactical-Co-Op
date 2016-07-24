class X2Action_Grapple extends X2Action_Fire;

var vector  DesiredLocation;

var private BoneAtom StartingAtom;
var private Rotator DesiredRotation;
var private CustomAnimParams Params;
var private vector StartingLocation;
var private float DistanceFromStartSquared;
var private bool ProjectileHit;
var private float StopDistanceSquared; // distance from the origin of the grapple past which we are done

function ProjectileNotifyHit(bool bMainImpactNotify, Vector HitLocation)
{
	ProjectileHit = true;
}

simulated state Executing
{
	function SendWindowBreakNotifies()
	{
		local XComGameStateVisualizationMgr VisualizationManager;
		local XComGameState_EnvironmentDamage EnvironmentDamage;
		local StateObjectReference DamageRef;

		VisualizationManager = `XCOMVISUALIZATIONMGR;
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
		{
			DamageRef = EnvironmentDamage.GetReference();
			VisualizationManager.SendInterTrackMessage(DamageRef);
		}
	}

Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bSkipIK = true;

	Params.AnimName = 'NO_GrappleFire';
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	while( ProjectileHit == false )
	{
		Sleep(0.0f);
	}

	// Have an emphasis on seeing the grapple tight
	Sleep(0.1f);

	Params.AnimName = 'NO_GrappleStart';
	DesiredLocation.Z = Unit.GetDesiredZForLocation(DesiredLocation);
	DesiredRotation = Rotator(Normal(DesiredLocation - UnitPawn.Location));
	StartingAtom.Rotation = QuatFromRotator(DesiredRotation);
	StartingAtom.Translation = UnitPawn.Location;
	StartingAtom.Scale = 1.0f;
	UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(Params, StartingAtom);
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// hide the targeting icon
	Unit.SetDiscState(eDS_None);

	StartingLocation = UnitPawn.Location;
	StopDistanceSquared = Square(VSize(DesiredLocation - StartingLocation) - UnitPawn.fStrangleStopDistance);

	// to protect against overshoot, rather than check the distance to the target, we check the distance from the source.
	// Otherwise it is possible to go from too far away in front of the target, to too far away on the other side
	DistanceFromStartSquared = 0;
	while( DistanceFromStartSquared < StopDistanceSquared )
	{
		Sleep(0.0f);
		DistanceFromStartSquared = VSizeSq(UnitPawn.Location - StartingLocation);
	}

	// send messages to do the window break visualization
	SendWindowBreakNotifies();

	Params.AnimName = 'NO_GrappleStop';
	Params.HasDesiredEndingAtom = true;
	Params.DesiredEndingAtom.Scale = 1.0f;
	Params.DesiredEndingAtom.Translation = DesiredLocation;
	DesiredRotation = UnitPawn.Rotation;
	DesiredRotation.Pitch = 0.0f;
	DesiredRotation.Roll = 0.0f;
	Params.DesiredEndingAtom.Rotation = QuatFromRotator(DesiredRotation);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));
	UnitPawn.bSkipIK = false;

	CompleteAction();
}

function CompleteAction()
{
	super.CompleteAction();

	// since we step out of and step into cover from different tiles, 
	// need to set the enter cover restore to the destination location
	Unit.RestoreLocation = DesiredLocation;
}

defaultproperties
{
	ProjectileHit = false;
}