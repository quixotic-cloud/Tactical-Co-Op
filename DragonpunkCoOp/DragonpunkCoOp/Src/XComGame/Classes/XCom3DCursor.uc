/**
 * XCom3DCursor
 * Demo pawn demonstrating animating character.
 *
 * Copyright 1998-2008 Epic Games, Inc. All Rights Reserved.
 */

class XCom3DCursor extends XComPawn
	native(Unit)
	config(GameCore);

var const config float CursorFloorHeight; // how high is each floor, in unreal units?
var const config float MinDrawCylinderHeightThreshold; // how high above the ground, in units, must a flying unit be before drawing the height cylinder

var protected int CachedMaxFloor; // cached from the plot definition of the current map. Don't use directly, instead call GetMaxFloor()
var protected float CachedCursorFloorOffset; // // cached from the plot definition of the current map.

struct native CursorSearchResult
{
	var Vector m_kLocation;
	var int m_iEffectiveFloor;
	var float m_fFloorBottom;
	var float m_fFloorTop;
	var bool m_bOnGround;

	structcpptext
	{
		FCursorSearchResult()
		{
			appMemzero(this, sizeof(FCursorSearchResult));
		}

		FCursorSearchResult(EEventParm)
		{
			appMemzero(this, sizeof(FCursorSearchResult));
		}
	}
};

enum CursorSearchDirection
{
	eCursorSearch_Down,
	eCursorSearch_Up,
	eCursorSearch_ExactFloor
};

var bool m_bPathingNeedsUpdate;

cpptext
{
	// AActor collision functions.
	virtual UBOOL ShouldTrace(UPrimitiveComponent* Primitive,AActor *SourceActor, DWORD TraceFlags);

	// MHU - We're still using default Unreal pawn physics, but we disallow it from
	//       setting any state except for PHYS_None, PHYS_Flying, and PHYS_Walking.
	virtual void setPhysics(BYTE NewPhysics, AActor *NewFloor = NULL, FVector NewFloorV = FVector(0,0,1) );

	virtual void physWalking(FLOAT deltaTime, INT Iterations);
	virtual void physFlying(FLOAT deltaTime, INT Iterations);
	virtual void physicsRotation(FLOAT deltaTime, FVector OldVelocity);
	virtual void CalcVelocity(FVector &AccelDir, FLOAT DeltaTime, FLOAT MaxSpeed, FLOAT Friction, INT bFluid, INT bBrake, INT bBuoyant);

private:
	// Certain values for the number of floors and the base floor offset need to be specified per plot, but looking up the plot every
	// access is expensive. This helper function exists to cache those values if they haven't already been.
	void CachePlotDefinitionValues();
}

var InstancedStaticMeshComponent m_LevelBorderWall;
var StaticMeshComponent m_kHeightCylinder;

var() editconst const DecalComponent Decal;

// The pawn that we are chained to
var transient XComUnitPawnNativeBase ChainedPawn;

// Requested floor is the floor as selected by the user up/down.
var int                         m_iRequestedFloor;
var float                       m_fLogicalCameraFloorHeight; // camera will be positioned a fixed height above this value.
var float                       m_fBuildingCutdownHeight; // z-value of an invisible plane below which buildings will be cutdown when using mouse style cutdowns.

var bool                        m_bLastCursorInBuildingStatus;
var bool                        m_bIgnoreCursorSnapToFloor;

// Cursor in air is used to indicate the user's intent of whether the cursor should snap to the ground,
// or if it should float in the air. Normally when not flying, you want the cursor to stick to the ground
// no matter what floor you are on. Per Jake, we should be able to "launch" the cursor into the air
// by pressing up and then the cursor will behave as if you were flying until you set it back down on the ground
// by explicitly pressing down to "land" it.
var bool                        m_bCursorLaunchedInAir;

var int                         m_iLastEffectiveFloorIndex;
var Actor                       m_kTouchingActor;

var bool                        m_bHoverFailDetectedToggle; // Just needs to be toggled whenever hover fail has been detected.

