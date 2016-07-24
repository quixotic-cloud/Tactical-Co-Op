//---------------------------------------------------------------------------------------
//  FILE:    X2WaypointTilesCache.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Utility class for gathering all reachable tiles for a waypoint. Used by the pathing pawn.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2WaypointTilesCache extends X2ReachableTilesCache
	dependson(XGTacticalGameCoreNativeBase)
	native(Core);

var TTile WaypointTile; // tile of the waypoint we are pathing from
var float CostToWaypoint; // Total cost to path to this waypoint

// Returns the origin and max cost for the tile cache. By default this is the unit's origin and max path cost, but
// you could create subclasses to explore "what if" scenarios at other locations
native function GetCacheOriginAndMaxCost(out TTile Origin, out float MaxCost);

native function float GetPathCostToTile(TTile Destination);