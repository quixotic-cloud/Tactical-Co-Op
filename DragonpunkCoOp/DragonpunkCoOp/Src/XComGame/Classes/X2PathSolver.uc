//---------------------------------------------------------------------------------------
//  FILE:    X2PathSolver.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Utility class for solving unit pathing.
//
//  See http://en.wikipedia.org/wiki/A* and http://en.wikipedia.org/wiki/Dijkstra%27s_algorithm for more info
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2PathSolver extends Object
	dependson(XGTacticalGameCoreNativeBase)
	config(GameCore)
	native(Core);

cpptext
{	
	// callback object to add a layer of indirection between the thing doing the pathing and the pathing callbacks
	// Allows non-units to also use the same pathing functions
	class FPathSolveInformation
	{
	public:
		FPathSolveInformation(INT InValidTraversals[eTraversal_MAX], INT InPathingSize, UXComGameState_Unit* InUnit = NULL, UBOOL InDisablePathBiasing = FALSE);

		UBOOL IsTraversalValid(ETraversalType Traversal) const
		{
			check(Traversal < eTraversal_MAX);
			return ValidTraversals[Traversal] > 0;
		}

		// caching wrapper to efficiently determine if a unit is affected by a given tile effect.
		// tile effects are things such as smoke, fire, etc.
		UBOOL IsImmuneToTileEffect(FName TileEffectName);

		// basic information about the pathing object
		const UBOOL DisablePathBiasing;
		const INT PathingSize;
		const INT PathingHeight;
		const UXComGameState_Unit* Unit;

		// cache variables to speed up expensive repeat function calls
		const UBOOL UnitShouldAvoidPathingNearCover;
		const UBOOL UnitShouldAvoidWallSmashing; // should we avoid large unit only wall smashes?
		const UBOOL UnitShouldAvoidDestruction; // should this unit avoid smashing through smaller things, like windows?
		const UBOOL UnitShouldExtraAvoidDestruction; //Optional "extra" bias against destruction. Motivating use-case: AI unit, not yet seen by player.
		const UBOOL DisallowHazardPathing; // if true, tiles with hazards on them will be completely disregarded
		const struct FConcealmentBreakingTilesCache* ConcealmentCache; // concealment cache for the unit, if any
		const UX2PathSolver& DefaultPathSolverObject; // for getting configurable cost bias values

	private:
		const struct FConcealmentBreakingTilesCache* GetConcealmentCacheForUnit(class UXComGameState_Unit* InUnit);

		TMap<FName, UBOOL> IsImmuneToTileEffectMap;
		INT ValidTraversals[eTraversal_MAX];
	};

	// allows the pathing pawn and other systems to determine if a given traversal can be taken, for purposes of pathing
	static UBOOL IsTraversalValid(const FPathingTraversalData& Traversal, FPathSolveInformation& PathingInfo);
}

// bias values are in tiles. if climb bias is 5, the unit would have to path 6 tiles out of his way
// before the climb path is considered preferable.
// bias values apply to the X2ReachableTilesCache as well
var const config float BreakStuffBias; // bias applied when crashing through windows or walls
var const config float ExtraBreakStuffBias; // extra bias applied when it's an AI, that the player can't see, breaking things
var const config float KickDoorBias; // bias applied when kicking a door open
var const config float ClimbBias; // bias applied when climbing up, over, or onto a ladder
var const config float ClimbOverBias; // bias applied when doing climbover
var const config float AIAvoidCoverBias; // when not in alert, the bias value ai will use to avoid walking right up against a wall
var const config float PathHazardBias; // bias applied when we're going to run through fire, smoke, poision, etc.
var const config float ConcealmentBreakingBias; // bias applied when we're going to break concealment.
var const config float AscendingBias; // bias applied when a flying unit is ascending. Should be negative so we favor ascension
var const config float LaunchBias; // bias applied against beginning flight
var const config float LargeUnitOnlyBias; // bias applied when doing traversals that require smashing through walls

native static function bool BuildPath(XComGameState_Unit Unit, TTile StartTile, TTile EndTile, out array<TTile> Path, optional bool LimitToUnitRange = false, optional out float PathCost);
native static function bool BuildRamPath(XComGameState_Unit Unit, vector StartPos, vector EndPos, out array<PathPoint> Path);

// Builds a path for things that aren't units. You provide the start and end points and the traversals the path is allowed to take,
// and it will return the path
native static function bool BuildNonUnitPath(TTile StartTile, 
											 TTile EndTile, 
											 const out array<ETraversalType> AllowedTraversalTypes, 
											 out array<TTile> Path, 
											 optional int MaxCost, 
											 optional out float PathCost);

native static function GetPathPointsFromPath(XComGameState_Unit Unit, const out array<TTile> Path, out array<PathPoint> PathPoints);

// returns true if the given unit is unable to move at least MinTileDistance tiles away from their origin
native static function bool IsUnitTrapped(XComGameState_Unit Unit, optional int MinTileDistance = 6);