class X2Effect_ToHitModifier extends X2Effect_Persistent;

struct EffectHitModifier
{
	var class<X2AbilityToHitCalc>   MatchToHit;
	var ShotModifierInfo            Modifier;
	var bool                        bApplyToMelee, bApplyToNonMelee;
	var bool                        bApplyToFlankedTarget, bApplyToNonFlankedTarget;
	var array<name>					AbilitiesAppliedTo;
	var bool                        bApplyIfImpaired;
};

var array<EffectHitModifier>        Modifiers;
var array<X2Condition>              ToHitConditions;
var bool                            bApplyAsTarget;

simulated function AddEffectHitModifier(EAbilityHitResult ModType, int ModAmount, string ModReason, class<X2AbilityToHitCalc> MatchToHit=class'X2AbilityToHitCalc_StandardAim',
										bool Melee=true, bool NonMelee=true, bool Flanked=true, bool NonFlanked=true, optional array<name> AbilityArrayNames, bool ApplyIfImpaired=true)
{
	local EffectHitModifier Modifier;
	Modifier.MatchToHit = MatchToHit;
	Modifier.Modifier.ModType = ModType;
	Modifier.Modifier.Value = ModAmount;
	Modifier.Modifier.Reason = ModReason;
	Modifier.bApplyToMelee = Melee;
	Modifier.bApplyToNonMelee = NonMelee;
	Modifier.bApplyToFlankedTarget = Flanked;
	Modifier.bApplyToNonFlankedTarget = NonFlanked;
	Modifier.bApplyIfImpaired = ApplyIfImpaired;
	
	if (AbilityArrayNames.Length > 0)
	{
		Modifier.AbilitiesAppliedTo = AbilityArrayNames;
	}

	Modifiers.AddItem(Modifier);
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local int i, j;
	local name AvailableCode;

	if (!bApplyAsTarget)
	{
		for (i = 0; i < Modifiers.Length; ++i)
		{
			if (!Modifiers[i].bApplyIfImpaired && Attacker.IsImpaired())
			{
				continue;
			}

			if (Modifiers[i].AbilitiesAppliedTo.Length > 0)
			{
				if (Modifiers[i].AbilitiesAppliedTo.Find(AbilityState.GetMyTemplateName()) == INDEX_NONE)
				{
					continue;
				}
			}
			else
			{
				if (!ClassIsChildOf(ToHitType, Modifiers[i].MatchtoHit))
					continue;
				if (!Modifiers[i].bApplyToMelee && bMelee)
					continue;
				if (!Modifiers[i].bApplyToNonMelee && !bMelee)
					continue;
			}
			if (!Modifiers[i].bApplyToFlankedTarget && bFlanking)
				continue;
			if (!Modifiers[i].bApplyToNonFlankedTarget && !bFlanking)
				continue;

			AvailableCode = 'AA_Success';
			for (j = 0; j < ToHitConditions.Length; ++j)
			{
				AvailableCode = ToHitConditions[j].MeetsCondition(Target);
				if (AvailableCode != 'AA_Success')
					break;
				AvailableCode = ToHitConditions[j].MeetsConditionWithSource(Target, Attacker);
				if (AvailableCode != 'AA_Success')
					break;
			}

			if (AvailableCode == 'AA_Success')
				ShotModifiers.AddItem(Modifiers[i].Modifier);
		}
	}
}

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local int i, j;
	local name AvailableCode;

	if (bApplyAsTarget)
	{
		for (i = 0; i < Modifiers.Length; ++i)
		{
			if (!Modifiers[i].bApplyIfImpaired && Target.IsImpaired())
			{
				continue;
			}

			if (Modifiers[i].AbilitiesAppliedTo.Length > 0)
			{
				if (Modifiers[i].AbilitiesAppliedTo.Find(AbilityState.GetMyTemplateName()) == INDEX_NONE)
				{
					continue;
				}
			}
			else
			{
				if (!ClassIsChildOf(ToHitType, Modifiers[i].MatchtoHit))
					continue;
				if (!Modifiers[i].bApplyToMelee && bMelee)
					continue;
				if (!Modifiers[i].bApplyToNonMelee && !bMelee)
					continue;
			}
			if (!Modifiers[i].bApplyToFlankedTarget && bFlanking)
				continue;
			if (!Modifiers[i].bApplyToNonFlankedTarget && !bFlanking)
				continue;

			AvailableCode = 'AA_Success';
			for (j = 0; j < ToHitConditions.Length; ++j)
			{
				AvailableCode = ToHitConditions[j].MeetsCondition(Target);
				if (AvailableCode != 'AA_Success')
					break;
				AvailableCode = ToHitConditions[j].MeetsConditionWithSource(Target, Attacker);
				if (AvailableCode != 'AA_Success')
					break;
			}

			if (AvailableCode == 'AA_Success')
				ShotModifiers.AddItem(Modifiers[i].Modifier);
		}
	}
}

defaultproperties
{
	bApplyAsTarget=false
}