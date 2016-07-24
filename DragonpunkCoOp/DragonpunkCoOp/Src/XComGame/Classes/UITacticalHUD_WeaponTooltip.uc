//---------------------------------------------------------------------------------------
 //  FILE:    UITacticalHUD_WeaponTooltip.uc
 //  AUTHOR:  Brit Steiner --  6/2014
 //  PURPOSE: Tooltip for the weapon stats used in the TacticalHUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_WeaponTooltip extends UITooltip;

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;
var int CENTER_PADDING;

var float BodyAreaHeight; 

var public UIPanel Container;
var UIScrollingText TitleControl;
var public UIPanel BodyArea;
var public UIMask BodyMask;

var public UITooltipInfoList AmmoInfoList;
var public UITooltipInfoList UpgradeInfoList;

simulated function UIPanel InitWeaponStats(optional name InitName, optional name InitLibID)
{
	local UIPanel Line; 

	InitPanel(InitName, InitLibID);

	Hide();
	
	Container = Spawn(class'UIPanel', self).InitPanel();
	Container.Width = Width; // Saved for positioning. 
	Spawn(class'UIPanel', Container).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(width, BodyAreaHeight);

	TitleControl = Spawn(class'UIScrollingText', Container);
	TitleControl.InitScrollingText('ScrollingText', "", width - PADDING_LEFT - PADDING_RIGHT, PADDING_LEFT, PADDING_TOP); 
	
	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( TitleControl );
	
	BodyArea = Spawn(class'UIPanel', Container);
	BodyArea.InitPanel('BodyArea').SetPosition(0, Line.Y + 4).SetSize(width, BodyAreaHeight - Line.Y - 6);  // 6to give it a little breathing room away from the line

	BodyMask = Spawn(class'UIMask', Container).InitMask('Mask', BodyArea).FitMask(BodyArea);

	AmmoInfoList = Spawn(class'UITooltipInfoList', Container).InitTooltipInfoList('AmmoPanelInfoList',,,, Width, OnChildPanelSizeRealized);
	UpgradeInfoList = Spawn(class'UITooltipInfoList', Container).InitTooltipInfoList('UpgradePanelInfoList',,,, Width, OnChildPanelSizeRealized);

	return self; 
}

simulated function ShowTooltip()
{	
	RefreshData();
	TitleControl.ResetScroll();
	
	super.ShowTooltip();
}


simulated function HideTooltip( optional bool bAnimateIfPossible = false )
{
	super.HideTooltip(bAnimateIfPossible);
	BodyArea.ClearScroll();
}

simulated function RefreshData()
{
	local XGUnit				kActiveUnit;
	local XComGameState_Unit	kGameStateUnit;
	local XComGameState_Item	kPrimaryWeapon;
	
	if(XComTacticalController(PC) == None)
	{	
		TitleControl.SetSubTitle(class'UIUtilities_Text'.static.StyleText( "DEBUGGING TEST", eUITextStyle_Tooltip_Title));
		AmmoInfoList.RefreshData(DEBUG_GetAmmo());
		UpgradeInfoList.RefreshData(DEBUG_GetUpgrades());
		return; 
	}

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
	
		kPrimaryWeapon = kGameStateUnit.GetPrimaryWeapon();
	}
	
	TitleControl.SetSubTitle(class'UIUtilities_Text'.static.StyleText(kPrimaryWeapon.GetMyTemplate().GetItemFriendlyName(kPrimaryWeapon.ObjectID), eUITextStyle_Tooltip_Title));

	AmmoInfoList.RefreshData(kPrimaryWeapon.GetUISummary_AmmoStats());
	UpgradeInfoList.RefreshData(kPrimaryWeapon.GetUISummary_ItemSecondaryStats());

	//At least one call, because sub elements may not have contents.
	OnChildPanelSizeRealized();
}

simulated function OnChildPanelSizeRealized()
{
	AmmoInfoList.SetY(BodyArea.Y + BodyArea.Height + 4);
	UpgradeInfoList.SetY(AmmoInfoList.Y + AmmoInfoList.Height + 4);

	Container.Height = UpgradeInfoList.Y + UpgradeInfoList.Height;
	Container.SetPosition(-Container.Width, -Container.Height); //Bottom right anchored area in this tooltip.
}

simulated function array<UISummary_ItemStat> DEBUG_GetStats()
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item;

	Item.Label = class'XLocalizedData'.default.DamageLabel; 
	Item.Value = "+99";
	Item.ValueState = eUIState_Good;
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.CritLabel;
	Item.Value = "99";
	Item.ValueState = eUIState_Normal;
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.AimLabel; 
	Item.Value = "+99";
	Item.ValueState = eUIState_Good;
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.ClipSizeLabel; 
	Item.Value = "99";
	Item.ValueState = eUIState_Normal;
	Stats.AddItem(Item); 

	return Stats;
}

simulated function array<UISummary_ItemStat> DEBUG_GetUpgrades()
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item; 
	local int iUpgrade; 
		
	Item.Label = class'XLocalizedData'.default.UpgradesHeader;
	Item.LabelStyle = eUITextStyle_Tooltip_H1;  
	Stats.AddItem(Item); 

	for( iUpgrade = 0; iUpgrade < 2; iUpgrade++ )
	{
		Item.Label = "Sample Silencer " $ iUpgrade;
		Item.LabelStyle = eUITextStyle_Tooltip_H2; 
		Item.Value = "No alert increase.";
		Item.ValueStyle = eUITextStyle_Tooltip_Body; 
		Stats.AddItem(Item);
	}


	return Stats;
}

simulated function array<UISummary_ItemStat> DEBUG_GetAmmo()
{
	local array<UISummary_ItemStat> Stats;
	local UISummary_ItemStat Item;
	local int iAmmo;

	Item.Label = class'XLocalizedData'.default.AmmoTypeLabel;
	Item.LabelStyle = eUITextStyle_Tooltip_H1;
	Stats.AddItem(Item);

	for( iAmmo = 0; iAmmo < 2; iAmmo++ )
	{
		Item.Label = "Sample Ammo " $ iAmmo;
		Item.LabelStyle = eUITextStyle_Tooltip_H2;
		Item.Value = "Special ammo description of this ammo that is in the weapon.";
		Item.ValueStyle = eUITextStyle_Tooltip_Body;
		Stats.AddItem(Item);
	}


	return Stats;
}


//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	BodyAreaHeight = 50;
	Width = 350;

	PADDING_LEFT	= 14;
	PADDING_RIGHT	= 14;
	PADDING_TOP		= 10;
	PADDING_BOTTOM	= 10;
}