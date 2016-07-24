//-----------------------------------------------------------
//
//-----------------------------------------------------------
class GenericHitEffect extends XComEmitter;

var() SoundCue HitSound;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	PlaySound(HitSound);
}

DefaultProperties
{
	HitSound=SoundCue'SoundEnvironment.MachineGunDirtCue'

	Begin Object Name=ParticleSystemComponent0
		bAcceptsLights=false
		SecondsBeforeInactive=0
		bOverrideLODMethod=true
		LODMethod=PARTICLESYSTEMLODMETHOD_DirectSet
		// Template=ParticleSystem'WeaponFX.GenericHit01'
		bAutoActivate=True
	End Object

	LifeSpan=7.0 // TODO: TOTAL HACK.  Get lifespan from particle system if possible.

	bDestroyOnSystemFinish=true
	bNoDelete=false
	bNetTemporary=true
}
