class XComLevelVolume extends Volume
	placeable
	native;

cpptext
{
	#if WITH_EDITOR
	virtual void PostRebuildMap();
	#endif

	virtual void PostLoad();
	virtual void PreBeginPlay();
	virtual void Serialize(FArchive& Ar);

	static void ValidateMap();
	static void EmptyMap();



}

var Material LevelBoundsMaterial;
var() const editconst StaticMeshComponent StaticMeshComponent;

var XComWorldData WorldData;
var XComDestructionInstData DestructionData;
var DestructionDecoEmitterPool DecoEmitterPool;

//Rendering for the vismap
var StaticMesh  TileMesh;
var Material NeverSeenTileMaterial;
var MaterialInstanceConstant NeverSeenMIC;
var() const editconst InstancedStaticMeshComponent InstancedMeshComponentNeverSeen;
var Material HaveSeenTileMaterial;
var MaterialInstanceConstant HaveSeenMIC;
var() const editconst InstancedStaticMeshComponent InstancedMeshComponentHaveSeen;
var Material BlockingTileMaterial;
var MaterialInstanceConstant BlockingMIC;
var() const editconst InstancedStaticMeshComponent InstancedMeshComponentBlocking;

var() const editconst XComWorldDataRenderingComponent WorldDataRenderingComponent;
var() const editconst XComCoverRenderingComponent CoverRenderingComponent;

var() const editconst InstancedStaticMeshComponent LowCoverComponent;
var() const editconst InstancedStaticMeshComponent HighCoverComponent;
var() const editconst InstancedStaticMeshComponent PeekLeftComponent;
var() const editconst InstancedStaticMeshComponent PeekRightComponent;

var() const editconst InstancedStaticMeshComponent CoverTileRenderingComponent;
var() const editconst InstancedStaticMeshComponent CoverNeighborRenderingComponent;
var() const editconst InstancedStaticMeshComponent FloorRenderingComponent;
var() const editconst InstancedStaticMeshComponent RampRenderingComponent;
var() const editconst InstancedStaticMeshComponent WallRenderingComponent;

var() const editconst InstancedStaticMeshComponent InteractRenderingComponent;

// Component Used to outline moveable area
var const XComMovementGridComponent BorderComponent;
var const XComMovementGridComponent BorderComponentDashing;

var InstancedStaticMeshComponent FlameThrowerHitTiles;
var InstancedStaticMeshComponent FlameThrowerSplashTiles;

var bool bInitializedFlamethrowerResources; //Tells whether our instanced mesh components for the flamethrower UI have been set yet

event Destroyed()
{
	if( WorldData != none )
	{
		WorldData.Cleanup();
	}
}

native function UpdateFlameThrowerTiles();
native function ClearFlameThrowerTiles();


//This needs to happen after a point at which the unit content has been loaded. Currently this is done the first time the flamethrower is used on something
event InitializeFlamethrowerResources()
{
	FlameThrowerHitTiles.SetTranslation(vect(0,0,0));
	FlameThrowerHitTiles.SetRotation(rot(0,0,0));

	FlameThrowerSplashTiles.SetTranslation(vect(0,0,0));
	FlameThrowerSplashTiles.SetRotation(rot(0,0,0));
}

