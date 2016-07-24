//---------------------------------------------------------------------------------------
//  FILE:    XComDebrisManager.uc
//  AUTHOR:  Scott Boeckmann --- 1/29/2014
//  PURPOSE: Spawns Debris created from Particle Collision events
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComDebrisManager extends DebrisManager
	native;

var native pointer DebrisManagerData{class FXComDebrisDataStruct};

struct native DebrisSpawnEvent
{
	var DebrisMeshCollection    MeshCollection;
	var vector                  HitLocation;
	var float                   DebrisStrength;
	var float                   SpawnDelay;
};

var transient array<DebrisSpawnEvent>   DebrisEvents;

cpptext
{	
	virtual void BeginDestroy();
	virtual void TickSpecial(FLOAT DeltaSeconds);

	void CreateDebrisManagerData();
	void EmptyManagerData();

	UBOOL FindDebrisData(FVector InSpawnLocation, struct FDebrisTileData& OutValue);
	void SetupInstancedStaticMesh(struct FDebrisTypeData& DebrisTypeData, UStaticMesh* pDebrisMesh);

	void SpawnDebrisImmediate(UDebrisMeshCollection* InDebrisCollection, FVector InSpawnLocation, FLOAT InDebrisStrength);

	void HideDebrisWithinBounds(FBox InBounds, UBOOL bNewHidden);

public:
	void RemoveDebrisFromTile(FTTile Tile);
	void RemoveAllDebris();
}

native function SpawnDebrisNative(ParticleSystemComponent InComp, DebrisMeshCollection InDebrisCollection, vector InSpawnLocation, float InDebrisStrength, float InSpawnDelay);

event SpawnDebris(ParticleSystemComponent InComp, DebrisMeshCollection InDebrisCollection, vector InSpawnLocation, float InDebrisStrength, float InSpawnDelay)
{
	SpawnDebrisNative(InComp, InDebrisCollection, InSpawnLocation, InDebrisStrength, InSpawnDelay);
}

defaultproperties
{
}