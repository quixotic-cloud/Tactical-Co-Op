//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidget_Spinner.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Data container for the UI spinner object 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidget_Spinner extends UIWidget;

var public string      strValue;              // each option has an arbitrary value stored with it
var public bool        bIsHorizontal;         // spinner type, vertical or horizontal

// Using the following arrays will make the widget ignore the 'strValue'
var public array<string>   arrLabels;              // text label shown for each option
var public array<int>      arrValues;              // each option has an arbitrary value stored with it
var public int             iCurrentSelection;      // which option in the list is currently selected, based on index
var public bool            bCanSpin;               // should it show the spinner arrows 

delegate del_OnIncrease(); // Callback you can set to be called when the right arrow is clicked or right button pressed 
delegate del_OnDecrease(); // Callback you can set to be called when the left arrow is clicked or left arrow changes 

defaultproperties
{
	strValue = "";
	eType  = eWidget_Spinner;
	bIsHorizontal = true; 
	bCanSpin = true; 
}


