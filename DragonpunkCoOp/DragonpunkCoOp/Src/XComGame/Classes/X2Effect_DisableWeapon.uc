class X2Effect_DisableWeapon extends X2Effect
	config(GameCore);

var localized string DisabledWeapon;
var localized string FailedDisable;

var config array<name> HideVisualizationOfResults;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item WeaponState, NewWeaponState;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit != none)
	{
		WeaponState = TargetUnit.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState);
		if (WeaponState != none)
		{
			NewWeaponState = XComGameState_Item(NewGameState.CreateStateObject(WeaponState.Class, WeaponState.ObjectID));
			NewWeaponState.Ammo = 0;
			NewGameState.AddStateObject(NewWeaponState);
		}
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	if( XComGameState_Unit(BuildTrack.StateObject_NewState) != none )
	{
		if (default.HideVisualizationOfResults.Find(EffectApplyResult) != INDEX_NONE)
		{
			return;
		}

		// Must be a unit in order to have this occur
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));

		if (EffectApplyResult == 'AA_Success')
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.DisabledWeapon, '', eColor_Bad);
		}
		else
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.FailedDisable, '', eColor_Good);
		}
	}
}