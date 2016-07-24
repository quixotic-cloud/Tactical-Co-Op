//---------------------------------------------------------------------------------------
//  FILE:    XComWorldData.uc
//  AUTHOR:  Ryan McFall  --  12/08/2010
//  PURPOSE: Maintains a 3d grid of tiles that can contain information about the playable
//           game space. Used primarily for visiblity.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComWorldData extends Object
	native(Core)
	inherits(FTickableObject)
	config(GameCore)
	dependson(XComTraceManager, X2GameRulesetVisibilityManager);

var private const config bool EnableThreadedWorldDataBuild;

//------------------------------------------------------------------------------
// Cover flags
//------------------------------------------------------------------------------
const COVER_North       = 0x00000001;
const COVER_South       = 0x00000002;
const COVER_East        = 0x00000004;
const COVER_West        = 0x00000008;
const COVER_NLow        = 0x00000010;
const COVER_SLow        = 0x00000020;
const COVER_ELow        = 0x00000040;
const COVER_WLow        = 0x00000080;
const COVER_NPeekLeft   = 0x00000100;
const COVER_SPeekLeft   = 0x00000200;
const COVER_EPeekLeft   = 0x00000400;
const COVER_WPeekLeft   = 0x00000800;
const COVER_NPeekRight  = 0x00001000;
const COVER_SPeekRight  = 0x00002000;
const COVER_EPeekRight  = 0x00004000;
const COVER_WPeekRight  = 0x00008000;
const COVER_Diagonal    = 0x00010000; // Tile's cover is all diagonal, rotated 45 degrees clockwise (Local N = World NE)
const COVER_ClimbOnto_N = 0x00020000;
const COVER_ClimbOnto_S = 0x00040000;
const COVER_ClimbOnto_E = 0x00080000;
const COVER_ClimbOnto_W = 0x00100000;
const COVER_ClimbOver_N = 0x00200000;
const COVER_ClimbOver_S = 0x00400000;
const COVER_ClimbOver_E = 0x00800000;
const COVER_ClimbOver_W = 0x01000000;

const COVER_DIR_ANY     = 0x0000000F; // COVER_North|Cover_South|COVER_East|COVER_West
const COVER_LOW_ANY     = 0x000000F0; //(COVER_NLow|COVER_SLow|COVER_ELow|COVER_WLow)

const WORLD_StepSize = 96.0f;
const WORLD_StepSizeSquared = 9216.0f;
const WORLD_StepSize_2D_Diagonal = 135.7645f; // = 96*sqrt(2) = diagonal distance between 2 tiles (on the same z plane).
const WORLD_StepSize_2DZ_Diagonal = 115.3776f; // = sqrt(96^2+64^2) = diagonal distance btwn 2 tiles not on the same z plane.
const WORLD_StepSize_3D_Diagonal = 150.0933f; // = cubic diagonal distance between 2 tiles.  
const WORLD_HalfStepSize = 48.0f;
const WORLD_FloorHeight = 64.0f;
const WORLD_HalfFloorHeight = 32.0f;
const WORLD_FloorHeightsPerLevel = 4.0f;
const WORLD_TotalLevels = 3.0f;

const WORLD_BaseHeight = 24.0f; //Offset by std. curb height
const WORLD_PartialRadius = 20.0f;
const WORLD_RampDotMaxThreshold = 0.9848f; //~10 deg
const WORLD_RampDotMinThreshold = 0.7f; //~45 deg

const WORLD_PATHING_ANY_DIR_BLOCKED = 0x0000003F;
const WORLD_VIS_ANY_DIR_BLOCKED     = 0x00000FC0;
const WORLD_VIS_ANY_CONCEALS        = 0x000007E8;   //Use bitwise & against voxel result  TraceFlags to determine whether the trace hit a concealing surface ( window, smoke, etc. )
const WORLD_VIS_ANY_OBSCURED        = 0x00000008;   //Subset of WORLD_VIS_ANY_CONCEALS. Indicates a trace intersected smoke

const WORLD_METERS_TO_UNITS_MULTIPLIER = 64.0f;
const WORLD_UNITS_TO_METERS_MULTIPLIER = 0.015625f; // 1/64

const DEFAULT_REBUILD_TILE_RATE = 16;

const WORLD_Melee_Range_Meters = 2.375f;            // approximately equal to sqrt(96^2 + 96^2 + 64^2). This is the distance between a tile on the ground and a tile diagonal and up one level.
//------------------------------------------------------------------------------
// Cover constants
//------------------------------------------------------------------------------
const Cover_BufferDistance = 4.0f;                      // Resolution of calculations in the cover system, all calculations are +/- buffer
const Cover_ClimbOverLateralDistance = 96.0f;           // XY distance from start of climb over to end
const Cover_ClimbOntoLateralDistance = 96.0f;           // XY distance from start of climb onto to end
const Cover_ShieldOffsetDistanceFromWall = 40.0f;       // How far from cover will the shield be
const Cover_CoverLocationOffset = 4.0f;					// Where the actual cover is, used for determining where characters should stand
const Cover_PeekHeightTolerance = 16.0f;                // How much height difference can there be between a cover loc and a peek location
const Cover_PeekTestHeight = 96.0f;                     // Height at which peek checks are done
const Cover_LowCoverHeight = 64.0f;                     // Max Height of low cover
const Cover_HighCoverHeight = 96.0f;                    // Height of high cover
const Cover_MinClimbOverHeight = 160.0f;                // Clearance needed to perform climb over/onto (from ground level)
const Cover_ClimbOverHeightTolerance = 8.0f;            // Climb over/onto checks will be at LowCoverHeight +/- this value
const Cover_TraceDensity = 16.0f;                       // Density of the matrix of line checks when looking for cover
const Cover_BaseNormalDotThreshold = 0.71f;             // Min dot between -TestDir and hit normal for cover to be created (~45 deg)
const Cover_DropDownOffset = 20.0f;
const Cover_DropDownLandingOffset = 4.0f;

//Mirrored in native code by ECoverDebugFlags, each element of which is 1 << EScriptCoverDebugFlags
enum EScriptCoverDebugFlags
{
	EScriptCOVER_DebugHeight,
	EScriptCOVER_DebugGround,
	EScriptCOVER_DebugPeek,
	EScriptCOVER_DebugWorld,
	EScriptCOVER_DebugOccupancy,
	EScriptCOVER_DebugClimb,
};

var transient bool bFinishedTileUpdateThisFrame;
var transient bool bUpdatedVisData;
var transient bool bDisableVisibilityUpdates;
var transient bool bDebugVisibility;
var transient bool bDebugFOW;
var transient bool bDebugEnableFOW;
var transient bool bEnableFOW;
var transient bool bEnableFOWUpdate;
var transient bool bDebugBlockingTiles;
var transient bool bDebugNormals;
var transient bool bShowCoverNodes;
var transient bool bShowCoverTiles;
var transient bool bShowFloorTiles;
var transient bool bUseIntroFOWUpdate;
var transient bool bDebuggingGenericUpdate;
var transient bool bEnableUnitOutline;
var transient bool bCinematicMode;

var transient EnvMapCaptureState StaticRainDepthCaptureState;

//Debug flags
var transient bool bDebugVoxelData;
var transient int  DebugFOWViewer;
var transient bool bDebugGameplayFOWData; //bDebugGameplayFOWData indicates that tiles should be shown / hidden based on LOS instead of using FOW values

var transient int  iDebugFloorTileUnitSize;
var transient int CoverDebugFlags;
var Box WorldBounds;
var int NumX;
var int NumY;
var int NumZ;
var int NumTiles;
var transient int NumRebuilds; //In-game, tracks the effective 'version' of the world grid data. Helps the visibility job manager know when a job is 'stale'.
var transient init array<byte> FOWUpdateTextureBuffer;
var transient bool bFOWTextureBufferIsDirty;
var transient double LastFOWTextureUpdateTime;

