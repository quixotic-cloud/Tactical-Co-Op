class X2Item_DefaultUtilityItems extends X2Item config(GameCore);

var config int MEDIKIT_CHARGES, NANOMEDIKIT_CHARGES;
var config int MEDIKIT_RANGE_TILES;

var config int BATTLESCANNER_RANGE;
var config int BATTLESCANNER_RADIUS;
var config int MIMICBEACON_RANGE;

var name MedikitCat;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;

	Items.AddItem(CreateXPad());
	Items.AddItem(CreateMedikit());
	Items.AddItem(NanoMedikit());
	Items.AddItem(CreateNanoScaleVest());
	Items.AddItem(CreatePlatedVest());
	Items.AddItem(CreateHazmatVest());
	Items.AddItem(CreateStasisVest());
	Items.AddItem(CreateBattleScanner());
	Items.AddItem(CreateMimicBeacon());
	Items.AddItem(MindShield());
	Items.AddItem(CombatStims());
	Items.AddItem(Hellweave());
	Items.AddItem(SKULLJACK());

	return Items;
}

static function X2WeaponTemplate CreateBattleScanner()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'BattleScanner');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Battle_Scanner";
	Template.EquipSound = "StrategyUI_Grenade_Equip";

	Template.GameArchetype = "WP_Grenade_BattleScanner.WP_Grenade_BattleScanner";
	Template.Abilities.AddItem('BattleScanner');
	Template.ItemCat = 'tech';
	Template.WeaponCat = 'utility';
	Template.WeaponTech = 'conventional';
	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_BeltHolster;
	Template.bMergeAmmo = true;
	Template.iClipSize = 2;
	Template.Tier = 1;

	Template.iRadius = default.BATTLESCANNER_RADIUS;
	Template.iRange = default.BATTLESCANNER_RANGE;

	Template.CanBeBuilt = true;
	Template.PointsToComplete = 0;
	Template.TradingPostValue = 6;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.BATTLESCANNER_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.BATTLESCANNER_RADIUS);

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventTrooper');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 30;
	Template.Cost.ResourceCosts.AddItem(Resources);
	
	return Template;
}

static function X2WeaponTemplate CreateMimicBeacon()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'MimicBeacon');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Mimic_Beacon";
	Template.EquipSound = "StrategyUI_Grenade_Equip";

	Template.GameArchetype = "WP_Grenade_MimicBeacon.WP_Grenade_MimicBeacon";
	Template.Abilities.AddItem('MimicBeaconThrow');
	Template.ItemCat = 'tech';
	Template.WeaponCat = 'utility';
	Template.WeaponTech = 'conventional';
	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_BeltHolster;
	Template.bMergeAmmo = true;
	Template.iClipSize = 1;
	Template.Tier = 1;

	Template.iRadius = 1;
	Template.iRange = default.MIMICBEACON_RANGE;

	Template.CanBeBuilt = true;
	Template.PointsToComplete = 0;
	Template.TradingPostValue = 15;

	Template.bShouldCreateDifficultyVariants = true;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.MIMICBEACON_RANGE);

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyFaceless');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'CorpseFaceless';
	Artifacts.Quantity = 2;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateXPad()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'XPad');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_X4";

	Template.ItemCat = 'tech';
	Template.WeaponCat = 'utility';
	Template.iRange = 15;
	Template.iRadius = 240;
	Template.iItemSize = 0;
	Template.Tier = -1;

	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_LowerBack;
	Template.Abilities.AddItem('Hack');
	Template.Abilities.AddItem('Hack_Chest');
	Template.Abilities.AddItem('Hack_Workstation');
	Template.Abilities.AddItem('Hack_ObjectiveChest');
		
	Template.GameArchetype = "WP_HackingKit.WP_HackingKit";

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	return Template;
}

