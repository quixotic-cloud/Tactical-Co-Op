class XComPath extends Object
	dependson(XComPathData)
	config(GameCore)
	native(Unit);

// To make transitions to and from flying look smoother, we compress the ease in and out
// near the launch and land. This values is the number of tiles from the launch/land tile that
// we want to compress
var private const config float LaunchAndLandEaseLengthTiles; // in tiles

// tunes for flight pathing. Controls the iteration count and strength of each flight path smoothing
var private const config int NumSmoothingIterations;
var private const config float SmoothStepBlendAlpha; // how much smoothing should we do each iteration?

// The path saved from the pathing system, with flags at each point.
// READ-ONLY. Modifying this outside this class will result in tears. -- jboswell
var protectedwrite array<PathPoint> Path;
var protectedwrite float Radius; // Radius of pawn expected to use this path
var protectedwrite float Height; // Half height of pawn expected to use this path (taken from CylinderComponent)

cpptext
{
	void AddPoint(const FPathPoint &Point);

	void DrawPath(const FColor &LineColor=FColor(0, 255, 0, 255));
	void SetExtents(FLOAT InRadius, FLOAT InHeight) { Radius = InRadius; Height = InHeight; }	
}

simulated native final function SetPathPointsDirect(const out array<PathPoint> InPathPoints);

simulated native final function Clear();
simulated native final function bool IsValid();

simulated native final function Vector GetStartPoint();
simulated native final function Vector GetEndPoint();

simulated native final function int PathSize();
simulated native final function int GetPathIndexFromPathDistance(float PathDistance);
simulated native final function Vector GetPoint(int Index);
simulated native final function ETraversalType GetTraversalType(int Index);
simulated native final function Actor GetActor(int Index);

// Given a traversal distance, return a point on the path
simulated native function Vector FindPointOnPath(float PathDistance);

// Traverses through path to determine the complete distance of the path
simulated native function float GetFullPathDistance();

// <APC> Added test to check for close combat intersection.
simulated native function bool DoesPathIntersectSphere(Vector vCenter, float fRadius, optional bool bDrawSegment=false);

simulated native function bool IsEndPointHighCover();
simulated native function bool IsEndPointLowCover();

// Removes unneeded points and smooths out the jaggies caused by pathing along discrete tile.
// points in pinned tiles will not be pulled.
simulated native static function PerformStringPulling(XGUnitNativeBase PathingUnit, out array<PathPoint> PathPoints, optional const out array<TTile> PinnedTiles);

simulated event string ToString()
{
	local string strRep;
	local int i;

	strRep = self $ "\n";
	for(i = 0; i < Path.Length; i++)
	{
		strRep $= "          point["$i$"]=" $ Path[i].Position @ Path[i].Traversal $ "\n";
	}

	return strRep;
}

simulated static native function GetPathTileArray(const out array<PathPoint> PathPoints, out array<TTile> arrTiles_Out);

simulated native static function bool TileContainsHazard(const XComGameState_Unit PathingUnit, const out TTile Tile);

defaultproperties
{
}
