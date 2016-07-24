//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGAIBehavior.uc    
//  AUTHOR:  Alex Cheng  --  2/17/2009
//  PURPOSE: Used for coding AI-specific behavior applied to an individual XGUnit actor.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XGAIBehavior extends Actor
	dependson(XComGameState_AIUnitData)
	native(AI)
	config(AI);

var const config float DEFAULT_AI_MIN_SPREAD_DISTANCE; // Default distance around other teammates where destination tiles get their weight shrunk.
var const config float DEFAULT_AI_SPREAD_WEIGHT_MULTIPLIER; // Multiplier on score of locations within min spread to scale down the weight.
var const config float DEFAULT_NO_MOVE_PENALTY_MULTIPLIER; // Multiplier on destination score of current tile location to devalue staying in the same place.
var config array<String> AoERepeatAttackExclusionList; // Ignore these types of abilities from the above list.

struct native AoETargetingInfo
{
	var Name Profile;					// Name of this AoE profile
	var Name Ability;					// Name of the AoE Ability.
	var bool bTargetEnemy;				// Include enemy units when gathering targets.  (does not include civilians)
	var bool bTargetCivilians;			// Include Neutral units when gathering targets.
	var bool bTargetAllies;				// Include ally units when gathering targets. ( does not include civilians )
	var bool bTargetCorpses;			// Include dead units (any team) when gathering targets
	var bool bTargetSelf;				// Include self when gathering targets.  ( i.e. for mind-controlled soldiers )
	var bool bRequiresOutdoor;			// Only select target locations that are outdoors
	var bool bUsePrecomputePath;		// Use grenade precompute path to test location
	var bool bFailOnFriendlyFire;		// Filter out destinations that damage allies or self
	var bool bIgnoreSelfDamage;			// Ignore self damage in above check.
	var bool bFailOnObjectiveFire;		// Do not select locations that have a destructible objective in the blast range.
	var bool bRequirePotentialTarget;	// Requires target from potential target stack to be in the target area.
	var bool bDoNotTargetGround;		// Require targeting unit positions, not ground positions.
	var bool bTestLocationValidity;		// Additional check to ensure locations are valid for consideration.
	var bool bPathToTarget;				// Unit paths to target destination for AoE effect.  Requires target locations within pathing range.
	var int  MinTargets;				// Minimum number of targets for a target location to be valid.

	structdefaultproperties
	{
		MinTargets=2
		bTargetEnemy=true
		bFailOnObjectiveFire=true
	}
};

var config array<AoETargetingInfo> AoEProfiles;
struct native AoETarget
{
	var vector Location;
	var Name Ability;
	var Name Profile;
};

//------------------------------------------------------------------------------------------------
// Pathing failure enums
enum EPathingFailure
{
	ePATHING_FAILURE_COMPUTE_PATH,
	ePATHING_FAILURE_BASE_VALIDATOR,
	ePATHING_FAILURE_UNREACHABLE,
};

//------------------------------------------------------------------------------------------------
// Persistent variables
// Persistent vars set up on LoadInit
var     			XGAIPlayer      m_kPlayer;
var     			XGUnit          m_kUnit;
//------------------------------------------------------------------------------------------------
// Variables updated per turn
var     name            m_kLastAIState;
var		bool			m_bAbortMove;
//------------------------------------------------------------------------------------------------
// Debugging variables
//------------------------------------------------------------------------------------------------
var	    vector              m_vDebugDestination;
var     LinearColor         m_kDebugColor;
var     Vector              m_vDebugDir[2];
var     Vector              m_vPathingOffset;
var     string              m_strDebugLog;
var     int                 m_iErrorCheck; // If == 0, break and display error message.
var     Vector              m_vFailureBegin; // Path failure start location.
var     array<int>          m_iFailureDest_CP; // Path failures this turn due to ComputePath returning false.
var     array<int>          m_iFailureDest_BV; // Path failures this turn due to BaseValidator returning false.
var     array<int>          m_iFailureDest_UR; // Path failures this turn due to IsDestReachable returning false.
var     int                 m_iLastFailureAdded;
//******************************************************************************************

var     AoETarget           TopAoETarget;

var     bool                m_bBadAreaChecksIgnoreAoE;

var     bool                m_bHasSquadSightAbility;

var     int                 m_iDebugHangLocation;

var     bool                m_bCanDash;
var     vector              m_vSortLoc;
var     XGUnit              m_kClosestCivilian;

var     int                 m_iTurnsUnseen;
var     bool                m_bShouldEngage;

var		XGAIPatrolGroup		m_kPatrolGroup;

//=======================================================================================
//X-Com 2 Refactoring
//
//@TODO - acheng - X-Com 2 conversion
var XComGameState_Unit      UnitState;
var GameRulesCache_Unit     UnitAbilityInfo;
var int                     DecisionStartHistoryIndex;

//Settings for UpdateTacticalDestinations
var private bool                    bLogTacticalDestinationIteration;
var private int                     UpdateTacticalDestinationsStepSize;

var private array<XComCoverPoint>   PointsToProcess;
var private bool					m_bNeedsTacticalDestinations;

//=======================================================================================
var AvailableAction			SelectedAbility;

var name	m_strBTAbilitySelection;
var X2AIBTBehavior m_kBehaviorTree;
var array<AvailableTarget> m_arrBTTargetStack; // Array of target ids for a particular ability.
var name m_strBTCurrAbility;
var int iBTSRunningTest;
var int m_iAlertDataIter;
var int m_iAlertDataScoreCurrent;
var int m_iAlertDataScoreHighestIndex;
var int m_iAlertDataScoreHighest;
var bool m_bAlertDataMovementUseCover;
var vector m_vAlertDataMovementDestination;
var bool m_bAlertDataMovementDestinationSet;
var array<int> AlertDataMarkedForDelete; // array of alert data indices marked for deletion.
var StateObjectReference PriorityTarget; // Used to indicate target for special circumstances. For example Chryssalid BurrowedAttack

struct native ability_target
{
	var name AbilityName;
	var int TargetID;
	var int iScore;
	var AvailableTarget kTarget;
};

var array<ability_target> m_arrBTBestTargetOption;
var ability_target m_kBTCurrTarget;
var AvailableAction m_kBTCurrAbility;
var bt_status m_eBTStatus;
var float m_fBTAbortTime;

var bool bScoringPriorityTarget; // Cached priority destination-scoring variables - has priority target.
var vector ScoringPriorityLocation; // Cached priority destination


var vector m_vBTDestination;
var bool m_bBTDestinationSet;
var bool bBTTargetSet;
var bool bSetDestinationWithAbility;
//var X2WeaponTemplate m_kBTPrimaryWeaponTemplate;
var X2WeaponTemplate m_kBTCurrWeaponTemplate;

var float m_fSightRangeSq;
var bool m_bUnitAbilityCacheDirty;
var int m_iUnitAbilityCacheHistoryIndex;

// Behavior-Tree-generated variables that are reset each time the behavior tree initializes.
struct native BehaviorTreeLocalVar
{
	var string VarName;
	var int Value;
};
var array<BehaviorTreeLocalVar> BTVars;

var bool bForcePathIfUnreachable;

// For X2 we have a new destination scoring system.
struct native ai_tile_score 
{
	var TTile kTile;
	var XComCoverPoint kCover; // Cover point, if any.
	var float fCoverValue; // -1 = no cover, or flanked. 0.5 = half cover, 1.0 = full cover.
	var float fDistanceScore; // Distance in tiles (direct length / 96) from enemy.
	var float fPriorityDistScore; // improve in distance in tiles from priority
	var float fFlankScore; // 0 if not flanking, 1 if flanking an enemy.
	var float fEnemyVisibility; // increments to 1 as more enemies are visible, -1 if no enemy is visible.
									// Incremental value = 1/MAX_EXPECTED_ENEMY_COUNT (default=1/4).  
									// Score can exceed 1.0 if more enemies visible than this MAX_EXPECTED_ENEMY_COUNT number)
	var float fEnemyVisibilityPeak1; // Max score at 1 when one enemy visible, decrements toward zero as more enemies are visible. 
									// -1 if no enemy is visible.  Min value with visible enemies = MIN_ENEMY_VIS_PEAK1_VALUE
	var float fAllyVisibility;   // 1 if over 'VIS_ALLY_PLATEAU_VALUE' allies are visible, 0 if no ally is visible.  Increases towards 1 as more allies are visible.
	var bool  bCloserThanIdeal; // true if distance to nearest enemy is less than IdealRange value.
	var bool  bWithinSpreadMin; // True if distance from nearest teammate is less than MinSpread value.
	var float SpreadMultiplier; // Value to multiply weighted score by to lower the score based on distance from nearest enemy.
	var float fAllyAbilityRangeScore; // Linearly increments to 1 if all allies are within the specified ability's range.
};

struct native AITileWeightProfile
{
	var Name Profile;
	var float fCoverWeight;
	var float fDistanceWeight;
	var float fFlankingWeight;
	var float fEnemyVisWeight;		// weight on Enemy Vis score that increases with the number of visible enemies. 
	var float fEnemyVisWeightPeak1; // Weight on Enemy Vis score that Maxes out at 1 visible enemy.
	var float fAllyVisWeight;
	var float fRandWeight; // For more random movement, i.e. civilian green alert movement.
	var float fCloseModifier;  // Locations closer than ideal range are multiplied by this value.
	var float fFarModifier;    // Locations further than ideal range are multiplied by this value.
	var float fPriorityDistWeight;
	var float MinimumTileDist;
	var bool  bPrioritizeClosest; // Uses closest enemy as priority target, instead of priority target specified by kismet.
	var bool  bIsMelee;

	structdefaultproperties
	{
		fCloseModifier=1.0f
		fFarModifier=1.0f
	}
};

// DEBUG struct, for drawing destination scores.
struct native DebugTileScore
{
	var ai_tile_score RawScore, DeltaScore;
	var bool bFailEnemyLoS, bFailAllyLoS, bFailDistance, bFailFlanking, bInBadArea, bNotReachable, bInMinSpread;
	var float RandVal;
	var float WeightedScore, FinalScore;
	var vector Location;
	var float DistToEnemy;
};
var array<DebugTileScore> DebugTileScores; // Array of scoring values for debug display.
var TTile DebugCursorTile;					// Current cursor tile location for detailed view.
var bool  bDisplayScoreDetail;				// flag to check if currently using detailed view.
var bool  m_bBTCanDash;
var bool  bBTCiviliansAsEnemiesInMove;     // Terrorist movement - only consider civilians as enemies in movement decisions.
var bool  bBTNoCoverMovement;					// Also for unrevealed terrorist movement - do not move into cover.
var bool  bIgnoreHazards;					// true for mind-controlled units?
// End destination debugging vars
// debug structure for behavior tree traversals.

struct native bt_traversal_data
{
	var int iHistoryIndex;
	var int BehaviorTreeRootIndex;
	var array<BTDetailedInfo> TraversalData;

	structdefaultproperties
	{
		BehaviorTreeRootIndex = INDEX_NONE
	}
};

var()	array<bt_traversal_data>   m_arrTraversals;
var()	string DebugBTScratchText; // Used for composited summary text in BT Node debugging.

struct native AIAvoidanceArea
{
	var vector Point;
	var float  RadiusUnitsSq;
};
struct native AIMoveRestriction
{
	var vector vAnchor;
	var bool bNoLoSToEnemy; // Destination requires NO visibility from any enemy.
	var bool bLoSToEnemy; // Destination requires visibility to at least one enemy.
	var bool bLoSToAlly;  // Destination requires visibliity to at least one ally.
	var float MaxDistance; // Distance in meters
	var bool bFlanking;   // Destination requires at least one enemy is flanked by this unit.
	var float fMaxDistSq;
	var int MinTargetCount; // Used for ally targets only.  Ignores vAnchor.  Uses MaxDistance to check distance from N allies.
	var bool bLoSToAxis;
	var bool bGroundOnly; // Restricted to ground tiles only.  (for burrowing specifically)
	var int TargetedObjectID; // Restricted to only attack this unit.  (for melee specifically)
	var array<AIAvoidanceArea> AvoidanceList;

	structdefaultproperties
	{
		MaxDistance=-1;
	}
};

var ai_tile_score m_kCurrTileData;
var array<ai_tile_score> m_arrBestTileOption; 
var array<float> m_arrBestTileScore;
var config array<AITileWeightProfile> m_arrMoveWeightProfile;
var private array<ai_tile_score> m_arrTilesToProcess;
var AIMoveRestriction m_kCurrMoveRestriction;
var bool m_bUseMoveRestriction;
var private bool                    bBTUpdatingTacticalDestinations;
var private bool					bBTHasStartedDestinationsProcess;
var private config float DefaultIdealRange;
var private const float DefaultMeleeIdealRange;
var private const float MAX_EXPECTED_ENEMY_COUNT;
var private const float MIN_ENEMY_VIS_PEAK1_VALUE;
var private const float VIS_ALLY_PLATEAU_VALUE;
var private const config float CURR_TILE_LINGER_PENALTY; // Used in distance score only on current tile, decreases value of staying in same location.
var private const config float CALC_RANGE_NUMERATOR; // Used in DistanceScore, CurrentTileScore value = CALC_RANGE_NUMERATOR / (| DTE - IR |*C + CALC_RANGE_DENOM_ADDEND).
var private const config float CALC_RANGE_DENOM_ADDEND; // CurrentTileScore value = CALC_RANGE_NUMERATOR / (| DTE - IR |*CALC_RANGE_DENOM_FACTOR + CALC_RANGE_DENOM_ADDEND).
var private const config float CALC_RANGE_DENOM_FACTOR; // Used in DistanceScore, CurrentTileScore value = CALC_RANGE_NUMERATOR / (| DTE - IR |*CALC_RANGE_DENOM_FACTOR + CALC_RANGE_DENOM_ADDEND).
var private const config bool  bCALC_RANGE_LINEAR;      // If true, use linear distance scoring instead of inverse.  Score=  (1 - |DTE-IR|/CALC_RANGE_LINEAR_DENOM).
var private const config float CALC_RANGE_LINEAR_DENOM;  // Used in linear distance scoring equation : Score=  (1 - |DTE-IR|/CALC_RANGE_LINEAR_DENOM).
var private const config float CALC_FULL_COVER_FACTOR_POD_LEADER; // Score value attributed to a location in full cover, for pod leaders.
var private const config float CALC_FULL_COVER_FACTOR; // Score value attributed to a location in full cover
var private const config float CALC_MID_COVER_FACTOR;  // Score value attributed to a location in mid cover
var private const config float CALC_NO_COVER_FACTOR;   // Score value attributed to a location in no cover
var float FullCoverFactor;
var private const float MaxDistScoreNoKnownEnemies; // Max distance score (meters value) for closest enemy distance when no enemies are known.

var array<vector> m_arrTargetLocations;
var int CurrMoveType;

var protected float SpreadMinDistanceSq; // Minimum distance in units within which to apply below multiplier.
var private float SpreadMultiplier; // Multiplier to apply to positive weights for locations within minimum spread range of other units.
var private array<float> SpreadTileDistances; // cached distance squared values per tiles away.
var private array<float> SpreadMultiplierPerDistance; // Cached multipliers used per distance away.

var private bool bUseSurprisedScamperMove;  // Flag to abbreviate path length on scamper movement.

// Surprised scamper variables.  Uses MAX_SURPRISED_SCAMPER_PATH_LENGTH when the original path to cover length is greater than this value.
//              Otherwise for paths greater than the MIN, picks a random number of tiles to use between the min and the path length.
var private const config int MIN_SURPRISED_SCAMPER_PATH_LENGTH; // Minimum tiles to use for surprised scamper moves.
var private const config int MAX_SURPRISED_SCAMPER_PATH_LENGTH; // Maximum tiles in path to use for surprised scamper moves.
var private int AIUnitDataID;

var private int PrimedAoEAbility; // Last ObjectID of ability that passed a call to SetAoEAbility.  
								  // If this ability is selected, update the player data with the target location, 
								  //  to prevent multiple AoE attacks on the same location in one turn.

var private StateObjectReference CurrentBTStackRef;
var array<StateObjectReference> ActiveBTStack;
var bool bIncludeAlliesAsMeleeTargets;

var array<XComGameState_Unit> CachedActiveAllies;
var array<StateObjectReference>  CachedKnownUnitRefs;
var array<StateObjectReference>  IgnoredEnemiesForDefenseChecks; // for Ruler system, to ignore enemies that have no action points left.
var int ActiveRevealedAllyCount;
var float WeightedAllyRangeSq;
var float AllyAbilityRangeWeight;
var int BTPriorityTarget; // Priority Target specified by Behavior Tree for use in movement profile scoring.
var int BTTargetIndex;    // from deprecated XGAIAbilityDM class
var private native Map_Mirror       CachedEnemyCover{TMap<INT, FXComCoverPoint>};        //  maps unit id to a group id.

var bool BTSkipTurnOnFailure;
struct native CachedAbilityNameList
{
	var int HistoryIndex;
	var array<Name> NameList;
	structdefaultproperties
	{
		HistoryIndex = INDEX_NONE
	}
};

var CachedAbilityNameList CachedAbilityNames;	// Cached names of all abilities available to this unit for the current BT run.
var bool WaitForExecuteAbility;					// Flag to indicate we are waiting on a pending ability to be submitted.

var array<TTile> AbilityPathTiles;	// Added for abilities that require a path.

function int GetAIUnitDataID(int UnitID)
{
	local XComGameStateHistory History;
	local XComGameState_AIUnitData DataState;
	if( AIUnitDataID != INDEX_NONE )
	{
		return AIUnitDataID;
	}
	if( m_kPlayer != None )
	{
		AIUnitDataID = m_kPlayer.GetAIUnitDataID(UnitID);
	}
	// Search through history and cache the object ID if it exists.
	if( AIUnitDataID == INDEX_NONE )
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_AIUnitData', DataState)
		{
			if( DataState.m_iUnitObjectID == m_kUnit.ObjectID )
			{
				AIUnitDataID = DataState.ObjectID;
				break;
			}
		}
	}
	return AIUnitDataID;
}
function ai_tile_score InitMoveTileData(TTile kTileIn, XComCoverPoint kCoverIn)
{
	local ai_tile_score kTileScore;
	kTileScore.kTile = kTileIn;
	kTileScore.kCover = kCoverIn;
	return kTileScore;
};

native function bool HasAlliesInRange(float MaxDistSq, int MinCount, const out vector vPosition);

function AddAvoidanceArea(TTile TileLoc, float UnitRadius)
{
	local AIAvoidanceArea AvoidArea;
	AvoidArea.Point = `XWORLD.GetPositionFromTileCoordinates(TileLoc);
	AvoidArea.RadiusUnitsSq = Square(UnitRadius);
	m_kCurrMoveRestriction.AvoidanceList.AddItem(AvoidArea);
}

function BT_RestrictFromAlliesWithEffect(Name EffectName, float MaxDistanceMeters)
{
	local XComGameState_Unit AllyUnit;
	local array<XComGameState_Unit> TeamUnits;

	m_kPlayer.GetPlayableUnits(TeamUnits, true);
	foreach TeamUnits(AllyUnit)
	{
		if( AllyUnit.ObjectID == UnitState.ObjectID )
		{
			continue;
		}
		if( AllyUnit.IsUnitAffectedByEffectName(EffectName) )
		{
			AddAvoidanceArea(AllyUnit.TileLocation, `METERSTOUNITS(MaxDistanceMeters));
		}
	}
}

function bool PassesRestriction( vector vPosition )
{
	local float fDistSq;
	local TTile TilePosition, PriorityTile;
	local vector AxisLocation;
	local GameRulesCache_VisibilityInfo VisInfo;
	local XComWorldData XWorld;
	local AIAvoidanceArea AvoidArea;
	XWorld = `XWORLD;
	if( m_kCurrMoveRestriction.MaxDistance > 0 )
	{
		// MinTargetCount is used without an anchor location.
		if( m_kCurrMoveRestriction.MinTargetCount > 0 )
		{
			if( VSizeSq(m_kCurrMoveRestriction.vAnchor) > 0 )
			{
				`RedScreenOnce("Error- MoveProfile has a Min Target Count specified in addition to a nonzero anchor location!   @acheng #BehaviorTreeProblems");
				return false;
			}
			// Check distance from allies.
			if( !HasAlliesInRange(m_kCurrMoveRestriction.fMaxDistSq, m_kCurrMoveRestriction.MinTargetCount, vPosition) )
			{
				return false;
			}
		}
		else
		{
			fDistSq = VSizeSq(vPosition - m_kCurrMoveRestriction.vAnchor);
			if( fDistSq > m_kCurrMoveRestriction.fMaxDistSq )
			{
				return false;
			}
			// If a visible mimic beacon exists, all destinations must have LoS to it.
			if( BTPriorityTarget > 0 && bScoringPriorityTarget )
			{
				TilePosition = XWorld.GetTileCoordinatesFromPosition(vPosition);
				PriorityTile = XWorld.GetTileCoordinatesFromPosition(ScoringPriorityLocation);
				if (!`XWORLD.CanSeeTileToTile(TilePosition, PriorityTile, VisInfo))
				{
					return false;
				}
			}
		}
	}

	TilePosition = XWorld.GetTileCoordinatesFromPosition(vPosition);

	if( m_kCurrMoveRestriction.bLoSToAxis && m_kPlayer != None && m_kPlayer.m_kNav != None )
	{
		AxisLocation = m_kPlayer.m_kNav.GetNearestPointOnAxisOfPlay(vPosition, true);
		PriorityTile = XWorld.GetTileCoordinatesFromPosition(AxisLocation);
		if( !`XWORLD.CanSeeTileToTile(TilePosition, PriorityTile, VisInfo) )
		{
			return false;
		}
	}

	if( m_kCurrMoveRestriction.bGroundOnly )
	{
		if( !XWorld.IsGroundTile(TilePosition) )
		{
			return false;
		}
	}

	if( m_kCurrMoveRestriction.AvoidanceList.Length > 0 )
	{
		foreach m_kCurrMoveRestriction.AvoidanceList(AvoidArea)
		{
			if( VSizeSq(vPosition - AvoidArea.Point) <= AvoidArea.RadiusUnitsSq )
			{
				return false;
			}
		}

	}
	return true;
}

