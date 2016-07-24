class X2Effect_TriggerEvent extends X2Effect;

var name TriggerEventName;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SourceUnit, TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	if (SourceUnit != none && TargetUnit != none && TriggerEventName != '')
	{
		//  trigger the specified event using the target as the "data" parameter and the source as the "source" parameter
		`XEVENTMGR.TriggerEvent(TriggerEventName, TargetUnit, SourceUnit, NewGameState);
	}
}