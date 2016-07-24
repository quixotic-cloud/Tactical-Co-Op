//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ApplyAcidToWorld.uc
//  AUTHOR:  Ryan McFall
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ApplyAcidToWorld extends X2Effect_World config(GameData);

var config string AcidParticleSystemFill_Name_1pc;
var config string AcidParticleSystemFill_Name_2pc;
var config string AcidParticleSystemFill_Name_3pc_Long;
var config string AcidParticleSystemFill_Name_3pc_Corner;
var config string AcidParticleSystemFill_Name_4pc_Long;
var config string AcidParticleSystemFill_Name_4pc_Square;
var config string AcidParticleSystemFill_Name_4pc_L;
var config string AcidParticleSystemFill_Name_4pc_Reverse_L;
var config string AcidParticleSystemFill_Name_4pc_Middle;
var config string AcidParticleSystemFill_Name_4pc_S;
var config string AcidParticleSystemFill_Name_4pc_Reverse_S;

function DetermineBlocks( array<TileIsland> TileIslands, out array<TilePosPair> OutTiles, out array<TileParticleInfo> OutParticleInfos )
{
	DetermineAcidBlocks( TileIslands, OutTiles, OutParticleInfos );
}

// Called from native code to get a list of effects to apply, as well as by the effect system based on EffectRefs
event array<X2Effect> GetTileEnteredEffects()
{
	local array<X2Effect> TileEnteredEffectsUncached;

	TileEnteredEffectsUncached.AddItem(class'X2StatusEffects'.static.CreateAcidBurningStatusEffect(2, 1));

	return TileEnteredEffectsUncached;
}

static simulated event bool ShouldRemoveFromDestroyedFloors() { return true; }

event array<ParticleSystem> GetParticleSystem_Fill()
{
	local array<ParticleSystem> ParticleSystems;
	ParticleSystems.AddItem(none);
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_1pc, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_2pc, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_3pc_Long, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_3pc_Corner, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_4pc_Long, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_4pc_Square, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_4pc_L, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_4pc_Reverse_L, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_4pc_Middle, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_4pc_S, class'ParticleSystem')));
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(AcidParticleSystemFill_Name_4pc_Reverse_S, class'ParticleSystem')));
	return ParticleSystems;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
}

