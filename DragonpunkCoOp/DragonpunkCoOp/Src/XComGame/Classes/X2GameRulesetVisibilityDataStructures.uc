class X2GameRulesetVisibilityDataStructures extends object native(Core);

enum UnitPeekSide
{
	eNoPeek,
	ePeekLeft,
	ePeekRight
};

struct native VoxelRaytraceCheckResult
{	
	var int     BlockedFlag;    //Indicates which blocking flag was responsible for blocking the trace. 0x0 if the trace was not blocked
	var byte    TraceFlags;     //Contains info about what the trace passed through ( smoke, windows, etc. )
	var TTile   BlockedTile;    //If bBlocked is true, contains the tile that blocked the trace	
	var TTile   BlockedVoxel;   //If bBlocked is true, contains the voxel that blocked the trace
	var bool    bDebug;         //Instructs the voxel raytrace to draw debug data
	var bool	bRecordAllTiles;	//Instructs the voxel raytrace to record all the tiles traced through.  Tiles can be found in TraceTiles member
	var bool	bTraceToMapEdge;	//Instructs the voxel raytrace to trace all the way to the map edge (having travelled through the end tile).
		
	var vector  TraceStart;
	var vector  TraceEnd;       
	var vector  TraceBlocked;	//Contains the location of the voxel where the trace was blocked
	var Actor	TraceBlockedActor;//The actor that created the blocking voxel that blocked this trace
	var float   Distance;       //Linear distance of this trace

	var array<TTile>	TraceTiles; // All the Tile that were traced through

	structcpptext
	{
	FVoxelRaytraceCheckResult()
	{
		appMemzero(this, sizeof(FVoxelRaytraceCheckResult));
	}
    FVoxelRaytraceCheckResult(EEventParm)
    {
        appMemzero(this, sizeof(FVoxelRaytraceCheckResult));
    }
	FORCEINLINE void InitializeForQuery()
	{
		appMemzero(this, sizeof(FVoxelRaytraceCheckResult));
	}
	FORCEINLINE void InitializeForQueryKeepInputFlags( )
	{
		UBOOL debug = bDebug, record = bRecordAllTiles, trace = bTraceToMapEdge;

		appMemzero( this, sizeof(FVoxelRaytraceCheckResult) );

		bDebug = debug;
		bRecordAllTiles = record;
		bTraceToMapEdge = trace;
	}
	}
};

//A debug-only structure that keeps information on what traces were performed while generating the results stored in a GameRulesCache_VisibilityInfo structure
struct native VisibilityTraceDebugInfo
{
	var vector  TraceStart;	
	var vector  TraceEnd;		
	var Actor   HitActor;   //Set if bHit is true
	var vector  TraceHit;       //Set if bHit is true
	var bool    bHit;
	var int     UsedCachedDataType;

	structcpptext
	{
	FVisibilityTraceDebugInfo()
	{
		appMemzero(this, sizeof(FVisibilityTraceDebugInfo));
	}
	FVisibilityTraceDebugInfo(EEventParm)
	{
		appMemzero(this, sizeof(FVisibilityTraceDebugInfo));
	}
	}
};

//This structure is used to store which cover direction and peek around location should be used
//when targeting other units.
struct native GameRulesCache_VisibilityInfo
{	
	//Use direct IDs since there are going to be a lot of these
	var int                     SourceID;               //Viewer/Shooter
	var int                     TargetID;               //Object against which we are testing visibility

	//Information about the source object's posture relative to target
	var TTile                   SourceTile;             //The tile being used by SourceID to view TargetID
	var int                     CoverDirection;         //The direction of cover to use to face the target referenced by this info structure
	var UnitPeekSide            PeekSide;               //The location of the peek tile to use when stepping out to fire at this unit ( if needed ). Zero if not stepping out.
	var float                   PeekToTargetDist;       //The distance from the peek location to the target, this is used as the main criteria for selecting a peek against a given target
	var float					DefaultTargetDist;		//The distance from the default tile of the source to the target ( default tile, or nearest tile if a multi-tile unit )

