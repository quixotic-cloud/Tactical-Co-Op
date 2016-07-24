class XComFracLevelActor extends FracturedStaticMeshActor 
	implements(XComCoverInterface)
	implements(Destructible)
	implements(IMouseInteractionInterface)
	dependson(XComLevelActor)
	dependson(XComDestructibleActor_Toughness)
	native(Destruction)
	placeable;

// Mask for visibility bit
const DamageDelay = 0.15f;

var() const editconst XComFloorComponent FloorComponent;

var() bool HideableWhenBlockingObjectOfInterest;

var() VisibilityBlocking VisibilityBlockingData;

/** An actor that should toggle hidden when this once does **/
var() Actor HidingPartner;

/** If set to true the 3d cursor will not consider this object for collision **/
var() const bool bIgnoreFor3DCursorCollision;

/** Indicates that this actor is a stair or stairwell. Will cause the 3D cursor to jump up to the next floor when it reaches the top. **/
var() const bool bIsStair;

/** Fracture regardless of damage-type */
var() bool bAlwaysFracture;
var() bool bAlwaysDestroyColumns;

var(Cover) bool bAlwaysConsiderForCover<DisplayName=Consider For Occupancy Checks?>;
var(Cover) bool bCanClimbOver;
var(Cover) bool bCanClimbOnto;
var(Cover) bool bIsValidDestination;/** Set to FALSE if units should not be able to finish their move on top of this object */
var(Cover) bool bIgnoreForCover;
var(Cover) bool bUseRigidBodyCollisionForCover;
var(Cover) ECoverForceFlag CoverForceFlag;
var(Cover) ECoverForceFlag CoverIgnoreFlag;

var(Pathing) bool bIsFloor;

var Box LastFilterBox;

var() XComDestructibleActor_Toughness Toughness<ToolTip="The health/damage taking characteristics of this actor (assign from GameData/Toughness)">;

var init array<int> SavedVisibleFragments;

/** Used to block tile lighting. (For Interior/Exterior Lighting) */
var() bool bBlockInteriorLighting;

/** Used to indicate this actor should use a larger extent check for cutouts */
var() bool bPrimaryCutoutActor;

//=======================================================================================
//X-Com 2 Refactoring
//
//Member variables go in here, everything else will be re-evaluated to see whether it 
//needs to be moved, kept, or removed.

var transient privatewrite int ObjectID;                  //Unique identifier for this object - used for network serialization and game state searches
//=======================================================================================


/** Effects which spawn as a result of fracture chunk removal. */
var() editinline array<FractureEffect> FractureEffects;

/** WeaponFXParams to use to feed weapon-based parameters to the FractureEffect. This should eventually be moved to the damage type but for
 *  now it can be assigned per-actor for iteration. */
var() XComDamageFXParams DamageParams;

var transient float TimeUntilDamageResolve;

var transient bool bNeedsDamageResolution;

var transient bool bDelayDamageReattach;
var transient bool bCollisionDisableTimerActive;    // whether the collision disabled timer is active
var transient float CollisionDisableTimer;          // during destruction, counts down time until collision is re-enabled so that particles do not land on invisible spots
var transient int TickCounter;                      // more than one thing can affect the tick for FracActors, this keeps track of them all

var() transient array<ParticleSystemComponent> DecoPSCs;


//******************************************************************************************

native simulated event BreakOffIsolatedIslands(out array<int> FragmentVis, array<int> IgnoreFrags, vector ChunkDir, array<FracturedStaticMeshPart> DisableCollWithPart, bool bWantPhysChunks);

native simulated function bool ConsiderForOccupancy();
native simulated function bool ShouldIgnoreForCover();
native simulated function bool CanClimbOver();
native simulated function bool CanClimbOnto();
native simulated function bool UseRigidBodyCollisionForCover();
native simulated function ECoverForceFlag GetCoverForceFlag();
native simulated function ECoverForceFlag GetCoverIgnoreFlag();
/* Flag all primitive components as currently cutdown */
native simulated function SetPrimitiveCutdownFlag(bool bShouldCutdown);
native simulated function SetPrimitiveCutoutFlag(bool bShouldCutout);
native simulated function SetPrimitiveCutdownFlagImm(bool bShouldCutdown);
native simulated function SetPrimitiveCutoutFlagImm(bool bShouldCutout);

native simulated function SetPrimitiveHidden(bool bInHidden);

/** Set vis fade on necessary primitive components */
native simulated function SetVisFadeFlag(bool bVisFade, optional bool bForceReattach=false );

