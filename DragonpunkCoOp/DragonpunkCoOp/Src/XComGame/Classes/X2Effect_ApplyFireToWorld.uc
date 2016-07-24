//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ApplyFireToWorld.uc
//  AUTHOR:  Ryan McFall
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ApplyFireToWorld extends X2Effect_World config(GameData) 
	native(Core)
	dependson(XComGameState_WorldEffectTileData);

var config string FireParticleSystemFill_Name;
var config int MAX_INTENSITY_2_TILES;
var config int LimitFireSpreadTiles; //Once there are this many tiles on fire in the world, the spread of fire will be limited to one new fire per turn
var config float FillIntensityLERPTimeSecs;

var float FireChance_Level1;
var float FireChance_Level2;
var float FireChance_Level3;

var bool bUseFireChanceLevel;
var bool bDamageFragileOnly;
var bool bCheckForLOSFromTargetLocation; //If set to true, only tiles that are visible from the target location will be set on fire


// Called from native code to get a list of effects to apply, as well as by the effect system based on EffectRefs
event array<X2Effect> GetTileEnteredEffects()
{
	local array<X2Effect> TileEnteredEffectsUncached;

	TileEnteredEffectsUncached.AddItem(class'X2StatusEffects'.static.CreateBurningStatusEffect(2, 1));
	
	return TileEnteredEffectsUncached;
}

static simulated event bool ShouldRemoveFromDestroyedFloors() { return true; }
static simulated function int GetTileDataDynamicFlagValue() { return 4; }  //TileDataIsOnFire
static simulated event float GetIntensityLERPTime() { return default.FillIntensityLERPTimeSecs; }
static simulated event bool IsConsideredHazard( const out VolumeEffectTileData TileData ) { return TileData.NumTurns > 0; }

event array<ParticleSystem> GetParticleSystem_Fill()
{
	local array<ParticleSystem> ParticleSystems;
	ParticleSystems.AddItem(none);
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(FireParticleSystemFill_Name, class'ParticleSystem')));
	return ParticleSystems;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
}

static simulated event AddLDEffectToTiles( name EffectName, XComGameState NewGameState, array<TilePosPair> Tiles, array<int> TileIntensities )
{
	local XComGameState_WorldEffectTileData FireTileUpdate, SmokeTileUpdate;
	local VolumeEffectTileData InitialFireTileData, InitialSmokeTileData;
	local array<VolumeEffectTileData> InitialFireTileDatas;
	local TilePosPair SmokeTile;
	local int Index, SmokeIndex;
	local array<TileIsland> TileIslands;
	local array<TileParticleInfo> FireTileParticleInfos;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	FireTileUpdate = XComGameState_WorldEffectTileData( NewGameState.CreateStateObject( class'XComGameState_WorldEffectTileData' ) );
	FireTileUpdate.WorldEffectClassName = EffectName;
	FireTileUpdate.PreSizeTileData( Tiles.Length );

	SmokeTileUpdate = XComGameState_WorldEffectTileData( NewGameState.CreateStateObject( class'XComGameState_WorldEffectTileData' ) );
	SmokeTileUpdate.WorldEffectClassName = 'X2Effect_ApplySmokeToWorld';
	SmokeTileUpdate.PreSizeTileData( Tiles.Length * 11 ); // conservative worst case estimate (sadly)

	for (Index = 0; Index < Tiles.Length; ++Index)
	{
		InitialFireTileData.EffectName = EffectName;
		InitialFireTileData.Intensity = TileIntensities[Index];
		InitialFireTileData.NumTurns = TileIntensities[Index];
		InitialFireTileData.LDEffectTile = true;

		InitialFireTileDatas.AddItem( InitialFireTileData );

		InitialSmokeTileData.EffectName = SmokeTileUpdate.WorldEffectClassName;
		InitialSmokeTileData.Intensity = -1; // no particle effects needed in this case.  The fire effect makes smoke for us.
		InitialSmokeTileData.DynamicFlagUpdateValue = class'X2Effect_ApplySmokeToWorld'.static.GetTileDataDynamicFlagValue( );
		InitialSmokeTileData.NumTurns = InitialFireTileData.NumTurns;
		InitialSmokeTileData.LDEffectTile = true;

		SmokeTile = Tiles[ Index ];
		// Create tile data smoke flags for some/all of the tiles in the fire's column.
		// The higher up we go the shorter it lasts (matching up with the effect).
		// And we should extend past the top of the level
		for (SmokeIndex = 0; (SmokeIndex < 11) && (SmokeTile.Tile.Z < WorldData.NumZ); ++SmokeIndex)
		{
			if ((SmokeIndex == 3) || (SmokeIndex == 4) || (SmokeIndex == 8))
			{
				if (--InitialSmokeTileData.NumTurns < 0)
				{
					break;
				}
			}

			SmokeTileUpdate.AddInitialTileData( SmokeTile, InitialSmokeTileData );
			SmokeTile.Tile.Z++;
		}
	}

	TileIslands = CollapseTilesToPools( Tiles, InitialFireTileDatas );
	DetermineFireBlocks( TileIslands, Tiles, FireTileParticleInfos );

	for (Index = 0; Index < Tiles.Length; ++Index)
	{
		FireTileUpdate.AddInitialTileData( Tiles[ Index ], InitialFireTileDatas[ Index ], FireTileParticleInfos[ Index ] );
	}

	NewGameState.AddStateObject( FireTileUpdate );
	NewGameState.AddStateObject( SmokeTileUpdate );

	`XEVENTMGR.TriggerEvent( 'GameplayTileEffectUpdate', FireTileUpdate, none, NewGameState );
	`XEVENTMGR.TriggerEvent( 'GameplayTileEffectUpdate', SmokeTileUpdate, none, NewGameState );
}

