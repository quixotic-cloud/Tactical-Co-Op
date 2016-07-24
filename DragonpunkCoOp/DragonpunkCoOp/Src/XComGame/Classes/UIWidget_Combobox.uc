//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidget_Combobox.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Data container for the UI combobox object 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidget_Combobox extends UIWidget
	native(UI);

var public array<string>   arrLabels;              // text label shown for each option
var public array<int>      arrValues;              // each option has an arbitrary value stored with it
var public int             iCurrentSelection;      // which option in the list is currently selected, based on index
var public int             iBoxSelection;          // which option in the list is displayed in the box area, based on index
var public bool            m_bComboBoxHasFocus;    // determines if a combobox is in use

defaultproperties
{
	eType                = eWidget_Combobox;
	m_bComboBoxHasFocus  = false;
	iCurrentSelection    = -1;
	iBoxSelection        = -1;
}
