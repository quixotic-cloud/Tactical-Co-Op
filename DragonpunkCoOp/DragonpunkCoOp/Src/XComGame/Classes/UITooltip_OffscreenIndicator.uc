//---------------------------------------------------------------------------------------
//  FILE:    UITooltip_OffscreenIndicator.uc
//  AUTHOR:  Sam Batista 8/11/2014
//  PURPOSE: Tooltip for offscreen indicators in the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class UITooltip_OffscreenIndicator extends UITooltip;
/*
simulated function UITooltip_TextBox InitTextTooltip(optional name InitName, optional name InitLibID)
{
	return UITooltip_TextBox(Init(InitName, InitLibID));
}

simulated function ShowTooltip()
{
	RefreshData();
	super.ShowTooltip();
}
simulated function HideTooltip( optional bool bAnimateIfPossible = false )
{
	AbilityArea.ClearScroll();
	super.HideTooltip(bAnimateIfPossible);
}

simulated function RefreshData()
{
	local XComGameState_Ability	kGameStateAbility;
	local int					iTargetIndex; 
	local array<string>			Path; 

	if( XComTacticalController(PC) == None )
	{	
		Data = DEBUG_GetUISummary_Ability();
		RefreshDisplay();	
		return; 
	}

	Path = SplitString( currentPath, "." );	
	iTargetIndex = int(Path[5]);
	kGameStateAbility = UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kAbilityHUD.GetAbilityAtIndex(iTargetIndex);
	
	if( kGameStateAbility == none )
	{
		HideTooltip();
		return; 
	}

	Data = kGameStateAbility.GetUISummary_Ability();
	RefreshDisplay();	
}
*/