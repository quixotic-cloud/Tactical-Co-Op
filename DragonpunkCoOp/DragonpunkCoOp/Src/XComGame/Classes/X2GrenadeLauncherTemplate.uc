class X2GrenadeLauncherTemplate extends X2WeaponTemplate native(Core);

var int IncreaseGrenadeRange;
var int IncreaseGrenadeRadius;

DefaultProperties
{
	WeaponCat = "grenade_launcher";
	InventorySlot = eInvSlot_SecondaryWeapon;
	StowedLocation = eSlot_RightBack;
	bSoundOriginatesFromOwnerLocation = false;
}