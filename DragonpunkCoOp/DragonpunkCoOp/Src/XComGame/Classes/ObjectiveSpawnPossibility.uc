class ObjectiveSpawnPossibility extends Actor
	native(Level)
	dependson(XComParcelManager)
	placeable;

var() const EParcelFacingType Facing;	// Which direction this Objective is facing
var deprecated int iTileRadius<DisplayName="i Tile Diameter">;
var() const int iTileHeight;		// The number of tiles along the Z (up) axis this OSP should consider for it's volume
var() const int iTileWidth;		// The number of tiles along the Y axis this OSP should consider for it's volume
var() const int iTileLength;		// The number of tiles along the X axis this OSP should consider for it's volume
var() const array<actor> arrActorsToSwap;  // 1st entry provides rotation and location of spawned actor
var() const bool bHideSwapActorsIfUnused; // if true, will remove all actors in arrActorsToSwap if this OSP was not used in the mission
var() const int iSwapRotationOffset; // In Degrees!
var() const bool bUseOSPFacingForSpawnRotation;  // if true, the facing of the spawned actor will match the rotation of this OSP. 
										   // If false, the spawned actor's rotation will be inherited from the actorToSwap + iSwapRotationOffset
var() const bool bShouldRestrictInteractionByVolume;  // if true, the interactive actor that is spawned by this OSP will have it's usable interaction sockets restricted to the volume described by this OSP
var() const array<string> arrMissionTypes;
var() const array<string> arrSubObjectiveTypes;
var() editoronly bool bDoesNotRequireGuardNodes; // Skips map check errors for this objective missing a guard node.
var() const array<XComLayerActor> kAssociatedLayers;

var() private SpriteComponent SpriteIconComponent;
var() private transient editoronly ArrowComponent FacingArrowComponent;
var() private  StaticMeshComponent Mesh;

var() const string SpawnTag; // Tag to allow the LDs to grab objective spawns by name, and not just index

// The name of the loot carrier to use to apply loot to the interactive object spawned from this OSP
var() const name LootCarrierName;
var() const array<name> HackRewards;            //  Names of HackRewardTemplates this object can provide if hacked.

var bool bBeenUsed;

// This associated interactive object will be marked as locked and be given the Strategy Hack Rewards
var() XComInteractiveLevelActor	AssociatedObjectiveActor;

// The lock strength set on the associated object when it is locked
var() int AssociatedLockStrength;

function ActivateAssociatedLayerActors()
{
	local XComLayerActor kLayerActor;
	
	foreach kAssociatedLayers(kLayerActor)
	{
		kLayerActor.SetActive(true);
	}
}

function GetSpawnTilePossibilities( out array<TTile> SpawnPossibilityTiles )
{
	local TTile RootTile;
	local vector RootLocation;
	local XComWorldData WorldData;
	local int AdjustedLength, AdjustedWidth, UnWoundYaw;

	// get a valid floor tile from the volume defined by this OSP
	WorldData = `XWORLD;
	RootLocation = Location;
	RootLocation.X += class'XComWorldData'.const.WORLD_HalfStepSize;  // half tile length
	RootLocation.Y += class'XComWorldData'.const.WORLD_HalfStepSize;  // half tile width
	RootLocation.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;  // half tile height
	RootTile = WorldData.GetTileCoordinatesFromPosition( RootLocation );

	// Ensure Yaw is unwound
	UnWoundYaw = Rotation.Yaw % 65536;
	if(UnWoundYaw < 0)
	{
		UnwoundYaw = UnwoundYaw + 65536; // rotate 360 degrees so that it's the same facing, but positive
	}

	// 90 Degrees
	if( UnWoundYaw > 8192 && UnWoundYaw <= 24576 )
	{
		AdjustedLength = iTileWidth;
		AdjustedWidth = iTileLength;
		RootTile.X -= iTileWidth;
	}
	// 180 degrees
	else if( UnWoundYaw > 24576 && UnWoundYaw <= 40960 )
	{
		AdjustedLength = iTileLength;
		AdjustedWidth = iTileWidth;
		RootTile.X -= iTileLength;
		RootTile.Y -= iTileWidth;
	}
	// 270 degrees
	else if( UnWoundYaw > 40960 && UnWoundYaw <= 57344 )
	{
		AdjustedLength = iTileWidth;
		AdjustedWidth = iTileLength;
		RootTile.Y -= iTileLength;
	}
	// no rotation
	else
	{
		AdjustedLength = iTileLength;
		AdjustedWidth = iTileWidth;
	}

	WorldData.GetSpawnTilePossibilities(RootTile, AdjustedLength, AdjustedWidth, iTileHeight, SpawnPossibilityTiles);
}

function Vector GetSpawnLocation()
{
	local array<TTile> SpawnPossibilityTiles;
	local TTile SpawnTile;
	local vector SpawnLocation;

	if (arrActorsToSwap.Length > 0 && arrActorsToSwap[0] != none)
	{
		if(arrActorsToSwap[0] == self)
		{
			`RedScreen("arrActorsToSwap will swap to self in OSP: " $ string(Name));
		}
		else if(arrActorsToSwap[0].Location == vect(0,0,0))
		{
			`RedScreen("arrActorsToSwap[0] is at the origin, is this an archetype? OSP:" $ string(Name));
		}

		return arrActorsToSwap[0].Location;
	}
	else
	{
		GetSpawnTilePossibilities(SpawnPossibilityTiles);
		
		if(SpawnPossibilityTiles.Length == 0)
		{
			`log("No valid spawn locations in OSP: " $ string(Name),,'XCom_ParcelOutput');
			return Location;
		}
		else
		{
			SpawnTile = SpawnPossibilityTiles[`SYNC_RAND(SpawnPossibilityTiles.Length)];
			SpawnLocation = `XWORLD.GetPositionFromTileCoordinates(SpawnTile);
			return SpawnLocation;
		}
	}
}

