//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_WarpsUnitToTile.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Warps a unit to a given tile (if possible) via kismet. For LD scripting demo/tutorial save creation.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_WarpUnitToTile extends SequenceAction;

var XComGameState_Unit Unit;
var Actor DestinationActor;
var vector DestinationLocation;

event Activated()
{
	local XComWorldData WorldData;
	local TTile DestinationTile;
	local XComGameState NewGameState;

	WorldData = `XWORLD;

	if(Unit == none)
	{
		`RedScreen("SeqAct_WarpUnitToTile: No unit provided");
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

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SeqAct_WarpUnitToTile: Warping Unit");
	Unit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Unit.SetVisibilityLocation(DestinationTile);
	NewGameState.AddStateObject(Unit);

	`TACTICALRULES.SubmitGameState(NewGameState);
}

defaultproperties
{
	ObjCategory="Automation"
	ObjName="Warp Unit To Tile"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Destination Actor",PropertyName=DestinationActor)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Destination Location",PropertyName=DestinationLocation)
}