//---------------------------------------------------------------------------------------
 //  FILE:    UITacticalHUD_EnemyTooltip.uc
 //  AUTHOR:  Brit Steiner --  6/2014
 //  PURPOSE: Tooltip for the enemy stats used in the TacticalHUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_EnemyTooltip extends UITooltip;

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;
var int PaddingBetweenBoxes; 
var int PaddingForAbilityList;

var int StatsHeight;
var int AbilitiesHeight; 

var UIStatList		StatList; 
var UIPanel				BodyArea;

//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
//var private UIAbilityList	AbilityList; 
var UIPanel				AbilityArea;
var UIText			Title; 
var UIPanel				Line; 

simulated function UIPanel InitEnemyStats(optional name InitName, optional name InitLibID)
{
	InitPanel(InitName, InitLibID);

	Hide();

	// --------------------

	BodyArea = Spawn(class'UIPanel', self); 
	BodyArea.InitPanel('BodyArea').SetPosition(0, 0);
	BodyArea.width = width;
	BodyArea.height = StatsHeight;

	Spawn(class'UIPanel', BodyArea).InitPanel('BGBoxSimpleStats', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(BodyArea.width, BodyArea.height);

	StatList = Spawn(class'UIStatList', BodyArea);
	StatList.InitStatList('StatListLeft',
		, 
		0, 
		0, 
		BodyArea.width, 
		BodyArea.height);

	Spawn(class'UIMask', self).InitMask('StatMask', StatList).FitMask(StatList); 

	// --------------------
	//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
	/*
	AbilityArea = Spawn(class'UIPanel', self); 
	AbilityArea.InitPanel('AbilityArea').SetPosition(0, BodyArea.height+ PaddingBetweenBoxes);
	AbilityArea.width = width;
	AbilityArea.height = AbilitiesHeight;
	
	Spawn(class'UIPanel', AbilityArea).InitPanel('BGBoxSimplAbilities', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetPosition(0, 0).SetSize(AbilityArea.width, AbilityArea.height);
	
	Title = Spawn(class'UIText', AbilityArea).InitText('Title');
	Title.SetPosition(PADDING_LEFT, PADDING_TOP); 
	Title.SetSize(width - PADDING_LEFT - PADDING_RIGHT, 32); 
	//Title.SetAlpha( class'UIUtilities_Text'.static.GetStyle(eUITextStyle_Tooltip_StatLabel).Alpha );
	Title.SetHTMLText( class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.AbilityListHeader, eUITextStyle_Tooltip_StatLabel) );

	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( Title );

	
	AbilityList = Spawn(class'UIAbilityList', AbilityArea);
	AbilityList.InitAbilityList('AbilityList',
		, 
		PADDING_LEFT, 
		Line.Y + PaddingForAbilityList, 
		AbilityArea.width-PADDING_LEFT-PADDING_RIGHT, 
		AbilityArea.height-Line.Y-PaddingForAbilityList-PADDING_BOTTOM,
		AbilityArea.height-Line.Y-PADDING_BOTTOM);

	Spawn(class'UIMask', AbilityArea).InitMask('AbilityMask', AbilityList).FitMask(AbilityList); 
	*/
	// --------------------

	//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
	//height = BodyArea.Y + BodyArea.height + PaddingBetweenBoxes + AbilityArea.height;
	height = BodyArea.Y + BodyArea.height;

	return self; 
}

simulated function ShowTooltip()
{
	local int ScrollHeight;

	if (RefreshData())
	{
		ScrollHeight = (StatList.height > StatList.height) ? StatList.height : StatList.height;
		BodyArea.AnimateScroll(ScrollHeight, StatsHeight);

		//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
		//AbilityList.Show(); 

		if (TooltipGroup != none && !bIsVisible)
		{
			//Notify the tooltip group if this panel is becoming visible.
			TooltipGroup.SignalNotify();
		}

		super.ShowTooltip();
	}
}


simulated function HideTooltip( optional bool bAnimateIfPossible = false )
{
	super.HideTooltip(bAnimateIfPossible);
	BodyArea.ClearScroll();
}

simulated function bool RefreshData()
{
	local XGUnit				ActiveUnit;
	local XComGameState_Unit	GameStateUnit;
	local int					iTargetIndex;
	local array<string>			Path;

	if( XComTacticalController(PC) == None )
	{
		StatList.RefreshData( DEBUG_GetStats() );
		//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
		//AbilityList.RefreshData( DEBUG_GetUISummary_Abilities() );
		return true;
	}
	
	Path = SplitString(currentPath, ".");
	iTargetIndex = int(Split(Path[5], "icon", true));
	ActiveUnit = XGUnit(XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.GetEnemyAtIcon(iTargetIndex));

	if( ActiveUnit == none )
	{
		HideTooltip();
		return false; 
	} 
	else if( ActiveUnit != none )
	{
		GameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.ObjectID));
	}
	
	StatList.RefreshData( GetStats(GameStateUnit) );
	//Disabling the enemy ability list, per gameplay, 1/23/2015 - bsteiner 
	//AbilityList.RefreshData( GameStateUnit.GetUISummary_Abilities() );

	return true;
}

simulated function array<UISummary_ItemStat> GetStats( XComGameState_Unit kGameStateUnit )
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item; 
	local EUISummary_UnitStats Summary;

	Summary = kGameStateUnit.GetUISummary_UnitStats();

	Item.Label = Summary.UnitName; 
	Item.Value = "";  
	Stats.AddItem(Item);

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
	return Stats;
}


simulated function array<UISummary_ItemStat> DEBUG_GetStats()
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item; 

	Item.Label = "SUPABAD SECTOID"; 
	Item.Value = "";  
	Stats.AddItem(Item);

	Item.Label = class'XLocalizedData'.default.HealthLabel; 
	Item.Value = "8/10";
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.AimLabel; 
	Item.Value = string(6); 
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.TechLabel; 
	Item.Value = string(8); 
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.WillLabel; 
	Item.Value = string(12); 
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.DefenseLabel; 
	Item.Value = string(7); 
	Stats.AddItem(Item); 

	Item.Label = class'XLocalizedData'.default.PsiOffenseLabel; 
	Item.Value = string(9); 
	Stats.AddItem(Item); 
	return Stats;
}

simulated function array<UISummary_Ability> DEBUG_GetUISummary_Abilities()
{
	local UISummary_Ability Data; 
	local array<UISummary_Ability> Abilities; 
	local int i; 

	for( i = 0; i < 5; i ++ )
	{
		Data.KeybindingLabel = "KEY";
		Data.Name = "DESC " $ i; 
		Data.Description = "Description text area. Lorizzle for sure dolizzle shizznit amizzle, crunk adipiscing fo. Nullizzle sapien velizzle, yo volutpizzle, quizzle, daahng dawg vel, arcu. "; 
		Data.ActionCost = 1;
		Data.CooldownTime = 1; 
		Data.bEndsTurn = true;
		Data.EffectLabel = "REFLEX";
		Data.Icon = "";
	
		Abilities.additem(Data);
	}

	return Abilities; 
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	width = 350;
	height = 500; 
	StatsHeight = 220;
	AbilitiesHeight = 300; 
	PaddingBetweenBoxes = 10;
	PaddingForAbilityList = 4;

	PADDING_LEFT	= 10;
	PADDING_RIGHT	= 10;
	PADDING_TOP		= 10;
	PADDING_BOTTOM	= 10;

}