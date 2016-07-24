//---------------------------------------------------------------------------------
// Particle Size By Distance from Emitter
// Dominic Cerquetti
// (c) 2008 Firaxis Games
//---------------------------------------------------------------------------------
// Vary a particle's size based on distance from the emitter
// Uses a distribution curve to multiply the scale of a particle
// from 0.0 to 1.0 based on the distance.
//
// NOTE: Unlike most particle systems TIME is not a factor here, only distance
//---------------------------------------------------------------------------------

class ParticleModuleSizeByDistance extends ParticleModuleSizeBase
		native(Particle)
		editinlinenew
		hidecategories(Object);

var(Size) rawdistributionfloat SizeMultiplierVsDistance;
var(Size) rawdistributionfloat MaxDistanceVariable;
var(Size) float MaxDistance;

cpptext
{
	virtual void PostLoad();
	virtual void Render3DPreview(FParticleEmitterInstance* Owner, const FSceneView* View,FPrimitiveDrawInterface* PDI);
	virtual void Update(FParticleEmitterInstance* Owner, INT Offset, FLOAT DeltaTime);
	virtual void SetToSensibleDefaults(UParticleEmitter* Owner);
}

defaultproperties
{
	bSpawnModule=false // call Spawn()
	bUpdateModule=true // call Update()

	MaxDistance = 40.0f
	bSupported3DDrawMode=true // jboswell: need this to draw the debug sphere
}
