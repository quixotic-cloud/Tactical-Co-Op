class X2Item_DefaultResources extends X2Item;

var localized array<string> PCSBlackMarketTexts;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Resources;

	Resources.AddItem(CreateTwistedSlag());
	Resources.AddItem(CreateSupplies());
	Resources.AddItem(CreateIntel());
	Resources.AddItem(CreateArmorHarness());
	Resources.AddItem(CreatePowerCell());
	Resources.AddItem(CreateMicroservoModule());
	Resources.AddItem(CreateWeaponFragment());
	Resources.AddItem(CreateAlienAlloy());
	Resources.AddItem(CreateEleriumCore());
	Resources.AddItem(CreateEleriumDust());



	Resources.AddItem(CreateCommonPCSSpeed());
	Resources.AddItem(CreateCommonPCSConditioning());
	Resources.AddItem(CreateCommonPCSFocus());
	Resources.AddItem(CreateCommonPCSPerception());
	Resources.AddItem(CreateCommonPCSAgility());
	Resources.AddItem(CreateRarePCSSpeed());
	Resources.AddItem(CreateRarePCSConditioning());
	Resources.AddItem(CreateRarePCSFocus());
	Resources.AddItem(CreateRarePCSPerception());
	Resources.AddItem(CreateRarePCSAgility());
	Resources.AddItem(CreateEpicPCSSpeed());
	Resources.AddItem(CreateEpicPCSConditioning());
	Resources.AddItem(CreateEpicPCSFocus());
	Resources.AddItem(CreateEpicPCSPerception());
	Resources.AddItem(CreateEpicPCSAgility());
	Resources.AddItem(CreateBrokenSectoidPsiAmp());
	Resources.AddItem(CreateIntactSectoidPsiAmp());

	Resources.AddItem(CreateCorpseSectoid());
	Resources.AddItem(CreateCorpseViper());
	Resources.AddItem(CreateCorpseMuton());
	Resources.AddItem(CreateCorpseBerserker());
	Resources.AddItem(CreateCorpseArchon());
	Resources.AddItem(CreateCorpseGatekeeper());
	Resources.AddItem(CreateCorpseCyberus());
	Resources.AddItem(CreateCorpseAndromedon());
	Resources.AddItem(CreateCorpseFaceless());
	Resources.AddItem(CreateCorpseChryssalid());
	Resources.AddItem(CreateCorpseAdventTrooper());
	Resources.AddItem(CreateCorpseAdventOfficer());
	Resources.AddItem(CreateCorpseAdventTurret());
	Resources.AddItem(CreateCorpseAdventMEC());
	Resources.AddItem(CreateCorpseAdventStunLancer());
	Resources.AddItem(CreateCorpseAdventShieldbearer());
	Resources.AddItem(CreateCorpseAdventPsiWitch());
	Resources.AddItem(CreateCorpseSectopod());
	
	Resources.AddItem(CreateDisabledADVENTMagRifle());
	
	// Intel Faucet items
	Resources.AddItem(CreateAdventDatapad());
	Resources.AddItem(CreateAlienDatapad());
	
	Resources.AddItem(CreateSmallIntelCache());
	Resources.AddItem(CreateBigIntelCache());

	Resources.AddItem(CreateSmallSuppliesCache());
	Resources.AddItem(CreateBigSuppliesCache());

	Resources.AddItem(CreateSmallAlienAlloyCache());
	Resources.AddItem(CreateBigAlienAlloyCache());

	// Facility Lead
	Resources.AddItem(CreateFacilityLeadItem());
	
	// Golden Path Items
	Resources.AddItem(CreateBlacksiteDataCube());
	Resources.AddItem(CreateStasisSuitComponent());
	Resources.AddItem(CreatePsiGateArtifact());
	Resources.AddItem(CreateTheTruth());

	return Resources;
}

