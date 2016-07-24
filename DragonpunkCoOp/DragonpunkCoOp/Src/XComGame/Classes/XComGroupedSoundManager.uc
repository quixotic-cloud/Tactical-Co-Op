//---------------------------------------------------------------------------------------
//  FILE:    XComGroupedSoundManager
//  AUTHOR:  Mark F. Domowicz -- 8/14/2015
//  PURPOSE: This class is for handling sound effects that represent groups of objects.
//           An example (and the actual first use of this class) is Fire/flame sounds.
//           We don't want a flame sound effect for every active particle emitter.  
//           Instead, ideally, we find areas where particle emitters are clumped or 
//           grouped, and play a single positional sound effect for that whole group.
//
//            Implementation Summary:
//
//            When a TILE has fire/acid/etc, the game calls AddTile(TILE) which does:
//                    if (TILE is near enough to an existing SPHERE)
//                        Add the TILE to that SPHERE.
//                        Reposition and Resize sphere to best fit all TILES it contains.
//                    else
//                        Create NEW_SPHERE, and add TILE to it.
//                        Center NEW_SPHERE at TILE's pos, and give it an initial size.
//                        NEW_SPHERE starts playing sound effect.
//
//            When a TILE becomes unaffected, the game calls RemoveTile(TILE) which does:
//                    Find the SPHERE that has the TILE in it.
//                    Remove the TILE from that SPHERE.
//                    If (the SPHERE now has 0 tiles)
//                        Stop playing the sound effect.
//                        Destroy the SPHERE.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------


class XComGroupedSoundManager extends Actor native(Core);


enum EGroupedSoundType
{
	eGroupedSoundType_Acid,
	eGroupedSoundType_Fire,
	eGroupedSoundType_Poison,
};


var array<XComGroupedSoundSphere> SoundSphereList;
var float fDefaultTileRadius;
var float fDefaultSphereRadius;
var EGroupedSoundType GroupSoundType;



event AddTile( TTile Tile )
{
	local XComGroupedSoundSphere SelectedSphere;

	SelectedSphere = FindOrCreateSoundSphereForTile( Tile );
	SelectedSphere.AddTile( Tile );
	SelectedSphere.UpdateValues( fDefaultSphereRadius, fDefaultTileRadius );
}



event RemoveTile( TTile Tile )
{
	local XComGroupedSoundSphere Sphere;
	local int i;

	for ( i = 0; i < SoundSphereList.Length; ++i )
	{
		//-----------------------
		// Remove the Tile from the sphere
		Sphere = SoundSphereList[ i ];
		Sphere.RemoveTile( Tile );
		Sphere.UpdateValues( fDefaultSphereRadius, fDefaultTileRadius );

		//-----------------------
		// If the sphere has no more tiles, remove it
		if ( Sphere.TileList.Length == 0 )
		{
			Sphere.Destroy();
			SoundSphereList.Remove( i, 1 );
			--i;
		}
	}
}



function XComGroupedSoundSphere FindOrCreateSoundSphereForTile( TTile Tile )
{
	local XComGroupedSoundSphere SphereIter;
	local XComGroupedSoundSphere SelectedSphere;
	local bool bSphereIsMaxSize;
	local bool bTileEnlargesSphere;
	local bool bTileMakesSphereTooLarge;

	InitDefaultRadii();

	//-----------------------
	// Try to find a sphere that the Tile can be assigned to.
	foreach SoundSphereList( SphereIter )
	{
		if ( IsTileInSphere( SphereIter, Tile ) )
		{
			bSphereIsMaxSize = ( SphereIter.fRadius > ( 16.0f * class'XComWorldData'.const.WORLD_StepSize ) );
			bTileEnlargesSphere = SphereIter.DoesAddingTileIncreaseRadius( Tile, fDefaultTileRadius );
			bTileMakesSphereTooLarge = ( bSphereIsMaxSize && bTileEnlargesSphere );

			if ( !bTileMakesSphereTooLarge )
				SelectedSphere = SphereIter;
		}
	}

	//-----------------------
	// If no workable sphere is found, create a new one.
	if ( SelectedSphere == none )
	{
		SelectedSphere = Spawn( class'XComGroupedSoundSphere' );
		SelectedSphere.fRadius = fDefaultSphereRadius;
		SelectedSphere.GroupSoundType = GroupSoundType;
		SoundSphereList.AddItem( SelectedSphere );
	}

	return SelectedSphere;
}



function bool IsTileInSphere( XComGroupedSoundSphere Sphere, TTile Tile )
{
	local float fTileToSphereDistSq;
	local Vector vTileWorldPos;

	vTileWorldPos = `XWORLD.GetPositionFromTileCoordinates( Tile );
	
	fTileToSphereDistSq = ( 
		Square( vTileWorldPos.X - Sphere.vPos.X ) + 
		Square( vTileWorldPos.Y - Sphere.vPos.Y ) + 
		Square( vTileWorldPos.Z - Sphere.vPos.Z ) );


	// Note: fDefaultSphereRadius is used here instead of fDefaultTileRadius
	// to essentially help ensure single tiles are more readily seen as inside
	// spheres.  This encourages tile grouping, and discourages new sphere 
	// creation.  mdomowicz 2015_08_18
	return ( fTileToSphereDistSq < Square( Sphere.fRadius + fDefaultSphereRadius ) );
}



function Init( EGroupedSoundType DesiredGroupSoundType )
{
	GroupSoundType = DesiredGroupSoundType;
	InitDefaultRadii();
}


// When running the game via TQL, the WORLD_StepSize is 0 at the time
// of the call to Init().  So this InitDefaultRadii() function is called
// mid-runtime to ensure the values are set properly.  mdomowicz 2015_09_02
function InitDefaultRadii()
{
	fDefaultTileRadius = class'XComWorldData'.const.WORLD_StepSize * 1.0f;
	fDefaultSphereRadius = class'XComWorldData'.const.WORLD_StepSize * 4.0f;
}



defaultproperties
{
}