function bool IsWithinMovementRange( TTile kTile, bool bCanDash=false, int MinimumTileDist=0.0f, bool bDebugLog=false )
{
	local float PathCost, DistSq, MinDistSq;
	local vector TileLoc;
	if( bDebugLog )
	{
		`LogAI("Mobility Value = "$m_kUnit.GetMobility()@"CostToTile="$m_kUnit.m_kReachableTilesCache.GetPathCostToTile(kTile));
	}
	if( MinimumTileDist > 0 )
	{
		MinDistSq = `TILESTOUNITS(MinimumTileDist);
		MinDistSq = Square(MinDistSq);
		TileLoc = `XWORLD.GetPositionFromTileCoordinates(kTile);
		DistSq = VSizeSq(GetGameStateLocation() - TileLoc);
		if( DistSq < MinDistSq )
		{
			return false;
		}
	}

	// If already in this tile, return true.
	if( kTile == UnitState.TileLocation )
	{
		return true;
	}
	// Check move is valid.
	PathCost = m_kUnit.m_kReachableTilesCache.GetPathCostToTile(kTile);
	if( PathCost < 0 )
	{
		return false;
	}
	if( !bCanDash )
	{
		return PathCost <= float(m_kUnit.GetMobility());
	}
	return true; // Otherwise dash move is valid if PathCost is not -1.
}

function bool HasXComUnitsCloserToObjective(float FuzzDistMeters)
{
	local float UnitDistFromObjective, XComDistSq, TestDistSq;
	local vector MyLoc, ObjectiveLoc, XComLoc;
	local array<XComGameState_Unit> XComList;
	local XComGameState_Unit XComUnit;
	local XComWorldData XWorld;
	if( m_kPlayer != None )
	{
		ObjectiveLoc = m_kPlayer.m_kNav.m_kAxisOfPlay.v2;
		MyLoc = GetGameStateLocation();
		UnitDistFromObjective = VSize2D(ObjectiveLoc - MyLoc);
		// Setting bar at this unit's distance to the objective, minus fuzz distance.
		TestDistSq = UnitDistFromObjective - `METERSTOUNITS(FuzzDistMeters); 
		// Check for possibility this could be negative.
		if( TestDistSq <= 0 )
		{
			`LogAIBT("Failed - Unit is already within FuzzDist ("$FuzzDistMeters$" meters) of the objective!");
			return false; // In practice this should not get hit, as long as the other BT check for distance from objective happens first (IsAtEndOfAxisOfPlay).
		}
		TestDistSq = Square(TestDistSq);

		XWorld = `XWORLD;
		// Test all xcom units to see if any unit is within this range of the objective.
		GetAllKnownEnemyStates(XComList);
		foreach XComList(XComUnit)
		{
			XComLoc = XWorld.GetPositionFromTileCoordinates(XComUnit.TileLocation);
			XComDistSq = VSizeSq2D(XComLoc - ObjectiveLoc);
			if( XComDistSq < TestDistSq )
			{
				return true;
			}
		}
	}
	return false;
}

function bool IsMeleeMove()
{
	return m_arrMoveWeightProfile[CurrMoveType].bIsMelee;
}

function CacheScoringPriorityValues()
{
	local TTile TargetTile;
	local XComGameState_AIPlayerData AIPlayerData;
	local XComGameState_Unit PriorityUnit;
	if( BTPriorityTarget > 0 )
	{
		PriorityUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BTPriorityTarget));
		if( PriorityUnit != None )
		{
			bScoringPriorityTarget = true;
			ScoringPriorityLocation = `XWORLD.GetPositionFromTileCoordinates(PriorityUnit.TileLocation);
		}
		else
		{
			`LogAIBT("Error - Priority target #"$BTPriorityTarget@"is not a valid unit.\n");
		}
	}
	else if( m_arrMoveWeightProfile[CurrMoveType].bPrioritizeClosest )
	{
		PriorityUnit = GetNearestKnownEnemy(m_kUnit.GetGameStateLocation(),,, bBTCiviliansAsEnemiesInMove);
		if( PriorityUnit != None )
		{
			bScoringPriorityTarget = true;
			ScoringPriorityLocation = `XWORLD.GetPositionFromTileCoordinates(PriorityUnit.TileLocation);
		}
	}
	else if( m_kPlayer != None )
	{
		AIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(m_kPlayer.GetAIDataID()));
		bScoringPriorityTarget = AIPlayerData.HasPriorityTargetLocation(TargetTile);
		if( bScoringPriorityTarget )
		{
			ScoringPriorityLocation = `XWORLD.GetPositionFromTileCoordinates(TargetTile);
		}
		else
		{
			if( m_arrMoveWeightProfile[CurrMoveType].fPriorityDistWeight != 0.0f )
			{
				`LogAI("Move Profile uses PriorityTargetLocation, but no Priority Target was found.");
			}
		}
	}
	else
	{
		bScoringPriorityTarget = false;
	}
}

function bool ShouldAvoidTilesWithCover()
{
	if( bBTNoCoverMovement || !CanUseCover() )
	{
		return true;
	}
	return false;
}

//In this method we begin the time consuming process of building a list of valid destinations for the AI. When the method has completed PointsToProcess
//should be filled with potential destinations that we will remove iteratively in StepGetDestinations
simulated function BT_StartGetDestinations(bool bFiltered=false, bool bSkipBuildDestList=false, bool bLogging=false)
{
	local XComWorldData WorldData;
	local Vector Position;
	local TTile kTile;
	local XComCoverPoint CoverPoint, EmptyCover;
	local ai_tile_score kTileScore;
	local array<Vector> MeleePoints;
	local array<TTile> AllTiles;
	local DebugTileScore DebugScore;

	`LogAI("Calling BT_StartGetDestinations");
	WorldData = `XWORLD;

	//Get list of points to consider
	PointsToProcess.Length = 0;

	if( m_kBTCurrWeaponTemplate == None && UnitState.GetPrimaryWeapon() != None )
	{
		`LogAI("BT StartGetDestinations: Current Weapon Template unset, using unit's primary weapon for optimal distance determination.");
		m_kBTCurrWeaponTemplate = X2WeaponTemplate(UnitState.GetPrimaryWeapon().GetMyTemplate());
	}

	CacheScoringPriorityValues();
	UpdateCurrTileData(DebugScore.DistToEnemy);
	DebugTileScores.Length = 0;
	DebugScore.RawScore = m_kCurrTileData;
	DebugScore.Location = m_kUnit.GetGameStateLocation();
	DebugTileScores.AddItem(DebugScore);

	m_kUnit.m_kReachableTilesCache.UpdateTileCacheIfNeeded();
	if( !ShouldAvoidTilesWithCover() && !UnitState.IsCivilian() && !IsMeleeMove() )
	{
		foreach m_kUnit.m_kReachableTilesCache.CoverDestinations(Position)
		{
			kTile = WorldData.GetTileCoordinatesFromPosition(Position);
			if( `CHEATMGR != None && `CHEATMGR.DebugInspectTileDest(kTile) )
			{
				`Log("Inspecting tile ("$kTile.X@kTile.Y@kTile.Z$")...");
			}
			if( !PassesTileCheck(kTile) )
			{
				continue;
			}
			if (m_bUseMoveRestriction && !PassesRestriction(Position))
			{
				continue;
			}
			WorldData.GetCoverPointAtFloor(Position, CoverPoint);
			kTileScore = InitMoveTileData(kTile, CoverPoint);
			m_arrTilesToProcess.AddItem(kTileScore);
		}
	}
	else if( IsMeleeMove() )
	{
		GetPathableMeleePoints(MeleePoints);
		foreach MeleePoints(Position)
		{
			if( m_bUseMoveRestriction && !PassesRestriction(Position) )
			{
				continue;
			}
			kTile = WorldData.GetTileCoordinatesFromPosition(Position);
			if( `CHEATMGR != None && `CHEATMGR.DebugInspectTileDest(kTile) )
			{
				`Log("Inspecting tile ("$kTile.X@kTile.Y@kTile.Z$")...");
			}
			if( PassesTileCheck(kTile) )
			{
				kTileScore = InitMoveTileData(kTile, EmptyCover);
				m_arrTilesToProcess.AddItem(kTileScore);
			}
		}
	}
	else
	{
		m_kUnit.m_kReachableTilesCache.GetAllPathableTiles(AllTiles, m_kUnit.GetMobility());
		foreach AllTiles(kTile)
		{
			if( `CHEATMGR != None && `CHEATMGR.DebugInspectTileDest(kTile) )
			{
				`Log("Inspecting tile ("$kTile.X@kTile.Y@kTile.Z$")...");
			}
			Position = WorldData.GetPositionFromTileCoordinates(kTile);
			if( m_bUseMoveRestriction && !PassesRestriction(Position) )
			{
				continue;
			}
			if( PassesTileCheck(kTile) )
			{
				CoverPoint = EmptyCover;
				if( WorldData.GetCoverPointAtFloor(Position, CoverPoint) )
				{
					if( ShouldAvoidTilesWithCover() )
						continue;
				}
				kTileScore = InitMoveTileData(kTile, CoverPoint);
				m_arrTilesToProcess.AddItem(kTileScore);
			}
		}
	}

	m_arrBestTileScore.Length = 0;
	m_arrBestTileOption.Length = 0;
	m_arrBestTileScore.Length = m_arrMoveWeightProfile.Length;
	m_arrBestTileOption.Length = m_arrMoveWeightProfile.Length;

	if( m_arrTilesToProcess.Length > 0 )
	{
		bBTUpdatingTacticalDestinations = true;
		DebugBTScratchText = "Processed"@m_arrTilesToProcess.Length@"tiles.\n";
		SetTimer(0.001f, false, nameof(BT_StepProcessDestinations));
	}
	else
	{
		m_kUnit.m_kReachableTilesCache.GetAllPathableTiles(AllTiles, m_kUnit.GetMobility());
		Position = m_kUnit.GetGameStateLocation();
		`LogAIBT("Possible error - no tiles to process found!  ReachableTileCache:CoverDestinations count="
			$ m_kUnit.m_kReachableTilesCache.CoverDestinations.Length$", All pathable tiles count="
			$ AllTiles.Length$", Mobility="$m_kUnit.GetMobility()@ "ActionPoints="$UnitState.ActionPoints.Length);
		if( WorldData.GetFloorPositionForTile(UnitState.TileLocation, Position) )
		{
			`LogAI("Floor position= ("$Position.X@Position.Y@Position.Z$")");
		}
		else
		{
			`LogAI("Floor position NOT FOUND!");
			`RedScreenOnce("Unit "$UnitState.ObjectID$": Floor position could not be found at tile("$UnitState.TileLocation.X@UnitState.TileLocation.Y@UnitState.TileLocation.Z$"), resulting in a pathing failure. (X2Pathing.cpp GetNeighborNodesCallback)  @Systems");
		}
	}
}

function bool PassesTileCheck(TTile Tile)
{
	local float MinimumTileDist;
	MinimumTileDist = m_arrMoveWeightProfile[CurrMoveType].MinimumTileDist;
	if( !IsWithinMovementRange(Tile, m_bCanDash, MinimumTileDist) )
	{
		return false;
	}
	if( !bIgnoreHazards 
	   && (class'XComPath'.static.TileContainsHazard(UnitState, Tile) 
		   || ( m_kPlayer != None && m_kPlayer.IsInTwoTurnAttackTiles(Tile))))
	{
		return false;
	}

	return true;
}

function BT_IgnoreHazards( bool bIgnore=true )
{
	bIgnoreHazards = bIgnore;
}

function BT_IncludeAlliesAsMeleeTargets()
{
	bIncludeAlliesAsMeleeTargets = true;
}

native function GetPathableMeleePointsHelper(out array<Vector> arrMeleePoints, array<StateObjectReference> EnemyList);

function GetPathableMeleePoints( out array<Vector> arrMeleePoints)
{
	local XComGameStateHistory History;
	local XComGameState_AIUnitData kUnitData;
	local int iDataID;
	local array<StateObjectReference> UnitList, VisibleAllies;
	local StateObjectReference UnitRef;

	History = `XCOMHISTORY;
	// If restricted to one target, only get melee points around that one target.
	if( m_kCurrMoveRestriction.TargetedObjectID > 0 )
	{
		UnitRef.ObjectID = m_kCurrMoveRestriction.TargetedObjectID;
		UnitList.AddItem(UnitRef);
	}
	else
	{
		iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
		if( iDataID > 0 )
		{
			kUnitData = XComGameState_AIUnitData(History.GetGameStateForObjectID(iDataID));
			kUnitData.GetAbsoluteKnowledgeUnitList(UnitList, , , true);
		}
		if( bIncludeAlliesAsMeleeTargets )
		{
			class'X2TacticalVisibilityHelpers'.static.GetAllVisibleUnitsOnTeamForSource(UnitState.ObjectID, UnitState.GetTeam(), VisibleAllies);
			foreach VisibleAllies(UnitRef)
			{
				if( UnitRef.ObjectID == m_kUnit.ObjectID )
				{
					continue;
				}
				UnitList.AddItem(UnitRef);
			}
		}
	}
	if( UnitList.Length > 0 )
	{
		GetPathableMeleePointsHelper(arrMeleePoints, UnitList);
	}
}

event int GetMeleeTileRange()
{
	local X2AbilityTemplate MeleeTemplate;
	local XComGameState_Ability MeleeAbility;
	local X2AbilityMultiTarget_Radius TargetStyle;
	local float Radius;
	// Search for a melee attack.  If it has one, use the range value on it.
	if( HasMeleeAttack(MeleeAbility, MeleeTemplate) )
	{
		TargetStyle = X2AbilityMultiTarget_Radius(MeleeTemplate.AbilityMultiTargetStyle);
		if( TargetStyle != None )
		{
			Radius = `UNITSTOTILES(TargetStyle.GetTargetRadius(MeleeAbility));
			return Radius;
		}
	}
	return 1; // Default melee range is one tile away.
}

function bool HasMeleeAttack(optional out XComGameState_Ability MeleeAbility_out, optional out X2AbilityTemplate MeleeTemplate_out)
{
	local AvailableAction Ability;
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;

	History = `XCOMHISTORY;
	foreach UnitAbilityInfo.AvailableActions(Ability)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Ability.AbilityObjectRef.ObjectID));
		MeleeTemplate_out = AbilityState.GetMyTemplate();
		if( MeleeTemplate_out.IsMelee() )
		{
			MeleeAbility_out = AbilityState;
			return true;
		}
	}
	return false;
}

// Get adjacent floor tiles around specified tile.
native function GetMeleePointsAroundTile(TTile Tile, out array<TTile> MeleeTiles_out, bool bAllowDiagonals = true);

simulated function BT_StepProcessDestinations()
{
	local ai_tile_score kTileData, kScoreData;
	local float arrScore, fDistToEnemy;
	local Vector vLoc;
	local bool bValid;
	local int IterationIndex, DebugIndex;
	local XComWorldData WorldData;
	local DebugTileScore DebugScore, BlankDebugScore;
	//local XGUnit kEnemy;
	WorldData = `XWORLD;
	`assert(bBTUpdatingTacticalDestinations);

	for(IterationIndex = 0; IterationIndex < UpdateTacticalDestinationsStepSize; ++IterationIndex )
	{
		if( m_arrTilesToProcess.Length > 0 )
		{
			kTileData = m_arrTilesToProcess[m_arrTilesToProcess.Length - 1];
			m_arrTilesToProcess.Remove(m_arrTilesToProcess.Length - 1, 1);

			if (`CHEATMGR != None && `CHEATMGR.DebugInspectTileDest(kTileData.kTile))
			{
				`Log("Inspecting tile ("$kTileData.kTile.X@kTileData.kTile.Y@kTileData.kTile.Z$")...");
			}
			if (`IS_VALID_COVER( kTileData.kCover ))
			{
				vLoc = kTileData.kCover.ShieldLocation;
			}
			else
			{
				vLoc = WorldData.GetPositionFromTileCoordinates(kTileData.kTile);
			}
			bValid = true;
			//Check for bad areas
			if (IsInBadArea(vLoc, bLogTacticalDestinationIteration))
			{
				bValid = false;
				// Debug data tracking
				DebugIndex = DebugTileScores.Length;
				DebugTileScores.Add(1);
				DebugTileScores[DebugIndex].RawScore = kTileData;
				DebugTileScores[DebugIndex].bInBadArea = true;
				DebugTileScores[DebugIndex].Location = vLoc;
			}

			//See if this tile is reachable
			if ( bValid && !m_kUnit.m_kReachableTilesCache.IsTileReachable(kTileData.kTile) )
			{
				if (bLogTacticalDestinationIteration)
				{
					`Log("Location ("$vLoc$") failed in StepProcessDestinations call to IsTileReachable(...).");
				}

				// Debug data tracking
				DebugIndex = DebugTileScores.Length;
				DebugTileScores.Add(1);
				DebugTileScores[DebugIndex].RawScore = kTileData;
				DebugTileScores[DebugIndex].bNotReachable = true;
				DebugTileScores[DebugIndex].Location = vLoc;

				bValid = false;
			}

			if ( bValid )
			{
				kScoreData = ScoreDestinationTile(kTileData.kTile, vLoc, kTileData.kCover, kTileData, fDistToEnemy);
				// Debug data tracking
				DebugScore = BlankDebugScore;
				DebugScore.RawScore = kTileData;
				DebugScore.DeltaScore = kScoreData;
				DebugScore.Location = vLoc;
				DebugScore.DistToEnemy = fDistToEnemy;

				arrScore = GetWeightedTileScore(kScoreData, kTileData, CurrMoveType, DebugScore);
				if( arrScore > m_arrBestTileScore[CurrMoveType] )
				{
					m_arrBestTileScore[CurrMoveType] = arrScore;
					m_arrBestTileOption[CurrMoveType] = kScoreData;
				}
				// Debug data tracking
				DebugTileScores.AddItem(DebugScore);
			}
		}
		else
		{
			`LogAIBT("Processed Destinations-"$m_arrMoveWeightProfile[CurrMoveType].Profile$"\n"$DebugBTScratchText);
			bBTUpdatingTacticalDestinations = false;
			break;
		}
	}

	if( bBTUpdatingTacticalDestinations )
	{
		//Still going, register for another pass
		SetTimer(0.001f, false, nameof(BT_StepProcessDestinations));
	}
}

function UpdateCurrTileData(optional out float fDistFromEnemy)
{
	local XComCoverPoint kCover;
	local vector vLoc;
	local string strFailText;

	vLoc = m_kUnit.GetGameStateLocation();
	`XWORLD.GetCoverPointAtFloor(vLoc, kCover);
	m_kCurrTileData = FillTileScoreData( UnitState.TileLocation, vLoc, kCover,,fDistFromEnemy );
	m_kCurrTileData.fDistanceScore *= CURR_TILE_LINGER_PENALTY;

	strFailText = "Unit"@UnitState.ObjectID@"updating current tile data, based on "$UnitState;
	strFailText @= "CurrTileData loc=("$m_kCurrTileData.kTile.X@m_kCurrTileData.kTile.Y@m_kCurrTileData.kTile.Z$")\n";
	strFailText @= "UnitState Loc=("$UnitState.TileLocation.X@UnitState.TileLocation.Y@UnitState.TileLocation.Z$")\n";
	`LogAI(strFailText@self@GetStateName());
}

function float GetIdealRangeMeters()
{
	if (IsMeleeMove() || class'XGAIPlayer'.static.IsMindControlled(UnitState))
	{
		return DefaultMeleeIdealRange;
	}
	if( m_kBTCurrWeaponTemplate == None && UnitState != None && UnitState.GetPrimaryWeapon() != None )
	{
		m_kBTCurrWeaponTemplate = X2WeaponTemplate(UnitState.GetPrimaryWeapon().GetMyTemplate());
	}
	if( m_kBTCurrWeaponTemplate != None )
	{
		return m_kBTCurrWeaponTemplate.iIdealRange;
	}
	return DefaultIdealRange;
}

function ai_tile_score ScoreDestinationTile( TTile kTile, vector vLoc, XComCoverPoint kCover, out ai_tile_score RawTileData_out, optional out float fDistFromEnemy )
{
	local ai_tile_score kDiffScore;
//	local float fOldAccuracy, fNewAccuracy;
//	local float fIdealRange;
	kDiffScore = InitMoveTileData(kTile, kCover);
	RawTileData_out = FillTileScoreData(kTile, vLoc, kCover,,fDistFromEnemy);
	// Scoring data
	// Cover value increases as our new cover improves over the old cover.  Also increases if we were flanked.
	kDiffScore.fCoverValue = RawTileData_out.fCoverValue - m_kCurrTileData.fCoverValue; 

	// UPDATE- Distance score difference is no longer calculated here since the weighting factors into both sides of the difference calculation.
	kDiffScore.fDistanceScore = RawTileData_out.fDistanceScore;
	kDiffScore.fPriorityDistScore = RawTileData_out.fPriorityDistScore;
		
	// Flank score increases if we were not flanking anyone but end up flanking someone
	kDiffScore.fFlankScore  = RawTileData_out.fFlankScore  - m_kCurrTileData.fFlankScore;
	// ENemy Visibility score increases from -1 to 1 when we had no visible enemies and now have visible enemies.  or vice versa.
	kDiffScore.fEnemyVisibility = RawTileData_out.fEnemyVisibility - m_kCurrTileData.fEnemyVisibility;
	// Enemy Vis1 score delta
	kDiffScore.fEnemyVisibilityPeak1 = RawTileData_out.fEnemyVisibilityPeak1 - m_kCurrTileData.fEnemyVisibilityPeak1;
	// Ally visibility score = -1 or 0 or 1, depending on gaining or losing visibility to allies.
	kDiffScore.fAllyVisibility = RawTileData_out.fAllyVisibility - m_kCurrTileData.fAllyVisibility;

	kDiffScore.fAllyAbilityRangeScore = RawTileData_out.fAllyAbilityRangeScore - m_kCurrTileData.fAllyAbilityRangeScore;
	return kDiffScore;
}

function float GetWeightedTileScore( ai_tile_score kTileDiffScore, ai_tile_score kRawTileData, int MoveProfileIndex, out DebugTileScore DebugScore)
{
	local float fTotalScore, RandVal;
	local int RandWeight;
	local float fDistanceScore, fCurrDistScore, fNewDistScore, fPriorityDistScore; // Distance score pulled out since it's a bit more complex.
	// Switch on special conditions for specific weighting profiles.
	// Early exit on locations without LoS to any enemies.
	if (m_bUseMoveRestriction)
	{ 
		if (m_kCurrMoveRestriction.bLoSToEnemy)
		{
			if (kRawTileData.fEnemyVisibility < 0)
			{
				DebugScore.bFailEnemyLoS = true;
				return 0;
			}
		}
		if( m_kCurrMoveRestriction.bNoLoSToEnemy )
		{
			if( kRawTileData.fEnemyVisibility > 0 )
			{
				DebugScore.bFailEnemyLoS = true;
				return 0;
			}
		}
		if (m_kCurrMoveRestriction.bLoSToAlly)
		{
			if (kRawTileData.fAllyVisibility < 1)
			{
				DebugScore.bFailAllyLoS = true;
				return 0;
			}
		}
		if( m_kCurrMoveRestriction.bFlanking )
		{
			if( kRawTileData.fFlankScore == 0 )
			{
				DebugScore.bFailFlanking = true;
				return 0;
			}
		}
	}

	// Fail if this is the same tile as we started on.
	if (kRawTileData.kTile.X == UnitState.TileLocation.X && kRawTileData.kTile.Y == UnitState.TileLocation.Y && abs(UnitState.TileLocation.Z-kRawTileData.kTile.Z) <= 3)
	{
		DebugScore.bInBadArea = true;
		return 0;
	}

	// Otherwise score is based on the weightings of each of the scores.
	fNewDistScore = kRawTileData.bCloserThanIdeal ? (kRawTileData.fDistanceScore*m_arrMoveWeightProfile[MoveProfileIndex].fCloseModifier)
												  : (kRawTileData.fDistanceScore*m_arrMoveWeightProfile[MoveProfileIndex].fFarModifier);
	fCurrDistScore = m_kCurrTileData.bCloserThanIdeal ? (m_kCurrTileData.fDistanceScore*m_arrMoveWeightProfile[MoveProfileIndex].fCloseModifier)
													  : (m_kCurrTileData.fDistanceScore*m_arrMoveWeightProfile[MoveProfileIndex].fFarModifier);
	fDistanceScore = fNewDistScore - fCurrDistScore;  

	// Calc priority distance - distance from priority target, if any.
	if( m_arrMoveWeightProfile[MoveProfileIndex].fPriorityDistWeight != 0 )
	{
		fPriorityDistScore = kRawTileData.fPriorityDistScore - m_kCurrTileData.fPriorityDistScore;
	}

	fTotalScore =   kTileDiffScore.fCoverValue      * m_arrMoveWeightProfile[MoveProfileIndex].fCoverWeight
		          + fDistanceScore					* m_arrMoveWeightProfile[MoveProfileIndex].fDistanceWeight
				  + kTileDiffScore.fFlankScore   * m_arrMoveWeightProfile[MoveProfileIndex].fFlankingWeight
				  + kTileDiffScore.fEnemyVisibility * m_arrMoveWeightProfile[MoveProfileIndex].fEnemyVisWeight
				  + kTileDiffScore.fEnemyVisibilityPeak1 * m_arrMoveWeightProfile[MoveProfileIndex].fEnemyVisWeightPeak1
				  + kTileDiffScore.fAllyVisibility  * m_arrMoveWeightProfile[MoveProfileIndex].fAllyVisWeight
				  + fPriorityDistScore				* m_arrMoveWeightProfile[MoveProfileIndex].fPriorityDistWeight
				  + kTileDiffScore.fAllyAbilityRangeScore * AllyAbilityRangeWeight
				  ;

	if (m_arrMoveWeightProfile[MoveProfileIndex].fRandWeight >= 0.1)
	{
		RandVal = Abs(DecisionStartHistoryIndex + (kRawTileData.kTile.X * kRawTileData.kTile.Y));
		RandWeight = m_arrMoveWeightProfile[MoveProfileIndex].fRandWeight*10;
		RandVal = RandVal % RandWeight;
		RandVal /= 10.0f;
		fTotalScore += RandVal;
		DebugScore.RandVal = RandVal;
	}

	DebugScore.WeightedScore = fTotalScore;
	// Apply spread weighting only on tiles that are > 0.
	if( fTotalScore > 0 )
	{
		if( kRawTileData.bWithinSpreadMin )
		{
			fTotalScore *= kRawTileData.SpreadMultiplier;
			DebugScore.bInMinSpread = true;
		}
	}

	DebugScore.FinalScore = fTotalScore;
	return fTotalScore;
}

function ai_tile_score FillTileScoreData(TTile kTile, vector vLoc, XComCoverPoint kCover, optional array<GameRulesCache_VisibilityInfo> arrEnemyInfos, optional out float fDist)
{
	local ai_tile_score kTileData;
	local GameRulesCache_VisibilityInfo VisibilityInfo;
	local int EnemyInfoIndex;
	local array<GameRulesCache_VisibilityInfo> arrAlliesInfo;
	local int nFlanked, nMidCover, nHighCover, nFlanksEnemy, nVisibleEnemies, nVisibleAllies, nAlliesInAbilityRange;
	local float fDistSq, fIdealRange, SpreadDistSq, PriorityDist;
	local XComCoverPoint kEnemyCover;
	local XComWorldData World;
	local XComCoverPoint Cover;
	local int Dir;

	World = `XWORLD;
	// Pull enemy visibility/cover data.
	kTileData = InitMoveTileData(kTile, kCover);
	if (arrEnemyInfos.Length == 0)
	{
		class'X2TacticalVisibilityHelpers'.static.GetAllEnemiesForLocation(vLoc, UnitState.ControllingPlayer.ObjectID, arrEnemyInfos);
		if( GetAIUnitDataID(m_kUnit.ObjectID) > 0 ) // Skip this step if the unit has no alert data container.  (XCom units)
		{
			for( EnemyInfoIndex = arrEnemyInfos.Length - 1; EnemyInfoIndex >= 0; EnemyInfoIndex-- )
			{
				// Discard info about units we don't know about, and ignore enemies that cannot see this location.
				if( (CachedKnownUnitRefs.Find('ObjectId', arrEnemyInfos[EnemyInfoIndex].SourceID) == INDEX_NONE)
				   // Also remove units that can't see this location due to LoS or range constraints.
				   || !arrEnemyInfos[EnemyInfoIndex].bVisibleGameplay || arrEnemyInfos[EnemyInfoIndex].DefaultTargetDist > m_fSightRangeSq )
				{
					arrEnemyInfos.Remove(EnemyInfoIndex, 1);
				}
			}
		}
	}
	class'X2TacticalVisibilityHelpers'.static.GetAllAlliesForLocation(vLoc, UnitState.ControllingPlayer.ObjectID, arrAlliesInfo);
	foreach arrAlliesInfo(VisibilityInfo)
	{
		if( VisibilityInfo.SourceID != m_kUnit.ObjectID )
		{
			if( VisibilityInfo.bClearLOS
			   && VisibilityInfo.DefaultTargetDist < m_fSightRangeSq )
			{
				nVisibleAllies++;
				if( VisibilityInfo.DefaultTargetDist < SpreadMinDistanceSq )
				{
					kTileData.bWithinSpreadMin = true;
					// Keep track of shortest spread distance.
					if( SpreadDistSq == 0 || VisibilityInfo.DefaultTargetDist < SpreadDistSq )
					{
						SpreadDistSq = VisibilityInfo.DefaultTargetDist;
					}
				}
			}
			if( WeightedAllyRangeSq > 0 && VisibilityInfo.DefaultTargetDist < WeightedAllyRangeSq )
			{
				nAlliesInAbilityRange++;
			}
		}
	}

	// Determine if flanked or not in cover.  Also determine if each enemy might be flanked from here.
	foreach arrEnemyInfos(VisibilityInfo)
	{
		if (VisibilityInfo.bClearLOS
			&& VisibilityInfo.DefaultTargetDist < m_fSightRangeSq)
		{
			// Ignore this from the visible enemy list if it is not a valid target (bound or panicked).
			if( m_kPlayer == None || m_kPlayer.IsTargetValidBasedOnLastResortEffects(VisibilityInfo.SourceID) )
			{
				nVisibleEnemies++;

				if( GetCachedEnemyCover(VisibilityInfo.SourceID, kEnemyCover) ) // Check if this point flanks the cover at the enemy location.
				{
					if( class'XGUnitNativeBase'.static.DoesFlankCover(vLoc, kEnemyCover) )
					{
						nFlanksEnemy++;
					}
				}
				else
				{
					// No cover at enemy location?  Flanked.
					nFlanksEnemy++;
				}
			}

			// Include any targets when considering spread.
			if( !IsMeleeMove() && VisibilityInfo.DefaultTargetDist < SpreadMinDistanceSq )
			{
				kTileData.bWithinSpreadMin = true;
				// Keep track of shortest spread distance.
				if( SpreadDistSq == 0 || VisibilityInfo.DefaultTargetDist < SpreadDistSq )
				{
					SpreadDistSq = VisibilityInfo.DefaultTargetDist;
				}
			}
		}
		else
		{
			// Don't consider flanking or cover scores on enemies that we can't see from here.
			continue;
		}

		// Only consider flanked-ness of location if this target is not in our ignore list.
		if( IgnoredEnemiesForDefenseChecks.Find('ObjectID', VisibilityInfo.SourceID) == INDEX_NONE )
		{
			if( VisibilityInfo.TargetCover == CT_None )
			{
				nFlanked++;
			}
			// warning - this will just take the last cover type, not necessarily the worst or best cover available here.
			else if( VisibilityInfo.TargetCover == CT_MidLevel )
			{
				nMidCover++;
			}
			else
			{
				nHighCover++;
			}
		}
	}

	if( kTileData.bWithinSpreadMin )
	{
		UpdateSpreadValue(kTileData, SpreadDistSq);
	}
	// Apply basic cover info for tile location when there are no enemies visible.
	if( arrEnemyInfos.Length == 0 )
	{
		World.GetCoverPointAtFloor(vLoc, Cover);

		for( Dir = 0; Dir < `COVER_DIR_COUNT; ++Dir )
		{
			if( `IS_HIGH_COVER(Cover, Dir ) )
			{
				nHighCover++;
			}
			if( `IS_LOW_COVER(Cover, Dir ) )
			{
				nMidCover++;
			}
		}
	}

	// Cover score is an average cover value against all enemies, from -5 (no cover) to 1 (standing cover)
	if (nFlanked+nMidCover+nHighCover > 0)
	{
		kTileData.fCoverValue =  ( nFlanked*CALC_NO_COVER_FACTOR				// No cover value
								   + nMidCover*CALC_MID_COVER_FACTOR			// Mid cover value
								   + nHighCover*FullCoverFactor)		// High cover value
								 / float(nFlanked + nMidCover + nHighCover);  // Take average of all cover values.
	}

	// Civilian enemy check. 
	if( bBTCiviliansAsEnemiesInMove )
	{
		// Overwrite nVisibleEnemies and arrEnemyInfos with visible enemy civilians.
		arrEnemyInfos.Length = 0;
		if( m_kPlayer.bCiviliansTargetedByAliens )
		{
			class'X2TacticalVisibilityHelpers'.static.GetAllTeamUnitsForLocation(vLoc, UnitState.ControllingPlayer.ObjectID, eTeam_Neutral, arrEnemyInfos);
			m_kPlayer.RemoveFacelessFromList(arrEnemyInfos);
		}
		nVisibleEnemies = arrEnemyInfos.Length;
	}

	//Fill out var int nTilesToEnemy; // Distance in meters from enemy.
	if ( GetNearestKnownEnemy(vLoc, fDistSq, arrEnemyInfos) != None )
	{
		fDist = Sqrt(fDistSq);
		fDist = `UNITSTOMETERS(fDist);
	}
	else
	{
		if( UnitState.ControllingPlayerIsAI() )
		{
			`LogAI("FillTileScoreData could not find nearest enemy to target location!  Setting distance value to"@MaxDistScoreNoKnownEnemies@"meters.");
		}
		fDist = MaxDistScoreNoKnownEnemies;
	}
	fIdealRange = GetIdealRangeMeters();
	kTileData.bCloserThanIdeal =  (fDist <= fIdealRange);
//	Calculation:  IR = ideal range, DTE = distance to the enemy
//	 A tile location gets a tile score based on the inverse of the difference between IR & CDTE:
//		CurrentTileScore(CTS) = CALC_RANGE_NUMERATOR / (| DTE - IR |*CALC_RANGE_DENOM_FACTOR + CALC_RANGE_DENOM_ADDEND).
//		Destination 'A' Tile Score(ATS) = (10 / (| DTE - IR | + 10))
//		This value gets modified depending on if it is inside or outside the ideal range(fCloseModifier vs fFarModifier)
//		and the final distance score is the difference between the modified ATS and the modified CTS.
//		e.g. if 'A' is closer than the ideal range, and the current unit location is further than the ideal range,
//		Distance Score = (ATS * fCloseModifier) - (CTS * fFarModifier).
	if( bCALC_RANGE_LINEAR )
	{
		kTileData.fDistanceScore = 1 - (abs(fDist - fIdealRange)/CALC_RANGE_LINEAR_DENOM);
	}
	else
	{
		kTileData.fDistanceScore = CALC_RANGE_NUMERATOR / (abs(fDist - fIdealRange)*CALC_RANGE_DENOM_FACTOR + CALC_RANGE_DENOM_ADDEND);
	}

	if( bScoringPriorityTarget )
	{
		PriorityDist = VSize(ScoringPriorityLocation - vLoc);
		PriorityDist = `UNITSTOMETERS(PriorityDist);
		if( bCALC_RANGE_LINEAR )
		{
			kTileData.fPriorityDistScore = 1 - (PriorityDist / CALC_RANGE_LINEAR_DENOM);
		}
		else
		{
			kTileData.fPriorityDistScore = CALC_RANGE_NUMERATOR / (PriorityDist*CALC_RANGE_DENOM_FACTOR + CALC_RANGE_DENOM_ADDEND);
		}
	}

	//Fill out var float FlankScore; // 0 if not flanking, 1 if flanking an enemy.
	if (nFlanksEnemy > 0)
	{
		kTileData.fFlankScore = 1;
	}

	//Fill out Enemy Visibility scores.
	if (nVisibleEnemies > 0)
	{
		kTileData.fEnemyVisibility = (1.0f/MAX_EXPECTED_ENEMY_COUNT)*nVisibleEnemies; // Pure increasing value per visible enemy.
		if (nVisibleEnemies > MAX_EXPECTED_ENEMY_COUNT)
		{
			kTileData.fEnemyVisibilityPeak1 = MIN_ENEMY_VIS_PEAK1_VALUE;
		}
		else
		{
			kTileData.fEnemyVisibilityPeak1 = 1.0f-((1.0f/MAX_EXPECTED_ENEMY_COUNT)*(nVisibleEnemies-1)); // N(1)=1.0, N(2)=0.75, N(3)=0.5, N(4)=0.25
		}
	}
	else
	{
		// Zero visible enemies is generally discouraged.
		kTileData.fEnemyVisibility = -1.0f;
		kTileData.fEnemyVisibilityPeak1 = -1.0f;
	}

	//Fill out var float AllyVisibility;   // 1 if ally is visible.
	if (nVisibleAllies > 0)
	{
		if (nVisibleAllies > VIS_ALLY_PLATEAU_VALUE)
			kTileData.fAllyVisibility = 1.0f;
		else
			kTileData.fAllyVisibility = 1.0f - (1.0f/(1<<nVisibleAllies)); // N(1)=.5, N(2)=.75, N(3)=.875, N(4)=.9375
	}
	else
	{
		kTileData.fAllyVisibility = 0;
	}

	if( nAlliesInAbilityRange > 0 && ActiveRevealedAllyCount > 0)
	{
		kTileData.fAllyAbilityRangeScore = float(nAlliesInAbilityRange) / float(ActiveRevealedAllyCount);
	}
	return kTileData;
}

function UpdateSpreadValue(out ai_tile_score TileData, float fDistSq)
{
	local int iTileIndex, MaxTileIndex;
	MaxTileIndex = SpreadTileDistances.Length;
	for( iTileIndex = 0; iTileIndex < MaxTileIndex; ++iTileIndex )
	{
		if( fDistSq <= SpreadTileDistances[iTileIndex] )
		{
			TileData.SpreadMultiplier = SpreadMultiplierPerDistance[iTileIndex];
			return;
		}
	}
	TileData.SpreadMultiplier = 1.0f; // If we got here, this distance is outside our SpreadMultiplierPerDistance arrays.
}

function bool IsBehaviorTreeAvailable()
{
	local X2AIBTBehavior kBT;
	kBT = GetBehaviorTree();
	return (kBT != None);
}

// RunCount = Number of times to sequentially run the behavior tree.
// History Index = Minimum history index to wait before running the behavior tree.
function bool StartRunBehaviorTree( Name OverrideNode='', bool bSkipTurnOnFailure=false, bool bInitFromPlayerEachRun=false)
{
	if( m_kBehaviorTree != None && m_kBehaviorTree.m_eStatus == BTS_RUNNING ) // Should not be starting a behavior tree when one is currently running.
	{
		`RedScreen("Attempting to start running new behavior tree ("$(OverrideNode!=''?String(OverrideNode):"Standard Root")$") on Unit "$UnitState.ObjectID$" when a behavior tree ("$m_kBehaviorTree.m_strName$") is already running!");
	}
	SetBehaviorTree(OverrideNode);
	if( IsBehaviorTreeAvailable() )
	{
		`LogAI(UnitState.ObjectID@"Calling StartRunBehaviorTree, Root="$m_kBehaviorTree.m_strName$", BehaviorTreeAvailable=true."@`ShowVar(bBTHasStartedDestinationsProcess));
		`BEHAVIORTREEMGR.BeginBehaviorTree(UnitState.ObjectID);
		RefreshUnitCache();
		LogAvailableAbilities();
		InitBehaviorTree(bSkipTurnOnFailure, bInitFromPlayerEachRun);
		StepProcessBehaviorTree();
		return true;
	}
	else
	{
		`RedScreen("Attempted to start behavior tree ("$(OverrideNode != '' ? String(OverrideNode) : "Standard Root")$") on Unit "$UnitState.ObjectID$", failed in IsBehaviorTreeAvailable()!");
	}
	return false;
}

function UseSurprisedScamperMovement()
{
	bUseSurprisedScamperMove = true;
}

function BTRunCompletePreExecute()
{
	if( m_kPlayer != None )
	{
		m_kPlayer.OnBTRunCompletePreExecute(UnitState.ObjectID);
	}
}

// Reset any override node, revert back to default.
function OnBehaviorTreeRunComplete()
{ 
	local X2AIBTBehaviorTree BTMgr;
	// Clean up alert data marked for deletion.
	DeleteMarkedAlertData();
	if( m_kPlayer != None )
	{
		m_kPlayer.OnBTRunCompletePostExecute(UnitState.ObjectID);
	}
	// Clear old behavior tree here, before the EndBehaviorTree kicks off the next one. (which could be this one again.)
	m_kBehaviorTree = None;
	BTMgr = `BEHAVIORTREEMGR;
	BTMgr.EndBehaviorTree(UnitState.ObjectID);

	// Clean up if this unit is done.
	if( BTMgr.ActiveObjectID != UnitState.ObjectID )
	{
		// Reset cheat manager behavior tree override after having used it.
		if( `CHEATMGR != None && `CHEATMGR.iAIBTOverrideID == UnitState.ObjectID )
		{
			`CHEATMGR.iAIBTOverrideID = 0;
			`CHEATMGR.strAIBTOverrideNode = '';
		}

		// Clear the priority target
		PriorityTarget.ObjectID = 0;
	}

	`PRECOMPUTEDPATH.ClearOverrideTargetLocation(); // Clear this flag in case the grenade target location was locked.
}

private function int DecreasingOrder(int Entry1, int Entry2)
{
	if( Entry1 == Entry2 )
	{
		return 0;
	}
	return (Entry1 > Entry2) ? 1 : -1;
}

// Delete alert data as specified from Behavior Tree action, BT_MarkAlertDataForDeletion
function DeleteMarkedAlertData()
{
	local int i, NumDeletions, AlertIndex;;
	local XComGameState_AIUnitData kUnitData;
	local XComGameState NewGameState;
	local int iDataID;

	NumDeletions = AlertDataMarkedForDelete.Length;
	if(NumDeletions > 0)
	{
		// Sort alert data decreasing order.
		AlertDataMarkedForDelete.Sort(DecreasingOrder);

		// Update unit data game state with deleted alert entries.
		iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
		if( iDataID > 0 ) // If this doesn't already exist, there is no data to delete.
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Deleting Old Alert Data");
			kUnitData = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', iDataID));
			for( i = 0; i < NumDeletions; ++i )
			{
				AlertIndex = AlertDataMarkedForDelete[i];
				`Assert(kUnitData.m_arrAlertData.Length > AlertIndex);
				kUnitData.m_arrAlertData.Remove(AlertIndex, 1);
			}
			AlertDataMarkedForDelete.Length = 0;
			NewGameState.AddStateObject(kUnitData);
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}
}

// Reset the behavior tree to use the override node or revert to the default behavior tree node.
function SetBehaviorTree(Name OverrideNode = '')
{
	local Name DefaultRoot;
	if (OverrideNode != '')
	{
		if (m_kBehaviorTree == None || m_kBehaviorTree.m_strName != OverrideNode)
		{
			`Assert( m_kBehaviorTree == None || m_kBehaviorTree.m_eStatus != BTS_RUNNING ); // Should not be changing the behavior tree when one is currently running.
			m_kBehaviorTree = `BEHAVIORTREEMGR.GenerateBehaviorTree(OverrideNode, UnitState.GetMyTemplate().CharacterGroupName);
			if (m_kBehaviorTree != None)
			{
				return;
			}
			`LogAI("Warning - SetBehaviorTree failed to generate behavior tree to node name:"@OverrideNode@"...Reverting to default.");
		}
		else // Exit if we don't need to change anything.  (Behavior tree is already set to the override node.)
		{
			return;
		}
	}

	DefaultRoot = GetBehaviorTreeRoot();
	// Exit if we don't need to change anything.
	if (m_kBehaviorTree != none && DefaultRoot == m_kBehaviorTree.m_strName)
	{
		return;
	}

	// Otherwise revert the tree to the default.
	`Assert( m_kBehaviorTree == None || m_kBehaviorTree.m_eStatus != BTS_RUNNING ); // Should not be changing the behavior tree when one is currently running.
	m_kBehaviorTree = `BEHAVIORTREEMGR.GenerateBehaviorTree(DefaultRoot, UnitState.GetMyTemplate().CharacterGroupName);
	if (m_kBehaviorTree == None)
	{
		`LogAI("Warning - SetBehaviorTree failed to generate behavior tree to default node:"@DefaultRoot@"...No behavior tree set for unit #"$UnitState.ObjectID);
	}
}

function X2AIBTBehavior GetBehaviorTree()
{
	local X2AIBTBehavior kBT;
	if (`CHEATMGR != None)
	{
		if (`CHEATMGR.iAIBTOverrideID == UnitState.ObjectID)
		{
			// Don't regenerate a new behavior tree if one is already running.
			if( m_kBehaviorTree.m_strName == `CHEATMGR.strAIBTOverrideNode )
				return m_kBehaviorTree;

			kBT = `BEHAVIORTREEMGR.GenerateBehaviorTree(`CHEATMGR.strAIBTOverrideNode, UnitState.GetMyTemplate().CharacterGroupName);
			if(kBT != None)
			{
				return kBT;
			}
		}
	}
	return m_kBehaviorTree;
}

function StepProcessBehaviorTree()
{
	local AvailableTarget kTarget;
	local X2AIBTBehavior kBT;
	kBT = GetBehaviorTree();
	`Assert(kBT != None);
	m_eBTStatus = kBT.Run(m_kUnit.ObjectID, DecisionStartHistoryIndex);

	if (m_eBTStatus == BTS_SUCCESS)
	{
		`LogAI("Behavior tree ran, result= SUCCESS.  Ability selected:"$m_strBTAbilitySelection);
		if (BT_HasTargetOption(m_strBTAbilitySelection, kTarget))
		{
			`LogAI("Target selected = "@kTarget.PrimaryTarget.ObjectID);
		}
		SaveBTTraversals();
		BTRunCompletePreExecute();
		BTExecuteAbility();
		OnBehaviorTreeRunComplete();
	}
	else if (m_eBTStatus == BTS_FAILURE)
	{
		`LogAI("Behavior tree ran, result= FAILURE.  No ability selected.");
		`CHEATMGR.AIStringsUpdateString(UnitState.ObjectID, "Error- Behavior tree FAILURE. no ability selected.");
		BTRunCompletePreExecute();
		if( BTSkipTurnOnFailure )
		{
			SkipTurn("from StepProcessBehaviorTree: Behavior tree result = FAILURE."); // Force end-of-turn if no ability is selected.
		}
		SaveBTTraversals();
		OnBehaviorTreeRunComplete();
		GotoState('EndOfTurn');
	}
	else if (m_eBTStatus == BTS_RUNNING)
	{
		`LogAI("Behavior tree ran, result= BTS_RUNNING.  Resuming next iteration after timer countsdown..");
		SetTimer(0.001f, false, nameof(StepProcessBehaviorTree));
	}
}

function BTExecuteAbility()
{
	local string strFailOutput;
	local XComGameState_Ability AbilityState;
	`LogAI(m_kUnit@m_kUnit.GetPawn()@"Called BTExecutingAbility().");
	m_strDebugLog @= "Executing ability: "@m_strBTAbilitySelection;

	if( m_strBTAbilitySelection == 'SkipMove' )
	{
		`CHEATMGR.AIStringsUpdateString(UnitState.ObjectID, "Behavior tree SUCCESS. Selected SKIP MOVE.");
		SkipTurn("from BTExecuteAbility- Selected SkipMove from BT.");
		return;
	}

	SelectedAbility = FindAbilityByName(m_strBTAbilitySelection, AbilityState);
	if( !IsValidAction(SelectedAbility, strFailOutput) )
	{
		`LogAI("Error- Behavior tree returned success, with no valid selected ability!  Error:"$strFailOutput);
		SkipTurn("from BTExecuteAbility- No valid selected ability!");
		return;
	}

	// Message intent.
	if( `CHEATMGR != None )
	{
		if( `CHEATMGR.m_strBTIntent != "" )
		{
			`PRES.GetWorldMessenger().Message(`CHEATMGR.m_strBTIntent, m_kUnit.GetGameStateLocation(), m_kUnit.GetVisualizedStateReference(), eColor_Cyan, , , eTeam_All);
			`CHEATMGR.AIStringsUpdateString(UnitState.ObjectID, `CHEATMGR.m_strBTIntent);
		}
		else
		{
			`CHEATMGR.AIStringsUpdateString(UnitState.ObjectID, string(m_strBTAbilitySelection));
		}
	}

	if( IsMoveAbility(SelectedAbility) )
	{
		ExecuteMoveAbility();
		//Later update this to pull from the destination we already selected.
	}
	else
	{
		if( !bBTTargetSet )
		{
			m_kBTCurrTarget.kTarget = BT_GetBestTarget(m_strBTAbilitySelection);
			m_kBTCurrTarget.AbilityName = m_strBTAbilitySelection;
			BTTargetIndex = INDEX_NONE;
		}
		if( bSetDestinationWithAbility )
		{
			m_arrTargetLocations.Length = 0;
			m_arrTargetLocations.AddItem(m_vBTDestination);
		}
		if( m_kBTCurrTarget.AbilityName == m_strBTAbilitySelection && m_kBTCurrTarget.kTarget.PrimaryTarget.ObjectID > 0 )
		{
			SetTargetIndexByObjectID(m_kBTCurrTarget.kTarget.PrimaryTarget.ObjectID);

			if( m_kPlayer != None && AbilityState.GetMyTemplate().Hostility == eHostility_Offensive )
			{
				// Adding to target set counter any time we specify a valid primary target for an offensive ability. 
				m_kPlayer.IncrementUnitTargetedCount(m_kBTCurrTarget.kTarget.PrimaryTarget.ObjectID);
			}
		}
		else if( AbilityState.GetMyTemplate().AbilityTargetStyle.IsA('X2AbilityTarget_Self') )
		{
			// Set target index to self. This fixes issues when self-targeting abilities apply their
			// effects to targets instead of to the shooters.
			SetTargetIndexByObjectID(UnitState.ObjectID);
		}

		ChooseWeapon();

		// Activate ability directly here instead of switching to another state to activate it.
		if( IsValidAction(SelectedAbility) )
		{
			class'XComGameStateContext_Ability'.static.ActivateAbility(SelectedAbility, BTTargetIndex, m_arrTargetLocations,, AbilityPathTiles);
			m_bUnitAbilityCacheDirty = true;

			if( `CHEATMGR.bForceAbilityOneTimeUse && GetAbilityName(SelectedAbility) ~= `CHEATMGR.strAIForcedAbility )
			{
				`CHEATMGR.strAIForcedAbility = "";
			}
			OnCompleteAbility(SelectedAbility, m_arrTargetLocations);
	
			// Register offensive ability usage with the AI Player.
			if( AbilityState.GetMyTemplate().Hostility == eHostility_Offensive )
			{
				XGAIPlayer(`BATTLE.GetAIPlayer()).RegisterOffensiveAbilityUsage( UnitState.ObjectID );
			}
		}
		else
		{
			`RedScreen("AI- Attempted to execute an invalid ability! Unit#"$UnitState.ObjectID@"Skipping turn.");
			SkipTurn("from function BTExecuteAbility- Invalid Ability.");
		}

	}

	GotoState('EndOfTurn');
}


function InitBehaviorTree(bool bSkipTurnOnFailure=false, bool bInitFromPlayerEachRun=false)
{
	local X2AIBTBehavior BT;
	local array<Name> dummyList;
	if( bInitFromPlayerEachRun )
	{
		InitFromPlayer();
	}
	BT = GetBehaviorTree();
`if(`notdefined(FINAL_RELEASE))
	BT.SetTraversalIndex(0); // Set node indices for each node in the behavior tree.  
						// This traverses the entire tree recursively - but only used for debug logging.
`endif

	BTSkipTurnOnFailure = bSkipTurnOnFailure;
	m_arrBTBestTargetOption.Length = 0;
	m_arrBTTargetStack.Length = 0;
	m_iAlertDataIter = INDEX_NONE;
	m_iAlertDataScoreCurrent = 0;
	m_iAlertDataScoreHighestIndex = INDEX_NONE;
	m_iAlertDataScoreHighest = 0;
	m_bAlertDataMovementUseCover = false;
	m_bAlertDataMovementDestinationSet = false;
	m_strBTCurrAbility = '';
	m_fBTAbortTime = WorldInfo.TimeSeconds + 5.0f;
	iBTSRunningTest = 3;
	m_bBTDestinationSet = false;
	bBTTargetSet = false;
	m_arrTargetLocations.Length = 0;
	bBTHasStartedDestinationsProcess = false;
	PrimedAoEAbility = INDEX_NONE;
	AbilityPathTiles.Length = 0;
	ActiveBTStack.Length = 0;
	CurrentBTStackRef.ObjectID = INDEX_NONE;
	bIncludeAlliesAsMeleeTargets = false;
	`LogAI("Calling InitBehaviorTree."@`ShowVar(bBTHasStartedDestinationsProcess));

	DebugBTScratchText = "";
	`CHEATMGR.m_strBTIntent = "";
	BTPriorityTarget = 0;
	m_kBTCurrTarget.TargetID = INDEX_NONE; // Clear current target
	bForcePathIfUnreachable = false;

	CacheAllies();
	CacheKnownEnemies();

	FindOrGetAbilityList('', dummyList); // Cache ability name list

	if( m_kPlayer != None )
	{
		m_kPlayer.OnBTRunInit();
	}
}

function CacheAllies()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	History = `XCOMHISTORY;
	CachedActiveAllies.Length = 0;
	ActiveRevealedAllyCount = 0;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.ObjectID != UnitState.ObjectID 
			&& Unit.GetTeam() == UnitState.GetTeam() 
			&& Unit.IsAbleToAct() )
		{
			CachedActiveAllies.AddItem(Unit);
			if( !Unit.IsUnrevealedAI() )
			{
				++ActiveRevealedAllyCount;  // Number used in movement weight scoring.
			}
		}
	}
}

