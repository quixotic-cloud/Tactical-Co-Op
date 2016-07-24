class X2Condition_FuseTarget extends X2Condition config(GameData_SoldierSkills);

var config array<name> FuseAbilities;

static function bool GetAvailableFuse(XComGameState_Unit TargetUnit, optional out StateObjectReference FuseTargetAbility)
{
	local StateObjectReference AbilityRef;
	local name AbilityName;
	local array<StateObjectReference> ExcludeWeapons;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;

	if (TargetUnit == none)
		return false;

	History = `XCOMHISTORY;

	foreach default.FuseAbilities(AbilityName)
	{
		ExcludeWeapons.Length = 0;
		AbilityRef = TargetUnit.FindAbility(AbilityName);
		while (AbilityRef.ObjectID != 0)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
			if (AbilityState.CanActivateAbility(TargetUnit) == 'AA_Success')
			{
				FuseTargetAbility = AbilityRef;
				return true;
			}
			ExcludeWeapons.AddItem(AbilityState.SourceWeapon);
			AbilityRef = TargetUnit.FindAbility(AbilityName, , ExcludeWeapons);
		}
	}

	return false; 
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	if (GetAvailableFuse(TargetUnit))
		return 'AA_Success';

	return 'AA_TargetHasNoLoot';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	local XComGameState_Unit TargetUnit, SourceUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	SourceUnit = XComGameState_Unit(kSource);
	if (TargetUnit == none || SourceUnit == none)
		return 'AA_NotAUnit';

	if (SourceUnit.IsFriendlyUnit(TargetUnit))
		return 'AA_UnitIsFriendly';

	return 'AA_Success'; 
}