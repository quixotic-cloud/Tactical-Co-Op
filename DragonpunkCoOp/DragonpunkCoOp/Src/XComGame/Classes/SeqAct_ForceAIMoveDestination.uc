//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ForceAIMoveDestination.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Forces a unit to select the given location as their next move destination
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_ForceAIMoveDestination extends SequenceAction;

var XComGameState_Unit Unit;
var string ReferenceActorTag;

event Activated()
{
	local XComTacticalCheatManager Cheats;
	local XComWorldData WorldData;
	local Actor ReferenceActor;
	local TTile ReferenceTile;

	if(Unit == none)
	{
		`Redscreen("SeqAct_ForceAIMoveDestination: Unit unspecified or invalid!");
		return;
	}
	
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'Actor', ReferenceActor)
	{
		if(string(ReferenceActor.Tag) == ReferenceActorTag)
		{
			WorldData = `XWORLD;

			if(WorldData.GetFloorTileForPosition(ReferenceActor.Location, ReferenceTile))
			{
				Cheats = `CHEATMGR;
				Cheats.AddForcedAIMoveDestination(Unit.GetReference(), ReferenceTile);
			}

			return;
		}
	}

	`Redscreen("SeqAct_ForceAIMoveDestination: Could not find actor with tag: " $ ReferenceActorTag);
}

defaultproperties
{
	ObjCategory="Automation"
	ObjName="Force Scamper Location"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="Reference Actor Tag",PropertyName=ReferenceActorTag)
}