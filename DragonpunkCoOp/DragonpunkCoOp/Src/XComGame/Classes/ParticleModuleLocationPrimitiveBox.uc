//=============================================================================
// ParticleModuleLocationPrimitiveBox
// Location primitive spawning within a 3D Box.
// Copyright 1998-2009 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class ParticleModuleLocationPrimitiveBox extends ParticleModuleLocationPrimitiveBase
	native(Particle)
	editinlinenew
	hidecategories(Object);

/** The radius of the sphere. Retrieved using EmitterTime. */
var(Location) rawdistributionfloat	SizeX;
var(Location) rawdistributionfloat	SizeY;
var(Location) rawdistributionfloat	SizeZ;

/** The amount to pull in from the ends of the box. If larger than size, all particles will be clamped to the center. */
var(Location) rawdistributionfloat	MarginX;
var(Location) rawdistributionfloat	MarginY;
var(Location) rawdistributionfloat	MarginZ;

cpptext
{
	virtual void	Spawn(FParticleEmitterInstance* Owner, INT Offset, FLOAT SpawnTime);
	virtual void	Render3DPreview(FParticleEmitterInstance* Owner, const FSceneView* View,FPrimitiveDrawInterface* PDI);
}

defaultproperties
{
	Begin Object Class=DistributionFloatConstant Name=DistributionSizeX
		Constant=50.0
	End Object
	SizeX=(Distribution=DistributionSizeX)
	
	Begin Object Class=DistributionFloatConstant Name=DistributionSizeY
		Constant=50.0
	End Object
	SizeY=(Distribution=DistributionSizeY)
	
	Begin Object Class=DistributionFloatConstant Name=DistributionSizeZ
		Constant=50.0
	End Object
	SizeZ=(Distribution=DistributionSizeZ)


	Begin Object Class=DistributionFloatConstant Name=DistributionMarginX
		Constant=0.0
	End Object
	MarginX=(Distribution=DistributionMarginX)

	Begin Object Class=DistributionFloatConstant Name=DistributionMarginY
		Constant=0.0
	End Object
	MarginY=(Distribution=DistributionMarginY)

	Begin Object Class=DistributionFloatConstant Name=DistributionMarginZ
		Constant=0.0
	End Object
	MarginZ=(Distribution=DistributionMarginZ)

		
	bSupported3DDrawMode=true
}
