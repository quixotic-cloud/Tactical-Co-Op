//---------------------------------------------------------------------------------------
//  FILE:    X2ReachableTilesCache.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Utility class for gathering all reachable tiles for a given unit. All pathing queries are
//           backed by an automatically updating tile cache, and are designed to be called hundreds of times
//           per frame with little to no performance impact.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2ReachableTilesCache extends Object
	dependson(XGTacticalGameCoreNativeBase)
	native(Core);

struct native TileCacheEntry
{
	var TTile ParentTile;
	var float CostToTile;
};

struct native LadderTraversal
{
	var TTile LowerTile; // tile at the bottom of the ladder
	var TTile UpperTile; // tile at the top of the ladder
	var bool ClimbUp; // if true, this traversal climbs up the ladder. Otherwise it climbs down.
};

enum TileCacheMapping
{
	BiasedTileCacheMapping, // the given destination tile should be built from the biased cache
	UnbiasedTileCacheMapping, // the given destination tile should be build from the unbiased cache
};

// There are actually two tile caches. On contains paths to all tiles in a pretty, obstacle avoiding method. This is the
// cache that is used to go around fences, avoid obstructions, etc. However, this causes some tiles to be otherwise out of reach,
// or to take two move points when they could be reached in just one. for these cases, we maintain a second tile cache which
// contains direct, minimum cost paths.
// note that aliens just use the biased tile cache, but that that's not something outside users of this system need to know.
var private native Map_Mirror BiasedTileCache { TMap<FTTile, FTileCacheEntry> }; // cache of tiles and path for biased (obstacle avoiding) paths
var private native Map_Mirror UnbiasedTileCache { TMap<FTTile, FTileCacheEntry> }; // cached of tiles for unbiased (min cost) paths
var private native Map_Mirror TileToCacheMapping { TMap<FTTile, TileCacheMapping> }; 
var privatewrite array<Vector> CoverDestinations;

// These members allow us to detect when the unit has changed location/status and lazily update the cache
var private XComGameState_Unit CacheUnit;
var private int LastHistoryIndex;

// Sets the unit this cache is meant to work on
function SetCacheUnit(XComGameState_Unit Unit)
{
	CacheUnit = Unit;
	ForceCacheUpdate();
}

// THIS IS NOT A GENERAL PURPOSE FUNCTION. This is temporary until we get world data change callbacks.
// Please do not write any logic that relies on it.
function ForceCacheUpdate()
{
	LastHistoryIndex = -1;
}

// Helper function to get all of the ladder traversals in the cache.
native function GetLadderTraversals(out array<LadderTraversal> LadderTraversals);

// Returns the origin and max cost for the tile cache. By default this is the unit's origin and max path cost, but
// you could create subclasses to explore "what if" scenarios at other locations
native function GetCacheOriginAndMaxCost(out TTile Origin, out float MaxCost);

// Update the TileCache. To be called internally before doing any query (if no update required it returns immediately).
// Also, can be called manually if you want to schedule an extra update check for some reason.
native function UpdateTileCacheIfNeeded();

// Gets a path to Destination, if possible. If not, Path will be Length == 0
native function bool BuildPathToTile(TTile Destination, out array<TTile> Path);

// Gets the cost of the path traversal to the destination, or -1 if the destination is not reachable by this unit.
native function float GetPathCostToTile(TTile Destination);

// Returns true if the unit can reach the given tile
native function bool IsTileReachable(TTile Destination);

// If Destination is reachable, returns destnation. Otherwise returns the closest point reachable by this unit.
// This will iterate over the entire list of reachable destinations and should therefore be used very sparingly.
// If you need it to go faster, talk to me (David B.) and I will setup a backing accelerator structure to make it
// very fast.
native function TTile GetClosestReachableDestination(TTile Destination, optional array<TTile> ExclusionList, optional int MinTileZLimit = -1, optional int MaxTileZLimit = 999);

// Helper function to draw the cost to every accessible tile over the tiles. Cover tiles will be white,
// all other tile will be medium gray
native function DebugDrawTiles();

// Get all pathable tiles.
native function GetAllPathableTiles(out array<TTile> AllTiles_out, float MaxDist=-1, bool OnlyFloorTiles=true);
