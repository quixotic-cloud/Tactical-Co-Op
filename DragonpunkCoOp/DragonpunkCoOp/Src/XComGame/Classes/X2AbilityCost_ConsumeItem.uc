class X2AbilityCost_ConsumeItem extends X2AbilityCost;

simulated function name CanAfford(XComGameState_Ability kAbility, XComGameState_Unit ActivatingUnit)
 {
	if (kAbility.GetSourceWeapon() == none || !ActivatingUnit.CanRemoveItemFromInventory(kAbility.GetSourceWeapon()))
		return 'AA_CannotAfford_AmmoCost';

	return 'AA_Success';
}

simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local StateObjectReference EmptyRef;
	local XComGameState_Unit UnitState;

	if (!bFreeCost)
	{
		UnitState = XComGameState_Unit(AffectState);
		if (UnitState != None && AffectWeapon != None)
		{
			if (UnitState.RemoveItemFromInventory(AffectWeapon, NewGameState))
			{
				NewGameState.RemoveStateObject(AffectWeapon.ObjectID);
				kAbility.SourceWeapon = EmptyRef;
			}
		}
	}
}