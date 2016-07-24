//---------------------------------------------------------------------------------------
//  FILE:    XComGroupedSoundSphere
//  AUTHOR:  Mark F. Domowicz -- 8/14/2015
//  PURPOSE: This is a helper class, used by XComGroupedSoundManager.uc.  See that file
//           for implementation notes.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------


class XComGroupedSoundSphere extends Actor native(Core);

var Vector vPos;
var float fRadius;
var array<TTile> TileList;

var EGroupedSoundType GroupSoundType;


function AddTile( TTile Tile )
{
	if ( TileList.Length == 0 )
	{
		if ( GroupSoundType == eGroupedSoundType_Acid )
		{
			PostAkEvent( AkEvent'SoundEnvironment.AcidLoop_SmallMediumLarge' );
		}
		else if ( GroupSoundType == eGroupedSoundType_Fire )
		{
			PostAkEvent( AkEvent'SoundEnvironment.FireLoop_SmallMediumLarge' );
		}
		else if ( GroupSoundType == eGroupedSoundType_Poison )
		{
			PostAkEvent( AkEvent'SoundEnvironment.GasLoop' );
		}
		else
		{
			`RedScreen("The current GroupSoundType is not supported.");
		}
	}

	TileList.AddItem( Tile );
}



function RemoveTile( TTile Tile )
{
	local TTile TempTile;
	local int i;

	//-----------------------
	// Remove the tile
	for ( i = 0; i < TileList.Length; ++i )
	{
		TempTile = TileList[ i ];
		if ( TempTile.X == Tile.X && TempTile.Y == Tile.Y && TempTile.Z == Tile.Z )
		{
			TileList.Remove( i, 1 );
			--i;
		}
	}

	//-----------------------
	// Stop the audio, if needed
	if ( TileList.Length == 0 )
	{
		if ( GroupSoundType == eGroupedSoundType_Acid )
		{
			PlayAkEvent( AkEvent'SoundEnvironment.Stop_AcidLoop_SmallMediumLarge' );
		}
		else if ( GroupSoundType == eGroupedSoundType_Fire )
		{
			PlayAkEvent( AkEvent'SoundEnvironment.Stop_FireLoop_SmallMediumLarge' );
		}
		else if ( GroupSoundType == eGroupedSoundType_Poison )
		{
			PlayAkEvent( AkEvent'SoundEnvironment.Stop_GasLoop' );
		}
		else
		{
			`RedScreen("The current GroupSoundType is not supported.");
		}
	}
}



function UpdateValues( float fBaseSphereRadius, float fRadiusPerTile )
{
	local float fAudioIntensity;
	local float fAudioRTPCValue;

	//-----------------------
	// Update Position
	vPos = GetAverageTilePosition();
	SetLocation( vPos );


	//-----------------------
	// Update Radius
	fRadius = 0.0f;
	if ( TileList.Length == 1 )
		fRadius = fBaseSphereRadius;
	if ( TileList.Length > 1 )
		fRadius = GetEnclosingRadiusFromCenter( vPos, fRadiusPerTile );

	
	//-----------------------
	// update the AkAudio Real Time Parameter Control
	fAudioIntensity = CalculateAudioIntensityPercent();
	fAudioRTPCValue = Lerp( 1, 100, fAudioIntensity );

	if ( GroupSoundType == eGroupedSoundType_Acid )
	{
		SetRTPCValue( 'AcidSize', fAudioRTPCValue );
	}
	else if ( GroupSoundType == eGroupedSoundType_Fire )
	{
		SetRTPCValue( 'FireSize', fAudioRTPCValue );
	}
	else if ( GroupSoundType == eGroupedSoundType_Poison )
	{
		SetRTPCValue( 'GasSize', fAudioRTPCValue );
	}
	else
	{
		`RedScreen("The current GroupSoundType is not supported.");
	}
}



function float GetEnclosingRadiusFromCenter( Vector vCenter, float fRadiusPerTile )
{
	local TTile Tile;
	local Vector vTilePos;
	local float fTileDistSq;
	local float fFarthestDistSq;
	local XComWorldData WorldData;

	WorldData = `XWORLD;
	fFarthestDistSq = 0.0f;

	foreach TileList( Tile )
	{
		vTilePos = WorldData.GetPositionFromTileCoordinates( Tile );
		fTileDistSq = VSizeSq( vTilePos - vCenter );

		if ( fFarthestDistSq < fTileDistSq )
		{
			fFarthestDistSq = fTileDistSq;
		}
	}

	return Sqrt( fFarthestDistSq ) + fRadiusPerTile;
}



function Vector GetAverageTilePosition()
{
	local Vector vTotalPos;

	if ( TileList.Length > 0 )
	{
		vTotalPos = GetTotalTilePosition();
		vTotalPos /= TileList.Length;
	}

	return vTotalPos;
}



function Vector GetTotalTilePosition()
{
	local TTile Tile;
	local Vector vTotalPos;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	foreach TileList( Tile )
	{
		vTotalPos += WorldData.GetPositionFromTileCoordinates( Tile );
	}

	return vTotalPos;
}



function float CalculateAudioIntensityPercent()
{
	local float fPercent;

	// This is just a first pass/guess at a way to determine intensity.
	// We may want to experiment with something more nuanced later.
	fPercent = FClamp( float(TileList.Length) / 10.0f, 0.0f, 1.0f );
	return fPercent;
}



function bool DoesAddingTileIncreaseRadius( TTile TestTile, float fRadiusPerTile )
{
	local Vector vTilePos;
	local Vector vTestCenter;
	local float fTestEnclosingRadius;


	//-----------------------
	// calculate what the new center would be with the TestTile added
	vTestCenter = GetTotalTilePosition();
	vTestCenter += `XWORLD.GetPositionFromTileCoordinates( TestTile );
	vTestCenter /= ( TileList.Length + 1 );


	//-----------------------
	// Is the enclosing radius needed for the TestTile bigger than
	// the current radius?
	vTilePos = `XWORLD.GetPositionFromTileCoordinates( TestTile );
	fTestEnclosingRadius = VSize( vTilePos - vTestCenter ) + fRadiusPerTile;
	return ( fTestEnclosingRadius > fRadius );
}



event Tick( float DeltaTime )
{
	super.Tick( DeltaTime );

	// Debug only - for visualizing the spheres.
	//DrawDebugSphere( Location, fRadius, 20, 255, 255, 255, false );
}