static function X2DataTemplate CreateNanoScaleVest()
{
	local X2EquipmentTemplate Template;
	local ArtifactCost Resources;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'NanofiberVest');
	Template.ItemCat = 'defense';
	Template.InventorySlot = eInvSlot_Utility;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Nano_Fiber_Vest";
	Template.EquipSound = "StrategyUI_Vest_Equip";

	Template.Abilities.AddItem('NanofiberVestBonus');

	Template.CanBeBuilt = true;
	Template.TradingPostValue = 15;
	Template.PointsToComplete = 0;
	Template.Tier = 0;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.NANOFIBER_VEST_HP_BONUS);

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('HybridMaterials');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 30;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'CorpseAdventTrooper';
	Artifacts.Quantity = 2;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreatePlatedVest()
{
	local X2EquipmentTemplate Template;
	
	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'PlatedVest');
	Template.ItemCat = 'defense';
	Template.InventorySlot = eInvSlot_Utility;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Armor_Harness";
	Template.EquipSound = "StrategyUI_Vest_Equip";

	Template.Abilities.AddItem('PlatedVestBonus');

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 25;
	Template.PointsToComplete = 0;
	Template.Tier = 2;

	Template.RewardDecks.AddItem('ExperimentalArmorRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.PLATED_VEST_HP_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, class'X2Ability_ItemGrantedAbilitySet'.default.PLATED_VEST_MITIGATION_AMOUNT);
	
	return Template;
}

static function X2DataTemplate CreateHazmatVest()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'HazmatVest');
	Template.ItemCat = 'defense';
	Template.InventorySlot = eInvSlot_Utility;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Hazmat_Vest";
	Template.EquipSound = "StrategyUI_Vest_Equip";

	Template.Abilities.AddItem('HazmatVestBonus');

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 25;
	Template.PointsToComplete = 0;
	Template.Tier = 2;

	Template.RewardDecks.AddItem('ExperimentalArmorRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.HAZMAT_VEST_HP_BONUS);

	return Template;
}

static function X2DataTemplate CreateStasisVest()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'StasisVest');
	Template.ItemCat = 'defense';
	Template.InventorySlot = eInvSlot_Utility;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Stasis_Vest";
	Template.EquipSound = "StrategyUI_Vest_Equip";

	Template.Abilities.AddItem('StasisVestBonus');

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 25;
	Template.PointsToComplete = 0;
	Template.Tier = 2;

	Template.RewardDecks.AddItem('ExperimentalArmorRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.STASIS_VEST_HP_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RegenLabel, , class'X2Ability_ItemGrantedAbilitySet'.default.STASIS_VEST_REGEN_AMOUNT);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MaxRegenLabel, , class'X2Ability_ItemGrantedAbilitySet'.default.STASIS_VEST_MAX_REGEN_AMOUNT);

	return Template;
}

static function X2DataTemplate CreateMedikit()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;
	
	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Medikit');
	Template.ItemCat = 'heal';
	Template.WeaponCat = default.MedikitCat;

	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_RearBackPack;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Medkit";
	Template.EquipSound = "StrategyUI_Medkit_Equip";

	Template.iClipSize = default.MEDIKIT_CHARGES;
	Template.iRange = default.MEDIKIT_RANGE_TILES;
	Template.bMergeAmmo = true;

	Template.Abilities.AddItem('MedikitHeal');
	Template.Abilities.AddItem('MedikitStabilize');
	Template.Abilities.AddItem('MedikitBonus');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.ChargesLabel, , default.MEDIKIT_CHARGES); // TODO: Make the label say charges
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.MEDIKIT_RANGE_TILES);

	Template.GameArchetype = "WP_Medikit.WP_Medikit";

	Template.CanBeBuilt = true;
	Template.TradingPostValue = 15;
	Template.PointsToComplete = 0;
	Template.Tier = 0;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 35;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Template.HideIfResearched = 'BattlefieldMedicine';

	return Template;
}

