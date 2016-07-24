/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class ParticleModuleLocationRandomLine extends ParticleModuleLocationRandomTemplate
	native(Particle)
	editinlinenew
	hidecategories(Object);

//=============================================================================
//	Properties
//=============================================================================

var() rawdistributionfloat  LengthDistribution;

/* A new bucket will be spawned for each fDistancePerBucket that the length of the segment is */
var() rawdistributionfloat  DistancePerBucketDistribution;

/* Holds the current length of the segment being used. */
var transient float   fCurrentSegmentLength;

/* Used to keep track of current weights for where to spawn particles */
var transient Array<float>  BucketSizes;

//=============================================================================
//	C++
//=============================================================================
cpptext
{
protected:
	virtual void GetRandomLocationFromShape(INT BucketLocation, FVector& OutLocation);
	virtual INT UpdateBuckets(FBaseParticle& Particle, FParticleEmitterInstance* Owner);

public:
	
}

//=============================================================================
//	Default properties
//=============================================================================
defaultproperties
{
	Begin Object Class=DistributionFloatConstantCurve Name=DistributionLengthDistribution
	End Object
	LengthDistribution=(Distribution=DistributionLengthDistribution)

	Begin Object Class=DistributionFloatConstantCurve Name=DistributionPerBucketDistribution
	End Object
	DistancePerBucketDistribution=(Distribution=DistributionPerBucketDistribution)
}