/* ====== Height fog related ======= */
var deprecated int HFNumX;
var deprecated int HFNumY;
var deprecated int HFNumZ;
var transient int HFNumX_New;
var transient int HFNumY_New;
var transient int HFNumZ_New;
var transient init array<byte> FOWHeightFogUpdateTextureBuffer;

/** A FIFO queue of min/max corners of the last n FOW texture updates. Needed to support lerping over time. */
var transient array<vector> UpdateCorners;
/** The bounds of the current update area of the FOW texture (in texels), generated from UpdateCorners. */
var transient Box CurrentUpdateBox;

var const native pointer WorldDataPtr{class UXComWorldDataContainer};

var transient DamageFrame DamageFrame;
var transient DamageMICManager DamageMICMgr;

//Destruction defaults - these define effects and actions to use in the event that none are specified when an object is destroyed. This way
//*something* will happen and the object won't just blink out of existance.
var private string DefaultFractureActorPath;
var transient XComFracLevelActor DefaultFractureActor;
var private string DefaultDestructibleActorPath;
var transient XComDestructibleActor DefaultDestructibleActor;

var transient int RebuildIndex;
var transient bool bEnableRebuildTileData;
var transient bool bSyncingVisualizer;  //Set to TRUE for the duration of of the SyncVisualizers call. Certain operations need to be aware of this state.
var transient bool bBatchingTileUpdates;

var delegate<CanSeeLocationCallback> CurrentCanSeeLocationCallback;
var object CurrentCanSeeLocationCallbackOwner;

/**Used to package data from UXComWorldDataContainer queries*/
struct native TileData
{
	var FloorTileData FloorData;
	var CoverTileData CoverData;
	var init array<XComInteractPoint> InteractPoints;
	var init array<TTile> TraversalStarts;
	var int     StaticFlags;
	var int     CoverFlags;
	var int     Viewers;	
	var int     DynamicWorldFlags;
	var Actor	TileOccupier;

	structcpptext
	{

	FTileData( ) :
		StaticFlags( 0 ),
		CoverFlags( 0 ),
		Viewers( 0 ),
		DynamicWorldFlags( 0 ),
		TileOccupier( NULL )
	{
	}

	}
};

struct native TileEffectUpdateData
{
	var TTile Tile;
	var int SparseArrayIndex;
	var int PreviousIntensity;

	var float DesiredLERPTime;
	var float ActiveLERPTime;
};

var transient init array<Actor> Viewers; //This should only ever be read from. To add or remove elements, use Register/Unregister
var transient protected init array<ViewerInfo> ViewerInfos;
var transient protected bool bUpdatingVisibility;
var transient protected init array<Actor> DeferredRemoveViewers;

var protected native Set_Mirror DebugTiles{TSet<FTTile>};

var protected array<TileEffectUpdateData> VolumeEffectUpdateTiles;

var private native Map_Mirror CachedTileEnteredEffects{TMap<FName, TArray<UX2Effect*>>};

var transient private init array<XComFloorVolume> FloorVolumeCache;
var transient private init array<TriggerVolume> WaterVolumeCache;
var transient private init array<XComLadder> LadderCache;

//Turn off the collision for frac actors that are losing chunks.
var protected native Set_Mirror ModifiedFracLevelActors{TSet<AXComFracLevelActor*>};
var protected native Map_Mirror StoredCollisionType{TMap<AActor*, ECollisionType>};
var protected native Map_Mirror PrevStaticMesh{TMap<AXComDestructibleActor*, UStaticMesh*>};
var protected native Map_Mirror PrevCollisionComponent{TMap<AXComDestructibleActor*, UPrimitiveComponent*>};

// Handles rendering the visibility map
//============================================================================
var XComLevelVolume Volume;
var transient bool bWorldDataInitialized;
var transient bool bUseSingleThreadedSolver;
var transient bool bInitVolumeEffectsPostLoad;
var bool bUseLineChecksForFOW;
var bool bDrawVisibilityChecks;
var float FOWNeverSeen;
var float FOWHaveSeen;
var float LastFloorHeight;

var transient bool bShowNeverSeenAsHaveSeen; //Setting for certain maps to make it so that never seen fog is shown as have seen
var transient bool bSolverStateRequiresUpdate; //Signal to the threaded vis solver that its copies of the world need to be updated. Set by FlushCachedVisibility

var array< class<Actor> > SupportedViewerClasses;

// Parameters that the engine will need regarding the world data
struct native WorldDataRenderParams
{	
	var vector VoxelSize;
	var vector LevelDimensions;
	var vector LevelPosition;
};

var WorldDataRenderParams RenderParams;

//
struct native SmokeEmitter
{
	var native Array_Mirror Tiles{TArray<FTTile>};

	var Vector HalfSize;
	var Vector Center;
	var byte VolumeType;

	var ParticleSystem ParticleTemplate;
	var ParticleSystemComponent Particles;

	structcpptext
	{
		FSmokeEmitter() :
		HalfSize(0,0,0),
		Center(0,0,0),
		VolumeType(0),
		ParticleTemplate(NULL),
		Particles(NULL)
		{
		}

		void CalcExtents()
		{
			FTTile Min = Tiles(0);
			FTTile Max = Tiles(0);
			for(INT i=1; i<Tiles.Num(); i++)
			{
				FTTile& Tile = Tiles(i);
				if( Tile.X > Max.X )	Max.X = Tile.X;
				if( Tile.Y > Max.Y )	Max.Y = Tile.Y;
				if( Tile.Z > Max.Z )	Max.Z = Tile.Z;
				if( Tile.X < Min.X )	Min.X = Tile.X;
				if( Tile.Y < Min.Y )	Min.Y = Tile.Y;
				if( Tile.Z < Min.Z )	Min.Z = Tile.Z;
			}

			HalfSize.X = (Max.X - Min.X + 1) * 0.5f;
			HalfSize.Y = (Max.Y - Min.Y + 1) * 0.5f;
			HalfSize.Z = (Max.Z - Min.Z + 1) * 0.5f;

			Center.X = Min.X + (Max.X - Min.X) * 0.5f;
			Center.Y = Min.Y + (Max.Y - Min.Y) * 0.5f;
			Center.Z = Min.Z + (Max.Z - Min.Z) * 0.5f;
		}

		void Merge(const FSmokeEmitter& Other)
		{
			Tiles.Append(Other.Tiles);
			CalcExtents();
		}

		UBOOL SharesEdge(const FSmokeEmitter& Other, INT Axis)
		{
			// two emitters are neighbors on a given axis if their min/max values on that axis match
			switch(Axis)
			{
			case AXIS_XZ: return (( Center.X + HalfSize.X == Other.Center.X - Other.HalfSize.X ) || ( Center.X - HalfSize.X == Other.Center.X + Other.HalfSize.X )) && Center.Z == Other.Center.Z && Center.Y == Other.Center.Y;
			case AXIS_YZ: return (( Center.Y + HalfSize.Y == Other.Center.Y - Other.HalfSize.Y ) || ( Center.Y - HalfSize.Y == Other.Center.Y + Other.HalfSize.Y )) && Center.Z == Other.Center.Z && Center.X == Other.Center.X;
			case AXIS_XY: return (( Center.Z + HalfSize.Z == Other.Center.Z - Other.HalfSize.Z ) || ( Center.Z - HalfSize.Z == Other.Center.Z + Other.HalfSize.Z )) && Center.X == Other.Center.X && Center.Y == Other.Center.Y;
			default: return FALSE;
			}
		}

		UBOOL CanMerge(const FSmokeEmitter& Other, INT Axis)
		{
			if( VolumeType != Other.VolumeType )
			{
				return FALSE;
			}
			// we can merge on a given axis if they share an edge and the other two axes have the same size (maintaining the rectangle shape)
			switch(Axis)
			{
			case AXIS_X: return ( HalfSize.Y == Other.HalfSize.Y && HalfSize.Z == Other.HalfSize.Z && SharesEdge(Other, AXIS_XZ) );
			case AXIS_Y: return ( HalfSize.X == Other.HalfSize.X && HalfSize.Z == Other.HalfSize.Z && SharesEdge(Other, AXIS_YZ) );
			case AXIS_Z: return ( HalfSize.Y == Other.HalfSize.Y && HalfSize.X == Other.HalfSize.X && SharesEdge(Other, AXIS_XY) );
			default: return FALSE;
			}
		}
	}
};