function CacheKnownEnemies()
{
	CachedKnownUnitRefs.Length = 0; 
	GetAllKnownEnemyStates(,CachedKnownUnitRefs);
	CacheEnemyCover();
	UpdateIgnoredEnemyList();
}

function UpdateIgnoredEnemyList()
{
	local array<StateObjectReference> EnemiesWithActionPoints;
	local int RemainingActionPoints;
	local StateObjectReference KnownEnemyRef;
	IgnoredEnemiesForDefenseChecks.Length = 0;
	// Check if any units can be ignored for those that can act during every action.
	if( UnitState.GetMyTemplate().bCanTickEffectsEveryAction )
	{
		if( !`TACTICALRULES.UnitActionPlayerIsAI() ) // No ignored enemies if this happens during the AI turn.
		{
			RemainingActionPoints = class'Helpers'.static.GetRemainingXComActionPoints(false, EnemiesWithActionPoints);
			if( RemainingActionPoints > 0 ) // If all enemies used their points already, ignore none.
			{
				foreach CachedKnownUnitRefs(KnownEnemyRef)
				{
					// If this unit is not in the list of units with action points, add it to the ignore list.
					if( EnemiesWithActionPoints.Find('ObjectID', KnownEnemyRef.ObjectID) == INDEX_NONE )
					{
						IgnoredEnemiesForDefenseChecks.AddItem(KnownEnemyRef);
					}
				}
			}
		}
	}

	// Otherwise, units that are last-resort units can be ignored when checking if the destination is flanked.
	foreach CachedKnownUnitRefs(KnownEnemyRef)
	{
		if( IgnoredEnemiesForDefenseChecks.Find('ObjectID', KnownEnemyRef.ObjectID) == INDEX_NONE 
		   && m_kPlayer != None && !m_kPlayer.IsTargetValidBasedOnLastResortEffects(KnownEnemyRef.ObjectID) )
		{
			IgnoredEnemiesForDefenseChecks.AddItem(KnownEnemyRef);
		}
	}
}

native function CacheEnemyCover();
native function bool GetCachedEnemyCover(int ObjectID, out XComCoverPoint CoverPoint);

function bool BT_HasBTVar(Name VarName, optional out int Value_out )
{
	local int Index;
	Index = BTVars.Find('VarName', String(VarName));
	if( Index == INDEX_NONE )
	{
		return false;
	}
	Value_out = BTVars[Index].Value;
	return true;
}
function bool BT_SetBTVar(String VarName, int Value, bool bOverwrite=true)
{
	local int Index;
	local BehaviorTreeLocalVar BTVar;
	Index = BTVars.Find('VarName', VarName);
	if( Index == INDEX_NONE )
	{
		BTVar.VarName = VarName;
		BTVar.Value = Value;
		BTVars.AddItem(BTVar);
		`LogAIBT("Added new entry.  \n VarName="$VarName@"\n Value="$Value);
		return true;
	}
	else if( bOverwrite )
	{
		BTVars[Index].Value = Value;
		`LogAIBT("Overwrote entry #"$Index$".  \n VarName="$VarName@"\n Value="$Value);
		return true;
	}
	`LogAIBT("ERROR - SetBTVar failed!  Entry for VarName:"$VarName@"exists, not set to overwrite!");
	return false;
}

function bool BT_HasTargetOption( Name strAbility, optional out AvailableTarget kTarget_out )
{
	local int iIndex;
	iIndex = m_arrBTBestTargetOption.Find('AbilityName', strAbility);
	if (iIndex == -1)
	{
		return false;
	}
	kTarget_out = m_arrBTBestTargetOption[iIndex].kTarget;
	return true;
}

function bool BT_SetTargetOption(Name strAbility, AvailableTarget Target)
{
	local int TargetIndex;
	local ability_target AbilityTargetData;
	local AvailableAction Action;
	Action = FindAbilityByName(strAbility);
	if( Action.AvailableTargets.Find('PrimaryTarget', Target.PrimaryTarget) != INDEX_NONE)
	{
		AbilityTargetData.AbilityName = strAbility;
		AbilityTargetData.iScore = 1000;
		AbilityTargetData.kTarget = Target;
		AbilityTargetData.TargetID = Target.PrimaryTarget.ObjectID;

		TargetIndex = m_arrBTBestTargetOption.Find('AbilityName', strAbility);
		if( TargetIndex == INDEX_NONE )
		{
			TargetIndex = m_arrBTBestTargetOption.Length;
			m_arrBTBestTargetOption.AddItem(AbilityTargetData);
		}
		else
		{
			m_arrBTBestTargetOption[TargetIndex] = AbilityTargetData;
		}
		return true;
	}
	else
	{
		`LogAIBT("BT_SetTargetOption failure - Target is not valid for ability "$strAbility);
	}
	return false;
}

// Check distance between current target and unit.
function float BT_GetTargetDistMeters(Name AbilityName)
{
	local GameRulesCache_VisibilityInfo VisInfo;
	local float Dist;
	local AvailableTarget Target;
	if( BT_HasTargetOption(AbilityName, Target) )
	{
		if( `TACTICALRULES.VisibilityMgr.GetVisibilityInfo(UnitState.ObjectID, Target.PrimaryTarget.ObjectID, VisInfo) )
		{
			Dist = Sqrt(VisInfo.DefaultTargetDist);
			Dist = `UNITSTOMETERS(Dist);
		}
		else
		{
			Dist = GetDistanceFromUnitID(Target.PrimaryTarget.ObjectID);
			Dist = `UNITSTOMETERS(Dist);
		}
	}
	else
	{
		`LogAIBT("Error - BT_GetTargetDistMeters:  No Current Target exists for ability "$AbilityName);
	}
	return Dist;
}

function int BT_GetHitChanceForPotentialTargetOnAbility(Name AbilityName)
{
	local XComGameState_Ability AbilityState;
	local ShotBreakdown Breakdown;
	local AvailableTarget Target;
	if( BT_HasTargetOption('Potential', Target) && Target.PrimaryTarget.ObjectID > 0)
	{
		FindAbilityByName(AbilityName, AbilityState);
		if( AbilityState == None )
		{
			`LogAIBT("Could not find ability "$AbilityName@"for this unit.");
			return 0;
		}

		AbilityState.GetShotBreakdown(Target, Breakdown);
		return Breakdown.FinalHitChance;
	}
	else
	{
		`LogAIBT("Error - BT_GetHitChanceForPotentialTargetOnAbility:  No potential target exists! ");
		`RedScreenOnce("BT Error - XGAIBehavior::BT_GetHitChanceForPotentialTargetOnAbility failed. No potential Target exists!) \n BT Root=" $m_kBehaviorTree.m_strName@" @ACHENG");
	}
	return 0;
}

function bool BT_SetTargetStack( Name strAbility )
{
	local AvailableTarget kTarget;
	local string DebugText;
	DebugBTScratchText = "";
	m_kBTCurrTarget.TargetID = INDEX_NONE;
	m_kBTCurrAbility = FindAbilityByName( strAbility );
	if (m_kBTCurrAbility.AbilityObjectRef.ObjectID > 0 && m_kBTCurrAbility.AvailableCode == 'AA_Success' && m_kBTCurrAbility.AvailableTargets.Length > 0)
	{
		m_strBTCurrAbility = strAbility;
		foreach m_kBTCurrAbility.AvailableTargets(kTarget)
		{
			if( IsValidTarget(kTarget) )
			{
				m_arrBTTargetStack.AddItem(kTarget);
				DebugText @= kTarget.PrimaryTarget.ObjectID;
			}
		}
		`LogAIBT("SetTargetStack results- Added:"@DebugText);
		return true;
	}
	if( m_kBTCurrAbility.AbilityObjectRef.ObjectID <= 0 )
	{
		`LogAIBT("SetTargetStack results- no Ability reference found: "$strAbility);
	}
	else if( m_kBTCurrAbility.AvailableCode != 'AA_Success' )
	{
		`LogAIBT("SetTargetStack results- Ability unavailable - AbilityCode == "$ m_kBTCurrAbility.AvailableCode);
	}
	else
	{
		`LogAIBT("SetTargetStack results- No targets available! ");
	}
	return false;
}

// Add all known enemies to target stack.
function bool BT_SetPotentialTargetStack(bool bVisibleOnly=false)
{
	local AvailableTarget Target;
	local XComGameState_AIUnitData UnitData;
	local int DataID;
	local array<StateObjectReference> KnownEnemies;
	local StateObjectReference EnemyRef;
	local AvailableAction EmptyAbility;
	local string DebugText;
	local XComGameState_Unit EnemyState;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	DebugBTScratchText = "";
	m_kBTCurrTarget.TargetID = INDEX_NONE;

	DataID = GetAIUnitDataID(m_kUnit.ObjectID);
	if( DataID > 0 )
	{
		UnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(DataID));
	}
	if( UnitData != None )
	{
		if( bVisibleOnly )
		{
			class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(UnitState.ObjectID, KnownEnemies, class'X2TacticalVisibilityHelpers'.default.LivingLOSVisibleFilter);
		}
		else
		{
			UnitData.GetAbsoluteKnowledgeUnitList(KnownEnemies);
		}
		m_kBTCurrAbility = EmptyAbility;
		m_strBTCurrAbility = 'Potential';
		foreach KnownEnemies(EnemyRef)
		{
			EnemyState = XComGameState_Unit(History.GetGameStateForObjectID(EnemyRef.ObjectID));
			if( !EnemyState.bRemovedFromPlay && !EnemyState.IsConcealed())
			{
				Target.PrimaryTarget.ObjectID = EnemyRef.ObjectID;
				m_arrBTTargetStack.AddItem(Target);
				DebugText @= Target.PrimaryTarget.ObjectID;
			}
		}
		`LogAIBT("SetPotentialTargetStack results- Added:"@DebugText);
		return true;
	}
	`LogAIBT("SetPotentialTargetStack results- Failed - No AIUnitData gamestate found.");
	return false;
}

// Add all visible allies to target stack.
function bool BT_SetPotentialAllyTargetStack()
{
	local AvailableTarget Target;
	local AvailableAction EmptyAbility;
	local XComGameState_Unit AllyState;
	local string DebugText;

	DebugBTScratchText = "";
	m_kBTCurrTarget.TargetID = INDEX_NONE;
	m_kBTCurrAbility = EmptyAbility;
	m_strBTCurrAbility = 'Potential';
	foreach CachedActiveAllies(AllyState)
	{
		if( AllyState.ObjectID == m_kUnit.ObjectID )
		{
			continue;
		}
		Target.PrimaryTarget.ObjectID = AllyState.ObjectID;
		m_arrBTTargetStack.AddItem(Target);
		DebugText @= Target.PrimaryTarget.ObjectID;
	}
	if( m_arrBTTargetStack.Length > 0 )
	{
		`LogAIBT("SetPotentialAllyTargetStack results- Added:"@DebugText);
		return true;
	}
	`LogAIBT("SetPotentialAllyTargetStack results- Failed - No visible allies found.");
	return false;
}

function bool BT_FindClosestPointToAxisGround()
{
	local int Iterations;
	local vector TargetLoc, AxisDirection;
	local TTile Tile;
	local XComWorldData XWorld;
	const MAX_ITERATIONS = 10;
	const SampleDistance = 320; // 5 meter increments.

	// Test point on Axis first.
	if( m_kPlayer != None && m_kPlayer.m_kNav != None )
	{
		TargetLoc = m_kPlayer.m_kNav.GetNearestPointOnAxisOfPlay(GetGameStateLocation(), true);
		AxisDirection = Normal(m_kPlayer.m_kNav.m_kAxisOfPlay.v2 - m_kPlayer.m_kNav.m_kAxisOfPlay.v1);
		XWorld = `XWorld;
		Tile = XWorld.GetTileCoordinatesFromPosition(TargetLoc);
		while( !XWorld.IsGroundTile(Tile) )
		{
			// Move along the axis of play and test other points along the axis.
			TargetLoc = TargetLoc + SampleDistance*AxisDirection;
			Tile = XWorld.GetTileCoordinatesFromPosition(TargetLoc);
			if( ++Iterations > MAX_ITERATIONS )
			{
				break;
			}
		}
		if( XWorld.IsGroundTile(Tile) )
		{
			Tile = m_kUnit.m_kReachableTilesCache.GetClosestReachableDestination(Tile);
			if( m_kUnit.m_kReachableTilesCache.IsTileReachable(Tile) )
			{
				m_vBTDestination = `XWORLD.GetPositionFromTileCoordinates(Tile);
				m_bBTDestinationSet = true;
				return true;
			}
			else
			{
				`LogAIBT(" GetClosestReachableDestination failed! \n");
			}
		}
		else
		{
			`LogAIBT("Tested"@Iterations@"tiles along axis, but could not find a ground tile.\n");
		}
	}
	`LogAIBT(" Failed - no ground tile found at or near axis. ");
	return false;
}

function bool BT_FindClosestPointToTarget(Name AbilityName)
{
	local int BestIndex;
	local XComGameState_Unit Target;
	local TTile Tile, TargetTile;
	BestIndex = m_arrBTBestTargetOption.Find('AbilityName', AbilityName);
	if( BestIndex != INDEX_NONE )
	{
		Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrBTBestTargetOption[BestIndex].TargetID));
		if( Target != None )
		{
			// Pick an occupied tile next to the target to find a path to.
			TargetTile = class'Helpers'.static.GetClosestValidTile(Target.TileLocation);
			if( !class'Helpers'.static.GetFurthestReachableTileOnPathToDestination(Tile, TargetTile, UnitState) )
			{
				`LogAIBT(" GetFurthestReachableTileOnPathToDestination failed! \n");
				Tile = m_kUnit.m_kReachableTilesCache.GetClosestReachableDestination(TargetTile);
			}

			if( m_kUnit.m_kReachableTilesCache.IsTileReachable(Tile) )
			{
				m_vBTDestination = `XWORLD.GetPositionFromTileCoordinates(Tile);
				m_bBTDestinationSet = true;
				return true;
			}
			else
			{
				`LogAIBT(" GetClosestReachableDestination failed! \n");
			}
		}
	}

	`LogAIBT(" Failed - No target found for ability: "$AbilityName);
	return false;
}

function bool BT_HeatSeekNearestUnconcealed()
{
	local XComGameState_Unit NearestEnemy;
	local vector EnemyLoc;
	local TTIle TileDestination;
	local XComWorldData XWorld;

	NearestEnemy = GetNearestKnownEnemy(GetGameStateLocation(), , , bBTCiviliansAsEnemiesInMove);
	if( NearestEnemy != None )
	{
		XWorld = `XWORLD;
		EnemyLoc = `XWORLD.GetPositionFromTileCoordinates(NearestEnemy.TileLocation);
		if( HasValidDestinationToward(EnemyLoc, EnemyLoc, m_bBTCanDash) )
		{
			if( CanUseCover() )
			{
				GetClosestCoverLocation(EnemyLoc, EnemyLoc);
			}

			TileDestination = XWorld.GetTileCoordinatesFromPosition(EnemyLoc);
			if( TileDestination != UnitState.TileLocation )
			{
				m_vBTDestination = EnemyLoc;
				m_bBTDestinationSet = true;
				return true;
			}
			else
			{
				`LogAIBT(" GetClosestCoverLocation failed! \n");
			}
		}
		else
		{
			`LogAIBT(" HasValidDestinationToward (nearest enemy) failed! \n");
		}
	}
	else
	{
		`LogAIBT(" GetNearestKnownEnemy failed! \n");
	}
	return false;
}


function bool BT_IsTargetInMovementRange( Name AbilityName )
{
	local XComGameState_Unit Target;
	local array<TTile> AdjacentTiles;
	local TTile Tile;
	local Name MeleeAbilityName;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate Template;
	local vector TilePosition, TargetVectorPosition;
	local XComWorldData XWorld;
	local float AbilityRange;
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
	if( Target != None )
	{
		MeleeAbilityName = 'StandardMelee';
		class'X2AIBTLeafNode'.static.ResolveAbilityNameWithUnit(MeleeAbilityName, self);
		if( AbilityName == MeleeAbilityName )
		{
			GetMeleePointsAroundTile(Target.TileLocation, AdjacentTiles);
			foreach AdjacentTiles(Tile)
			{
				if( IsWithinMovementRange(Tile, m_bBTCanDash) )
				{
					`LogAIBT("Ability:"$AbilityName$" determined to be IN Melee range from target "$m_kBTCurrTarget.TargetID$".\n");
					return true;
				}
			}
		}
		else
		{
			FindAbilityByName(AbilityName, AbilityState);
			if( AbilityState != None )
			{
				Template = AbilityState.GetMyTemplate();
				if( Template.AbilityTargetStyle.IsA('X2AbilityTargetStyle_Self') )
				{
					// Ability range originates at the unit, and extends by the ability radius.
					AbilityRange = AbilityState.GetAbilityRadius();
				}
				else
				{
					// For most other abilities, the ability range originates at the cursor location.
					// So the ability range includes the cursor range, plus any 'splash damage' radius.
					AbilityRange = `METERSTOUNITS(AbilityState.GetAbilityCursorRangeMeters());
					AbilityRange += AbilityState.GetAbilityRadius();
				}

				if( AbilityRange > 0) 
				{
					// For now just testing the closest reachable tile to the target.
					// If we need to support checking LoS, we can update that here as well, probably checking more tiles.
					XWorld = `XWORLD;
					Tile = m_kUnit.m_kReachableTilesCache.GetClosestReachableDestination(Target.TileLocation);
					TilePosition = XWorld.GetPositionFromTileCoordinates(Tile);
					TargetVectorPosition = XWorld.GetPositionFromTileCoordinates(Target.TileLocation);
					if( VSizeSq(TargetVectorPosition - TilePosition) < Square(AbilityRange) )
					{
						`LogAIBT("Ability:"$AbilityName$" determined IN range ("$AbilityRange / 64.0f$"m) from closest tile to target.\n");
						return true;
					}
					else
					{
						`LogAIBT("Ability:"$AbilityName$" determined out of range ("$AbilityRange/64.0f$"m) from closest tile to target.\n");
					}
				}
				else
				{
					`LogAIBT("Could not determine valid ability range for ability:"$AbilityName$"\n");
				}
			}
		}
	}
	return false;
}

function bool BT_IsTargetInAttackRange( Name AbilityName )
{
	local AvailableTarget Target;
	local XComGameState_Unit TargetState;
	local XComGameState_Ability AbilityState;
	local float MinRange, MaxRange;
	if( BT_HasTargetOption(AbilityName, Target) || BT_HasTargetOption('Potential', Target) )
	{
		TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
	}
	else 
	{
		BT_GetTarget(TargetState);
	}

	if( TargetState != None )
	{
		FindAbilityByName(AbilityName, AbilityState);
		if( AbilityState != None )
		{
			AbilityState.GetValidWeaponRange(MinRange, MaxRange);
			if( class'Helpers'.static.IsUnitInRangeFromLocations(UnitState, TargetState, UnitState.TileLocation, TargetState.TileLocation, MinRange, MaxRange))
			{
				`LogAIBT("Found valid range of ability"@AbilityName@"between "$MinRange@"and"@MaxRange@"units.  Target is IN range.");
				return true;
			}
			`LogAIBT("Found valid range of ability"@AbilityName@"between "$MinRange@"and"@MaxRange@"units.  Target is NOT in range.");
		}
	}
	else
	{
		`LogAIBT("No best target defined for ability: "$AbilityName@"or no target stack currently active.");
	}
	return false;
}

function int BT_GetAbilityTargetUnitCount(Name strAbility)
{
	local AvailableTarget kTarget;
	local AvailableAction kAbility;
	local array<int> arrTargetList;
	local StateObjectReference kTargetRef;
	local XComGameState_Ability kAbilityState;
	local XComGameState_Unit TargetState;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	kAbility = FindAbilityByName(strAbility, kAbilityState);
	if (kAbilityState != None && kAbility.AvailableTargets.Length > 0)
	{
		foreach kAbility.AvailableTargets(kTarget)
		{
			if (kTarget.PrimaryTarget.ObjectID > 0)
			{
				if (arrTargetList.Find(kTarget.PrimaryTarget.ObjectID) == INDEX_NONE)
				{
					TargetState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
					if( TargetState != None )
					{
						arrTargetList.AddItem(kTarget.PrimaryTarget.ObjectID);
						`LogAIBT("\nTarget Found: "$kTarget.PrimaryTarget.ObjectID);
					}
				}
			}
			
			foreach kTarget.AdditionalTargets(kTargetRef)
			{
				if (kTargetRef.ObjectID > 0 && arrTargetList.Find(kTargetRef.ObjectID) == -1)
				{
					TargetState = XComGameState_Unit(History.GetGameStateForObjectID(kTargetRef.ObjectID));
					if( TargetState != None )
					{
						arrTargetList.AddItem(kTargetRef.ObjectID);
						`LogAIBT("\nTarget Found: "$kTargetRef.ObjectID);
					}
				}
			}
		}
	}
	return arrTargetList.Length;
}

function bool BT_SetNextTarget()
{
	if( m_arrBTTargetStack.Length == 0 )
		return false;
	BT_InitNextTarget(m_arrBTTargetStack[0]);
	m_arrBTTargetStack.Remove(0,1);
	return true;
}

function BT_InitNextTarget(AvailableTarget kTarget)
{
	m_kBTCurrTarget.AbilityName = m_strBTCurrAbility;
	m_kBTCurrTarget.iScore = 0;
	m_kBTCurrTarget.TargetID = kTarget.PrimaryTarget.ObjectID;
	m_kBTCurrTarget.kTarget = kTarget;
	`LogAIBT("CurrTarget set: ObjectID = "$m_kBTCurrTarget.TargetID);
	DebugBTScratchText = " ==============================\n";
	DebugBTScratchText $= "Scoring Next Target: #"$m_kBTCurrTarget.TargetID@ "\n";
}

function BT_AddToTargetScore(int iScore, Name AlternateDebugLabel='')
{
	local String DescLabel;
	m_kBTCurrTarget.iScore += iScore;
	if( AlternateDebugLabel == '' )
	{
		DescLabel = `BEHAVIORTREEMGR.GetLeafParentName();
	}
	else
	{
		DescLabel = String(AlternateDebugLabel);
	}
	if( iScore < 0 )
	{
		DebugBTScratchText @= DescLabel @" . . . "$iScore @"\n";
	}
	else
	{
		DebugBTScratchText @= DescLabel @" . . . +"$iScore @ "\n";
	}

}

function int BT_GetHitChanceOnTarget( optional Name AbilityName )
{
	local XComGameState_Ability kAbility;
	local ShotBreakdown kBreakdown;
	if( m_kBTCurrTarget.kTarget.PrimaryTarget.ObjectID > 0 )
	{
		if( m_kBTCurrAbility.AbilityObjectRef.ObjectID > 0 )
		{
			if( AbilityName != '' )
			{
				FindAbilityByName(AbilityName, kAbility);
				if( kAbility == None )
				{
					`LogAIBT("Could not find ability "$AbilityName@"for this unit.");
				}
			}
			if( kAbility == None )
			{
				kAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrAbility.AbilityObjectRef.ObjectID));
			}
			kAbility.GetShotBreakdown(m_kBTCurrTarget.kTarget, kBreakdown);
			return kBreakdown.FinalHitChance;
		}
		else
		{
			`LogAIBT("Error - BT_GetHitChanceOnTarget:  No Current Ability exists! (This does not work for PotentialTargetStacks!)");
			`RedScreenOnce("BT Error - XGAIBehavior::BT_GetHitChanceOnTarget failed. No Current Ability exists! (This does not work for PotentialTargetStacks!)\n BT Root=" $m_kBehaviorTree.m_strName@" @ACHENG");
		}
	}
	else
	{
		`LogAIBT("Error - BT_GetHitChanceOnTarget:  No Current Target exists!");
		`RedScreenOnce("BT Error - XGAIBehavior::BT_GetHitChanceOnTarget failed. No Current Target exists!\n BT Root=" $m_kBehaviorTree.m_strName@" @ACHENG");
	}
	return 0;
}

function int BT_GetHitChanceOnBestTarget()
{
	local int iBestIdx;
	local XComGameState_Ability kAbility;
	local ShotBreakdown kBreakdown;
	local AvailableAction kAvailableAction;
	local String ShotAbilityName;

	ShotAbilityName = GetStandardShotName();
	kAvailableAction = GetShotAbility(true);
	kAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAvailableAction.AbilityObjectRef.ObjectID));
	iBestIdx = m_arrBTBestTargetOption.Find('AbilityName', Name(ShotAbilityName));
	if( iBestIdx != -1 )
	{
		kAbility.GetShotBreakdown(m_arrBTBestTargetOption[iBestIdx].kTarget, kBreakdown);
		return kBreakdown.FinalHitChance;
	}
	return 0;
}

function int BT_GetHighestHitChanceAgainstXCom()
{
	local XComGameState_Ability Ability;
	local ShotBreakdown Breakdown;
	local AvailableAction Action;
	local AvailableTarget Target;
	local int TopHitChance, HitChance;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	History = `XCOMHISTORY;

	Action = GetShotAbility(false);
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
	TopHitChance = -1;
	foreach Action.AvailableTargets(Target)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
		if( Unit.GetTeam() != eTeam_XCom )
		{
			continue;
		}
		Ability.GetShotBreakdown(Target, Breakdown);
		HitChance = Breakdown.FinalHitChance;
		if( HitChance > TopHitChance )
		{
			TopHitChance = HitChance;
		}
	}
	return TopHitChance;
}

function BT_UpdateBestTarget()
{
	local int iBestIdx;
	`LogAIBT(DebugBTScratchText);
	`LogAIBT("- - -  Total Score = "@m_kBTCurrTarget.iScore);
	iBestIdx = INDEX_NONE;
	// Only update targets with a + score.
	if (m_kBTCurrTarget.iScore > 0)
	{
		iBestIdx = m_arrBTBestTargetOption.Find('AbilityName', m_strBTCurrAbility);
		if( iBestIdx == INDEX_NONE )
		{
			iBestIdx = m_arrBTBestTargetOption.Length;
			m_arrBTBestTargetOption.AddItem(m_kBTCurrTarget);
		}
		else
		{
			if (m_kBTCurrTarget.iScore > m_arrBTBestTargetOption[iBestIdx].iScore)
			{		
				m_arrBTBestTargetOption[iBestIdx] = m_kBTCurrTarget;
			}
		}
	}
	if( iBestIdx >= 0 )
	{
		`LogAIBT("  -- Best: Unit#"$m_arrBTBestTargetOption[iBestIdx].TargetID@" ("$m_arrBTBestTargetOption[iBestIdx].iScore$")\n");
	}
	else
	{
		`LogAIBT("  -- Best: Unit: NONE\n");
	}
}

function bool BT_SetTargetAsPriority(Name AbilityName)
{

	local int BestIndex;
	BestIndex = m_arrBTBestTargetOption.Find('AbilityName', AbilityName);
	if( BestIndex != INDEX_NONE )
	{
		BTPriorityTarget = m_arrBTBestTargetOption[BestIndex].TargetID;
		return true;
	}

	`LogAIBT(" Failed - No target found for ability: "$AbilityName);
	return false;
}

function int BT_GetVisibleEnemyXcomOnlyCount(bool bIncludeIncapacitated=false, bool bIncludeCosmetic=false, bool bIncludeTurrets=false)
{
	local int NumVisibleEnemies;
	local array<StateObjectReference> VisibleUnits;
	local StateObjectReference kObjRef;
	local XComGameState_Unit kEnemy;

	NumVisibleEnemies = 0;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(UnitState.ObjectID, VisibleUnits);
	foreach VisibleUnits(kObjRef)
	{
		kEnemy = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kObjRef.ObjectID));
		if( kEnemy != None && kEnemy.IsAlive() && kEnemy.GetTeam() == eTeam_XCom && !kEnemy.IsConcealed() )
		{
			if( (!bIncludeIncapacitated && kEnemy.IsIncapacitated())
			   || (!bIncludeCosmetic && kEnemy.GetMyTemplate().bIsCosmetic)
			   || (!bIncludeTurrets && kEnemy.IsTurret()) )
			{
				continue;
			}

			NumVisibleEnemies++;
		}
	}
	return NumVisibleEnemies;
}

function int BT_GetVisibleAllyCount(bool bIncludeIncapacitated = false, bool bIncludeCosmetic = false, bool bIncludeTurrets = false)
{
	local int NumVisibleAllies;
	local array<StateObjectReference> VisibleUnits;
	local StateObjectReference kObjRef;
	local XComGameState_Unit kAlly;

	NumVisibleAllies = 0;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleUnitsOnTeamForSource(UnitState.ObjectID, UnitState.GetTeam(), VisibleUnits);
	foreach VisibleUnits(kObjRef)
	{
		kAlly = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kObjRef.ObjectID));
		if( kAlly != None && kAlly.IsAlive() && kAlly.ObjectID != UnitState.ObjectID)
		{
			if( (!bIncludeIncapacitated && kAlly.IsIncapacitated())
			   || (!bIncludeCosmetic && kAlly.GetMyTemplate().bIsCosmetic)
			   || (!bIncludeTurrets && kAlly.IsTurret()) )
			{
				continue;
			}

			NumVisibleAllies++;
		}
	}
	return NumVisibleAllies;
}
function AvailableTarget BT_GetBestTarget( name AbilityName )
{
	local int iBestIdx;
	local AvailableTarget kTarget;
	iBestIdx = m_arrBTBestTargetOption.Find('AbilityName', AbilityName);
	if (iBestIdx >= 0)
	{
		kTarget = m_arrBTBestTargetOption[iBestIdx].kTarget;
	}
	return kTarget;
}

function bool BT_TargetIsKillable()
{
	local XComGameState_Unit kTarget;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;
	kTarget = XComGameState_Unit(History.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
	if (IsPossibleKillShot(m_kBTCurrAbility, kTarget))
	{
		return true;
	}

	return false;
}

function bool BT_TargetIsAdvent()
{
	local XComGameState_Unit kTarget;
	kTarget = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
	return kTarget.IsAdvent();
}

function bool BT_TargetIsAlien()
{
	local XComGameState_Unit kTarget;
	kTarget = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
	return kTarget.IsAlien();
}

function bool BT_TargetIsRobotic()
{
	local XComGameState_Unit kTarget;
	kTarget = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
	return kTarget.IsRobotic();
}

function bool IsPossibleKillShot(AvailableAction kAbility, XComGameState_Unit kTargetState)
{
	local ShotBreakdown kBreakdown;
	local XComGameState_Ability kAbilityState;
	local StateObjectReference kTargetRef;
	local WeaponDamageValue MinDamage, MaxDamage;
	local int iTarget, AllowsShield;

	if (kAbility.AbilityObjectRef.ObjectID > 0)	
	{
		kAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAbility.AbilityObjectRef.ObjectID));
		kTargetRef = kTargetState.GetReference();
		iTarget = kAbility.AvailableTargets.Find('PrimaryTarget', kTargetRef);
	
		if (iTarget != INDEX_NONE)
		{
			kAbilityState.GetShotBreakdown(kAbility.AvailableTargets[iTarget], kBreakdown);
			if (kBreakdown.FinalHitChance > 50)
			{
				kAbilityState.GetDamagePreview(kTargetRef, MinDamage, MaxDamage, AllowsShield);
				if (MinDamage.Damage >= kTargetState.GetCurrentStat(eStat_HP))
					return true;
			}
		}
	}
	return false;
}

function bool BT_IsFlankingTarget()
{
	local XComGameState_Unit kTarget;
	local vector vMyLoc;
	local XComCoverPoint kCover;
	if (BT_GetTarget(kTarget) && kTarget.CanTakeCover())
	{
		if( GetCachedEnemyCover(kTarget.ObjectID, kCover) ) // Check if this point flanks the cover at the enemy location.
		{
			vMyLoc = GetGameStateLocation();
			if (class'XGUnitNativeBase'.static.DoesFlankCover(vMyLoc, kCover) )
			{
				// Enemy has cover, but is flanked.
				return true;
			}
		}
		else
		{
			// Enemy is not in cover.
			return true;
		}
	}
	return false;
}

function bool BT_GetTarget(out XComGameState_Unit kTarget_out)
{
	if( m_kBTCurrTarget.TargetID > 0 )
	{
		kTarget_out = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
		if( kTarget_out != None )
		{
			return true;
		}
	}
	// Updated to use alert target if there is no regular target stack target.
	else if( BT_GetAlertTarget(kTarget_out) )
	{
		return true;
	}
	return false;
}

function bool BT_GetAlertTarget(out XComGameState_Unit kTarget_out)
{
	local AlertData Data;
	kTarget_out = None;
	if( GetAlertData(Data) )
	{
		if( Data.AlertSourceUnitID > 0)
		{
			kTarget_out = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Data.AlertSourceUnitID));
		}
	}

	if( kTarget_out != None )
	{
		return true;
	}
	return false;
}

function bt_status BT_FindDestinationWithLOS(int MoveTypeIndex)
{
	m_kCurrMoveRestriction.bLoSToEnemy = true;
	return BT_FindDestination(MoveTypeIndex, true);
}


