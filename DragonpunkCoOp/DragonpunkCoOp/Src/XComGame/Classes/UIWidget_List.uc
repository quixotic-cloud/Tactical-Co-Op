//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidget_List.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Data container for the UI list object 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidget_List extends UIWidget;

var public array<string>   arrLabels;              // text label shown for each option
var public array<int>      arrValues;              // each option has an arbitrary value stored with it
var public int             iCurrentSelection;      // which option in the list is currently selected, based on index
var public bool            m_bHasFocus;            // determines if a list is active
var public bool            m_bWrap;                // determines if a list wraps upon itself

delegate del_OnSelectionChanged(int iSelected);

defaultproperties
{
	eType        = eWidget_List;
	m_bHasFocus  = false;
	m_bWrap      = false;
	iCurrentSelection    = -1;
}