var array<SmokeEmitter>     SmokeEmitters;
var transient array<Vector> PotentialFireColumns;

var native transient Array_Mirror RenderVisibilityTilesToUpdate{TArray<FTTile>};

// Tile data recording destructible actor information
struct native DestructibleTileData
{
   var init array<Destructible>          DestructibleActors;
   var init array<Destructible>          SwapMeshes;				// Destroyed Actors that no longer contribute to gameplay data but have a visual mesh still hanging about
   var init array<XComFracLevelActor>    FracActors;
   var init array<int>                   FractureChunks; // Fracture actor and chunk index encoded as an int

   structcpptext
   {
	   UBOOL Contains( AActor *Actor, const FVector &Location, UXComWorldData &WorldData );
	   UBOOL TileSharesDestructibles( const FVector &Location, UXComWorldData &WorldData );
   }
};

struct native DestructibleEffectTileData
{
	var init array<Actor> Actors;
};

enum EShapeType
{
	SHAPE_SPHERE,
	SHAPE_CYLINDER,
	SHAPE_BOX,
	SHAPE_CONE,
	SHAPE_CAPSULE,
};

cpptext
{
	enum TileStaticFlags
	{	
		TileDataBlocksPathingXNeg       = 1 << 1,
		TileDataBlocksPathingXPos       = 1 << 2,
		TileDataBlocksPathingYNeg       = 1 << 3,		
		TileDataBlocksPathingYPos       = 1 << 4,
		TileDataBlocksPathingZNeg       = 1 << 5,		
		TileDataBlocksPathingZPos       = 1 << 6,

		// If you change the order of any of the visibility flags, you need to update
		//   occupancy texture code in XComWorldDataRendering and possibly related shader code
		//   So please don't do that unless you have to. JMS
		TileDataBlocksVisibilityXNeg    = 1 << 7,
		TileDataBlocksVisibilityXPos    = 1 << 8,
		TileDataBlocksVisibilityYNeg    = 1 << 9,		
		TileDataBlocksVisibilityYPos    = 1 << 10,
		TileDataBlocksVisibilityZNeg    = 1 << 11,		
		TileDataBlocksVisibilityZPos    = 1 << 12,		
		
		TileDataIsFloorTile             = 1 << 13,
		TileDataIsRampTile              = 1 << 14, /**Special type of floor tile, so ramp tiles are Ramp AND Floor tiles*/
		TileDataOccupied                = 1 << 15,
		TileDataOccupiedPartial         = 1 << 16,
		TileDataPathBlocking            = 1 << 17, /**Similar in function to occupied, but is a coarser check and does not require valid cover*/
										//1 << 18,	Unused.  Was TileDataFlammable
		TileDataHasLargeUnitClearance   = 1 << 19,/**This returns true if the tile has clearance on (TileX+1,TileY) (TileX,TileY+1) and (TileX+1,TileY+1)*/
		TileDataIsLedgeTile             = 1 << 20,
		TileDataCanEndMoveOnTile        = 1 << 21,

		TileDataIsBorderTileXPos		= 1 << 22,
		TileDataIsBorderTileXNeg		= 1 << 23,
		TileDataIsBorderTileYPos		= 1 << 24,
		TileDataIsBorderTileYNeg		= 1 << 25,

		TileDataIsWaterTile             = 1 << 26,
		TileDataFloorTileOccupier		= 1 << 27,
	};

	enum TileVoxelDataFlags
	{
		TileDataVoxelBlocking = 1,
		TileDataVoxelConceals = 1 << 1,
	};

	enum TileVisibilityFlags
	{
		TileDataNeverSeen = 1 << 1,
		TileDataHaveSeen = 1 << 2,
		TileDataCanSee = 1 << 3,
	};

	enum TileDynamicFlags
	{
		TileDataIsBlockedByUnit         = 1 << 1,
		TileDataIsOnFire                = 1 << 2,
		TileDataContainsSmoke           = 1 << 3,
		TileDataContainsPoison          = 1 << 4,
	};

	enum ViewerPosture
	{
		ePostureDefault,
		ePosturePeekLeft,
		ePosturePeekRight
	};

	void BuildTileData(const FTTile &Tile, const FVector& WorldMin);
	void BuildSeedData();
	void BuildInteractionData(); //Iterates all interactive level actors - can only be used if pathing is rebuilt for an entire level
	void BuildInteractionDataForInteractiveActor( AXComInteractiveLevelActor *InteractiveLevelActor );

	virtual void PreSave();
	virtual void PostLoad();
	virtual void BeginDestroy();

	// FTickableObject interface
	virtual void Tick(FLOAT DeltaTime);	
	virtual UBOOL IsTickable() const
	{	
		return !HasAnyFlags( RF_Unreachable | RF_AsyncLoading );
	}
	virtual UBOOL IsTickableWhenPaused() const
	{
		return FALSE;
	}
	
	// =====
	void ComputeWorldAmbientFromTileData(BYTE* OutWorldAmbient);
	void ComputeVisBlockingFromTileData( BYTE* OutVisBlocking );

	//Support functions for building the world data
	void RemoveFloorDataHelper( const FTTile &Tile, AActor *FloorActor, UXComGameState_EnvironmentDamage *DamageStateObject, TSet<FTTile> &PathingModifiedTiles );
	void UpdateTileNeighbor( const FTTile &From, const FTTile &To, UBOOL skip_remove = FALSE );

	BYTE ComputeDirectionsToCheck(const FTTile &Tile);
	void ComputeCoverPoints(const FTTile &Tile, BYTE DirectionsToCheck, UBOOL bDiagonal, AActor* IgnoreActor = NULL);
	void ClearAndComputeCoverPoints( const FTTile &Tile, BYTE Directions, UBOOL bDiagonal, AActor* IgnoreActor = NULL );
	void ComputeOccupancy(const FTTile &Tile, UBOOL bPartial, UBOOL bPerformFloorCheck);
	void ComputeVisibilityVoxels(const FTTile &Tile, UBOOL Refresh = FALSE);
	INT  ComputeTileSupportsLargeUnits(const FTTile &Tile);
	void ComputeBlockingFlags(const FTTile& Tile, FTileData& TileData, UBOOL bIncludeRenderVisibility = FALSE);
	void ComputeTileNeighbors(const struct FTileDesc& Tile, BYTE DirectionsToCompute = 0xFF);
	void ComputeLevelBorderTiles(const struct FTTile& Tile);
	void FindAndAddDropDown(const FTTile& SourceTile, UINT SourceTileFlags, const FTTile& NeighborTile, UINT NeighborTileFlags, const FTTile& NeighborOffset, UBOOL DirectionBlockedHigh);
	void FindAndAddWallClimbs(const FTTile& SourceTile, UINT SourceTileFlags, const FTTile& NeighborTile, UINT NeighborTileFlags, const FTTile& NeighborOffset, 
							  UINT LowCoverFlag, UINT CoverDirFlag);
	void FindAndAddClimbOverOnto(const FTTile& SourceTile, const FTTile& NeighborTile, UBOOL bSourceDiagonal,
								 UINT NeighborTileStaticFlags, const FTTile& NeighborOffset, UINT ClimbOverFlags, UINT ClimbOntoFlags,
								 UINT HighPathFlags, UINT BlockedCheckFlag, UINT NeighborBlockedCheckFlag);
	void FindAndAddClimbOver2Tile(const FTTile& SourceTile, const FTTile& ClimbOverTile, UINT  ClimbOverTileFlags,
												const FTTile& LandingTile, UBOOL DirectionBlockedHigh);
	void FindAndAddDoorCrossing(const FTTile& SourceTile, const FTTile& NeighborTile, UBOOL bCheckForWindowKick);
	void ComputeInteractions(const FTTile& Tile); //Might affect regular neighbor nodes ( eg. doors ), so has to happen prior to that processing
	void ComputeLadders(const FTTile& Tile, UBOOL AnyTile = FALSE); //Requires regular neighbor nodes / drop down / climb over to have been generated
	void ReviewFloorTileStatus(const FTTile& Tile, FTileData& TileData );
	void ProcessVolumeEffects(FLOAT DeltaT);
	void SetUpSmokeEffects(	const FTTile& Tile, UINT DynamicFlags, TileDynamicFlags eSmokeType, INT iDuration );
	void CleanupVisibilityProcessing();	
	void UpdateUnitVisibility(class AActor* Viewer,UBOOL bIncremental,UBOOL bCheckRange);
	void UpdateVisibilityMapForViewer( INT ViewerIndex, UBOOL bForce = FALSE);
	void ClearVisibilityMap(INT ViewerFlags, WORD HasSeenSetting); //Sets any CanSee tiles to HaveSeen

	void RebuildTile( const FTTile& Tile );
	void ComputeAltFloorNormal( const FTTile& Tile );

	/**Kicks off the render thread process for updating the visibility map texture*/
	void UpdateVisibilityMapTexture();
	void UpdateOccupancyTexture();
	void UpdateVisBlockingTexture();

	//Queries against the world data
	UBOOL GetTileViewerData(INT ViewerIndex, const FTTile &kTile, UINT& ViewerData) const;
	UBOOL IsFloorTileAndValidDestination(const FTTile &Tile, const UXComGameState_Unit *UnitState = NULL);
	UBOOL IsReachableFloorTile(const FTTile &Tile);
	UBOOL IsLedgeTile(const FTTile &Tile);
	UBOOL IsTileAdjacentToCover(const FTTile& Tile); // returns true if the given tile either abuts cover, or there is a cover on one of it's diagonals
	UBOOL TileBlocksVisibility(const FTTile &Tile, const FTTile &Delta);
	UBOOL TileBlocksPathing(const FTTile &Tile, const FTTile &Delta, UINT DynamicBlockingFlags = 0);
	UBOOL TileOutOfRange(const FTTile& Tile);
	UBOOL BuildTileCacheInternal(const FTTile& StartingTile, const FTTile& DestinationTile, INT MaxPathCost = -1);
	UBOOL CanSeeInternal( INT ViewerIndex, ViewerPosture SourcePosture, const FTTile& SourceTile, const FVector& SourcePosition,
						  AXGUnitNativeBase* FromUnit, AActor* FromActor, AXGUnitNativeBase* ToUnit, AActor* ToActor,
						  BYTE CheckForFlag, INT& OutVisInfo, UBOOL bCheckRange, AXComTraceManager* TraceMgr );

	UBOOL CanStopProjectile(AActor* TestActor);

	// Helper function to recurse through the specified Actor (so that Blueprints or other associated actors can 
	// also be added to the rebuild list).
	void InternalSetRebuildActor( AActor* InActor, BYTE RebuildType );

	FTTile GetFallingFloor( FTTile Tile, int ResistiveHealth );

	static void GetExpandedDestructibleBounds( AXComDestructibleActor *Destructible, FVector &ExpMin, FVector &ExpMax, FVector &Axis );
	static void GetExpandedFracActorBounds( AXComFracLevelActor *FracActor, FVector &ExpMin, FVector &ExpMax, FVector &Axis );

	//------------------------------------------------------------------------------
	// Damage data
	//------------------------------------------------------------------------------

	// Add/remove an actor from the destruction tile data
	void FlushDestructionTileData();
	void FlushEnvDmgTileData();
	void RegisterDestructionActor( AActor* Actor );
	void DeregisterDestructionActor( AActor* Actor );
	void RegisterFractureChunks( AXComFracLevelActor* FracActor );
	void DeregisterFractureChunks( AXComFracLevelActor* FracActor );
	void AddFracActorRuntime( AXComFracLevelActor* FracActor );
	void AddRemainingSwapMesh( AXComDestructibleActor *Destructible, const FTTile &kTile );
	void ResolveAllFractureChunkNeighbors();
	void ResolveFractureChunkNeighbors( AXComFracLevelActor* FracActor );
	void ClearNeighborChunks( class AXComTileFracLevelActor* TileFracActor );
	void GatherNeighborChunks( class AXComTileFracLevelActor* TileFracActor ); 
	void AddDestructionActorToTile( AActor* Actor, const FTTile &kTile );
	void RemoveDestructionActorFromTile( AActor* Actor, const FTTile &kTile );
	void AddFractureChunkToTile( UINT FracChunkID, const FTTile &kTile );
	void RemoveFractureChunkFromTile( UINT FracChunkID, const FTTile &kTile );
	void AddDestructionEffectActorToTile(AActor* Actor, const FTTile &kTile);
	void RemoveDestructionEffectActorToTile(AActor* Actor, const FTTile &kTile);

	void HandleDestructionVisuals( const TArray<struct FTTile> &FractureTiles, const TArray<class AXComTileFracLevelActor*> &AdjacentFracActors,
									const TArray<class IDestructible*> &DestructibleActors, TSet<UINT> &UniqueRemovedChunks,
									UXComGameState_EnvironmentDamage* DamageEventStateObject);

	UINT GetDmgFromTileCoordinates( const FTTile &kTile );

	FORCEINLINE UBOOL TileOnBoard( const FTTile& TileCoords ) const
	{
		return (TileCoords.X >= 0) && (TileCoords.Y >= 0) && (TileCoords.Z >= 0) &&
			(TileCoords.X < NumX) && (TileCoords.Y < NumY) && (TileCoords.Z < NumZ);
	}

	UINT GetFracActorID( AXComFracLevelActor* FracActor );
	UBOOL FindFracActorID( AXComFracLevelActor* FracActor, INT& ID );
	AXComFracLevelActor* GetFracActor( UINT ID );

	void GatherTileLadders(const TArray<FTTile> &Tiles,
								 TArray<AXComLadder*> &DestructibleLadders);

	void GatherTileDestructibles( const TArray<FTTile> &Tiles,
									TArray<FTTile> &DamageTiles,
									TArray<IDestructible*> &DestructibleActors,
									TSet<UINT> &UniqueRemovedChunks,
									TSet<FTTile> &AdjacentTiles,
									TArray<AXComTileFracLevelActor*> &AdjacentFracActors,
									UXComGameState_EnvironmentDamage *DamageGameState = NULL );

	TArray<UX2Effect*> GetTileEntryEffects( const FName &Name );

	static UXComWorldData *Instance();

	static UBOOL VoxelRaytrace( const FTTile &SourceTile,
								const FTTile &DestTile, 
								const FTTile &SourceVoxel,
								const FTTile &DestVoxel,
								const FTTile &WorldDimensions,
								INT CheckStaticFlags, void* VoxelTileData,
								void* DynamicTileFlags, FVoxelRaytraceCheckResult& OutCheckResult, 
								void* TileViewerFlags = NULL, BYTE TileViewerSetting = 0x0 ); //Optional params that make the voxel ray trace update tiles as it passes through them

	static UBOOL VoxelRaytrace( const FVector& Source, const FVector& Dest, 
								INT CheckStaticFlags, void* VoxelTileData,
								void* DynamicTileFlags, FVoxelRaytraceCheckResult& OutCheckResult );

	FORCEINLINE UBOOL IsValid()
	{
		return (WorldDataPtr != NULL);
	}

	void GetTeamAdjacentDestructibles( ETeam team, FDestructibleTileData &DestructibleData );
	void MaybeAddForcedDestructionGamestates(class UXComGameState *NewGameState, const TArray<AXComDestructibleActor*> &Destructibles, class UXComGameState_EnvironmentDamage *DamageEvent);

	//Debugging
	void UpdateCoverRendering();
	void UpdateFloorRendering();

	//Serialization
	/**
	* Callback used to allow object register its direct object references that are not already covered by
	* the token stream.
	*
	* @param ObjectArray	array to add referenced objects to via AddReferencedObject
	* - this is here to keep the navmesh from being GC'd at runtime
	*/
	virtual void AddReferencedObjects( TArray<UObject*>& ObjectArray );
	virtual void Serialize(FArchive& Ar);
	void         PostSaveGameSerialize(); /** Special handling to clear out any transient serialized properties */

	struct FTileCollectShape
	{
		FTileCollectShape( const FVector& p, FLOAT r );
		FTileCollectShape( const FVector& p, FLOAT r, FLOAT h );
		FTileCollectShape( const FVector& min, const FVector& max );
		FTileCollectShape( const FVector& p, const FVector& axis, const FLOAT r );
		FTileCollectShape( const FLOAT r, const FVector& p, const FVector& axis );

		UBOOL Contains( const FVector &p ) const;

		void GetExtents( FVector &min, FVector &max ) const;

	private:
		EShapeType Type;

		FVector Position;
		FVector ConeAxis;

		FLOAT Radius;
		FLOAT Height;
		FLOAT ConeAngle;

		FVector Minimum;
		FVector Maximum;
	};

	typedef void (*CollectTilesCallback)( const FTTile&, const FVector&, void* );
	void CollectTiles( const FTileCollectShape &Shape, CollectTilesCallback WorkerCallback, void *UserData = NULL );
}