function SetMoveRestriction(out AIMoveRestriction kMoveRestriction, vector vLoc, float MaxDistMeters, int MinTargetCount)
{
	kMoveRestriction.vAnchor = vLoc;
	kMoveRestriction.MaxDistance = MaxDistMeters;
	kMoveRestriction.MinTargetCount = MinTargetCount;

	if (MaxDistMeters > 0)
	{
		kMoveRestriction.fMaxDistSq = `METERSTOUNITS(MaxDistMeters);
		kMoveRestriction.fMaxDistSq = Square(kMoveRestriction.fMaxDistSq);
	}
}

function BT_ResetDestinationSearch()
{
	m_kCurrMoveRestriction.vAnchor = vect(0, 0, 0);
	m_kCurrMoveRestriction.bNoLoSToEnemy = false;
	m_kCurrMoveRestriction.bLoSToEnemy = false;
	m_kCurrMoveRestriction.bLoSToAlly = false;
	m_kCurrMoveRestriction.MaxDistance = -1;
	m_kCurrMoveRestriction.bFlanking = false;
	m_kCurrMoveRestriction.fMaxDistSq = -1;
	m_kCurrMoveRestriction.MinTargetCount = 0;
	m_kCurrMoveRestriction.bLoSToAxis = false;
	m_kCurrMoveRestriction.bGroundOnly = false;
	m_kCurrMoveRestriction.TargetedObjectID = INDEX_NONE;
	m_kCurrMoveRestriction.AvoidanceList.Length = 0;
	m_bUseMoveRestriction = false;
	bBTHasStartedDestinationsProcess = false;
	m_bBTDestinationSet = false;
	m_kBTCurrWeaponTemplate=None;
	m_bBTCanDash = false;
	bIgnoreHazards = false;
	bBTCiviliansAsEnemiesInMove = false;
	bBTNoCoverMovement = false;
	WeightedAllyRangeSq = -1;
	AllyAbilityRangeWeight = 0;
}

function BT_SetCanDash()
{
	m_bBTCanDash = true;
}

function BT_SetCiviliansAsEnemiesInMoveCalculation()
{
	bBTCiviliansAsEnemiesInMove = true;
}

function BT_SetNoCoverMovement()
{
	bBTNoCoverMovement = true;
}

function bool BT_SetAbilityForDestination( AvailableAction kAbility )
{
	local XComGameState_Ability kAbilityState;
	kAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAbility.AbilityObjectRef.ObjectID));
	if (kAbilityState != None)
	{
		m_kBTCurrWeaponTemplate = X2WeaponTemplate(kAbilityState.GetSourceWeapon().GetMyTemplate());
		if (m_kBTCurrWeaponTemplate != None)
			return true;
	}
	return false;
}

function bool BT_RestrictMoveToAbilityRange( name strAbility, int MinTargetCount=0 )
{
	local AvailableTarget Target;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit TargetState;
	local vector TargetLoc;
	local float MaxDistance;
	local int AoEAbilityID;
	local X2AbilityMultiTargetStyle TargetStyle;
	FindAbilityByName(strAbility, AbilityState);
	if (AbilityState != None)
	{
		MaxDistance = AbilityState.GetAbilityCursorRangeMeters();
		if( MaxDistance < 0 ) // Not a X2AbilityTarget_Cursor targeting style.
		{
			MaxDistance = GetAbilityRadius(AbilityState);
			MaxDistance = `UNITSTOMETERS(MaxDistance);
		}
		if( BT_HasTargetOption(strAbility, Target) )
		{
			TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
			TargetLoc = `XWORLD.GetPositionFromTileCoordinates(TargetState.TileLocation);
			m_kCurrMoveRestriction.TargetedObjectID = TargetState.ObjectID;
			SetMoveRestriction(m_kCurrMoveRestriction, TargetLoc, MaxDistance, 0);
			if( bBTHasStartedDestinationsProcess )
			{
				bBTHasStartedDestinationsProcess = false;
			}
			return true;
		}
		// AoE targets need special handling, since they aren't using the location of the target.
		else if ( HasAoEAbility(AoEAbilityID,strAbility) && AbilityState.ObjectID == AoEAbilityID )
		{
			if( TopAoETarget.Ability == strAbility ) 
			{
				// Use AoE target as our restriction anchor.
				SetMoveRestriction(m_kCurrMoveRestriction, TopAoETarget.Location, MaxDistance, 0);
				if( bBTHasStartedDestinationsProcess )
				{
					bBTHasStartedDestinationsProcess = false;
				}
				return true;
			}
			else if( MinTargetCount > 0 )
			{
				TargetStyle = AbilityState.GetMyTemplate().AbilityMultiTargetStyle;
				if( TargetStyle != None && TargetStyle.IsA('X2AbilityMultiTarget_Radius') )
				{
					MaxDistance = `UNITSTOMETERS(X2AbilityMultiTarget_Radius(TargetStyle).GetTargetRadius(AbilityState));
					SetMoveRestriction(m_kCurrMoveRestriction, vect(0, 0, 0), MaxDistance, MinTargetCount);
					return true;
				}
				else
				{
					`LogAIBT("Error - MinTargetCount currently only supported with radius-type targeting." );
				}
			}
			else if( BT_HasTargetOption('Potential', Target) )
			{
				TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
				TargetLoc = `XWORLD.GetPositionFromTileCoordinates(TargetState.TileLocation);
				SetMoveRestriction(m_kCurrMoveRestriction, TargetLoc, MaxDistance, 0);
				m_kCurrMoveRestriction.TargetedObjectID = TargetState.ObjectID;
				if( bBTHasStartedDestinationsProcess )
				{
					bBTHasStartedDestinationsProcess = false;
				}
				return true;
			}
			else
			{
				`LogAIBT("No AoE target specified for ability "@strAbility$". This function requires FindPotentialAoETargets-"$strAbility@" to have been run before this node is run, or specify Param[0] for a minimum number of targets > 0");
			}
		}
		else if( BT_HasTargetOption('Potential', Target) ) 
		{
			TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
			TargetLoc = `XWORLD.GetPositionFromTileCoordinates(TargetState.TileLocation);
			SetMoveRestriction(m_kCurrMoveRestriction, TargetLoc, MaxDistance, 0);
			m_kCurrMoveRestriction.TargetedObjectID = TargetState.ObjectID;
			if( bBTHasStartedDestinationsProcess )
			{
				bBTHasStartedDestinationsProcess = false;
			}
			return true;
		}
		// Currently we only allow using restrictions on current best-targets per ability.
		`LogAIBT("No target option found for ability "$strAbility@"- failed to set restriction within range of target.");
	}
	else
	{
		`LogAIBT("Failed to find ability name:"@strAbility);
	}
	return false;
}

// Force movement destination search to filter out any locations that are not in weapon range of specified potential target.
function bool BT_RestrictMoveToPotentialTargetRange(name AbilityName)
{
	local AvailableTarget Target;
	local XComGameState_Unit TargetState;
	local XComGameState_Ability AbilityState;
	local float RangeMin, RangeMax;
	local vector TargetLoc;

	if (BT_HasTargetOption('Potential', Target))
	{
		TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
		if(TargetState != None)
		{
			m_kCurrMoveRestriction.TargetedObjectID = TargetState.ObjectID;
			TargetLoc = `XWORLD.GetPositionFromTileCoordinates(TargetState.TileLocation);
			FindAbilityByName(AbilityName, AbilityState);
			if( AbilityState != None )
			{
				if( AbilityState.GetMyTemplate().AbilityTargetStyle.IsA('X2AbilityTarget_Self') )
				{
					RangeMax = AbilityState.GetAbilityRadius();
				}
				else
				{
					AbilityState.GetValidWeaponRange(RangeMin, RangeMax);
				}

				m_kCurrMoveRestriction.bLoSToEnemy = true;
				SetMoveRestriction(m_kCurrMoveRestriction, TargetLoc, `UNITSTOMETERS(RangeMax), 0);
				return true;
			}
			else
			{
				`LogAI("BT_RestrictMoveToPotentialTargetRange- FindAbilityByName: "$AbilityName@" Failed to find ability!!!");
			}
		}
	}
	return false;
}

function bool BT_AddAbilityRangeWeight(name AbilityName, float Weight=1.0f)
{
	local XComGameState_Ability AbilityState;

	FindAbilityByName(AbilityName, AbilityState);
	WeightedAllyRangeSq = -1;
	if( AbilityState != None )
	{
		WeightedAllyRangeSq = GetAbilityRadius(AbilityState);
		if( WeightedAllyRangeSq > 0 )
		{
			WeightedAllyRangeSq = Square(WeightedAllyRangeSq);
			AllyAbilityRangeWeight = Weight;
			return true;
		}
		else
		{
			`LogAIBT("BT_AddAbilityRangeWeight-"$AbilityName@" Failed to find ability radius > 0!");
		}
	}
	else
	{
		`LogAIBT("BT_AddAbilityRangeWeight- FindAbilityByName: "$AbilityName@" Failed to find ability!!!");
	}
	return false;
}

function BT_RestrictMoveFromEnemyLoS()
{
	m_kCurrMoveRestriction.bNoLoSToEnemy = true;
	if( bBTHasStartedDestinationsProcess )
	{
		bBTHasStartedDestinationsProcess = false;
	}
}

function BT_RestrictMoveToEnemyLoS()
{
	m_kCurrMoveRestriction.bLoSToEnemy = true;
	if (bBTHasStartedDestinationsProcess)
	{
		bBTHasStartedDestinationsProcess = false;
	}
}

function BT_RestrictMoveToAllyLoS()
{
	m_kCurrMoveRestriction.bLoSToAlly = true;
	if (bBTHasStartedDestinationsProcess)
	{
		bBTHasStartedDestinationsProcess = false;
	}
}
function BT_RestrictMoveToFlanking()
{
	m_kCurrMoveRestriction.bFlanking = true;
	if( bBTHasStartedDestinationsProcess )
	{
		bBTHasStartedDestinationsProcess = false;
	}
}

function BT_RestrictToAxisLoS()
{
	m_kCurrMoveRestriction.bLoSToAxis = true;
	if( bBTHasStartedDestinationsProcess )
	{
		bBTHasStartedDestinationsProcess = false;
	}
}

function BT_RestrictToGroundTiles()
{
	m_kCurrMoveRestriction.bGroundOnly = true;
}

function BT_DisableGroupMove()
{
	local XComGameState_AIGroup GroupState;
	local XComGameState NewGameState;
	if( m_kPlayer != None && m_kPlayer.m_kNav != None && m_kPlayer.m_kNav.IsPatrol(m_kUnit.ObjectID, m_kPatrolGroup) )
	{
		if( !m_kPatrolGroup.bDisableGroupMove )
		{
			m_kPatrolGroup.bDisableGroupMove = true;
			// Attempt to insert the other units in the group into the queue.
			m_kPlayer.AddGroupToMoveList(UnitState);
		}
		// Also disable scampering.  
		GroupState = GetGroupState();
		if( !GroupState.bProcessedScamper )
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Disable Scamper, pre-burrowed attack.");
			GroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', GroupState.ObjectID));
			GroupState.bProcessedScamper = true;
			NewGameState.AddStateObject(GroupState);
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}
}

function bt_status BT_FindDestination(int MoveTypeIndex, bool bRestricted=false)
{
	local TTile Tile;
	// Check if we need to reset our 
	if (bRestricted != m_bUseMoveRestriction)
	{
		// Reset destinations.
		bBTHasStartedDestinationsProcess = false;
		m_bUseMoveRestriction = bRestricted;
	}

	// Kick off if this hasn't been kicked off yet.
	if (!bBTHasStartedDestinationsProcess)
	{
		bBTHasStartedDestinationsProcess = true;
		UpdateTacticalDestinationsStepSize = 50;
		m_bCanDash = m_bBTCanDash;
		CurrMoveType = MoveTypeIndex;
		BT_StartGetDestinations(false, true, false);
	}

	// Still updating.
	if (bBTUpdatingTacticalDestinations)
	{
		return BTS_RUNNING;
	}

	// Done - check if we have any good destinations.
	if (m_arrBestTileScore[MoveTypeIndex] > 0)
	{
		// For now we are going to use the first one in the list.
		Tile = m_arrBestTileOption[MoveTypeIndex].kTile;
		m_vBTDestination = `XWORLD.GetPositionFromTileCoordinates(Tile);
		m_bBTDestinationSet = true;
		return BTS_SUCCESS;
	}

	// Reset restrictions and destination search on failures.
	BT_ResetDestinationSearch();
	return BTS_FAILURE;
}

function bool BTHandleGenericMovement()
{
	local int iAlertLevel;
	iAlertLevel = UnitState.GetCurrentStat(eStat_AlertLevel);
	if (iAlertLevel == 0 || UnitState.IsUnrevealedAI())
	{
		// Only green alert units move if they are in patrols.  Also allow non-ai units to move freely.
		if( m_kPlayer == None || m_kPlayer.m_kNav.IsPatrol(m_kUnit.ObjectID, m_kPatrolGroup) )
		{
			m_strBTAbilitySelection = 'StandardMove';
			return true;
		}
	}
	else if (iAlertLevel == 1)
	{
		m_strBTAbilitySelection = 'StandardMove';
		return true;
	}
	return false;
}

function XComGameState_AIPlayerData GetAIPlayerData()
{
	local XComGameState_AIPlayerData kData;
	if(m_kPlayer != None)
	{
		kData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(m_kPlayer.m_iDataID));
	}
	else
	{
		kData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(UnitState.GetAIPlayerDataID(true)));
	}
	return kData;
}

function XComGameState_AIGroup GetGroupState()
{
	local StateObjectReference kUnitRef;
	local XComGameState_AIPlayerData kPlayerData;
	local XComGameState_AIGroup kGroup;
	local int iID;

	kPlayerData = GetAIPlayerData();
	if (kPlayerData != None)
	{
		kUnitRef = UnitState.GetReference();
		iID = kPlayerData.GetGroupObjectIDFromUnit(kUnitRef);
		kGroup = XComGameState_AIGroup(`XCOMHISTORY.GetGameStateForObjectID(iID));
	}
	return kGroup;
}

function bool BT_IsFirstCombatTurn()
{
	// Check if last turn we were still green.
	local XComGameState LastTurnState;
	local XComGameState_Unit kOldUnitData;
	if (UnitState.GetCurrentStat(eStat_AlertLevel) > 0 && m_kPlayer != None)
	{
		LastTurnState = m_kPlayer.GetLastTurnGameState();
		kOldUnitData = XComGameState_Unit(LastTurnState.GetGameStateForObjectID(m_kUnit.ObjectID));
		if (kOldUnitData.GetCurrentStat(eStat_AlertLevel) == 0)
			return true;
	}
	return false;
}

function BT_SkipMove()
{
	m_strBTAbilitySelection = 'SkipMove';
}

function bool BT_DidNotMoveLastTurn()
{
	local string strLastAbilityName;
	if (SelectedAbility.AbilityObjectRef.ObjectID == 0)
	{
		return true;
	}
	strLastAbilityName = GetAbilityName(SelectedAbility);
	if (strLastAbilityName == "StandardMove")
	{
		return false;
	}
	return true;
}

function bool BT_IsFlanked()
{
	return UnitState.IsFlanked();
}

function bool BT_IsVisibleToPlayer( int ObjID )
{
	local XGPlayer kPlayer;
	kPlayer = XGBattle_SP(`BATTLE).GetHumanPlayer();
	return class'X2TacticalVisibilityHelpers'.static.GetTargetIDVisibleForPlayer(ObjID, kPlayer.ObjectID);
}

function bool BT_FindPotentialAoETarget(Name AoETargetProfile)
{
	if( FindAoETarget(AoETargetProfile) )
	{
		return true;
	}
	return false;
}

function bool BT_SelectAoETarget(Name ProfileName)
{
	local int iAbilityID;
	local AvailableTarget AvailTargets;
	local AoETargetingInfo Profile;
	local TTile TileDest, kClosestTile;

	if( HasAoEAbility(iAbilityID, GetAbilityFromTargetingProfile(ProfileName, Profile)) )
	{
		if (CanHitAoETarget(iAbilityID, TopAoETarget, Profile, true))
		{
			SetAdditionalAOETargets(AvailTargets);
			m_arrTargetLocations.Length = 0;
			SetAOETargetLocations(AvailTargets);
			PrimedAoEAbility = iAbilityID; // Mark this ability to save top aoe target if ability is used.
			if( Profile.bPathToTarget )
			{
				TileDest = `XWORLD.GetTileCoordinatesFromPosition(TopAoETarget.Location);
				if( !m_kUnit.m_kReachableTilesCache.BuildPathToTile(TileDest, AbilityPathTiles) )
				{
					if( !class'Helpers'.static.GetFurthestReachableTileOnPathToDestination(kClosestTile, TileDest, UnitState) )
					{
						kClosestTile = m_kUnit.m_kReachableTilesCache.GetClosestReachableDestination(TileDest);
					}
					m_kUnit.m_kReachableTilesCache.BuildPathToTile(kClosestTile, AbilityPathTiles);
				}
			}
			return true;
		}
	}
	return false;
}

function SetAdditionalAOETargets(out AvailableTarget Targets)
{
	local AvailableAction Ability;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local X2AbilityTemplate Template;
	local int i;
//	local bool bShowValidTiles;
//	local array<TTile> Tiles;
//	local TTile Tile;
//	local vector TileLoc;

	History = `XCOMHISTORY;
//	bShowValidTiles = false;
	for( i = 0; i < UnitAbilityInfo.AvailableActions.Length; ++i )
	{
		Ability = UnitAbilityInfo.AvailableActions[i];
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Ability.AbilityObjectRef.ObjectID));
		Template = AbilityState.GetMyTemplate();
		if( Template.DataName == TopAoETarget.Ability )
		{
/*			// FOR DEBUG ONLY.
			if( bShowValidTiles )
			{
				Template.AbilityMultiTargetStyle.GetValidTilesForLocation(AbilityState, TopAoETarget.Location, Tiles);
				foreach Tiles(Tile)
				{
					TileLoc = `XWORLD.GetPositionFromTileCoordinates(Tile);
					`SHAPEMGR.DrawSphere(TileLoc, vect(5, 5, 25), m_kDebugColor, true);
				}
			}

			// END DEBUG ONLY.
*/
			AbilityState.GatherAdditionalAbilityTargetsForLocation(TopAoETarget.Location, Targets);
			BTTargetIndex = UnitAbilityInfo.AvailableActions[i].AvailableTargets.Length;
			UnitAbilityInfo.AvailableActions[i].AvailableTargets.AddItem(Targets);
			bBTTargetSet = true;
			return;
		}
	}
}

function SetAOETargetLocations(const AvailableTarget Targets)
{
	local XComGameState_Ability AbilityState;
	
	FindAbilityByName(TopAoETarget.Ability, AbilityState);
	if( AbilityState != None )
	{
		AbilityState.GatherAbilityTargetLocationsForLocation(TopAoETarget.Location, Targets, m_arrTargetLocations);
	}
}

// Save out list of traversals to our unit AI data state.
// Update - due to save file constraints, this now saves BT traversals locally.  Also- this is only for debug.
function SaveBTTraversals()
{
`if(`notdefined(FINAL_RELEASE))
	local int RootIndex;
	local array<BTDetailedInfo> arrStatusList;

	BT_GetNodeDetailList(arrStatusList);
	RootIndex = `BEHAVIORTREEMGR.GetNodeIndex(m_kBehaviorTree.m_strName);
	AddTraversalData(arrStatusList, RootIndex);
`endif
}

function AddTraversalData(array<BTDetailedInfo> TraversalData, int RootIndex)
{
	local bt_traversal_data kNewStream;
	kNewStream.iHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	kNewStream.TraversalData = TraversalData;
	kNewStream.BehaviorTreeRootIndex = RootIndex;
	m_arrTraversals.AddItem(kNewStream);
}

function string GetBTTraversalDebugString(int iIndex = -1, bool bShowInvalid = true)
{
	local string strOutput;
	local bt_traversal_data kData;
	local int iNode;
	local BTDetailedInfo BTResult;

	if( m_arrTraversals.Length > 0 )
	{
		if( iIndex == -1 || iIndex >= m_arrTraversals.Length )
		{
			iIndex = m_arrTraversals.Length - 1;
		}

		kData = m_arrTraversals[iIndex];
		strOutput = "History Frame="$kData.iHistoryIndex$"       Unit#"$UnitState.ObjectID$"\n";
		for( iNode = 0; iNode < kData.TraversalData.Length; iNode++ )
		{
			BTResult = kData.TraversalData[iNode];
			if( !bShowInvalid && BTResult.Result != BTS_SUCCESS && BTResult.Result != BTS_FAILURE )
			{
				continue;
			}

			strOutput @= CompileBTString(BTResult, iNode, m_kBehaviorTree) @ "\n";
		}
	}
	return strOutput;

}

function string CompileBTString(BTDetailedInfo BTResult, int iNodeTraversalIndex, X2AIBTBehavior kBTRoot)
{
	local int iColorState;
	local string strOutput, NodeName;
	local X2AIBTBehavior kNode;
	if( BTResult.Result == BTS_SUCCESS )
	{
		iColorState = eUIState_Good;
	}
	else if( BTResult.Result == BTS_FAILURE )
	{
		iColorState = eUIState_Bad;
	}
	else
	{
		iColorState = eUIState_Disabled;
	}
	if( kBTRoot != None )
	{
		kNode = kBTRoot.GetNodeIndex(iNodeTraversalIndex);
		if( kNode != None )
		{
			NodeName = string(kNode.m_strName);
		}
		else
		{
			NodeName = "<Unknown Node>";
		}
	}
	else
	{
		NodeName = "<Unknown Node>";
	}

	strOutput = ColorTextByNode(kNode, iNodeTraversalIndex$")"@NodeName)
		@ class'UIUtilities_Text'.static.GetColoredText("["$string(BTResult.Result)$"]", iColorState);
	return strOutput;
}

function String ColorTextByNode(const out X2AIBTBehavior kNode, String Text)
{
	local String ColorText;
	local EDecoratorType DecType;
	ColorText = "<font color='#";
	if( kNode.IsA('X2AIBTDefaultConditions') )
	{	
		ColorText $= class'UIUtilities_Colors'.const.WARNING_HTML_COLOR; // YELLOW
	}
	else if( kNode.IsA('X2AIBTDefaultActions') )
	{
		ColorText $= class'UIUtilities_Colors'.const.WARNING2_HTML_COLOR; // ORANGE
	}
	else if( kNode.IsA('X2AIBTSelector') )
	{
		ColorText $= class'UIUtilities_Colors'.const.WHITE_HTML_COLOR; // WHITE
	}
	else if( kNode.IsA('X2AIBTSequence') )
	{
		ColorText $= class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR; // CYAN
	}
	else if( kNode.IsA('X2AIBTDecorator') )
	{
		DecType = X2AIBTDecorator(kNode).m_eDecType;
		switch( DecType )
		{
		case eDT_Inverter:
			ColorText $= "663300"; // BROWN?
			break;
		case eDT_Failer:
			ColorText $= "FF0000"; // RED
			break;
		case eDT_Successor:
			ColorText $= class'UIUtilities_Colors'.const.CASH_HTML_COLOR; // GREEN
			break;
		case eDT_RepeatUntilFail:
			ColorText $= class'UIUtilities_Colors'.const.SCIENCE_HTML_COLOR; // BLUE
			break;
		case eDT_RandFilter:
			ColorText $= class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR; // PURPLE
			break;
		default:
			ColorText $= class'UIUtilities_Colors'.const.BLACK_HTML_COLOR; 
		}
	}
	ColorText $= "'>"$Text$"</font>";
	return ColorText;
}

function XComGameState_Unit GetParentUnitState()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitState.ObjectID));
}

function string BT_GetNodeName( int iIndex )
{
	local X2AIBTBehavior kNode;
	kNode = m_kBehaviorTree.GetNodeIndex(iIndex);
	if (kNode != None)
		return string(kNode.m_strName);
	return "NOT FOUND";
}

function BT_GetNodeDetailList(out array<BTDetailedInfo> List)
{
	m_kBehaviorTree.GetNodeStatusList(List, DecisionStartHistoryIndex);
}

function bool BT_TargetIsCivilian()
{
	local XComGameState_Unit Target;
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
	return Target.IsCivilian();
}

function bool BT_TargetCanBecomeZombie()
{
	local XComGameState_Unit Target;
	local UnitValue TurnedZombieValue;

	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
	// Fail if this unit is robotic or alien.  (Humans only.)
	if( Target.IsAlien() || Target.IsRobotic() )
	{
		return false;
	}
	// Fail if this unit has already turned into a zombie.
	if( Target.GetUnitValue(class'X2Effect_SpawnPsiZombie'.default.TurnedZombieName, TurnedZombieValue) )
	{
		if( TurnedZombieValue.fValue > 0 )
		{
			return false;
		}
	}
	return true;
}

function bool BT_GetLivingEnemiesWithoutEffects(array<Name> EffectNames, optional out array<XComGameState_Unit> EnemyList, bool bBreakEarlyIfAnyFound=false)
{
	GetAllKnownEnemyStates(EnemyList, , , EffectNames);
	return EnemyList.Length > 0;
}

function bool BT_TargetIsClosestValidTarget()
{
	local GameRulesCache_VisibilityInfo kEnemyInfo;
	local array<XComGameState_Unit> EnemyList;
	local XComGameState_Unit CurrTargetState, Enemy;
	local array<Name> ExcludedEffects;
	local float DistSq, CurrTargetDistSq;
	local XComWorldData World;
	local vector MyLocation;
	World = `XWORLD;

	ExcludedEffects.AddItem(class'X2Ability_Viper'.default.BindSustainedEffectName);
	ExcludedEffects.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);

	BT_GetLivingEnemiesWithoutEffects(ExcludedEffects, EnemyList);

	// Check for closest against all non-panicked and non-bound enemies.
	if( EnemyList.Length > 0 )
	{
		MyLocation = GetGameStateLocation();
		CurrTargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
		if( EnemyList.Find(CurrTargetState) == INDEX_NONE )
		{
			return false;
		}

		CurrTargetDistSq = VSizeSq(World.GetPositionFromTileCoordinates(CurrTargetState.TileLocation) - MyLocation);
		foreach EnemyList(Enemy)
		{
			if( Enemy.ObjectID == CurrTargetState.ObjectID )
			{
				continue;
			}
			DistSq = VSizeSq(World.GetPositionFromTileCoordinates(Enemy.TileLocation) - MyLocation);
			if( DistSq < CurrTargetDistSq )
			{
				// Exit early if we find any enemy location closer than the current target distance.
				return false;
			}
		}
		// If we got here, that means none of the other enemies is closer than this unit.
		return true;
	}
	else
	{
		// If no non-panicked non-bound enemies exist, then take any closest enemy.
		class'X2TacticalVisibilityHelpers'.static.GetClosestVisibleEnemy(UnitState.ObjectID, kEnemyInfo );
		if( kEnemyInfo.TargetID == m_kBTCurrTarget.TargetID )
		{
			return true;
		}
	}
	return false;
}

function ETeam BT_GetTargetTeam()
{
	local XComGameState_Unit Target;
	if (BT_GetTarget(Target))
	{
		return Target.GetTeam();
	}
	return eTeam_None;
}

function bool BT_TargetHasHighestSoldierRank()
{
	local AvailableTarget kTarget;
	local XComGameState_Unit kSoldier;
	local XComGameStateHistory History;
	local int iCurrRank;
	History = `XCOMHISTORY;

	kSoldier = XComGameState_Unit(History.GetGameStateForObjectID(m_kBTCurrTarget.TargetID));
	iCurrRank = kSoldier.GetRank();

	foreach m_kBTCurrAbility.AvailableTargets(kTarget)
	{
		if (m_kBTCurrTarget.TargetID == kTarget.PrimaryTarget.ObjectID)
			continue;
		kSoldier = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
		if (kSoldier.GetRank() > iCurrRank)
		{
			return false;
		}
	}

	return true;
}

function bool BT_TargetHasHighestTeamVisibility()
{
	local AvailableTarget kTarget;
	local int iCurrUnitVis, iVis;

	iCurrUnitVis = class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(m_kBTCurrTarget.TargetID);

	foreach m_kBTCurrAbility.AvailableTargets(kTarget)
	{
		if (m_kBTCurrTarget.TargetID == kTarget.PrimaryTarget.ObjectID)
			continue;

		iVis = class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(kTarget.PrimaryTarget.ObjectID);
		if (iVis > iCurrUnitVis)
		{
			return false;
		}
	}
	return true;
}

function bool BT_TargetHasHighestShotHitChance()
{
	local XComGameState_Ability kShotAbility;
	local ShotBreakdown kBreakdown;
	local AvailableTarget kTarget;
	local AvailableAction kShotAction;
	local int iCurrHitChance;
	local String ShotAbilityName;

	ShotAbilityName = GetStandardShotName();

	kShotAction = FindAbilityByName( Name(ShotAbilityName), kShotAbility );
	kTarget.PrimaryTarget.ObjectID = m_kBTCurrTarget.TargetID;
	kShotAbility.GetShotBreakdown(kTarget, kBreakdown);
	iCurrHitChance = kBreakdown.FinalHitChance;

	foreach kShotAction.AvailableTargets(kTarget)
	{
		if (kTarget.PrimaryTarget.ObjectID == m_kBTCurrTarget.TargetID)
			continue;

		kShotAbility.GetShotBreakdown(kTarget, kBreakdown);
		if (kBreakdown.FinalHitChance > iCurrHitChance)
		{
			return false;
		}
	}
	return true;
}

function bool BT_SetAlertDataStack()
{
	local XComGameState_AIUnitData kUnitData;
	local int iDataID;

	// Clear out any alert data marked for delete before resetting the alert data stack.  (should already be empty)
	DebugBTScratchText = "";
	m_kBTCurrTarget.TargetID = INDEX_NONE;
	m_iAlertDataIter = INDEX_NONE;
	m_iAlertDataScoreCurrent = 0;
	m_iAlertDataScoreHighestIndex = INDEX_NONE;
	m_iAlertDataScoreHighest = 0;
	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
	if( iDataID > 0 )
	{
		kUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));
		kUnitData.RemoveOldAlertData();
		return kUnitData.m_arrAlertData.Length != 0;
	}
	`LogAI("No alert data found (also no AIUnitData) .");
	return false;
}

// Mark alert data index for delete.  (To be deleted after the behavior tree traversal is completed.)
function BT_MarkAlertDataForDeletion()
{
	if( m_iAlertDataIter > INDEX_NONE )
	{
		if( AlertDataMarkedForDelete.Find(m_iAlertDataIter) == INDEX_NONE )
		{
			AlertDataMarkedForDelete.AddItem(m_iAlertDataIter);
		}
	}
	else if( m_iAlertDataScoreHighestIndex != INDEX_NONE )
	{
		if( AlertDataMarkedForDelete.Find(m_iAlertDataScoreHighestIndex) == INDEX_NONE )
		{
			AlertDataMarkedForDelete.AddItem(m_iAlertDataScoreHighestIndex);
		}
	}
	else
	{
		`RedScreen("BT_MarkAlertDataForDeletion accessing invalid alert data.  (No alert data stack is active) @acheng");
	}
}

function bool GetAlertData(out AlertData Data_out)
{
	local int iDataID;
	local XComGameState_AIUnitData AIUnitData;

	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
	if( iDataID > 0 )
	{
		AIUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));
		if( AIUnitData != None )
		{
			if( m_iAlertDataIter > INDEX_NONE &&  m_iAlertDataIter < AIUnitData.m_arrAlertData.Length )
			{
				Data_out = AIUnitData.m_arrAlertData[m_iAlertDataIter];
				return true;
			}
			else if( m_iAlertDataScoreHighestIndex > INDEX_NONE &&  m_iAlertDataScoreHighestIndex < AIUnitData.m_arrAlertData.Length )
			{
				Data_out = AIUnitData.m_arrAlertData[m_iAlertDataScoreHighestIndex];
				return true;
			}
			else
			{
				`RedScreen(GetFuncName()@"accessing invalid alert data.  (No alert data stack or top alert data selected) @acheng");
			}
		}
	}
	return false;
}

// Return true if this unit can see the current alert data tile in the alert data stack.
function bool BT_AlertDataTileIsVisible()
{
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		return class'X2TacticalVisibilityHelpers'.static.CanUnitSeeLocation(m_kUnit.ObjectID, Data.AlertLocation);
	}

	return false;
}

function bool BT_SetNextAlertData()
{
	local XComGameState_AIUnitData kUnitData;
	local int iDataID;

	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
	if( iDataID > 0 )
	{
		kUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));

		if( (kUnitData.m_arrAlertData.Length == 0) || (m_iAlertDataIter + 1 >= kUnitData.m_arrAlertData.Length) )
		{
			m_iAlertDataIter = INDEX_NONE;
			return false;
		}

		++m_iAlertDataIter;
		m_iAlertDataScoreCurrent = 0;

		`LogAIBT("CurrAlertData set: Index="$m_iAlertDataIter@ "UnitSource=#"$kUnitData.m_arrAlertData[m_iAlertDataIter].AlertSourceUnitID@"Cause="$kUnitData.m_arrAlertData[m_iAlertDataIter].AlertCause);
		DebugBTScratchText = " ==============================\n";
		DebugBTScratchText $= "Scoring Next Target: #"$m_iAlertDataIter@ "UnitSource=#"$kUnitData.m_arrAlertData[m_iAlertDataIter].AlertSourceUnitID@"Cause="$kUnitData.m_arrAlertData[m_iAlertDataIter].AlertCause@ "\n";

		return true;
	}
	return false;
}

function bool BT_AlertDataIsAbsoluteKnowledge()
{
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		return (Data.AlertKnowledgeType == eAKT_Absolute);
	}
	return false;
}

function bool BT_AlertDataWasSoundMade()
{
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		return (Data.AlertRadius > 0);
	}
	return false;
}

function bool BT_AlertDataWasEnemyThere()
{
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		return (Data.AlertKnowledgeType == eAKT_FormerAbsolute);
	}
	return false;
}

function bool BT_AlertDataIsCorpseThere()
{
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		return (Data.AlertCause == eAC_DetectedNewCorpse);
	}
	return false;
}

function bool BT_AlertDataIsAggressive()
{
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		return Data.bWasAggressive;
	}
	return false;
}

function bool BT_HasValidAlertDataLocation()
{
	return (m_iAlertDataScoreHighestIndex != INDEX_NONE);
}

