class X2Item_DefaultArmors extends X2Item;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Armors;

	Armors.AddItem(CreateKevlarArmor());
	Armors.AddItem(CreateMediumPlatedArmor());
	Armors.AddItem(CreateLightPlatedArmor());
	Armors.AddItem(CreateHeavyPlatedArmor());
	Armors.AddItem(CreateMediumPoweredArmor());
	Armors.AddItem(CreateLightPoweredArmor());
	Armors.AddItem(CreateHeavyPoweredArmor());
	return Armors;
}

static function X2DataTemplate CreateKevlarArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'KevlarArmor');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Kevlar_Armor";
	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;
	Template.ArmorTechCat = 'conventional';
	Template.Tier = 0;
	Template.AkAudioSoldierArmorSwitch = 'Conventional';
	Template.EquipSound = "StrategyUI_Armor_Equip_Conventional";

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, 0, true);

	return Template;
}

static function X2DataTemplate CreateMediumPlatedArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'MediumPlatedArmor');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Predator_Armor";
	Template.ItemCat = 'armor';
	Template.bAddsUtilitySlot = true;
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;
	Template.TradingPostValue = 20;
	Template.PointsToComplete = 0;
	Template.Abilities.AddItem('MediumPlatedArmorStats');
	Template.ArmorTechCat = 'plated';
	Template.Tier = 1;
	Template.AkAudioSoldierArmorSwitch = 'Predator';
	Template.EquipNarrative = "X2NarrativeMoments.Strategy.CIN_ArmorIntro_PlatedMedium";
	Template.EquipSound = "StrategyUI_Armor_Equip_Plated";

	Template.CreatorTemplateName = 'MediumPlatedArmor_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'KevlarArmor'; // Which item this will be upgraded from

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.MEDIUM_PLATED_HEALTH_BONUS, true);

	return Template;
}

static function X2DataTemplate CreateLightPlatedArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'LightPlatedArmor');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Spider_Suit";
	Template.ItemCat = 'armor';
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;
	Template.PointsToComplete = 0;
	Template.Abilities.AddItem('LightPlatedArmorStats');
	Template.Abilities.AddItem('Grapple');
	Template.ArmorTechCat = 'plated';
	Template.Tier = 2;
	Template.AkAudioSoldierArmorSwitch = 'Spider';
	Template.EquipNarrative = "X2NarrativeMoments.Strategy.CIN_ArmorIntro_PlatedLight";
	Template.EquipSound = "StrategyUI_Armor_Equip_Plated";

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.LIGHT_PLATED_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, class'X2Ability_ItemGrantedAbilitySet'.default.LIGHT_PLATED_MOBILITY_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.DodgeLabel, eStat_Dodge, class'X2Ability_ItemGrantedAbilitySet'.default.LIGHT_PLATED_DODGE_BONUS);
		
	return Template;
}

static function X2DataTemplate CreateHeavyPlatedArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'HeavyPlatedArmor');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Hammer_Armor";
	Template.ItemCat = 'armor';
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 35;
	Template.PointsToComplete = 0;
	Template.bHeavyWeapon = true;
	Template.Abilities.AddItem('HeavyPlatedArmorStats');
	Template.ArmorTechCat = 'plated';
	Template.Tier = 2;
	Template.AkAudioSoldierArmorSwitch = 'EXO';
	Template.EquipNarrative = "X2NarrativeMoments.Strategy.CIN_ArmorIntro_PlatedHeavy";
	Template.EquipSound = "StrategyUI_Armor_Equip_Plated";

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.HEAVY_PLATED_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, class'X2Ability_ItemGrantedAbilitySet'.default.HEAVY_PLATED_MITIGATION_AMOUNT);
		
	return Template;
}

static function X2DataTemplate CreateMediumPoweredArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'MediumPoweredArmor');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Warden_Armor";
	Template.ItemCat = 'armor';
	Template.bAddsUtilitySlot = true;
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;
	Template.TradingPostValue = 60;
	Template.PointsToComplete = 0;
	Template.Abilities.AddItem('MediumPoweredArmorStats');
	Template.ArmorTechCat = 'powered';
	Template.Tier = 3;
	Template.AkAudioSoldierArmorSwitch = 'Warden';
	Template.EquipNarrative = "X2NarrativeMoments.Strategy.CIN_ArmorIntro_PoweredMedium";
	Template.EquipSound = "StrategyUI_Armor_Equip_Powered";

	Template.CreatorTemplateName = 'MediumPoweredArmor_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'MediumPlatedArmor'; // Which item this will be upgraded from

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.MEDIUM_POWERED_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, class'X2Ability_ItemGrantedAbilitySet'.default.MEDIUM_POWERED_MITIGATION_AMOUNT);
	
	return Template;
}

static function X2DataTemplate CreateLightPoweredArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'LightPoweredArmor');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_WraithSuit";
	Template.ItemCat = 'armor';
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 100;
	Template.PointsToComplete = 0;
	Template.Abilities.AddItem('LightPoweredArmorStats');
	Template.Abilities.AddItem('GrapplePowered');
	Template.Abilities.AddItem('WallPhasing');
	Template.ArmorTechCat = 'powered';
	Template.Tier = 4;
	Template.AkAudioSoldierArmorSwitch = 'Wraith';
	Template.EquipNarrative = "X2NarrativeMoments.Strategy.CIN_ArmorIntro_PoweredLight";
	Template.EquipSound = "StrategyUI_Armor_Equip_Powered";

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.LIGHT_POWERED_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, class'X2Ability_ItemGrantedAbilitySet'.default.LIGHT_POWERED_MOBILITY_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.DodgeLabel, eStat_Dodge, class'X2Ability_ItemGrantedAbilitySet'.default.LIGHT_POWERED_DODGE_BONUS);
		
	return Template;
}

static function X2DataTemplate CreateHeavyPoweredArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'HeavyPoweredArmor');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Marauder_Armor";
	Template.ItemCat = 'armor';
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 120;
	Template.PointsToComplete = 0;
	Template.bHeavyWeapon = true;
	Template.Abilities.AddItem('HeavyPoweredArmorStats');
	Template.Abilities.AddItem('HighCoverGenerator');
	Template.ArmorTechCat = 'powered';
	Template.Tier = 4;
	Template.AkAudioSoldierArmorSwitch = 'WAR';
	Template.EquipNarrative = "X2NarrativeMoments.Strategy.CIN_ArmorIntro_PoweredHeavy";
	Template.EquipSound = "StrategyUI_Armor_Equip_Powered";

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_ItemGrantedAbilitySet'.default.HEAVY_POWERED_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, class'X2Ability_ItemGrantedAbilitySet'.default.HEAVY_POWERED_MITIGATION_AMOUNT);
	
	return Template;
}