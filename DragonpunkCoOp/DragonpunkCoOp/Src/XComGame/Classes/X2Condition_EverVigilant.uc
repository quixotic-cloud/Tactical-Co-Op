class X2Condition_EverVigilant extends X2Condition;

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit SourceUnit, TargetUnit;

	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);

	if (SourceUnit == none || TargetUnit == none)
		return 'AA_NotAUnit';

	//  If the shooter is under effect of Ever Vigilant...
	if (SourceUnit.IsUnitAffectedByEffectName(class'X2Ability_SpecialistAbilitySet'.default.EverVigilantEffectName))
	{
		//  If the target is not in Red Alert...
		if (TargetUnit.GetCurrentStat(eStat_AlertLevel) < 2)
		{
			return 'AA_UnitIsFriendly';
		}
	}

	return 'AA_Success';
}