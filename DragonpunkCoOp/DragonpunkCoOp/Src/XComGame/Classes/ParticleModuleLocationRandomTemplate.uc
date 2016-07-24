/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class ParticleModuleLocationRandomTemplate extends ParticleModule
	native(Particle)
	editinlinenew
	hidecategories(Object)
	abstract;

//=============================================================================
//	Properties
//=============================================================================

/* Force the particles spawned to be placed on the floor of the tile. */
var() bool      bForceSpawnOnFloor;

/* If Forcing spawning on the floor, how many tiles up should we search for floor tiles. */
var() int       iFloorTileSearchDown<EditCondition=bForceSpawnOnFloor>;

/* Should we not spawn when on a tile that is not axis-aligned (i.e. UFO roofs, etc.) */
var() bool      bIgnoreNonAxisAlignedTiles<EditCondition=bForceSpawnOnFloor>;

/* Only spawn in tiles that the flamethrower is affecting. */
var() bool      bUseFlameThrowerTiles;

/* Should we use bucket weighting */
var() bool      bUseBucketWeighting;

/* Scale with which to decrease weight of bucket just spawned in. */
var() float     fWeightScaleDown<EditCondition=bUseBucketWeighting>;

/* Scale with which to increase weight of bucket not spawned in. */
var() float     fWeightScaleUp<EditCondition=bUseBucketWeighting>;

/* Used to keep track of current weights for where to spawn particles */
var transient Array<float>  BucketWeights;

/* Used to keep track of the previous bucket spawned in. Updates weights 1 frame behind. */
var transient int     iPreviousBucketSpawn;

//=============================================================================
//	C++
//=============================================================================
cpptext
{
protected:
	virtual void GetRandomLocationFromShape(INT BucketLocation, FVector& OutLocation);
	virtual INT UpdateBuckets(FBaseParticle& Particle, FParticleEmitterInstance* Owner);

	INT ChooseBucketToSpawnIn(INT NumValidBuckets);

public:
	virtual void Spawn(FParticleEmitterInstance* Owner, INT Offset, FLOAT SpawnTime);
}

//=============================================================================
//	Default properties
//=============================================================================
defaultproperties
{
	bSpawnModule=true
	bUpdateModule=false

	bForceSpawnOnFloor=false
	bUseFlameThrowerTiles=false
	iFloorTileSearchDown=1
	bIgnoreNonAxisAlignedTiles=false
	bUseBucketWeighting=false
	fWeightScaleDown=0.25
	fWeightScaleUp=2.0
	iPreviousBucketSpawn=-1
}
