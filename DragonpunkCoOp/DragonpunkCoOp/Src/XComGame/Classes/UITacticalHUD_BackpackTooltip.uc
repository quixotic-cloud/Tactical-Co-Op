//---------------------------------------------------------------------------------------
 //  FILE:    UITacticalHUD_BackpackTooltip.uc
 //  AUTHOR:  Sam Batista --  1/2015
 //  PURPOSE: Tooltip for the backpack stats used in the TacticalHUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_BackpackTooltip extends UITooltip;

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;
var int PADDING_BETWEEN_PANELS;

var public UIStatList BackpackList; 
var public UIPanel BackpackArea;
var public UIMask BackpackMask;
var public UIPanel BackpackBG; 

simulated function UIPanel InitBackpackTooltip(optional name InitName, optional name InitLibID)
{
	InitPanel(InitName, InitLibID);

	Hide();

	// -------------------------
		
	BackpackArea = Spawn(class'UIPanel', self); 
	BackpackArea.InitPanel('BackpackArea').SetPosition(0, 0 + Height + PADDING_BETWEEN_PANELS);
	BackpackArea.width = Width; 
	BackpackArea.height = Height;

	BackpackBG = Spawn(class'UIPanel', BackpackArea).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(Width, Height);

	BackpackList = Spawn(class'UIStatList', BackpackArea);
	BackpackList.InitStatList('StatListLeft',, PADDING_LEFT, PADDING_TOP, Width-PADDING_RIGHT, BackpackArea.height-PADDING_BOTTOM, class'UIStatList'.default.PADDING_LEFT, class'UIStatList'.default.PADDING_RIGHT/2);

	BackpackMask = Spawn(class'UIMask', BackpackArea).InitMask('Mask', BackpackList).FitMask(BackpackList); 

	return self; 
}

simulated function ShowTooltip()
{
	RefreshData();
	super.ShowTooltip();
}

simulated function RefreshData()
{
	local XGUnit				kActiveUnit;
	local XComGameState_Unit	kGameStateUnit;
	local array<UISummary_ItemStat> BackpackItems; 
	
	// Only update if new unit
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();

	if( kActiveUnit == none )
	{
		HideTooltip();
		return; 
	} 
	else if( kActiveUnit != none )
	{
		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	}

	BackpackItems = GetBackpackList(kGameStateUnit); 

	if( BackpackItems.length == 0 )
		BackpackBG.Hide();
	else
		BackpackBG.Show();

	BackpackList.RefreshData( BackpackItems ); 
}

simulated function array<UISummary_ItemStat> GetBackpackList( XComGameState_Unit kGameStateUnit )
{
	local array<UISummary_ItemStat> ItemList; 
	local UISummary_ItemStat Item; 
	local array<XComGameState_Item> BackpackItems; 
	local int i; 
	local XComGameState_Item kBackpackItem, kArmorItem; 

	// --------------------------------------
	// First, if we don't have a backpack: 
	if( !kGameStateUnit.HasBackpack() )
	{
		// --------------------------------------
		kArmorItem = kGameStateUnit.GetItemInSlot(eInvSlot_Armor); 
		if( kArmorItem.AllowsHeavyWeapon() )
		{
			// Soldier doesn't have a backpack because soldier is wearing heavy armor.

			Item.Label = class'XLocalizedData'.default.WearingHeavyArmorLabel; 
			Item.Value = "";
			ItemList.AddItem(Item); 
			
			return ItemList;
		}

		// --------------------------------------
		//Soldier may not have a backpack at all, and no special case from above, in which case, show nothing at all. 
		return ItemList; 
	}

	// --------------------------------------

	BackpackItems = kGameStateUnit.GetAllItemsInSlot(eInvSlot_Backpack);

	// We do have a backpack, so label it: 
	Item.Label = class'XLocalizedData'.default.BackpackLabel; 
	Item.Value = "";
	ItemList.AddItem(Item); 

	if( BackpackItems.length == 0 )
	{
		// So we do have a backpack here, but it's empty. 

		Item.Label = class'XLocalizedData'.default.BackpackEmptyLabel; 
		Item.Value = "";
		ItemList.AddItem(Item); 

		return ItemList; 
	}

	// --------------------------------------
	// Backpack is not empty, so show all contained items: 	
	for( i = 0; i < BackpackItems.length; i++ )
	{
		kBackpackItem = BackpackItems[i];

		Item.Label = kBackpackItem.GetMyTemplate().GetItemFriendlyName(); 
		Item.Value = " ";
		if (kBackpackItem.Quantity > 1)
			Item.Value = "x" $ kBackpackItem.Quantity;
		ItemList.AddItem(Item); 
	}
	return ItemList; 
}


//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	Width = 200;
	Height = 200;

	PADDING_LEFT	= 0;
	PADDING_RIGHT	= 0;
	PADDING_TOP		= 10;
	PADDING_BOTTOM	= 10;
	PADDING_BETWEEN_PANELS = 10;
}