	//Information about the target object's posture relative to source	
	var TTile                   DestTile;               //The tile from which TargetID is seen by SourceID
	var ECoverType              TargetCover;            //Caches the type of cover Target has against Source             
	var float                   TargetCoverAngle;   	//The angle from the source to the target relative to the target's cover (in degrees)

	//Flags conveying information on visibility from source to target	
	var bool                    bClearLOS;              //TRUE if LOS is clear (ie. squad sight valid)
	var bool                    bVisibleBasic;          //TRUE if LOS is clear *AND* PeekToTargetDist is less than the source's visibility radius.	
	var bool                    bVisibleFromDefault;    //TRUE if sight to the target does not require a using a peek tile at the source
	var bool                    bVisibleToDefault;      //TRUE if sight to the target does not require a using a peek tile at the target
	var bool                    bConcealedTrace;        //TRUE if the voxel trace hit any of the 'TileDataConceals' flags

	//bVisibleGameplay reflects game play mechanics like stealth, where bVisiblBasic might be true but the state of the unit makes it hidden
	var bool                    bVisibleGameplay;       //Cached result of 'UpdateGameplayVisibility'
	var init array<name>        GameplayVisibleTags;    //Array of names that allow for customizable behavior in response to specific unit conditions
	var bool					bTargetIsEnemy;			//Caches the result of the TargetIsEnemy interface method
	var bool					bTargetIsAlly;			//Caches the result of the TargetIsAlly interface method	
	var bool					bTargetMoved;			//Filled out by UpdateGameplayVisibility, so will be false for vis queries that do not pass through that method
	var bool					bBeyondSightRadius;		//Cache is incomplete because the target is beyond the sight radius of the source

	//Debugging data
	//Cached debug information for the traces that produced this visibility info. There can be up to 25 traces per Visibility info:
	//5 source locations (default + 4 peeks) to 5 target locations (default + 4 peeks)
	var transient init array<VisibilityTraceDebugInfo> DebugTraceData;

