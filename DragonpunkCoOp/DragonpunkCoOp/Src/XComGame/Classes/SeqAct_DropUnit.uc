///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_DropUnit.uc
//  AUTHOR:  David Burchanowski  --  11/05/2014
//  PURPOSE: Drops a unit at the specified location
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_DropUnit extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var private XComGameState_Unit SpawnedUnit; // the unit that was dropped
var private string CharacterPoolEntry; // The character pool entry that we want to drop
var private string CharacterTemplate; // The template of the unit we want to drop (only needed if no pool entry specified)

var private Vector DropLocation; // the location to drop the unit at
var() private Actor DropLocationActor; // allows placing a marker in the map to drop a unit at

event Activated()
{	
	local XComGameStateHistory History;
	local XComAISpawnManager SpawnManager;
	local StateObjectReference SpawnedUnitRef;
	local ETeam Team;

	// determine our drop location
	if(DropLocationActor != none)
	{
		DropLocation = DropLocationActor.Location;
	}

	// determine the drop team
	if(InputLinks[0].bHasImpulse)
	{
		Team = eTeam_XCom;
	}
	else if(InputLinks[1].bHasImpulse)
	{
		Team = eTeam_Alien;
	}
	else if(InputLinks[2].bHasImpulse)
	{
		Team = eTeam_Neutral;
	}

	// spawn the unit
	History = `XCOMHISTORY;
	SpawnManager = `SPAWNMGR;
	SpawnedUnitRef = SpawnManager.CreateUnit( DropLocation, name(CharacterTemplate), Team, false,,,, CharacterPoolEntry );
	SpawnedUnit = XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnitRef.ObjectID));

	if(SpawnedUnit == none)
	{
		`Redscreen("SeqAct_DropUnit failed to drop a unit. CharacterTemplate: " $ CharacterTemplate $ ", CharacterPoolEntry: " $ CharacterPoolEntry);
	}
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;

	BuildTrack.StateObject_OldState = SpawnedUnit;
	BuildTrack.StateObject_NewState = SpawnedUnit;
	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext());

	VisualizationTracks.AddItem(BuildTrack);
}

function ModifyKismetGameState(out XComGameState GameState);

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Drop Unit"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	bAutoActivateOutputLinks=true

	InputLinks(0)=(LinkDesc="XCom")
	InputLinks(1)=(LinkDesc="Alien")
	InputLinks(2)=(LinkDesc="Civilian")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Spawned Unit",PropertyName=SpawnedUnit,bWriteable=true)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="Pool Entry",PropertyName=CharacterPoolEntry)
	VariableLinks(2)=(ExpectedType=class'SeqVar_String',LinkDesc="Template",PropertyName=CharacterTemplate)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Location",PropertyName=DropLocation)
}
