class X2Effect_Shredder extends X2Effect_ApplyWeaponDamage
	config(GameData_SoldierSkills);

var config int ConventionalShred, MagneticShred, BeamShred;

function WeaponDamageValue GetBonusEffectDamageValue(XComGameState_Ability AbilityState, XComGameState_Item SourceWeapon, StateObjectReference TargetRef)
{
	local WeaponDamageValue ShredValue;
	local X2WeaponTemplate WeaponTemplate;
	local XComGameState_Unit SourceUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	ShredValue = EffectDamageValue;             //  in case someone has set other fields in here, but not likely

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if ((SourceWeapon != none) &&
		(SourceUnit != none) &&
		SourceUnit.HasSoldierAbility('Shredder'))
	{
		WeaponTemplate = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
		if (WeaponTemplate != none)
		{
			ShredValue.Shred = default.ConventionalShred;

			if (WeaponTemplate.WeaponTech == 'magnetic')
				ShredValue.Shred = default.MagneticShred;
			else if (WeaponTemplate.WeaponTech == 'beam')
				ShredValue.Shred = default.BeamShred;
		}
	}

	return ShredValue;
}

DefaultProperties
{
	bAllowFreeKill=true
	bIgnoreBaseDamage=false
}