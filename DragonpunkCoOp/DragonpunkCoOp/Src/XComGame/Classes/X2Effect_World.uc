//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_World.uc
//  AUTHOR:  Ryan McFall
//
//  Base class for effects that are applied to the world, and not to units. These require
//  additional handling. This indirection allows the world data to generically apply effects
//  to objects entering tiles.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_World extends X2Effect 
	abstract 
	native(Core);

var bool bCenterTile;

// Overridden by base classes
event array<X2Effect> GetTileEnteredEffects();

event array<ParticleSystem> GetParticleSystem_Fill();

event AddWorldEffectTickEvents( XComGameState NewGameState, XComGameState_WorldEffectTileData TickingWorldEffect );

native static function array<TileIsland> CollapseTilesToPools( out array<TilePosPair> Collection, optional array<VolumeEffectTileData> TileDatas );
native static function DetermineFireBlocks( array<TileIsland> TileIslands, out array<TilePosPair> OutTiles, out array<TileParticleInfo> OutParticleInfos );
native static function DetermineAcidBlocks( array<TileIsland> TileIslands, out array<TilePosPair> OutTiles, out array<TileParticleInfo> OutParticleInfos );

event DetermineBlocks( array<TileIsland> TileIslands, out array<TilePosPair> OutTiles, out array<TileParticleInfo> OutParticleInfos )
{
	DetermineFireBlocks( TileIslands, OutTiles, OutParticleInfos );
}

static simulated function FilterForLOS( out array<TilePosPair> Tiles, vector TargetLocation, float Radius )
{
	local TTile TargetTile, TestTile;
	local int x;
	local VoxelRaytraceCheckResult VisInfo;

	if (FillRequiresLOSToTargetLocation( ))
	{
		TargetTile = `XWORLD.GetTileCoordinatesFromPosition( TargetLocation );
		for (x = 0; x < Tiles.Length; ++x)
		{
			TestTile = Tiles[x].Tile;

			if (`XWORLD.VoxelRaytrace_Tiles( TargetTile, TestTile, VisInfo ) == true)
			{
				Tiles.Remove( x, 1 );
				--x;
			}
		}
	}
}

static simulated event AddLDEffectToTiles( name EffectName, XComGameState NewGameState, array<TilePosPair> Tiles, array<int> TileIntensities)
{
	local XComGameState_WorldEffectTileData GameplayTileUpdate;
	local array<TileIsland> TileIslands;
	local array<TileParticleInfo> TileParticleInfos;
	local VolumeEffectTileData InitialTileData;
	local array<VolumeEffectTileData> AllTileDatas;
	local int Intensity, Index;

	GameplayTileUpdate = XComGameState_WorldEffectTileData( NewGameState.CreateStateObject( class'XComGameState_WorldEffectTileData' ) );
	GameplayTileUpdate.WorldEffectClassName = EffectName;

	InitialTileData.EffectName = EffectName;
	InitialTileData.NumTurns = GetTileDataNumTurns( );
	InitialTileData.DynamicFlagUpdateValue = GetTileDataDynamicFlagValue( );
	InitialTileData.LDEffectTile = true;

	GameplayTileUpdate.PreSizeTileData( Tiles.Length );

	if (HasFillEffects( ))
	{
		foreach TileIntensities( Intensity )
		{
			InitialTileData.Intensity = Intensity;
			AllTileDatas.AddItem( InitialTileData );
		}

		TileIslands = CollapseTilesToPools( Tiles, AllTileDatas );
		DetermineFireBlocks( TileIslands, Tiles, TileParticleInfos );

		for (Index = 0; Index < Tiles.Length; ++Index)
		{
			GameplayTileUpdate.AddInitialTileData( Tiles[Index], AllTileDatas[Index], TileParticleInfos[Index] );
		}
	}
	else
	{
		for (Index = 0; Index < Tiles.Length; ++Index)
		{
			InitialTileData.Intensity = TileIntensities[Index];

			GameplayTileUpdate.AddInitialTileData( Tiles[Index], InitialTileData );
		}
	}
	NewGameState.AddStateObject( GameplayTileUpdate );

	`XEVENTMGR.TriggerEvent( 'GameplayTileEffectUpdate', GameplayTileUpdate, none, NewGameState );
}

static simulated event AddEffectToTiles(Name EffectName, X2Effect_World Effect, XComGameState NewGameState, array<TilePosPair> Tiles, vector TargetLocation, float Radius, float Coverage, optional XComGameState_Unit SourceStateObject, optional XComGameState_Item SourceWeaponState, optional bool bUseFireChance)
{
	local XComGameState_WorldEffectTileData GameplayTileUpdate;
	local array<TileIsland> TileIslands;
	local array<TileParticleInfo> TileParticleInfos;
	local VolumeEffectTileData InitialTileData;

	GameplayTileUpdate = XComGameState_WorldEffectTileData(NewGameState.CreateStateObject(class'XComGameState_WorldEffectTileData'));
	GameplayTileUpdate.WorldEffectClassName = EffectName;

	InitialTileData.EffectName = EffectName;
	InitialTileData.NumTurns = GetTileDataNumTurns();
	InitialTileData.DynamicFlagUpdateValue = GetTileDataDynamicFlagValue();
	if (SourceStateObject != none)
		InitialTileData.SourceStateObjectID = SourceStateObject.ObjectID;
	if (SourceWeaponState != none)
		InitialTileData.ItemStateObjectID = SourceWeaponState.ObjectID;

	FilterForLOS( Tiles, TargetLocation, Radius );

	if (HasFillEffects())
	{
		TileIslands = CollapseTilesToPools(Tiles);
		DetermineFireBlocks(TileIslands, Tiles, TileParticleInfos);

		GameplayTileUpdate.SetInitialTileData( Tiles, InitialTileData, TileParticleInfos );
	}
	else
	{
		GameplayTileUpdate.SetInitialTileData( Tiles, InitialTileData );
	}
	NewGameState.AddStateObject(GameplayTileUpdate);
			
	`XEVENTMGR.TriggerEvent( 'GameplayTileEffectUpdate', GameplayTileUpdate, SourceStateObject, NewGameState );
}

