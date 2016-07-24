class X2Effect_DelayedAbilityActivation extends X2Effect_Persistent;

var name TriggerEventName;      // Used to identify the event that this effect will trigger

static private function TriggerAssociatedEvent(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit SourceUnit;
	local X2Effect_DelayedAbilityActivation DelayedEffect;

	DelayedEffect = X2Effect_DelayedAbilityActivation(PersistentEffect);
	if (DelayedEffect.TriggerEventName == '')
	{
		`RedScreen("X2Effect_DelayedAbilityActivation - TriggerEventName must be set:"@DelayedEffect.TriggerEventName);
	}

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`XEVENTMGR.TriggerEvent(DelayedEffect.TriggerEventName, SourceUnit, SourceUnit);
}

defaultproperties
{
	EffectRemovedFn = TriggerAssociatedEvent
}