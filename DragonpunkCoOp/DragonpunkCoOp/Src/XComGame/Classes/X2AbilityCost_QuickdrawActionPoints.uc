class X2AbilityCost_QuickdrawActionPoints extends X2AbilityCost_ActionPoints;

simulated function bool ConsumeAllPoints(XComGameState_Ability AbilityState, XComGameState_Unit AbilityOwner)
{
	if (AbilityOwner.HasSoldierAbility('Quickdraw') && AbilityState.GetSourceWeapon().InventorySlot == eInvSlot_SecondaryWeapon)
	{
		return false;
	}
	return super.ConsumeAllPoints(AbilityState, AbilityOwner);
}