//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_CinematicSpawn.uc
//  AUTHOR:  David Burchanowski  --  1/27/2016
//  PURPOSE: Context to add a unit to the gameboard in a pretty, cinematic method
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_CinematicSpawn extends XComGameStateContext;

// since this needs to serialize to the history, we can't use an actor directly.
// Store the identifying information instead
var private ActorIdentifier SpawnPointIdentifier;

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	// this class isn't meant to be used with SubmitGameStateContext. Use the factory function AddCinematicSpawnGameState() instead
	`assert(false);
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	local VisualizationTrack BuildTrack;
	local X2Action_CameraLookAt CameraAction;
	local X2Action_PlayMatinee MatineeAction;
	local XComGameState_Unit SpawnedUnit;
	local X2CinematicSpawnPoint SpawnPoint;
	local Actor SpawnPointActor;

	if(!class'Actor'.static.FindActorByIdentifier(SpawnPointIdentifier, SpawnPointActor))
	{
		`Redscreen("XComGameStateContext_CinematicSpawn::ContextBuildVisualization(): Unable to find actor for identifier " $ SpawnPointIdentifier.ActorName);
	}

	SpawnPoint = X2CinematicSpawnPoint(SpawnPointActor);
	if(SpawnPoint == none)
	{
		`Redscreen("XComGameStateContext_CinematicSpawn::ContextBuildVisualization(): Found actor, but it is not an X2CinematicSpawnPoint: " $ PathName(SpawnPointActor));
	}

	// grab the spawned unit from the game state
	foreach AssociatedState.IterateByClassType(class'XComGameState_Unit', SpawnedUnit)
	{
		BuildTrack.StateObject_OldState = SpawnedUnit;
		BuildTrack.StateObject_NewState = SpawnedUnit;
		break;
	}

	// camera pan over to see the unit spawn
	CameraAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTrack(BuildTrack, self));
	CameraAction.LookAtLocation = `XWORLD.GetPositionFromTileCoordinates(SpawnedUnit.TileLocation);
	CameraAction.BlockUntilActorOnScreen = true;
	CameraAction.UseTether = false;
	CameraAction.SnapToFloor = true;

	// play the spawn matinee
	if(SpawnPoint != none && SpawnPoint.MatineePrefix != "")
	{
		MatineeAction = X2Action_PlayMatinee(class'X2Action_PlayMatinee'.static.AddToVisualizationTrack(BuildTrack, self));
		MatineeAction.SelectMatineeByTag(SpawnPoint.MatineePrefix);
		MatineeAction.AddUnitToMatinee(SpawnPoint.MatineeUnitGroup, SpawnedUnit);
		MatineeAction.SetMatineeBase(SpawnPoint.MatineeBaseTag);
		MatineeAction.SetMatineeLocation(SpawnPoint.Location, SpawnPoint.Rotation);
	}

	// show the spawned unit
	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTrack(BuildTrack, self);

	VisualizationTracks.AddItem(BuildTrack);
}

/// <summary>
///
/// Spawns a new unit for the specified spawn point and adds it to the history.
/// Returns a reference to the spawned unit
///
/// </summary>
public static function XComGameState_Unit AddCinematicSpawnGameState(X2CinematicSpawnPoint InSpawnPoint)
{
	local XComGameStateHistory History;
	local XComGameStateContext_CinematicSpawn CinematicSpawnContext;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

	CinematicSpawnContext = XComGameStateContext_CinematicSpawn(CreateXComGameStateContext());
	CinematicSpawnContext.SpawnPointIdentifier = InSpawnPoint.GetActorId();

	CinematicSpawnContext = XComGameStateContext_CinematicSpawn(History.CreateNewGameState(true, CinematicSpawnContext).GetContext());
	UnitState = InSpawnPoint.SpawnUnit(CinematicSpawnContext.AssociatedState);

	`TACTICALRULES.SubmitGameState(CinematicSpawnContext.AssociatedState);

	return UnitState;
}

function string SummaryString()
{
	local Actor SpawnPoint;

	if(class'Actor'.static.FindActorByIdentifier(SpawnPointIdentifier, SpawnPoint))
	{
		return "XComGameStateContext_CinematicSpawn: " $ PathName(X2CinematicSpawnPoint(SpawnPoint));
	}
	else
	{
		return "Error, could not find actor for identifier " $ SpawnPointIdentifier.ActorName;
	}
}