function int BT_GetAlertDataAge()
{
	local int Age;
	local XComGameState_Player ControllingPlayer;
	local AlertData Data;

	if( GetAlertData(Data) )
	{
		ControllingPlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
		Age = ControllingPlayer.PlayerTurnCount - Data.PlayerTurn;
		`assert(Age >= 0);
	}
	return Age;
}

function int BT_GetAlertDataRadius()
{
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		return Data.AlertRadius;
	}
	return 0;
}

// dkaplan: removed 3/23/15
//function int BT_GetAlertDataDistanceAtTimeOfAlert()
//{
//	local XComGameState_AIUnitData kUnitData;
//	local int iDataID;
//	local TTile AlertLocTile, UnitLocTile;
//	local vector AlertLocVec, UnitLocVec;
//	local XComWorldData World;
//
//	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
//	kUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));
//	World = `XWORLD;
//
//	AlertLocTile = kUnitData.m_arrAlertData[m_iAlertDataIter].AlertLocation;
//	UnitLocTile = kUnitData.m_arrAlertData[m_iAlertDataIter].UnitLocationAtTimeOfAlert;
//	AlertLocVec = World.GetPositionFromTileCoordinates(AlertLocTile);
//	UnitLocVec = World.GetPositionFromTileCoordinates(UnitLocTile);
//
//	return `UNITSTOMETERS(vSize(AlertLocVec - UnitLocVec));
//}

function int BT_GetAlertDataDistance()
{
	local AlertData Data;
	local float fDist;
	local TTile TileLoc;
	local XComWorldData XWorld;

	XWorld = `XWORLD;
	if( GetAlertData(Data) )
	{
		TileLoc = Data.AlertLocation;
		fDist = VSize(XWorld.GetPositionFromTileCoordinates(TileLoc)-XWorld.GetPositionFromTileCoordinates(UnitState.TileLocation));
		fDist = `UNITSTOMETERS(fDist);
	}
	else
	{
		`LogAI("Error - Invalid AlertData!  returning 0 for GetAlertDataDistance!");
	}
	
	return fDist;
}

function int BT_GetAlertCount()
{
	local XComGameState_AIUnitData kUnitData;
	local int iDataID;

	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
	kUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));
	if( kUnitData != None )
	{
		return kUnitData.m_arrAlertData.Length;
	}
	return 0;
}

function bool BT_AlertDataIsType(String AlertTypeCheck)
{
	local String AlertCauseString;
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		AlertCauseString = Caps(String(Data.AlertCause));
		if( InStr(AlertCauseString, Caps(AlertTypeCheck)) != -1 ) // Contains string in enum name
		{
			return true;
		}
	}
	return false;
}

function bool BT_AlertDataHasTag(String TagString)
{
	local AlertData Data;
	if( GetAlertData(Data) )
	{
		return Data.KismetTag ~= TagString;
	}
	else
	{
		`LogAI("Error - Invalid AlertData!  Returning false for BT_AlertDataHasTag("$TagString$")");
	}
	return false;
}

function BT_AddToAlertDataScore(int iScore)
{
	m_iAlertDataScoreCurrent += iScore;
	if( iScore < 0 )
	{
		DebugBTScratchText @= `BEHAVIORTREEMGR.GetLeafParentName()@" . . . "$iScore @"\n";
	}
	else
	{
		DebugBTScratchText @= `BEHAVIORTREEMGR.GetLeafParentName()@" . . . +"$iScore @ "\n";
	}
}

function BT_UpdateBestAlertData()
{	
	`LogAIBT(DebugBTScratchText);
	`LogAIBT("- - -  Total Score = "@m_iAlertDataScoreCurrent);
	if( m_iAlertDataScoreCurrent > m_iAlertDataScoreHighest )
	{
		m_iAlertDataScoreHighestIndex = m_iAlertDataIter;
		m_iAlertDataScoreHighest = m_iAlertDataScoreCurrent;
	}
	if( m_iAlertDataScoreHighest >= 0 )
	{
		`LogAIBT("  -- Best: Alert: Alert Data Index# "$m_iAlertDataScoreHighestIndex@" ("$m_iAlertDataScoreHighest$")\n");
	}
	else
	{
		`LogAIBT("  -- Best: Unit: NONE\n");
	}
}

function BT_AlertDataMovementUseCover()
{	
	m_bAlertDataMovementUseCover = true;
}

function bool BT_FindAlertDataMovementDestination()
{
	local vector vDest;
	local XComGameState_AIUnitData kUnitData;
	local int iDataID;
	local XComWorldData World;
	local TTile AlertTileLocation, DestinationTile;
	local bool bHasValidDestination;

	m_bAlertDataMovementDestinationSet = false;

	if (m_iAlertDataScoreHighestIndex == INDEX_NONE)
	{
		`RedScreen("Selected Alert Data via Behavior Tree is not valid. This needs to be selected to use AlertDataMovement!\n\nSkipping this unit's turn. (Unit "$UnitState.ObjectID$")");
		return false;
	}
	World = `XWORLD;

	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
	if( iDataID > 0 )
	{
		kUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));
		AlertTileLocation = kUnitData.m_arrAlertData[m_iAlertDataScoreHighestIndex].AlertLocation;
		vDest = World.GetPositionFromTileCoordinates(AlertTileLocation);
		if (HasValidDestinationToward(vDest, vDest, m_bBTCanDash))
		{
			bHasValidDestination = true;
			if (m_bAlertDataMovementUseCover)
			{
				// Moving towards the Alert Data Location but prioritize cover to known enemies and the location
				if (!GetClosestCoverLocation(vDest, vDest,,true))
				{
					bHasValidDestination = false;
					`LogAIBT("BT_FindAlertDataMovementDestination Unit#"$m_kUnit.ObjectID$" Failed to find any valid cover destination towards alert at ("$AlertTileLocation.X@ AlertTileLocation.Y@ AlertTileLocation.Z$")");
				}
			}

			DestinationTile = World.GetTileCoordinatesFromPosition(vDest);
			if (bHasValidDestination && UnitState.TileLocation != DestinationTile)
			{
				m_vAlertDataMovementDestination = vDest;
				`LogAIBT("BT_FindAlertDataMovementDestination Unit#"$m_kUnit.ObjectID$" Found destination:  ("$m_vAlertDataMovementDestination.X@ m_vAlertDataMovementDestination.Y@ m_vAlertDataMovementDestination.Z$")");
				m_bAlertDataMovementDestinationSet = true;
			}
		}
		else
		{
			`LogAIBT("BT_FindAlertDataMovementDestination Unit#"$m_kUnit.ObjectID$" Failed to find any valid destination towards alert at ("$AlertTileLocation.X@ AlertTileLocation.Y@ AlertTileLocation.Z$")");
		}
		return m_bAlertDataMovementDestinationSet;
	}
	return false;
}

function bool BT_HandleOrangeAlertMovement()
{
	local int iAlertLevel;
	iAlertLevel = UnitState.GetCurrentStat(eStat_AlertLevel);
	if (iAlertLevel == 1)
	{
		m_strBTAbilitySelection = 'StandardMove';
		return true;
	}

	return false;
}

function bool BT_HandleYellowAlertMovement()
{
	local int iAlertLevel;
	iAlertLevel = UnitState.GetCurrentStat(eStat_AlertLevel);
	if (iAlertLevel == 1)
	{
		m_strBTAbilitySelection = 'StandardMove';
		return true;
	}

	return false;
}

function string BT_GetLastAbilityName()
{
	local String LastAbilityUsed;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local XComGameState_Ability AbilityState;   

	// Check if we have the last ability used cached here locally.
	if( SelectedAbility.AbilityObjectRef.ObjectID > 0 )
	{
		LastAbilityUsed = GetAbilityName(SelectedAbility);
		if( LastAbilityUsed != "" )
		{
			return LastAbilityUsed;
		}
	}

	// Otherwise step through history and find last enemy that used an ability.
	History = `XCOMHISTORY;
	foreach History.IterateContextsByClassType(class'XComGameStateContext_Ability', Context)
	{
		if( Context.InputContext.SourceObject.ObjectID == UnitState.ObjectID )
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
			if( AbilityState.IsAbilityInputTriggered() )
			{
				return String(Context.InputContext.AbilityTemplateName);
			}
		}
	}

	// None found.  Return empty string.
	return LastAbilityUsed;
}

function int BT_GetSuppressorCount()
{
	if( UnitState.IsUnitAffectedByEffectName(class'X2Effect_Suppression'.default.EffectName) )
	{
		return UnitState.GetSuppressors();
	}
	return 0;
}
function bool BT_SetSuppressorStack()
{
	local array<StateObjectReference> Suppressors;
	local StateObjectReference UnitRef;
	local string DebugText;

	ActiveBTStack.Length = 0;
	CurrentBTStackRef.ObjectID = INDEX_NONE;

	UnitState.GetSuppressors(Suppressors);
	foreach Suppressors(UnitRef)
	{
		ActiveBTStack.AddItem(UnitRef);
		DebugText @= UnitRef.ObjectID;
	}
	`LogAIBT("SetSuppressorStack results- Added:"@DebugText$"\n");
	return ActiveBTStack.Length > 0;
}

function bool BT_SetNextSuppressor()
{
	if( ActiveBTStack.Length == 0 )
		return false;
	CurrentBTStackRef = ActiveBTStack[0];
	ActiveBTStack.Remove(0, 1);
	`LogAIBT("SetNextSuppressor: Unit# "$CurrentBTStackRef.ObjectID@"\n");
	return true;
}

function int BT_GetOverwatcherCount( bool bCountAllies=false )
{
	local array<StateObjectReference> Overwatchers;
	local array<StateObjectReference> VisibleEnemies;
	local StateObjectReference UnitRef;
	local int Count;
	local array<Name> OverwatchTypes;

	if( bCountAllies )
	{
		return GetNumOverwatchingAllies();
	}

	OverwatchTypes.AddItem(class'X2Effect_ReserveOverwatchPoints'.default.ReserveType); // Add basic overwatch.
	OverwatchTypes.AddItem(class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint);// Include Pistol Overwatch in overwatch checks.
	OverwatchTypes.AddItem(class'X2Ability_SharpshooterAbilitySet'.default.KillZoneReserveType);// Include Killzone in overwatch checks.
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(UnitState.ObjectID, VisibleEnemies);
	class'X2TacticalVisibilityHelpers'.static.GetOverwatchingEnemiesOfTarget(UnitState.ObjectID, Overwatchers, , true, OverwatchTypes);
	foreach Overwatchers(UnitRef)
	{
		if( VisibleEnemies.Find('ObjectID', UnitRef.ObjectID) != INDEX_NONE )
		{
			Count++;
		}
	}
	return Count;
}

function bool BT_SetOverwatcherStack()
{
	local array<StateObjectReference> Overwatchers;
	local array<StateObjectReference> VisibleEnemies;
	local StateObjectReference UnitRef;
	local string DebugText;
	local array<Name> OverwatchTypes;

	ActiveBTStack.Length = 0;
	CurrentBTStackRef.ObjectID = INDEX_NONE;

	OverwatchTypes.AddItem(class'X2Effect_ReserveOverwatchPoints'.default.ReserveType); // Add basic overwatch.
	OverwatchTypes.AddItem(class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint);// Include Pistol Overwatch in overwatch checks.
	OverwatchTypes.AddItem(class'X2Ability_SharpshooterAbilitySet'.default.KillZoneReserveType);// Include Killzone in overwatch checks.

	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(UnitState.ObjectID, VisibleEnemies);
	class'X2TacticalVisibilityHelpers'.static.GetOverwatchingEnemiesOfTarget(UnitState.ObjectID, Overwatchers, , true, OverwatchTypes);
	foreach Overwatchers(UnitRef)
	{
		if( VisibleEnemies.Find('ObjectID', UnitRef.ObjectID) != INDEX_NONE )
		{
			ActiveBTStack.AddItem(UnitRef);
			DebugText @= UnitRef.ObjectID;
		}
	}
	`LogAIBT("SetOverwatcherStack results- Added:"@DebugText$"\n");
	return ActiveBTStack.Length > 0;
}

function bool BT_SetNextOverwatcher()
{
	if( ActiveBTStack.Length == 0 )
		return false;
	CurrentBTStackRef = ActiveBTStack[0];
	ActiveBTStack.Remove(0, 1);
	`LogAIBT("SetNextOverwatcher: Unit# "$CurrentBTStackRef.ObjectID@"\n");
	return true;
}

function int GetNumOverwatchingAllies()
{
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit Unit;
	local int OverwatchersCount;
	m_kUnit.m_kPlayer.GetPlayableUnits(Units);
	foreach Units(Unit)
	{
		if( Unit.ObjectID == UnitState.ObjectID )
		{
			continue;
		}
		if( Unit.NumAllReserveActionPoints() > 0 )
		{
			++OverwatchersCount;
		}
	}
	return OverwatchersCount;
}

function int BT_GetGroupSize()
{
	local XComGameState_AIGroup Group;
	Group = GetGroupState();
	if( Group != None )
	{
		return Group.m_arrMembers.Length;
	}
	return 0;
}

function int BT_GetTargetSelectedThisTurnCount()
{
	if( m_kBTCurrTarget.TargetID <= 0 )
	{
		`RedScreen("Error - called BT_GetTargetSelectedThisTurnCount() when no valid target is in the target stack.");
	}
	if(m_kPlayer != None )
	{
		return m_kPlayer.GetNumTimesUnitTargetedThisTurn(m_kBTCurrTarget.TargetID);
	}
	return 0;
}

// Search for an ability name, or output all valid ability names if not found.
function bool FindOrGetAbilityList(Name TargetName, out array<Name> AbilityNames)
{
	local XComGameStateHistory History;
	local AvailableAction kAbility;
	local XComGameState_Ability AbilityState;
	local Name AbilityName;
	local int HistoryIndex;
	History = `XCOMHISTORY;
	HistoryIndex = History.GetCurrentHistoryIndex();

	if( CachedAbilityNames.HistoryIndex == HistoryIndex )
	{
		AbilityNames = CachedAbilityNames.NameList;
		if( AbilityNames.Find(TargetName) != INDEX_NONE )
		{
			return true;
		}
		return false;
	}

	foreach UnitAbilityInfo.AvailableActions(kAbility)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(kAbility.AbilityObjectRef.ObjectID));
		AbilityName = AbilityState.GetMyTemplateName();
		if( AbilityName == TargetName )
		{
			return true;
		}
		AbilityNames.AddItem(AbilityName);
	}
	AddCachedAbilityNameList(AbilityNames, HistoryIndex);
	return false;
}

function AddCachedAbilityNameList(array<Name> AbilityNames, int HistoryIndex)
{
	CachedAbilityNames.NameList = AbilityNames;
	CachedAbilityNames.HistoryIndex = HistoryIndex;
}


//------------------------------------------------------------------------------------------------
// END BEHAVIOR TREE SUPPORT.
//------------------------------------------------------------------------------------------------
// Return the name of the ability given a targeting profile name, if it exists.
function Name GetAbilityFromTargetingProfile(Name ProfileName, optional out AoETargetingInfo Profile_out)
{
	local int ProfileIndex; 
	local Name Ability;
	ProfileIndex = AoEProfiles.Find('Profile', ProfileName);
	if( ProfileIndex != INDEX_NONE )
	{
		Profile_out = AoEProfiles[ProfileIndex];
		Ability = Profile_out.Ability;
		// Use equivalent ability name when needed.
		class'X2AIBTLeafNode'.static.ResolveAbilityNameWithUnit(Ability, self);
		Profile_out.Ability = Ability;
	}
	return Ability;
}
function TTile GetClosestTile(const out array<TTile> TileList, vector ClosestToPoint=GetGameStateLocation())
{
	local float Dist, MinDist;
	local int ClosestIndex, i, Count;
	local vector Position, CurrLocation;
	local XComWorldData XWorld;
	CurrLocation = ClosestToPoint;
	ClosestIndex = INDEX_NONE;
	Count = TileList.Length;
	XWorld = `XWORLD;
	for (i=0; i<Count; i++)
	{
		Position = XWorld.GetPositionFromTileCoordinates(TileList[i]);
		Dist = VSizeSq(Position - CurrLocation);
		if( ClosestIndex == INDEX_NONE || Dist < MinDist )
		{
			ClosestIndex = i;
			MinDist = Dist;
		}
	}
	return TileList[ClosestIndex];
}
// Attempt to find a valid AoE target location, given an AoE profile.
// Profile specifies who to target, and what conditions cause a target location to fail.
//------------------------------------------------------------------------------------------------
simulated function bool FindAoETarget(Name ProfileName)
{
	local AoETargetingInfo Profile;
	local array<TTile> TargetList; // List of potential target locations;
	local array<TTile> FailOnHitList; // List of locations that invalidate a potential target location.
	local vector TargetLocation;
	local bool bFoundTarget;
	local XComGameState_Ability AbilityState;
	local XComWorldData XWorld;
	local TTile TargetTile;
	local Name AbilityName;
	local XComGameState_Unit RequiredTarget; // Target required to be in the AoE area.
	local TTile RequiredHitLocation, ClosestTarget;
	local X2AbilityMultiTargetStyle TargetStyle;
	local array<TTile> TargetArea, PathableTiles;
	local int TopHitCount, EnemyHits, BadHits;

	XWorld = `XWORLD;
	// Find targeting profile with given Profile Name.
	AbilityName = GetAbilityFromTargetingProfile(ProfileName, Profile);
	bFoundTarget = false;
	if( AbilityName == '' )
	{
		`RedScreen("AI Behavior Tree- FindAoETarget cannot find AoE targeting profile: "$ProfileName@" @acheng");
	}
	else
	{
		FindAbilityByName(AbilityName, AbilityState);
		if( AbilityState == None )
		{
			`RedScreen("AI Behavior Tree- AoE profile ("$ProfileName$") Ability not found: "$AbilityName@" @acheng");
			return false;
		}
		TargetStyle = AbilityState.GetMyTemplate().AbilityMultiTargetStyle;

		// Get all potential AoE targets based on profile settings.
		if( !GetAllAoETargets(TargetList, Profile, RequiredTarget) )
		{
			return false;
		}
		ClosestTarget = GetClosestTile(TargetList);

		if( RequiredTarget != None )
		{
			RequiredHitLocation = RequiredTarget.TileLocation;
		}

		// Get points to avoid. Include destructible Objective locations and teammates if friendly fire is to be avoided.
		GetAoEAvoidancePoints(FailOnHitList, Profile); 

		if( Profile.bPathToTarget )
		{
			m_kUnit.m_kReachableTilesCache.GetAllPathableTiles(PathableTiles);
			if( PathableTiles.Length == 0 )
			{
				return false;
			}
		}

		// Start with largest group, looking for a valid midpoint target. If none found, remove furthest from group and repeat.
		while( TargetList.Length >= Profile.MinTargets && TargetList.Length > 0)
		{
			// Test the center of the target list to see if all units are within the AoE radius.
			TargetTile = GetMidPointTile(TargetList);

			// Only use pathable tiles when specified.
			if( Profile.bPathToTarget )
			{
				TargetLocation = XWorld.GetPositionFromTileCoordinates(TargetTile);
				TargetTile = GetClosestTile(PathableTiles, TargetLocation);
			}

			// Ensure we use a valid ground target location
			if( !Profile.bDoNotTargetGround )
			{
				if( Profile.bRequiresOutdoor )
				{
					// Raise the point to the max Z level and drop it down to the first floor it hits.
					TargetTile.Z = XWorld.NumZ - 1;
				}

				TargetTile.Z = XWorld.GetFloorTileZ(TargetTile, true);
				XWorld.GetFloorPositionForTile(TargetTile, TargetLocation);
			}
			else
			{
				TargetLocation = XWorld.GetPositionFromTileCoordinates(TargetTile);
			}

			TargetArea.Length = 0;
			TargetStyle.GetValidTilesForLocation(AbilityState, TargetLocation, TargetArea);

			EnemyHits = GetNumIntersectingTiles(TargetList, TargetArea);
			BadHits = GetNumIntersectingTiles(FailOnHitList, TargetArea);
			if( EnemyHits == TargetList.Length
			   &&  BadHits == 0 )
			{
				TopAoETarget.Location = TargetLocation;
				TopAoETarget.Ability = AbilityName;
				TopAoETarget.Profile = Profile.Profile;
				bFoundTarget = true;
				`LogAIBT("Found AoE target location that hits "$TargetList.Length@"targets! ");
				break;
			}
			// Keep track of other decent options, but keep looking for better ones.
			else if( EnemyHits >= Profile.MinTargets  && BadHits == 0 && EnemyHits >= TopHitCount)
			{
				TopHitCount = EnemyHits;
				TopAoETarget.Location = TargetLocation;
				TopAoETarget.Ability = AbilityName;
				TopAoETarget.Profile = Profile.Profile;
				bFoundTarget = true;
			}

			// Force the required hit location to stay on the list until there's only that one left.
			if( TargetList.Length > 1 && RequiredTarget != None )
			{
				TargetList.RemoveItem(RequiredHitLocation);
				RemoveFurthestFromCluster(TargetList);
				TargetList.AddItem(RequiredHitLocation);
			}
			else
			{
				// Ideal target not found.  Remove furthest.
				RemoveFurthestFromCluster(TargetList);
			}

			if( TargetList.Length == 1 )
			{
				// Single target change - if we're left with looking at a single target, any target could do. 
				// But pick the closest from the original list, if no other unit is required.
				if( RequiredTarget != None )
				{
					TargetList[0] = RequiredHitLocation;
				}
				else
				{
					TargetList[0] = ClosestTarget;
				}
			}
		}
	}
	return bFoundTarget;
}

// Use absolute knowledge to fill list of game states of known enemies.  
function GetAllKnownEnemyStates(optional out array<XComGameState_Unit> UnitList, optional out array<StateObjectReference> RefList, bool IncludeCiviliansOnTerrorMaps=false, optional array<Name> ExcludedEffects )
{
	local XGPlayer Player;
	local XComGameState_AIUnitData AIUnitData;
	local array<XComGameState_Unit> TempList;
	local XComGameState_Unit EnemyState;
	local Name EffectName;
	local bool bAffected;

	AIUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(GetAIUnitDataID(m_kUnit.ObjectID)));
	if( AIUnitData != None )
	{
		AIUnitData.GetAbsoluteKnowledgeUnitList(RefList, UnitList, , IncludeCiviliansOnTerrorMaps);
	}
	else
	{
		Player = `BATTLE.GetEnemyPlayer(m_kUnit.m_kPlayer);
		Player.GetPlayableUnits(UnitList);
	}

	if( ExcludedEffects.Length > 0 )
	{
		TempList = UnitList;
		UnitList.Length = 0;
		foreach TempList(EnemyState)
		{
			bAffected = false;
			foreach ExcludedEffects(EffectName)
			{
				if( EnemyState.IsUnitAffectedByEffectName(EffectName) )
				{
					`LogAIBT("Unit"$EnemyState.ObjectID@"is affected by Effect"@EffectName@"\n");
					bAffected = true;
					break;
				}
			}
			if( !bAffected )
			{
				`LogAIBT("Unit #"$EnemyState.ObjectID@"is NOT affected by any effects specified!\n");
				UnitList.AddItem(EnemyState);
			}
		}
	}
}

// Populate list of targets based on a given AoE Targeting profile
function bool GetAllAoETargets(out array<TTile> TargetList, AoETargetingInfo Profile, out XComGameState_Unit RequiredTarget, bool bVisibleOnly=false)
{
	local XGBattle Battle;
	local XGPlayer Player;
	local array<XComGameState_Unit> UnitList;
	local XComGameState_Unit TargetState;
	local AvailableTarget Target;
	local XComGameState_Ability AbilityState;
	Battle = `BATTLE;

	if( Profile.bRequirePotentialTarget )
	{
		if( BT_HasTargetOption('Potential', Target) )
		{
			RequiredTarget = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.PrimaryTarget.ObjectID));
		}
		if( RequiredTarget == None )
		{
			`LogAIBT("AoE Finder failed in GetAllAoETargets: AoE profile requires potential target. No potential target found.");
			return false;
		}
	}

	if( Profile.bTargetEnemy )
	{
		GetAllKnownEnemyStates(UnitList);
	}

	if( Profile.bTargetAllies )
	{
		Player = m_kUnit.m_kPlayer;
		Player.GetPlayableUnits(UnitList);
	}

	if( Profile.bTargetCivilians )
	{
		Player = XGBattle_SP(Battle).GetCivilianPlayer();
		Player.GetPlayableUnits(UnitList);
	}

	if( Profile.bTargetCorpses )
	{
		// Get allied corpses.
		Player = m_kUnit.m_kPlayer;
		Player.GetDeadUnits(UnitList, true);
		// Get Enemy corpses.
		Player = Battle.GetEnemyPlayer(m_kUnit.m_kPlayer);
		Player.GetDeadUnits(UnitList, true);
		// Get Civilian corpses.
		Player = XGBattle_SP(Battle).GetCivilianPlayer();
		Player.GetDeadUnits(UnitList, true);
	}

	if( Profile.bTargetSelf )
	{
		if( UnitList.Find(UnitState) == INDEX_NONE )
		{
			UnitList.AddItem(UnitState);
		}
	}
	if( Profile.bTestLocationValidity )
	{
		FindAbilityByName(Profile.Ability, AbilityState);
	}

	foreach UnitList(TargetState)
	{
		if( Profile.bTestLocationValidity )
		{
			Target.AdditionalTargets.Length = 0;
			AbilityState.GatherAdditionalAbilityTargetsForLocation(TopAoETarget.Location, Target);
			if( Target.AdditionalTargets.Length == 0 )
			{
				continue;
			}
		}
		if( !TargetState.GetMyTemplate().bIsCosmetic // Skip gremlins from being considered in AoE attacks.
		       && !TargetState.IsIncapacitated()   // Skip bleeding out / unconscious / Stasis lanced.
			   && !TargetState.IsConcealed() )      // Do not consider units we should not be able to see.
		{
			if (!bVisibleOnly || class'X2TacticalVisibilityHelpers'.static.CanUnitSeeLocation(UnitState.ObjectID, TargetState.TileLocation))
			{
				TargetList.AddItem(TargetState.TileLocation);
			}
		}
	}
	return TargetList.Length > 0;
}

// Populate list of target locations to avoid based on a given AoE Targeting profile
function GetAoEAvoidancePoints(out array<TTile> AvoidanceList, AoETargetingInfo Profile)
{
	local array<XComGameState_Unit> Allies;
	local XComGameState_Unit TargetState;
	local XComWorldData XWorld;
	local XComGameState_AIPlayerData AIPlayerData;
	local XComGameState_InteractiveObject Objective;
	local XComGameState_BattleData BattleData;
	local vector Loc;
	local TTile Tile;

	XWorld = `XWORLD;
	if( Profile.bFailOnFriendlyFire ) // Add all allies.
	{
		m_kUnit.m_kPlayer.GetPlayableUnits(Allies);
		foreach Allies(TargetState)
		{
			if( TargetState.ObjectID == UnitState.ObjectID && Profile.bIgnoreSelfDamage )
			{
				continue;
			}
			AvoidanceList.AddItem(TargetState.TileLocation);
		}
	}
	 
	if ( Profile.bFailOnObjectiveFire ) 
	{  
		AIPlayerData = GetAIPlayerData();
		//  If we have a 'Priority Target Object' set by Kismet, that means our objective should be attacked, so skip this check.
		if( !AIPlayerData.HasPriorityTargetObject(Objective) && `TACTICALMISSIONMGR.GetObjectivesCenterPoint(Loc) )
		{
			// Otherwise always avoid attacking the objective location.
			BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
			Tile = XWorld.GetTileCoordinatesFromPosition(BattleData.MapData.ObjectiveLocation);
			AvoidanceList.AddItem(Tile);
		}
	}

	// Avoid hitting the same tile multiple times in one turn.
	if( m_kPlayer != None )
	{
		foreach m_kPlayer.AoETargetedThisTurn(Tile)
		{
			AvoidanceList.AddItem(Tile);
		}
	}
}

//------------------------------------------------------------------------------------------------
// AoE helper functions.  Pull furthest point from a group of locations.
function RemoveFurthestFromCluster(out array<TTile> Cluster)
{
	local TTile Loc;
	Loc = GetFurthestFromSet(Cluster);
	Cluster.RemoveItem(Loc);
}

//------------------------------------------------------------------------------------------------
// AoE helper function.  Find center point given a group of locations.
native simulated function TTile GetMidPointTile(array<TTile> TileSet);
simulated function vector GetMidPointV(array<vector> arrLoc)
{
	local vector vMinLoc, vMaxLoc, vCenter, vLoc;
	vMinLoc = arrLoc[0];
	vMaxLoc = arrLoc[0];
	foreach arrLoc(vLoc)
	{
		vMinLoc.X = Min(vLoc.X, vMinLoc.X);
		vMinLoc.Y = Min(vLoc.Y, vMinLoc.Y);
		vMinLoc.Z = Min(vLoc.Z, vMinLoc.Z);

		vMaxLoc.X = Max(vLoc.X, vMaxLoc.X);
		vMaxLoc.Y = Max(vLoc.Y, vMaxLoc.Y);
		vMaxLoc.Z = Max(vLoc.Z, vMaxLoc.Z);
	}
	vCenter = (vMinLoc + vMaxLoc) / 2;
	return vCenter;
}

//------------------------------------------------------------------------------------------------
// Support for finding AoE target locations.
native function int GetNumIntersectingTiles(array<TTile> TileSetA, array<TTile> TileSetB);

//------------------------------------------------------------------------------------------------
// Sums up all manhattan distances between this unit and others.  Used to determine furthest unit from set.
simulated function int GetFurthestScore(TTile Source, array<TTile> arrSet)
{
	local TTile Tile, DistTile;
	local int TotalManhattanDist;
	TotalManhattanDist = 0;
	foreach arrSet(Tile)
	{
		if( Tile == Source )
			continue;

		DistTile.X = Tile.X - Source.X;
		DistTile.Y = Tile.Y - Source.Y;
		TotalManhattanDist += abs(DistTile.X) + abs(DistTile.Y);
	}
	return TotalManhattanDist;
}
//------------------------------------------------------------------------------------------------
simulated function TTile GetFurthestFromSet(array<TTile> arrSet)
{
	local TTile Tile, Furthest;
	local int Dist, Largest;
	Largest = -1.0f;
	foreach arrSet(Tile)
	{
		Dist = GetFurthestScore(Tile, arrSet);
		if( Dist > Largest )
		{
			Largest = Dist;
			Furthest = Tile;
		}
	}
	return Furthest;
}
// Return nearest enemy to the specified location.
function XComGameState_Unit GetNearestKnownEnemy(vector vLocation, optional out float fClosestDistSq, optional array<GameRulesCache_VisibilityInfo> EnemyInfos, bool IncludeCiviliansOnTerrorMaps=true)
{
	local XComGameState_AIUnitData kUnitData;
	local int iDataID;
	local array<StateObjectReference> arrKnownEnemyList;
	local StateObjectReference kEnemyRef;
	local XComGameStateHistory History;
	local XComGameState_Unit kEnemy, kClosest;
	local vector vAlertLocation;
	local float fDistSq;
	local GameRulesCache_VisibilityInfo VisInfo;
	History = `XCOMHISTORY;

	// Use pre-existing info if available.
	if( EnemyInfos.Length > 0 )
	{
		foreach EnemyInfos(VisInfo)
		{
			if( kClosest == None || VisInfo.DefaultTargetDist < fClosestDistSq )
			{
				kClosest = XComGameState_Unit(History.GetGameStateForObjectID(VisInfo.SourceID));
				fClosestDistSq = VisInfo.DefaultTargetDist;
			}
		}
		return kClosest;
	}

	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
	if( iDataID > 0 )
	{
		kUnitData = XComGameState_AIUnitData(History.GetGameStateForObjectID(iDataID));
		if( kUnitData != None )
		{
			kUnitData.GetAbsoluteKnowledgeUnitList(arrKnownEnemyList,,,IncludeCiviliansOnTerrorMaps);
			foreach arrKnownEnemyList(kEnemyRef)
			{
				kEnemy = XComGameState_Unit(History.GetGameStateForObjectID(kEnemyRef.ObjectID));
				if( kEnemy.GetTeam() == eTeam_Neutral && kEnemy.IsAlien() )
				{
					continue; // Don't consider faceless civilians in this check.
				}
				vAlertLocation = `XWORLD.GetPositionFromTileCoordinates(kEnemy.TileLocation);
				fDistSq = VSizeSq(vAlertLocation - vLocation);
				if( kClosest == None || fDistSq < fClosestDistSq )
				{
					kClosest = kEnemy;
					fClosestDistSq = fDistSq;
				}
			}
		}
	}
	
	if( kUnitData == None ) // This unit may not have AIUnitData if it is mind-controlled.
	{
		class'X2TacticalVisibilityHelpers'.static.GetClosestVisibleEnemy(UnitState.ObjectID, VisInfo);
		if( VisInfo.SourceID > 0 )
		{
			fClosestDistSq = VisInfo.DefaultTargetDist;
			kClosest = XComGameState_Unit(History.GetGameStateForObjectID(VisInfo.SourceID));
			return kClosest;
		}
	}
	return kClosest;
}
//------------------------------------------------------------------------------------------------

function UpdateSightRange()
{
	m_fSightRangeSq = Square(`METERSTOUNITS(UnitState.GetVisibilityRadius()+3));// Added 3m sight range buffer.
}

function AvailableTarget FindAvailableTarget( int ObjectID, AvailableAction kAbility )
{
	local AvailableTarget kTarget, kNone;
	if (kAbility.AbilityObjectRef.ObjectID > 0 && kAbility.AvailableCode == 'AA_Success' && kAbility.AvailableTargets.Length > 0)
	{
		foreach kAbility.AvailableTargets(kTarget)
		{
			if (kTarget.PrimaryTarget.ObjectID == ObjectID)
			{
				return kTarget;
			}
		}
	}

	`Warn("XGAIBehavior::FindAvailableTarget - no target"@ObjectID@"found for ability"@GetAbilityName(kAbility));
	return kNone;

}

function AvailableTarget FindAvailableTargetByName( int iObjectID, Name strAbility )
{
	local AvailableAction kAbility;
	local AvailableTarget kTarget;
	kAbility = FindAbilityByName( strAbility );
	if (kAbility.AbilityObjectRef.ObjectID > 0)
	{
		kTarget = FindAvailableTarget(iObjectID, kAbility);
	}
	return kTarget;
}

function LogAvailableAbilities()
{
	local AvailableAction kAbility;
	local XComGameState_Ability kAbilityState;
	local XComGameStateHistory kHistory;
	//	local name kAbilityName;

	kHistory = `XCOMHISTORY;

	`LogAI("Logging available abilities for unit"@UnitState.ObjectID@" Ability cached from History Index"@m_iUnitAbilityCacheHistoryIndex);
	foreach UnitAbilityInfo.AvailableActions(kAbility)
	{
		kAbilityState = XComGameState_Ability(kHistory.GetGameStateForObjectID( kAbility.AbilityObjectRef.ObjectID ));
		`LogAI("AvailableAction:"@kAbilityState.GetMyTemplateName()@"Status="$kAbility.AvailableCode);
	}
}
//------------------------------------------------------------------------------------------------
function ResetErrorCheck()
{
	m_strDebugLog="Turn #"$`BATTLE.m_iPlayerTurn@" Unit:"@m_kUnit@" Behavior:"@self;
	m_iErrorCheck = 10;
}
//------------------------------------------------------------------------------------------------
function UpdateErrorCheck()
{
	m_iErrorCheck--;
	if (m_iErrorCheck <= 0)
	{
		m_bAbortMove=true;
		`Warn("XGAIBehavior failed on error check- too many iterations!");
		`Log("Failsafe break triggered!  AI Log:\n"@m_strDebugLog);

		GotoState('EndOfTurn');
	}
}
function RefreshUnitCache()
{
	// Refresh UnitState, AbilityInfo cache.  Must be refreshed after each action used.
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kUnit.ObjectID));	
	InitUnitAbilityInfo();
}

function Init( XGUnit kUnit )
{
	//local float fAggroRange;
	//local name strBTRoot;
	m_kUnit = kUnit;

	//@TODO - acheng - X-Com 2 conversion
	//m_kUnit should be getting set from the unit state, but for now this will work
	RefreshUnitCache();
	InitUnitAbilityInfo();

	DebugInit();    // debug
	m_kPlayer = XGAIPlayer(m_kUnit.GetPlayer());
	ResetErrorCheck();

	if (!kUnit.m_bSubsystem)
	{
		//strBTRoot = GetBehaviorTreeRoot();
		//if (strBTRoot != '')
		//{
		//	`Assert( m_kBehaviorTree == None || m_kBehaviorTree.m_eStatus != BTS_RUNNING ); // Should not be changing the behavior tree when one is currently running.
		//	//m_kBehaviorTree = `BEHAVIORTREEMGR.GenerateBehaviorTree(strBTRoot, UnitState.GetMyTemplate().CharacterGroupName);
		//}
		ValidateBTWeights();
	}
}

function ValidateBTWeights()
{
	local int iWeightProfile;
	for (iWeightProfile=0; iWeightProfile < m_arrMoveWeightProfile.Length; iWeightProfile++)
	{
		if (m_arrMoveWeightProfile[iWeightProfile].fCloseModifier == 0)
		{
			`RedScreen("File: DefaultAI.ini : Invalid move weight profile fCloseModifier value of 0!  (Divide By Zero error) Resetting to 1.");
			m_arrMoveWeightProfile[iWeightProfile].fCloseModifier = 1.0f;
		}
		if (m_arrMoveWeightProfile[iWeightProfile].fFarModifier == 0)
		{
			`RedScreen("File: DefaultAI.ini : Invalid move weight profile fFarModifier value of 0!  (Divide By Zero error) Resetting to 1.");
			m_arrMoveWeightProfile[iWeightProfile].fFarModifier = 1.0f;
		}
	}
}


