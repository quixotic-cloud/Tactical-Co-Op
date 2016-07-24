class X2Condition_AbilitySourceWeapon extends X2Condition;

var bool WantsReload;
var bool CheckAmmo;
var CheckConfig CheckAmmoData;
var bool NotLoadedAmmoInSecondaryWeapon;
var name MatchGrenadeType;
var bool CheckGrenadeFriendlyFire;
var bool CheckAmmoTechLevel;
var name MatchWeaponTemplate;               //  requires exact match to weapon's template's DataName

function AddAmmoCheck(int Value, optional EValueCheck CheckType=eCheck_Exact, optional int ValueMax=0, optional int ValueMin=0)
{
	CheckAmmo = true;
	CheckAmmoData.Value = Value;
	CheckAmmoData.CheckType = CheckType;
	CheckAmmoData.ValueMax = ValueMax;
	CheckAmmoData.ValueMin = ValueMin;
}

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState, TargetUnitState;
	local XComGameState_Item SourceWeapon, PrimaryWeapon, SecondaryWeapon;
	local X2AmmoTemplate AmmoTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local name AmmoResult;
	local X2GrenadeTemplate GrenadeTemplate;

	SourceWeapon = kAbility.GetSourceWeapon();
	if (SourceWeapon != none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
		TargetUnitState = XComGameState_Unit(kTarget);
		if (WantsReload)
		{
			if (SourceWeapon.Ammo == SourceWeapon.GetClipSize())
				return 'AA_AmmoAlreadyFull';
		}
		if (CheckAmmo)
		{
			AmmoResult = PerformValueCheck(SourceWeapon.Ammo, CheckAmmoData);                                                                                                                          
			if (AmmoResult != 'AA_Success')
				return AmmoResult;
		}
		if (NotLoadedAmmoInSecondaryWeapon)
		{
			SecondaryWeapon = UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon);
			if (SecondaryWeapon != none && SecondaryWeapon.LoadedAmmo.ObjectID == SourceWeapon.ObjectID)
				return 'AA_AmmoAlreadyFull';
		}
		if (MatchGrenadeType != '')
		{
			GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());
			if (GrenadeTemplate == none)
				GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetLoadedAmmoTemplate(kAbility));
			if (GrenadeTemplate == none || GrenadeTemplate.DataName != MatchGrenadeType)
				return 'AA_WeaponIncompatible';
		}
		if (MatchWeaponTemplate != '')
		{
			if (SourceWeapon.GetMyTemplateName() != MatchWeaponTemplate)
				return 'AA_WeaponIncompatible';
		}
		if (CheckGrenadeFriendlyFire)
		{
			if (kTarget != none)
			{				
				if (TargetUnitState != none)
				{
					GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());
					if (GrenadeTemplate == none)
					{
						GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetLoadedAmmoTemplate(kAbility));
						if (GrenadeTemplate == none)
							return 'AA_WeaponIncompatible';
					}
					if (!GrenadeTemplate.bFriendlyFire)
					{
						if (!UnitState.IsEnemyUnit(TargetUnitState))
							return 'AA_UnitIsFriendly';
					}
				}
			}
		}
		if (CheckAmmoTechLevel)
		{
			PrimaryWeapon = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon);
			AmmoTemplate = X2AmmoTemplate(SourceWeapon.GetMyTemplate());
			WeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
			if (WeaponTemplate != none && AmmoTemplate != none)
			{
				if (!AmmoTemplate.IsWeaponValidForAmmo(WeaponTemplate))
					return 'AA_WeaponIncompatible';
			}
		}
	}
	return 'AA_Success';
}