struct native TilePosPair
{
	var TTile Tile;
	var Vector WorldPos;

	structcpptext
	{
		FORCEINLINE UBOOL operator==(const FTilePosPair &Other) const
		{
			return Tile == Other.Tile && WorldPos == Other.WorldPos;		
		}

	}
};

struct native TileParticleInfo
{
	var TTile Tile;
	var Int ParticleKey;
	var Rotator Rotation;
	var TTile TileOffset;
	var Int NumXTiles;
	var Int NumYTiles;
	var init array<TTile> CoveredTiles;
};

struct native TileIsland
{
	var init array<TilePosPair> Tiles;
	var int Intensity;

	structcpptext
	{
		UBOOL IsTileAttached(FTilePosPair Tile);
		UBOOL IsTileAttached(FTilePosPair Tile, FVolumeEffectTileData TileData);
		void AttachTile(FTilePosPair Tile);
		void GetBounds(FTTile& MinBounds, FTTile& MaxBounds) const;
		void GetWorldBounds(FVector& MinBounds, FVector& MaxBounds) const;
	}
};

struct native ActorTraceHitInfo
{
	var Actor  HitActor;
	var Vector HitLocation;
};

//============================================================================
// Visibility map interface
//============================================================================
native function RegisterActor( Actor Viewer, int SightRadius, optional vector PositionOffset ); //Adds a viewer to the Viewers list
native function UnregisterActor( Actor Viewer, optional bool bRemoveFromUnitsArrays=true );//Removes a viewer from the Viewers list
native function InitializeWorldData();//Initializes the singleton we use for storing our spatial data structures
native function Cleanup();//Cleans up the singleton we use for storing our spatial data structures
native function UpdateFloorHeight(float ShowFloorHeight = -1.0);//Used by the building visibility system
native function BuildWorldData( XComLevelVolume LevelVolume );/*Run when users save a map, this will quantize the playable game space and build a 3d tile grid*/
native function StartAsyncBuildWorldData();
native function bool AsyncBuildWorldDataComplete();

