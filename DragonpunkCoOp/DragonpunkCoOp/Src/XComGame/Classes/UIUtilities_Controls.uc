//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities_Controls.uc
//  AUTHOR:  bsteiner
//  PURPOSE: Container of static helper functions for the UI Controls. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities_Controls extends Object;

// Common library movie clip items that we dynamically load in. 
const MC_GenericPixel           = 'Pixel';
const MC_X2Background           = 'X2BackgroundPanel'; // The common panel with decorative lines, 9-sliced. 
const MC_X2BackgroundSimple     = 'X2BackgroundSimple'; // The basic bg box without any lines, 9-sliced.  
const MC_X2BackgroundShading    = 'X2BackgroundShading'; //Used as a background shading fill for alternating line items, like in a spreadsheet.  
const MC_BonusIcon				= 'BonusArrow'; //Buff
const MC_PenaltyIcon			= 'PenaltyArrow'; //Debuff 
const MC_IconSelector			= 'IconSelector';
const MC_AttentionPulse			= 'AttentionPulseAnimation';
const MC_AttentionIcon			= 'AttentionIcon';

// ==========================================================================

public static function CloseAllDropdowns(optional UIPanel ParentPanel)
{
	local UIPanel ChildControl;
	local UIDropdown Dropdown;

	if(ParentPanel == none)
		ParentPanel = `PRES.ScreenStack.GetCurrentScreen();

	foreach ParentPanel.ChildPanels(ChildControl)
	{
		Dropdown = UIDropdown(ChildControl);
		if( Dropdown != none )
		{
			Dropdown.Close();
		}
		else if( ChildControl != ParentPanel.Screen ) // Screens insert themselves into their ChildPanels array
		{
			CloseAllDropdowns(ChildControl);
		}
	}
}

// ==========================================================================

// Usually used for snappeing a divider line beneath a title text area
public static function UIPanel CreateDividerLineBeneathControl( UIPanel TargetControl, optional UIPanel SpawnScope = none, optional int LeadingAdjustment = -4 )
{
	local UIPanel Line; 

	if( SpawnScope == none ) SpawnScope = TargetControl.ParentPanel; 

	Line = SpawnScope.Spawn(class'UIPanel', SpawnScope).InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
	Line.SetPosition(TargetControl.X, TargetControl.Y + TargetControl.height + leadingAdjustment); 
	Line.SetSize( TargetControl.width, 2 );
	Line.SetColor( class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR );
	Line.SetAlpha( 15 );

	return Line; 
}