function name GetBehaviorTreeRoot()
{
	local Name RootName;
	if (UnitState == None)
	{
		RefreshUnitCache();
	}
	if (UnitState != None && UnitState.GetMyTemplate() != None)
	{
		RootName = Name(UnitState.GetMyTemplate().strBehaviorTree);
		if( `BEHAVIORTREEMGR.IsValidBehavior(RootName) )
		{
			return RootName;
		}
	}
	return '';
}

function bool InitUnitAbilityInfo()
{
	local GameRulesCache_Unit kInfo;
	if (!m_bUnitAbilityCacheDirty && m_iUnitAbilityCacheHistoryIndex != `XCOMHISTORY.GetCurrentHistoryIndex())
	{
		m_bUnitAbilityCacheDirty = true;
	}
	if (m_bUnitAbilityCacheDirty && `XCOMGAME.GameRuleset.GetGameRulesCache_Unit(UnitState.GetReference(), kInfo))
	{
		UpdateAbilityInfo(kInfo);
	}
	return !m_bUnitAbilityCacheDirty;
}

function UpdateAbilityInfo(GameRulesCache_Unit kInfo)
{
	UnitAbilityInfo = kInfo;
	m_bUnitAbilityCacheDirty=false;
	m_iUnitAbilityCacheHistoryIndex=`XCOMHISTORY.GetCurrentHistoryIndex();
}

simulated function LoadInit( XGUnit kUnit )
{
	//local XComUnitPawn kPawn;
	m_kUnit = kUnit;
	if (m_kUnit != none)
	{
		SetTickIsDisabled(false);
	}
	m_kPlayer = XGAIPlayer(m_kUnit.GetPlayer());
	DebugInit();
}
//------------------------------------------------------------------------------------------------
simulated function InitTurn( bool UpdateHistoryIndexStart=true )
{
	//RAM - use this to determine whether we have made a decision before we get to the EndTurn state or not. If we have not decided, skip our turn.
	if( UpdateHistoryIndexStart )
	{
		DecisionStartHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	}
	RefreshUnitCache();

	`LogAI(m_kUnit@self@"InitTurn: Action Points = "$ UnitState.NumAllActionPoints());
	UpdateSightRange();
	TopAoETarget.Ability = '';

	UpdateSpreadVars(); // Cache values related to Minimum Spread for destination search.
	UpdateCoverValues(); // Set Full Cover factor value

	m_bCanDash = false;//m_iTurnsUnseen >= MAX_TURNS_UNSEEN_BEFORE_RUSH

	m_bAbortMove=false; // Reset before rebuilding abilities.  This flag is used to see if we should attempt to move again.

	//dramatically increase likelihood to flee if shot.
	m_vDebugDir[0]=vect(0,0,0);
	m_vDebugDir[1]=vect(0,0,0);
	m_kLastAIState=name("-");

	DebugInitTurn();
}
//------------------------------------------------------------------------------------------------
function DebugInitTurn()
{
	// Reset failed pathing data
	m_vFailureBegin = m_kUnit.GetGameStateLocation();
	m_iFailureDest_CP.Length = 0;
	m_iFailureDest_BV.Length = 0;
	m_iFailureDest_UR.Length = 0;
}

function UpdateSpreadVars()
{
	local X2CharacterTemplate Template;
	local int iTile;
	local float MaxTile, SpreadMinDist;
	Template = UnitState.GetMyTemplate();
	
	if( Template.AIMinSpreadDist >= 0 )
	{
		SpreadMinDist = `METERSTOUNITS(Template.AIMinSpreadDist);
	}
	else
	{
		SpreadMinDist = `METERSTOUNITS(DEFAULT_AI_MIN_SPREAD_DISTANCE);
	}
	SpreadMinDistanceSq = Square(SpreadMinDist);
	if( Template.AISpreadMultiplier > 0 )
	{
		SpreadMultiplier = Template.AISpreadMultiplier;
	}
	else
	{
		SpreadMultiplier = DEFAULT_AI_SPREAD_WEIGHT_MULTIPLIER;
	}

	// Set up cached values to specify a spread multiplier based on tile distance- score increases as it gets further away from the enemy.
	SpreadTileDistances.Length = 0;
	SpreadMultiplierPerDistance.Length = 0;
	MaxTile = FCeil(`UNITSTOTILES(SpreadMinDist));
	if( MaxTile > 0 ) 
	{
		for( iTile = 0; iTile < MaxTile; ++iTile )
		{
			SpreadTileDistances.AddItem(Square(`TILESTOUNITS(iTile + 1.415f))); // Square unit distances per tile. Starts at 1 tile distance, +.415 include diagonal in first tier.
			SpreadMultiplierPerDistance.AddItem(iTile*(1.0f - SpreadMultiplier) / MaxTile + SpreadMultiplier); // Increments linearly as it gets further from teammates.
		}
	}
}

function UpdateCoverValues()
{
	if( UnitState.IsGroupLeader() )
	{
		FullCoverFactor = CALC_FULL_COVER_FACTOR_POD_LEADER;
	}
	else
	{
		FullCoverFactor = CALC_FULL_COVER_FACTOR;
	}
}
//------------------------------------------------------------------------------------------------
function DebugLogPathingFailure( Vector vDest, int eReason )
{
	local int iFoundCell;
	local array<int> arrList;
	local int iCell;
	iCell = `XWORLD.GetVisibilityMapTileIndexFromPosition(vDest);

	if (m_iLastFailureAdded == iCell)
		return;

	switch (eReason)
	{
		case ePATHING_FAILURE_COMPUTE_PATH:
			arrList = m_iFailureDest_CP;
		break;
		case ePATHING_FAILURE_BASE_VALIDATOR:
			arrList = m_iFailureDest_BV;
		break;
		case ePATHING_FAILURE_UNREACHABLE:
			arrList = m_iFailureDest_UR;
		break;
	}
	iFoundCell = arrList.Find(iCell);
	if (iFoundCell == -1)
	{
		switch (eReason)
		{
			case ePATHING_FAILURE_COMPUTE_PATH:
				m_iFailureDest_CP.AddItem(iCell);
			break;
			case ePATHING_FAILURE_BASE_VALIDATOR:
				m_iFailureDest_BV.AddItem(iCell);
			break;
			case ePATHING_FAILURE_UNREACHABLE:
				m_iFailureDest_UR.AddItem(iCell);
			break;
		}
		m_iLastFailureAdded = iCell;
	}
}
//------------------------------------------------------------------------------------------------
// Initialization step called from XGAIPlayer.
simulated function InitFromPlayer()
{
	ResetErrorCheck();
	BTVars.Length = 0; // Clear BehaviorTree variables once per turn.
}
//------------------------------------------------------------------------------------------------
function bool CanAoEHit( array<XGUnit> arrTargetList, int iAbilityType )
{
	return false;
}
//------------------------------------------------------------------------------------------------
function float GetAbilityRadius(XComGameState_Ability AbilityState)
{
	local float Radius;
	// Pull damage radius from ability.  (valid for circular / spherical AoE abilities).
	Radius = AbilityState.GetAbilityRadius();

	if( Radius <= 0 ) // i.e. Line = unlimited range.  Return the visibility range so we have something to work with.
	{
		Radius = `METERSTOUNITS(UnitState.GetVisibilityRadius());
	}
	return Radius;
}
//------------------------------------------------------------------------------------------------
// Updated to accept any type of aoe ability profile
function bool CanHitAoETarget( int AbilityObjectID, out AoETarget Target, AoETargetingInfo Profile, bool bIgnoreValidity=false )
{
	local float MaxDist, Dist, HitRange;
	local AvailableAction Ability;
	local XComGameState_Ability AbilityState;
	local array<TTile> TargetList, FailOnHitList, TargetArea;
	local vector MyLoc;
	local XComGameState_Unit RequiredTarget;
	local int TargetsHit, AvoidanceHits;
	local string Error;
	local X2AbilityMultiTargetStyle TargetStyle;

	Ability = FindAbilityByID(AbilityObjectID );
	MyLoc = m_kUnit.GetGameStateLocation();
	if (bIgnoreValidity || IsValidAction(Ability, Error))
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityObjectID));
		TargetStyle = AbilityState.GetMyTemplate().AbilityMultiTargetStyle;
		HitRange = GetAoEHitRange(AbilityState);
		if( HitRange > 0 ) // Negative Throw Range means unrestricted range.
		{
			MaxDist = Square(HitRange);
			Dist = VSizeSq(Target.Location - MyLoc);
			if( Dist >= MaxDist ) // Ensure it is within throw range.
			{
				`LogAIBT("CanHitAoETarget failed - out of hit range.");
				return false;
			}
		}

		if( Profile.bUsePrecomputePath ) // Grenades use precomputed grenade paths.  
		{
			PrecomputeGrenadePath(Ability, Target.Location);
			Target.Location = `PRECOMPUTEDPATH.GetEndPosition();
		}

		// Get all potential AoE targets based on profile settings.
		GetAllAoETargets(TargetList, Profile, RequiredTarget);

		// Get points to avoid. Include destructible Objective locations and teammates if friendly fire is to be avoided.
		GetAoEAvoidancePoints(FailOnHitList, Profile);

		TargetStyle.GetValidTilesForLocation(AbilityState, Target.Location, TargetArea);

		TargetsHit = GetNumIntersectingTiles(TargetList, TargetArea);
		AvoidanceHits = GetNumIntersectingTiles(FailOnHitList, TargetArea);
		if( TargetsHit >= Profile.MinTargets &&  AvoidanceHits == 0 )
		{
			return true;
		}
		else
		{
			`LogAIBT("CanHitAoETarget failed - TargetsHit="$TargetsHit@"Min="$Profile.MinTargets@"AvoidanceHits="$AvoidanceHits);
		}
	}
	else
	{
		`LogAIBT("CanHitAoETarget failed - IsValidAction returned false - error code:"@Error);
	}
	return false;
}
//
//------------------------------------------------------------------------------------------------
//function bool TestPotentialAoEDestination( vector vAoeLocation, float fDamageRadius, optional out array<XGUnit> arrHitUnits, bool bIgnoreSplash=false )
//{
//	return TestPotentialGrenadeDestination( vAoELocation, fDamageRadius, true, bIgnoreSplash );
//	//return m_kPlayer.GetNumTargetsInRange(vAoELocation, Square(fDamageRadius), m_kPlayer.GetAllAoETargets(), arrHitUnits) > 1;
//}
//// Trace to a ground location near the target, see if the new ground location hits our enemies.
////------------------------------------------------------------------------------------------------
//function bool UpdateAoETargetLocation( out AoETarget Target, vector vTraceStart, optional out array<XGUnit> arrHitUnits, bool bIgnoreSplash=false )
//{
//	local TTile kTile;
//	local vector vHitLoc, vHitNormal, vTraceEnd;
//	local actor kHitActor;
//	local float fDamageRadius;
//	// Attempt to find a new destination, tracing toward the initial target and dropping to the ground.
//	vTraceEnd = Target.Location; // Drop endpoint down
//	kHitActor = `XTRACEMGR.XTrace(eXTrace_World, vHitLoc, vHitNormal, vTraceEnd, vTraceStart, vect(1,1,1));
//	if (kHitActor != None)
//	{
//		vHitLoc += vHitNormal * 64; // Push away from hit plane by about a tile.
//		`XWORLD.GetFloorTileForPosition(vHitLoc, kTile, true);
//		// Save floor tile destination as our new target.
//		vHitLoc = `XWORLD.GetPositionFromTileCoordinates(kTile);
//	}
//	else // trace failed.  (No obstructions)  Set destination as ground position.
//	{
//		`XWORLD.GetFloorTileForPosition(Target.Location, kTile, true);
//		vHitLoc = `XWORLD.GetPositionFromTileCoordinates(kTile);
//	}
//
//	fDamageRadius = Target.AoERadius;
//
//	if (TestPotentialAoEDestination( vHitLoc, fDamageRadius, arrHitUnits, bIgnoreSplash))
//	{
//		Target.Location = vHitLoc;
//		return true;
//	}
//	return false;
//}

//------------------------------------------------------------------------------------------------
//function bool UpdateGrenadeDestination( out AoETarget kTarget, XGAbility_Targeted kAbility )
//{
//	local int iX,iY,iZ;
//	local vector vMidpoint, vHitLoc, vHitNormal, vTraceEnd, vTraceStart;
//	local actor kHitActor;
//	// Attempt to find a new destination, tracing toward the initial target and dropping to the ground.
//	vMidpoint = (kTarget.Location + m_kUnit.GetGameStateLocation()) *0.5f;
//	vTraceEnd = kTarget.Location + vect(0,0,-128); // Drop endpoint down
//	vTraceStart = vMidpoint + vect(0,0,256); // raise start point up.
//	kHitActor = `XTRACEMGR.XTrace(eXTrace_World, vHitLoc, vHitNormal, vTraceEnd, vTraceStart, vect(1,1,1));
//	if (kHitActor != None)
//	{
//		vHitLoc += vHitNormal * 64; // Push away from hit plane by about a tile.
//		if (!`XWORLD.GetFloorTileForPosition(vHitLoc, iX, iY, iZ, true))
//			return false;
//
//		// Save floor tile destination as our new target.
//		vHitLoc = `XWORLD.GetPositionFromTileCoordinates(iX, iY, iZ);
//		if (TestPotentialGrenadeDestination( vHitLoc, kAbility.m_kWeapon.GetOverallDamageRadius(), true))
//		{
//			kTarget.Location = vHitLoc;
//			return true;
//		}
//	}
//	else // trace failed.  Set destination as ground position.
//	{
//		`XWORLD.GetFloorTileForPosition(kTarget.Location, iX, iY, iZ, true);
//		kTarget.Location = `XWORLD.GetPositionFromTileCoordinates(iX, iY, iZ);
//		return true;
//	}
//	// Got here means the new grenade destination does not hit more than 1 enemy, or we are hitting one of our own.
//	return false;
//}
////------------------------------------------------------------------------------------------------
simulated function bool PrecomputeGrenadePath( AvailableAction kAction, vector vTargetLoc )
{
	local XComGameState_Ability kAbility;
	local XComGameState_Item kGrenadeItem;
	local XComPrecomputedPath PPath;
	local XComWeapon kWeapon;
	local X2WeaponTemplate kWeaponTemplate;
	local bool bValid;
	kAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID));
	kGrenadeItem = kAbility.GetSourceWeapon();
	kWeapon = XComWeapon(XGWeapon(kGrenadeItem.GetVisualizer()).m_kEntity);
	PPath = `PRECOMPUTEDPATH;
	kWeaponTemplate = X2WeaponTemplate(kGrenadeItem.GetMyTemplate());
	PPath.SetWeaponAndTargetLocation(kWeapon, m_kUnit.m_eTeam, vTargetLoc, kWeaponTemplate.WeaponPrecomputedPathData);
	PPath.CalculateTrajectoryToTarget(kWeaponTemplate.WeaponPrecomputedPathData);
	bValid = PPath.iNumKeyFrames > 0;
	return bValid;
}
//------------------------------------------------------------------------------------------------
simulated function bool IsLocationWithinGrenadeRadius(vector vLoc, vector vGrenadeLoc, float fRadius, optional out float fOutDistSq)
{
	fOutDistSq = VSizeSq2D(vGrenadeLoc - vLoc);
	return fOutDistSq < Square(fRadius);
}

//------------------------------------------------------------------------------------------------
simulated function float GetAoEHitRange( XComGameState_Ability kAbility)
{
	return `METERSTOUNITS(GetAoEHitRangeMeters(kAbility));
}
//------------------------------------------------------------------------------------------------
simulated function int GetAoEHitRangeMeters( XComGameState_Ability kAbility)
{
	local X2AbilityMultiTargetStyle TargetingStyle;
	local X2AbilityMultiTarget_Cone ConeTargetingStyle;
	TargetingStyle = kAbility.GetMyTemplate().AbilityMultiTargetStyle;
	// If this is a cone-multitarget ability, use the cone radius, otherwise use the cursor range on the ability.
	ConeTargetingStyle = X2AbilityMultiTarget_Cone(TargetingStyle);
	if( ConeTargetingStyle != None )
	{
		return ConeTargetingStyle.fTargetRadius;
	}
	else if( TargetingStyle.IsA('X2AbilityMultiTarget_Line') )
	{
		return -1; // Unlimited range.
	}
	return kAbility.GetAbilityCursorRangeMeters();
}
//------------------------------------------------------------------------------------------------
simulated function bool HasPotentialKillShot( optional out AvailableAction kAbility_out)
{
	local AvailableTarget kTarget;
	local XComGameState_Unit kTargetState;

	// TODO- step through all offensive abilities
	kAbility_out = GetShotAbility( true );
	foreach kAbility_out.AvailableTargets(kTarget)
	{
		kTargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));

		if (kTargetState!=None && IsPossibleKillShot(kAbility_out, kTargetState))
		{
			return true;
		}
	}
	return false;
}

//------------------------------------------------------------------------------------------------
simulated function XComGameState_Unit GetNearestVisibleEnemy(optional bool bVisibleToGroup=true)
{
	local GameRulesCache_VisibilityInfo kEnemyInfo, kClosest;
	local XComGameState_Unit kEnemy;
	local XComGameState_AIGroup kGroup;
	local StateObjectReference kUnitRef;
	local float fClosestDist;
	if (bVisibleToGroup)
	{
		kGroup = GetGroupState();
		foreach kGroup.m_arrMembers(kUnitRef)
		{
			class'X2TacticalVisibilityHelpers'.static.GetClosestVisibleEnemy(kUnitRef.ObjectID, kEnemyInfo);
			if (kClosest.TargetID == 0 || kEnemyInfo.DefaultTargetDist < fClosestDist)
			{
				fClosestDist = kEnemyInfo.DefaultTargetDist;
				kClosest = kEnemyInfo;
			}
		}
		if (kClosest.TargetID > 0)
		{
			kEnemy = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kClosest.TargetID));
			return kEnemy;
		}
	}

	class'X2TacticalVisibilityHelpers'.static.GetClosestVisibleEnemy(UnitState.ObjectID, kEnemyInfo);
	kEnemy = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kEnemyInfo.TargetID));
	return kEnemy;
}
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
simulated function OnTakeFire()
{	
	if (m_kPlayer != none)
	{
		m_kPlayer.OnTakeFire(m_kUnit.ObjectID);
	}
}
//------------------------------------------------------------------------------------------------
simulated function OnGuardDeath( XGUnit kUnit ) // Overwritten in elder class.
{
}
//------------------------------------------------------------------------------------------------
simulated function OnDeath( XGUnit kKiller )
{
	if (m_kPlayer.GetActiveUnit() == m_kUnit)
	{
		GotoState('EndOfTurn');
	}
}
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// Debugging functions
//------------------------------------------------------------------------------------------------
simulated function DebugInit()
{
	m_vPathingOffset=vect(0,0,0);
}
//------------------------------------------------------------------------------------------------
simulated function DrawDebugLabel(Canvas kCanvas, out vector vScreenPos)
{
	local XGUnit kUnit;
	local int Index;
	local array<StateObjectReference> OutFlankers;
	local XComGameState_AIGroup kGroup;
	local XComGameState_AIUnitData AIUnitData;
	local String GroupText, JobText;
	local XComGameStateHistory History;

	local string strFlank;
	History = `XCOMHISTORY;
	if( m_kUnit.GetTeam() != eTeam_Alien )
	{
		return;
	}

	if (`CHEATMGR != None && `CHEATMGR.bShowActions)
	{
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
		vScreenPos.Y+= 15;
		if (m_kUnit.IsAliveAndWell())
		{
			if (m_kUnit.GetTeam() == eTeam_Neutral)
			{
				kCanvas.SetDrawColor(210,210,210);
			}
			else
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_kUnit.ObjectID));

				// Draw color is now based on their alert level.
				if (UnitState.GetCurrentStat(eStat_AlertLevel) == 2) 
					kCanvas.SetDrawColor(255,128,128);
				else if (UnitState.GetCurrentStat(eStat_AlertLevel) == 0) 
					kCanvas.SetDrawColor(128,255,128);
				else if (UnitState.GetCurrentStat(eStat_AlertLevel) == 1) 
					kCanvas.SetDrawColor(255,255,128);
				else
					kCanvas.SetDrawColor(255,255,255);
			}
		}
		else
		{
			kCanvas.SetDrawColor(200,200,200);
		}

		// Base text.
		if( AIUnitDataID > 0 )
		{
			AIUnitData = XComGameState_AIUnitData(History.GetGameStateForObjectID(GetAIUnitDataID(m_kUnit.ObjectID)));
		}
		if( AIUnitData != None && AIUnitData.JobIndex != INDEX_NONE )
		{
			JobText = "-"$String(`AIJobMgr.GetJobName(AIUnitData.JobIndex))$"-";
		}
		kGroup = GetGroupState();
		if (kGroup != None)
		{
			GroupText = "Group#"$kGroup.ObjectID;
			if( kGroup.bFallingBack )
			{
				GroupText = GroupText @ "-FALLBACK-";
			}
		}
		else
		{
			GroupText = "(NO Group)";
		}
		kCanvas.DrawText(m_kUnit@"["$UnitState.GetMyTemplateName()$"]"@m_kUnit.ObjectID@GroupText@JobText@ ((m_kPlayer.GetActiveUnit() == m_kUnit) ? "[*ACTIVE*]" : "")@(UnitState.IsTurret() ? string(UnitState.IdleTurretState) : ""));

		kCanvas.SetDrawColor(255,255,255);
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
		vScreenPos.Y+= 15;

		if (`CHEATMGR != None && `CHEATMGR.bShowNamesOnly)
			return;

		class'X2TacticalVisibilityHelpers'.static.GetFlankingEnemiesOfTarget(m_kUnit.ObjectID, OutFlankers);
		if (OutFlankers.Length > 0)
		{
			for( Index = 0; Index < OutFlankers.Length; ++Index )
			{
				kUnit = XGUnit(History.GetVisualizer(OutFlankers[Index].ObjectID));
				strFlank="Flanker="@kUnit$"\n";
			}
		}
		else
			strFlank="";
		kCanvas.DrawText("Last State:"@m_kLastAIState@strFlank);
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
		vScreenPos.Y+= 15;
	}
}
//------------------------------------------------------------------------------------------------
simulated function MakeDebugColor( float fAlpha=1.0f)
{ 
	local int iUnit;
	local float fRed, fBlue, fGreen;

	iUnit = UnitState.ObjectID % 9;
	// Convert integer value into a color value.
	iUnit++; // Skip black.
	if (iUnit >= 8)
	{
		fRed = 0.5f;
		fGreen = 0.5f;
		fBlue = 0.5f;
	}
	if ( (iUnit&1) != 0)
		fRed = 1.0f;
	if ( (iUnit&2) != 0)
		fGreen = 1.0f;
	if ( (iUnit&4) != 0)
		fBlue = 1.0f;
	m_kDebugColor = MakeLinearColor(fRed,fGreen,fBlue,fAlpha);
}
//------------------------------------------------------------------------------------------------
simulated function BeginNewMovePath()
{
}
//------------------------------------------------------------------------------------------------
simulated function OnMoveComplete()
{
	AddToPathHistory(true);
	m_kPlayer.OnMoveComplete(m_kUnit);
}

//------------------------------------------------------------------------------------------------
simulated function OnMoveFailure(string strFail="", bool bSkipOnMoveFailureAction=false)
{
	if (!bSkipOnMoveFailureAction)
	{
		SwitchToAttack(strFail);
	}

	`LogAI("MOVE FAILURE ("$ UnitState.ObjectID $"):"@strFail);
}

//------------------------------------------------------------------------------------------------
simulated function AddToPathHistory( optional bool bPathEnd = false )
{
}
//------------------------------------------------------------------------------------------------
simulated function SetDebugDir( Vector vDir, bool bIsNormalized = false, bool bAlt = false )
{
	if (!bIsNormalized)
	{
		vDir = Normal(vDir);
	}
	if (bAlt)
		m_vDebugDir[1] = vDir;
	else
		m_vDebugDir[0] = vDir;
}
//------------------------------------------------------------------------------------------------
// The Tick fn is essentially for debugging.  should be disabled otherwise. (TODO)
//------------------------------------------------------------------------------------------------
simulated function DebugDrawDestination()
{
	if (`CHEATMGR != None && `CHEATMGR.bShowDestination
		&& VSizeSq2D(m_vDebugDestination - vect(0,0,0)) > 1)
	{
		`SHAPEMGR.DrawSphere( m_vDebugDestination, vect(5,5,80), m_kDebugColor);
	}
}
//------------------------------------------------------------------------------------------------
simulated function DebugDrawPathFailures()
{
	local int iPath;
	local vector vLoc;
	if (`CHEATMGR != None && `CHEATMGR.bDisplayPathingFailures)
	{
		for (iPath=0; iPath<m_iFailureDest_CP.Length; iPath++)
		{
			vLoc = `XWORLD.GetPositionFromTileIndex(m_iFailureDest_CP[iPath]);
			DrawDebugLine(m_vFailureBegin, vLoc, 255,0,0, false);
			`SHAPEMGR.DrawBox(vLoc, vect(10,10,10), MakeLinearColor(1,0,0, 1));
		}
		for (iPath=0; iPath<m_iFailureDest_BV.Length; iPath++)
		{
			vLoc = `XWORLD.GetPositionFromTileIndex(m_iFailureDest_BV[iPath]);
			DrawDebugLine(m_vFailureBegin, vLoc, 255,255,0, false);
			`SHAPEMGR.DrawBox(vLoc, vect(10,10,10), MakeLinearColor(1,1,0, 1));
		}
		for (iPath=0; iPath<m_iFailureDest_UR.Length; iPath++)
		{
			vLoc = `XWORLD.GetPositionFromTileIndex(m_iFailureDest_UR[iPath]);
			DrawDebugLine(m_vFailureBegin, vLoc, 51,255,0, false);
			`SHAPEMGR.DrawBox(vLoc, vect(10,10,10), MakeLinearColor(0.2,1,0, 1));
		}
	}
}
//------------------------------------------------------------------------------------------------
// Draw red-green gradient spheres on all scored locations.
function DebugDrawDestinationScoring()
{
	local XComWorldData World;
	local DebugTileScore Score;
	local SimpleShapeManager Shape;
	local vector TileLoc;
	local LinearColor SphereColor;
	local float Green;
	Shape = `SHAPEMGR;
	World = `XWORLD;
	foreach DebugTileScores(Score)
	{
		TileLoc = World.GetPositionFromTileCoordinates(Score.RawScore.kTile);
		if( Score.bFailAllyLoS
		   || Score.bFailDistance
		   || Score.bFailEnemyLoS
		   || Score.bFailFlanking
		   || Score.bInBadArea
		   || Score.bNotReachable )
		{
			SphereColor = MakeLinearColor(1.0, 0.2, 0.2, 0.5);  // Failures - Red.
		}
		else if( Score.RawScore.kTile == DebugTileScores[0].RawScore.kTile ) // Current tile.  White.
		{
			SphereColor = MakeLinearColor(1, 1, 1, 1);
		}
		else
		{
			// Draw spheres for all weighted scores somewhere between red and green.
			Green = FMax(-1, Score.FinalScore);
			Green = FMin(1, Green);
			Green *= 0.5f;
			SphereColor = MakeLinearColor(0.5f-Green, 0.5f+Green, 0, 1);
		}
		SphereColor.A = 0.5f;
		Shape.DrawSphere(TileLoc, vect(30, 30, 30), SphereColor);
	}
}
// Helper fn to help display tile scores on one line.
function string GetDebugString(ai_tile_score TileScore)
{
	return	"C=" $`TruncFloatString(TileScore.fCoverValue,2)@
			"D=" $`TruncFloatString(TileScore.fDistanceScore,2)@
			"F=" $`TruncFloatString(TileScore.fFlankScore,2)@
			"E=" $`TruncFloatString(TileScore.fEnemyVisibility,2)@
			"E1="$`TruncFloatString(TileScore.fEnemyVisibilityPeak1,2)@
			"A=" $`TruncFloatString(TileScore.fAllyVisibility,2)@
		    "i=" $(TileScore.bCloserThanIdeal ? "Near" : "Far")@
		    "P=" $`TruncFloatString(TileScore.fPriorityDistScore, 2)@
			"R=" $`TruncFloatString(TileScore.fAllyAbilityRangeScore, 2)
			;
}
// Display either all overall weights or move cursor on a specific location to draw details of scoring calculation.
function DebugDrawDestinationScoringText(Canvas kCanvas)
{
	local vector vScreenPos, CursorPos;
	local TTile CursorTile;
	local DebugTileScore Score;
	local float DistScoreNew, DistScoreCurr, DistScoreTotal, ModifierNew, ModifierCurr, IdealRange, PriorityScoreNew, PriorityScoreCurr, PriorityScoreTotal,
				AbilityRangeNew, AbilityRangeCurr, AbilityRangeTotal;
	local ai_tile_score CurrTileScore;
	local bool bSkipCalc;
	local float fDVal, fCVal, fFVal, fEVal, fE1Val, fAVal, fPVal, fRVal;
	local ai_tile_score ModifiedDelta;
	CursorPos = XComTacticalController(GetALocalPlayerController()).GetCursorPosition();
	CursorTile = `XWORLD.GetTileCoordinatesFromPosition(CursorPos);
	// Turn off high-detail display if cursor moves off the current Detail tile.
	if( CursorTile.X != DebugCursorTile.X && CursorTile.Y != DebugCursorTile.Y )
	{
		bDisplayScoreDetail = false;
	}
	// cache the saved 'current tile location' score
	if( DebugTileScores.Length > 0 )
	{
		CurrTileScore = DebugTileScores[0].RawScore;
	}
	foreach DebugTileScores(Score)
	{
		// High-detail score display - show calculations for weightings on the cursor tile.
		if( bDisplayScoreDetail )
		{
			if( Score.RawScore.kTile == DebugCursorTile )
			{
				vScreenPos = kCanvas.Project(Score.Location);
				vScreenPos.X -= 100;
				vScreenPos.X = Max(0, vScreenPos.X);
				vScreenPos.Y += 30; // Avoid 'dashing' popup.
				kCanvas.SetDrawColor(255, 64, 0);
				if( Score.bFailAllyLoS )
				{
					kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("Failed Restriction: Ally LoS");
					vScreenPos.Y += 15;
					bSkipCalc = true;
				}
				if( Score.bFailEnemyLoS )
				{
					kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("Failed Restriction: Enemy LoS");
					vScreenPos.Y += 15;
					bSkipCalc = true;
				}
				if( Score.bFailDistance )
				{
					kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("Failed Restriction: Distance from Anchor");
					vScreenPos.Y += 15;
					bSkipCalc = true;
				}
				if( Score.bFailFlanking )
				{
					kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("Failed Restriction: Flanking");
					vScreenPos.Y += 15;
					bSkipCalc = true;
				}
				if( Score.bInBadArea )
				{
					kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("Failed check- InBadArea");
					vScreenPos.Y += 15;
					bSkipCalc = true;
				}
				if( Score.bNotReachable )
				{
					kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("Failed check- Reachable");
					vScreenPos.Y += 15;
					bSkipCalc = true;
				}
				if( bSkipCalc ) // Exit early if this location failed before calculating a score.
					return;

				// Output current move profile weights
				kCanvas.SetDrawColor(255, 255, 255);
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("Weight Profile= "@m_arrMoveWeightProfile[CurrMoveType].Profile
								 @": C("$  `TruncFloatString(m_arrMoveWeightProfile[CurrMoveType].fCoverWeight, 2)
								 $"), D("$	`TruncFloatString(m_arrMoveWeightProfile[CurrMoveType].fDistanceWeight, 2)
								 $"), F("$	`TruncFloatString(m_arrMoveWeightProfile[CurrMoveType].fFlankingWeight, 2)
								 $"), E("$	`TruncFloatString(m_arrMoveWeightProfile[CurrMoveType].fEnemyVisWeight, 2)
								 $"), E1("$	`TruncFloatString(m_arrMoveWeightProfile[CurrMoveType].fEnemyVisWeightPeak1, 2)
								 $"), A("$	`TruncFloatString(m_arrMoveWeightProfile[CurrMoveType].fAllyVisWeight, 2)
								 $"), P("$	`TruncFloatString(m_arrMoveWeightProfile[CurrMoveType].fPriorityDistWeight, 2)
								 $"), R("$	`TruncFloatString(AllyAbilityRangeWeight, 2)
								 $")");
				// Output 'linger penalty' value for current location.
				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("Linger Penalty="
								 $`TruncFloatString(CURR_TILE_LINGER_PENALTY, 2)
								 @"(D="@ (m_kCurrTileData.fDistanceScore / CURR_TILE_LINGER_PENALTY)
								 $" * "$`TruncFloatString(CURR_TILE_LINGER_PENALTY, 2)
								 $" = "$`TruncFloatString(m_kCurrTileData.fDistanceScore, 2) );

				// Output Distance score breakdown for new location.
				if( Score.RawScore.bCloserThanIdeal )
				{
					ModifierNew = m_arrMoveWeightProfile[CurrMoveType].fCloseModifier;
				}
				else
				{
					ModifierNew = m_arrMoveWeightProfile[CurrMoveType].fFarModifier;
				}
				if( CurrTileScore.bCloserThanIdeal )
				{
					ModifierCurr = m_arrMoveWeightProfile[CurrMoveType].fCloseModifier;
				}
				else
				{
					ModifierCurr = m_arrMoveWeightProfile[CurrMoveType].fFarModifier;
				}
				IdealRange = GetIdealRangeMeters();
				DistScoreNew = Score.RawScore.fDistanceScore*ModifierNew;
				DistScoreCurr = CurrTileScore.fDistanceScore*ModifierCurr;
				DistScoreTotal = DistScoreNew - DistScoreCurr;

				PriorityScoreNew = Score.RawScore.fPriorityDistScore;
				PriorityScoreCurr = CurrTileScore.fPriorityDistScore;
				PriorityScoreTotal = PriorityScoreNew - PriorityScoreCurr;

				AbilityRangeNew = Score.RawScore.fAllyAbilityRangeScore;
				AbilityRangeCurr = CurrTileScore.fAllyAbilityRangeScore;
				AbilityRangeTotal = AbilityRangeNew - AbilityRangeCurr;

				// Ideal range and Distance Score breakdown
				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText(" Distance Breakdown:  IdealRange = "$IdealRange);

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("   Old Tile  :"
								 $"Enemy Dist= "$`TruncFloatString(DebugTileScores[0].DistToEnemy, 2)
								 @(CurrTileScore.bCloserThanIdeal ? "NearModifier=" : "FarModifier=") $ `TruncFloatString(ModifierCurr, 2)
								 @"Score=("$`TruncFloatString(CurrTileScore.fDistanceScore, 2)$")*("$`TruncFloatString(ModifierCurr, 2)$")="$`TruncFloatString(DistScoreCurr, 2));

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("   New Tile:"
								 $"Enemy Dist= "$`TruncFloatString(Score.DistToEnemy,2)
								 @(Score.RawScore.bCloserThanIdeal ? "NearModifier=" : "FarModifier=") $ `TruncFloatString(ModifierNew,2)
								 @"Score= ("$`TruncFloatString(Score.RawScore.fDistanceScore, 2)$")*("$`TruncFloatString(ModifierNew, 2)$")="$`TruncFloatString(DistScoreNew, 2));

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("Distance Score delta = NewTileScore-OldTileScore = ("$`TruncFloatString(DistScoreNew, 2)$") - ("$`TruncFloatString(DistScoreCurr, 2)$") = "$`TruncFloatString(DistScoreTotal, 2));

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("Priority Distance Score delta = NewTileScore-OldTileScore = ("$`TruncFloatString(PriorityScoreNew, 2)$") - ("$`TruncFloatString(PriorityScoreCurr, 2)$") = "$`TruncFloatString(PriorityScoreTotal, 2));

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("Ability Range Score delta = NewTileScore-OldTileScore = ("$`TruncFloatString(AbilityRangeNew, 2)$") - ("$`TruncFloatString(AbilityRangeCurr, 2)$") = "$`TruncFloatString(AbilityRangeTotal, 2));

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("Old Tile Raw Score:"@GetDebugString(m_kCurrTileData));

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.DrawText("New Tile Raw Score:"$GetDebugString(Score.RawScore));

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				ModifiedDelta = Score.DeltaScore;
				ModifiedDelta.fDistanceScore = DistScoreTotal;
				kCanvas.DrawText("Total Delta Score (New-Old Raw Scores):"$GetDebugString(ModifiedDelta));

				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				fCVal = m_arrMoveWeightProfile[CurrMoveType].fCoverWeight			*Score.DeltaScore.fCoverValue;
				fDVal = m_arrMoveWeightProfile[CurrMoveType].fDistanceWeight			*DistScoreTotal;
				fFVal = m_arrMoveWeightProfile[CurrMoveType].fFlankingWeight			*Score.DeltaScore.fFlankScore;
				fEVal = m_arrMoveWeightProfile[CurrMoveType].fEnemyVisWeight			*Score.DeltaScore.fEnemyVisibility;
				fE1Val = m_arrMoveWeightProfile[CurrMoveType].fEnemyVisWeightPeak1	*Score.DeltaScore.fEnemyVisibilityPeak1;
				fAVal = m_arrMoveWeightProfile[CurrMoveType].fAllyVisWeight			*Score.DeltaScore.fAllyVisibility;
				fPVal = m_arrMoveWeightProfile[CurrMoveType].fPriorityDistWeight		*PriorityScoreTotal;
				fRVal = AllyAbilityRangeWeight											*AbilityRangeTotal;
				kCanvas.DrawText("Weighted Score"
					$"  = C(" $`TruncFloatString(fCVal, 2)
					$") + D(" $`TruncFloatString(fDVal, 2)
					$") + F(" $`TruncFloatString(fFVal, 2)
					$") + E(" $`TruncFloatString(fEVal, 2)
					$") + E1("$`TruncFloatString(fE1Val, 2)
					$") + A(" $`TruncFloatString(fAVal, 2)
					$") + P(" $`TruncFloatString(fPVal, 2)
					$") + R(" $`TruncFloatString(fRVal, 2)
					$") = "$`TruncFloatString(Score.WeightedScore, 2));
				if( Score.RawScore.bWithinSpreadMin )
				{
				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("SpreadMult = "$`TruncFloatString(Score.RawScore.SpreadMultiplier, 2));
				vScreenPos.Y += 15;
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("FinalScore=Weighted*SpreadMultiplier="$`TruncFloatString(Score.FinalScore, 2) );
				}
				else
				{
					vScreenPos.Y += 15;
					kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
					kCanvas.DrawText("FinalScore="$`TruncFloatString(Score.FinalScore, 2) );
				}


				break;
			}
		}
		else
		{
			// Initial tile has no weighted score.  (was where the unit started from on last FindDestination call)
			if( Score.RawScore.kTile == CurrTileScore.kTile )
				continue;

			// Draw overall weight score text over the tile in question.
			vScreenPos = kCanvas.Project(Score.Location);
			kCanvas.SetPos(Max(0, vScreenPos.X - 10), vScreenPos.Y);
			if( Score.FinalScore <= 0 )
			{
				kCanvas.SetDrawColor(128, 128, 128);
			}
			else
			{
				kCanvas.SetDrawColor(255, 255, 255);
			}
			kCanvas.DrawText(`TruncFloatString(Score.FinalScore,2));

			// Check if we should switch into High Detail mode.  If cursor is on our tile, switch.
			if( Score.RawScore.kTile.X == CursorTile.X && Score.RawScore.kTile.Y == CursorTile.Y && abs(Score.RawScore.kTile.Z-CursorTile.Z) <= 3)
			{
				DebugCursorTile = Score.RawScore.kTile;
				bDisplayScoreDetail = true;
				break;
			}
		}
	}
}
//------------------------------------------------------------------------------------------------
// overridden in Inactive state.
// Returns true if this is the one currently active unit (currently selecting and performing a 
//  move/shoot/etc action) during the AI player's turn.
simulated function bool IsActive()
{
	return true;
}
//------------------------------------------------------------------------------------------------
// For now return a random point between the two units within the equipped weapon's long range
simulated function vector FindFiringPosition( XGUnit kEnemy )
{
	return FindValidPathDestinationToward( kEnemy.Location );
}
//------------------------------------------------------------------------------------------------
// This function will determine where the sectoid will attempt to path to.
function vector DecideNextDestination( optional out string strFail )
{
	strFail = "Reached empty DecideNextDestination function, this is an error.";
	m_bAbortMove = true;
    return vect(0,0,0);
}

//------------------------------------------------------------------------------------------------
simulated function bool IsAboveFloorTile( Vector vLoc, int iMinTiles=1)
{
	local TTile kFloor, kTile;

	if (!`XWORLD.GetFloorTileForPosition(vLoc, kFloor, true))
		return false;
	kTile = `XWORLD.GetTileCoordinatesFromPosition(vLoc);
	if (kTile.Z - kFloor.Z > iMinTiles)
		return true;
	return false;
}
//------------------------------------------------------------------------------------------------
simulated function ResetLocationHeight( out vector vLoc, bool bSetToFloor=true )
{
	local TTile kTile;
	local vector vFloor;
	local float fCurrHeight;
	`XWORLD.GetFloorTileForPosition(vLoc, kTile, true);
	vFloor = `XWORLD.GetPositionFromTileCoordinates(kTile);
	fCurrHeight = bSetToFloor?0.0f:(m_kUnit.GetPawn().GetCollisionHeight()*0.5f) + 5;//m_kUnit.GetGameStateLocation().Z - m_kUnit.GetWorldZ();
	vLoc.Z = vFloor.Z + fCurrHeight;
}
//------------------------------------------------------------------------------------------------
simulated function vector ValidateDestination( Vector vLoc )
{
	local TTile Tile;

	Tile = `XWORLD.GetTileCoordinatesFromPosition(vLoc);
	if( IsInBadArea(vLoc) || !IsValidPathDestination(vLoc) || (`XWORLD.GetUnitOnTile( Tile ).ObjectId != m_kUnit.ObjectID))
	{
		ResetLocationHeight(vLoc);
		Tile = `XWORLD.GetTileCoordinatesFromPosition(vLoc);
		if( IsInBadArea(vLoc) || !IsValidPathDestination(vLoc) || (`XWORLD.GetUnitOnTile( Tile ).ObjectID != m_kUnit.ObjectID))
			return FindValidPathDestinationToward(vLoc,,false);
	}
	return vLoc;
}

