//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_EnableTileEffectVolume.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Fades the camera out in a game state safe way
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_EnableTileEffectVolume extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

var() name VolumeTag;

event Activated()
{
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local XComTileEffectVolume EffectVolume;

	// find all volumes with the given tag, and visualize their effects
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComTileEffectVolume', EffectVolume)
	{
		if(EffectVolume.Tag == VolumeTag)
		{
			EffectVolume.AddVisualizationTracks(GameState, VisualizationTracks);
		}
	}
}

function ModifyKismetGameState(out XComGameState GameState)
{
	local XComTileEffectVolume EffectVolume;
	local array<TilePosPair> AffectedTiles;
	local array<int> AffectedIntensities;
	local X2Effect_World WorldEffect;

	// find all volumes with the given tag, and add (or remove) the effect from their tiles 
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComTileEffectVolume', EffectVolume)
	{
		if(EffectVolume.Tag == VolumeTag)
		{
			if(InputLinks[0].bHasImpulse)
			{
				EffectVolume.GetAffectedTiles(AffectedTiles, AffectedIntensities);
				WorldEffect = X2Effect_World(class'XComEngine'.static.GetClassDefaultObject(EffectVolume.TileEffect));
				WorldEffect.AddLDEffectToTiles(WorldEffect.GetWorldEffectClassName(), GameState, AffectedTiles, AffectedIntensities);
				EffectVolume.ApplyToUnits(AffectedTiles, AffectedIntensities, GameState);
			}
			else
			{
				EffectVolume.ClearAffectedTiles(GameState);
			}
		}
	}
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Activate Tile Effect Volume"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Name',LinkDesc="Volume Tag",PropertyName=VolumeTag)
}