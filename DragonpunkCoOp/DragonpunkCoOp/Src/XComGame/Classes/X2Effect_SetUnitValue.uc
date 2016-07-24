class X2Effect_SetUnitValue extends X2Effect;

var name UnitName;
var float NewValueToSet;
var EUnitValueCleanup CleanupType;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;

	TargetUnitState = XComGameState_Unit(kNewTargetState);
	TargetUnitState.SetUnitFloatValue(UnitName, NewValueToSet, CleanupType);
}