static function X2DataTemplate CreateSupplies()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'Supplies');
	Template.CanBeBuilt = false;
	Template.HideInInventory = true;

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Supplies";
	Template.ItemCat = 'resource';

	return Template;
}

static function X2DataTemplate CreateIntel()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'Intel');
	Template.CanBeBuilt = false;
	Template.HideInInventory = true;

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Intel";
	Template.ItemCat = 'resource';

	return Template;
}


static function X2DataTemplate CreateCommonPCSSpeed()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'CommonPCSSpeed');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Speed";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 15;
	Template.bAlwaysUnique = false;
	Template.Tier = 0;

	Template.StatBoostPowerLevel = 1;
	Template.StatsToBoost.AddItem(eStat_Mobility);
	Template.bUseBoostIncrement = true;
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateCommonPCSConditioning()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'CommonPCSConditioning');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Metabolism";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 20;
	Template.bAlwaysUnique = false;
	Template.Tier = 0;

	Template.StatBoostPowerLevel = 1;
	Template.StatsToBoost.AddItem(eStat_HP);
	Template.bUseBoostIncrement = true;
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateCommonPCSFocus()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'CommonPCSFocus');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Focus";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 10;
	Template.bAlwaysUnique = false;
	Template.Tier = 0;

	Template.StatBoostPowerLevel = 1;
	Template.StatsToBoost.AddItem(eStat_Will);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateCommonPCSPerception()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'CommonPCSPerception');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Perception";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 20;
	Template.bAlwaysUnique = false;
	Template.Tier = 0;

	Template.StatBoostPowerLevel = 1;
	Template.StatsToBoost.AddItem(eStat_Offense);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateCommonPCSAgility()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'CommonPCSAgility');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Dodge";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 15;
	Template.bAlwaysUnique = false;
	Template.Tier = 0;

	Template.StatBoostPowerLevel = 1;
	Template.StatsToBoost.AddItem(eStat_Dodge);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateRarePCSSpeed()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'RarePCSSpeed');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Speed";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 40;
	Template.bAlwaysUnique = false;
	Template.Tier = 1;

	Template.StatBoostPowerLevel = 2;
	Template.StatsToBoost.AddItem(eStat_Mobility);
	Template.bUseBoostIncrement = true;
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateRarePCSConditioning()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'RarePCSConditioning');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Metabolism";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 40;
	Template.bAlwaysUnique = false;
	Template.Tier = 1;

	Template.StatBoostPowerLevel = 2;
	Template.StatsToBoost.AddItem(eStat_HP);
	Template.bUseBoostIncrement = true;
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateRarePCSFocus()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'RarePCSFocus');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Focus";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 20;
	Template.bAlwaysUnique = false;
	Template.Tier = 1;

	Template.StatBoostPowerLevel = 2;
	Template.StatsToBoost.AddItem(eStat_Will);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateRarePCSPerception()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'RarePCSPerception');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Perception";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 50;
	Template.bAlwaysUnique = false;
	Template.Tier = 1;

	Template.StatBoostPowerLevel = 2;
	Template.StatsToBoost.AddItem(eStat_Offense);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateRarePCSAgility()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'RarePCSAgility');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Dodge";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 30;
	Template.bAlwaysUnique = false;
	Template.Tier = 1;

	Template.StatBoostPowerLevel = 2;
	Template.StatsToBoost.AddItem(eStat_Dodge);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateEpicPCSSpeed()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'EpicPCSSpeed');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Speed";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 55;
	Template.bAlwaysUnique = false;
	Template.Tier = 2;

	Template.StatBoostPowerLevel = 3;
	Template.StatsToBoost.AddItem(eStat_Mobility);
	Template.bUseBoostIncrement = true;
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateEpicPCSConditioning()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'EpicPCSConditioning');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Metabolism";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 55;
	Template.bAlwaysUnique = false;
	Template.Tier = 2;

	Template.StatBoostPowerLevel = 3;
	Template.StatsToBoost.AddItem(eStat_HP);
	Template.bUseBoostIncrement = true;
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateEpicPCSFocus()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'EpicPCSFocus');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Focus";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 30;
	Template.bAlwaysUnique = false;
	Template.Tier = 2;

	Template.StatBoostPowerLevel = 3;
	Template.StatsToBoost.AddItem(eStat_Will);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateEpicPCSPerception()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'EpicPCSPerception');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Perception";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 75;
	Template.bAlwaysUnique = false;
	Template.Tier = 2;

	Template.StatBoostPowerLevel = 3;
	Template.StatsToBoost.AddItem(eStat_Offense);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateEpicPCSAgility()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'EpicPCSAgility');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Dodge";
	Template.ItemCat = 'combatsim';
	Template.TradingPostValue = 45;
	Template.bAlwaysUnique = false;
	Template.Tier = 2;

	Template.StatBoostPowerLevel = 3;
	Template.StatsToBoost.AddItem(eStat_Dodge);
	Template.InventorySlot = eInvSlot_CombatSim;

	Template.BlackMarketTexts = default.PCSBlackMarketTexts;

	return Template;
}