//  Feel free to override this in a child class; this is a basic implementation of adding some effect to all tiles within the ability's radius.
simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityStateObject;
	local XComGameState_Unit SourceStateObject;
	local XComGameState_Item SourceItemStateObject;
	local float AbilityRadius, AbilityCoverage;
	local XComWorldData WorldData;
	local vector TargetLocation;
	local array<TilePosPair> OutTiles;
	local X2AbilityTemplate AbilityTemplate;
	local array<TTile> AbilityTiles;
	local TilePosPair OutPair;
	local int i;

	//If this damage effect has an associated position, it does world damage
	if( ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0 )
	{
		History = `XCOMHISTORY;
		SourceStateObject = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		SourceItemStateObject = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));	
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));									

		if( SourceStateObject != none && AbilityStateObject != none && (SourceItemStateObject != none || !RequireSourceItemForEffect()) )
		{
			AbilityTemplate = AbilityStateObject.GetMyTemplate();
			if( AbilityTemplate.AbilityMultiTargetStyle != none )
			{
				WorldData = `XWORLD;
				AbilityRadius = AbilityStateObject.GetAbilityRadius();
				AbilityCoverage = AbilityStateObject.GetAbilityCoverage();
				TargetLocation = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
				AbilityTemplate.AbilityMultiTargetStyle.GetValidTilesForLocation(AbilityStateObject, TargetLocation, AbilityTiles);
				for( i = 0; i < AbilityTiles.Length; ++i )
				{
					OutPair.Tile = AbilityTiles[i];
					OutPair.WorldPos = WorldData.GetPositionFromTileCoordinates(OutPair.Tile);

					if (OutTiles.Find('Tile', OutPair.Tile) == INDEX_NONE)
					{
						OutTiles.AddItem(OutPair);
					}
				}
					
				AddEffectToTiles( GetWorldEffectClassName(), self, NewGameState, OutTiles, TargetLocation, AbilityRadius, AbilityCoverage, SourceStateObject, SourceItemStateObject );
			}
		}
	}
}

simulated function name GetWorldEffectClassName() { return Class.Name; }
simulated function name GetTileDataEffectName() { return Class.Name; }
static simulated function int GetTileDataNumTurns() { return 1; }
static simulated function int GetTileDataDynamicFlagValue() { return 0; }
static simulated function bool RequireSourceItemForEffect() { return true; }
static simulated event bool ShouldRemoveFromDestroyedFloors() { return false; }
static simulated function bool HasFillEffects() { return true; }
static simulated function bool FillRequiresLOSToTargetLocation() { return false; }
static simulated event float GetIntensityLERPTime() { return 0.0f; }
static simulated event bool IsConsideredHazard( const out VolumeEffectTileData TileData ) { return TileData.NumTurns > -1; }

defaultproperties
{
	bCenterTile = true;
}