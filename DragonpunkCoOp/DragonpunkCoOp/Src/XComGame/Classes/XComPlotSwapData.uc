//---------------------------------------------------------------------------------------
//  FILE:    X2CameraStack.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Data container class so that the LDs can specify the plot information
//           in a separate config file from the other parcel data.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComPlotSwapData extends Object
	native(Core)
	config(PlotSwaps);

// Plot swaps all behave in basically the same way. The LDs can setup a "bucket" of archetypes for things that load into the world,
// and then if we find an archetype in a bucket that doesn't match the type of plot we are loading into, we can find another
// bucket of the same bucket type but the correct plot type and replace with one of its archetypes.
// Example: You have a bushy tree in temperate wilderness that needs to be a dead tree when you load into an arid map.
// if you setup this data:
//  Bucket1 = (BucketType="Tree", PlotType="Wilderness", BiomeType="Temperate", Archetypes[0]="BushyTree")
//  Bucket2 = (BucketType="Tree", PlotType="Wilderness", BiomeType="Arid", Archetypes[0]="DeadTree")
//
// then the dead and live trees will automatically replace each other when loading into arid and temperate wilderness maps
// if they are of the wrong type of tree (bushy tree in an arid map, etc).

struct native PlotActorSwapInfo
{
	var array<string> arrPlotType;          // plot type the archetypes in this bucket are valid for
	var string strBiomeType;                // biome type the archetypes in this bucket are valid for
	var string strBucketType;               // type of this bucket.
	var array<string> arrArchetypes;        // All XComLevelActor archetypes that belong to this bucket
	var array<string> arrBlueprintMapNames; // All blueprint map names that belong to this bucket
	var bool AlwaysSwap;                    // even if this is the bucket we want, swap the contents around to increase variety
};

struct native PlotMaterialSwapInfo
{
	var array<string> arrPlotType;
	var string strBiomeType;
	var string strBucketType;
	var array<string> arrMaterials;
	var bool AlwaysSwap;                    // even if this is the bucket we want, swap the contents around to increase variety
};

struct native PlotFoliageSwapInfo
{
	var array<string> arrPlotType;
	var string strBiomeType;
	var string strBucketType;
	var array<string> strFoliageMesh;
};

struct native WaterParticleSwapInfo
{
	var array<string> arrPlotType;
	var string strBiomeType;
	var string strBucketType;
	var array<string> arrParticleSystems;
};

var private const config array<PlotActorSwapInfo> arrPlotActorSwapInfo;
var private const config array<PlotMaterialSwapInfo> arrPlotMaterialSwapInfo;
var private const config array<PlotFoliageSwapInfo> arrPlotFoliageSwapInfo;
var private const config array<WaterParticleSwapInfo> arrWaterParticleSwapInfo;

// Scans through a fully loaded plot, its parcels and pcps and replaces actors that don't belong
// in a particular plot type/biome with acceptable alternatives for the target plot type. For example,
// if you have a cactus in a map that should be temperate, this would replace it with a tree.
static private native function SwapActorsAndBlueprints(string TargetBiomeType, string TargetPlotType);

// Scans through a fully loaded plot and does the same thing that SwapActors does, but for materials.
static private native function SwapMaterials(string TargetBiomeType, string TargetPlotType);

// Same thing again, but for deco
static private native function SwapDeco(string TargetBiomeType, string TargetPlotType);

static private native function SwapFoliage(string TargetBiomeType, string TargetPlotType);

static private native function SwapWaterParticles(string TargetBiomeType, string TargetPlotType);

static private native function RefreshTextureStreamingData();

// hook used by the blueprint loading system to determine if it should load a different blueprint instead.
// it's slightly more complex than just keeping all of the swap logic in this module, but since loading a blueprint
// just to throw it away immediately is very expensive, it's worth it. Returns true if a swap was found.
// note that it could be swapped to a level actor, so if the function returns true and BlueprintToSwapIn
// is none, then the blueprint should just nop and wait for the normal swap logic to replace it.
static native function bool FindBlueprintSwap(XComBlueprint Blueprint, out string BlueprintMapToSwapIn);

// Scans through a fully loaded map and converts anything that doesn't match the biome to
// something that does. i.e., allows you to load arid parcels into temperate plots and have them
// look decent
static function AdjustParcelsForBiomeType(string TargetBiomeType, string TargetPlotType)
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;

	if(TargetPlotType != "")
	{
		// reset the random seed. It's okay to do this here because it only moves the sequence back to the start. The
		// way that is interpreted is different for each system, and so mathematically equally "random" even
		// if each system were to reset the seed
		History = `XCOMHISTORY;
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		class'Engine'.static.SetRandomSeeds(BattleData.iLevelSeed);

		SwapActorsAndBlueprints(TargetBiomeType, TargetPlotType);
		SwapFoliage(TargetBiomeType, TargetPlotType);
		SwapMaterials(TargetBiomeType, TargetPlotType);
		SwapDeco(TargetBiomeType, TargetPlotType);
		SwapWaterParticles(TargetBiomeType, TargetPlotType);
		RefreshTextureStreamingData();
	}
}