//---------------------------------------------------------------------------------------
//  FILE:    X2CinematicSpawnPoint.uc
//  AUTHOR:  David Burchanowski  --  1/26/2016
//  PURPOSE: Allows LDs to mark up a spawn point in the world that will 
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2CinematicSpawnPoint extends Actor
	placeable;

var() const string CharacterTemplate; // Character template to spawn
var() const string MatineePrefix; // Comment prefix of the matinee to play
var() const name MatineeBaseTag; // Tag comment of the base actor to orient the matinee at the spawn location
var() const name MatineeUnitGroup; // Name of the group in the matinee that the spawned actor should be added to
var() const string FilterTag; // Extra tag for filtering. Should match a filer in SeqAct_SpawnCinematicUnit

function bool CanSpawnUnit()
{
	local XComWorldData WorldData;
	local TTile Tile;

	// in order to spawn a unit here, we need the tile to be clear
	WorldData = `XWORLD;

	if(!WorldData.GetFloorTileForPosition(Location, Tile))
	{
		`Redscreen("No floor for X2CinematicSpawnActor " $ PathName(self));
		return false;
	}

	if(WorldData.IsTileFullyOccupied(Tile))
	{
		return false;
	}

	if(WorldData.IsTileBlockedByUnitFlag(Tile))
	{
		return false;
	}

	return true;
}

function XComGameState_Unit SpawnUnit(optional XComGameState GameState)
{
	local XComGameStateHistory History;
	local XComAISpawnManager SpawnManager;
	local StateObjectReference SpawnedUnitRef;
	local XComGameState_Unit SpawnedUnit;

	History = `XCOMHISTORY;
	SpawnManager = `SPAWNMGR;

	SpawnedUnitRef = SpawnManager.CreateUnit(Location, name(CharacterTemplate), eTeam_Alien, false,, GameState);
	SpawnedUnit = XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnitRef.ObjectID));

	if(SpawnedUnit == none)
	{
		`Redscreen("X2CinematicSpawnPoint failed to Spawn a unit. CharacterTemplate: " $ CharacterTemplate);
	}

	return SpawnedUnit;
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true     // precomputed lighting is used until the static mesh is changed
		bCastShadows=false // there will be a static shadow so no need to cast a dynamic shadow
		bSynthesizeSHLight=false
		bSynthesizeDirectionalLight=true; // get rid of this later if we can
		bDynamic=true     // using a static light environment to save update time
		bForceNonCompositeDynamicLights=TRUE // needed since we are using a static light environment
		bUseBooleanEnvironmentShadowing=FALSE
		TickGroup=TG_DuringAsyncWork
	End Object

	Begin Object Class=StaticMeshComponent Name=ExitStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'Parcel.Meshes.Parcel_Extraction_3x3'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
		Scale3D=(X=0.33,Y=0.33,Z=0.33)
	End Object
	Components.Add(ExitStaticMeshComponent)

	Begin Object Class=StaticMeshComponent Name=FacingArrow
		HiddenGame=true
		HiddenEditor=false
		StaticMesh=StaticMesh'UI_Waypoint.Meshes.WaypointArrowB'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
		Scale3D=(X=2,Y=2,Z=2)
		Rotation=(Pitch=0,Yaw=16384,Roll=0)
	End Object
	Components.Add(FacingArrow)

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'LayerIcons.Editor.group_spawn'
		HiddenGame=True
		Translation=(X=0,Y=0,Z=64)
		Scale=0.5
	End Object
	Components.Add(Sprite);

	bEdShouldSnap=true
}