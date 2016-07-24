//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidget_Button.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Data container for the UI combobox object 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidget_Button extends UIWidget;

var public int      iValue;              // each option has an arbitrary value stored with it

defaultproperties
{
	iValue = -1;
	eType  = eWidget_Button;
}