function Rotator GetSpawnRotation()
{
	local Rotator Result;
	local int FacingMultiplier;

	if( !bUseOSPFacingForSpawnRotation && arrActorsToSwap.Length > 0 )
	{
		Result = arrActorsToSwap[0].Rotation;
		Result.Yaw += iSwapRotationOffset * DegToUnrRot;
		return Result;
	}
	else
	{
		Result = Rotation;
		FacingMultiplier = Clamp( int(Facing) - 1, 0, 3 );
		Result.Yaw = (Result.Yaw + (FacingMultiplier * 16384) + (iSwapRotationOffset * DegToUnrRot)) % 65536;
		return Result;
	}
}
 
function HideSwapActors()
{
	local Actor SwapActor;

	foreach arrActorsToSwap(SwapActor)
	{
		class'XComWorldData'.static.GetWorldData( ).RemoveActorTileData( SwapActor, true );
		SwapActor.SetCollisionType(COLLIDE_NoCollision);
		SwapActor.bActorDisabled = true;
		SwapActor.SetVisible(false);
	}
}

native function Box GetInteractionBoundingBox();

cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PostLoad();
	virtual void PostEditMove(UBOOL bFinished);
#if WITH_EDITOR
	virtual void CheckForErrors();
#endif
}

DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true     // precomputed lighting is used until the static mesh is changed
		bCastShadows=false // there will be a static shadow so no need to cast a dynamic shadow
		bSynthesizeSHLight=false
		bSynthesizeDirectionalLight=true; // get rid of this later if we can
		bDynamic=true     // using a static light environment to save update time
		bForceNonCompositeDynamicLights=TRUE // needed since we are using a static light environment
		bUseBooleanEnvironmentShadowing=FALSE
		TickGroup=TG_DuringAsyncWork
	End Object

	Begin Object Class=StaticMeshComponent Name=ObjStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'Parcel.Meshes.EditorRadiusSphere'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=64,G=0,B=64,A=255)
		LightEnvironment=MyLightEnvironment
		AbsoluteScale=true
		Translation=(X=48,Y=48,Z=48)
	End Object
	Components.Add(ObjStaticMeshComponent)
	Mesh=ObjStaticMeshComponent;

	Begin Object Class=SpriteComponent Name=SpriteOSP
		HiddenGame=True
		AbsoluteScale=true
		Translation=(X=48,Y=48,Z=96)
		Sprite=Texture2D'EditorResources.Ambientcreatures'
		Scale=0.25
	End Object
	Components.Add(SpriteOSP)
	SpriteIconComponent=SpriteOSP

	Begin Object Class=ArrowComponent Name=Arrow
	ArrowColor=(R=192,G=255,B=64)
	ArrowSize=2.0
	AbsoluteScale=true
	AbsoluteRotation=true
	Translation=(X=48,Y=48,Z=96)
	HiddenGame=true
	AlwaysLoadOnClient=False
	AlwaysLoadOnServer=False
	End Object
	Components.Add(Arrow)
	FacingArrowComponent=Arrow

	bStatic=true
	bNoDelete=true
	bEdShouldSnap=true

	DrawScale3D=(X=1.0, Y=1.0, Z=1.0)

	iTileHeight = 1
	iTileWidth = -1
	iTileLength = 1

	bUseOSPFacingForSpawnRotation=true

	Facing=EParcelFacingType_N

	AssociatedLockStrength=1
}
