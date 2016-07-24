//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_AuraSource extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;

	// Register for the required events
	// At the start of every turn, each Aura Source checks what Units it should affect
	EventMgr.RegisterForEvent(EffectObj, 'PlayerTurnBegun', EffectGameState.OnTotalAuraCheck, ELD_OnStateSubmitted);
}

function UpdateBasedOnAuraTarget(XComGameState_Unit SourceUnitState, XComGameState_Unit TargetUnitState, XComGameState_Effect SourceAuraEffectGameState, XComGameState NewGameState)
{
	local XComGameState_BaseObject NewTargetState;
	local EffectAppliedData AuraTargetApplyData;
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityStateObject;
	local X2AbilityTemplate AbilityTemplate;
	local int i;
	local name EffectAttachmentResult;
	local bool bIsAtLeastOneEffectAttached;

	History = `XCOMHISTORY;

	NewTargetState = NewGameState.CreateStateObject(TargetUnitState.Class, TargetUnitState.ObjectID);

	AuraTargetApplyData = SourceAuraEffectGameState.ApplyEffectParameters;
	AuraTargetApplyData.EffectRef.LookupType = TELT_AbilityMultiTargetEffects;
	AuraTargetApplyData.TargetStateObjectRef = TargetUnitState.GetReference();

	AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(SourceAuraEffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	AbilityTemplate = AbilityStateObject.GetMyTemplate();

	bIsAtLeastOneEffectAttached = false;

	for (i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; ++i)
	{
		// Apply each of the aura's effects to the target
		AuraTargetApplyData.EffectRef.TemplateEffectLookupArrayIndex = i;
		EffectAttachmentResult = AbilityTemplate.AbilityMultiTargetEffects[i].ApplyEffect(AuraTargetApplyData, NewTargetState, NewGameState);

		// If it didn't attach, now check to see if the effect is already attached
		bIsAtLeastOneEffectAttached = bIsAtLeastOneEffectAttached || (EffectAttachmentResult == 'AA_Success');
	}

	if (bIsAtLeastOneEffectAttached)
	{
		NewGameState.AddStateObject(NewTargetState);
	}
	else
	{
		NewGameState.PurgeGameStateForObjectID(NewTargetState.ObjectID);
	}
}

private function RemoveAuraTargetEffects(XComGameState_Unit SourceUnitState, XComGameState_Unit TargetUnitState, XComGameState_Effect SourceAuraEffectGameState, XComGameState NewGameState)
{
	local XComGameState_Effect TargetUnitAuraEffect;
	local XComGameState_Ability AuraAbilityStateObject;
	local X2AbilityTemplate AuraAbilityTemplate;
	local XComGameStateHistory History;
	local int i;
	local array<XComGameState_Effect> EffectsToRemove;
	local X2Effect_Persistent PersistentAuraEffect;

	History = `XCOMHISTORY;

	AuraAbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(SourceAuraEffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	AuraAbilityTemplate = AuraAbilityStateObject.GetMyTemplate();

	for (i = 0; i < AuraAbilityTemplate.AbilityMultiTargetEffects.Length; ++i)
	{
		// Loop over all of the aura ability's multi effects and if they are persistent, save it off
		PersistentAuraEffect = X2Effect_Persistent(AuraAbilityTemplate.AbilityMultiTargetEffects[i]);

		if (PersistentAuraEffect != none && TargetUnitState.IsUnitAffectedByEffectName(PersistentAuraEffect.EffectName))
		{
			TargetUnitAuraEffect = TargetUnitState.GetUnitAffectedByEffectState(PersistentAuraEffect.EffectName);

			if (TargetUnitAuraEffect != none && (TargetUnitAuraEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID == SourceUnitState.ObjectID))
			{
				// This effect should be removed if it is affecting this Target Unit and the Source Unit of the
				// effect is the same as the SourceUnitState
				EffectsToRemove.AddItem(TargetUnitAuraEffect);
			}
		}
	}

	for (i = 0; i < EffectsToRemove.Length; ++i)
	{
		// Apply each of the aura's effects to the target
		EffectsToRemove[i].RemoveEffect(NewGameState, NewGameState);
	}
}

defaultproperties
{
}