	structcpptext
	{
	/** Constructors */
    FGameRulesCache_VisibilityInfo() : 
	SourceID(-1),
	TargetID(-1),
	CoverDirection(-1),
	TargetCoverAngle(-1.f),
	PeekSide(eNoPeek),
	PeekToTargetDist(FLT_MAX),
	DefaultTargetDist(FLT_MAX)
    {
		bVisibleGameplay = FALSE;
		bVisibleBasic = FALSE;
		bClearLOS = FALSE;
		bVisibleFromDefault = FALSE;
		bVisibleToDefault = FALSE;
		bConcealedTrace = FALSE;
		GameplayVisibleTags.Empty();
		DebugTraceData.Empty();
		bTargetIsEnemy = FALSE;
		bTargetIsAlly = FALSE;
		bTargetMoved = FALSE;
		bBeyondSightRadius = FALSE;
    }

    FGameRulesCache_VisibilityInfo(EEventParm)
    {
        appMemzero(this, sizeof(FGameRulesCache_VisibilityInfo));
    }
	
	FORCEINLINE UBOOL operator==(const FGameRulesCache_VisibilityInfo &Other) const
	{
		return  SourceID == Other.SourceID &&
			TargetID == Other.TargetID &&
			CoverDirection == Other.CoverDirection &&
			PeekSide == Other.PeekSide &&
			PeekToTargetDist == Other.PeekToTargetDist &&
			bVisibleGameplay == Other.bVisibleGameplay &&
			bVisibleBasic == Other.bVisibleBasic &&
			bClearLOS == Other.bClearLOS &&
			bVisibleFromDefault == Other.bVisibleFromDefault &&
			bVisibleToDefault == Other.bVisibleToDefault &&
			bConcealedTrace == Other.bConcealedTrace  &&
			bTargetIsEnemy == Other.bTargetIsEnemy &&
			bTargetIsAlly == Other.bTargetIsAlly &&
			TargetCover == Other.TargetCover &&
			bTargetMoved == Other.bTargetMoved;
	}

	FORCEINLINE UBOOL VisibilityFlagsEqual(const FGameRulesCache_VisibilityInfo &Other) const
	{
		return  bVisibleGameplay == Other.bVisibleGameplay &&
			bVisibleBasic == Other.bVisibleBasic &&
			bClearLOS == Other.bClearLOS &&
			bVisibleFromDefault == Other.bVisibleFromDefault &&
			bVisibleToDefault == Other.bVisibleToDefault &&
			bConcealedTrace == Other.bConcealedTrace &&
			bTargetMoved == Other.bTargetMoved;
	}

	//This is called immediately prior to calculating a visibility relationship between a given source and target state object. Data that is 
	//invariant through multiple calls (eg. source & target IDs) is left alone. The rest, initialized
	FORCEINLINE void InitializeForQuery()
	{
		CoverDirection = -1;
		PeekSide = eNoPeek;
		PeekToTargetDist = FLT_MAX;
		DefaultTargetDist = FLT_MAX;
		bVisibleGameplay = FALSE;
		bVisibleBasic = FALSE;
		bClearLOS = FALSE;
		bVisibleFromDefault = FALSE;
		bVisibleToDefault = FALSE;
		bConcealedTrace = FALSE;
		GameplayVisibleTags.Empty();
		DebugTraceData.Empty();		
		TargetCover = CT_Standing;
		TargetCoverAngle = -1.f;
		bTargetMoved = FALSE;
		bBeyondSightRadius = FALSE;
	}

	//Since units can be multi-tile, and this structure is the result of a point to point visibility check, we must be able to merge these structures
	//into a single result that the gameplay can use
	FORCEINLINE void Merge(const FGameRulesCache_VisibilityInfo &Other)
	{
		bClearLOS |= Other.bClearLOS;
		bVisibleFromDefault |= Other.bVisibleFromDefault;
		bVisibleToDefault |= Other.bVisibleToDefault;
		bTargetMoved |= Other.bTargetMoved;
		bBeyondSightRadius &= Other.bBeyondSightRadius;
				
		//Only merge in values that have clear LOS, OR if no prior values have had clear LOS
		if(Other.bClearLOS || !bClearLOS)
		{
			//Don't merge in these values unless the posture is equal or better to what we have already.
			if(Other.TargetCover <= TargetCover)
			{
				//It's better, this is the new optimal viewing data
				CoverDirection = Other.CoverDirection;
				TargetCoverAngle = Other.TargetCoverAngle;
				DefaultTargetDist = Other.DefaultTargetDist;
				PeekToTargetDist = Other.PeekToTargetDist;
				PeekSide = Other.PeekSide;
				SourceTile = Other.SourceTile;
				DestTile = Other.DestTile;
				bConcealedTrace = Other.bConcealedTrace;
				TargetCover = Other.TargetCover;
				DebugTraceData = Other.DebugTraceData;
			}
		}		
	}
	}
};

struct native VisibilityInfoFrame
{	
	var int HistoryFrameIndex;
	var bool bInterruptFrame;

	//Contains an element for each visibility relationship (n^2 with the number of viewers)
	var init array<GameRulesCache_VisibilityInfo> VisibilityCache;

	//This map facilitates lookup for how visibility changed in this info frame. 
	//Key: index of a VisibilityCache element that changed  Value: Previous visibility info
	var native Map_Mirror VisibilityDeltaMap {TMap<INT, FGameRulesCache_VisibilityInfo>};

	//This map provides a mechanism for mapping ObjectIDs to a list of indices in VisibilityCache that they affect. (ie. they are either the source or the target)	
	var native Map_Mirror ObjectIDToVisibilityCacheIndices {TMap<INT, TArray<INT> >};
};

enum FOWTileStatus
{
	eFOWTileStatus_Seen,
	eFOWTileStatus_HaveSeen,
	eFOWTileStatus_NeverSeen,
};

