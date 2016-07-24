class X2Effect_EnableGlobalAbility extends X2Effect;

var name GlobalAbility;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	class'XComGameState_BattleData'.static.SetGlobalAbilityEnabled(GlobalAbility, true, NewGameState);
}