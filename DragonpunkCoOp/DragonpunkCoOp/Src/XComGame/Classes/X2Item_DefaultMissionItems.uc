class X2Item_DefaultMissionItems extends X2Item;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;

	Items.AddItem(CreateGatherEvidenceDevice());
	Items.AddItem(CreateExplosiveMissionDevice());
	Items.AddItem(CreateAdvancedExplosiveMissionDevice());
	Items.AddItem(CreateSpyDevice());

	return Items;
}

static function X2DataTemplate CreateGatherEvidenceDevice()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'GatherEvidenceDevice');
	Template.CanBeBuilt = false;
	Template.StartingItem = true;
	Template.bInfiniteItem = true;
	Template.HideInInventory = true;
	Template.HideInLootRecovered = true;

	Template.InventorySlot = eInvSlot_Mission;
	Template.ItemCat = 'mission';
	Template.Abilities.AddItem('GatherEvidence');
	Template.strBackpackIcon = "img:///UILibrary_Common.holoscanner_icon";

	return Template;
}

static function X2DataTemplate CreateExplosiveMissionDevice()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'ExplosiveMissionDevice');
	Template.CanBeBuilt = false;
	Template.StartingItem = true;
	Template.bInfiniteItem = true;
	Template.HideInInventory = true;
	Template.HideInLootRecovered = true;

	Template.InventorySlot = eInvSlot_Mission;
	Template.ItemCat = 'mission';
	Template.Abilities.AddItem('PlantExplosiveMissionDevice');
	Template.strBackpackIcon = "img:///UILibrary_Common.x4_icon";

	return Template;
}

static function X2DataTemplate CreateAdvancedExplosiveMissionDevice()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AdvancedExplosiveMissionDevice');
	Template.CanBeBuilt = false;
	Template.StartingItem = true;
	Template.bInfiniteItem = true;
	Template.HideInInventory = true;
	Template.HideInLootRecovered = true;

	Template.InventorySlot = eInvSlot_Mission;
	Template.ItemCat = 'mission';

	Template.Abilities.AddItem('PlantExplosiveMissionDevice');
	Template.Abilities.AddItem('ExplosiveDeviceDetonate');
	Template.strBackpackIcon = "img:///UILibrary_Common.x4_icon";

	return Template;
}

static function X2DataTemplate CreateSpyDevice()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'SpyDevice');
	Template.CanBeBuilt = false;
	Template.StartingItem = true;
	Template.bInfiniteItem = true;
	Template.HideInInventory = true;
	Template.HideInLootRecovered = true;

	Template.InventorySlot = eInvSlot_Mission;
	Template.ItemCat = 'mission';
	Template.strBackpackIcon = "img:///UILibrary_Common.holoscanner_icon";

	return Template;
}