// Overwritten in green alert state.
function bool IsGroupMove()
{
	return false;
}
//------------------------------------------------------------------------------------------------
simulated function bool MoveUnit( optional out string strFail )
{
    local vector vDestination;
	local TTile kDest;
	local XComGameState_AIGroup kGroup;

     // Pathing
    vDestination = DecideNextDestination(strFail);

	kDest = `XWORLD.GetTileCoordinatesFromPosition(vDestination);

	if (!m_bBTDestinationSet && !m_bAlertDataMovementDestinationSet)
	{
		if (!m_bAbortMove && kDest.X == UnitState.TileLocation.X && kDest.Y == UnitState.TileLocation.Y && abs(UnitState.TileLocation.Z-kDest.Z) <= 3)
		{
			kGroup = GetGroupState();
			strFail = GetStateName()@"No BT Destination set, DecideNextDestination returned current location. AlertLevel="$UnitState.GetCurrentStat(eStat_AlertLevel)@"Group="$kGroup.ObjectID@kGroup;
			`Log(strFail@self@GetStateName());
			m_bAbortMove = true;
		}

		if (!m_bAbortMove)
		{
			if (`XWORLD.IsPositionOnFloor(vDestination) && !DestinationIsReachable(vDestination))
			{
				kGroup = GetGroupState();
				strFail = GetStateName()@"No BT Destination set, DecideNextDestination is beyond movement range!. AlertLevel="$UnitState.GetCurrentStat(eStat_AlertLevel)@"Group="$kGroup.ObjectID@kGroup;
				`Log(strFail@self@GetStateName());
				// What happened?  Reattempt for debugging purposes.
				vDestination = DecideNextDestination();
			}

			vDestination = ValidateDestination(vDestination);
		}

		if (m_bAbortMove)
		{
			OnMoveFailure(strFail);
			return false;
		}
	}
	
	`LogAI("Moving to: "$vDestination);
	if (IsGroupMove())
	{
		return GroupMoveToPoint(vDestination, strFail);
	}

	return MoveToPoint(vDestination, strFail);
}

//------------------------------------------------------------------------------------------------
//Returns TRUE if the path attempt succeeded, FALSE if a path could not be found
simulated function bool MoveToPoint(vector vDestination, optional out string FailText)
{
	local array<TTile> Path;
	local bool bPathFailed;
	local TTile kTileDest;
	local array<PathPoint> PathPoints;

	bPathFailed=false;

	kTileDest = `XWORLD.GetTileCoordinatesFromPosition(vDestination);

	if (kTileDest.X == UnitState.TileLocation.X && kTileDest.Y == UnitState.TileLocation.Y && abs(UnitState.TileLocation.Z-kTileDest.Z) <= 3)
	{
		FailText = "MoveToPoint returned current location. Aborting movement.";
		if (m_bBTDestinationSet)
		{
			FailText @= "CurrTileData loc=("$m_kCurrTileData.kTile.X@m_kCurrTileData.kTile.Y@m_kCurrTileData.kTile.Z$")\n";
		}
		FailText @= "UnitState Loc=("$UnitState.TileLocation.X@UnitState.TileLocation.Y@UnitState.TileLocation.Z$")\n";
		FailText @= "TileDest Loc=("$kTileDest.X@kTileDest.Y@kTileDest.Z$")\n";
		FailText @= "UnitState data based on "@UnitState;
		`Log(FailText@self@GetStateName());
		bPathFailed = true;
	}

	if (!bPathFailed)
	{
		bPathFailed = !m_kUnit.m_kReachableTilesCache.IsTileReachable(kTileDest);
		if (bPathFailed)
		{
			FailText = "IsTileReachable on destination ("$kTileDest.X@kTileDest.Y@kTileDest.Z$") failed on IsTileReachable.";
		}
	}

	if( !bPathFailed || bForcePathIfUnreachable )
	{	
		if (XGAIBehavior_Civilian(self) != none)
		{
			XGAIBehavior_Civilian(self).m_iMoveTimeStart = WorldInfo.TimeSeconds;
		}

		m_kUnit.m_kReachableTilesCache.BuildPathToTile(kTileDest, Path);
		if( bForcePathIfUnreachable && Path.Length < 2 )
		{
			bPathFailed = false;
			class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, kTileDest, Path);
			// get the path points
			class'X2PathSolver'.static.GetPathPointsFromPath(UnitState, Path, PathPoints);
			// make the flight path nice and smooth
			class'XComPath'.static.PerformStringPulling(m_kUnit, PathPoints);
			// Reinsert into our array.
			class'XComPath'.static.GetPathTileArray(PathPoints, Path);
		}

		if (Path.Length < 2)
		{
			FailText = "MoveToPoint attempted m_kReachableTilesCache.BuildPathToTile end ended up with a Path length < 2. Aborting movement.";
			`Log(FailText@self@GetStateName());
			bPathFailed = true;
		}
		else
		{
			if( bUseSurprisedScamperMove )
			{
				AdjustDestinationForSurprisedScamper(Path);
				kTileDest = Path[Path.Length - 1];
				bUseSurprisedScamperMove = false;
			}

			`LogAI("* * * Move - Unit "$m_kUnit.ObjectID@"to ("$kTiledest.X@kTileDest.Y@kTileDest.Z$") * * *");
			XComTacticalController(GetALocalPlayerController()).GameStateMoveUnitSingle(m_kUnit, Path);
			// Update final destination in case the movement here was interrupted.
			RefreshUnitCache();
			kTileDest = UnitState.TileLocation;
			`XWORLD.SetTileBlockedByUnitFlagAtLocation(UnitState, kTileDest); // Flag this location as occupied.
		}
	}
	else 
	{
		OnMoveFailure("MoveToPoint failed in ComputePathTo location:"$vDestination@FailText, false);
	}

	return !bPathFailed;
}   

//------------------------------------------------------------------------------------------------
//Returns TRUE if the path attempt succeeded, FALSE if a path could not be found
simulated function bool GroupMoveToPoint( vector Destination, out string FailText )
{	
	local array<PathingInputData> GroupPaths;

	if( !UnitState.IsGroupLeader() )
	{
		`RedScreen("Attempting to group move from a unit that is not the group leader!!!  @ACHENG");
	}

	if(m_kPatrolGroup.GetGroupMovePaths(Destination, GroupPaths, UnitState))
	{
		XComTacticalController(GetALocalPlayerController()).GameStateMoveUnit(m_kUnit, GroupPaths);
		return true;
	}
	else
	{
		FailText = FailText @" m_kPatrolGroup.GetGroupMovePaths failure.";
	}

	return false;
}   

//------------------------------------------------------------------------------------------------
// Shorten the path on Surprised Scamper. Uses config values for min and max scamper path length.
// In determining the shortened length, use the max length value when the path is larger than the
// max value.  Use the full original path if the path is not longer than the min length value.
// Otherwise for path lengths between the min and max values, pick any random length less than the 
// original path length.
function AdjustDestinationForSurprisedScamper(out array<TTile> Path)
{
	local int TileCount, RandLength;
	TileCount = Path.Length;
	if( TileCount > MIN_SURPRISED_SCAMPER_PATH_LENGTH )
	{
		if( TileCount > MAX_SURPRISED_SCAMPER_PATH_LENGTH )
		{
			Path.Length = MAX_SURPRISED_SCAMPER_PATH_LENGTH;
		}
		else
		{
			RandLength = MIN_SURPRISED_SCAMPER_PATH_LENGTH + `SYNC_RAND(TileCount - MIN_SURPRISED_SCAMPER_PATH_LENGTH);
			Path.Length = RandLength;
		}
		`LogAI("Surprised scamper! Shortened path destination by"@TileCount - Path.Length@"tiles.");
	}
}

//------------------------------------------------------------------------------------------------
simulated function bool IsVisibleToEnemy( )
{
	if ( `TACTICALRULES.VisibilityMgr.GetNumViewersOfTarget(m_kUnit.ObjectID) > 0 )
		return true;

	return false;
}

//------------------------------------------------------------------------------------------------
function bool HasAdjacentNeighbors( XComGameState_Unit kUnit, out array<int> NeighborIDs, bool bXComOnly=true, bool bAlienOnly=false)
{
	local XComGameStateHistory History;
	local XComGameState_Unit kOtherUnit;
	History = `XCOMHISTORY;
	NeighborIDs.Length = 0;
	foreach History.IterateByClassType(class'XComGameState_Unit', kOtherUnit)
	{
		if (kOtherUnit.ObjectID == kUnit.ObjectID)
			continue;
		if (bAlienOnly && !kOtherUnit.ControllingPlayerIsAI())
			continue;
		if (bXComOnly && kOtherUnit.GetTeam() != eTeam_XCom)
			continue;

		if (abs(kOtherUnit.TileLocation.X-kUnit.TileLocation.X) + abs(kOtherUnit.TileLocation.Y-kUnit.TileLocation.Y)  == 1
			&& (kOtherUnit.TileLocation.Z == kUnit.TileLocation.Z) )
		{
			NeighborIDs.AddItem(kOtherUnit.ObjectID);
		}
	}
	return (NeighborIDs.Length > 0);
}
//------------------------------------------------------------------------------------------------
// This function is quite hacky.  We'll rewrite eventually - Casey
simulated function ChooseWeapon()
{
	local XGWeapon kWeapon;

	// Use primary weapon when the ability doesn't call for another.
	if( !IsValidAction() || IsMoveAbility() ) // AbilityDM::IsWeaponAbility returned !IsMoveAbility.
	{
		kWeapon = m_kUnit.GetInventory().m_kPrimaryWeapon;
	}
	else
	{
		kWeapon = GetWeapon();
	}

	if (kWeapon != None && kWeapon.m_eEquipLocation == kWeapon.m_eSlot)
	    m_kUnit.GetInventory().SetActiveWeapon(kWeapon);
}


//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
simulated function BeginTurn( ) {} // defined only in active state.
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
simulated function bool CanUseCover()
{
	return UnitState.CanTakeCover();
}
//------------------------------------------------------------------------------------------------
simulated function bool IsAbilityValid(AvailableAction kAbility)
{
	return true;
}
//------------------------------------------------------------------------------------------------
simulated function bool IsInBadArea( Vector vLoc, bool bDebugLog=false, optional out string strFail)
{
	if (`CHEATMGR != None  && `CHEATMGR.bDebugBadAreaLog)
		bDebugLog=true;

	if (!XComTacticalGRI(WorldInfo.GRI).IsValidLocation( vLoc, m_kUnit ) )
	{
		strFail @= "Location ("$vLoc$") failed in TacticalGRI::IsValidLocation.";
		if (bDebugLog)
			`Log(strFail);
		return true;
	}

	if( class'XComSpawnRestrictor'.static.IsInvalidPathLocationNative(vLoc) )
	{
		return true;
	}

	return false;
}
//------------------------------------------------------------------------------------------------
function bool DestinationIsReachable( Vector vLocation )
{
	local bool bValid;
	bValid = m_kUnit.DestinationIsReachable(vLocation);
	if (!bValid)
		DebugLogPathingFailure(vLocation, ePATHING_FAILURE_UNREACHABLE);
	return bValid;
}
//------------------------------------------------------------------------------------------------
// Validate cover locations based on any grenades nearby.
simulated function bool BaseValidator( vector vCoverLoc )
{
	return BaseValidatorDebug(vCoverLoc);
}
function bool BaseValidatorDebug( vector vCoverLoc, optional out string strFail )
{
	local bool bValid;
	bValid = true;

	if (bValid && IsInBadArea(vCoverLoc,, strFail))
	{
		bValid = false;
		strFail @= "Failed on function IsInBadArea()";
	}

	if (bValid && `XWORLD.IsPositionOnFloor(vCoverLoc) && !DestinationIsReachable(vCoverLoc)) // Only test DestinationIsReachable with ground destinations.
	{
		bValid = false;
		strFail @= "Failed on function DestinationIsReachable";
	}

	if (!bValid)
		DebugLogPathingFailure(vCoverLoc, ePATHING_FAILURE_BASE_VALIDATOR);

	return bValid;
}
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// STATES
//------------------------------------------------------------------------------------------------
////------------------------------------------------------------------------------------------------
////------------------------------------------------------------------------------------------------
////------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
auto state Inactive
{
	simulated event BeginState(name P)
	{
		//If the AI player is moving units, and we got in here without changing game states, then skip our turn...
		if(m_kPlayer != None && m_kPlayer.CurrentMoveUnit.UnitObjectRef.ObjectID > 0 )
		{			
			//If no new history frames were added, it means we did not decide on an action to take. Skip our turn. This is
			//an error condition, as there there are other calls to SkipTurn prior to this that should have been hit.
			if( DecisionStartHistoryIndex == `XCOMHISTORY.GetCurrentHistoryIndex() )
			{		
				`LogAI("Inactive::BeginState - Skipping AI turn for unit"$m_kUnit.ObjectID);
				SkipTurn("from State Inactive, HistoryIndex not incremented since last run error.");
			}
		}
	}
	simulated event EndState(name N)
	{
		`LogAI("EndState Inactive ->"@N);
	}
	
	simulated function bool IsActive()
	{
		return false;
	}

	simulated function BeginTurn( )
	{
		GotoState( 'Active' );
	}

}
//------------------------------------------------------------------------------------------------
state Active
{
	simulated event BeginState(name P)
	{
	}
	simulated event EndState(name N)
	{
		`LogAI("EndState Active ->"@N);
	}
Begin:	
	Sleep(0);
	if (`CHEATMGR != None && `CHEATMGR.bSkipNonMeleeAI)
		GotoState( 'EndOfTurn' );
	else
	{
		InitTurn();
		m_kUnit.m_kReachableTilesCache.ForceCacheUpdate();
		GotoState( 'ExecutingAI' );
	}
}

// This ensures that a group that starts in green alert will all move with the green alert behavior.  
// Fixes issues where the first unit gets alerted to an enemy before the next unit in the group begins movement, gets
// set as red alert, and ends up moving in red alert behavior when the entire group should start moving with green behavior.
function int GetAlertLevelOverride()
{
	local int iOverride;
	// We only care to override the alert level when we are doing green patrol simultaneous movement.  
	// Otherwise we should only be using the game state alert levels.
	if( m_kPlayer != None && m_kPlayer.m_ePhase == eAAP_GreenPatrolMovement)
	{
		// Unit is scampering.  Use Red alert.
		if( m_kPlayer.IsScampering(UnitState.ObjectID, false))
		{
			return `ALERT_LEVEL_RED;
		}
		if( m_kPlayer.m_kNav.IsPatrol(m_kUnit.ObjectID, m_kPatrolGroup) && !m_kPatrolGroup.bDisableGroupMove )
		{
			iOverride = m_kPatrolGroup.GetLastAlertLevel(m_kUnit.ObjectID);
			if( iOverride == 0 || m_kPatrolGroup.bStartedUnrevealed ) // we should only use the override when it was zero.  Otherwise we use our current alert level.
			{
				return iOverride;
			}
		}
	}
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kUnit.ObjectID));	
	return UnitState.GetCurrentStat(eStat_AlertLevel);
}

function bool IsOrangeAlert()
{
	if (GetAlertLevelOverride() == 1)
	{
		if (HasAlertLocation(,true))
		{
			return true;
		}
	}
	return false;
}

function bool HasAlertLocation( optional out vector vAlertLoc_out, bool bIgnoreImpliedAlerts=false )
{
	local int iDataID;
	local XComGameState_AIUnitData kUnitData;
	local AlertData kAlertData;

	iDataID = GetAIUnitDataID(UnitState.ObjectID);
	if( iDataID > 0 )
	{
		kUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));

		if( kUnitData.GetPriorityAlertData(kAlertData, , bIgnoreImpliedAlerts) )
		{
			vAlertLoc_out = `XWORLD.GetPositionFromTileCoordinates(kAlertData.AlertLocation);
			return true;
		}
	}
	return false;

}

function bool StartedTurnUnrevealed()
{
	local XGAIGroup Group;
	if( m_kPlayer != None &&  m_kPlayer.m_kNav != None)
	{
		m_kPlayer.m_kNav.GetGroupInfo(UnitState.ObjectID, Group);
		if( Group != None )
		{
			return Group.bStartedUnrevealed;
		}
	}
	return false;
}

//------------------------------------------------------------------------------------------------
// Determine what kind of move should happen.
simulated function ExecuteMoveAbility()
{
	local string strFail;
	local bool bMindControlled;
	//local int nEnemiesVisible;
	local int InitialAlertLevel;

	if( !UnitState.ControllingPlayerIsAI() )
	{
		`LogAI("XComMovement.");
		GotoState('XComMovement');
		return;
	}

	bMindControlled = class'XGAIPlayer'.static.IsMindControlled(UnitState);
	
	//nEnemiesVisible = UnitState.GetNumVisibleEnemyUnits(true,true);//class'X2TacticalVisibilityHelpers'.static.GetNumVisibleEnemyTargetsToSource(m_kUnit.ObjectID);
	//
	// update - these should be completely based on the visualizers alert state.
	InitialAlertLevel = GetAlertLevelOverride(); // May be overridden by initial patrol group alert level.
	if( UnitState.IsUnrevealedAI() && m_kPlayer != None && !m_kPlayer.IsScampering(UnitState.ObjectID) && !bMindControlled ) // Green alert level.
	{
		`LogAI("GreenAlertMovement.");
		GotoState('GreenAlertMovement');
	}
	else if( m_iAlertDataScoreHighestIndex != INDEX_NONE && m_bAlertDataMovementDestinationSet )
	{
		`LogAI("AlertDataMovement.");
		GotoState('AlertDataMovement');
	}
	else if( InitialAlertLevel == 2 || bMindControlled || m_kPlayer.IsScampering(UnitState.ObjectID)) // Red alert level.
	{
		`LogAI("RedAlertMovement.");
		GotoState('RedAlertMovement');
	}
	else if ( InitialAlertLevel == 1 ) // Yellow alert
	{
		if (HasAlertLocation(,true))
		{
			`LogAI("OrangeAlertMovement.");
			GotoState('OrangeAlertMovement');
		}
		else
		{
			`LogAI("YellowAlertMovement.");
			GotoState('YellowAlertMovement');
		}
	}
	else
	{
		`LogAI("NON-MOVE.");
		strFail @= "ExecuteMoveAbility:No move state valid!";
		SwitchToAttack(strFail);
	}
}

function bool WaitingForBTRun()
{
	if( !`BEHAVIORTREEMGR.IsReady() || ( m_kBehaviorTree != None && m_kBehaviorTree.m_eStatus == BTS_RUNNING ))
		return true;
	return false;
}

//------------------------------------------------------------------------------------------------
state ExecutingAI
{
	simulated event BeginState(name P)
	{
		UpdateErrorCheck(); // Ensure we don't get stuck looping in this state.
	}
	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState ExecutingAI ->"@N);
	}

	// Force green alert groups to stay together. If the leader of the group moves, then the entire group moves.
	// If the leader of the group does some other action, the other members skip their move.
	function bool HasOverrideAbility(out AvailableAction OverrideAction_out, out Name OverrideAbilityName_out)
	{
		local XComGameState_AIGroup GroupState; 
		local vector Destination;
		local array<vector> XComMidpointFlankArray;

		if( UnitState.IsUnrevealedAI()
		    && m_kPatrolGroup != None 
			&& m_kPatrolGroup.HasOverrideAction(OverrideAbilityName_out, UnitState.ObjectID) )
		{
			OverrideAction_out = FindAbilityByName(OverrideAbilityName_out);
			return true;
		}
		if( GetCheatOverride(OverrideAction_out, OverrideAbilityName_out) )
		{
			return true;
		}

		// Fallback behavior. Skips behavior tree and paths to fallback location.
		GroupState = GetGroupState();
		if( GroupState.IsFallingBack(Destination) )
		{
			m_bBTCanDash = true;
			// Kick off initial fallback call.
			if( GroupState.ShouldDoFallbackYell() )
			{
				OverrideAbilityName_out = 'Yell';
				OverrideAction_out = FindAbilityByName(OverrideAbilityName_out);
				m_bBTDestinationSet = false;
				return true;
			}
			// Abort if we're already at our fallback destination
			else if( GroupState.IsUnitInFallbackArea(UnitState) && !GroupState.bProcessedScamper)
			{
				OverrideAbilityName_out = 'SkipMove';
				m_bBTDestinationSet = false;
				return true;
			}
			// Otherwise dash for the fallback area.
			else if( HasValidDestinationToward(Destination, m_vBTDestination, true) )
			{
				// Update - Always force the destination to be in cover to the enemy.
				XComMidpointFlankArray.AddItem(GetXComMidPoint());
				GetClosestCoverLocation(m_vBTDestination, m_vBTDestination, false, , XComMidpointFlankArray);

				OverrideAbilityName_out = 'StandardMove';
				OverrideAction_out = FindAbilityByName(OverrideAbilityName_out);
				m_bBTDestinationSet = true;
				return true;
			}
			else
			{
				`LogAI("Error - FALLBACK unit failed to find a destination towards vector ("$Destination$")");
			}
		}
		return false;
	}

	Begin:	
	m_iDebugHangLocation=2;
	// Wait for queued BT runs first.
	while( WaitingForBTRun() )
	{
		sleep(0.1f);
	}
	RefreshUnitCache();
	if( !UnitAbilityInfo.bAnyActionsAvailable || UnitState.IsPanicked() )
	{
		//It should be impossible to enter this state without abilities to use, but just in case...
		SkipTurn("from state ExecutingAI - no actions available or unit is panicked");
		m_iDebugHangLocation=3;
		GotoState('EndOfTurn');
	}
	else
	{
		if( HasOverrideAbility(m_kBTCurrAbility, m_strBTAbilitySelection) )
		{
			BTExecuteAbility();
		}
		else if (!StartRunBehaviorTree(,true) )
		{
			`RedScreen("AI failed to start Behavior Tree.  Unit type = "$UnitState.GetMyTemplateName()$".  Skipping turn.");
			SkipTurn("from state ExecutingAI - Behavior Tree Start Failure.");
			GotoState('EndOfTurn');
		}
		else
		{
			while (m_eBTStatus == BTS_RUNNING)
			{
				Sleep(0.0f);
				if (WorldInfo.TimeSeconds > m_fBTAbortTime)
				{
					`CHEATMGR.AIStringsUpdateString(UnitState.ObjectID, "Error- Behavior tree timed-out!");
					`Warn("Error- behavior tree took too long to finish!  Aborted!");
					`Assert(false);
					break;
				}
			}
		}
	}

	m_iDebugHangLocation=14;
	while( WaitingForBTRun() )
	{
		sleep(0.1f);
	}
	GotoState('EndOfTurn');
}
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
state MoveState
{
	function ForceNextGroupUnitBegin()
	{
		local int iID;
		local XComGameState_Unit kUnitState;
		local XComGameStateHistory History;
		History = `XCOMHISTORY;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_kUnit.ObjectID));	
		// Ensure this unit is not in WaitingToScamper list.
		m_kPlayer.m_arrWaitForScamper.RemoveItem(m_kUnit.ObjectID);
		foreach m_kPatrolGroup.m_arrUnitIDs(iID)
		{
			if( m_kPlayer.m_arrWaitForScamper.Find(iID) != -1 )
			{
				kUnitState = XComGameState_Unit(History.GetGameStateForObjectID(iID));
				if( kUnitState.NumAllActionPoints() > 0 )
				{
					`LogAI("SCAMPER: ForceNextGroupUnitBegin called, attempting to force begin unit#"$iID);
					m_kPlayer.BeginNextUnitTurn(iID, true);
					break;
				}
			}
		}
	}

	simulated event BeginState(Name P)
	{
		local string FailText;
		`LogAI(m_kUnit@"Begin MoveState from"@P@" Unit@"$m_kUnit.GetGameStateLocation()@"UnitState@"$m_kUnit.GetGameStateLocation());
		m_bAbortMove=false;
		if (m_kPatrolGroup != None)
		{
			m_kPatrolGroup.OnMoveBeginState(m_kUnit.ObjectID);
		}

		if( !MoveUnit(FailText) )
		{ 
			// Move failed.
			SkipTurn();
		}

		GotoState('EndOfTurn');
	}

	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState MoveState ->"@N@" Unit@"$m_kUnit.GetGameStateLocation()@"UnitState@"$m_kUnit.GetGameStateLocation());
		if( m_kPlayer != None && m_kPlayer.m_bWaitingForScamper )
		{
			if( m_kPlayer.m_arrWaitForScamper.Length > 0 )
			{
				`LogAI("Unit"@m_kUnit.ObjectID@"MoveState::EndState- WaitingForScamper: forcing next scamper unit to move.");
				ForceNextGroupUnitBegin();
			}
			else
			{
				`LogAI("Unit"@m_kUnit.ObjectID@"MoveState::EndState- WaitingForScamper - exhausted all units waiting for scamper..");
			}
		}
		if (m_kPatrolGroup != None)
		{
			m_kPatrolGroup.OnMoveEndState(m_kUnit.ObjectID);
		}

	}

	function RemoveAlertTile(int iAIID)
	{
		// TO DO: Update GameState for AIUnitData to remove the 0th element of the alert tiles array.
		local XComGameStateContext_TacticalGameRule NewContext;
		local XComGameStateHistory History;

		History = `XCOMHISTORY;

		`logAI("XGAIBehavior::RemoveAlertTile 0"$m_kUnit @ self);
		NewContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UpdateAIRemoveAlertTile);
		NewContext.AIRef = History.GetGameStateForObjectID(iAIID).GetReference();
		`XCOMGAME.GameRuleset.SubmitGameStateContext(NewContext);
	}
}
//------------------------------------------------------------------------------------------------

function vector GetGameStateLocation()
{
	local XComGameState_Unit kUnitState;
	kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kUnit.ObjectID));	
	return `XWORLD.GetPositionFromTileCoordinates(kUnitState.TileLocation);
}

//------------------------------------------------------------------------------------------------
state GreenAlertMovement extends MoveState
{
	simulated event BeginState(Name P)
	{
		if (m_kPlayer.m_kNav.IsPatrol(m_kUnit.ObjectID, m_kPatrolGroup))
		{
			if( UnitState.IsGroupLeader() )
			{
				`LogAI(m_kUnit@"Beginning GreenAlertMovement (patrol movement) from"@P);
				m_kPatrolGroup.InitPatrolMovement();
			}
			else
			{
				// Stop right there. Only group leaders can initialize group patrol movement.
				SkipGroupTurn();
				GotoState('EndOfTurn');
				return;
			}
		}
		else 
		{
			`RedScreen("Error - Patrol Group does not exist for unit: "$UnitState.ObjectID@" @acheng");
		}
		super.BeginState(P);
	}

	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState GreenAlertMovement Move->"@N);
		m_kLastAIState = name("GreenAlertMovement");

		if (m_kPatrolGroup != None && m_kPatrolGroup.m_bRebuildDestinations)
			XGAIPlayer(`BATTLE.GetAIPlayer()).UpdateDataToAIGameState();

		super.EndState(N);
	}

	function bool IsGroupMove()
	{
		if (m_kPatrolGroup != None && !m_kPatrolGroup.bDisableGroupMove)
		{
			return true;
		}
		return super.IsGroupMove();
	}
	function Vector DecideNextDestination( optional out string strFail )
	{
		local vector vDest, MyLoc;
		MyLoc = GetGameStateLocation();
		vDest = MyLoc;

		CheckForCheatManagerMoveDestination();

		if( m_bBTDestinationSet )
		{
			strFail @= "GotDestFromBTSearch.  (Green Alert)";
			return m_vBTDestination;
		}
		if (m_kPatrolGroup != None)
		{
			m_kPatrolGroup.GetPatrolDestination(m_kUnit.ObjectID, vDest);
			vDest = XComTacticalGRI(WorldInfo.GRI).GetClosestValidLocation(vDest, m_kUnit,, false);

			// Abort movement if we are already where we want to be, and are waiting for someone else.
			if (VSizeSq2D(vDest-MyLoc) < Square(`METERSTOUNITS(3)))
			{
				m_bAbortMove = true;
				m_kPatrolGroup.SetNextActualDest(vDest); // Update this to ensure we are ticking our stuck counter.
				SkipTurn("from State GreenAlertMovement, destination is within 3 meters of current location.");
				return vDest;
			}

			if (HasValidDestinationToward( vDest, vDest ))
			{
				m_kPatrolGroup.SetNextActualDest(vDest);
			}
			else
			{
				strFail = "Could not find a valid destination toward the destination closer than the current location.  Tile cache may need to be updated?";
				m_bAbortMove = true;
				SkipTurn("from state GreenAlertMovement, no valid destination towards target location.");
			}
			return vDest;
		}
		else 
		{
			`RedScreen("Error - Patrol Group does not exist for unit: "$UnitState.ObjectID@" @acheng");
		}
		// Got here - no group, so no green alert movement defined.
		strFail = "Unit("$UnitState.ObjectID$") - GreenAlertMovement failure.  Not moving.";
		`LogAI(strFail);
		m_bAbortMove = true;
		SkipTurn("from state GreenAlertMovement - no group, no movement defined.");
		GotoState('EndOfTurn');
		return vDest;
	}

	simulated function OnMoveFailure(string strFail="", bool bSkipOnMoveFailureAction=false)
	{
		// Green alert units can't attack anyone.
		if( UnitState.IsUnrevealedAI() )
		{
			if (m_kPatrolGroup != None)
			{
				m_kPatrolGroup.OnMoveFailure(m_kUnit.ObjectID, strFail, bSkipOnMoveFailureAction);
			}
			// Skip to the next guy.
			m_kPlayer.InvalidateUnitToMove(m_kUnit.ObjectID);
		}
		else
		{
			if (!bSkipOnMoveFailureAction)
				SwitchToAttack(strFail);
		}
	}
}

//------------------------------------------------------------------------------------------------
state YellowAlertMovement extends MoveState
{
	simulated event BeginState(Name P)
	{
		if (m_kPlayer.m_kNav.IsPatrol(m_kUnit.ObjectID, m_kPatrolGroup))
		{
			`LogAI(m_kUnit@"Beginning YellowAlertMovement (patrol movement) from"@P);
			m_kPatrolGroup.InitPatrolMovement();
		}
		else 
		{
			`RedScreen("Error - Patrol Group does not exist for unit: "$UnitState.ObjectID@" @acheng");
		}
		super.BeginState(P);
	}

	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState YellowAlertMovement Move->"@N);
		m_kLastAIState = name("YellowAlertMovement");
		if (m_kPatrolGroup != None && m_kPatrolGroup.m_bRebuildDestinations)
			XGAIPlayer(`BATTLE.GetAIPlayer()).UpdateDataToAIGameState();

		super.EndState(N);
	}

	function Vector DecideNextDestination( optional out string strFail )
	{
		local vector vDest, MyLoc;
		local XComGameState_Unit NearestEnemy;

		CheckForCheatManagerMoveDestination();

		if (m_bBTDestinationSet)
		{
			strFail @= "GotDestFromBTSearch. (Yellow Alert)";
			return m_vBTDestination;
		}
		MyLoc = GetGameStateLocation();
		vDest = MyLoc;
		if (!HasAlertLocation(vDest))
		{
			// CHEAT - no other options - move toward nearest enemy location.
			NearestEnemy = GetNearestKnownEnemy(MyLoc);
			if ( NearestEnemy == None )
			{
				// Got here - no place to go?
				strFail = "Unit("$UnitState.ObjectID$") - YellowAlertMovement failure.  Not moving.  No destination defined.";
				`LogAI(strFail);
				m_bAbortMove = true;
				SkipTurn("from state YellowAlertMovement-no destination defined.");
				GotoState('EndOfTurn');
				return vDest;
			}
			else
			{
				vDest = `XWORLD.GetPositionFromTileCoordinates(NearestEnemy.TileLocation);
			}
		}
		vDest = FindValidPathDestinationToward(vDest);
		GetClosestCoverLocation(vDest, vDest);
		return vDest;
	}
}

//------------------------------------------------------------------------------------------------
state OrangeAlertMovement extends MoveState
{
	simulated event BeginState(Name P)
	{
		if (m_kPlayer.m_kNav.IsPatrol(m_kUnit.ObjectID, m_kPatrolGroup))
		{
			`LogAI(m_kUnit@"Beginning OrangeAlertMovement (patrol movement) from"@P);
			m_kPatrolGroup.InitPatrolMovement();
		}
		else 
		{
			`RedScreen("Error - Patrol Group does not exist for unit: "$UnitState.ObjectID@" @acheng");
		}
		super.BeginState(P);
	}

	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState OrangeAlertMovement Move->"@N);
		m_kLastAIState = name("OrangeAlertMovement");
		if (m_kPatrolGroup != None && m_kPatrolGroup.m_bRebuildDestinations)
			XGAIPlayer(`BATTLE.GetAIPlayer()).UpdateDataToAIGameState();

		super.EndState(N);
	}

	function Vector DecideNextDestination( optional out string strFail )
	{
		local vector vDest, MyLoc;
		local XComGameState_Unit NearestEnemy;

		CheckForCheatManagerMoveDestination();

		if (m_bBTDestinationSet)
		{
			strFail @= "GotDestFromBTSearch.";
			return m_vBTDestination;
		}
		MyLoc = GetGameStateLocation();
		vDest = MyLoc;

		if (!HasAlertLocation(vDest))
		{
			// CHEAT - no other options - move toward nearest enemy location.
			NearestEnemy = GetNearestKnownEnemy(MyLoc);
			if( NearestEnemy == None )
			{
				// Got here - no place to go?
				strFail = "Unit("$UnitState.ObjectID$") - OrangeAlertMovement failure.  Not moving.";
				`LogAI(strFail);
				m_bAbortMove = true;
				SkipTurn("from state OrangeAlertMovement- no alert location and no known enemies.");
				GotoState('EndOfTurn');
				return vDest;
			}
			else
			{
				vDest = `XWORLD.GetPositionFromTileCoordinates(NearestEnemy.TileLocation);
			}
		}
		vDest = FindValidPathDestinationToward(vDest);
		GetClosestCoverLocation(vDest, vDest);
		return vDest;
	}
}

private function CheckForCheatManagerMoveDestination()
{
	local XComTacticalCheatManager CheatManager;
	local XComWorldData WorldData;
	local TTile DestinationTile;
	local int ForcedMoveIndex;

	CheatManager = `CHEATMGR;

	ForcedMoveIndex = CheatManager.ForcedDestinationQueue.Find('UnitStateRef', UnitState.GetReference());
	if( ForcedMoveIndex != INDEX_NONE )
	{
		WorldData = `XWORLD;
		DestinationTile = CheatManager.ForcedDestinationQueue[ForcedMoveIndex].MoveDestination;
		m_vBTDestination = WorldData.GetPositionFromTileCoordinates(DestinationTile);
		m_bBTDestinationSet = true;
		CheatManager.ForcedDestinationQueue.Remove(ForcedMoveIndex, 1);
	}
}

//------------------------------------------------------------------------------------------------
state RedAlertMovement extends MoveState
{
	simulated event BeginState(Name P)
	{
		// Refresh patrol group since it may be invalid.
		if( m_kPlayer != None )
		{
			m_kPlayer.m_kNav.IsPatrol(m_kUnit.ObjectID, m_kPatrolGroup);
		}
		`LogAI(m_kUnit@"Beginning RedAlertMovement from"@P);
		super.BeginState(P);
	}

	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState RedAlertMovement Move->"@N);
		m_kLastAIState = name("RedAlertMovement");
		super.EndState(N);
	}
	function Vector DecideNextDestination( optional out string strFail )
	{
		local vector vDest, MyLoc;
		local int nEnemiesVisible;
		local XComGameState_Unit NearestEnemy;

		CheckForCheatManagerMoveDestination();

		if (m_bBTDestinationSet)
		{
			strFail @= "GotDestFromBTSearch.";
			return m_vBTDestination;
		}

		// This code generally won't get hit unless the BT does not specify a destination for red alert. (perhaps this should be a red screen?)
		`Warn("Possible AI error - using old code to find red alert destination since no destination was set from Behavior Tree! Unit#"$UnitState.ObjectID@"Frame#"$DecisionStartHistoryIndex);
		nEnemiesVisible = UnitState.GetNumVisibleEnemyUnits(true,true);//class'X2TacticalVisibilityHelpers'.static.GetNumVisibleEnemyTargetsToSource(m_kUnit.ObjectID);
		MyLoc = GetGameStateLocation();
		vDest = MyLoc;

		// If we have no enemies in sight, go to the last alert location.  Otherwise, 
		// use standard tactical movement with enemies in sight.
		if (nEnemiesVisible == 0)
		{
			if (HasAlertLocation(vDest))
			{
				return vDest;
			}
			else
			{
				// CHEAT - no other options - move toward nearest enemy location.
				NearestEnemy = GetNearestKnownEnemy(MyLoc);
				if( NearestEnemy == None )
				{
					// Got here - no place to go?
					strFail = "Unit("$UnitState.ObjectID$") - RedAlertMovement failure.  Not moving.  No destination defined.";
					`LogAI(strFail);
					m_bAbortMove = true;
					SkipTurn("from state RedAlertMovement-no destination defined.");
					GotoState('EndOfTurn');
					return vDest;
				}
				else
				{
					vDest = `XWORLD.GetPositionFromTileCoordinates(NearestEnemy.TileLocation);
				}
				vDest = FindValidPathDestinationToward(vDest);
				GetClosestCoverLocation(vDest, vDest);
			}
			return vDest;
		}

		return vDest;
	}
}

//------------------------------------------------------------------------------------------------
state AlertDataMovement extends MoveState
{
	simulated event BeginState(Name P)
	{
		`LogAI(m_kUnit@"Beginning AlertDataMovement from"@P);
		super.BeginState(P);
	}

	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState AlertDataMovement Move->"@N);
		m_kLastAIState = name("AlertDataMovement");
		super.EndState(N);
	}

	function Vector DecideNextDestination( optional out string strFail )
	{
		if (m_bAlertDataMovementDestinationSet)
		{
			strFail @= "GotDestFromAlertDataMovementDestinationSearch.";
			return m_vAlertDataMovementDestination;
		}

		strFail = "Unit("$UnitState.ObjectID$") - AlertDataMovement failure.  Not moving.";
		`LogAI(strFail);
		m_bAbortMove = true;
		SkipTurn("from AlertDataMovement - no alert data movement destination set.");
		GotoState('EndOfTurn');
		return m_vBTDestination;
	}
}
//------------------------------------------------------------------------------------------------
state XComMovement extends MoveState // Only accessed via specialized behavior tree, i.e. panic/scamper/etc.
{
	simulated event BeginState(Name P)
	{
		// Refresh patrol group since it may be invalid.
		`LogAI(m_kUnit@"Beginning XComMovement from"@P);
		super.BeginState(P);
	}

	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState XComMovement Move->"@N);
		m_kLastAIState = name("XComMovement");
		super.EndState(N);
	}
	function Vector DecideNextDestination(optional out string strFail)
	{
		if( !m_bBTDestinationSet )
		{
			`RedScreen("XCom ran BehaviorTree to move, but no destination was set! Skipping this unit's turn. (Unit "$UnitState.ObjectID$")");
			m_bAbortMove = true;
			SkipTurn("from state XComMovement - No BT Destination Set.");
			GotoState('EndOfTurn');
		}
		return m_vBTDestination;
	}
}
//------------------------------------------------------------------------------------------------
simulated function bool IsValidPathDestination( vector vLoc, optional out string strFail )
{
	local TTile Tile;

	// Test pathing
	Tile = `XWorld.GetTileCoordinatesFromPosition(vLoc);
	if (m_kUnit.m_kReachableTilesCache.IsTileReachable(Tile))
	{
		if (BaseValidatorDebug(vLoc, strFail))
		{
			return true;
		}
		else
		{
			strFail @= "BaseValidator failed on location("$vLoc.X@vLoc.Y@vLoc.Z$").";
		}
	}
	else
	{
		strFail @= "m_kUnit.m_kReachableTilesCache.IsTileReachable("$Tile.X@ Tile.Y@ Tile.Z$ ") returned FALSE.";
	}

	if (`CHEATMGR != None && `CHEATMGR.bShowPathFailures)
	{
		DrawDebugSphere(vLoc, 5, 10, 255,0,0, true);
	}
	return false;
}
//------------------------------------------------------------------------------------------------
function bool GetTileWithinOneActionPointMove( TTile kTileIn, out TTile kTileOut, bool bAllowDashMovement=false )
{
	local array<TTile> arrPath;
	local int iPathIdx;
	local TTile kCurrTile;
	if (m_kUnit.m_kReachableTilesCache.BuildPathToTile(kTileIn, arrPath) && arrPath.Length > 0)
	{
		for (iPathIdx = arrPath.Length-1; iPathIdx >= 0; --iPathIdx)
		{
			kCurrTile = arrPath[iPathIdx];
			if( IsWithinMovementRange(kCurrTile, bAllowDashMovement) )
			{
				kTileOut = kCurrTile;
				return true;
			}
		}
	}
	return false;
}

//------------------------------------------------------------------------------------------------
simulated function bool HasValidDestinationToward( vector vTarget, out vector vDestination, bool bAllowDash=false )
{
	local TTile kTile, kClosestTile;

	// First.  Get nearest valid dest.  Test for valid path.
	vDestination = XComTacticalGRI(WorldInfo.GRI).GetClosestValidLocation(vTarget, m_kUnit,,false);

	ResetLocationHeight(vDestination);

	if (IsValidPathDestination(vDestination))
	{
		// This may not be accurate if it is a winding path.
		kTile = `XWORLD.GetTileCoordinatesFromPosition(vDestination);
		if (IsWithinMovementRange(kTile, bAllowDash))
		{
			return true;
		}
		else
		{
			if (GetTileWithinOneActionPointMove(kTile, kTile, bAllowDash))
			{
				vDestination = `XWORLD.GetPositionFromTileCoordinates(kTile);
				return true;
			}
		}
	}

	// Force stay in cover if we need to.  Find nearest cover point to our destination.
	kTile = `XWORLD.GetTileCoordinatesFromPosition(vTarget);

	kTile = class'Helpers'.static.GetClosestValidTile(kTile);
	if( !class'Helpers'.static.GetFurthestReachableTileOnPathToDestination(kClosestTile, kTile, UnitState) )
	{
		kClosestTile = m_kUnit.m_kReachableTilesCache.GetClosestReachableDestination(kTile);
		if( !m_kUnit.m_kReachableTilesCache.IsTileReachable(kClosestTile) )
		{
			`RedScreenOnce(`Location@"\nUnit cannot reach 'closest reachable tile' - likely unit is stuck in an unpathable location! \nUnit #"$UnitState.ObjectID @ UnitState.GetMyTemplateName()$"\n@Tile: ("$UnitState.TileLocation.X@UnitState.TileLocation.Y@UnitState.TileLocation.Z$")\n @raasland or @dburchanowski or @acheng\n\n" );
			return false;
		}
	}
	if (kClosestTile != UnitState.TileLocation)
	{
		vDestination = `XWORLD.GetPositionFromTileCoordinates(kClosestTile);
		return true;
	}

	return false;
}

