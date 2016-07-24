//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_UnitFallingNoRagdoll extends X2Action;

var private XComGameStateContext_Falling FallingContext;
var private XComGameState_Unit NewUnitState;

var private vector LandingLocation;
var private vector EndingLocation;
var private int LocationIndex;

var private float fPawnHalfHeight;
var private XComWorldData WorldData;

var private TTile DamageTile;
var private TTile StupidTile; // because unreal won't allow passing elements of dynamic arrays as const out params!!!!!

var private vector ImpulseDirection;
var private float fImpulseMag;

var private X2Camera_FallingCam FallingCamera;

var private CustomAnimParams AnimParams;
var private BoneAtom DesiredStartingAtom;

function Init(const out VisualizationTrack InTrack)
{
	super.Init( InTrack );
	WorldData = `XWORLD;

	FallingContext = XComGameStateContext_Falling( StateChangeContext );

	LocationIndex = 0;

	StupidTile = FallingContext.LandingLocations[0];
	LandingLocation = WorldData.GetPositionFromTileCoordinates(StupidTile);

	StupidTile = FallingContext.EndingLocations[0];
	EndingLocation = WorldData.GetPositionFromTileCoordinates(StupidTile);

	fPawnHalfHeight = UnitPawn.CylinderComponent.CollisionHeight;

	NewUnitState = XComGameState_Unit(InTrack.StateObject_NewState);
}

function MaybeNotifyEnvironmentDamage( )
{
	local XComGameState_EnvironmentDamage EnvironmentDamage;
	local StateObjectReference DmgObjectRef;
	local TTile CurrentTile;
	local Vector PawnLocation;
	local int ZOffset;
	
	PawnLocation = UnitPawn.GetCollisionComponentLocation();
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(PawnLocation);
	if (CurrentTile.Z > DamageTile.Z)
	{
		return;
	}

	DamageTile = CurrentTile;	
	--DamageTile.Z;
		
	foreach FallingContext.AssociatedState.IterateByClassType( class'XComGameState_EnvironmentDamage', EnvironmentDamage )
	{
		//Iterate downward a short distance from where we are, as this will sync the destruction better with the motion of the ragdoll
		for(ZOffset = 0; ZOffset > -4; --ZOffset)
		{	
			--CurrentTile.Z;
			if(EnvironmentDamage.HitLocationTile == DamageTile)
			{
				DmgObjectRef = EnvironmentDamage.GetReference();
				VisualizationMgr.SendInterTrackMessage(DmgObjectRef);
			}
		}
		
	}
}

function CompleteAction()
{
	super.CompleteAction();
	//`CAMERASTACK.RemoveCamera(FallingCamera);//RAM - disable until more testing
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event EndState( name nmNext )
	{
		if (IsTimedOut()) // just in case something went wrong, get the pawn into the proper state
		{
			UnitPawn.SetLocation( EndingLocation );
		}
	}

	function StartFallingCamera()
	{
		FallingCamera = new class'X2Camera_FallingCam';
		FallingCamera.UnitToFollow = Unit;
		FallingCamera.TraversalStartPosition = WorldData.GetPositionFromTileCoordinates(FallingContext.StartLocation);
		StupidTile = FallingContext.LandingLocations[LocationIndex];
		FallingCamera.TraversalEndPosition = WorldData.GetPositionFromTileCoordinates(StupidTile);
		`CAMERASTACK.AddCamera(FallingCamera);
	}

Begin:
	//StartFallingCamera(); //RAM - disable until more testing
	UnitPawn.DeathRestingLocation = EndingLocation;

	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'MV_ClimbFall_Start';
	DesiredStartingAtom.Translation = LandingLocation;
	DesiredStartingAtom.Translation.Z = UnitPawn.Location.Z;
	DesiredStartingAtom.Rotation = QuatFromRotator(UnitPawn.Rotation);
	DesiredStartingAtom.Scale = 1.0f;
	UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(AnimParams, DesiredStartingAtom);
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

	DamageTile = FallingContext.StartLocation;

	while( LocationIndex < FallingContext.EndingLocations.Length )
	{
		StupidTile = FallingContext.LandingLocations[ LocationIndex ];
		LandingLocation = WorldData.GetPositionFromTileCoordinates( StupidTile );

		StupidTile = FallingContext.EndingLocations[ LocationIndex ];
		EndingLocation = WorldData.GetPositionFromTileCoordinates( StupidTile );

		UnitPawn.UpdateRagdollLinearDriveDestination(LandingLocation);
		UnitPawn.DeathRestingLocation = LandingLocation;

		while (UnitPawn.GetCollisionComponentLocation().Z >(LandingLocation.Z + fPawnHalfHeight + 5))
		{
			Sleep( 0.00f );
			MaybeNotifyEnvironmentDamage( );
		}

		if (LandingLocation != EndingLocation)
		{
			UnitPawn.DeathRestingLocation = EndingLocation;
			// wait for it to get into the right tile column
			if(VSizeSq2D(UnitPawn.GetCollisionComponentLocation() - EndingLocation) > Square(class'XComWorldData'.const.WORLD_StepSize / 4))
			{
				UnitPawn.EnableRMA(true, true);
				UnitPawn.EnableRMAInteractPhysics(true);

				AnimParams = default.AnimParams;
				AnimParams.AnimName = 'MV_ClimbFall_Start';
				DesiredStartingAtom.Translation = LandingLocation;
				DesiredStartingAtom.Translation.Z = UnitPawn.Location.Z;
				DesiredStartingAtom.Rotation = QuatFromRotator(UnitPawn.Rotation);
				DesiredStartingAtom.Scale = 1.0f;
				UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(AnimParams, DesiredStartingAtom);
				UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
			}

			DamageTile = FallingContext.EndingLocations[ LocationIndex ];
		}

		++LocationIndex;
	}

	MaybeNotifyEnvironmentDamage();

	UnitPawn.DeathRestingLocation = EndingLocation;

	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	AnimParams = default.AnimParams;
	AnimParams.HasDesiredEndingAtom = true;
	AnimParams.DesiredEndingAtom.Translation = EndingLocation;
	AnimParams.DesiredEndingAtom.Translation.Z = UnitPawn.GetGameUnit().GetDesiredZForLocation(AnimParams.DesiredEndingAtom.Translation);
	AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(UnitPawn.Rotation);
	AnimParams.DesiredEndingAtom.Scale = 1.0f;
	if (!NewUnitState.IsDead() && !NewUnitState.IsIncapacitated())
	{
		AnimParams.AnimName = 'MV_ClimbFall_Stop';
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

		Unit.IdleStateMachine.CheckForStanceUpdate();
	}
	else
	{
		AnimParams.AnimName = 'MV_ClimbFall_Death';
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	}

	UnitPawn.SetLocation(AnimParams.DesiredEndingAtom.Translation);
	
	CompleteAction();
}

event HandleNewUnitSelection()
{
	if( FallingCamera != None )
	{
		`CAMERASTACK.RemoveCamera(FallingCamera);
		FallingCamera = None;
	}
}

defaultproperties
{
	TimeoutSeconds = 10.0f
}