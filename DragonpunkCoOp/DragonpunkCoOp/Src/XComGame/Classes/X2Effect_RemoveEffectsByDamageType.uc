class X2Effect_RemoveEffectsByDamageType extends X2Effect_RemoveEffects;

var array<name> DamageTypesToRemove;

simulated function bool ShouldRemoveEffect(XComGameState_Effect EffectState, X2Effect_Persistent PersistentEffect)
{
	local name DamageType;

	foreach PersistentEffect.DamageTypes(DamageType)
	{
		if (DamageTypesToRemove.Find(DamageType) != INDEX_NONE)
			return true;
	}
	return super.ShouldRemoveEffect(EffectState, PersistentEffect);
}

//Fail to apply if the unit isn't actually affected by any of the types we remove.
function name DamageTypesRelevant(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local name TypeToRemove;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState == None)
		return 'AA_NotAUnit';

	foreach DamageTypesToRemove(TypeToRemove)
	{
		if (UnitState.IsUnitAffectedByDamageType(TypeToRemove))
		{
			//Unit is affected by at least one type we remove - go ahead
			return 'AA_Success';
		}
	}

	foreach EffectNamesToRemove(TypeToRemove)
	{
		if (UnitState.IsUnitAffectedByEffectName(TypeToRemove))
		{
			return 'AA_Success';
		}
	}

	//The unit isn't affected by anything we heal. Don't apply.
	return 'AA_UnitIsNotInjured';
}

defaultproperties
{
	ApplyChanceFn=DamageTypesRelevant
}