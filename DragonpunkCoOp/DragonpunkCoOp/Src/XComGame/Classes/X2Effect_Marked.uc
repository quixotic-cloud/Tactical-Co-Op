//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_Marked extends X2Effect_Persistent
	config(GameCore);

var config int ACCURACY_CHANCE_BONUS;
var config int CRIT_CHANCE_BONUS;
var config int CRIT_DAMAGE_BONUS;

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, 
										const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect)
{
	// This unit takes extra crit damage
	if (AppliedData.AbilityResultContext.HitResult == eHit_Crit)
	{
		return default.CRIT_DAMAGE_BONUS;
	}
}

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo AccuracyInfo, CritInfo;

	AccuracyInfo.ModType = eHit_Success;
	AccuracyInfo.Value = default.ACCURACY_CHANCE_BONUS;
	AccuracyInfo.Reason = FriendlyName;
	ShotModifiers.AddItem(AccuracyInfo);

	CritInfo.ModType = eHit_Crit;
	CritInfo.Value = default.CRIT_CHANCE_BONUS;
	CritInfo.Reason = FriendlyName;
	ShotModifiers.AddItem(CritInfo);
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const int TickIndex, XComGameState_Effect EffectState)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, FriendlyName, '', eColor_Bad);
}