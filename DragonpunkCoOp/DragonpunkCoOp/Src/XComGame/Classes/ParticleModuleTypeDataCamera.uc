//---------------------------------------------------------------------------------
// TypeDataModule for an emitter centered on the camera
// Jeremy Shopf
// (c) 2009 Firaxis Games
//---------------------------------------------------------------------------------
// Centers the emitter near the XComCamera. 
//---------------------------------------------------------------------------------

class ParticleModuleTypeDataCamera extends ParticleModuleTypeDataBase
   native(Particle)
   editinlinenew
   collapsecategories
   hidecategories(Object);

var Camera m_kCameraObject;
/** Offsets the emitter by the supplied amount along the camera vector */
var() float CameraVectorOffset;
/** Influences how far along the velocity vector to center the emitter	*/
var() float  VelocityCompensation;

cpptext
{
   /**
    *   Create the custom ParticleEmitterInstance.
    *
    *   @param  InEmitterParent           The UParticleEmitter that holds this TypeData module.
    *   @param  InComponent               The UParticleSystemComponent that 'owns' the emitter instance being created.
    *   @return FParticleEmitterInstance* The create emitter instance.
    */
   virtual FParticleEmitterInstance*   CreateInstance(UParticleEmitter* InEmitterParent, UParticleSystemComponent* InComponent);
}

defaultproperties
{
	VelocityCompensation = 0.0;
}