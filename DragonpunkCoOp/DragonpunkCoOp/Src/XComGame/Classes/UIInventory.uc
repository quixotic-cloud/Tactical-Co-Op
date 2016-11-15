//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInventory.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Base class for Trading Post, Reverse Engineering, and Build Item screens.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIInventory extends UIScreen;

var localized string m_strTitle;
var localized string m_strSubTitleTitle;
var localized string m_strConfirmButtonLabel;
var localized string m_strInventoryLabel;
var localized string m_strSellLabel;
var localized string m_strTotalLabel;
var localized string m_strEmptyListTitle;

var UIX2PanelHeader TitleHeader;

var UIItemCard ItemCard;

var UIPanel ListContainer; // contains all controls bellow
var UIList List;
var UIPanel ListBG;

var XComGameStateHistory History;
var XComGameState_HeadquartersXCom XComHQ;

var name DisplayTag;
var name CameraTag;

var name InventoryListName;

//Flag for type of info to fill in right info card. 
var bool bSelectFirstAvailable; 
var bool bUseSimpleCard; 

// Set this to specify how long camera transition should take for this screen
var float OverrideInterpTime;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);

	BuildScreen();
	UpdateNavHelp();
}

simulated function BuildScreen()
{
	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	TitleHeader.InitPanelHeader('TitleHeader', m_strTitle, m_strSubTitleTitle);
	TitleHeader.SetHeaderWidth( 580 );
	if( m_strTitle == "" && m_strSubTitleTitle == "" )
		TitleHeader.Hide();

	ListContainer = Spawn(class'UIPanel', self).InitPanel('InventoryContainer');

	ItemCard = Spawn(class'UIItemCard', ListContainer).InitItemCard('ItemCard');

	ListBG = Spawn(class'UIPanel', ListContainer);
	ListBG.InitPanel('InventoryListBG'); 
	ListBG.bShouldPlayGenericUIAudioEvents = false;
	ListBG.Show();

	List = Spawn(class'UIList', ListContainer);
	List.InitList(InventoryListName);
	List.bSelectFirstAvailable = bSelectFirstAvailable;
	List.bStickyHighlight = true;
	List.OnSelectionChanged = SelectedItemChanged;
	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);

	SetCategory(m_strInventoryLabel);
	SetBuiltLabel(m_strTotalLabel);

	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	if( bIsIn3D )
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, OverrideInterpTime != -1 ? OverrideInterpTime : `HQINTERPTIME);
}

simulated function PopulateData()
{
	// override behavior in child classes
	List.ClearItems();
	PopulateItemCard();

	if( List.ItemCount == 0 && m_strEmptyListTitle  != "" )
	{
		TitleHeader.SetText(m_strTitle, m_strEmptyListTitle);
		SetCategory("");
	}
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIInventory_ListItem ListItem;
	ListItem = UIInventory_ListItem(ContainerList.GetItem(ItemIndex));
	if(ListItem != none)
	{
		if(ListItem.ItemTemplate != none)
		{
			PopulateItemCard(ListItem.ItemTemplate, ListItem.ItemRef);
		}
		else if( bUseSimpleCard )
		{
			PopulateSimpleCommodityCard(ListItem.ItemComodity, ListItem.ItemRef);
		}
		else
		{
			PopulateResearchCard(ListItem.ItemComodity, ListItem.ItemRef);
		}
	}
}

simulated function PopulateItemCard(optional X2ItemTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	if( ItemCard != none )
	{
		if( ItemTemplate != None )
		{
			ItemCard.PopulateItemCard(ItemTemplate, ItemRef);
			ItemCard.Show();
		}
		else
			ItemCard.Hide();
	}
}

simulated function PopulateResearchCard(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
	ItemCard.PopulateResearchCard(ItemCommodity, ItemRef);
	ItemCard.Show();
}

simulated function PopulateSimpleCommodityCard(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
	ItemCard.PopulateSimpleCommodityCard(ItemCommodity, ItemRef);
	ItemCard.Show();
}

simulated function HideQueue()
{
	local UIScreen QueueScreen;
	
	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_Storage');
	if( QueueScreen != None )
		UIFacility_Storage(QueueScreen).Hide();
}

simulated function ShowQueue(optional bool bRefreshQueue = false)
{
	local UIScreen QueueScreen;
	
	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_Storage');
	if( QueueScreen != None )
	{
		if(bRefreshQueue)
		{
			//UIFacility_Storage(QueueScreen).UpdateBuildQueue();
		}
		UIFacility_Storage(QueueScreen).Show();
	}
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(CloseScreen);
	if(`ISCONTROLLERACTIVE)
		NavHelp.AddSelectNavHelp();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			`HQPRES.UIPauseMenu( ,true );
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

// -1 will hide the highlight.
simulated function SetTabHighlight(int TabIndex)
{
	MC.BeginFunctionOp("setTabHighlight");
	MC.QueueNumber(TabIndex);
	MC.EndOp();
}

simulated function SetCategory(string Category)
{
	MC.BeginFunctionOp("setItemCategory");
	MC.QueueString(Category);
	MC.EndOp();
}

simulated function SetBuiltLabel(string Label)
{
	MC.BeginFunctionOp("setBuiltLabel");
	MC.QueueString(Label);
	MC.EndOp();
}

simulated function SetBuildItemLayout()
{
	MC.FunctionVoid( "setBuildItemLayout" );
}

simulated function SetChooseResearchLayout()
{
	MC.FunctionVoid( "setChooseResearchLayout" );
}

simulated function SetInventoryLayout()
{
	MC.FunctionVoid( "setInventoryLayout" );
}

simulated function SetBlackMarketLayout()
{
	MC.FunctionVoid( "setBlackMarketLayout" );
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	if(bIsIn3D)
		UIMovie_3D(Movie).HideDisplay(DisplayTag);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
	if(bIsIn3D)
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, `HQINTERPTIME);
}

simulated function PlaySFX(String Sound)
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent(Sound);
}

simulated function XComGameState_HeadquartersResistance RESHQ()
{
	return class'UIUtilities_Strategy'.static.GetResistanceHQ();
}

simulated function XComGameState_HeadquartersAlien ALIENHQ()
{
	return class'UIUtilities_Strategy'.static.GetAlienHQ();
}

simulated function XComGameState_BlackMarket BLACKMARKET()
{
	return class'UIUtilities_Strategy'.static.GetBlackMarket();
}

simulated function OnCancel()
{
	CloseScreen();
	if(bIsIn3D)
		UIMovie_3D(Movie).HideDisplay(DisplayTag);
}

defaultproperties
{
	Package = "/ package/gfxInventory/Inventory";

	InventoryListName="inventoryListMC";
	bUseSimpleCard = false;	
	bAnimateOnInit = true;
	bSelectFirstAvailable = true;

	OverrideInterpTime = -1;
}