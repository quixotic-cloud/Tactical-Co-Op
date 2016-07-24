//---------------------------------------------------------------------------------------
//  FILE:    X2MaterialGroupSwapActor.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: It's living in a material world.
//           Associates groups of actors who should all use the same material when doing procedural plot swap
//           adjustments.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2MaterialSwapGroupActor extends PointInSpace
	native(Core)
	placeable;

cpptext
{
	// applies the given material to the given index on all actors in this group
	void SetMaterialOnAll(INT MaterialIndex, UMaterialInterface* NewMaterial);
}

// every actor in this array will swap to the same materials
var() private array<Actor> SwapActors;

defaultproperties
{
	Begin Object NAME=Sprite
		Sprite=Texture2D'LayerIcons.Editor.group_swap'
		Scale=0.25
	End Object
}