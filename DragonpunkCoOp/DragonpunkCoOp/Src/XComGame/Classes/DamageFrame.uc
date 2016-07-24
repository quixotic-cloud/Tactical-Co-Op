class DamageFrame extends Object
	native(Core);

var XComGameState_EnvironmentDamage DamageStateObject;
var bool bActive;
var float LastStartTime;

var native transient const MultiMap_Mirror DamagedActors{TMultiMap<AActor*,AActor*>};
var transient const array<ParticleSystemComponent> SpawnedPSCs;

var const int MaxDesiredParticlesPerEvent;

cpptext
{
	void Start(UXComGameState_EnvironmentDamage* DamageStateObject);
	void Finish();
	void Reset();

	void PropagateToDamageTiles();
}

native function RecordPSC(ParticleSystemComponent PSC);
native function float GetParticleSpawnFactor();

native function bool CanDamage(Actor InActor, optional Actor DamageCauser) const;
native function DealDamage(XComGameState_EnvironmentDamage DamageObject);

defaultproperties
{

	bActive=false;
	MaxDesiredParticlesPerEvent=16
	LastStartTime = 0.0f
}
