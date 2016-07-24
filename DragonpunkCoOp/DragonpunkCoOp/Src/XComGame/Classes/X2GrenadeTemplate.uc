class X2GrenadeTemplate extends X2WeaponTemplate native(Core);

var array<X2Effect> ThrownGrenadeEffects;
var array<X2Effect> LaunchedGrenadeEffects;
var bool bFriendlyFire, bFriendlyFireWarning;
var bool bAllowVolatileMix;

var localized string ThrownAbilityName;
var localized string ThrownAbilityHelpText;
var localized string LaunchedAbilityName;
var localized string LaunchedAbilityHelpText;

var name OnThrowBarkSoundCue;

DefaultProperties
{
	bAllowVolatileMix=true
	WeaponCat="grenade"
	ItemCat="grenade"
	InventorySlot=eInvSlot_Utility
	StowedLocation=eSlot_BeltHolster
	bMergeAmmo=true
	bSoundOriginatesFromOwnerLocation=false
	bFriendlyFire=true
	bFriendlyFireWarning=true
	bHideWithNoAmmo=true
}