static function X2DataTemplate CreateArmorHarness()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'ArmorHarness');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Armor_Harness";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 15;

	return Template;
}

static function X2DataTemplate CreatePowerCell()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'PowerCell');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Power_Cell";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 40;

	return Template;
}

static function X2DataTemplate CreateMicroservoModule()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'MicroservoModule');
	
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Microserver_Module";
	Template.TradingPostValue = 75;
	Template.ItemCat = 'resource';

	return Template;
}

static function X2DataTemplate CreateEleriumCore()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'EleriumCore');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.EleriumCore';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Elerium_Core";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 15;

	return Template;
}

static function X2DataTemplate CreateWeaponFragment()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'WeaponFragment');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Weapon_Fragments";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 3;
	Template.MaxQuantity = 10;

	return Template;
}

static function X2DataTemplate CreateAlienAlloy()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'AlienAlloy');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Alien_Alloy";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 3;
	Template.MaxQuantity = 40;
	Template.HideInInventory = true;

	return Template;
}

static function X2DataTemplate CreateEleriumDust()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'EleriumDust');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Elerium_Crystals";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 5;
	Template.MaxQuantity = 40;
	Template.HideInInventory = true;

	return Template;
}

static function X2DataTemplate CreateTwistedSlag()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'TwistedSlag');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Twisted_Slag";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 1;
	Template.MaxQuantity = 10;

	return Template;
}

static function X2DataTemplate CreateBrokenSectoidPsiAmp()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'BrokenSectoidPsiAmp');

	Template.ItemCat = 'resource';
	Template.TradingPostValue = 15;
	Template.MaxQuantity = 1;

	return Template;
}

static function X2DataTemplate CreateIntactSectoidPsiAmp()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'IntactSectoidPsiAmp');

	Template.ItemCat = 'resource';
	Template.TradingPostValue = 75;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;
	Template.ExplosiveRemains = 'BrokenSectoidPsiAmp';

	return Template;
}

static function X2DataTemplate CreateCorpseSectoid()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseSectoid');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Sectoid";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 5;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseViper()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseViper');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Viper";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 5;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseMuton()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseMuton');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Muton";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 5;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseBerserker()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseBerserker');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Berserker";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 7;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseArchon()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseArchon');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Archon";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 7;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseCyberus()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseCyberus');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Codex_Brain";
	Template.ItemCat = 'resource';
	Template.MaxQuantity = 6;
	Template.LeavesExplosiveRemains = true;
	Template.bAlwaysRecovered = true;

	Template.ItemRecoveredAsLootNarrative = "X2NarrativeMoments.Strategy.MISC_VO_Thanks_Codex_Brain_Tygan";
	Template.IsObjectiveItemFn = IsCodexCorpseObjectiveItem;

	return Template;
}

