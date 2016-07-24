//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidget_Slider.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Data container for the UI slider object 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidget_Slider extends UIWidget;

var public int      iValue;
var public int      iStepSize; //Percent of 100 that an arrow click will cause the value to step. 

delegate del_OnIncrease(); // Callback you can set to be called when the right arrow is clicked or right button pressed 
delegate del_OnDecrease(); // Callback you can set to be called when the left arrow is clicked or left arrow changes 
delegate del_OnValueChanged(); // Callback you can set to be called when the left arrow is clicked or left arrow changes 

defaultproperties
{
	iValue = -1;
	iStepSize = 10;
	eType  = eWidget_Slider;
}


