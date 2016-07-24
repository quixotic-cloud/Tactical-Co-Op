class X2AbilityToHitCalc_StatCheck_UnitVsUnit extends X2AbilityToHitCalc_StatCheck;

var ECharStatType AttackerStat, DefenderStat;

function int GetAttackValue(XComGameState_Ability kAbility, StateObjectReference TargetRef)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	return UnitState.GetCurrentStat(AttackerStat);
}

function int GetDefendValue(XComGameState_Ability kAbility, StateObjectReference TargetRef)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
	return UnitState.GetCurrentStat(DefenderStat);
}

function string GetAttackString() { return class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[AttackerStat]; }
function string GetDefendString() { return class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[DefenderStat]; }

DefaultProperties
{
	AttackerStat = eStat_PsiOffense
	DefenderStat = eStat_Will
}