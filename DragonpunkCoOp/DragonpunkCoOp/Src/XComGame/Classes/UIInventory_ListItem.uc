//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInventory_ListItem.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIPanel representing a list entry on UIInventory_Manufacture screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIInventory_ListItem extends UIListItemString;

var int Quantity;
var X2ItemTemplate ItemTemplate;
var Commodity ItemComodity;
var StateObjectReference ItemRef;
var X2EncyclopediaTemplate XComDatabaseEntry;

simulated function UIInventory_ListItem InitInventoryListItem(X2ItemTemplate InitTemplate, 
															  int InitQuantity, 
															  optional StateObjectReference InitItemRef, 
															  optional string Confirm, 
															  optional EUIConfirmButtonStyle InitConfirmButtonStyle = eUIConfirmButtonStyle_Default,
															  optional int InitRightCol,
															  optional int InitHeight)
{
	// Set data before calling super, so that it's available in the initialization. 
	ItemTemplate = InitTemplate;
	Quantity = InitQuantity;
	ItemRef = InitItemRef;
	ConfirmButtonStyle = InitConfirmButtonStyle;

	InitListItem();

	SetConfirmButtonStyle(ConfirmButtonStyle, Confirm, InitRightCol, InitHeight,, OnDoubleclickConfirmButton);

	//Create all of the children before realizing, to be sure they can receive info. 
	RealizeDisabledState();
	RealizeBadState();
	RealizeAttentionState();
	RealizeGoodState();

	return self;
}

simulated function InitInventoryListCommodity(Commodity initCommodity, 
											  optional StateObjectReference InitItemRef, 
											  optional string Confirm, 
											  optional EUIConfirmButtonStyle InitConfirmButtonStyle = eUIConfirmButtonStyle_Default,
											  optional int InitRightCol,
											  optional int InitHeight)
{
	// Set data before calling super, so that it's available in the initialization. 
	ItemComodity = initCommodity;
	Quantity = 0;
	ItemRef = InitItemRef;
	ConfirmButtonStyle = InitConfirmButtonStyle;

	InitListItem();

	SetConfirmButtonStyle(ConfirmButtonStyle, Confirm, InitRightCol, InitHeight,, OnDoubleclickConfirmButton);

	//Create all of the children before realizing, to be sure they can receive info. 
	RealizeDisabledState();
	RealizeBadState();
	RealizeAttentionState();
	RealizeGoodState();
}

simulated function InitInventoryListXComDatabase(X2EncyclopediaTemplate EntryTemplate)
{
	// Set data before calling super, so that it's available in the initialization. 
	XComDatabaseEntry = EntryTemplate;

	InitListItem();
	
	//Create all of the children before realizing, to be sure they can receive info. 
	RealizeDisabledState();
	RealizeBadState();
	RealizeAttentionState();
	RealizeGoodState();
}

simulated function OnInit()
{
	super.OnInit();	
	PopulateData();
}

// Set bDisabled variable
simulated function RealizeDisabledState()
{
	local bool bIsDisabled;
	local UISimpleCommodityScreen CommScreen;
	local int CommodityIndex;

	if(ClassIsChildOf(Screen.Class, class'UISimpleCommodityScreen'))
	{
		CommScreen = UISimpleCommodityScreen(Screen);
		CommodityIndex = CommScreen.GetItemIndex(ItemComodity);
		bIsDisabled = !CommScreen.MeetsItemReqs(CommodityIndex) || CommScreen.IsItemPurchased(CommodityIndex);
	}

	SetDisabled(bIsDisabled);
}

simulated function RealizeGoodState()
{
	local UISimpleCommodityScreen CommScreen;
	local int CommodityIndex;

	if( ClassIsChildOf(Screen.Class, class'UISimpleCommodityScreen') )
	{
		CommScreen = UISimpleCommodityScreen(Screen);
		CommodityIndex = CommScreen.GetItemIndex(ItemComodity);
		ShouldShowGoodState(CommScreen.ShouldShowGoodState(CommodityIndex));
	}
}

