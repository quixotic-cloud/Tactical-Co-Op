//---------------------------------------------------------------------------------------
 //  FILE:    UITacticalHUD_PerkTooltip.uc
 //  AUTHOR:  Brit Steiner --  7/1/2014
 //  PURPOSE: Tooltip for the soldier passive abilities used in the TacticalHUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_PerkTooltip extends UITooltip;

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;

var public UIEffectList ItemList; 

simulated function UITacticalHUD_PerkTooltip InitPerkTooltip(optional name InitName, optional name InitLibID)
{
	InitPanel(InitName, InitLibID);

	Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(width, height);

	ItemList = Spawn(class'UIEffectList', self);
	ItemList.InitEffectList('ItemList',
		, 
		PADDING_LEFT, 
		PADDING_TOP, 
		width-PADDING_LEFT-PADDING_RIGHT, 
		height-PADDING_TOP-PADDING_BOTTOM,
		height-PADDING_TOP-PADDING_BOTTOM);

	Spawn(class'UIMask', self).InitMask('Mask', ItemList).FitMask(ItemList);

	Hide();

	return self; 
}

simulated function ShowTooltip()
{
	RefreshData();	
	ItemList.Show(); 	
	super.ShowTooltip();
}


simulated function HideTooltip( optional bool bAnimateIfPossible = false )
{
	super.HideTooltip(bAnimateIfPossible);
	ItemList.Hide();
}

simulated function RefreshData()
{
	local XGUnit				kActiveUnit;
	local XComGameState_Unit	kGameStateUnit;
	local array<UISummary_UnitEffect> Effects, TargetEffect; 
	local int					iTargetIndex; 
	local array<string>			Path; 

	Path = SplitString(currentPath, ".");	
	iTargetIndex = int(GetRightMost(Path[Path.Length-1]));

	kActiveUnit = XComTacticalController(PC).GetActiveUnit();

	if( kActiveUnit == none )
	{
		if( XComTacticalController(PC) != None )
			HideTooltip();
		else //For testing in the shell 
			ItemList.RefreshData( DEBUG_GetData() );

		return; 
	} 

	kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	Effects = kGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Passive); 
	TargetEffect.AddItem( Effects[iTargetIndex] );
	ItemList.RefreshData( TargetEffect ); 
}

simulated function array<UISummary_UnitEffect> DEBUG_GetData()
{
	local array<UISummary_UnitEffect> Items; 
	local UISummary_UnitEffect Item; 
	local int i;

	for( i = 0; i < 3; i++ )
	{
		Item.Name = "Perk" @ string(i);
		Item.Description = "Sample perk "$string(i) $" description! This is where the description for the perk would go.";
		Item.Icon = "img:///UILibrary_PerkIcons.UIPerk_adrenalneurosympathy"; 
		Items.AddItem(Item);
	}

	return Items;
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	width = 300;
	height = 225;

	PADDING_LEFT	= 10;
	PADDING_RIGHT	= 10;
	PADDING_TOP		= 10;
	PADDING_BOTTOM	= 10;

	bUsePartialPath = true; 
	bFollowMouse = false;
	bRelativeLocation = true;
}