function bool IsCodexCorpseObjectiveItem()
{
	return !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T1_M4_StudyCodexBrain');
}

static function X2DataTemplate CreateCorpseAndromedon()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseAndromedon');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Andromedon";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 6;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseFaceless()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseFaceless');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Faceless_Goo";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 4;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseChryssalid()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseChryssalid');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Cryssalid";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 3;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseGatekeeper()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseGatekeeper');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Gatekeeper";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 10;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseAdventTrooper()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseAdventTrooper');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Advent_Trooper";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 3;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseAdventOfficer()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseAdventOfficer');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Advent_Officer";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 4;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;
	//Template.ItemRecoveredAsLootNarrative = "X2NarrativeMoments.Tygan_Setup_Phase_ADVENT_Officer_Corpse_Recovered";
	Template.IsObjectiveItemFn = IsOfficerCorpseObjectiveItem;

	return Template;
}

function bool IsOfficerCorpseObjectiveItem()
{
	return (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T1_M1_AutopsyACaptain') == eObjectiveState_InProgress);
}

static function X2DataTemplate CreateCorpseAdventTurret()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseAdventTurret');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Advent_Turret";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 5;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseAdventMEC()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseAdventMEC');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_MEC";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 4;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseAdventStunLancer()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseAdventStunLancer');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Advent_Stun_Lance";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 3;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseAdventShieldbearer()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseAdventShieldbearer');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Advent_Shieldbearer";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 4;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateCorpseAdventPsiWitch()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseAdventPsiWitch');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Avatar";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 25;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;
	Template.bAlwaysRecovered = true;

	Template.ItemRecoveredAsLootNarrative = "X2NarrativeMoments.Strategy.S_Support_Avatar_Corpse_Recovered_Tygan";
	Template.ItemRecoveredAsLootNarrativeReqsNotMet = "X2NarrativeMoments.S_GP_Avatar_Body_Recovered_But_Prereqs_Not_Met_Tygan";
	Template.IsObjectiveItemFn = IsAvatarCorpseObjectiveItem;
		
	Template.Requirements.SpecialRequirementsFn = IsAvatarAutopsyAvailable;

	return Template;
}

function bool IsAvatarCorpseObjectiveItem()
{
	return !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T5_M1_AutopsyTheAvatar');
}

function bool IsAvatarAutopsyAvailable()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local StateObjectReference TechRef;
	local array<StateObjectReference> AvailableTechRefs;
	
	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	AvailableTechRefs = XComHQ.GetAvailableTechsForResearch(true);

	foreach AvailableTechRefs(TechRef)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		if (TechState.GetMyTemplateName() == 'AutopsyAdventPsiWitch')
		{
			return true;
		}
	}

	return false;
}

static function X2DataTemplate CreateCorpseSectopod()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'CorpseSectopod');

	Template.strImage = "img:///UILibrary_StrategyImages.CorpseIcons.Corpse_Sectopod";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 15;
	Template.MaxQuantity = 1;
	Template.LeavesExplosiveRemains = true;

	return Template;
}

static function X2DataTemplate CreateDisabledADVENTMagRifle()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'DisabledADVENTMagRifle');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Mag_Rifle_Chassis";
	Template.ItemCat = 'resource';
	Template.TradingPostValue = 10;
	Template.MaxQuantity = 1;

	return Template;
}

static function X2DataTemplate CreateAdventDatapad()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'AdventDatapad');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventDatapad';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Advent_Datapad";
	Template.ItemCat = 'utility';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.TradingPostValue = 40;

	return Template;
}

static function X2DataTemplate CreateAlienDatapad()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'AlienDatapad');

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AlienDatapad';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Alien_Datapad";
	Template.ItemCat = 'utility';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.TradingPostValue = 65;

	return Template;
}

