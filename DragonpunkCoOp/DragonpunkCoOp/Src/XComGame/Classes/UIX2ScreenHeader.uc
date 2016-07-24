//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIX2ScreenHeader.uc
//  AUTHOR:  Brit Steiner - 10/29/2014 
//  PURPOSE: Wrapper class for the facility screen header asset. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIX2ScreenHeader extends UIPanel;

var string LocationField;
var string RoomField;

simulated function UIX2ScreenHeader InitScreenHeader( optional name InitName, optional string initTitle, optional string initLabel )
{
	InitPanel(InitName);
	SetText(initTitle, initLabel);
	return self;
}

simulated function SetText( optional string NewLocation, optional string NewRoom )
{
	if(NewLocation != LocationField || NewRoom != RoomField)
	{
		LocationField = NewLocation;
		RoomField = NewRoom; 

		mc.BeginFunctionOp("setText");
		mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(LocationField));
		mc.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(RoomField));
		mc.EndOp();
	}
}

simulated function Show()
{
	super.Show();
	RemoveTweens();
	AddTweenBetween("_alpha", 0, 100, 0.3);
	AddTweenBetween("_x", -300, 0, 0.3);
}

simulated function Hide()
{
	super.Hide();
	RemoveTweens();
}


simulated function UIX2ScreenHeader SetBGColorState(EUIState ColorState)
{
	// TODO! @jmontgomery: do we want to change the heade rto show damage? 
	//SetBGColor(class'UIUtilities_Colors'.static.GetColorLabelFromState(ColorState));
	return self;
}


defaultproperties
{
	LibID = "ScreenHeader";
	height = 106;
}