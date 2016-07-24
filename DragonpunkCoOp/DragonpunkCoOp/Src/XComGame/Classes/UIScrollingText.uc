//--    --------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIText.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIText to populate and manipulate a text field.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

// TODO: Make this link up with XComScrollingTextField

class UIScrollingText extends UIPanel;

// UIText member variables
var string text;
var string htmlText;
var bool bDisabled; //For gray text coloring 

simulated function UIScrollingText InitScrollingText(optional name InitName, optional string initText, optional float initWidth,
															 optional float initX, optional float initY, optional bool useTitleFont)
{
	InitPanel(InitName);
	
	// HAX: scrolling text fields are always one liners, make them huge to fit the text
	mc.FunctionNum("setTextWidth", Screen.Movie.UI_RES_X);

	SetPosition(initX, initY);
	SetWidth(initWidth);

	if(useTitleFont)
		SetTitle(initText);
	else
		SetText(initText);

	return self;
}

simulated function UIScrollingText SetText(optional string txt)
{
	if(text != txt)
	{
		text = txt;
		SetHTMLText(class'UIUtilities_Text'.static.AddFontInfo(txt, Screen.bIsIn3D));
	}
	return self;
}

simulated function UIScrollingText SetTitle(optional string txt)
{
	if(text != txt)
	{
		text = txt;
		SetHTMLText(class'UIUtilities_Text'.static.AddFontInfo(txt, Screen.bIsIn3D, true));
	}
	return self;
}

simulated function UIScrollingText SetSubTitle(optional string txt)
{
	if(text != txt)
	{
		text = txt;
		SetHTMLText(class'UIUtilities_Text'.static.AddFontInfo(txt, Screen.bIsIn3D, true, true));
	}
	return self;
}

simulated function UIScrollingText SetHTMLText(optional string txt, optional bool bForce = false)
{
	if(bForce || htmlText != txt)
	{
		htmlText = txt;
		mc.FunctionString("setText", htmlText);
	}
	return self;
}

// Sizing this control really means sizing its mask
simulated function SetWidth(float NewWidth)
{
	if(Width != NewWidth)
	{
		Width = NewWidth;
		mc.FunctionNum("setMaskWidth", Width);
	}
}

// Sizing this control really means sizing its mask
simulated function SetHeight(float NewHeight)
{
	`RedScreen("NOT SUPPORTED");
}

simulated function UIPanel SetSize(float NewWidth, float NewHeight)
{
	`RedScreen("NOT SUPPORTED");
	return self;
}

simulated function UIScrollingText ResetScroll()
{
	mc.FunctionVoid("resetScroll");
	return self;
}

simulated function UIScrollingText SetDisabled(optional bool bDisable = true)
{
	if( bDisabled != bDisable )
	{
		bDisabled = bDisable;
		mc.FunctionBool("setDisabled", bDisabled);
	}
	return self;
}

defaultproperties
{
	LibID = "ScrollingTextControl";
	bIsNavigable = false;

	height = 32; // default text height
}
