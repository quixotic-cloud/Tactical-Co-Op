//---------------------------------------------------------------------------------------
//  FILE:    X2MeleePathingPath.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Specialized pathing pawn for activated melee pathing. Draws tiles around every unit the 
//           currently selected ability can melee from, and allows the user to select one to move there.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2MeleePathingPawn extends XComPathingPawn
	native(Unit);

var private XComGameState_Unit UnitState; // The unit we are currently using
var private XComGameState_Ability AbilityState; // The ability we are currently using
var private Actor TargetVisualizer; // Visualizer of the current target 

var private array<TTile> PossibleTiles; // list of possible tiles to melee from

// Instanced mesh component for the grapple target tile markup
var private InstancedStaticMeshComponent InstancedMeshComponent;

// adds tiles to the instance mesh component for every tile in the PossibileTiles array
private native function UpdatePossibleTilesVisuals();

function Init(XComGameState_Unit InUnitState, XComGameState_Ability InAbilityState)
{
	super.SetActive(XGUnitNativeBase(InUnitState.GetVisualizer()));

	UnitState = InUnitState;
	AbilityState = InAbilityState;

	InstancedMeshComponent.SetStaticMesh(StaticMesh(DynamicLoadObject("UI_3D.Tile.AOETile", class'StaticMesh')));
	InstancedMeshComponent.SetAbsolute(true, true);
}

simulated function SetActive(XGUnitNativeBase kActiveXGUnit, optional bool bCanDash, optional bool bObeyMaxCost)
{
	`assert(false); // call Init() instead
}

// disable the built in pathing melee targeting.
simulated protected function bool CanUnitMeleeFromMove(XComGameState_BaseObject TargetObject, out XComGameState_Ability MeleeAbility)
{
	return false;
}

function GetTargetMeleePath(out array<TTile> OutPathTiles)
{
	OutPathTiles = PathTiles;
}

// overridden to always just show the slash UI, regardless of cursor location or other considerations
simulated protected function UpdatePuckVisuals(XComGameState_Unit ActiveUnitState, 
												const out TTile PathDestination, 
												Actor TargetActor,
												X2AbilityTemplate MeleeAbilityTemplate)
{
	local XComWorldData WorldData;
	local XGUnit Unit;
	local vector MeshTranslation;
	local Rotator MeshRotation;	
	local vector MeshScale;
	local vector FromTargetTile;
	local float UnitSize;

	WorldData = `XWORLD;

	// determine target puck size and location
	MeshTranslation = TargetActor.Location;

	Unit = XGUnit(TargetActor);
	if(Unit != none)
	{
		UnitSize = Unit.GetVisualizedGameState().UnitSize;
		MeshTranslation = Unit.GetPawn().CollisionComponent.Bounds.Origin;
	}
	else
	{
		UnitSize = 1.0f;
	}

	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;

	// when slashing, we will technically be out of range. 
	// hide the out of range mesh, show melee mesh
	OutOfRangeMeshComponent.SetHidden(true);
	SlashingMeshComponent.SetHidden(false);
	SlashingMeshComponent.SetTranslation(MeshTranslation);

	// rotate the mesh to face the thing we are slashing
	FromTargetTile = WorldData.GetPositionFromTileCoordinates(PathDestination) - MeshTranslation; 
	MeshRotation.Yaw = atan2(FromTargetTile.Y, FromTargetTile.X) * RadToUnrRot;
		
	SlashingMeshComponent.SetRotation(MeshRotation);
	SlashingMeshComponent.SetScale(UnitSize);

	// the normal puck is always visible, and located wherever the unit
	// will actually move to when he executes the move
	PuckMeshComponent.SetHidden(false);
	PuckMeshComponent.SetStaticMeshes(GetMeleePuckMeshForAbility(MeleeAbilityTemplate), PuckMeshConfirmed);
	if (IsDashing() || ActiveUnitState.NumActionPointsForMoving() == 1)
	{
		RenderablePath.SetMaterial(PathMaterialDashing);
	}
		
	MeshTranslation = VisualPath.GetEndPoint(); // make sure we line up perfectly with the end of the path ribbon
	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;
	PuckMeshComponent.SetTranslation(MeshTranslation);

	MeshScale.X = ActiveUnitState.UnitSize;
	MeshScale.Y = ActiveUnitState.UnitSize;
	MeshScale.Z = 1.0f;
	PuckMeshComponent.SetScale3D(MeshScale);
}

simulated function UpdateMeleeTarget(XComGameState_BaseObject Target)
{
	local X2AbilityTemplate AbilityTemplate;

	if(Target == none)
	{
		`Redscreen("X2MeleePathingPawn::UpdateMeleeTarget: Target is none!");
		return;
	}

	TargetVisualizer = Target.GetVisualizer();
	AbilityTemplate = AbilityState.GetMyTemplate();

	PossibleTiles.Length = 0;
	if(class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile(UnitState, Target, AbilityTemplate, PossibleTiles))
	{
		// build a path to the default (best) tile
		RebuildPathingInformation(PossibleTiles[0], TargetVisualizer, AbilityTemplate);
		
		// and update the tiles to reflect the new target options
		UpdatePossibleTilesVisuals();
	}
}

// override the tick. Rather than do the normal path update stuff, we just want to see if the user has pointed the mouse
// at any of our other possible tiles
simulated event Tick(float DeltaTime)
{
	local XCom3DCursor Cursor;
	local XComWorldData WorldData;
	local vector CursorLocation;
	local TTile PossibleTile;
	local TTile CursorTile;
	local X2AbilityTemplate AbilityTemplate;

	Cursor = `CURSOR;
	WorldData = `XWORLD;

	CursorLocation = Cursor.GetCursorFeetLocation();
	CursorTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);

	if(TargetVisualizer != none && CursorTile != LastDestinationTile) 
	{
		foreach PossibleTiles(PossibleTile)
		{
			if(PossibleTile == CursorTile)
			{
				AbilityTemplate = AbilityState.GetMyTemplate();
				RebuildPathingInformation(CursorTile, TargetVisualizer, AbilityTemplate);
			}
		}
	}
}

// don't update objective tiles
function UpdateObjectiveTiles(XComGameState_Unit InActiveUnitState);

defaultproperties
{
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