//An interface for arbitrarily showing / hiding areas in the FOW
native function Actor CreateFOWViewer(vector Location, float Radius, INT UseObjectID = -1);
native function DestroyFOWViewer(Actor Viewer);

//This method is run when starting a tactical game. It handles syncing up the world data tile information with what is contained within the game state history, as well as
//updating any actors affected by changes to the world data ( such as damage ).
native function SyncVisualizers(optional int HistoryIndex = -1);
native function SyncReplay(XComGameState ProcessGameState, optional out array<int> out_WorldEffectUpdateStateObjectIDs);

//------------------------------------------------------------------------------
// Destruction data
//------------------------------------------------------------------------------
native function RebuildDestructionData( optional bool bRefreshDecoMeshes=false ); // Performs any destruction data initialization that should be performed when all levels are finished loading
native function AddDestructiblesPlacedOnTop( Actor Destructible, const out StateObjectReference DestructionEventID );

//------------------------------------------------------------------------------
// Tile coordinate conversions / queries
//------------------------------------------------------------------------------
native function TTile GetTileCoordinatesFromPosition( const out Vector Position, bool bVoxelCoords=false );/*Converts a 3d vector position into a 3d tile grid coordinates, voxel coords specifies that the tile coordinates should be in visibility voxel space*/
native function Vector GetFractionalTileCoordinatesFromPosition( const out Vector Position );/*Converts a 3d vector position into a 3d coordinate w/i a single tile*/
native function bool IsTileOutOfRange(const out TTile kTile);/*Queries if current tile is out of range, ie. inside the level volume or not*/
native function ClampTile( out TTile kTile );/*clamps the input tile to the level volume*/
native function Vector GetClosestValidCursorPosition( Vector currentLocation, int iLockToFloor=-1 );/*Gets the closest valid position on the WorldGrid*/
native function vector GetPositionFromTileCoordinates(const out TTile kTile);/*Converts 3d tile grid coordinates into a 3d position*/
native function vector GetCornerPositionFromTileCoordinates(const out TTile kTile);/*Converts 3d tile grid coordinates into a 3d position at the corner of the tile*/
native function vector GetPositionFromTileIndex(INT Index);/*Convert a tile index into position*/
native function bool GetFloorTileForPosition( const out vector Position, out TTile kTile, bool bUnlimitedSearch=false );/*For a given position, will find the floor tile either at or one tile below that position*/
native function int  GetFloorTileZ(TTile kTile, bool bUnlimitedSearch=false ); // Returns floor tile Z given tile location, if found.  Otherwise returns source Z.
native function float GetFloorZForPosition( const out vector Position, bool bUnlimitedSearch=false );
native function bool GetFloorPositionForTile(TTile kTile, out vector FloorPosition); // returns true/false whether or not the tile is a floor tile.  if it's a floor tile, FloorPosition set to where the floor is in that tile
native function bool IsPositionOnFloor( const out Vector Position );
native function bool IsPositionOnFloorAndValidDestination( const out Vector Position, optional XComGameState_Unit UnitState );
native function bool TileHasFloorThatIsDestructible( const out TTile kTile );
native function bool IsFloorTile( const out TTile kTile, optional Actor IgnoreFloor );
native function bool IsRampTile(const out TTile kTile);

// Utility function to determine if there is clearance from one tile to an adjacent tile for the purposes of melee, interaction, etc
native function bool IsAdjacentTileBlocked(const out TTile SourceTile, const out TTile DestinationTile) const;

native function CollectTilesInSphere( out array<TilePosPair> Collection, const out Vector Position, float Radius );
native function CollectTilesInCylinder( out array<TilePosPair> Collection, const out Vector Position, float Radius, float Height );
native function CollectTilesInBox( out array<TilePosPair> Collection, const out Vector Minimum, const out Vector Maximum );
native function CollectTilesInCone(out array<TilePosPair> Collection, const out Vector Position, const out Vector ConeAxis, float Radius);
native function CollectTilesInCapsule(out array<TilePosPair> Collection, const out Vector PositionA, const out Vector PositionB, float Radius);

native function CollectDestructiblesInTiles( const out array<TilePosPair> Tiles, out array<XComDestructibleActor> Destructibles );

//Given a disc specified by Position + Radius within the XY plane, will produce a list of floor tiles beneath the disc
native function CollectFloorTilesBelowDisc( out array<TilePosPair> Collection, const out Vector Position, float Radius );

//Finds the PathObject associated with the traversal between two neighboring tiles.
native function Actor GetPathObjectFromTraversalToNeighbor(const TTile StartTile, const TTile EndTile, bool bUnitIsLarge);

