//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidget_Checkbox.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Data container for the UI combobox object 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidget_Checkbox extends UIWidget;

// style 0 == label to the left of the checkbox (default)
// style 1 == label to the right of the checkbox
var public int iTextStyle;
var public bool bChecked;

defaultproperties
{
	bChecked = false;
	eType  = eWidget_Checkbox;
}