static simulated function AddAcidToTilesShared( Name EffectName, XComGameState NewGameState, array<TilePosPair> AcidTiles, XComGameState_Unit SourceStateObject, optional bool LDEffect = false )
{
	local XComGameState_WorldEffectTileData GameplayTileUpdate;
	local VolumeEffectTileData InitialTileData;	
	local array<TileParticleInfo> AcidTileParticleInfos;
	local array<TileIsland> TileIslands;

	TileIslands = CollapseTilesToPools(AcidTiles);
	DetermineAcidBlocks(TileIslands, AcidTiles, AcidTileParticleInfos);

	GameplayTileUpdate = XComGameState_WorldEffectTileData(NewGameState.CreateStateObject(class'XComGameState_WorldEffectTileData'));
	GameplayTileUpdate.WorldEffectClassName = EffectName;

	InitialTileData.EffectName = EffectName;
	InitialTileData.NumTurns = 1;			
	InitialTileData.LDEffectTile = LDEffect;

	GameplayTileUpdate.SetInitialTileData( AcidTiles, InitialTileData, AcidTileParticleInfos);
	NewGameState.AddStateObject(GameplayTileUpdate);

	`XEVENTMGR.TriggerEvent( 'GameplayTileEffectUpdate', GameplayTileUpdate, SourceStateObject, NewGameState );
}

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityStateObject;
	local XComGameState_Unit SourceStateObject;
	local XComGameState_Item SourceItemStateObject;
	local float AbilityRadius, AbilityCoverage;
	local XComWorldData WorldData;
	local vector TargetLocation, TopLocation;
	local array<TilePosPair> OutTiles;

	//If this damage effect has an associated position, it does world damage
	if( ApplyEffectParameters.AbilityInputContext.TargetLocations.Length > 0 )
	{
		History = `XCOMHISTORY;
		SourceStateObject = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		SourceItemStateObject = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));	
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));									

		if( SourceStateObject != none && SourceItemStateObject != none && AbilityStateObject != none )
		{	
			WorldData = `XWORLD;
			AbilityRadius = AbilityStateObject.GetAbilityRadius();
			AbilityCoverage = AbilityStateObject.GetAbilityCoverage();
			TargetLocation = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
			
			TopLocation = TargetLocation;
			TopLocation.Z += AbilityRadius;
			
			WorldData.CollectFloorTilesBelowDisc( OutTiles, TopLocation, AbilityRadius );
			
			AddEffectToTiles(Class.Name, self, NewGameState, OutTiles, TargetLocation, AbilityRadius, AbilityCoverage);
		}
	}
}

static simulated event AddLDEffectToTiles( name EffectName, XComGameState NewGameState, array<TilePosPair> Tiles, array<int> TileIntensities )
{
	//Intensity values are currently irrelevant for acid

	AddAcidToTilesShared( EffectName, NewGameState, Tiles, none, true );
}

static simulated event AddEffectToTiles(Name EffectName, X2Effect_World Effect, XComGameState NewGameState, array<TilePosPair> Tiles, vector TargetLocation, float AbilityRadius, float AbilityCoverage, optional XComGameState_Unit SourceStateObject, optional XComGameState_Item SourceItemState, optional bool bUseFireChance)
{
	local TTile TopTile;
	local int NumToRemove, RemoveIndex;
	local int Index;
	local VoxelRaytraceCheckResult VisInfo;
	local vector TopLocation;

	TopLocation = TargetLocation;
	TopLocation.Z += AbilityRadius;

	TopTile = `XWORLD.GetTileCoordinatesFromPosition( TopLocation );
	`XWORLD.ClampTile( TopTile );

	NumToRemove = Tiles.Length * (1 - AbilityCoverage / 100);

	// First cull out invalid tiles.
	//   Tiles with pre-existing fire or acid
	//   Tiles with no LOS to the top of the ability radius
	for (Index = 0; Index < Tiles.Length; ++Index)
	{
		//   Already contains Fire or acid
		if (`XWORLD.TileContainsFire( Tiles[Index].Tile ) || `XWORLD.TileContainsAcid( Tiles[Index].Tile ))
		{
			Tiles.Remove( Index, 1 );
			NumToRemove--;
			Index--;

			continue;
		}

		//   Tiles with no LOS to the top of the ability radius
		if (`XWORLD.VoxelRaytrace_Tiles( TopTile, Tiles[Index].Tile, VisInfo ) == true)
		{
			if (VisInfo.BlockedTile != Tiles[Index].Tile)
			{
				Tiles.Remove( Index, 1 );
				NumToRemove--;
				Index--;

				continue;
			}
		}
	}

	for( Index = 0; Index < NumToRemove; ++Index )
	{
		RemoveIndex = `SYNC_RAND_STATIC(Tiles.Length);
		Tiles.Remove(RemoveIndex,1);
	}

	AddAcidToTilesShared( EffectName, NewGameState, Tiles, SourceStateObject );
}

event AddWorldEffectTickEvents( XComGameState NewGameState, XComGameState_WorldEffectTileData TickingWorldEffect )
{
	local int Index;
	local XComGameState_EnvironmentDamage DamageEvent;
	local TilePosPair Pair;
	local array<TilePosPair> OutTiles;

	for (Index = 0; Index < TickingWorldEffect.StoredTileData.Length; ++Index)
	{
		// only acid that is timing out deals damage to the environment
		if (TickingWorldEffect.StoredTileData[Index].Data.NumTurns >= 0)
		{
			continue;
		}

		Pair.Tile = TickingWorldEffect.StoredTileData[Index].Tile;
		if (`XWORLD.TileHasFloorThatIsDestructible( Pair.Tile ))
		{
			Pair.Tile = TickingWorldEffect.StoredTileData[Index].Tile;
			Pair.WorldPos = `XWORLD.GetPositionFromTileCoordinates( Pair.Tile );
			OutTiles.AddItem( Pair );
		}
	}

	if (OutTiles.Length > 0)
	{
		DamageEvent = XComGameState_EnvironmentDamage( NewGameState.CreateStateObject( class'XComGameState_EnvironmentDamage' ) );

		DamageEvent.DamageAmount = 500;
		DamageEvent.bRadialDamage = true;
		DamageEvent.bAffectFragileOnly = false;

		for (Index = 0; Index < OutTiles.Length; ++Index)
		{
			`assert( OutTiles[Index].Tile.Z > 0 ); // how do we have a destructible floor for Z-index 0? that's bad

			// find what the next floor tile down is (possibly even just a single tile).
			Pair = OutTiles[Index];
			--Pair.Tile.Z;
			Pair.Tile.Z = `XWORLD.GetFloorTileZ( Pair.Tile, true );

			DamageEvent.DamageTiles.AddItem( OutTiles[Index].Tile );

			//   Already contains Fire or acid, ignore it
			if (`XWORLD.TileContainsFire( Pair.Tile ) || `XWORLD.TileContainsAcid( Pair.Tile ))
			{
				OutTiles.Remove( Index, 1 );
				Index--;

				continue;
			}

			// update the set of tiles for the new floor tile
			Pair.WorldPos = `XWORLD.GetPositionFromTileCoordinates( Pair.Tile );
			OutTiles[Index] = Pair;
		}

		NewGameState.AddStateObject( DamageEvent );
		AddAcidToTilesShared( Class.Name, NewGameState, OutTiles, none );
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local X2Action_UpdateWorldEffects_Acid AddAcidAction;
	if( BuildTrack.StateObject_NewState.IsA('XComGameState_WorldEffectTileData') )
	{
		AddAcidAction = X2Action_UpdateWorldEffects_Acid(class'X2Action_UpdateWorldEffects_Acid'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		AddAcidAction.bCenterTile = bCenterTile;
		AddAcidAction.SetParticleSystems(GetParticleSystem_Fill());
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const int TickIndex, XComGameState_Effect EffectState)
{
}


defaultproperties
{
	DamageTypes.Add("Acid");
	bCenterTile=false
}