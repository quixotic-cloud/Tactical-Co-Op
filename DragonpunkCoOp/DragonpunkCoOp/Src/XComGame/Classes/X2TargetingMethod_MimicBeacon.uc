//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_MimicBeacon extends X2TargetingMethod_Grenade;

function Update(float DeltaTime)
{
	local vector NewTargetLocation;
	local array<vector> TargetLocations;
	local array<TTile> Tiles;
	local array<Actor> CurrentlyMarkedTargets;

	NewTargetLocation = GetSplashRadiusCenter();

	if( NewTargetLocation != CachedTargetLocation )
	{
		// The target location has moved, check to see if the new tile
		// is a valid location for the mimic beacon
		TargetLocations.AddItem(Cursor.GetCursorFeetLocation());
		if( ValidateTargetLocations(TargetLocations) == 'AA_Success' )
		{
			// Valid tile, update UI
			GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
			DrawAOETiles(Tiles);
		}
	}

	UpdateTargetLocation(DeltaTime);
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	local name AbilityAvailability;
	local TTile TeleportTile;
	local XComWorldData World;
	local bool bFoundFloorTile;

	AbilityAvailability = super.ValidateTargetLocations(TargetLocations);
	if( AbilityAvailability == 'AA_Success' )
	{
		World = `XWORLD;
		
		bFoundFloorTile = World.GetFloorTileForPosition(TargetLocations[0], TeleportTile);
		if( bFoundFloorTile && !World.CanUnitsEnterTile(TeleportTile) )
		{
			AbilityAvailability = 'AA_TileIsBlocked';
		}
	}

	return AbilityAvailability;
}