class X2Item_SoldierKit extends X2Item;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;

	Items.AddItem(CreateSoldierKit());
	
	return Items;
}

static function X2ItemTemplate CreateSoldierKit()
{
	local X2EquipmentTemplate    Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'SoldierKit');
	Template.InventorySlot = eInvSlot_Backpack;
	Template.ItemCat = 'utility';

	return Template;
}