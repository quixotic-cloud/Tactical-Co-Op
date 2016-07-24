class X2Effect_Stasis extends X2Effect_Persistent;

var localized string StasisFlyover;
var name StunStartAnim;
var bool bSkipFlyover;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	TargetUnit.bInStasis = true;
	TargetUnit.ActionPoints.Length = 0;
	TargetUnit.ReserveActionPoints.Length = 0;

	`XEVENTMGR.TriggerEvent('AffectedByStasis', kNewTargetState, kNewTargetState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		`assert(TargetUnit != none);
		TargetUnit = XComGameState_Unit(NewGameState.CreateStateObject(TargetUnit.Class, TargetUnit.ObjectID));
		NewGameState.AddStateObject(TargetUnit);
	}
	
	TargetUnit.bInStasis = false;
}

function UnitEndedTacticalPlay(XComGameState_Effect EffectState, XComGameState_Unit UnitState)
{
	UnitState.bInStasis = false;
}

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType) 
{
	return true;
}

function bool CanAbilityHitUnit(name AbilityName) 
{
	return false;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	// Empty because we will be adding all this at the end with ModifyTracksVisualization
}

simulated function ModifyTracksVisualization(XComGameState VisualizeGameState, out VisualizationTrack ModifyTrack, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_PlayAnimation PlayAnimation;

	if (EffectApplyResult == 'AA_Success' && ModifyTrack.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		if (!bSkipFlyover)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(ModifyTrack, VisualizeGameState.GetContext()));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.StasisFlyover, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Stunned, 1.0, true);
		}

		if( XComGameState_Unit(ModifyTrack.StateObject_NewState).IsTurret() )
		{
			class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTrack(ModifyTrack, VisualizeGameState.GetContext());
		}
		else
		{
			// Not a turret
			// Play the start stun animation
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(ModifyTrack, VisualizeGameState.GetContext()));
			PlayAnimation.Params.AnimName = StunStartAnim;
		}
		class'X2StatusEffects'.static.UpdateUnitFlag(ModifyTrack, VisualizeGameState.GetContext());

		super.AddX2ActionsForVisualization(VisualizeGameState, ModifyTrack, EffectApplyResult);
	}
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlayAnimation PlayAnimation;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, RemovedEffect);

	if (XComGameState_Unit(BuildTrack.StateObject_NewState) != none)
	{
		if( XComGameState_Unit(BuildTrack.StateObject_NewState).IsTurret() )
		{
			class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
		}
		else
		{
			// The unit is not a turret
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
			PlayAnimation.Params.AnimName = 'HL_StunnedStop';
		}
		class'X2StatusEffects'.static.UpdateUnitFlag(BuildTrack, VisualizeGameState.GetContext());
	}
}

DefaultProperties
{
	EffectName = "Stasis"
	DuplicateResponse = eDupe_Refresh
	CustomIdleOverrideAnim="HL_StunnedIdle"
	StunStartAnim="HL_StunnedStart"
	ModifyTracksFn=ModifyTracksVisualization
	EffectHierarchyValue=950
}