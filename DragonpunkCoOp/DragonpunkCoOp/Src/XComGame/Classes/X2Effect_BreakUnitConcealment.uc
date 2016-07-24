class X2Effect_BreakUnitConcealment extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventManager;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		EventManager = `XEVENTMGR;
		EventManager.TriggerEvent('EffectBreakUnitConcealment', UnitState, UnitState, NewGameState);
	}
}