class X2Effect_BleedingOut extends X2Effect_ModifyStats;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local int SightValue;
	local StatChange SightChange;

	UnitState = XComGameState_Unit(kNewTargetState);
	SightValue = UnitState.GetCurrentStat(eStat_SightRadius) - class'X2StatusEffects'.default.BLEEDOUT_SIGHT_RADIUS;
	SightChange.StatType = eStat_SightRadius;
	SightChange.StatAmount = -SightValue;
	NewEffectState.StatChanges.AddItem(SightChange);

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}
