class X2Effect_RemoveEffects extends X2Effect;

var array<name> EffectNamesToRemove;
var bool        bCleanse;               //  Indicates the effect was removed "safely" for gameplay purposes so any bad "wearing off" effects should not trigger
										//  e.g. Bleeding Out normally kills the soldier it is removed from, but if cleansed, it won't.
var bool        bCheckSource;           //  Match the source of each effect to the target of this one, rather than the target.

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent PersistentEffect;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if ((bCheckSource && (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)) ||
			(!bCheckSource && (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)))
		{
			PersistentEffect = EffectState.GetX2Effect();
			if (ShouldRemoveEffect(EffectState, PersistentEffect))
			{
				EffectState.RemoveEffect(NewGameState, NewGameState, bCleanse);
			}
		}
	}
}

simulated function bool ShouldRemoveEffect(XComGameState_Effect EffectState, X2Effect_Persistent PersistentEffect)
{
	return EffectNamesToRemove.Find(PersistentEffect.EffectName) != INDEX_NONE;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Effect;

	if (EffectApplyResult != 'AA_Success')
		return;

	//  We are assuming that any removed effects were cleansed by this RemoveEffects. If this turns out to not be a good assumption, something will have to change.
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.bRemoved)
		{
			if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == BuildTrack.StateObject_NewState.ObjectID)
			{
				Effect = EffectState.GetX2Effect();
				if (Effect.CleansedVisualizationFn != none && bCleanse)
				{
					Effect.CleansedVisualizationFn(VisualizeGameState, BuildTrack, EffectApplyResult);
				}
				else
				{
					Effect.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, EffectState);
				}
			}
			else if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == BuildTrack.StateObject_NewState.ObjectID)
			{
				Effect = EffectState.GetX2Effect();
				Effect.AddX2ActionsForVisualization_RemovedSource(VisualizeGameState, BuildTrack, EffectApplyResult, EffectState);
			}
		}
	}
}

DefaultProperties
{
	bCleanse = true
}