native function bool TileContainsPoison(const out TTile kTile);
native function bool TileContainsSmoke(const out TTile kTile);
native function bool IsWaterTile(const out TTile Tile);
native function bool IsGroundTile(const out TTile kTile, name NotConsideredGroundTag = '');

native function bool TileContainsFire(const out TTile kTile);
native function bool TileContainsAcid(const out TTile kTile);

native function bool TileContainsWorldEffect(const out TTile kTile, name WorldEffectClassName);

//GetTileDebugString return a string representation of tile information for debugging and display in-game
native function SetDebugCoverFlag(EScriptCoverDebugFlags FlagSetting);    // CoverDebugFlags |= 1 << FlagSetting
native function UnsetDebugCoverFlag(EScriptCoverDebugFlags FlagSetting);  // CoverDebugFlags &= ~(1 << FlagSetting)
native function AddDebugTile(const out TTile CheckTile);
native function ClearDebugTiles();
native function string GetTileDebugString_StaticFlags(const out TTile CheckTile);
native function ProfileTileRebuild(const out TTile MinTile, const out TTile MaxTile);

//Deprecated - tiles are no longer stored in a flat array! RAM TODO - REMOVE
native function int GetVisibilityMapTileIndex(const out TTile kTile);/*Converts 3d tile grid coordinates into an index into the tiles array*/
native function int GetVisibilityMapTileIndexFromPosition( const out Vector Position );/*Returns an index into the tiles array from a 3d position*/
native function GetVisibilityMapTileCoordinates(INT Index, out TTile kTile);/*Converts an index into 3d tile grid coordinates in the tiles array*/

//------------------------------------------------------------------------------
// Debug
//------------------------------------------------------------------------------
native function UpdateDebugVisuals(optional bool bOnlyShowBlocking=true);/*Rebuilds debug visuals for the visibility map. Only displays the Z level of the position set in the most recent call to 'UpdateVisibilityMapForPosition'*/
native function DebugUpdateVisibilityMapForViewer( Actor Viewer, const out Vector DebugLocation );/*Debugging ONLY*/
native function DisableUnitVisCleanup();

//------------------------------------------------------------------------------
// Volume Effects
//------------------------------------------------------------------------------
//This method loops through all game play volume effects, updates their tile data via state objects inserted into the passed-in game state
native function BuildGameplayTileEffectUpdate(XComGameState OutGameplayTileUpdateState);
native function bool ApplyWorldEffectsToObject(XComGameState_BaseObject ApplyToObject, XComGameState NewGameState); //Returns true if any world effects were added to the object

native function UpdateVolumeEffects(XComGameState_WorldEffectTileData TileDataStateObject, array<ParticleSystem> AssociatedParticleTemplates, bool bCenterTile);
native function UpdateVolumeEffects_PartialUpdate(XComGameState_WorldEffectTileData TileDataStateObject, array<TTile> PartialActivationTiles, bool partialExclude, array<ParticleSystem> AssociatedParticleTemplates, bool bCenterTile);

native function FindFloorInfoForEffect(ParticleSystemComponent ParticleEffect, TTile EffectTile, bool AddEffect = true);

//------------------------------------------------------------------------------
// Pathing / Overmind
//------------------------------------------------------------------------------
delegate CanSeeLocationCallback();
native function bool IsInNoSpawnZone( const out Vector vLoc, bool bCivilian=FALSE, bool bLogFailures=false );
native function CollectLadderLandingTiles(out array<TTile> LadderTiles);
//------------------------------------------------------------------------------
// Visibility
//------------------------------------------------------------------------------
native function bool HasPendingVisibilityUpdates();/*Returns true if any viewers are still processing visibility asynchronously*/
native function FlushCachedVisibility();
native function bool CanSeeTileToTile( const out TTile FromTile, const out TTile ToTile, out GameRulesCache_VisibilityInfo DirectionInfo);
native function bool VoxelRaytrace_Locations( const out Vector FromLocation, const out Vector ToLocation, out VoxelRaytraceCheckResult OutResult );
native function bool VoxelRaytrace_Tiles( const out TTile FromLocation, const out TTile ToLocation, out VoxelRaytraceCheckResult OutResult );
native function BenchmarkRaytraces(int Iterations);

native function bool HasOverheadClearance( const out Vector Location, float ClearanceDistanceRequirement = 64.0f );
native function InitializeAllViewersToHaveSeenFog(bool bSetting); //Special purpose function for kismet - makes 'never seen' fog render as 'have seen'
native function bool IsAdjacentTileVisible( const out Vector FromLocation, const out Vector ToLocation ); // Used for melee clearance check, no vis-blocking high cover between two points.
native function GetTileFOWValue( const out TTile CheckTile, out FOWTileStatus OutFOWTileStatus, out BYTE OutGameplayTileFlags ); //Queries the cached visibility data
native function CachedCoverAndPeekData GetCachedCoverAndPeekData( const out TTile CheckTile ); //Queries a cache storing peek / cover information per tile

native function GetTileViewingUnits( const out TTile CheckTile, out array<XComUnitPawnNativeBase> UnitViewers );

//Visibility debugging support
native function ShowVisibilityVoxels();
native function HideVisibilityVoxels();

native function ShowFOWViewerData();
native function HideFOWViewerData();

//------------------------------------------------------------------------------
// Cover / Interactions
//------------------------------------------------------------------------------
native function GetTileData(const out TTile CheckTile, out TileData Data);

static native final function Vector GetWorldDirection(const int CoverDir, const bool bDiagonal);
static native final function Vector GetPeekLeftDirection(const int CoverDir, const bool bDiagonal);
static native final function Vector GetPeekRightDirection(const int CoverDir, const bool bDiagonal);
static native final function ECoverType GetCoverTypeForTarget(const out Vector ShooterLocation, const out Vector TargetLocation, out float TargetCoverAngle, out optional ECoverDir TargetCoverDir);
static native final function float  GetCoverTestLength(const int CoverDir, const bool bDiagonal);
static native final function bool   GetCoverDirection( out int CoverDir, int dX, int dY ); // dX and dY must be one of the 4 axis directions.
native function bool GetCoverToEnemiesInPathingRange(XGUnitNativeBase Unit, out array<XComCoverPoint> CoverPoints);
native function bool GetCoverPoints(const Vector InPoint, const float Radius, const float Height, out array<XComCoverPoint> CoverPoints, optional bool bSortedByDist=false);
native function bool GetClosestCoverPoint(const Vector InPoint, const float Radius, out XComCoverPoint CoverPoint, optional bool bOnlyUnblockedTiles=false, optional bool bAvoidNoSpawnZones=false);
native function bool GetCoverPoint(const Vector InPoint, out XComCoverPoint CoverPoint); // Gets cover of tile that InPoint is in.
native function bool GetCoverPointAtFloor(const Vector InPoint, out XComCoverPoint CoverPoint); // Gets cover of floor tile at InPoint.
native function bool GetInteractionPoints(const Vector InPoint, const float Radius, const float Height, out array<XComInteractPoint> InteractPoints); // TODO@jboswell: Finish this
native function bool GetClosestInteractionPoint(const Vector InPoint, const float Radius, const float Height, out XComInteractPoint InteractPoint);
native function RemoveInteractionPoints(XComInteractiveLevelActor InActor);
native function bool GetClosestActionLocation(const Vector TestLocation, out Vector ActionLocation, optional float Radius=128.0f);
native function bool IsActionAvailable(const Vector TestLocation, optional float Radius=128.0f);
native function Vector FindClosestValidLocation(const Vector TestLocation, bool bAllowFlying, bool bPrioritizeZLevel, bool bAvoidNoSpawnZones=false); //bPrioritizeZLevel controls whether this function will exhaustively search similar Z levels

