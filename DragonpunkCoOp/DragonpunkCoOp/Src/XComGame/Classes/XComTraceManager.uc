class XComTraceManager extends Actor
	native(Core);

enum EXComTraceType
{
	eXTrace_Screen, // Prioritizes units over the world.
	eXTrace_UnitVisibility,
	eXTrace_UnitVisibility_IgnoreTeam,  // Visibility traces that ignore team pawns
	eXTrace_UnitVisibility_IgnoreAllButTarget, // Visibility trace that ignores all *pawns* except the target
	eXTrace_CameraObstruction,
	eXTrace_World,
	eXTrace_AllActors, // Traces actors and uses IsPositionVisible to ignore cutouts
	eXTrace_NoPawns,
};

var EXComTraceType          m_eCurrentType;
var ETeam                   m_eIgnoreTeam;
var Actor                   m_Target;

native function Actor XTrace
(
	EXComTraceType              eType,
	out vector					HitLocation,
	out vector					HitNormal,
	vector						TraceEnd,
	optional vector				TraceStart,
	optional vector				Extent,
	optional out TraceHitInfo	HitInfo,
	optional bool               bDrawDebugLine,
	optional ETeam              eIgnoreTeam,
	optional Actor              Target
);

native function XTraceAndHideXComHideableFlaggedLevelActors
(
	out array<Actor> aActorsCurrentlyHidden,
	Vector vTraceStart,
	Vector vTraceEnd,
	Vector vCursorExtents,
	int iMethod,
	bool bDrawDebugLines,
	bool bHideThisFrame
);

//native function XTraceAndHideBuildingFloors
//(
//	out array<XComFloorVolume> aFloorVolumesPrevHidden,
//	out int iNumFloorVolumesAffected,
//	XGLevel kLevel,
//	XComCutoutBox kCutoutBox,
//	Vector vTraceStart,
//	Vector vTraceEnd,
//	bool bUnhideOnly
//);

native function XTraceAndFindFloorVolumes
(
	out array<XComFloorVolume> aFloorVolumesOut,
	Vector vTraceStart,
	Vector vTraceEnd
);

// Traces done for the purpose of determining whether the camera view of a unit would be obstructed from specified location/trace.
native function Actor XTraceCameraToUnitObstruction(out Vector HitLocation, Vector vTraceStart, Vector vTraceEnd);

simulated native function bool IsVisibilityTrace();

defaultproperties
{

}