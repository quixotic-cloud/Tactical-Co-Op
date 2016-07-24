class X2Effect_Executed extends X2Effect;

var localized string UnitExecutedFlyover;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local int KillAmount;
	local bool bForceBleedOut;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	// If a unit is bleeding out, kill it
	// If a unit is alive AND cannot become bleeding out, kill it
	// if a unit is alive AND can become bleeding out, set it to bleeding out
	TargetUnit = XComGameState_Unit(kNewTargetState);
	KillAmount = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);

	if( !TargetUnit.IsBleedingOut() && TargetUnit.CanBleedOut() )
	{
		bForceBleedOut = true;
	}

	TargetUnit.TakeEffectDamage(self, KillAmount, 0, 0, ApplyEffectParameters, NewGameState, bForceBleedOut);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	if (EffectApplyResult != 'AA_Success')
		return;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.UnitExecutedFlyover, '', eColor_Bad); // TODO: Check with audio if they want a special clip here
}