static simulated function SharedApplyFireToTiles( Name EffectName, X2Effect_ApplyFireToWorld FireEffect, XComGameState NewGameState, array<TilePosPair> OutTiles, XComGameState_Unit SourceStateObject, int ForceIntensity = -1, optional bool UseFireChance = false )
{
	local XComGameState_WorldEffectTileData FireTileUpdate, SmokeTileUpdate;
	local VolumeEffectTileData InitialFireTileData, InitialSmokeTileData;
	local array<VolumeEffectTileData> InitialFireTileDatas;
	local XComDestructibleActor PossibleFuel;
	local TilePosPair SmokeTile;
	local int Index, SmokeIndex, Intensity2;
	local array<TileIsland> TileIslands;
	local array<TileParticleInfo> FireTileParticleInfos;
	local float FireChanceTotal, FireLevelRand;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	FireChanceTotal = FireEffect.FireChance_Level1 + FireEffect.FireChance_Level2 + FireEffect.FireChance_Level3;

	FireTileUpdate = XComGameState_WorldEffectTileData(NewGameState.CreateStateObject(class'XComGameState_WorldEffectTileData'));
	FireTileUpdate.WorldEffectClassName = EffectName;
	FireTileUpdate.PreSizeTileData( OutTiles.Length );

	SmokeTileUpdate = XComGameState_WorldEffectTileData(NewGameState.CreateStateObject(class'XComGameState_WorldEffectTileData'));
	SmokeTileUpdate.WorldEffectClassName = 'X2Effect_ApplySmokeToWorld';
	SmokeTileUpdate.PreSizeTileData( OutTiles.Length * 11 ); // conservative worst case estimate (sadly)

	for (Index = 0; Index < OutTiles.Length; ++Index)
	{
		InitialFireTileData.EffectName = EffectName;
		InitialSmokeTileData.EffectName = SmokeTileUpdate.WorldEffectClassName;
		InitialSmokeTileData.Intensity = -1; // no particle effects needed in this case.  The fire effect makes smoke for us.
		InitialSmokeTileData.DynamicFlagUpdateValue = class'X2Effect_ApplySmokeToWorld'.static.GetTileDataDynamicFlagValue();

		// Initial randomness factor
		if(ForceIntensity > -1)
		{
			InitialFireTileData.NumTurns = ForceIntensity;
		}
		else
		{
			InitialFireTileData.NumTurns = `SYNC_RAND_STATIC(2) + 1;
		}

		if (UseFireChance)
		{
			FireLevelRand = `SYNC_FRAND_STATIC() * FireChanceTotal;
			if(FireLevelRand > (FireEffect.FireChance_Level1 + FireEffect.FireChance_Level2))
			{
				InitialFireTileData.NumTurns = 3;
			}
			else if(FireLevelRand > FireEffect.FireChance_Level1)
			{
				InitialFireTileData.NumTurns = 2;
			}
			else
			{
				InitialFireTileData.NumTurns = 1;
			}
		}


		if (default.MAX_INTENSITY_2_TILES > 0)
		{
			if (Intensity2 > default.MAX_INTENSITY_2_TILES && InitialFireTileData.NumTurns > 1)
				InitialFireTileData.NumTurns = 1;
		}

		if (InitialFireTileData.NumTurns >= 2)
			Intensity2++;

		// Additional length/intensity when there's something to burn
		PossibleFuel = XComDestructibleActor( `XWORLD.GetActorOnTile( OutTiles[Index].Tile, true ) );
		if ((PossibleFuel != none) && (PossibleFuel.Toughness != none))
		{
			InitialFireTileData.NumTurns += PossibleFuel.Toughness.AvailableFireFuelTurns;
		}

		// cap to maximum effect intensity
		InitialFireTileData.Intensity = InitialFireTileData.NumTurns;

		InitialSmokeTileData.NumTurns = InitialFireTileData.NumTurns;
		SmokeTile = OutTiles[Index];

		// Create tile data smoke flags for some/all of the tiles in the fire's column.
		// The higher up we go the shorter it lasts (matching up with the effect).
		// And we should extend past the top of the level
		for (SmokeIndex = 0; (SmokeIndex < 11) && (SmokeTile.Tile.Z < WorldData.NumZ); ++SmokeIndex)
		{
			if ((SmokeIndex == 3) || (SmokeIndex == 4) || (SmokeIndex == 8))
			{
				if (--InitialSmokeTileData.NumTurns < 0)
				{
					break;
				}
			}

			SmokeTileUpdate.AddInitialTileData( SmokeTile, InitialSmokeTileData );
			SmokeTile.Tile.Z++;
		}

		InitialFireTileDatas.AddItem(InitialFireTileData);
	}

	TileIslands = CollapseTilesToPools(OutTiles, InitialFireTileDatas);
	DetermineFireBlocks(TileIslands, OutTiles, FireTileParticleInfos);

	for(Index = 0; Index < OutTiles.Length; ++Index)
	{
		FireTileUpdate.AddInitialTileData(OutTiles[Index], InitialFireTileDatas[Index], FireTileParticleInfos[Index]);
	}

	NewGameState.AddStateObject(FireTileUpdate);
	NewGameState.AddStateObject(SmokeTileUpdate);

	`XEVENTMGR.TriggerEvent( 'GameplayTileEffectUpdate', FireTileUpdate, SourceStateObject, NewGameState );
	`XEVENTMGR.TriggerEvent( 'GameplayTileEffectUpdate', SmokeTileUpdate, SourceStateObject, NewGameState );
}

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityStateObject;
	local XComGameState_Unit SourceStateObject;
	local float AbilityRadius, AbilityCoverage;
	local XComWorldData WorldData;
	local vector TargetLocation;
	local array<TilePosPair> OutTiles;
	local array<TTile> AbilityTiles;
	local TilePosPair OutPair;
	local int i;

	//If this damage effect has an associated position, it does world damage
	if( ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0 )
	{
		History = `XCOMHISTORY;
		SourceStateObject = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));									

		if( SourceStateObject != none && AbilityStateObject != none )
		{	
			WorldData = `XWORLD;
			AbilityRadius = AbilityStateObject.GetAbilityRadius();
			AbilityCoverage = AbilityStateObject.GetAbilityCoverage();
			TargetLocation = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
			AbilityStateObject.GetMyTemplate().AbilityMultiTargetStyle.GetValidTilesForLocation(AbilityStateObject, TargetLocation, AbilityTiles);
			for (i = 0; i < AbilityTiles.Length; ++i)
			{
				if (WorldData.GetFloorPositionForTile(AbilityTiles[i], OutPair.WorldPos))
				{
					if (WorldData.GetFloorTileForPosition(OutPair.WorldPos, OutPair.Tile))
					{
						if (OutTiles.Find('Tile', OutPair.Tile) == INDEX_NONE)
						{
							OutTiles.AddItem(OutPair);
						}
					}
				}
			}
			//WorldData.CollectFloorTilesBelowDisc( OutTiles, TargetLocation, AbilityRadius );
			if (bUseFireChanceLevel)
			{
				AddEffectToTiles(Class.Name, self, NewGameState, OutTiles, TargetLocation, AbilityRadius, AbilityCoverage, SourceStateObject, none, true);
			}
			else
			{
				AddEffectToTiles(Class.Name, self, NewGameState, OutTiles, TargetLocation, AbilityRadius, AbilityCoverage);
			}
		}
	}
}

static simulated event AddEffectToTiles(Name EffectName, X2Effect_World Effect, XComGameState NewGameState, array<TilePosPair> Tiles, vector TargetLocation, float AbilityRadius, float AbilityCoverage, optional XComGameState_Unit SourceStateObject, optional XComGameState_Item SourceItemState, optional bool bUseFireChance)
{
	local XComWorldData WorldData;

	local vector TopLocation;
	local TTile TopTile;
	local TTile TestTile;

	local int NumToRemove;
	local int RemoveIndex;
	local int Index;
	
	local VoxelRaytraceCheckResult VisInfo;
	local XComDestructibleActor PossibleFuel;

	TopLocation = TargetLocation;
	TopLocation.Z += AbilityRadius;
	TopTile = `XWORLD.GetTileCoordinatesFromPosition( TopLocation );
	`XWORLD.ClampTile( TopTile );

	NumToRemove = Tiles.Length * (1 - AbilityCoverage / 100);
	
	WorldData = `XWORLD;

	// First cull out invalid tiles.
	//   Water Tiles
	//   NonFlammable Tile Occupiers.
	//   Tiles with no LOS to the top of the ability radius
	for (Index = 0; Index < Tiles.Length; ++Index)
	{
		//   NonFlammable Tile Occupiers.
		PossibleFuel = XComDestructibleActor( WorldData.GetActorOnTile( Tiles[Index].Tile, true ) );
		if ((PossibleFuel != none) && (PossibleFuel.Toughness != none) && PossibleFuel.Toughness.bNonFlammable)
		{
			Tiles.Remove( Index, 1 );
			NumToRemove--;
			Index--;

			continue;
		}

		//   Water Tiles
		if (WorldData.IsWaterTile( Tiles[Index].Tile ) || WorldData.TileContainsFire( Tiles[Index].Tile ) || WorldData.TileContainsAcid( Tiles[Index].Tile ))
		{
			Tiles.Remove( Index, 1 );
			NumToRemove--;
			Index--;
			
			continue;
		}

		if (bUseFireChance)
		{
			//Flamethrower also does not want flame near the source so remove those tiles
			if ((SourceStateObject.TileLocation.X >= Tiles[Index].Tile.X - 1 && SourceStateObject.TileLocation.X <= Tiles[Index].Tile.X + 1) &&
				(SourceStateObject.TileLocation.Y >= Tiles[Index].Tile.Y - 1 && SourceStateObject.TileLocation.Y <= Tiles[Index].Tile.Y + 1) &&
				(SourceStateObject.TileLocation.Z >= Tiles[Index].Tile.Z - 1 && SourceStateObject.TileLocation.Z <= Tiles[Index].Tile.Z + 1))
			{
				Tiles.Remove(Index, 1);
				NumToRemove--;
				Index--;

				continue;
			}
		}

		//   Tiles with no LOS to the top of the ability radius
		if(X2Effect_ApplyFireToWorld(Effect).bCheckForLOSFromTargetLocation)
		{
			if(`XWORLD.VoxelRaytrace_Tiles(TopTile, Tiles[Index].Tile, VisInfo) == true)
			{
				if(VisInfo.BlockedTile != Tiles[Index].Tile)
				{
					TestTile = VisInfo.BlockedTile;
					TestTile.Z--;

					if((PossibleFuel == none) || (`XWORLD.GetActorOnTile(TestTile, true) != PossibleFuel))
					{
						Tiles.Remove(Index, 1);
						NumToRemove--;
						Index--;

						continue;
					}
				}
			}
		}
	}

	// The select the coverage from the remaining (counting all the invalids against the uncovered percentage).
	for( Index = 0; Index < NumToRemove; ++Index )
	{
		RemoveIndex = `SYNC_RAND_STATIC(Tiles.Length);
		Tiles.Remove(RemoveIndex,1);
	}

	if (bUseFireChance)
	{
		SharedApplyFireToTiles(EffectName, X2Effect_ApplyFireToWorld(Effect), NewGameState, Tiles, SourceStateObject, -1, true);
	}
	else
	{
		SharedApplyFireToTiles(EffectName, X2Effect_ApplyFireToWorld(Effect), NewGameState, Tiles, SourceStateObject);
	}
}

native function GetFireSpreadTiles(out array<TilePosPair> OutTiles, XComGameState_WorldEffectTileData TickingWorldEffect );

event AddWorldEffectTickEvents( XComGameState NewGameState, XComGameState_WorldEffectTileData TickingWorldEffect )
{
	local int Index, CurrentIntensity;
	local array<TilePosPair> OutTiles;
	local array<TTile> DestroyedTiles;
	local TTile Tile;	
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComDestructibleActor TileActor;
	
	//Spread before reducing the intensity
	GetFireSpreadTiles(OutTiles, TickingWorldEffect);
	SharedApplyFireToTiles(Class.Name, self, NewGameState, OutTiles, none);

	// Reduce the intensity of the fire each time it ticks
	for (Index = 0; Index < TickingWorldEffect.StoredTileData.Length; ++Index)
	{
		if (TickingWorldEffect.StoredTileData[Index].Data.LDEffectTile)
		{
			continue;
		}

		CurrentIntensity = TickingWorldEffect.StoredTileData[Index].Data.Intensity;
		TickingWorldEffect.UpdateTileDataIntensity( Index, CurrentIntensity - 1 );

		if (CurrentIntensity == 1)
		{
			DestroyedTiles.AddItem( TickingWorldEffect.StoredTileData[Index].Tile );
		}
	}

	if (DestroyedTiles.Length > 0)
	{
		DamageEvent = XComGameState_EnvironmentDamage( NewGameState.CreateStateObject(class'XComGameState_EnvironmentDamage') );

		DamageEvent.DEBUG_SourceCodeLocation = "UC: X2Effect_ApplyFireToWorld:AddWorldEffectTickEvents()";

		DamageEvent.DamageTypeTemplateName = 'Fire';
		DamageEvent.bRadialDamage = false;
		DamageEvent.DamageAmount = 20;
		DamageEvent.bAffectFragileOnly = bDamageFragileOnly;

		foreach DestroyedTiles( Tile )
		{
			TileActor = XComDestructibleActor( `XWORLD.GetActorOnTile( Tile, true  ) );

			DamageEvent.DamageTiles.AddItem( Tile );

			if (TileActor != none && (TileActor.Toughness == none || !TileActor.Toughness.bInvincible))
			{
				DamageEvent.DestroyedActors.AddItem( TileActor.GetActorID() );
			}
		}

		NewGameState.AddStateObject( DamageEvent );
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local X2Action_UpdateWorldEffects_Fire AddFireAction;
	local XComGameState_WorldEffectTileData GameplayTileUpdate;

	GameplayTileUpdate = XComGameState_WorldEffectTileData(BuildTrack.StateObject_NewState);

	// since we also make smoke, we don't want to add fire effects for those track states
	if((GameplayTileUpdate != none) && (GameplayTileUpdate.WorldEffectClassName == Class.Name) && (GameplayTileUpdate.SparseArrayIndex > -1))
	{
		AddFireAction = X2Action_UpdateWorldEffects_Fire(class'X2Action_UpdateWorldEffects_Fire'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		AddFireAction.bCenterTile = bCenterTile;
		AddFireAction.SetParticleSystems(GetParticleSystem_Fill());
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const int TickIndex, XComGameState_Effect EffectState)
{
}

defaultproperties
{
	bCenterTile = false;
	DamageTypes.Add("Fire");
	bUseFireChanceLevel = false;
	bDamageFragileOnly = false;
	bCheckForLOSFromTargetLocation = true;

	FireChance_Level1 = 0.25f;
	FireChance_Level2 = 0.5f;
	FireChance_Level3 = 0.25f;
}