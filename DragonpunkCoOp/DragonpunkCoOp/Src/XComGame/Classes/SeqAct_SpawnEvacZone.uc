//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    SeqAct_SpawnEvacZone.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Spawns an evac zone at the specified location
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class SeqAct_SpawnEvacZone extends SequenceAction
	implements(X2KismetSeqOpVisualizer)
	config(GameCore);

// If BiasAwayFromXComSpawn is true, then how narrow is the cone opposite the xcom spawn in which we can place the evac zone?
var const config float BiasConeAngleInDegrees;

var Vector SpawnLocation; // desired spawn location, in parameter
var Vector ActualSpawnLocation; // actually used spawn location, out parameter

// if specified, will use SpawnLocation as a centerpoint around which a spawn within these bounds
// will be spawned
var() int MinimumTilesFromLocation; // in tiles
var() int MaximumTilesFromLocation; // in tiles
var() bool BiasAwayFromXComSpawn; // if true, will attempt to pick an evac location further away from the xcom spawn

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local XComGameState_EvacZone EvacZone;
	local VisualizationTrack Track;

	foreach GameState.IterateByClassType(class'XComGameState_EvacZone', EvacZone)
	{
		Track.StateObject_OldState = EvacZone;
		Track.StateObject_NewState = EvacZone;
		class'X2Action_SyncVisualizer'.static.AddToVisualizationTrack(Track, GameState.GetContext());
		VisualizationTracks.AddItem(Track);
	}
}

event Activated()
{
	// this needs to be computed in the activation so that we copy the actual spawn location
	// out to the variable node in kismet
	ActualSpawnLocation = GetSpawnLocation();
}

function ModifyKismetGameState(out XComGameState GameState)
{
	local ETeam Team;

	if(InputLinks[0].bHasImpulse)
	{
		Team = eTeam_XCom;
	}
	else
	{
		Team = eTeam_Alien;
	}

	class'XComGameState_EvacZone'.static.PlaceEvacZone(GameState, ActualSpawnLocation, Team);
}

private function Vector GetSpawnLocation()
{
	local XComWorldData WorldData;
	local XComGroupSpawn Spawn;
	local XComParcelManager ParcelManager;
	local XComTacticalMissionManager MissionManager;
	local Vector ObjectiveLocation;
	local float TilesFromSpawn;
	local array<XComGroupSpawn> SpawnsInRange;
	local vector SoldierSpawnToObjectiveNormal;
	local float BiasHalfAngleDot;
	local float SpawnDot;

	if(MinimumTilesFromLocation < 0 && MaximumTilesFromLocation < 0)
	{
		// simple case, this isn't a ranged check and we just want to use the exact location
		return SpawnLocation;
	}

	if(MinimumTilesFromLocation >= MaximumTilesFromLocation)
	{
		`Redscreen("SeqAct_SpawnEvacZone: The minimum zone distance is further than the maximum, this makes no sense!");
		return SpawnLocation;
	}

	// find all group spawns that lie within the the specified limits
	WorldData = `XWORLD;
	foreach `BATTLE.AllActors(class'XComGroupSpawn', Spawn)
	{
		TilesFromSpawn = VSize(Spawn.Location - SpawnLocation) / class'XComWorldData'.const.WORLD_StepSize;
		if(TilesFromSpawn > MinimumTilesFromLocation 
			&& TilesFromSpawn < MaximumTilesFromLocation 
			&& WorldData.Volume.EncompassesPoint(Spawn.Location)) // only if it lies within the extents of the level
		{
			SpawnsInRange.AddItem(Spawn);
		}
	}

	if(SpawnsInRange.Length == 0)
	{
		// couldn't find any spawns in range!
		`Redscreen("SeqAct_SpawnEvacZone: Couldn't find any spawns in range, spawning at the centerpoint!");
		return SpawnLocation;
	}

	// now pick a spawn.
	if(BiasAwayFromXComSpawn)
	{
		ParcelManager = `PARCELMGR;
		MissionManager = `TACTICALMISSIONMGR;
		if(MissionManager.GetObjectivesCenterpoint(ObjectiveLocation))
		{
			// randomize the array so we can just take the first one that is on the opposite side of the objectives
			// from the xcom spawn
			SpawnsInRange.RandomizeOrder();

			SoldierSpawnToObjectiveNormal = Normal(ParcelManager.SoldierSpawn.Location - ObjectiveLocation);
			BiasHalfAngleDot = cos((180.0f - (BiasConeAngleInDegrees * 0.5)) * DegToRad); // negated since it's on the opposite side of the spawn
			foreach SpawnsInRange(Spawn)
			{
				SpawnDot = SoldierSpawnToObjectiveNormal dot Normal(Spawn.Location - ObjectiveLocation);
				if(SpawnDot < BiasHalfAngleDot)
				{
					return Spawn.Location;
				}
			}
		}
	}

	// random pick
	return SpawnsInRange[`SYNC_RAND(SpawnsInRange.Length)].Location;
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Spawn Evac Zone"
	bCallHandler=false
	
	MinimumTilesFromLocation=-1
	MaximumTilesFromLocation=-1

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="XCom")
	InputLinks(1)=(LinkDesc="Alien")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Input Location",PropertyName=SpawnLocation)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Actual Location",PropertyName=ActualSpawnLocation,bWriteable=true)
}