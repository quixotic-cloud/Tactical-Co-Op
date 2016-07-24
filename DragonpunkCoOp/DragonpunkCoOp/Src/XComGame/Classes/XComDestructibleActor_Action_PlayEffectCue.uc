class XComDestructibleActor_Action_PlayEffectCue extends XComDestructibleActor_Action
	native(Destruction);

var(XComDestructibleActor_Action) instanced EffectCue EffectCue;
var(XComDestructibleActor_Action) EmitterInstanceParameterSet InstanceParameters;
var(XComDestructibleActor_Action) Rotator RotationAdjustment;
var(XComDestructibleActor_Action) Vector PositionAdjustment;
var(XComDestructibleActor_Action) Vector ScaleAdjustment;
/** This is here just to allow for flexible experimentation. Take out later if not needed. See Steve Jameson */
var(XComDestructibleActor_Action) XComDamageFXParams DamageParams;

var(XComDestructibleActor_Action) bool bUseMaterialInheritance;
var(XComDestructibleActor_Action) bool bStatePersistentEffect;

var transient array<ParticleSystemComponent> PSCs;

native function Activate();
native function Deactivate();
native function Load(float InTimeInState);
native function bool Validate();

simulated event ParticleSystemComponent SpawnEffect( Actor Actor, EffectCue Cue, Vector EffectLocation, Rotator EffectRotation, const out array<ParticleSysParam> InInstanceParameters, float InWarmupTime, vector InScale  )
{
	return class'EffectCue'.static.SpawnEffectWithInstanceParams( Actor.WorldInfo.MyEmitterPool, Cue, EffectLocation, EffectRotation, InInstanceParameters,InWarmupTime, InScale );
}

cpptext
{
	void SpawnEffects(float WarmupTime, UXComWorldData* WorldData );
}

defaultproperties
{
	ScaleAdjustment=(X=1,Y=1,Z=1)
	DamageParams=XComDamageFXParams'FX_Destruction_Fracture_Data.DamageFXParams_Default' // I know this is bad but 90% of playeffectcue will use this one so it's going to be referenced anyway
	bUseMaterialInheritance=true
	bStatePersistentEffect=false
}

