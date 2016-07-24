class X2Effect_SoulSteal extends X2Effect;

var name UnitValueToRead;
var localized string HealedMessage;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local UnitValue ValueToRead;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState.GetUnitValue(UnitValueToRead, ValueToRead))
	{
		UnitState.ModifyCurrentStat(eStat_HP, ValueToRead.fValue);
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Unit OldUnitState, NewUnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int Healed;
	local string Msg;

	if (EffectApplyResult == 'AA_Success')
	{
		OldUnitState = XComGameState_Unit(BuildTrack.StateObject_OldState);
		NewUnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
		if (OldUnitState != none && NewUnitState != none)
		{
			Healed = NewUnitState.GetCurrentStat(eStat_HP) - OldUnitState.GetCurrentStat(eStat_HP);
			if (Healed > 0)
			{
				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
				Msg = Repl(default.HealedMessage, "<Heal/>", Healed);
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Msg, '', eColor_Good);
			}
		}
	}
}