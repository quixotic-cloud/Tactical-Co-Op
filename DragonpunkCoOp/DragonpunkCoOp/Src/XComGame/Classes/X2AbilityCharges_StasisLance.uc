class X2AbilityCharges_StasisLance extends X2AbilityCharges config(GameData_SoldierSkills);

var config int BASE_CHARGES;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit)
{
	return default.BASE_CHARGES;
}