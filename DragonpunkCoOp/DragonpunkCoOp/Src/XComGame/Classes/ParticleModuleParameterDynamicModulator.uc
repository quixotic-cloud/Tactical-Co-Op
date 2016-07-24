//---------------------------------------------------------------------------------------
//  FILE:    ParticleModuleParameterDynamicModulator.uc
//  AUTHOR:  Ryan McFall  --  06/11/2010
//  PURPOSE: This particle module allows users to modulate dynamic parameters via
//           distribution float parameters. For instance, the user may have a float
//           parameter that represents distance to a target. This module could change
//           a dynamic parameter based on that distance parameter
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class ParticleModuleParameterDynamicModulator extends ParticleModuleParameterModulator
		native(Particle)
		editinlinenew
		hidecategories(Object);

var() rawdistributionfloat ModulationParameter;
var() int DynamicParameterSet;
var() int DynamicParameterIndex;

cpptext
{
	// ParticleModuleParameterModulator interface
	virtual void Modulate( FParticleEmitterInstance* Owner, FVector4& outValue, FVector4& outValue1 );
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
}

defaultproperties
{
	Begin Object Class=DistributionFloatConstant Name=DistributionModulationParameter
	Constant=1.0
	End Object
	ModulationParameter=(Distribution=DistributionModulationParameter)
	DynamicParameterSet = 0;
	DynamicParameterIndex = 0;
}