//------------------------------------------------------------------------------------------------
// Failsafe to find a valid destination towards the target, by trial and error.
simulated function vector FindValidPathDestinationToward( vector vTarget, float fMaxDistance = -1, bool bFilterDests=true, bool bSkipBuildDestList=false, optional out string strFail, bool bUseAStar=false)
{
	local Vector vDest;

	if (HasValidDestinationToward( vTarget, vDest ))
	{
		return vDest;
	}

	strFail @= "HasValidDestToward"@vTarget@"failed.";
	// If we get here from green alert, just skip your turn silently.
	if( UnitState.IsUnrevealedAI() )
	{		
		m_bAbortMove = true;
		SkipTurn("from fn FindValidPathDestinationToward, from green alert.  No valid destination towards target location.");
		return vDest;
	}

	`Log(m_kUnit@"FindValidPathDestinationToward failed! No valid locations found!!! Aborting move.");
	SwitchToAttack(strFail);
	return vDest;
}
//------------------------------------------------------------------------------------------------
simulated function SwitchToAttack( string strReason="" )
{
	if (m_bBTDestinationSet)
	{
		`RedScreen("Selected Destination via Behavior Tree, but still switched to attack!\n\nReason:"$strReason @" \n\nSkipping this unit's turn. (Unit "$UnitState.ObjectID$")");
		SkipTurn("called from fn SwitchToAttack, destination is set, state="$GetStateName()@strReason);
		return;
	}
	else if (IsBehaviorTreeAvailable())
	{
		`RedScreen("In Behavior Tree movement, but still switched to attack!\n\nReason:"$strReason @" \n\nSkipping this unit's turn. (Unit "$UnitState.ObjectID$")");
		SkipTurn("called from fn SwitchToAttack, destination is not set, and behavior tree is available. state="$GetStateName()@strReason);
		return;
	}
	m_bAbortMove = true;
	//if (IsDormant()) 
	//	return;

	SkipTurn("called from fn SwitchToAttack, no behavior tree is available.  state="$GetStateName()@strReason);
	`Log("UnitID"@m_kUnit.ObjectID@"aborting Move, with no attack options.  Ending Turn."@strReason);
	GotoState('EndOfTurn');
}
//------------------------------------------------------------------------------------------------
simulated function bool HasAoEAbility(optional out int iObjectID, optional Name strAbilityName )
{
	local AvailableAction kAbility;
	local XComGameState_Ability kAbilityState;
	local X2AbilityTemplate kTemplate;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;
	if( strAbilityName != '' )
	{
		kAbility = FindAbilityByName(strAbilityName, kAbilityState);
		if (kAbility.AbilityObjectRef.ObjectID > 0 )
		{
			kAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(kAbility.AbilityObjectRef.ObjectID));
			kTemplate = kAbilityState.GetMyTemplate();
			if( kTemplate.AbilityMultiTargetStyle != None )
			{
				iObjectID = kAbility.AbilityObjectRef.ObjectID;
				return true;
			}
		}
	}
	else
	{
		foreach UnitAbilityInfo.AvailableActions(kAbility)
		{
			kAbilityState = XComGameState_Ability(History.GetGameStateForObjectID( kAbility.AbilityObjectRef.ObjectID ));
			kTemplate = kAbilityState.GetMyTemplate();
			if (kTemplate.AbilityMultiTargetStyle != None && kTemplate.AbilityMultiTargetStyle.IsA('X2AbilityMultiTarget_Radius'))
			{
				iObjectID = kAbilityState.ObjectID;
				return true;
			}
		}
	}

	return false;
}

//------------------------------------------------------------------------------------------------
// Test IsInCover from GameState_Unit location.  More accurate than visualizer's location / cover state, when in mid-move.
function bool IsInCover()
{
	local ECoverType Cover;
	local array<StateObjectReference> VisibleUnits;
	local  StateObjectReference kObjRef;
	local vector vTarget, vShooter;
	local XComGameState_Unit kEnemy;
	local float TrashAngle;
	//local int iCurrHistoryIndex;
	local bool bInCover;
	if (CanUseCover())
	{
		//iCurrHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
		//if (m_iLastCoverRefresh != iCurrHistoryIndex)
		//{
			//m_iLastCoverRefresh = iCurrHistoryIndex;
			vTarget = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);
			class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(m_kUnit.ObjectID, VisibleUnits);
			if (VisibleUnits.Length > 0) // First - default InCover value is only true if enemies are visible.
				bInCover = true; 
			else
				bInCover = false;

			// Mark as not-in-cover if any enemies can see this guy out of cover.
			foreach VisibleUnits(kObjRef)
			{
				kEnemy = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kObjRef.ObjectID));
				if( kEnemy.IsCivilian() )  // Don't check cover against civilians.  (retaliation levels)
				{
					continue;
				}
				vShooter = `XWORLD.GetPositionFromTileCoordinates(	kEnemy.TileLocation );
				Cover = `XWORLD.GetCoverTypeForTarget(vShooter, vTarget, TrashAngle);
				if (Cover == CT_None)
					bInCover = false;
			}
		//}
		return bInCover;
	}
	return false;
}
//------------------------------------------------------------------------------------------------
function bool IsInDangerousArea(optional out string strDebug)
{
	local int nEnemiesVisible;
	
	nEnemiesVisible = UnitState.GetNumVisibleEnemyUnits(true,true);//class'X2TacticalVisibilityHelpers'.static.GetNumVisibleEnemyTargetsToSource(m_kUnit.ObjectID);

	if( UnitState.IsUnitAffectedByEffectName(class'X2Effect_MindControl'.default.EffectName))
	{
		return false; // No area too dangerous for mind-controlled enemies.
	}

	if (CanUseCover())
	{
		// Flanked check. 
		if (nEnemiesVisible > 0 && !IsInCover())
		{
			strDebug@="AIBehavior::IsInDangerousArea==TRUE: Unit takes cover, EnemiesVis>0 && !IsInCover()";
			return true;
		}
	}

	// Check for damaging volume effects.  (fire/poison/acid, if vulnerable)
	if( class'XComPath'.static.TileContainsHazard(UnitState, UnitState.TileLocation) )
	{
		strDebug @= "AIBehavior::IsInDangerousArea==TRUE: Tile contains hazard.";
		return true;
	}

	// Check for fire and explosives 
	return m_kPlayer.IsInDangerousArea( m_kUnit.GetGameStateLocation(), strDebug );
}
//------------------------------------------------------------------------------------------------
function int GetWeaponRangeModAtLocation( vector vLocation, XGUnit kEnemy )
{
	local XGWeapon kWeapon;
	kWeapon = m_kUnit.GetInventory().GetPrimaryWeapon();
	return `GAMECORE.CalcRangeModForWeaponAt(kWeapon.GameplayType(), m_kUnit, kEnemy, vLocation);
}

//------------------------------------------------------------------------------------------------
function int GetHitChanceEstimateFrom( vector vLocation, XGUnit kEnemy, bool TestVisibility=true )
{
	return 0;
}

//------------------------------------------------------------------------------------------------
function float GetDistanceFromUnitID(int TargetID)
{
	local XComGameState_Unit Target;
	Target = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetID));
	if( Target == None )
	{
		`RedScreenOnce("Invalid Target ID entered for function XGAIBehavior::GetDIstanceFromUnitID: ("$TargetID$") - @ACHENG");
		return 0;
	}
	return GetDistanceFromEnemy(Target);
}

function float GetDistanceFromEnemy( XComGameState_Unit kEnemy )
{
	local vector EnemyLocation;
	EnemyLocation = `XWORLD.GetPositionFromTileCoordinates(kEnemy.TileLocation);
	return VSize(EnemyLocation - m_kUnit.GetGameStateLocation());
}

//------------------------------------------------------------------------------------------------
simulated function OnCompleteAbility(AvailableAction kAbility, array<vector> TargetLocations)
{
	local String AbilityName;
	local XComGameState_Ability AbilityState;
	local Name TwoTurnAttackAbilityName;
	local TTile Tile;
	AbilityName = GetAbilityName(kAbility);
	if (AbilityName == "Yell")
	{
		m_kPlayer.RestartYellCooldown(); // Enforce WristCom global cooldown.
	}
	if( PrimedAoEAbility == kAbility.AbilityObjectRef.ObjectID
	   && AoERepeatAttackExclusionList.Find(AbilityName) == INDEX_NONE )
	{
		// Save the targeted aoe location, prevent repeated aoe attacks here.
		Tile = `XWORLD.GetTileCoordinatesFromPosition(TopAoETarget.Location);
		m_kPlayer.AoETargetedThisTurn.AddItem(Tile);
	}
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAbility.AbilityObjectRef.ObjectID));
	TwoTurnAttackAbilityName = AbilityState.GetMyTemplate().TwoTurnAttackAbility;
	if( TwoTurnAttackAbilityName != '' )
	{
		FindAbilityByName(TwoTurnAttackAbilityName, AbilityState);
		if( AbilityState != None )
		{
			m_kPlayer.AddTwoTurnAttackTargets(TargetLocations, AbilityState);
		}
	}
}

//------------------------------------------------------------------------------------------------

function vector GetTargetDestination()
{
	return m_vDebugDestination;
}

function SkipGroupTurn()
{
	local XComGameStateContext_TacticalGameRule EndTurnContext;
	local XGAIGroup Group;
	local int UnitID;
	if( m_kPlayer != None )
	{
		m_kPlayer.m_kNav.GetGroupInfo(UnitState.ObjectID, Group);
	}
	if( Group != None )
	{
		foreach Group.m_arrUnitIDs(UnitID)
		{
			EndTurnContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
			EndTurnContext.GameRuleType = eGameRule_SkipUnit;
			EndTurnContext.UnitRef = `XCOMHISTORY.GetGameStateForObjectID(UnitID).GetReference();
			`XCOMGAME.GameRuleset.SubmitGameStateContext(EndTurnContext);
			`CHEATMGR.AIStringsUpdateString(UnitID, "SkippedTurn.");
			if( m_kPlayer != None )
			{
				m_kPlayer.InvalidateUnitToMove(UnitID);
			}
		}
	}
}

// Force unit to end its turn, used for non-active units, and for major failures in AI ability selection.
simulated function SkipTurn( optional string DebugLogText="" )
{
	local XComGameStateContext_TacticalGameRule EndTurnContext;

	`logAI("XGAIBehavior::SkipTurn::"$m_kUnit @ self@m_kUnit.ObjectID@ DebugLogText);

	RefreshUnitCache();
	if (UnitState.NumAllActionPoints() != 0)
	{
		// If unrevealed, the entire group skips its turn.  Fixes assert with group movement, after group leader skips its move.
		if( StartedTurnUnrevealed() )
		{
			SkipGroupTurn();
		}
		else
		{
			EndTurnContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
			EndTurnContext.GameRuleType = eGameRule_SkipUnit;
			EndTurnContext.UnitRef = `XCOMHISTORY.GetGameStateForObjectID(m_kUnit.ObjectID).GetReference();
			`XCOMGAME.GameRuleset.SubmitGameStateContext(EndTurnContext);
			`CHEATMGR.AIStringsUpdateString(m_kUnit.ObjectID, "SkippedTurn.");
		}
	}
	if (m_kPlayer != None)
	{
		m_kPlayer.InvalidateUnitToMove(m_kUnit.ObjectID);
	}
}


// BT conditions
function bool HasAmmo()
{
	local AvailableAction kShot;
	local XComGameState_Ability AbilityState;
	local array<name> ErrorList;
	// Second move - shoot if we have a shot.
	kShot = GetShotAbility(true);
	if( kShot.AbilityObjectRef.ObjectID > 0 )
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kShot.AbilityObjectRef.ObjectID));
		ErrorList = AbilityState.GetAvailabilityErrors(UnitState);

		// Check if ammo cost is one of the reasons this shot is not available.
		if( ErrorList.Find('AA_CannotAfford_AmmoCost') != INDEX_NONE )
		{
			return false;
		}

		return true;
	}
	`LogAIBT("No standard shot ability found!  HasAmmo return false.");
	return false;
}

function bool IsLastActionPoint()
{
	return UnitState.NumAllActionPoints() == 1;
}

function AvailableAction FindAbilityByName( name strName, optional out XComGameState_Ability kAbilityState )
{
	local AvailableAction kAbility, kNullAbility;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	foreach UnitAbilityInfo.AvailableActions(kAbility)
	{
		kAbilityState = XComGameState_Ability(History.GetGameStateForObjectID( kAbility.AbilityObjectRef.ObjectID ));
		if (kAbilityState.GetMyTemplateName() == strName)
		{
			return kAbility;
		}
	}
	kAbilityState = None;
	`LogAIBT("Ability NOT FOUND: "$strName@"\n");
	return kNullAbility;
}

function AvailableAction FindAbilityByID( int iObjectID )
{
	local AvailableAction kNullAbility;
	local int iAbility;
	local StateObjectReference kAbilityRef;
	kAbilityRef.ObjectID = iObjectID;
	iAbility = UnitAbilityInfo.AvailableActions.Find('AbilityObjectRef', kAbilityRef);
	if (iAbility != -1)
	{
		return UnitAbilityInfo.AvailableActions[iAbility];
	}
	return kNullAbility;
}

function bool IsValidAbility(name AbilityName, optional out String DebugText)
{
	local AvailableAction kAbility;
	kAbility = FindAbilityByName(AbilityName);
	if (kAbility.AbilityObjectRef.ObjectID > 0)
	{
		return IsValidAction(kAbility, DebugText);
	}
	else
	{
		DebugText @= "Ability not found: "$AbilityName;
	}
	return false;
}

function vector GetXComMidPoint()
{
	local vector XComLocation;
	local float  Radius;
	m_kPlayer.GetSquadLocation(XComLocation, Radius);
	return XComLocation;
}
// This function returns the closest _pathable_ cover location to the given location.  Uses pathable tile cache.
function bool GetClosestCoverLocation(vector vLocation, out vector vCoverLoc_out, bool bExitEarlyIfUnseen=true, bool bCheckBestAlertDataTileLocation=false, optional array<vector> FlankedCheck)
{
	local vector vCover, vClosestCover, vAlertDataLoc, FlankerLoc;
	local XComWorldData WorldData;
	local TTile kTile;
	local XComCoverPoint CoverPoint;
	local array<GameRulesCache_VisibilityInfo> arrEnemyInfos;
	local GameRulesCache_VisibilityInfo kEnemyInfo;
	local float fDistSq, fClosestSq;
	local bool bFlanked;
	local XComGameState_AIUnitData kUnitData;
	local int iDataID;
	local TTile AlertTileLocation;
	local array<StateObjectReference> arrKnownEnemyList;

	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
	if( iDataID > 0 )
	{
		kUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));
		kUnitData.GetAbsoluteKnowledgeUnitList(arrKnownEnemyList,,,false);
	}

	WorldData = `XWORLD;
	fClosestSq = -1;

	if (bExitEarlyIfUnseen && arrKnownEnemyList.Length == 0)
	{
		vCoverLoc_out = vLocation;
		return true;
	}

	if (bCheckBestAlertDataTileLocation)
	{
		AlertTileLocation = kUnitData.m_arrAlertData[m_iAlertDataScoreHighestIndex].AlertLocation;
		vAlertDataLoc = WorldData.GetPositionFromTileCoordinates(AlertTileLocation);
	}

	foreach m_kUnit.m_kReachableTilesCache.CoverDestinations(vCover)
	{
		kTile = WorldData.GetTileCoordinatesFromPosition(vCover);
		bFlanked = false;
		if( `CHEATMGR != None && `CHEATMGR.DebugInspectTileDest(kTile) )
		{
			`Log("Inspecting tile ("$kTile.X@kTile.Y@kTile.Z$")...");
		}

		if (m_bBTCanDash || m_kUnit.m_kReachableTilesCache.GetPathCostToTile(kTile) <= m_kUnit.GetMobility())
		{
			if (!IsInBadArea(vLocation))
			{
				WorldData.GetCoverPointAtFloor(vCover, CoverPoint);
				// Check flanking.
				if (bCheckBestAlertDataTileLocation)
				{
					// TODO: This may not be using the proper visibility checks
					bFlanked = class'XGUnitNativeBase'.static.DoesFlankCover(vAlertDataLoc, CoverPoint);
				}
				// Check additional flank checks.  
				if( !bFlanked )
				{
					foreach FlankedCheck(FlankerLoc)
					{
						bFlanked = class'XGUnitNativeBase'.static.DoesFlankCover(FlankerLoc, CoverPoint);
						if( bFlanked )
						{
							break;
						}
					}
				}
				
				if (!bFlanked)
				{
					// Test all enemies that can see this point
					arrEnemyInfos.Length = 0;
					class'X2TacticalVisibilityHelpers'.static.GetAllEnemiesForLocation(CoverPoint.TileLocation, UnitState.ControllingPlayer.ObjectID, arrEnemyInfos);
					foreach arrEnemyInfos(kEnemyInfo)
					{
						// Ignore enemies this unit isn't aware of
						if (kEnemyInfo.TargetCover == CT_None 
							&& kEnemyInfo.bClearLOS
							&& kEnemyInfo.DefaultTargetDist < m_fSightRangeSq
							&& arrKnownEnemyList.Find('ObjectID', kEnemyInfo.SourceID) != -1)
						{
							bFlanked = true;
							break;
						}
					}
				}

				if (bFlanked)
					continue;

				fDistSq=VSizeSq(vLocation-vCover);
				if (fClosestSq == -1 || fDistSq < fClosestSq)
				{
					fClosestSq = fDistSq;
					vClosestCover = vCover;
				}
			}
		}
	}

	if (fClosestSq >= 0)
	{
		vCoverLoc_out = vClosestCover;
		return true;
	}
	vCoverLoc_out = vLocation;
	return false;
}

function bool PickRandomCoverLocation(out vector RandCover_out, float MinTileDist, float MaxTileDist, bool bRequireEnemyLoS=true)
{
	local array<vector> CoverList;
	local int Index;
	if( CollectUnflankedCoverLocations(GetGameStateLocation(), CoverList, MinTileDist, MaxTileDist,, bRequireEnemyLoS) )
	{
		Index = `SYNC_RAND(CoverList.Length);
		RandCover_out = CoverList[Index];
		return true;
	}

	`RedScreen("Cleave/Clone/Teleport error - Could not find any visible unflanked cover locations found within range!  @acheng");
	RandCover_out = GetGameStateLocation();
	return false;
}

function bool CollectUnflankedCoverLocations(vector vLocation, out array<vector> CoverList_out, float MinTileDist, float MaxTileDist, optional array<vector> FlankedCheck, bool bRequireEnemyLoS=true)
{
	local vector vCover, FlankerLoc;
	local XComWorldData WorldData;
	local XComCoverPoint CoverPoint;
	local array<GameRulesCache_VisibilityInfo> arrEnemyInfos;
	local GameRulesCache_VisibilityInfo kEnemyInfo;
	local bool bFlanked, bVisible;
	local XComGameState_AIUnitData kUnitData;
	local int iDataID, EnemyPlayerID;
	local array<StateObjectReference> arrKnownEnemyList;
	local array<XComCoverPoint> Superset, Subset;
	local array<vector> VisibleCoverList;
	local float MinRange, MaxRange;
	local TTile CoverTile;

	iDataID = GetAIUnitDataID(m_kUnit.ObjectID);
	if( iDataID > 0 )
	{
		kUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));
		kUnitData.GetAbsoluteKnowledgeUnitList(arrKnownEnemyList, , , false);
	}

	WorldData = `XWORLD;
	MinRange = `TILESTOUNITS(MinTileDist);
	MaxRange = `TILESTOUNITS(MaxTileDist);
	WorldData.GetCoverPoints(vLocation, MaxRange, MaxRange, Superset);
	WorldData.GetCoverPoints(vLocation, MinRange, MinRange, Subset);

	EnemyPlayerID = `BATTLE.GetEnemyPlayer(m_kUnit.m_kPlayer).ObjectID;

	foreach Superset(CoverPoint)
	{
		if( Subset.Find('TileLocation', CoverPoint.TileLocation) == INDEX_NONE  // Skip any cover inside the min range.
		   && XComTacticalGRI(WorldInfo.GRI).IsValidLocation(CoverPoint.TileLocation, m_kUnit) )
		{
			CoverTile.X = CoverPoint.X;
			CoverTile.Y = CoverPoint.Y;
			CoverTile.Z = CoverPoint.Z;
			// Check if point is visible to the enemy player.  Can only be teleported into a visible tile.
			if( EnemyPlayerID > 0
			   && !class'X2TacticalVisibilityHelpers'.static.CanSquadSeeLocation(EnemyPlayerID, CoverTile) )
			{
				continue;
			}


			bFlanked = false;
			bVisible = false;
			vCover = CoverPoint.TileLocation;

			// Test all enemies that can see this point
			arrEnemyInfos.Length = 0;
			class'X2TacticalVisibilityHelpers'.static.GetAllEnemiesForLocation(vCover, UnitState.ControllingPlayer.ObjectID, arrEnemyInfos);
			foreach arrEnemyInfos(kEnemyInfo)
			{
				// Ignore enemies this unit isn't aware of
				if( kEnemyInfo.TargetCover == CT_None
				   && kEnemyInfo.bClearLOS
				   && arrKnownEnemyList.Find('ObjectID', kEnemyInfo.SourceID) != -1 )
				{
					bFlanked = true;
					break;
				}
				if( kEnemyInfo.bVisibleGameplay )
				{
					bVisible = true;
				}
			}

			if( !bFlanked )
			{
				// Check additional flank checks.  
				foreach FlankedCheck(FlankerLoc)
				{
					bFlanked = class'XGUnitNativeBase'.static.DoesFlankCover(FlankerLoc, CoverPoint);
					if( bFlanked )
					{
						break;
					}
				}
			}

			if( bFlanked )
				continue;

			CoverList_out.AddItem(vCover);
			if( bVisible )
			{
				VisibleCoverList.AddItem(vCover);
			}
		}
	}

	// Prefer the visible cover list if it is nonempty.
	if( VisibleCoverList.Length > 0 && VisibleCoverList.Length != CoverList_out.Length )
	{
		CoverList_out = VisibleCoverList;
	}
	return CoverList_out.Length > 0;
}
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// State code
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// Overwritten in XGAIBehavior_Civilian
simulated function OnUnitEndTurn()
{
}
//------------------------------------------------------------------------------------------------
state EndOfTurn
{
	simulated event BeginState(Name P)
	{
		`LogAI(m_kUnit@"Beginning state : EndOfTurn");
		`LogAI("super.BeginState fn call completed."$m_strDebugLog);
	}
	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState EndOfTurn ->"@N);
	}

Begin:

	Sleep(0.1f);

	OnUnitEndTurn();
//		`Log("Completed OnUnitEndTurn fn. Entering state Inactive."@self@GetStateName());

	GotoState('Inactive');
}
//------------------------------------------------------------------------------------------------
simulated event Tick( float fDeltaT )
{
	//local Vector vSphere;
	local XComTacticalCheatManager kCheatMgr;
	`if(`isdefined(FINAL_RELEASE))
//		SetTickIsDisabled(true);  // Cannot disable ticking otherwise state code will never run.
		return;
	`endif

	kCheatMgr = `CHEATMGR;
	if( kCheatMgr != none )
	{
		if( m_kUnit != none &&
		   (kCheatMgr.bShowDestination
		   || kCheatMgr.bDisplayPathingFailures
		   || kCheatMgr.bTurning
		   || kCheatMgr.bMarker
		   || kCheatMgr.bShowTracking
		   || kCheatMgr.bShowAttackRange
		   || kCheatMgr.bShowVisibleEnemies
		   ) )
		{
			DebugDrawDestination();
			DebugDrawPathFailures();
			if( m_kUnit.IsAliveAndWell() )
			{
				if( kCheatMgr.bTurning )
				{
					DrawDebugLine(m_kUnit.GetGameStateLocation() + vect(0, 0, 0), m_kUnit.GetGameStateLocation() + m_vDebugDir[0] * 64 + vect(0, 0, 0), 255, 128, 0, false);
					DrawDebugLine(m_kUnit.GetGameStateLocation() + vect(5, 5, 5), m_kUnit.GetGameStateLocation() + m_vDebugDir[1] * 64 + vect(5, 5, 5), 255, 0, 0, false);
					DrawDebugLine(m_kUnit.GetGameStateLocation() + vect(10, 10, 10), m_kUnit.GetGameStateLocation() + Vector(m_kUnit.GetPawn().Rotation) * 64 + vect(10, 10, 10), 255, 255, 255, false);
				}
				if( kCheatMgr.bMarker )
				{
					DrawDebugLine(m_kUnit.GetGameStateLocation(), m_kUnit.GetGameStateLocation() + vect(0, 0, 400), 255, 0, 0, false);
				}
				if( kCheatMgr.bShowAttackRange )
				{
					if( m_kUnit.GetInventory() != None && m_kUnit.GetInventory().GetActiveWeapon() != None )
					{
						XComPresentationLayer(XComTacticalController(XGBattle_SP(`BATTLE).GetHumanPlayer().Owner).Pres).DRAWRange(m_kUnit.GetGameStateLocation(),
							m_kUnit.GetInventory().GetActiveWeapon().LongRange(), MakeLinearColor(1, 0, 0, 0.2));
					}
				}
			}
		}
		if( kCheatMgr.bDebugAIDestinations && UnitState != None && kCheatMgr.DebugMoveObjectID == UnitState.ObjectID )
		{
			DebugDrawDestinationScoring();
		}
	}
}

//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
function AvailableAction GetMoveAbility()
{
	local AvailableAction kNullAction, kAction;
	foreach UnitAbilityInfo.AvailableActions(kAction)
	{
		if( IsValidAction(kAction) && GetAbilityName(kAction) == "StandardMove" )
		{
			return kAction;
		}
	}
	return kNullAction;
}

//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
function bool GetCheatOverride(out AvailableAction kAbility, out Name OverrideAbilityName_out)
{
	local XComWorldData WorldData;
	local AvailableAction kAction;
	local TTile DestinationTile;
	local int ForcedMoveIndex;

	ForcedMoveIndex = `CHEATMGR.ForcedDestinationQueue.Find('UnitStateRef', UnitState.GetReference());
	if( ForcedMoveIndex != INDEX_NONE )
	{
		WorldData = `XWORLD;
		DestinationTile = `CHEATMGR.ForcedDestinationQueue[ForcedMoveIndex].MoveDestination;
		m_vBTDestination = WorldData.GetPositionFromTileCoordinates(DestinationTile);
		m_bBTDestinationSet = true;
		kAbility = GetMoveAbility();
		OverrideAbilityName_out = 'StandardMove';
		`CHEATMGR.ForcedDestinationQueue.Remove(ForcedMoveIndex, 1);

		return true;
	}
	if( `CHEATMGR.strAIForcedAbility != "" )
	{
		foreach UnitAbilityInfo.AvailableActions(kAction)
		{
			if( GetAbilityName(kAction) ~= `CHEATMGR.strAIForcedAbility && IsValidAction(kAction) )
			{
				kAbility = kAction;
				OverrideAbilityName_out = Name(`CHEATMGR.strAIForcedAbility);
				if( IsValidAction(kAbility) )
				{
					if( `CHEATMGR.bForceAbilityOneTimeUse )
					{
						`CHEATMGR.strAIForcedAbility = "";
					}
					return true;
				}
				return false;
			}
		}
	}
	return false;
}

//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
static function string GetAbilityName(AvailableAction kAction)
{
	local XComGameState_Ability kAbilityState;
	local name kAbilityName;

	kAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID));
	if( kAbilityState != None )
	{
		kAbilityName = kAbilityState.GetMyTemplateName();
	}
	return string(kAbilityName);
}

//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class 
function SetTargetIndexByObjectID(int TargetObjectID)
{
	local AvailableTarget kTarget;
	local int iTarget;
	for( iTarget = 0; iTarget < SelectedAbility.AvailableTargets.Length; iTarget++ )
	{
		kTarget = SelectedAbility.AvailableTargets[iTarget];
		if( kTarget.PrimaryTarget.ObjectID == TargetObjectID )
		{
			BTTargetIndex = iTarget;
			return;
		}
	}
	`RedScreen("Target not found in available targets for ability!"@GetAbilityName(SelectedAbility)@"Setting target index to 0.");
	`LogAI("Target not found in available targets for ability!"@GetAbilityName(SelectedAbility)@"Setting target index to 0.");
	BTTargetIndex = 0;
}

//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class.  (was: IsValidAbility)
function bool IsValidAction(AvailableAction kAbility=SelectedAbility, optional out string kDebugFailure)
{
	local XComGameState_Ability kAbilityState;

	if( kAbility.AvailableCode != 'AA_Success' )
	{
		kDebugFailure @= "AvailableCode != eAASuccess ("$kAbility.AvailableCode$")";
		return false;
	}

	kAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAbility.AbilityObjectRef.ObjectID));
	if( kAbilityState == None )
	{
		kDebugFailure @= "Invalid ability object ID!";
		return false;
	}

	return kAbility.AvailableCode == 'AA_Success'
		&& kAbility.AbilityObjectRef.ObjectID > 0;
}
//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
function bool IsMoveAbility(AvailableAction kAbility=SelectedAbility)
{
	local string kAbilityName;

	kAbilityName = GetAbilityName(kAbility);

	if( kAbilityName == "StandardMove" )
	{
		return true;
	}
	return false;
	//	return m_kAbility.GetType() == eAbility_Move || m_kAbility.GetType() == eAbility_Launch;
}

//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
function bool IsValidTarget(AvailableTarget kTarget)
{
	local XComGameStateHistory History;
	local XComGameState_Unit kTargetState;
	if( kTarget.AdditionalTargets.Length > 0 )
	{
		return true;
	}
	if( kTarget.PrimaryTarget.ObjectID <= 0 )
	{
		return false;
	}

	// Only allow AI to target enemies that have been spotted.
	if( UnitState.ControllingPlayerIsAI() && m_kPlayer != None ) // Spotted / concealment check is only valid for AI.
	{
		History = `XCOMHISTORY;
			kTargetState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
		if( kTargetState.bRemovedFromPlay )
		{
			return false;
		}
		if( kTargetState != None
		   && (kTargetState.GetTeam() == eTeam_XCom) )   // This check only valid against XCom. 
		{
			if( m_kPlayer.bAIHasKnowledgeOfAllUnconcealedXCom && kTargetState.IsConcealed() )
			{
				`LogAI("Target"@kTargetState.ObjectID@"not valid: Target is concealed!");
				return false;
			}
			else if (!m_kPlayer.bAIHasKnowledgeOfAllUnconcealedXCom && !kTargetState.IsSpotted())// Fail if not spotted.
			{
				`LogAI("Target "@kTargetState.ObjectID@"not valid: Not Spotted.");
				return false;
			}
		}
	}
	return true;
}

//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
function XGWeapon GetWeapon()
{
	local XComGameState_Ability kAbilityState;
	local XComGameState_Item kWeaponState;

	if( SelectedAbility.AbilityObjectRef.ObjectID > 0 && !IsMoveAbility(SelectedAbility) )
	{
		kAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectedAbility.AbilityObjectRef.ObjectID));
		kWeaponState = kAbilityState.GetSourceWeapon();
		if( kWeaponState != None )
		{
			return XGWeapon(kWeaponState.GetVisualizer());
		}
	}
	return none;
}

//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
function string GetStandardShotName()
{
	local Name ShotAbility;
	ShotAbility = 'StandardShot';
	class'X2AIBTLeafNode'.static.ResolveAbilityNameWithUnit(ShotAbility, self);
	return String(ShotAbility);
}
//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
function AvailableAction GetShotAbility(bool bIgnoreValidity = false)
{
	local AvailableAction kNullAction, kAction;
	local String ShotAbility;
	ShotAbility = GetStandardShotName();
	foreach UnitAbilityInfo.AvailableActions(kAction)
	{
		if( (bIgnoreValidity || IsValidAction(kAction)) && GetAbilityName(kAction) == ShotAbility )
			return kAction;
	}
	return kNullAction;
}
//------------------------------------------------------------------------------------------------
// from deprecated XGAIAbilityDM class
function AvailableAction GetAvailableAbility(string strAbilityName, bool bAllowInvalid = false, optional out string strError)
{
	local AvailableAction kNullAction, kAction, kSaved;
	local bool bFound;
	foreach UnitAbilityInfo.AvailableActions(kAction)
	{
		if( GetAbilityName(kAction) == strAbilityName )
		{
			bFound = true;
			if( IsValidAction(kAction, strError) )
				return kAction;
			if( bAllowInvalid && kSaved.AbilityObjectRef.ObjectID == kNullAction.AbilityObjectRef.ObjectID )
			{
				kSaved = kAction;
			}
		}
	}
	if( !bFound )
	{
		strError @= "Action not found in AvailableActions list.";
	}
	return kSaved; // == NullAction if bAllowInvalid is false.
}

replication
{
	if( Role == Role_Authority )
		m_kUnit;
}

defaultproperties
{
	// Networking variables -tsmith 
	//RemoteRole=ROLE_SimulatedProxy
	//bAlwaysRelevant=true
	RemoteRole=ROLE_None
	bAlwaysRelevant=false
	m_bUnitAbilityCacheDirty=true
	DefaultMeleeIdealRange=1.5f
	MAX_EXPECTED_ENEMY_COUNT=4.0f;
	MIN_ENEMY_VIS_PEAK1_VALUE=0.1f;
	VIS_ALLY_PLATEAU_VALUE=4.0f;
	MaxDistScoreNoKnownEnemies=25.0f;
	AIUnitDataID=INDEX_NONE
}