defaultproperties
{	
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0		
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		CollideActors=FALSE
		BlockActors=TRUE
		BlockZeroExtent=TRUE
		BlockNonZeroExtent=TRUE
		BlockRigidBody=FALSE
		bUsePrecomputedShadows=TRUE
		bAcceptsLights=FALSE
		CanBlockCamera=false
	End Object	
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)	

	Begin Object Class=InstancedStaticMeshComponent Name=InstancedMeshComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'SimpleShapes.ASE_UnitCube'
	End object
	InstancedMeshComponentNeverSeen=InstancedMeshComponent0
	Components.Add(InstancedMeshComponent0)

	Begin Object Class=InstancedStaticMeshComponent Name=InstancedMeshComponent1
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'SimpleShapes.ASE_UnitCube'
	End object
	InstancedMeshComponentHaveSeen=InstancedMeshComponent1
	Components.Add(InstancedMeshComponent1)

	Begin Object Class=InstancedStaticMeshComponent Name=InstancedMeshComponent2
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'SimpleShapes.ASE_UnitCube'
	End object
	InstancedMeshComponentBlocking=InstancedMeshComponent2
	Components.Add(InstancedMeshComponent2)

	begin object name=BrushComponent0
		CanBlockCamera=false
	end object

	begin object class=XComCoverRenderingComponent name=CoverRenderingComponent0
		HiddenEditor=true
	end object
	Components.Add(CoverRenderingComponent0)
	CoverRenderingComponent=CoverRenderingComponent0

	begin object class=XComWorldDataRenderingComponent name=WorldDataRenderingComponent0
		HiddenEditor=false
	end object
	Components.Add(WorldDataRenderingComponent0)
	WorldDataRenderingComponent=WorldDataRenderingComponent0

	begin object class=InstancedStaticMeshComponent name=LowCoverComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_3D.Cover.CoverHalf_Editor'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(LowCoverComponent0);
	LowCoverComponent=LowCoverComponent0;

	begin object class=InstancedStaticMeshComponent name=HighCoverComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_3D.Cover.CoverFull_Editor'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(HighCoverComponent0);
	HighCoverComponent=HighCoverComponent0;

	begin object class=InstancedStaticMeshComponent name=PeekLeftCoverComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.Editor_PeekAroundLeft'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(PeekLeftCoverComponent0);
	PeekLeftComponent=PeekLeftCoverComponent0;

	begin object class=InstancedStaticMeshComponent name=PeekRightCoverComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.Editor_PeekAroundRight'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(PeekRightCoverComponent0);
	PeekRightComponent=PeekRightCoverComponent0;

	begin object class=InstancedStaticMeshComponent name=CoverTileRenderingComponent0
		TranslucencySortPriority=99 //render immediately below the pathing line
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.CoverTile'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(CoverTileRenderingComponent0);
	CoverTileRenderingComponent=CoverTileRenderingComponent0;

	begin object class=InstancedStaticMeshComponent name=NeighborTileRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.CoverTileNeighbor'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(NeighborTileRenderingComponent0);
	CoverNeighborRenderingComponent=NeighborTileRenderingComponent0;

	begin object class=InstancedStaticMeshComponent name=FloorRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.FloorTile'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(FloorRenderingComponent0);
	FloorRenderingComponent=FloorRenderingComponent0;

	begin object class=InstancedStaticMeshComponent name=RampRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.RampTile'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(RampRenderingComponent0);
	RampRenderingComponent=RampRenderingComponent0;

	begin object class=InstancedStaticMeshComponent name=WallRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.WallPlane'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(WallRenderingComponent0);
	WallRenderingComponent=WallRenderingComponent0;

	begin object class=InstancedStaticMeshComponent name=InteractRenderingComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		StaticMesh=StaticMesh'UI_Cover.Editor_Meshes.InteractTile'
		HiddenGame=true
		HiddenEditor=true
	end object
	Components.Add(InteractRenderingComponent0);
	InteractRenderingComponent=InteractRenderingComponent0;

	LevelBoundsMaterial = Material'Materials.DevTextures.LevelVolumeBorder'
	bStatic=True
	bWorldGeometry=false
	bCollideActors=true
	bBlockActors=False
	bHidden=False	
	bPathColliding=True
	
	NeverSeenTileMaterial = Material'EngineDebugMaterials.LevelColorationLitMaterial'
	HaveSeenTileMaterial = Material'EngineDebugMaterials.LevelColorationLitMaterial'
	BlockingTileMaterial = Material'EngineDebugMaterials.LevelColorationLitMaterial'

	Begin Object Class=XComMovementGridComponent Name=MovementBorder
		bCustomHidden=true
	End Object

	BorderComponent=MovementBorder
	Components.Add(MovementBorder)

	Begin Object Class=XComMovementGridComponent Name=MovementBorderDashing
		bCustomHidden=true
	End Object

	BorderComponentDashing=MovementBorderDashing
	Components.Add(MovementBorderDashing)

	Begin Object Class=InstancedStaticMeshComponent Name=FlameThrowerHit
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		bIgnoreOwnerHidden=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		StaticMesh=StaticMesh'UI_Range.Meshes.FlameThrowerHit'
	End Object
	FlameThrowerHitTiles=FlameThrowerHit
	Components.Add(FlameThrowerHit)

	Begin Object Class=InstancedStaticMeshComponent Name=FlameThrowerSplash
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		bIgnoreOwnerHidden=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		StaticMesh=StaticMesh'UI_Range.Meshes.FlameThrowerSplash'
	End Object
	FlameThrowerSplashTiles=FlameThrowerSplash
	Components.Add(FlameThrowerSplash)
}