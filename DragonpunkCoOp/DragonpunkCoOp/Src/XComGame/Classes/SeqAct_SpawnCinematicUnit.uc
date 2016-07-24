//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_SpawnCinematicUnit.uc
//  AUTHOR:  David Burchanowski  --  1/26/2016
//  PURPOSE: Spawns a unit from the "cinematic" spawn options
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_SpawnCinematicUnit extends SequenceAction;

// Enum of possible range filter options
enum CinematicSpawnCenterType
{
	NoRangeLimit, // any spawn point on the map is fair game
	RelativeToSquadCenter, // only spawns between MinTileRange and MaxTileRage from the centerpoint of the squad will be considered
	RelativeToSpecifiedUnit, // only spawns between MinTileRange and MaxTileRage from FilterUnit will be considered
	RelativeToObjective, // only spawns between MinTileRange and MaxTileRage from the primary object will be considered
	RelativeToLineOfPlay, // only spawns between MinTileRange and MaxTileRage from the line of play will be considered
};

// Specifies the type of range filtering to do, if any
var() private const CinematicSpawnCenterType RangeFilter;

// Specifies the minimum tile range limit if using a range filter
var() private const int MinTileRange;

// Specifies the maximum tile range limit if using a range filter
var() private const int MaxTileRange;

// Additionally limits the potential spawn locations to just those with the specified character template
var() private const string CharacterTemplate;

// Additionally limits the potential spawn locations to just those with the specified tag
var() private const string FilterTag;

// If using RelativeToSpecifiedUnit as the RangeFilter, specifies the unit the range limits are relative to
var private XComGameState_Unit FilterUnit;

// reference to the unit that was spawned, if any
var private XComGameState_Unit SpawnedUnit;

event Activated()
{
	local array<X2CinematicSpawnPoint> FilteredSpawnPoints;
	local X2CinematicSpawnPoint SelectedSpawnPoint;

	// choose a spawn point and spawn a unit into our game state
	GetFilteredSpawnPoints(FilteredSpawnPoints);
	if(FilteredSpawnPoints.Length == 0)
	{
		`Redscreen("No spawn points were found that satisfied the spawn criteria for " $ PathName(self));
		SpawnedUnit = none;
		return;
	}

	SelectedSpawnPoint = FilteredSpawnPoints[`SYNC_RAND(FilteredSpawnPoints.Length)];
	SpawnedUnit = class'XComGameStateContext_CinematicSpawn'.static.AddCinematicSpawnGameState(SelectedSpawnPoint);
}

private function GetFilteredSpawnPoints(out array<X2CinematicSpawnPoint> FilteredSpawnPoints)
{
	local XComWorldData WorldData;
	local X2CinematicSpawnPoint SpawnPoint;
	local vector FilterCenter;
	local float MinDistanceSquared;
	local float MaxDistanceSquared;
	local float DistanceSquared;
	local int Index;

	// start by gathering all Spawn points that are able to spawn and valid for the filter tag
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'X2CinematicSpawnPoint', SpawnPoint)
	{
		if(CharacterTemplate != "" && CharacterTemplate != SpawnPoint.CharacterTemplate)
		{
			continue;
		}

		if(FilterTag != "" && FilterTag != SpawnPoint.FilterTag)
		{
			continue;
		}

		if(!SpawnPoint.CanSpawnUnit())
		{
			continue;
		}

		// basic filtering criteria check out, add this point to the list
		FilteredSpawnPoints.AddItem(SpawnPoint);
	}

	// and then filter by range, if needed
	if(RangeFilter == NoRangeLimit)
	{
		return; // no need to do any range filtering
	}
	else if(MinTileRange <= 0 && MaxTileRange <= 0)
	{
		// validate we have ranges
		`Redscreen("A range filter was specified but MinTileRange and MaxTileRange are both unspecified.");
		return;
	}

	// convert the min and max ranges to unreal units
	MinDistanceSquared = MinTileRange * class'XComWorldData'.const.WORLD_StepSize;
	MaxDistanceSquared = MaxTileRange * class'XComWorldData'.const.WORLD_StepSize;
	MinDistanceSquared *= MinDistanceSquared; // actually square the ranges
	MaxDistanceSquared *= MaxDistanceSquared;

	if(RangeFilter == RelativeToLineOfPlay)
	{
		// TODO: the line of play filter needs it's own handler because it filters by range from a line segment,
		// not a center point
		`Redscreen("This is not yet implemented.");
	}
	else
	{
		// all other range filters are relative to a point, so they can share most logic

		// first determine the center point
		switch(RangeFilter)
		{
		case RelativeToObjective:
			if(!`TACTICALMISSIONMGR.GetObjectivesCenterpoint(FilterCenter))
			{
				`Redscreen("SeqAct_SpawnCinematicUnit: RangeFilter is RelativeToObjective but no objectives found!");
				FilterCenter = class'SeqAct_GetXComTeamCenterpoint'.static.GetXComTeamCenterpoint(); // use squad center as a fallback
			}
			break;

		case RelativeToSpecifiedUnit:
			if(FilterUnit != none)
			{
				`Redscreen("SeqAct_SpawnCinematicUnit: RangeFilter is RelativeToSpecifiedUnit but no unit provided!");
				// use squad center as a fallback
				FilterCenter = class'SeqAct_GetXComTeamCenterpoint'.static.GetXComTeamCenterpoint(); // use squad center as a fallback
			}

			WorldData = `XWORLD;
			FilterCenter = WorldData.GetPositionFromTileCoordinates(FilterUnit.TileLocation);
			break;

		case RelativeToSquadCenter:
			FilterCenter = class'SeqAct_GetXComTeamCenterpoint'.static.GetXComTeamCenterpoint();
			break;

		default:
			`assert(false); // unspecified range limiter!
		}

		// and then filter out by range from the center point
		for(Index = FilteredSpawnPoints.Length - 1; Index >= 0; Index--)
		{
			DistanceSquared = VSizeSq(FilterCenter - FilteredSpawnPoints[Index].Location);
			if((MinDistanceSquared > 0 && DistanceSquared < MinDistanceSquared) 
				|| (MaxDistanceSquared > 0 && DistanceSquared > MaxDistanceSquared))
			{
				FilteredSpawnPoints.Remove(Index, 1);
			}
		}
	}
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Cinematic Spawn Unit"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	bAutoActivateOutputLinks=true

	MinTileRange = -1
	MaxTileRange = -1

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Spawned Unit",PropertyName=SpawnedUnit,bWriteable=true)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Filter Unit",PropertyName=FilterUnit)
}