native function bool GetSpawnTilePossibilities(const out TTile RootTile, int Length, int Width, int Height, out array<TTile> TilePossibilities);
native function bool GetUnoccupiedNonCoverTiles(const out TTile RootTile, int TileRadius, out array<TTile> TilePossibilities);
native function bool GetFloorTilePositions(const Vector InPoint, const float Radius, const float Height, out array<vector> vFloorTilePositions, optional bool bSortedByDist = false);
//------------------------------------------------------------------------------
// Tile Data ( blocking, fire, etc. )
//------------------------------------------------------------------------------
native function AddActorTileData( Actor NewActor );
native function RemoveActorTileData( Actor ExistingActor, bool Immediate = false );
native function RefreshActorTileData( Actor ExistingActor );
native function UpdateTileDataCache( optional XComGameState_EnvironmentDamage DamageStateObject, bool Immediate = false );

native function ProcessDamageTiles( XComGameState_EnvironmentDamage DamageEventStateObject );
native function RestoreFrameDestructionCollision( );
native function HandleDestructionVisuals( XComGameState_EnvironmentDamage DamageEvent );
native function HandleDestructionVisuals_Selective( XComGameState_EnvironmentDamage DamageEvent, out array<TTile> selectedTiles );


native function UpdateTileRenderVisibility();
native function AddTilesToRenderVisibilityUpdate(array<TTile> TilesToAdd); 

native function StateObjectReference GetUnitOnTile(const out TTile kTile);
native function Actor GetActorOnTile( const out TTile kTile, optional bool bIgnoreUnits = false );
native function XComDestructibleActor FindDestructibleActor( const out ActorIdentifier ActorID );

native function DebugRebuildTileData( const out TTile kTile );
native function DebugDestroyTile( const out TTile kTile, optional bool bOccupierOnly = false, optional bool bFragileDamage );
native function DebugDamageOccupier( const out TTile kTile );

native function ClearTileBlockedByUnitFlag(XComGameState_Unit BlockingUnit);
native function SetTileBlockedByUnitFlag(XComGameState_Unit UnitStateObject);
native function SetTileBlockedByUnitFlagAtLocation(XComGameState_Unit UnitStateObject, const out TTile kTile);
native function bool IsTileBlockedByUnitFlag(const out TTile kTile, optional const XComGameState_Unit IgnoreUnit) const;
static native function XComWorldData GetWorldData();
native function bool IsTileFullyOccupied( const out TTile kTile );
native function bool IsTileOccupied( const out TTile kTile );
native function bool CanUnitsEnterTile( const out TTile kTile );
native function CacheVisibilityDataForTile( const out TTile kTile, out CachedCoverAndPeekData Data); //Calculates cover and peed data for the given tile, and stores it in a cache so that it doesn't need to be recalculated spuriously
native function ClearVisibilityDataAroundTile(const out TTile kTile, float DistanceUnits = 192.0f); //Clears cached cover and peed data around a given tile at a distance of DistanceUnits
native function vector GetValidSpawnLocation(const out vector InitialPt);
native function bool IsLocationVisibleToTeam(const out vector TestLocation, ETeam TeamFlag);

native function bool IsLocationFlammable(const out vector Location);
native function bool SetIsWaterTile( const out TTile kTile, bool bIsWaterTile );
native function bool IsLocationHighCover(const out vector Location);
native function bool IsLocationLowCover(const out vector Location);

native function bool GetAdjacentDestructibles( XComGameState_Unit Unit, out DestructibleTileData DestructibleData, optional out Vector CoverForShooterLocation, optional XComGameState_Unit SourceUnit);

native function GenerateProjectileTouchList(XComGameState_Unit Shooter, const out vector StartLocation, const out vector StopLocation, out array<ProjectileTouchEvent> OutProjectileTouchEvents, bool bDebug);

//Provides custom projectile logic to a trace. This provides contextual behavior for the real-time simulating visuals of a projectile.
native function bool ProjectileTrace(XComGameStateContext_Ability AbilityContext, out Vector HitLocation, out Vector HitNormal, Vector TraceStart, Vector TraceDirection, bool bCollideWithTargetPawn, optional out TraceHitInfo HitInfo);

//------------------------------------------------------------------------------
// Special purpose / game play
//------------------------------------------------------------------------------
native function DoInitialTextureStreaming(const Vector Location);//I didn't know where else to put this. Called from XGBattle, needs to be native -sboeckmann
native function ProcessFlameThrowerSweep(bool bProcessFire, XComUnitPawn UnitPawn, const Vector Facing, float AimOffsetX, float FlameRange, 
										 float SweepAngle, out array<XGUnitNativeBase> OutFlamedUnits, out array<vector> OutSecondaryFireLocations);
native function DrawFlameThrowerUI(XComUnitPawnNativeBase UnitPawn, const out Vector OriginLoc, const out Vector TargetLoc, float FlameRange, float SweepAngle, out array<Actor> OutFlamedUnits);
native function ClearFlameThrowerUI();

// Returns true if the given unit can grapple to the specified tile.
// If Peek is set, then the unit must step out on that peek side to perform the grapple
// Overhang tile indicates which neighboring tile the unit will pass through to reach the ledge
// If the grapple needs to break a window, that is also returned
native function bool IsValidGrappleDestination(const out TTile Dest, XComGameState_Unit UnitState, out UnitPeekSide Peek, out TTile OverhangTile, out XComDestructibleActor WindowToBreak);
native function bool HasClimboverDropdownForGrapple(const out TTile Dest, const out TTile Offset, out XComDestructibleActor WindowToBreak); // helper for IsValidGrappleDestination

//Uses XComCover line checks which are what the vis system uses to build tile data. Refer to enum CheckType to get alternate values for CheckType
native function bool WorldTrace( const out vector StartLocation, const out vector EndLocation, out vector HitLocation, out vector HitNormal, out actor HitActor, optional int CheckType = 4 ); 

native function bool GetAllActorsTrace(const out vector StartLocation, const out vector EndLocation, out array<ActorTraceHitInfo> HitInfo);
//============================================================================
//

native function SubmitUnitFallingContext(XComGameState_Unit FallingUnit, TTile Tile);

//Event manager callback methods
native function EventListenerReturn OnGameplayTileEffectUpdate(Object EventData, Object EventSource, XComGameState GameState, Name EventID);

