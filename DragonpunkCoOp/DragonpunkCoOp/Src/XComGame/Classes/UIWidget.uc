//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidget.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Base class of the UI widget system 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidget extends Object
	native(UI);

enum UIWidgetType
{
	eWidget_Invalid,
	eWidget_Combobox,
	eWidget_Button,
	eWidget_List,
	eWidget_Spinner,
	eWidget_Slider,
	eWidget_Checkbox
};

var public string          strTitle;    // basic display string, used differently in derived classes
var public int             eType;       //sets teh type of the widget, in derived classes
var public bool            bIsActive;   //expected to be used to alter navigation when hiding elements 
var public bool            bIsDisabled; //does not alter navigation, but prevents on changed callbacks
var public bool            bReadOnly;   //does not alter navigation, but prevents on changed callbacks, and reflects read-only styling 

delegate del_OnValueChanged(); // Callback you can set to be called when the value changes 

defaultproperties
{
	strTitle    = "Unset Widget Name";
	eType       = eWidget_Invalid;
	bIsActive   = true;
	bIsDisabled = false;
	bReadOnly   = false;
}
