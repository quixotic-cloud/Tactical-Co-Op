
class UIInventory_Storage extends UIInventory;

var localized string m_strNoLoot;
var localized string m_strBuy; 

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	List.SetHeight(680);

	PopulateData();
	List.SetSelectedIndex(0, true);
	SetInventoryLayout();
	SetX(500);

	HideQueue();
}

simulated function CloseScreen()
{
	Super.CloseScreen();

	ShowQueue();
}

simulated function PopulateData()
{
	local XComGameState_Item Item;
	local X2ItemTemplate ItemTemplate;
	local StateObjectReference ItemRef;
	local UIInventory_ListItem ListItem;
	local array<XComGameState_Item> InventoryItems;

	super.PopulateData();

	foreach XComHQ.Inventory(ItemRef)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
		if (Item == None || Item.GetMyTemplate() == None)
			continue;

		ItemTemplate = Item.GetMyTemplate();
		if((Item.HasBeenModified() || !ItemTemplate.bInfiniteItem) && !ItemTemplate.HideInInventory && 
			!XComHQ.IsTechResearched(ItemTemplate.HideIfResearched) && !XComHQ.HasItemByName(ItemTemplate.HideIfPurchased))
		{
			InventoryItems.AddItem(Item);
		}
	}

	InventoryItems.Sort(SortItemsAlpha);

	foreach InventoryItems(Item)
	{
		Spawn(class'UIInventory_ListItem', List.itemContainer).InitInventoryListItem(Item.GetMyTemplate(), Item.Quantity, Item.GetReference());
	}
	
	if(List.ItemCount > 0)
	{
		TitleHeader.SetText(m_strTitle, "");
		ListItem = UIInventory_ListItem(List.GetItem(0));
		PopulateItemCard(ListItem.ItemTemplate, ListItem.ItemRef);
	}
	else
	{
		TitleHeader.SetText(m_strTitle, m_strNoLoot);
		SetCategory("");
		SetBuiltLabel("");
	}
}

function int SortItemsAlpha(XComGameState_Item ItemA, XComGameState_Item ItemB)
{
	local X2ItemTemplate ItemTemplateA, ItemTemplateB;

	ItemTemplateA = ItemA.GetMyTemplate();
	ItemTemplateB = ItemB.GetMyTemplate();

	if (ItemTemplateA.GetItemFriendlyName() < ItemTemplateB.GetItemFriendlyName())
	{
		return 1;
	}
	else if (ItemTemplateA.GetItemFriendlyName() > ItemTemplateB.GetItemFriendlyName())
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

defaultproperties
{
	DisplayTag      = "UIBlueprint_BuildItems";
	CameraTag       = "UIBlueprint_BuildItems";
}