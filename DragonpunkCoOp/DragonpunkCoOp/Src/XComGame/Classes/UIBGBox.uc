//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIBGBox.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIBGBox that positions and sizes a background element.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

// TODO: Make this link up with XComScrollingTextField

class UIBGBox extends UIPanel;

var string BGColor;
var bool IsHighlighted;
var public bool bHighlightOnMouseEvent;

simulated function UIBGBox InitBG(optional name InitName, optional float InitX, optional float InitY, optional float InitWidth, optional float InitHeight, optional EUIState InitColorState = eUIState_Faded)
{
	InitPanel(InitName);
	SetPosition(InitX, InitY);
	SetSize(InitWidth, InitHeight);
	SetBGColorState(InitColorState);
	return self;
}

/* Valid bg colors are:
 * 
 * cyan
 * red
 * yellow
 * green
 * gray
 * 
 * cyan_highlight
 * red_highlight
 * yellow_highlight
 * green_highlight
 * gray_highlight
*/
simulated function UIBGBox SetBGColor(string ColorLabel)
{
	if(BGColor != ColorLabel)
	{
		BGColor = ColorLabel;
		mc.FunctionString("gotoAndPlay", BGColor);
	}
	return self;
}

simulated function UIBGBox SetBGColorState(EUIState ColorState)
{
	SetBGColor(class'UIUtilities_Colors'.static.GetColorLabelFromState(ColorState));
	return self;
}

simulated function UIBGBox SetHighlighed(bool Highlight)
{
	local int Index;
	local string NewColor;

	if(IsHighlighted != Highlight)
	{
		IsHighlighted = Highlight;

		Index = InStr(BGColor, "_highlight");

		if( IsHighlighted && Index == INDEX_NONE )
			NewColor = BGColor $ "_highlight";
		else if( Index != INDEX_NONE )
			NewColor = Left(BGColor, Index);

		SetBGColor(NewColor);
	}
	return self;
}

// Call this function if you only want to show outline, or only want to show fill.
// Look at UIUtilities_Colors to get preset hex colors.
// IMPORTANT: Automatic highlighting will no longer work if you call this function, 
// you will have to override 'OnMouseEventDelegate' and call SetColor manually to implement mouse highlight.
simulated function UIBGBox SetOutline(bool bOutline, optional string HexColor)
{
	SetBGColor(bOutline ? "outline" : "fill");

	if(HexColor != "")
		SetColor(HexColor);

	return self;
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	SetHighlighed(bHighlightOnMouseEvent && bIsFocused);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	SetHighlighed(bHighlightOnMouseEvent && bIsFocused);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	super.OnMouseEvent(cmd, args);

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
			OnReceiveFocus();
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
			OnLoseFocus();
			break;
	}
}

defaultproperties
{
	LibID = "X2BackgroundSimple";
	BGColor = "faded";
	bIsNavigable = false;
	bProcessesMouseEvents = false;
	bHighlightOnMouseEvent = true;
}
