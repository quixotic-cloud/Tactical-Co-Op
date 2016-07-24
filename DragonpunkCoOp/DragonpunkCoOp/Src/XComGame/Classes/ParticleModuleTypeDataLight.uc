//---------------------------------------------------------------------------------
// TypeDataModule for an emitter centered on a light
// Jeremy Shopf
// (c) 2009 Firaxis Games
//---------------------------------------------------------------------------------
// Centers the emitter on the light the emitter is attached to. 
//---------------------------------------------------------------------------------

class ParticleModuleTypeDataLight extends ParticleModuleTypeDataBase
   native(Particle)
   editinlinenew
   collapsecategories
   hidecategories(Object);

enum LightType
{
	eLT_PointLight,
	eLT_SpotLight
};

var() const LightType ParticleLightType;

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

   virtual UBOOL IsSpotLightTypeDataModule() {return ParticleLightType == eLT_SpotLight;}
}

defaultproperties
{
	ParticleLightType=eLT_PointLight
}