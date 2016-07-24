//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInventoryTactical.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIInventoryTactical extends UIScreen;

//  UI
var UIPanel			m_kRContainer;
var UIList		m_kLootList;

var UIText		    m_kText;

//var UIButton		m_kButton_DumpAll;
//var UIButton		m_kButton_TakeAll;
var UIButton		m_kButton_OK;

var AkEvent                 LootingSound;

var localized string				m_strDumpAll;
var localized string				m_strTakeAll;
var localized string				m_strTitle;

//  GAME DATA
struct LootDisplay
{
	var Lootable                    LootTarget;
	var array<StateObjectReference> LootItems;
	var array<int>					HasBeenLooted;
};

var Lootable                    LootTarget;

var XComGameState               m_NewGameState;		// deprecated
var XComGameState_Unit          m_Looter;
var array<StateObjectReference> m_LooterItems;		// deprecated
var array<LootDisplay>          m_Loots;			// deprecated
var delegate<OnScreenClosed>            ClosedCallback;

delegate OnScreenClosed();

//----------------------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	//------------------------------------------------------------

	m_kRContainer = Spawn(class'UIPanel', self);
	m_kRContainer.InitPanel('RightContainer');

	MC.BeginFunctionOp("SetTitle");
	MC.QueueString( m_strTitle );
	MC.QueueString( m_Looter.GetName(eNameType_RankFull) );
	MC.EndOp();

	m_kLootList = Spawn(class'UIList', m_kRContainer);
	m_kLootList.InitList('ListB', 10, 135, 480, 290); // position list underneath title
	
	m_kButton_OK = Spawn(class'UIButton', m_kRContainer);
	m_kButton_OK.InitButton('BackButton', class'UIUtilities_Text'.default.m_strGenericOK, OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kButton_OK.SetPosition(180, 430); 
	
	UpdateData();
}

simulated function InitLoot(XComGameState_Unit Looter, Lootable LootableObject, delegate<OnScreenClosed> CallbackFn )
{
	ClosedCallback = CallbackFn;
	m_Looter = Looter;
	LootTarget = LootableObject;
}

simulated function OnButtonClicked(UIButton button)
{
	switch( button )
	{
	case m_kButton_OK:
		WorldInfo.PlayAkEvent(LootingSound);
		UpdateData();

		CloseScreen();

		if (ClosedCallback != none)
			ClosedCallback();

		XComPresentationLayer(Movie.Pres).m_kInventoryTactical = none; 
		break;
	}
}

simulated function bool OnCancel(optional string arg = "")
{
	if (ClosedCallback != none)
		ClosedCallback();

	XComPresentationLayer(Movie.Pres).m_kInventoryTactical = none; 
	return true;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		OnButtonClicked(m_kButton_OK);
	}

	return true;
}

simulated function UpdateData()
{
	local int j;
	local XComGameState_Item Item;
	local X2ItemTemplate ItemTemplate;
	local UIInventoryTactical_LootingItem UIItem;
	local string ItemName, Tooltip;
	local XComGameStateHistory History;
	local array<StateObjectReference> LootItems;

	History = `XCOMHISTORY;

	// Update Loot List
	ClearTooltips(m_kLootList);
	m_kLootList.ClearItems();

	LootItems = LootTarget.GetAvailableLoot();

	MC.FunctionString("SetHeader", LootTarget.GetLootingName());

	for (j = 0; j < LootItems.Length; ++j)
	{
		Item = XComGameState_Item(History.GetGameStateForObjectID(LootItems[j].ObjectID));
		ItemTemplate = Item.GetMyTemplate();

		UIItem = Spawn(class'UIInventoryTactical_LootingItem', m_kLootList.ItemContainer).InitLootItem(true);
		ItemName = ItemTemplate.GetItemFriendlyName();
		if (Item.Quantity > 1)
			ItemName @= "x" $ string(Item.Quantity);

		Tooltip = ItemTemplate.GetItemLootTooltip();
		if( Tooltip != "" )
			UIItem.SetText(ItemName, Tooltip);
		else
			UIItem.SetText(ItemName, ItemTemplate.GetItemBriefSummary(Item.ObjectID));

		UIItem.GameStateObjectID = Item.ObjectID;
	}
}

function ClearTooltips( UIList list )
{
	local int i;
	local UIInventoryTactical_LootingItem UIItem;
	for (i = 0; i < list.ItemCount; ++i)
	{
		UIItem = UIInventoryTactical_LootingItem(list.GetItem(i));
		if (UIItem != none)
			Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(UIItem.MCPath));
	}
}

function bool IsLoot(UIInventoryTactical_LootingItem item)
{
	return m_kLootList.GetItemIndex(item) != -1;
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxLootingUI/LootingUI";
	InputState = eInputState_Consume;
	LootingSound = AkEvent'SoundTacticalUI.TacticalUI_Looting'
	bConsumeMouseEvents = true;
	bShowDuringCinematic = true; // hacking animation is considered a cinematic, so make sure not to hide this during cinematics
}