static function X2DataTemplate CreateSmallIntelCache()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'SmallIntelCache');

	Template.ItemCat = 'resource';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.ResourceTemplateName = 'Intel';
	Template.ResourceQuantity = 20;

	return Template;
}

static function X2DataTemplate CreateBigIntelCache()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'BigIntelCache');

	Template.ItemCat = 'resource';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.ResourceTemplateName = 'Intel';
	Template.ResourceQuantity = 40;

	return Template;
}

static function X2DataTemplate CreateSmallSuppliesCache()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'SmallSuppliesCache');

	Template.ItemCat = 'resource';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.ResourceTemplateName = 'Supplies';
	Template.ResourceQuantity = 35;

	return Template;
}

static function X2DataTemplate CreateBigSuppliesCache()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'BigSuppliesCache');

	Template.ItemCat = 'resource';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.ResourceTemplateName = 'Supplies';
	Template.ResourceQuantity = 75;

	return Template;
}

static function X2DataTemplate CreateSmallAlienAlloyCache()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'SmallAlienAlloyCache');
	
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Alien_Alloy";
	Template.ItemCat = 'resource';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.ResourceTemplateName = 'AlienAlloy';
	Template.ResourceQuantity = 10;

	return Template;
}

static function X2DataTemplate CreateBigAlienAlloyCache()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'BigAlienAlloyCache');
	
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Alien_Alloy";
	Template.ItemCat = 'resource';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.ResourceTemplateName = 'AlienAlloy';
	Template.ResourceQuantity = 20;

	return Template;
}

static function X2DataTemplate CreateFacilityLeadItem()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'FacilityLeadItem');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Facility_Lead";
	Template.ItemCat = 'resource';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.TradingPostValue = 10;

	Template.Requirements.SpecialRequirementsFn = NoFacilityLeadAvailable;

	return Template;
}

function bool NoFacilityLeadAvailable()
{
	return !`XCOMHQ.HasItemByName('FacilityLeadItem');
}

///////////////////////////////////////////////////////////////////
// Golden Path Items

static function X2DataTemplate CreateBlacksiteDataCube()
{
	local X2QuestItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Template, 'BlacksiteDataCube');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Black_Site_Data";
	Template.ItemCat = 'goldenpath';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.HideInLootRecovered = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.MissionType.AddItem("GP_Blacksite");

	Template.RewardType.AddItem('Reward_None');
	Template.RewardType.AddItem('Reward_Supplies');

	Template.ItemRecoveredAsLootNarrative = "X2NarrativeMoments.Golden_Path_Mission_Loot_Blacksite_Vial";

	return Template;
}

static function X2DataTemplate CreateStasisSuitComponent()
{
	local X2QuestItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Template, 'StasisSuitComponent');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Forge_Data";
	Template.ItemCat = 'goldenpath';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.HideInLootRecovered = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.MissionType.AddItem("GP_Forge");

	Template.RewardType.AddItem('Reward_None');
	Template.RewardType.AddItem('Reward_Supplies');

	Template.ItemRecoveredAsLootNarrative = "X2NarrativeMoments.Golden_Path_Mission_Loot_Forge_Body";

	return Template;
}

static function X2DataTemplate CreatePsiGateArtifact()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'PsiGateArtifact');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Psi_Gate_Generator";
	Template.ItemCat = 'goldenpath';
	Template.CanBeBuilt = false;
	Template.HideInInventory = false;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	Template.ItemRecoveredAsLootNarrative = "X2NarrativeMoments.Golden_Path_Mission_Loot_Psi_Gate";

	return Template;
}

static function X2DataTemplate CreateTheTruth()
{
	local X2ItemTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'TheTruth');

	Template.ItemCat = 'goldenpath';
	Template.CanBeBuilt = false;
	Template.HideInInventory = true;
	Template.HideInLootRecovered = true;
	Template.bOneTimeBuild = false;
	Template.bBlocked = false;

	return Template;
}

