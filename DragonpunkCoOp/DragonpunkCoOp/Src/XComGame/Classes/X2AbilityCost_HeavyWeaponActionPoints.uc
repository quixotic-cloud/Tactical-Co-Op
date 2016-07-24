class X2AbilityCost_HeavyWeaponActionPoints extends X2AbilityCost_ActionPoints;

simulated function int GetPointCost(XComGameState_Ability AbilityState, XComGameState_Unit AbilityOwner)
{
	if (AbilityOwner.HasSoldierAbility('Salvo'))
		return 1;

	return 1;
}

DefaultProperties
{
	bConsumeAllPoints = true
	DoNotConsumeAllSoldierAbilities(0)="Salvo"
}