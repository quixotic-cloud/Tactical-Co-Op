// ---------------------------------------------------
// Effect Cue
// ---------------------------------------------------
// Works kind of like a sound cue
//
// It contains one or more particle system to choose
// from at runtime and special information about them
//
// (c) 2008 Firaxis Games
// Author: Dominic Cerquetti (dcerquetti@firaxis.com)
// ---------------------------------------------------

class EffectCue extends Object
	native(Particle)
	editinlinenew
	collapsecategories
	hidecategories(Object);
	
struct native ParticleSystemEntry
{
	var() ParticleSystem ParticleSystem;
	var() float Weight;
	
	structdefaultproperties
	{
		Weight = 1.0f;
	}
};
	
var() instanced array<ParticleSystemEntry> ParticleSystems;

// returns -1 if nothing in array
native function int PickParticleSystemIndexToUse();

function ParticleSystem PickParticleSystemToUse()
{
	local int i;
	i = PickParticleSystemIndexToUse();
	if (i != -1)
		return ParticleSystems[i].ParticleSystem;

	return none;
}

function ParticleSystemComponent PlayOnActor(Actor A, 	
											 optional SkeletalMeshComponent AttachMesh = none, 
											 optional SkeletalMeshSocket AttachSocket = none,
											 optional float WarmupTime = -1.0,
											 optional EmitterInstanceParameterSet ParameterSet = none)
{
	local int i;
	local ParticleSystem PSTemplate;
	local ParticleSystemComponent PSC;	

	if (A == none)
		return none;

	i = PickParticleSystemIndexToUse();
	if (i != -1)
		PSTemplate = ParticleSystems[i].ParticleSystem;
		
	if (PSTemplate == none)
		return none;

	if( WarmupTime > -1.0 )
	{
		PSTemplate.WarmupTime = WarmupTime;
	}

	PSC = new(A) class'ParticleSystemComponent';

	if( ParameterSet != none )
	{
		PSC.InstanceParameters = ParameterSet.InstanceParameters;
	}

	if( AttachMesh != none && AttachSocket != none )
	{
		AttachMesh.AttachComponentToSocket(PSC, AttachSocket.SocketName);
	}
	else
	{
		A.AttachComponent(PSC);		
	}

	PSC.bAutoActivate = true;
	PSC.SetTemplate(PSTemplate);

	return PSC;
}

static function ParticleSystemComponent SpawnEffect( EmitterPool kEmitterPool, EffectCue kCue, vector kLocation, rotator kRotation )
{
	local ParticleSystem kParticleSystem;

	if (kCue == none)
	{
		return none;
	}

	kParticleSystem = kCue.PickParticleSystemToUse();
	if (kParticleSystem == none)
	{
		return none;
	}

	return kEmitterPool.SpawnEmitter( kParticleSystem, kLocation, kRotation );
}

static function ParticleSystemComponent SpawnEffectWithInstanceParams( EmitterPool kEmitterPool, 
																	   EffectCue kCue, 
																	   vector kLocation, 
																	   rotator kRotation, 
																	   const out array<ParticleSysParam> InstanceParameters,
																	   optional float WarmupTime = -1.0,
																	   optional vector Scale )
{
	local ParticleSystem kParticleSystem;

	if (kCue == none)
	{
		return none;
	}

	kParticleSystem = kCue.PickParticleSystemToUse();
	if (kParticleSystem == none)
	{
		return none;
	}

	return kEmitterPool.SpawnEmitter( kParticleSystem, kLocation, kRotation, ,,, false, InstanceParameters, WarmupTime, Scale );
}

defaultproperties
{
}