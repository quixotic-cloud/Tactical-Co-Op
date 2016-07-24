class X2ArmorTemplate extends X2EquipmentTemplate;

var(X2ArmorTemplate) bool bHeavyWeapon <Tooltip="Armor will allow access to HeavyWeapon slot and restrict use of the backpack.">;
var(X2ArmorTemplate) bool bAddsUtilitySlot <Tooltip="Allows soldier to bring a second utility item.">;
var(X2ArmorTemplate) name ArmorTechCat;
var(X2ArmorTemplate) name AkAudioSoldierArmorSwitch;
var(X2ArmorTemplate) name ArmorCat; // If the armor has a specialized category, so it is only usable by certain classes

function bool ValidateTemplate(out string strError)
{
	local X2ItemTemplateManager ItemTemplateManager;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (!ItemTemplateManager.ArmorTechIsValid(ArmorTechCat))
	{
		strError = "armor tech category '" $ ArmorTechCat $ "' is invalid";
		return false;
	}

	return super.ValidateTemplate(strError);
}

DefaultProperties
{
	InventorySlot=eInvSlot_Armor
	ItemCat="armor"
	ArmorCat="soldier"
}