// MHU - Variables used to control distance cursor can travel from pawn.
var float                       m_fMaxChainedDistance;
var float                       m_fMinChainedDistance;
var vector                      PreviousChainedCursorPosition;  //Used to detect mouse movement
var float						ChainedCursorUpdateTimer;       //Used to eliminate mouse hysteresis

// JMS - an occlusion factor averaged over many frames, calculated via line checks
var float                       m_fCursorOcclusion;
var float                       m_fCutoutFadeFactor;
var bool                        m_bOccluded;
var bool                        m_bHiddenOverride; // this is a temp fix for demo
var vector2D                    m_vCutoutExtent;
var float                       m_fCursorExtentFactor;

////////////////////////
// Native functions
////////////////////////
native function int GetMaxFloor();
native function bool IsCursorOccluded();
native function bool CameraLineCheck( Vector PositionToTest, out Vector OutFurthestOccluder  );
native function UpdateCursorVisibility();
simulated native private function DisplayHeightDifferences();

simulated native private function CursorSearchResult CursorSnapToFixedFloors(float fCollisionRadius, 
																			 int iDesiredFloor,
																			 CursorSearchDirection eSearchType);

simulated native private function Vector ProcessChainedDistance(Vector vLocation);

native function int WorldZToFloor(Vector kLocation);
native function float WorldZFromFloor(int iFloor);
native function float GetFloorMinZ(int iFloor);
native function float GetFloorMaxZ(int iFloor);

native function bool ShouldSearchExactFloors();

////////////////////////
// Script functions
////////////////////////
simulated event PostBeginPlay()
{
	local StaticMesh CylinderMesh;

	super.PostBeginPlay();

	CollisionComponent.SetBlockRigidBody(true);

`if(`notdefined(FINAL_RELEASE))
	//RAM - SCRIPT DEBUG - REMOVE FOR FINAL
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(self, 'Location', self, OnCursorMoved);
`endif
	
	CylinderMesh = StaticMesh(`CONTENT.GetGameContent("UnitCursor.CursorHeight.cursorHeightCyl"));
	m_kHeightCylinder.SetStaticMesh(CylinderMesh);
}

