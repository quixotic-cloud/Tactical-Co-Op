class XComLevelActor extends StaticMeshActor 
	implements(XComCoverInterface)
	implements(IMouseInteractionInterface)
	native(Level)
	placeable; 

cpptext 
{
	virtual void PostEditMove(UBOOL bFinished);
	virtual void PostLoad();

	virtual void SetLDMaxDrawDistance(INT Mode, FLOAT MaxDrawDistance);

	// AActor collision functions.
	virtual UBOOL ShouldTrace(UPrimitiveComponent* Primitive,AActor *SourceActor, DWORD TraceFlags);

};

enum ECameraVisibilityType
{
	eCameraVisibilityType_SameAsUnitVisibility,
	eCameraVisibilityType_BlockCamera,
	eCameraVisibilityType_DoNotBlockCamera
};

struct native VisibilityBlocking
{
	var() const bool bBlockUnitVisibility;
	var() const ECameraVisibilityType eBlockCameraVisibility;
	var() const bool bIsWindow;

	structdefaultproperties
	{
		bBlockUnitVisibility = true
		eBlockCameraVisibility = eCameraVisibilityType_BlockCamera
	}
};

var() const editconst XComFloorComponent FloorComponent;

var() VisibilityBlocking VisibilityBlockingData;

var() bool HideableWhenBlockingObjectOfInterest;

var() bool UsePeripheryHiding;

/** An actor that should toggle hidden when this once does **/
var() Actor HidingPartner;

/** If set to true the 3d cursor will not consider this object for collision **/
var() const bool bIgnoreFor3DCursorCollision;

/** Indicates that this actor is a stair or stairwell. Will cause the 3D cursor to jump up to the next floor when it reaches the top. **/
var() const bool bIsStair;

var() const bool bNeedsTerrainVertexBlending;

var(Cover) bool bAlwaysConsiderForCover<DisplayName=Consider For Occupancy Checks?>;
var(Cover) bool bCanClimbOver;
var(Cover) bool bCanClimbOnto;
/** Set to FALSE if units should not be able to finish their move on top of this object */
var(Cover) bool bIsValidDestination;
var(Cover) bool bIgnoreForCover;
var(Cover) bool bUseRigidBodyCollisionForCover;
var(Cover) ECoverForceFlag CoverForceFlag;
var(Cover) ECoverForceFlag CoverIgnoreFlag;

/** Used to block tile lighting. (For Interior/Exterior Lighting) */
var() bool bBlockInteriorLighting;

/** Used to indicate this actor should use a larger extent check for cutouts */
var() bool bPrimaryCutoutActor;

/** Indicates if this Level Actor should be excluded from any building/floor volumes (Only works for level actors within blueprints) */
var() bool bExcludeFromBuildingVolume;

native function bool IsPositionVisible( const out Vector Position, out int bCutout, PrimitiveComponent HitComp );

native simulated function bool ConsiderForOccupancy();
native simulated function bool ShouldIgnoreForCover();
native simulated function bool UseRigidBodyCollisionForCover();
native simulated function bool CanClimbOver();
native simulated function bool CanClimbOnto();
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

native simulated function bool ShouldUsePeripheryHiding();

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

native simulated function bool ShouldBlockCameraTraces();

simulated event PostBeginPlay()
{
	local RenderChannelContainer RenderChannels;

	super.PostBeginPlay();
	RenderChannels = StaticMeshComponent.RenderChannels;
	RenderChannels.UnitVisibility = VisibilityBlockingData.bBlockUnitVisibility;
	RenderChannels.RainCollisionStatic = true;
	StaticMeshComponent.SetRenderChannels(RenderChannels);
}

simulated event Tick (float DeltaTime)
{
	super.Tick(DeltaTime);
	// Immediately stop ticking.
	// At least one tick is necessary to go hidden.
	//SetTickIsDisabled(true);
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

// jboswell: Copied from DynamicSMActor
function OnSetMaterial(SeqAct_SetMaterial Action)
{
	StaticMeshComponent.SetMaterial( Action.MaterialIndex, Action.NewMaterial );

	// If this is ever used in game, we must copy the replication code from DynamicSMActor here -- jboswell
}

defaultproperties
{
	//Begin Object Class=XComKynapseFracturedComponent Name=KyFractureCpnt
	//End Object
	//Components.Add(KyFractureCpnt);

	Begin Object Name=StaticMeshComponent0
		BlockRigidBody=TRUE
		WireframeColor=(R=193,G=255,B=6,A=255)

		// at the behest of Orion, Dom set these.
//		bCastDynamicShadow=true         // commented out at the behest of Moose - perf hit
//		bUsePrecomputedShadows=false    // commented out at the behest of Moose - perf hit
		bForceDirectLightMap=false

		bReceiverOfDecalsEvenIfHidden=TRUE // Prevent decals getting deleted when hiding this actor through building vis system.

		CanBlockCamera=true
	End Object

	Begin Object Class=XComFloorComponent Name=FloorComponent0
		fTargetOpacityMaskHeight=999999.0
	End Object
	FloorComponent=FloorComponent0
	Components.Add(FloorComponent0)

	bStatic=false // TODO: is there other stuff we need?
	bStaticCollision=true;
	bNoDelete=false
	m_bNoDeleteOnClientInitializeActors=true
	bMovable=false
	
	HideableWhenBlockingObjectOfInterest=false
	UsePeripheryHiding = false

	bIgnoreFor3DCursorCollision=false
	bTickIsDisabled=true
	bWorldGeometry=true
	bPathColliding=true
	bCollideActors=TRUE
	bBlockActors=true
	bAlwaysConsiderForCover=true
	bCanClimbOnto=true
	bCanClimbOver=false
	bIsValidDestination=true
	bConsiderAllStaticMeshComponentsForStreaming=true;
	CoverForceFlag=CoverForce_Default;
	bUseRigidBodyCollisionForCover=false

	bBlockInteriorLighting=false
	bPrimaryCutoutActor=false

	bNeedsTerrainVertexBlending=false

	bExcludeFromBuildingVolume=false
}
