// Contains all data related to pawn reactions to damage types
// You will have one of these classes for each unique type of unit, but they can be shared
// e.g. you'll have a "human" damage type container and an "alien" damage type container / etc
//
// To create new ones of these in the editor:
class DamageTypeHitEffectContainer extends Object native(Core);

var() array<MaterialInterface> DecalMaterials;

// Map a particular damage type to a particular effect class
// e.g. DamageType "Bullet" -> red blood splatter + squishy sound.
struct native DamageEffectMap
{	
	var() name DamageTypeName<DynamicList = "DamageTypeList">;
	var() EAbilityHitResult HitResult<ToolTip='additional criterion for selecting this projectile based on hit result'>;
	var() XComPawnHitEffect HitEffect<ToolTip="effect used for each individual projectile">;
	var() XComPawnHitEffect MetaHitEffect<ToolTip="effect used just once as an overall effect">;
};

var() array<DamageEffectMap> DamageTypeToHitEffectMap;
var() array<DamageEffectMap> DamageTypeToRuptureHitEffectMap;

var(Death) ParticleSystem DeathEffect<ToolTip="Effect to play, in addition to above FX, when unit dies. e.g. an explosion for the tank.">;
var(Death) SoundCue DeathSound<ToolTip="Sound to play, in addition to SoundCollection death sound.">;

cpptext
{
public:
	virtual void GetDynamicListValues(const FString& ListName, TArray<FString>& Values);
}

simulated function XComPawnHitEffect GetHitEffectsTemplateForDamageType(name DamageTypeName, EAbilityHitResult Result)
{
	local int FoundIndex;

	FoundIndex = GetIndexFromDamageTypeName( DamageTypeName, Result );

	if (FoundIndex < DamageTypeToHitEffectMap.Length)
	{
		return DamageTypeToHitEffectMap[FoundIndex].HitEffect;
	}

	//the likely cause to not find the hit effect is because it isn't a DefaultProjectile, so I am skipping that string compare here to check if it's a DefaultProjectile Chang You Wong 2015-7-1
	FoundIndex = GetIndexFromDamageTypeName( 'DefaultProjectile', Result );

	if (FoundIndex < DamageTypeToHitEffectMap.Length)
	{
		return DamageTypeToHitEffectMap[FoundIndex].HitEffect;
	}

	if(DamageTypeToHitEffectMap.Length > 0)
	{
		return DamageTypeToHitEffectMap[0].HitEffect;
	}

	return none;
}

simulated function XComPawnHitEffect GetMetaHitEffectTemplateForDamageType(name DamageTypeName, EAbilityHitResult Result)
{
	local int FoundIndex;

	FoundIndex = GetIndexFromDamageTypeName( DamageTypeName, Result );

	if(FoundIndex < DamageTypeToHitEffectMap.Length)
	{
		return DamageTypeToHitEffectMap[FoundIndex].MetaHitEffect;
	}

	//the likely cause to not find the hit effect is because it isn't a DefaultProjectile, so I am skipping that string compare here to check if it's a DefaultProjectile Chang You Wong 2015-7-1
	FoundIndex = GetIndexFromDamageTypeName( 'DefaultProjectile', Result );

	if(FoundIndex < DamageTypeToHitEffectMap.Length)
	{
		return DamageTypeToHitEffectMap[FoundIndex].MetaHitEffect;
	}

	if(DamageTypeToHitEffectMap.Length > 0)
	{
		return DamageTypeToHitEffectMap[0].MetaHitEffect;
	}

	return none;
}

simulated private function int GetIndexFromDamageTypeName(name DamageTypeName, EAbilityHitResult Result)
{
	local int FoundIndex;
	local int FallbackIndex;
	FallbackIndex = DamageTypeToHitEffectMap.Length;

	for(FoundIndex = 0; FoundIndex < DamageTypeToHitEffectMap.Length; ++FoundIndex)
	{
		if(DamageTypeToHitEffectMap[FoundIndex].DamageTypeName == DamageTypeName)
		{
			if( DamageTypeToHitEffectMap[FoundIndex].HitResult == Result )
			{
				break;
			}
			else if( DamageTypeToHitEffectMap[FoundIndex].HitResult == eHit_Success )
			{
				FallbackIndex = FoundIndex;
			}
		}
	}

	if( FoundIndex < DamageTypeToHitEffectMap.Length )
	{
		return FoundIndex;
	}
	else if( FallbackIndex < DamageTypeToHitEffectMap.Length )
	{
		return FallbackIndex;
	}

	return DamageTypeToHitEffectMap.Length;
}

simulated function XComPawnHitEffect GetRuptureHitEffectsTemplateForDamageType(name DamageTypeName)
{
	local int FoundIndex;

	FoundIndex = GetRuptureIndexFromDamageTypeName(DamageTypeName);

	if (FoundIndex < DamageTypeToRuptureHitEffectMap.Length)
	{
		return DamageTypeToRuptureHitEffectMap[FoundIndex].HitEffect;
	}

	if(DamageTypeToRuptureHitEffectMap.Length > 0)
	{
		return DamageTypeToRuptureHitEffectMap[0].HitEffect;
	}

	return none;
}

simulated function XComPawnHitEffect GetMetaRuptureHitEffectTemplateForDamageType(name DamageTypeName)
{
	local int FoundIndex;

	FoundIndex = GetRuptureIndexFromDamageTypeName(DamageTypeName);

	if (FoundIndex < DamageTypeToRuptureHitEffectMap.Length)
	{
		return DamageTypeToRuptureHitEffectMap[FoundIndex].MetaHitEffect;
	}

	if (DamageTypeToRuptureHitEffectMap.Length > 0)
	{
		return DamageTypeToRuptureHitEffectMap[0].MetaHitEffect;
	}

	return none;
}

simulated private function int GetRuptureIndexFromDamageTypeName(name DamageTypeName)
{
	local int FoundIndex;

	for (FoundIndex = 0; FoundIndex < DamageTypeToRuptureHitEffectMap.Length; ++FoundIndex)
	{
		if(DamageTypeToRuptureHitEffectMap[FoundIndex].DamageTypeName == DamageTypeName)
		{
			break;
		}
	}

	return FoundIndex;
}

simulated function MaterialInterface GetDecalMaterial()
{
	return DecalMaterials[Rand(DecalMaterials.Length)];
}

DefaultProperties
{	
}
