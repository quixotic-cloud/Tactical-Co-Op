class X2Effect_IncrementUnitValue extends X2Effect_SetUnitValue;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;
	local UnitValue UnitVal;
	
	TargetUnitState = XComGameState_Unit(kNewTargetState);
	TargetUnitState.GetUnitValue(UnitName, UnitVal);	
	TargetUnitState.SetUnitFloatValue(UnitName, UnitVal.fValue + NewValueToSet, CleanupType);
}