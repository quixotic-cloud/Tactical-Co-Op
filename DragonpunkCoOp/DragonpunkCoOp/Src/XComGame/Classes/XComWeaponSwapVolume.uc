class XComWeaponSwapVolume extends TriggerVolume
	placeable;

var bool bSwappingWeapon;
var() class<XGWeapon> WeaponClass;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp,Vector HitLocation, Vector HitNormal)
{
	local XGUnit kUnit;
	local XGWeapon kNewWeapon;
	local XGInventoryItem kItem;
	local XComUnitPawn XPawn;

	super.Touch(Other, OtherComp, HitLocation, HitNormal);

	XPawn = XComUnitPawn(Other);

	if (WeaponClass == none)
		return;

	if (XPawn != none)
		kUnit = (XGUnit(XPawn.GetGameUnit()));

	if (kUnit == none)
		return;

	if(bSwappingWeapon)
		return;

	if(XPawn != none)
	{

		bSwappingWeapon = true;

		kItem = kUnit.GetInventory().GetItem( eSlot_RightHand );
		kUnit.GetInventory().DropItem(kItem);
		
		if (kUnit.GetPawn().Weapon.Mesh != none)
		{
			kUnit.GetPawn().Mesh.DetachComponent(kUnit.GetPawn().Weapon.Mesh);
		}

		kNewWeapon = Spawn(WeaponClass, kUnit.Owner);

		kNewWeapon.Init();

		kUnit.GetInventory().EquipItem(kNewWeapon, true);

		bSwappingWeapon = false;
	}
}

defaultproperties
{
	bSwappingWeapon = false;
	WeaponClass=none;
}