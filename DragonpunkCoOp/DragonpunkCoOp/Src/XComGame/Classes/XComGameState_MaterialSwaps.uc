//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MaterialSwaps.uc
//  AUTHOR:  David Burchanowski  --  04/30/2014
//  PURPOSE: Component gamestate to track material changes to an object
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_MaterialSwaps extends XComGameState_BaseObject
	native(Core);

struct native MaterialSwapEntry
{
	var string SwapMaterialPath;
	var int MaterialIndex;
};

var private array<MaterialSwapEntry> MaterialSwaps;

native function string GetMaterialPath(MaterialInterface Material);

// Adds or updates a material swap to this state.
function SetMaterialSwap(MaterialInterface SwapMaterial, int MaterialIndex)
{
	local MaterialSwapEntry Swap;
	local int Index;

	// check if we already had a swap for this index. If so, update it
	for(Index = 0; Index < MaterialSwaps.Length; Index++)
	{
		if(MaterialSwaps[Index].MaterialIndex == MaterialIndex)
		{
			MaterialSwaps[Index].SwapMaterialPath = GetMaterialPath(SwapMaterial);
			return;
		}
	}

	// we didn't already have this swap, add it
	Swap.MaterialIndex = MaterialIndex;
	Swap.SwapMaterialPath = GetMaterialPath(SwapMaterial);
	MaterialSwaps.AddItem(Swap);
}

// Applies all swaps tracked by this state to the associated visualizer. This function will probably need to
// be expanded to support different kinds of actors as needed.
function ApplySwapsToVisualizer()
{
	local Actor Visualizer;
	local XComInteractiveLevelActor LevelActor;
	local MaterialSwapEntry Swap;
	local MaterialInterface SwapMaterial;

	Visualizer = GetVisualizer();

	LevelActor = XComInteractiveLevelActor(Visualizer);
	if(LevelActor != none && LevelActor.SkeletalMeshComponent != none)
	{
		foreach MaterialSwaps(Swap)
		{
			// yes this will swap to nothing if the material isn't found. This is intentional, as it
			// acts as an extra in your face debugging tool
			SwapMaterial = MaterialInterface(DynamicLoadObject(Swap.SwapMaterialPath, class'MaterialInterface'));
			LevelActor.SkeletalMeshComponent.SetMaterial(Swap.MaterialIndex, SwapMaterial);
		}
	}
}
