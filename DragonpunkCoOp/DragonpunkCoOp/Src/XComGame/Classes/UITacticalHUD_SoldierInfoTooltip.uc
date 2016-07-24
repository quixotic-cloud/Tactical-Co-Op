//---------------------------------------------------------------------------------------
 //  FILE:    UITacticalHUD_SoldierInfoTooltip.uc
 //  AUTHOR:  Brit Steiner --  6/2014
 //  PURPOSE: Tooltip for the weapon stats used in the TacticalHUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_SoldierInfoTooltip extends UITooltip;

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;
var int PADDING_BETWEEN_PANELS; 

var int StatsHeight;
var int StatsWidth;

var public UIStatList StatList; 
var public UIPanel BodyArea;
var public UIMask BodyMask;

simulated function UIPanel InitSoldierStats(optional name InitName, optional name InitLibID)
{
	InitPanel(InitName, InitLibID);

	if (`CHEATMGR != none && `CHEATMGR.bDebugXp)
	{
		StatsHeight = default.StatsHeight + 100;
		PADDING_BETWEEN_PANELS = default.PADDING_BETWEEN_PANELS + 100;
	}

	width = StatsWidth; 
	height = StatsHeight + PADDING_BETWEEN_PANELS; 

	Hide();

	// -------------------------

	BodyArea = Spawn(class'UIPanel', self); 
	BodyArea.InitPanel('BodyArea').SetPosition(0, 0);
	BodyArea.width = StatsWidth;
	BodyArea.height = StatsHeight;

	Spawn(class'UIPanel', BodyArea).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(StatsWidth, StatsHeight);
	
	StatList = Spawn(class'UIStatList', BodyArea);
	StatList.InitStatList('StatList',, PADDING_LEFT, PADDING_TOP, StatsWidth-PADDING_RIGHT, BodyArea.height-PADDING_BOTTOM, class'UIStatList'.default.PADDING_LEFT, class'UIStatList'.default.PADDING_RIGHT/2);

	BodyMask = Spawn(class'UIMask', BodyArea).InitMask('Mask', StatList).FitMask(StatList); 

	return self; 
}

simulated function ShowTooltip()
{
	local int ScrollHeight;

	//Trigger only on the correct hover item 
	if( class'UITacticalHUD_BuffsTooltip'.static.IsPathBonusOrPenaltyMC(currentPath) ) return;

	RefreshData();
	
	ScrollHeight = (StatList.height > StatList.height ) ? StatList.height : StatList.height; 
	BodyArea.AnimateScroll( ScrollHeight, BodyMask.height);

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
	
	StatList.RefreshData( GetSoldierStats(kGameStateUnit) );
}


simulated function array<UISummary_ItemStat> GetSoldierStats( XComGameState_Unit kGameStateUnit )
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item; 
	local EUISummary_UnitStats Summary;

	Summary = kGameStateUnit.GetUISummary_UnitStats();

	Item.Label = class'XLocalizedData'.default.HealthLabel; 
	Item.Value = Summary.CurrentHP $"/" $Summary.MaxHP; //TODO: Colorize when below a threshold 
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.AimLabel; 
	Item.Value = string(Summary.Aim); 
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.TechLabel; 
	Item.Value = string(Summary.Tech); 
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.WillLabel; 
	Item.Value = string(Summary.Will); 
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.ArmorLabel;
	Item.Value = string(Summary.Armor);
	Stats.AddItem(Item);

	Item.Label = class'XLocalizedData'.default.DodgeLabel;
	Item.Value = string(Summary.Dodge);
	Stats.AddItem(Item);

	Item.Label = class'XLocalizedData'.default.PsiOffenseLabel; 
	Item.Value = string(Summary.PsiOffense); 
	Stats.AddItem(Item); 

	if (`CHEATMGR != none && `CHEATMGR.bDebugXp)
	{
		Item.Label = class'XLocalizedData'.default.XpLabel;
		Item.Value = string(Summary.Xp);
		Stats.AddItem(Item);

		Item.Label = class'XLocalizedData'.default.XpSharesLabel;
		Item.Value = string(Summary.XpShares);
		Stats.AddItem(Item);

		Item.Label = class'XLocalizedData'.default.XpSquadSharesLabel;
		Item.Value = string(Summary.SquadXpShares);
		Stats.AddItem(Item);

		Item.Label = class'XLocalizedData'.default.XpEarnedPoolLabel;
		Item.Value = string(Summary.EarnedPool);
		Stats.AddItem(Item);
	}

	return Stats;
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	StatsHeight=200;
	StatsWidth=200;

	PADDING_LEFT	= 0;
	PADDING_RIGHT	= 0;
	PADDING_TOP		= 10;
	PADDING_BOTTOM	= 10;
	PADDING_BETWEEN_PANELS = 10;
}