/** Get all the height values used for building visibility */
native simulated function GetPrimitiveVisHeight( out float fCutdownHeight, out float fCutoutHeight, 
												 out float fOpacityMaskHeight, out float fPreviousOpacityMaskHeight );
/** Set all the height values used for building visibility */
native simulated function SetPrimitiveVisHeight( float fCutdownHeight, float fCutoutHeight, 
												 float fOpacityMaskHeight, float fPreviousOpacityMaskHeight );

/** Get the current and target cutout and height values. Allows the actor to determine which primitive
 *  component the values come from. */
native simulated function GetPrimitiveVisFadeValues( out float CutoutFade, out float TargetCutoutFade );

/** Set the current and target cutout and height values. Allows the actor to determine which primitive
 *  component the values come from. */
native simulated function SetPrimitiveVisFadeValues( float CutoutFade, float TargetCutoutFade );

native simulated function float GetCutdownOffset();

native simulated function bool CanUseCutout();

/* Sets all primitive components to hide completely rather than using cutout */
native simulated function SetHideableFlag(bool bShouldHide);
/* Sets all primitive components to hide completely rather than using cutout */
native simulated function SetHideableFlagImm(bool bShouldHide, optional bool bAffectMainSceneChannel=true);

native simulated function SetIsHidingFromExternalMeshGroup(bool bIsHidingFromExternalMeshGroup);
native simulated function bool IsHidingFromExternalMeshGroup();

native simulated function bool CanUseHideable();
native simulated function ChangeVisibilityAndHide( bool bShow, float fCutdownHeight, float fCutoutHeight );
native simulated function ChangeVisibility( float fCutdown, float fCutoutHeight );
native simulated function GetTargetVisibility(out float fCutdown, out float fCutoutHeight);
native simulated function Actor GetHidingPartner();
native simulated function PostApplyCheckpoint();
native function bool IsPositionVisible( const out Vector Position, out int bCutout, PrimitiveComponent HitComp );

/** To be able to delay fracture visuals, a timer is kept and the frac actor will begin to tick. */
native function BeginDamageReattach();
native function FinishDamageReattach();
native function SwitchToFractureCollision();
native function RestoreToRenderMatchCollision();

/** Disable collision for a short period during destruction events */
native function BeginDamageTimer();
native function EndDamageTimer();

native function UpdateRenderVisibility();

native function bool GetDesiredTickState();

simulated event ParticleSystemComponent SpawnEffect( XComFracLevelActor FracActor, EffectCue Cue, Vector EffectLocation, vector EffectRotation, const out array<ParticleSysParam> InstanceParameters )
{
	return class'EffectCue'.static.SpawnEffectWithInstanceParams( FracActor.WorldInfo.MyEmitterPool, Cue, EffectLocation, Rotator(EffectRotation), InstanceParameters );
}

cpptext
{
	// AActor collision functions.
	virtual UBOOL ShouldTrace(UPrimitiveComponent* Primitive,AActor *SourceActor, DWORD TraceFlags);
	virtual UBOOL InStasis();
	virtual void TickSpecial(FLOAT DeltaSeconds);


	virtual void PreSave();
	virtual void PostLoad();
	virtual void PostEditMove(UBOOL bFinished);

	virtual UBOOL PostProcessChunkDamage();
	virtual void  PostProcessDamage(const FStateObjectReference &Dmg);
	virtual void  SpawnDamageEffects(const FStateObjectReference &Dmg);
	virtual void  ApplyAOEDamageMaterial();
	virtual void  RemoveAOEDamageMaterial();
	virtual bool  GetAOEBreadcrumb() { return FALSE; }
	virtual int GetToughnessHealth() { return Toughness ? Toughness->Health : ((UXComDestructibleActor_Toughness *)(UXComDestructibleActor_Toughness::StaticClass()->GetDefaultObject()))->Health; }
	virtual void GetAffectedChildren(TArray<IDestructible*>& Children);
}

