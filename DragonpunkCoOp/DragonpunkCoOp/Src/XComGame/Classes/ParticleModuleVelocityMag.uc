//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComParticleModuleVelocityMagn.uc
//  AUTHOR:  Jeremy Shopf -- 05/21/09
//  PURPOSE: Normalizes the velocity and set the magnitude to the specified amount
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class ParticleModuleVelocityMag extends ParticleModuleVelocityBase
	native(Particle)
	editinlinenew
	hidecategories(Object);

/** 
 *	The velocity magnitude to override to
 */
var(Velocity) rawdistributionfloat	StartVelocityMag;

cpptext
{
	virtual void	Spawn(FParticleEmitterInstance* Owner, INT Offset, FLOAT SpawnTime);
}

defaultproperties
{
	bSpawnModule=true

	Begin Object Class=DistributionFloatUniform Name=DistributionStartVelocityMag
	End Object
	StartVelocityMag=(Distribution=DistributionStartVelocityMag)

}
