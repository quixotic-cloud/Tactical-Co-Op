//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_MoveUnitToTile.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Moves a unit to a given tile (if possible) via kismet. For LD scripting demo/tutorial save creation.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_MoveUnitToTile extends SequenceAction;

var XComGameState_Unit Unit;
var Actor DestinationActor;
var vector DestinationLocation;

event Activated()
{
	local XComTacticalController TacticalController;
	local XComWorldData WorldData;
	local XGUnit Visualizer;
	local array<TTile> Path;
	local TTile DestinationTile;

	TacticalController = XComTacticalController(`BATTLE.GetALocalPlayerController());
	WorldData = `XWORLD;

	if(Unit == none)
	{
		`RedScreen("SeqAct_MoveUnitToTile: No unit provided");
		return;
	}

	if(DestinationActor != none)
	{
		DestinationLocation = DestinationActor.Location;
	}

	if(!WorldData.GetFloorTileForPosition(DestinationLocation, DestinationTile))
	{
		`RedScreen("SeqAct_MoveUnitToTile: Destination location is invalid" $ string(DestinationLocation));
		return;
	}

	Visualizer = XGUnit(Unit.GetVisualizer());
	if(Visualizer.m_kReachableTilesCache.BuildPathToTile(DestinationTile, Path))
	{
		TacticalController.GameStateMoveUnitSingle(Visualizer, Path);
	}
	else
	{
		`Redscreen("SeqAct_MoveUnitToTile: no path exists to specified location!");
	}
}

defaultproperties
{
	ObjCategory="Automation"
	ObjName="Move Unit To Tile"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Destination Actor",PropertyName=DestinationActor)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Destination Location",PropertyName=DestinationLocation)
}