static function X2DataTemplate NanoMedikit()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;
	local ArtifactCost Artifacts;
	
	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'NanoMedikit');
	Template.ItemCat = 'heal';
	Template.WeaponCat = default.MedikitCat;

	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_RearBackPack;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_MedkitMK2";
	Template.EquipSound = "StrategyUI_Medkit_Equip";

	Template.iClipSize = default.NANOMEDIKIT_CHARGES;
	Template.iRange = default.MEDIKIT_RANGE_TILES;
	Template.bMergeAmmo = true;

	Template.Abilities.AddItem('NanoMedikitHeal');
	Template.Abilities.AddItem('MedikitStabilize');
	Template.Abilities.AddItem('NanoMedikitBonus');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.ChargesLabel, , default.NANOMEDIKIT_CHARGES);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.MEDIKIT_RANGE_TILES);

	Template.GameArchetype = "WP_Medikit.WP_Medikit_Lv2";

	Template.CanBeBuilt = true;
	Template.TradingPostValue = 25;
	Template.PointsToComplete = 0;
	Template.Tier = 1;

	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'CorpseViper';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	Template.Requirements.RequiredTechs.AddItem('BattlefieldMedicine');

	Template.CreatorTemplateName = 'BattlefieldMedicine'; // The schematic which creates this item
	Template.BaseItem = 'Medikit'; // Which item this will be upgraded from

	return Template;
}

static function X2DataTemplate MindShield()
{
	local X2EquipmentTemplate Template;
	local ArtifactCost Resources;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'MindShield');
	Template.ItemCat = 'psidefense';
	Template.InventorySlot = eInvSlot_Utility;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_MindShield";
	Template.EquipSound = "StrategyUI_Mindshield_Equip";

	Template.Abilities.AddItem('MindShield');

	Template.CanBeBuilt = true;
	Template.TradingPostValue = 12;
	Template.PointsToComplete = 0;
	Template.Tier = 1;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsySectoid');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 45;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'CorpseSectoid';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);
	
	return Template;
}

static function X2DataTemplate CombatStims()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;
	local ArtifactCost Artifacts;
	
	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'CombatStims');
	Template.ItemCat = 'utility';
	Template.WeaponCat = 'utility';

	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_RearBackPack;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Combat_Stims";
	Template.EquipSound = "StrategyUI_Medkit_Equip";

	Template.Abilities.AddItem('CombatStims');

	Template.GameArchetype = "WP_Medikit.WP_CombatStim";

	Template.CanBeBuilt = true;
	Template.TradingPostValue = 10;
	Template.Tier = 2;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyBerserker');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 35;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'CorpseBerserker';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate Hellweave()
{
	local X2EquipmentTemplate Template;
	local ArtifactCost Resources;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'Hellweave');
	Template.ItemCat = 'defense';
	Template.InventorySlot = eInvSlot_Utility;
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Hellweave";
	Template.EquipSound = "StrategyUI_Vest_Equip";

	Template.Abilities.AddItem('ScorchCircuits');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.SCORCHCIRCUITS_HEALTH_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.BurnChanceLabel, , class'X2Ability_ItemGrantedAbilitySet'.default.SCORCHCIRCUITS_APPLY_CHANCE);

	Template.CanBeBuilt = true;
	Template.TradingPostValue = 15;
	Template.Tier = 2;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyChryssalid');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 65;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'CorpseChryssalid';
	Artifacts.Quantity = 2;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate SKULLJACK()
{
	local X2WeaponTemplate Template;
	
	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'SKULLJACK');
	Template.InventorySlot = eInvSlot_Utility;

	Template.Abilities.AddItem('SKULLJACKAbility');
	Template.Abilities.AddItem('SKULLMINEAbility');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.TechBonusLabel, eStat_Hacking, class'X2AbilityToHitCalc_Hacking'.default.SKULLJACK_HACKING_BONUS, false, IsSkullminingResearched);

	Template.CanBeBuilt = false;
	Template.PointsToComplete = 0;
	Template.TradingPostValue = 15;
	Template.MaxQuantity = 1;
	Template.Tier = 1;

	Template.GameArchetype = "WP_HackingKit.WP_SKULLJACK";

	Template.StowedLocation = eSlot_RightForearm;
	Template.WeaponCat = 'skulljack';
	Template.WeaponTech = 'conventional';
	Template.ItemCat = 'goldenpath';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Skulljack";
	Template.EquipSound = "StrategyUI_Skulljack_Equip";

	Template.OnEquippedFn = SKULLJACKEquipped;

	return Template;
}

function bool IsSkullminingResearched()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched('Skullmining');
}

function SKULLJACKEquipped(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	`XEVENTMGR.TriggerEvent('OnSKULLJACKEquip', ItemState, ItemState, NewGameState);
}

DefaultProperties
{
	MedikitCat="medikit"
}
