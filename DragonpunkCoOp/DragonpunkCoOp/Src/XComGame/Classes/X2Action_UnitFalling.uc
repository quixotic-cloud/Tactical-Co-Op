//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_UnitFalling extends X2Action;

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
var private float SingleTileFallStartTime;

var bool StartingAllowAnimations;

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
	local XComGameState_EnvironmentDamage EnvironmentDamage;
	local StateObjectReference DmgObjectRef;

	super.CompleteAction();
	//`CAMERASTACK.RemoveCamera(FallingCamera);//RAM - disable until more testing

	// do a last-ditch trigger of any remaining damage states.  this is similar to X2Action_MoveEnd.FinalNotifyEnvironmentDamage
	foreach FallingContext.AssociatedState.IterateByClassType( class'XComGameState_EnvironmentDamage', EnvironmentDamage )
	{
		DmgObjectRef = EnvironmentDamage.GetReference( );
		VisualizationMgr.SendInterTrackMessage( DmgObjectRef );
	}
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event EndState( name nmNext )
	{
		if (IsTimedOut()) // just in case something went wrong, get the pawn into the proper state
		{
			UnitPawn.EndRagDoll( );
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

	function CopyPose()
	{
		AnimParams.AnimName = 'Pose';
		AnimParams.Looping = true;
		AnimParams.BlendTime = 0.0f;
		AnimParams.HasPoseOverride = true;
		AnimParams.Pose = UnitPawn.Mesh.LocalAtoms;
		UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}

Begin:
	//StartFallingCamera(); //RAM - disable until more testing
	UnitPawn.DeathRestingLocation = EndingLocation;

	UnitPawn.EnableFootIK(false);

	StartingAllowAnimations = UnitPawn.GetAnimTreeController().GetAllowNewAnimations();
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

	// Lets put him in the first couple frames of the get up animation to get him to land on his back
	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'HL_GetUp';
	AnimParams.BlendTime = 0.33f;
	AnimParams.PlayRate = 0.1;
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);

	// Small sleep helps unit animate to his back a bit before ragdoll takes over
	Sleep(0.01f);

	UnitPawn.SetFinalRagdoll(false);
	UnitPawn.StartRagdoll( true, , , false );

	DamageTile = FallingContext.StartLocation;

	while (LocationIndex < FallingContext.LandingLocations.Length)
	{
		StupidTile = FallingContext.LandingLocations[ LocationIndex ];
		LandingLocation = WorldData.GetPositionFromTileCoordinates( StupidTile );

		StupidTile = FallingContext.EndingLocations[ LocationIndex ];
		EndingLocation = WorldData.GetPositionFromTileCoordinates( StupidTile );

		UnitPawn.UpdateRagdollLinearDriveDestination(LandingLocation);
		UnitPawn.DeathRestingLocation = LandingLocation;

		SingleTileFallStartTime = ExecutingTime;
		while (UnitPawn.GetCollisionComponentLocation().Z >(LandingLocation.Z + fPawnHalfHeight + 5) && 
			   (ExecutingTime - SingleTileFallStartTime < 1.0) )  // mini timeout to prevent long fall times
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
				// apply an impulse in the right direction and a bit up (for a bounce like effect)
				ImpulseDirection = EndingLocation - UnitPawn.GetCollisionComponentLocation();
				ImpulseDirection.Z = VSize2D(ImpulseDirection)*2;
				ImpulseDirection = Normal(ImpulseDirection);
				fImpulseMag = VSize2D(UnitPawn.GetCollisionComponentLocation() - EndingLocation)*8;
				UnitPawn.Mesh.AddImpulse(ImpulseDirection * fImpulseMag);
				Sleep( 0.0f );
			}

			DamageTile = FallingContext.EndingLocations[ LocationIndex ];
		}

		++LocationIndex;
	}

	UnitPawn.UpdateRagdollLinearDriveDestination(EndingLocation);
	UnitPawn.DeathRestingLocation = EndingLocation;

	Sleep(1.0f * GetDelayModifier()); // let them ragdoll for a bit, for effect.

	//Experimental, there are no shipping game mechanics that knock back but allow the target to survive.
	if (!NewUnitState.IsDead() && !NewUnitState.IsIncapacitated())
	{
		//Make a fancier transition out of ragdoll if needed 

		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

		// Before copying the pose, make sure the pawn is on the ground, and the skeleton has been updated to reflect this new position
		UnitPawn.SetLocation(EndingLocation);
		UnitPawn.Mesh.ForceSkelUpdate();

		// Copy all the bone transforms so we match his pose
		CopyPose();
		UnitPawn.EndRagDoll();

		// After ragdoll has ended, set the pawn location again, otherwise he is in the air
		UnitPawn.SetLocation(EndingLocation);

		Unit.ResetWeaponsToDefaultSockets(); //Grab the gun back if needed	

		UnitPawn.EnableRMA(true, true);
		UnitPawn.EnableRMAInteractPhysics(true);
		UnitPawn.EnableFootIK(false);
		

		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'HL_GetUp';
		AnimParams.BlendTime = 0.5f;
		AnimParams.HasDesiredEndingAtom = true;
		AnimParams.DesiredEndingAtom.Translation = EndingLocation;
		AnimParams.DesiredEndingAtom.Translation.Z = UnitPawn.GetGameUnit().GetDesiredZForLocation(AnimParams.DesiredEndingAtom.Translation);
		AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(UnitPawn.Rotation);
		AnimParams.DesiredEndingAtom.Scale = 1.0f;
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

		UnitPawn.EnableFootIK(true);
		UnitPawn.EnableRMA(false, false);
		UnitPawn.EnableRMAInteractPhysics(false);

		Unit.IdleStateMachine.CheckForStanceUpdate();
	}
	
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(StartingAllowAnimations);

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