//World effects update at the start of each turn. For now this is a general rule, but eventually each type of effect might have its own update rules.
static function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_Player EventPlayer;
	local XComGameStateContext_UpdateWorldEffects UpdateWorldEffectsContext;	
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	
	EventPlayer = XComGameState_Player(EventData);	
	if( EventPlayer != none )
	{
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if( EventPlayer.ObjectID == BattleData.PlayerTurnOrder[0].ObjectID ) //If the first player's turn is starting, update per-turn effects
		{
			UpdateWorldEffectsContext = XComGameStateContext_UpdateWorldEffects(class'XComGameStateContext_UpdateWorldEffects'.static.CreateXComGameStateContext());
			`GAMERULES.SubmitGameStateContext(UpdateWorldEffectsContext);
		}	
	}
	else
	{
		`redscreen("OnPlayerTurnBegun: EventPlayer should not be NULL");
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnObjectMoved(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{	
	local XComGameState_BaseObject ApplyEffectsToObject;
	local XComGameStateContext_ApplyWorldEffects ApplyWorldEffectsContext;	
	
	ApplyEffectsToObject = XComGameState_BaseObject(EventData);	
	if( ApplyEffectsToObject != none )
	{		
		ApplyWorldEffectsContext = XComGameStateContext_ApplyWorldEffects(class'XComGameStateContext_ApplyWorldEffects'.static.CreateXComGameStateContext());
		ApplyWorldEffectsContext.ApplyEffectTarget = ApplyEffectsToObject;

		//The game state submission process will handle building / not building a new game state based on whether the moving object can be affected
		`GAMERULES.SubmitGameStateContext(ApplyWorldEffectsContext);
	}
	else
	{
		`redscreen("OnObjectMoved: ApplyEffectsToObject should not be NULL");
	}

	return ELR_NoInterrupt;
}

function bool TeamInRadiusOfUnit( ETeam team, int tile_radius, XGUnit Unit)
{
	local XComGameStateHistory History;
	local array<TilePosPair> OutTiles;
	local float Radius;
	local vector Location;
	local TilePosPair TilePair;
	local TTile TileLocation;
	local StateObjectReference UnitReference;
	local XGUnitNativeBase TileUnit;

	History = `XCOMHISTORY;

	Radius = tile_radius * WORLD_StepSize;

	Location = Unit.Location;
	Location.Z += tile_radius * WORLD_FloorHeight;

	TileLocation = GetTileCoordinatesFromPosition( Unit.Location );

	CollectFloorTilesBelowDisc( OutTiles, Location, Radius );

	foreach OutTiles( TilePair )
	{
		if (abs( TilePair.Tile.Z - TileLocation.Z ) > tile_radius)
		{
			continue;
		}

		UnitReference = GetUnitOnTile( TilePair.Tile );
		if(UnitReference.ObjectID > 0)
		{
			TileUnit = XGUnitNativeBase(History.GetVisualizer(UnitReference.ObjectID));
			if(TileUnit != none && (TileUnit.m_eTeam == team))
			{
				return true;
			}
		}
	}

	return false;
}

static function EventListenerReturn OnEnvironmentalDamageOccurred(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{	
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameStateHistory History;
	local XComGameState SetFiresGameState;
	local XComGameState_EnvironmentDamage EnvironmentDamage;	
	local X2DamageTypeTemplate DamageTypeTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local int Index;
	local TilePosPair CandidateTile;
	local array<TilePosPair> CandidateFireTiles;	
	local Vector DiscLocation;
	//local Vector DrawDebugBoxExtents;
	local int FireCount;
	local int FireRoll;
	local int Intensity;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	//Check to see whether this environmental damage should set secondary fires
	EnvironmentDamage = XComGameState_EnvironmentDamage(EventSource);	
	if(EnvironmentDamage != none && (`CHEATMGR == None || !`CHEATMGR.bDisableSecondaryFires))
	{
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
		DamageTypeTemplate = ItemTemplateManager.FindDamageTypeTemplate(EnvironmentDamage.DamageTypeTemplateName);

		FireRoll = `SYNC_RAND_STATIC(100);
		FireCount = DamageTypeTemplate.MinFireCount + `SYNC_RAND_STATIC(DamageTypeTemplate.MaxFireCount + 1);
		
		//There is a minimum required damage amount of destruction to set secondary fires
		if(FireRoll <= DamageTypeTemplate.FireChance &&
		   FireCount > 0 &&
		   EnvironmentDamage.DamageAmount >= 10 &&
		   EnvironmentDamage.bAffectFragileOnly != true) 
		{
			/*
			DrawDebugBoxExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
			DrawDebugBoxExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
			DrawDebugBoxExtents.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;			
			*/
			if(EnvironmentDamage.DamageTiles.Length == 1)
			{
				CandidateTile.WorldPos = WorldData.GetPositionFromTileCoordinates( CandidateTile.Tile );
				if(WorldData.IsLocationFlammable(CandidateTile.WorldPos))
				{
					//For the simple case, there is just one candidate
					CandidateTile.Tile = EnvironmentDamage.DamageTiles[0];
					CandidateFireTiles.AddItem(CandidateTile);
				}

				//Prefer to set occupied tile adjacent to the recent damage on fire
				for(Index = 0; Index < EnvironmentDamage.AdjacentFractureTiles.Length; ++Index)
				{
					CandidateTile.Tile = EnvironmentDamage.AdjacentFractureTiles[Index];
					CandidateTile.WorldPos = WorldData.GetPositionFromTileCoordinates(CandidateTile.Tile);
					if(WorldData.IsLocationFlammable(CandidateTile.WorldPos))
					{
						CandidateFireTiles.AddItem(CandidateTile);
						//class'WorldInfo'.static.GetWorldInfo().DrawDebugBox(CandidateTile.WorldPos, DrawDebugBoxExtents, 255, 255, 255, true);
					}
				}
			}
			else
			{
				//Prefer to set occupied tile adjacent to the recent damage on fire
				for(Index = 0; Index < EnvironmentDamage.AdjacentFractureTiles.Length; ++Index)
				{	
					CandidateTile.Tile = EnvironmentDamage.AdjacentFractureTiles[Index];
					CandidateTile.WorldPos = WorldData.GetPositionFromTileCoordinates(CandidateTile.Tile);
					if(WorldData.IsLocationFlammable(CandidateTile.WorldPos))
					{
						CandidateFireTiles.AddItem(CandidateTile);
						//class'WorldInfo'.static.GetWorldInfo().DrawDebugBox(CandidateTile.WorldPos, DrawDebugBoxExtents, 255, 255, 255, true);
					}
				}
				
				//Failsafe, fires on floor tiles / destructibles if there were no appropriate fracture adjacent tiles
				if(CandidateFireTiles.Length == 0)
				{					
					DiscLocation = EnvironmentDamage.HitLocation;
					DiscLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight * 2;
					WorldData.CollectFloorTilesBelowDisc(CandidateFireTiles, DiscLocation, EnvironmentDamage.DamageRadius);
				}
			}
						
			//Reduce the list to the size we want
			while(CandidateFireTiles.Length > FireCount)
			{	
				CandidateFireTiles.Remove(`SYNC_RAND_STATIC(CandidateFireTiles.Length), 1);
			}

			if (CandidateFireTiles.Length > 0)
			{
				//Yes, let's set some fires
				History = `XCOMHISTORY;
				ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Set Secondary Fires");
				ChangeContainer.BuildVisualizationFn = EnvironmentDamage.VisualizeSecondaryFires;

				//Defer to the game state that triggered us for timing.
				if (GameState.GetContext().DesiredVisualizationBlockIndex > -1)
				{
					ChangeContainer.SetDesiredVisualizationBlockIndex(GameState.GetContext().DesiredVisualizationBlockIndex);
				}
				else
				{
					ChangeContainer.SetDesiredVisualizationBlockIndex(GameState.HistoryIndex);
				}
			
				SetFiresGameState = History.CreateNewGameState(true, ChangeContainer);
			
				//All damage based fire starts at intensity 1
				Intensity = 1;
				class'X2Effect_ApplyFireToWorld'.static.SharedApplyFireToTiles('X2Effect_ApplyFireToWorld', X2Effect_ApplyFireToWorld(class'Engine'.static.FindClassDefaultObject("X2Effect_ApplyFireToWorld")), SetFiresGameState, CandidateFireTiles, none, Intensity);

				`GAMERULES.SubmitGameState(SetFiresGameState);
			}
		}
	}

	return ELR_NoInterrupt;
}

event RegisterForObliterate()
{
	`XCOMHISTORY.RegisterOnObliteratedGameStateDelegate(OnObliterateGameState);
}

event RegisterForNewGameState()
{
	`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState);
}

native function OnNewGameState(XComGameState NewGameState);

native function OnObliterateGameState(XComGameState ObliteratedGameState);

defaultproperties
{
	NumX = 0
	NumY = 0
	NumZ = 0
	bDrawVisibilityChecks = false	
	bUseLineChecksForFOW = false	
	LastFloorHeight = -1.0
	bDebugBlockingTiles = false
	bEnableFOW = true
	bDebugEnableFOW = true;
	bEnableFOWUpdate = false
	bUpdatingVisibility = false
	bUseSingleThreadedSolver = false
	bWorldDataInitialized = false
	bFOWTextureBufferIsDirty = true
	bDisableVisibilityUpdates = true
	bUseIntroFOWUpdate = false
	bDebugFOW = false
	bEnableUnitOutline = true
	bCinematicMode = false
	iDebugFloorTileUnitSize=1
	DebugFOWViewer=-2
	bBatchingTileUpdates=false

	DefaultFractureActorPath = "FX_DestructionDefaults.ARC_FracActor"
	DefaultDestructibleActorPath = "FX_DestructionDefaults.ARC_DestructibleActor"

	SupportedViewerClasses(0) = class'XComUnitPawnNativeBase'

	StaticRainDepthCaptureState = eEMCS_Off
}