simulated event PostBeginPlay()
{
	local FracturedStaticMesh FracMesh;
	local RenderChannelContainer RenderChannels;

	if( DamageParams == none )
	{
		DamageParams = XComDamageFXParams(DynamicLoadObject("FX_Destruction_Fracture_Data.DamageFXParams_Default", class'XComDamageFXParams'));
	}

	// FIRAXIS REMOVAL
	// Simple rigid body collision has to be turned on when bSpawnPhysicsChunks == true
	// Per triangle collision does not work well for rigid body physics anyway, because of its cost
	// TODO@jboswell: Investigate this when ragdoll goes wrong against walls
	FracMesh = FracturedStaticMesh(FracturedStaticMeshComponent.StaticMesh);
	if (FracMesh != none)
	{
		FracMesh.bSpawnPhysicsChunks = false;
		FracMesh.UseSimpleRigidBodyCollision = true;
	}

	// This is a bad idea!  Removing it.  Prevents us from doing COLLIDE_TouchAll because bWorldGeometry assumes blocking when
	// we might only want touch events. - Casey
	//bWorldGeometry = true;

	super.PostBeginPlay();
	RenderChannels = FracturedStaticMeshComponent.RenderChannels;
	RenderChannels.RainCollisionStatic = true;
	FracturedStaticMeshComponent.SetRenderChannels(RenderChannels);

	super.PostBeginPlay();
}

simulated native function ResetHealth();

// jboswell: native override of FSMA.BreakOffPartsInRadius(), works on columns (grid cells)
simulated native function ApplyDamage(Vector Origin, float Radius, int Damage);

// Apply damage directly to a chunk
simulated native function RemoveChunks( array<int> ChunkIdx, XComGameState_EnvironmentDamage DamageEventStateObject );

simulated event BreakOffPartsInRadius(vector Origin, float Radius, float RBStrength, bool bWantPhysChunksAndParticles)
{
	// Have to start ticking now
	SetTickIsDisabled(false);
	
	ApplyDamage(Origin, Radius, 10);
}

simulated event Tick (float DeltaTime)
{
	super.Tick(DeltaTime);
	// Immediately stop ticking.
	// At least one tick is necessary to go hidden.
	//SetTickIsDisabled(true);
}

simulated event DestructibleTakeDamage(XComGameState_EnvironmentDamage DamageEvent)
{
	//Empty, frac level actors get special processing
}

simulated event TakeCollateralDamage(Actor FromActor, int ColumnIdx, float MaxZ, int DamageAmount)
{
	//DamageColumn(ColumnIdx, MaxZ, DamageAmount, false);
	//PostProcessDamage();
}

// Receives mouse events
function bool OnMouseEvent(    int cmd, 
							   int Actionmask, 
							   optional Vector MouseWorldOrigin, 
							   optional Vector MouseWorldDirection, 
							   optional Vector HitLocation)
{
	return false; 
}

native simulated function bool ShouldBlockCameraTraces();

defaultproperties
{
	Begin Object Name=FracturedStaticMeshComponent0
		WireframeColor=(R=111,G=63,B=254,A=255)

		// at the behest of Orion, Dom set these.  Need this for houses and fences to cast shadows at the moment
		bCastDynamicShadow=true     
		bUsePrecomputedShadows=false // sulz wants this set for Lightmass to work correctly.
		bForceDirectLightMap=false

		// jboswell: Static lighting on by default (as per Zel)
		LightingChannels=(Static=true,bInitialized=true)

		BlockNonZeroExtent=TRUE
		BlockZeroExtent=TRUE

		CanBlockCamera=true

		bReceiverOfDecalsEvenIfHidden=TRUE // Prevent decals getting deleted when hiding this actor through building vis system.
	End Object

	//Begin Object Class=XComKynapseFracturedComponent Name=KyFractureCpnt
	//End Object
	//Components.Add(KyFractureCpnt);

	Begin Object Class=XComFloorComponent Name=FloorComponent0
		fTargetOpacityMaskHeight=999999.0
	End Object
	FloorComponent=FloorComponent0
	Components.Add(FloorComponent0)

	bIgnoreFor3DCursorCollision=false
	HideableWhenBlockingObjectOfInterest=false
	bTickIsDisabled=true; // jboswell: gets turned on later by destruction
	bStaticCollision=true;
	bPathColliding=false
	bWorldGeometry=true
	bNoDelete=FALSE
	m_bNoDeleteOnClientInitializeActors=true
	bAlwaysConsiderForCover=true
	bCanClimbOver=false
	bCanClimbOnto=false
	bIsValidDestination=true
	bIgnoreForCover=false
	bCanStepUpOn=false
	CoverForceFlag=CoverForce_Default;
	bNeedsDamageResolution=true
	bAlwaysFracture=false;
	bUseRigidBodyCollisionForCover=false
	bBlockInteriorLighting=true
	bPrimaryCutoutActor=true
}
