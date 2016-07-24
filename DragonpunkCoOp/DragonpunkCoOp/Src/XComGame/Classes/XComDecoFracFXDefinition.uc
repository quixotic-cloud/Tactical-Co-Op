//---------------------------------------------------------------------------------------
//  FILE:    XComDecoFracFXDefinition.uc
//  AUTHOR:  Jeremy Shopf 3/25/14
//  PURPOSE: This object contains a set of definitions that maps damage types to 
//				deco-specific effects spawned from XComTileFracLevelActors
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComDecoFracFXDefinition extends Object
	native(Level);

struct native PerDamageFX
{
	/**Select the damage type that the specified particle systems will be associated with */
	var() name EffectDamageTypeName<DynamicList = "DamageTypeList">;
	var() editinline EffectCue  EffectTemplate;
	/** Random dice roll is performed for each possible spawn point and compared against this value. */
	var() float                 Probability;

	structdefaultproperties
	{	
		EffectDamageTypeName = "Explosion"
		Probability=1.0;
	}
};

struct native DecoFXType
{
	var() array<PerDamageFX> DamageFX;
};

var() array<DecoFXType> DecoFX;

simulated event ParticleSystemComponent SpawnEffect( XComTileFracLevelActor FracActor, EffectCue Cue, Vector EffectLocation, Rotator EffectRotation, const out array<ParticleSysParam> InstanceParameters )
{
	return class'EffectCue'.static.SpawnEffectWithInstanceParams( `LEVEL.LevelVolume.DecoEmitterPool, Cue, EffectLocation, EffectRotation, InstanceParameters );
}

cpptext
{
public:
	virtual void GetDynamicListValues(const FString& ListName, TArray<FString>& Values);
	void CreateDecoEffects(AXComTileFracLevelActor* FracLevelActor, const TArray<INT>& DecoData, const UXComGameState_EnvironmentDamage &Dmg);
}
