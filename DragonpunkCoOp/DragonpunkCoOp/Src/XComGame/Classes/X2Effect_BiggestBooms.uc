class X2Effect_BiggestBooms extends X2Effect_Persistent
	config(GameCore);

var config int CRIT_CHANCE_BONUS;
var config int CRIT_DAMAGE_BONUS;

function bool AllowCritOverride() { return true; }

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local X2AbilityToHitCalc_StandardAim StandardHit;

	if (AppliedData.AbilityResultContext.HitResult == eHit_Crit)
	{
		StandardHit = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);
		if (StandardHit != none && StandardHit.bIndirectFire)
		{
			return default.CRIT_DAMAGE_BONUS;
		}
	}
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo BoomInfo;

	if (bIndirectFire)
	{
		BoomInfo.ModType = eHit_Crit;
		BoomInfo.Value = default.CRIT_CHANCE_BONUS;
		BoomInfo.Reason = FriendlyName;
		ShotModifiers.AddItem(BoomInfo);
	}
}