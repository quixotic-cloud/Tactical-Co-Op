//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    ParticleModuleLocationCamera.uc
//  AUTHOR:  Jeremy Shopf  --  04/13/2009
//  PURPOSE: XCom specific module that places the emitter
//				at the player controller camera
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class ParticleModuleLocationCamera extends ParticleModuleLocationBase
	native(Particle)
	editinlinenew
	hidecategories(Object);

/** 
 *	The location the particle should be emitted, relative to the emitter.
 *	Retrieved using the EmitterTime at the spawn of the particle.
 */
var Vector m_kOldLocation;
var() float CameraVectorOffset;
var() float VelocityCompensation;
cpptext
{
	virtual void	Spawn(FParticleEmitterInstance* Owner, INT Offset, FLOAT SpawnTime);
	virtual void	Render3DPreview(FParticleEmitterInstance* Owner, const FSceneView* View,FPrimitiveDrawInterface* PDI);
}

defaultproperties
{
	bSpawnModule=true
	VelocityCompensation=0.0
	CameraVectorOffset=0.0

}

