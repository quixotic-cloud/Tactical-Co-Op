//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_WorldEffectTileData.uc
//  AUTHOR:  Ryan McFall  --  7/17/2014
//  PURPOSE: This state object keeps track of changes to the array of gameplay tile data
//           sparse matrices
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_WorldEffectTileData extends XComGameState_BaseObject native(Core);

//Data that is entered into the dynamic flags
struct native WorldEffectTileDataContainer
{
	var TTile                   Tile;
	var VolumeEffectTileData    Data;
	var int                     ParticleKey;
	var Rotator                 Rotation;
	var TTile                   TileOffset;
	var IntPoint				Scale;

	structcpptext
	{
	FWorldEffectTileDataContainer()
	{
		appMemzero(this, sizeof(FWorldEffectTileDataContainer));
	}
	FWorldEffectTileDataContainer(EEventParm)
	{
		appMemzero(this, sizeof(FWorldEffectTileDataContainer));
	}
	}
};

var name WorldEffectClassName;
var privatewrite int SparseArrayIndex; //Indicates which sparse array this data is associated with
var privatewrite array<WorldEffectTileDataContainer> StoredTileData; //Data corresponding to the volume effects in the tiles

/// <summary>
/// Helper method that will set the private data members of this state object
/// </summary>
native function SetInitialTileData(const out array<TilePosPair> Tiles, const out VolumeEffectTileData InitialTileData, optional const array<TileParticleInfo> TileParticles);
native function AddInitialTileData(const out TilePosPair Tile, const out VolumeEffectTileData InitialTileData, optional const out TileParticleInfo TileParticles);
native function PreSizeTileData(int SizeHint);

simulated function UpdateTileDataIntensity( int Index, int NewIntensity )
{
	StoredTileData[ Index ].Data.Intensity = NewIntensity;
}

DefaultProperties
{	
	SparseArrayIndex = -1;
}
