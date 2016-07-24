//---------------------------------------------------------------------------------------
//  FILE:    X2GrapplePuck.uc
//  AUTHOR:  David Burchanowski  --  8/05/2015
//  PURPOSE: Provides the visuals for the grapple targeting method
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2GrapplePuck extends Actor
	native(Core)
	config(GameCore);

struct native GrappleTarget
{
	var TTile Tile; // Tile the unit will grapple to
	var Vector TileLocation; // cached centerpoint of the tile
	var Vector OverhangLocation; // rather than clip the edge of the ledge, the path line is first drawn to this point, then the tile center
	var bool WillBreakWindow; // true if this location requires a window break to reach
};

var private const config float PathHeightOffset;  // how far above the ground should we draw the grapple path?
var private const config float MaxGrappleDistance;  // how far away from the unit (in meters) can we grapple?

var private const config string PuckMeshName; // name of the grapple puck mesh
var private const config string PuckMeshConfirmedName; // name of the mesh that animates out when a move is confirmed
var private const config string PathMaterialName; // material for the ribbon that traces the movement path

var private array<GrappleTarget> GrappleLocations; // Array of all grapple locations currently available to this unit
var private XCom3DCursor Cursor;
var private XComGameState_Unit UnitState;
var private TTile LastCursorTile; // The last time the cursor was point to
var private int SelectedGrappleLocation; // Index into the GrappleLocations array that the user is currently targeting

// Path component to draw the grapple line from the unit to the ledge
var private XComRenderablePathComponent GrapplePath;

// mesh that draws if we will break hazards or concealment
var private X2WaypointStaticMeshComponent  WaypointMesh;

// Static mesh for the path ending puck
var private X2FadingStaticMeshComponent GrapplePuck;

// Instanced mesh component for the grapple target tile markup
var private InstancedStaticMeshComponent InstancedMeshComponent;

// returns true if there are valid grapple locations for a grappling unit on the origin tile. If OutGrappleLocations is
// provided, will also fill out those locations.
native static function bool HasGrappleLocations(XComGameState_Unit Unit, optional out array<GrappleTarget> OutGrappleLocations);

native function FillOutGridComponent();
native function UpdateGrapplePath();
native function UpdateGrappleWaypoint();
native function SelectGrappleLocation();
native function SelectClosestGrappleLocationToUnit();

simulated event PostBeginPlay()
{
	Cursor = `CURSOR;
}

function InitForUnitState(XComGameState_Unit InUnitState)
{
	local StaticMesh PuckMesh;
	local StaticMesh PuckMeshConfirmed;

	UnitState = InUnitState;

	InstancedMeshComponent.SetStaticMesh(StaticMesh(DynamicLoadObject("UI_3D.Tile.AOETile", class'StaticMesh')));
	InstancedMeshComponent.SetAbsolute(true, true);

	// load the resources for our components
	GrapplePath.SetMaterial(MaterialInterface(DynamicLoadObject(PathMaterialName, class'MaterialInterface')));

	PuckMesh = StaticMesh(DynamicLoadObject(PuckMeshName, class'StaticMesh'));
	PuckMeshConfirmed = StaticMesh(DynamicLoadObject(PuckMeshConfirmedName, class'StaticMesh'));
	GrapplePuck.SetStaticMeshes(PuckMesh, PuckMeshConfirmed);
	
	WaypointMesh.Init();

	// get all valid grapple location
	HasGrappleLocations(UnitState, GrappleLocations);

	// add tiles for all grapple locations to the grid component
	FillOutGridComponent();

	// and select the default grapple destination (if any)
	if(GrappleLocations.Length > 0)
	{
		SelectClosestGrappleLocationToUnit();
	}
}

simulated event Tick(float DeltaTime)
{
	local XComWorldData WorldData;
	local Vector CursorLocation;
	local TTile CursorTile;

	super.Tick(DeltaTime);

	WorldData = `XWORLD;

	CursorLocation = Cursor.GetCursorFeetLocation();
	CursorTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);
	if(CursorTile != LastCursorTile)
	{
		LastCursorTile = CursorTile;
		SelectGrappleLocation(); // update the grapple location if needed to reflect the new cursor location
	}
}

function bool GetGrappleTargetLocation(out Vector TargetLocation)
{
	if(GrappleLocations.Length > 0)
	{
		TargetLocation = GrappleLocations[SelectedGrappleLocation].TileLocation;
		return true;
	}

	return false;
}

function ShowConfirmAndDestroy()
{
	GotoState('ConfirmAndDestroy');
}

state ConfirmAndDestroy
{
	// don't do any updates while we are just waiting to cleanup
	simulated event Tick(float DeltaTime);

	// can't do this again once already in the state
	function ShowConfirmAndDestroy();

Begin:
	GrapplePath.SetHidden(true);
	InstancedMeshComponent.SetHidden(true);

	GrapplePuck.FadeOut();
	WaypointMesh.FadeOut();
	while(GrapplePuck.IsFading() || WaypointMesh.IsFading())
	{
		Sleep(0);
	}

	// once the puck has fully faded out, we can destroy ourselves
	Destroy();
}

defaultproperties
{
	Begin Object Class=XComRenderablePathComponent Name=PathComponent
		iPathLengthOffset=-2
		fRibbonWidth=2
		fEmitterTimeStep=10
		TranslucencySortPriority=100
		bTranslucentIgnoreFOW=true
		PathType=eCU_WithConcealment
	End Object
	GrapplePath=PathComponent
	Components.Add(PathComponent)

	Begin Object Class=X2FadingStaticMeshComponent Name=PuckMeshComponentObject
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false

		AbsoluteTranslation=true
		AbsoluteRotation=true
		bTranslucentIgnoreFOW=true
		TranslucencySortPriority=1000
	End Object
	GrapplePuck=PuckMeshComponentObject
	Components.Add(PuckMeshComponentObject)

	Begin Object Class=X2WaypointStaticMeshComponent Name=WaypointMeshComponentObject
	End Object
	WaypointMesh=WaypointMeshComponentObject
	Components.Add(WaypointMeshComponentObject)

	Begin Object Class=InstancedStaticMeshComponent Name=InstancedMeshComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
	End object
	InstancedMeshComponent=InstancedMeshComponent0
	Components.Add(InstancedMeshComponent0)
}