class X2AmmoTemplate_Flechette extends X2AmmoTemplate;

var int ArmoredDamageMod;
var int OrganicDamageMod;

function GetTotalDamageModifier(XComGameState_Item AmmoState, XComGameState_Unit ShooterState, XComGameState_BaseObject TargetState, out WeaponDamageValue AmmoDamage)
{
	local XComGameState_Unit TargetUnit;

	super.GetTotalDamageModifier(AmmoState, ShooterState, TargetState, AmmoDamage);

	TargetUnit = XComGameState_Unit(TargetState);
	if (TargetUnit != none)
	{
		if (TargetUnit.GetCurrentStat(eStat_ArmorMitigation) > 0)
			AmmoDamage.Damage += ArmoredDamageMod;
		else if (!TargetUnit.IsRobotic())
			AmmoDamage.Damage += OrganicDamageMod;
	}
}