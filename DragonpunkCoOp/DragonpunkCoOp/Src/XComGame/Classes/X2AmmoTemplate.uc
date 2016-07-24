class X2AmmoTemplate extends X2EquipmentTemplate
	native(Core);

struct native AmmoDamageModifier
{
	var X2Condition         TargetCondition;
	var WeaponDamageValue   DamageValue;
};

var int                 ModClipSize;
var array<X2Effect>     TargetEffects;
var array<AmmoDamageModifier>   DamageModifiers;
var array<name>         AllowedWeaponTech;      //  If the list is not empty, the weapon the ammo is loaded into must match one of these tech levels.
var bool                bBypassShields;

function AddAmmoDamageModifier(X2Condition Condition, WeaponDamageValue DamageValue)
{
	local AmmoDamageModifier Modifier;

	Modifier.DamageValue = DamageValue;
	Modifier.TargetCondition = Condition;
	DamageModifiers.AddItem(Modifier);
}

function GetTotalDamageModifier(XComGameState_Item AmmoState, XComGameState_Unit ShooterState, XComGameState_BaseObject TargetState, out WeaponDamageValue AmmoDamage)
{
	local Damageable DamageTarget;
	local int i;

	DamageTarget = Damageable(TargetState);
	if (DamageTarget == none)
		return;

	for (i = 0; i < DamageModifiers.Length; ++i)
	{
		if (DamageTarget.IsImmuneToDamage(DamageModifiers[i].DamageValue.DamageType))
			continue;
		if (DamageModifiers[i].TargetCondition != none)
		{
			if (DamageModifiers[i].TargetCondition.MeetsCondition(TargetState) != 'AA_Success')
				continue;
			if (DamageModifiers[i].TargetCondition.MeetsConditionWithSource(TargetState, ShooterState) != 'AA_Success')
				continue;
		}		
		AmmoDamage.Damage += DamageModifiers[i].DamageValue.Damage;
		AmmoDamage.Spread += DamageModifiers[i].DamageValue.Spread;
		AmmoDamage.Crit += DamageModifiers[i].DamageValue.Crit;
		AmmoDamage.Pierce += DamageModifiers[i].DamageValue.Pierce;
		AmmoDamage.Rupture += DamageModifiers[i].DamageValue.Rupture;
		AmmoDamage.Shred += DamageModifiers[i].DamageValue.Shred;
		AmmoDamage.PlusOne += DamageModifiers[i].DamageValue.PlusOne;       //  NOTE: stacking multiple PlusOne values is only going to result in 1 possible extra dmage, so don't expect more than that
	}
}

function bool IsWeaponValidForAmmo(X2WeaponTemplate WeaponTemplate)
{
	if (AllowedWeaponTech.Length > 0)
	{
		if (AllowedWeaponTech.Find(WeaponTemplate.WeaponTech) == INDEX_NONE)
			return false;
	}
	return true;
}

DefaultProperties
{
	InventorySlot = eInvSlot_Utility
	ItemCat = "ammo"
	bBypassShields=false
}