// Set bBad variable
simulated function RealizeBadState()
{
	local bool bBad;
	local UISimpleCommodityScreen CommScreen;
	local int CommodityIndex;

	switch( Screen.Class )
	{
	case class'UIInventory_BuildItems':
		bBad = !UIInventory_BuildItems(Screen).CanBuildItem(ItemTemplate);
		break;
	case class'UIInventory_Implants':
		bBad = !UIInventory_Implants(Screen).CanEquipImplant(ItemRef);
		break;
	}

	if( ClassIsChildOf(Screen.Class, class'UISimpleCommodityScreen') )
	{
		CommScreen = UISimpleCommodityScreen(Screen);
		CommodityIndex = CommScreen.GetItemIndex(ItemComodity);
		bBad = !CommScreen.CanAffordItem(CommodityIndex);
	}

	SetBad(bBad);
}

simulated function RealizeAttentionState()
{
	local UISimpleCommodityScreen CommScreen;
	local int CommodityIndex;

	if( ClassIsChildOf(Screen.Class, class'UISimpleCommodityScreen') )
	{
		CommScreen = UISimpleCommodityScreen(Screen);
		CommodityIndex = CommScreen.GetItemIndex(ItemComodity);
		NeedsAttention( CommScreen.NeedsAttention(CommodityIndex), UseObjectiveIcon() );
	}
}

simulated function bool UseObjectiveIcon()
{
	if( ClassIsChildOf(Screen.Class, class'UIChooseResearch') )
		return true;

	return false;
}

simulated function NeedsAttention( bool bNeedsAttention , optional bool bIsObjective = false )
{
	super.NeedsAttention(bNeedsAttention, bIsObjective);
	if( AttentionIcon != none )
		AttentionIcon.SetPosition(4,4);
}

simulated function UIListItemString SetBad(bool isBad, optional string TooltipText)
{
	ButtonBG.SetBad(bIsBad, TooltipText);
	super.SetBad(isBad, TooltipText);
	return self;
}

simulated function UpdateQuantity(int NewQuantity)
{
	Quantity = NewQuantity;
}

simulated function PopulateData(optional bool bRealizeDisabled)
{
	local string ItemQuantity; 
	
	if(Quantity > 0)
		ItemQuantity = GetColoredText(string(Quantity));
	else
		ItemQuantity = GetColoredText("-");

	MC.BeginFunctionOp("populateData");
	if(Screen.Class == class'UIInventory_BuildItems' && ItemTemplate.bPriority)
	{
		MC.QueueString(GetColoredText(ItemTemplate.GetItemFriendlyName(ItemRef.ObjectID) $ class'UIUtilities_Text'.default.m_strPriority));
	}
	else if( Screen.Class == class'UIInventory_XComDatabase' )
	{
		MC.QueueString(XComDatabaseEntry.GetListTitle());
		ItemQuantity = "";
	}
	else if(!ClassIsChildOf(Screen.Class, class'UISimpleCommodityScreen'))
	{
		MC.QueueString(GetColoredText(ItemTemplate.GetItemFriendlyName(ItemRef.ObjectID)));
	}
	else
	{
		MC.QueueString(GetColoredText(ItemComodity.Title));
		ItemQuantity = GetColoredText("");
	}
	
	MC.QueueString(ItemQuantity);
	
	MC.EndOp();

	//---------------

	if(bRealizeDisabled)
		RealizeDisabledState();

	RealizeBadState();

	//Button.SetDisabled(bIsDisabled);
	//ConfirmButton.SetDisabled(bIsDisabled);
}

simulated function string GetColoredText(string Txt, optional int FontSize = 24)
{
	local int uiState;
	
	uiState = eUIState_Normal;

	/*if (bDisabled)
	{
		if (ClassIsChildOf(Screen.Class, class'UISimpleCommodityScreen'))
			uiState = eUIState_Bad;
		else if (Screen.Class == class'UIInventory_Implants')
			uiState = eUIState_Disabled;
	}
	else */if(Screen.Class == class'UIInventory_BuildItems' && ItemTemplate.bPriority)
		uiState = eUIState_Warning;

	if( uiState == eUIState_Normal )
		return class'UIUtilities_Text'.static.GetSizedText(Txt, FontSize);
	else
		return class'UIUtilities_Text'.static.GetColoredText(Txt, uiState, FontSize);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnDoubleclickConfirmButton(UIButton Button)
{
	// do nothing
}

defaultproperties
{
	width = 700;
	LibID = "InventoryItem";
	bDisabled = false;
	bCascadeFocus = false;
	ConfirmButtonStyle = eUIConfirmButtonStyle_Default;
}