`if(`notdefined(FINAL_RELEASE))
function OnCursorMoved()
{
	local XComCheatManager CheatMgr;
	local Vector vLoc;	
	
	CheatMgr = XComCheatManager(GetALocalPlayerController().CheatManager);
	if( CheatMgr.bDebuggingVisibilityToCursor )
	{
		vLoc = CheatMgr.Outer.Pawn.Location;	
		`XWORLD.DebugUpdateVisibilityMapForViewer(CheatMgr.m_kVisDebug.GetPawn(), vLoc);
	}
}
`endif

reliable server function ServerGotoState(name nmState)
{
	if(GetStateName() != nmState)
	{
		GotoState(nmState);
	}
}

function Vector GetCursorFeetLocation()
{
	local Vector vFeetLocation;

	vFeetLocation = Location;
	vFeetLocation.Z -= CylinderComponent(CollisionComponent).CollisionHeight;

	return vFeetLocation;
}

simulated native function SetHidden(bool bNewHidden);

simulated function SetForceHidden(bool bHiddenOverride)
{
	m_bHiddenOverride = bHiddenOverride;
	SetHidden(bHiddenOverride);
}

simulated event FellOutOfWorld(class<DamageType> dmgType)
{
	local Vector kAdjustedLocation;
	kAdjustedLocation = Location;
	kAdjustedLocation.Z = 0.0;
	CursorSetLocation(kAdjustedLocation, false);
}

reliable server function ServerSetChainedPawn(XComUnitPawn kChainedPawn)
{
	ChainedPawn = kChainedPawn;
}

simulated function MoveToUnit( XComUnitPawn Unit, optional bool bSetCamView=true, optional bool bResetChainedDistance=true )
{
	local Vector kLocation;
	
	if( bResetChainedDistance )
	{
		// Exploit fix: don't reset the chain distances if a targeting method is currently active. 
		// You could throw a grenade completely across the map if we did that
		if(`Pres.m_kTacticalHUD.m_kAbilityHUD.TargetingMethod == none)
		{
			m_fMaxChainedDistance = 0;
			m_fMinChainedDistance = 0;
		}

		ChainedPawn = Unit;
		if(Role < ROLE_Authority)
		{
			ServerSetChainedPawn(Unit);
		}
	}

	kLocation = Unit.Location;
	kLocation.Z -= Unit.GetCollisionHeight() * 0.5;
	MoveToLocation( kLocation, bSetCamView );
}

simulated function CursorSetLocation(Vector newLoc, optional bool bResetSpeedCurveRampUp = true, optional bool bSnapToValidPosition=true)
{
	local Vector validLoc;
	local XComWorldData kWorldData;

	newLoc = ProcessChainedDistance(newLoc);

	kWorldData = `XWORLD;
	if (bSnapToValidPosition && kWorldData != none)
		validLoc = `XWORLD.GetClosestValidCursorPosition(newLoc);
	else
		validLoc = newLoc;

	if(m_eTeam == GetALocalPlayerController().m_eTeam)
	{
		if (bResetSpeedCurveRampUp && VSize(newLoc-Location) > 32)
		{
			//`CAMERAMGR.ResetCameraSpeedCurveRampUp(0.05);
		}
	}

	validLoc.Z += CylinderComponent(CollisionComponent).CollisionHeight;

	SetLocation(validLoc);

	m_bPathingNeedsUpdate = true;
}

exec function TestMove()
{
	MoveToLocation( Location, true );
}

simulated event SetVisible(bool bVisible)
{
	super.SetVisible(bVisible);
}

function MoveToLocation( vector Pos, bool bSetCamView )
{
	local rotator rotOnlyYaw;

	GotoState('');
	ServerGotoState('');
	SetPhysics( PHYS_None ); 
	SetCollision( false, false ); // MHU - This && physics change allows cursor to travel into/out of buildings seamlessly at varying floor heights.
	CursorSetLocation( Pos );

	// cursor should be oriented flat. this fixes an MP problem where the cursor was pitched/rolled. -tsmith 
	rotOnlyYaw = Rotation;
	rotOnlyYaw.Pitch = 0;
	rotOnlyYaw.Roll = 0;
	SetRotation(rotOnlyYaw);

	//  jbouscher - Manually clear building and floor volumes as they should have been all untouched when we turned collision off, but this doesn't always happen correctly.
	IndoorInfo.CurrentBuildingVolume = none;
	IndoorInfo.CurrentFloorVolumes.Length = 0;

	SetCollision( default.bCollideActors, default.bBlockActors );

	GotoState('CursorMode_NoCollision');
	ServerGotoState('CursorMode_NoCollision');
}

function AscendFloor()
{
}

reliable server function ServerAscendFloor()
{
	AscendFloor();
}

function DescendFloor()
{
}

reliable server function ServerDescendFloor()
{
	DescendFloor();
}

// This will attempt to snap to the requested floor, but if it cannot, 
// it will do the best it can. Check the return value to see which floor
// the cursor ended up on
simulated function CursorSearchResult CursorSnapToFloor(int iDesiredFloor, optional CursorSearchDirection eSearchType = eCursorSearch_Down)
{
	local CursorSearchResult kResult;
	local float CollisionRadius;

	if(ShouldSearchExactFloors())
	{
		eSearchType = eCursorSearch_ExactFloor;
	}

	// make the radius much smaller than it actually is, we only want to center of the cursor to feel "solid".
	// otherwise you could be hovering off the edge of a roof by just the very edge of the cursor, which feels
	// strange.
	CollisionRadius = CylinderComponent(CollisionComponent).CollisionRadius * 0.1;

	// now we need to do our search.
	kResult = CursorSnapToFixedFloors(CollisionRadius * 0.1, 
									  iDesiredFloor,
									  eSearchType);

	// we've traced and have a cursor point, so set it
	CursorSetLocation(kResult.m_kLocation, false);
	m_fLogicalCameraFloorHeight = kResult.m_fFloorBottom;
	m_fBuildingCutdownHeight = kResult.m_fFloorTop;

	m_iLastEffectiveFloorIndex = kResult.m_iEffectiveFloor;
	return kResult;
}

protected function bool DisableFloorChanges()
{
	// Don't allow user to change elevations in the tutorial if we're not supposed to.
	// disabled for x2, but leaving this function here as we'll likely want to do this again
	return false;
}

state CursorMode_NoCollision
{
	function Reset()
	{		
		local XGUnit kActiveUnit;
		local XComUnitPawnNativeBase kActiveUnitPawn;
		local CursorSearchResult kResult;

		m_bLastCursorInBuildingStatus = false;
		m_iLastEffectiveFloorIndex = 0;
		m_fLogicalCameraFloorHeight = 0.0;
		m_fBuildingCutdownHeight = 0.0;
		m_iRequestedFloor = 0;

		kActiveUnitPawn = ChainedPawn;

		// no explicit chained pawn, so fall back to using the currently active soldier
		if(kActiveUnitPawn == none)
		{
			kActiveUnit = XComTacticalController( Owner ).GetActiveUnit();
			if(kActiveUnit != none)
			{
				kActiveUnitPawn = kActiveUnit.GetPawn();
			}
		}

		// reset our desired floor to match the unit we want to control
		if(kActiveUnitPawn != none)
		{
			m_iRequestedFloor = GetIdealPawnFloor(kActiveUnitPawn);
			kResult = CursorSnapToFloor(m_iRequestedFloor);
			m_fLogicalCameraFloorHeight = kResult.m_fFloorBottom;
		}
	}

	protected function int GetIdealPawnFloor(XComUnitPawnNativeBase kPawn)
	{
		return WorldZToFloor(kPawn.Location);
	}

	event BeginState( name P )
	{
		bCollideWorld = false; // MHU Could be reset to true during gameplay.
		AccelRate=0;
		SetPhysics( PHYS_Flying );

		Reset();
	}

	event Tick( float DeltaTime )
	{
		local bool bCursorMoved;
		local CursorSearchResult Result;

		if ( ChainedPawn != none )
		{
			if( XComTacticalController( Owner ).IsMouseActive() )
			{
				bCursorMoved = true;

				ChainedCursorUpdateTimer += DeltaTime;
				if( VSizeSq(PreviousChainedCursorPosition - Location) > 9216.0f ) //96 units sq'd ( 1 tile )
				{						
					ChainedCursorUpdateTimer = 0.0f;
					PreviousChainedCursorPosition = Location;
				}

				if( ChainedCursorUpdateTimer > 0.25f )
				{
					bCursorMoved = false;
				}
			}
			else
			{
				bCursorMoved = VSizeSq(Velocity) > 1.0f;
			}

			if (!m_bIgnoreCursorSnapToFloor && bCursorMoved)
			{
				Result = CursorSnapToFloor(m_iRequestedFloor);
				class'Engine'.static.GetCurrentWorldInfo().WorldCascadeZ = Result.m_kLocation.Z;
			}
		}
		else
		{
			AbortState_ChainedToUnit();
		}

		DisplayHeightDifferences();
		UpdateCursorVisibility();

		// Need to set this for any materials that may use the XComCursorPosition node
		class'WorldInfo'.static.GetWorldInfo().SetXComCursorPosition(Location);
	}

	event EndState( name N )
	{
	}

	function AscendFloor()
	{
		local CursorSearchResult kResult;

		if(DisableFloorChanges()) return;

		if(Role < ROLE_Authority)
		{
			ServerAscendFloor();
		}
		
		// when the user wants to ascend, they are wanting to ascend from the floor where the cursor is.
		// The last requested floor could be different if they were on top of a building and then
		// then dropped down to the ground, for example, so always make sure to use the last effective floor
		m_iRequestedFloor = min(m_iLastEffectiveFloorIndex + 1, GetMaxFloor());

		// update cursor height switching logic. Only increase our requested floor
		// if the user was able to see a change (i.e., the effective floor also increased)
		kResult = CursorSnapToFloor(m_iRequestedFloor, eCursorSearch_Up);
		m_bCursorLaunchedInAir = !kResult.m_bOnGround;
		if(kResult.m_iEffectiveFloor > m_iRequestedFloor)
		{
			m_iRequestedFloor = kResult.m_iEffectiveFloor; // in case we jumped more than one floor
		}
		class'Engine'.static.GetCurrentWorldInfo().WorldCascadeZ = kResult.m_kLocation.Z;
	}

	function DescendFloor()
	{
		local CursorSearchResult kResult;

		if(DisableFloorChanges()) return;

		if(Role < ROLE_Authority)
		{
			ServerDescendFloor();
		}

		m_iRequestedFloor = max(m_iLastEffectiveFloorIndex - 1, 0);

		// update cursor height switching logic. Only decrease our requested floor
		// if the user was able to see a change (i.e., the effective floor also decreased)
		kResult = CursorSnapToFloor(m_iRequestedFloor, eCursorSearch_ExactFloor);
		m_bCursorLaunchedInAir = !kResult.m_bOnGround;
		if(kResult.m_iEffectiveFloor > m_iRequestedFloor)
		{
			m_iRequestedFloor++;
		}
		else
		{
			m_iRequestedFloor = kResult.m_iEffectiveFloor; // in case we jumped more than one floor
		}
		class'Engine'.static.GetCurrentWorldInfo().WorldCascadeZ = kResult.m_kLocation.Z;
	}

	function AbortState_ChainedToUnit()
	{
		SetPhysics( PHYS_Flying );
		GotoState( '' );
		ServerGotoState( '' );
	}

	event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
	{
		super.Touch(Other, OtherComp, HitLocation, HitNormal);

		if(Other.IsA('XComUnitPawn'))
		{
			m_kTouchingActor = Other;
		}
	}
	event UnTouch( Actor Other )
	{
		super.UnTouch(Other);

		if(Other == m_kTouchingActor)
		{
			m_kTouchingActor = none;
		}
	}
}

simulated function LogDebugInfo()
{
	super.LogDebugInfo();

	`log( "bCollideActors:"@bCollideActors );
	`log( "bBlockActors:"@bBlockActors );
	`log( "bProjTarget:"@bProjTarget );
}

defaultproperties
{	
	Begin Object Name=CollisionCylinder
		CollisionRadius=+032.000000
		CollisionHeight=+064.000000
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=true
		RBCollideWithChannels=(Default=false,BlockingVolume=true,Pawn=true)
		RBChannel=RBCC_Nothing
		CanBlockCamera=false
	End Object

	begin object class=InstancedStaticMeshComponent name=LevelBorderWall
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.FloorTile'
		HiddenGame=false
		HiddenEditor=true
	end object
	Components.Add(LevelBorderWall);
	m_LevelBorderWall=LevelBorderWall;

	begin object class=StaticMeshComponent name=HeightDifferenceCylinder
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		HiddenGame=true
		HiddenEditor=true
		Scale3D=(X=1,Y=1,Z=1)
	end object
	Components.Add(HeightDifferenceCylinder);
	m_kHeightCylinder=HeightDifferenceCylinder;

	// MHU Uncollidable cursor changes
	bCollideWorld=true
	bCanStepUpOn=true

	DrawScale=0.625

	// cjcone@psyonix: set to true to trigger touch events on other actors
	bCollideActors=true
	bBlockActors=false
	bProjTarget=false

	MaxStepHeight=26
	WalkableFloorZ=.10f

	Health=10000000
	HealthMax=10000000

	AirSpeed=8192.0f
	GroundSpeed=1200.0f
	AccelRate=0.0f        // 2*Normal rate
	//AirControl=100

	// Network variables -tsmith 
	// TODO: don't replicate with the new gamestate system -tsmith
	RemoteRole=ROLE_SimulatedProxy
	m_bReplicateHidden=false
	bAlwaysRelevant=false
	// TODO: bOnlyRelevantToFriendlies -tsmith 
	bOnlyRelevantToOwner=true
	bUpdateSimulatedPosition=false
	m_bPerformPhysicsForRoleAutonomous=true

	m_iRequestedFloor=0
	CachedMaxFloor=-1

	m_bLastCursorInBuildingStatus=false
	m_bIgnoreCursorSnapToFloor=false;
	m_bPathingNeedsUpdate=true;

	bDoNotTriggerSeqEventTouch=true
}
