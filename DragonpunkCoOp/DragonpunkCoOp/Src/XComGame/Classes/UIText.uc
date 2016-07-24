//--    --------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIText.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIText to populate and manipulate a Text field.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

// TODO: Make this link up with XComScrollingTextField

class UIText extends UIPanel;

// UIText member variables
var string Text;
var string HtmlText;
var bool ResizeToText;
var bool TextSizeRealized;

var float ScrollPercent;

// this delegate is triggered when Text size is calculated after setting Text data
delegate OnTextSizeRealized();

simulated function UIText InitText(optional name InitName, optional string InitText, optional bool InitTitleFont, optional delegate<OnTextSizeRealized> TextSizeRealizedDelegate)
{
	InitPanel(InitName);
	
	if(InitTitleFont)
		SetTitle(InitText, TextSizeRealizedDelegate);
	else
		SetText(InitText, TextSizeRealizedDelegate);

	return self;
}

simulated function UIText SetText(string NewText, optional delegate<OnTextSizeRealized> TextSizeRealizedDelegate)
{
	if(Text != NewText)
	{
		Text = NewText;
		SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(Text, Screen.bIsIn3D), TextSizeRealizedDelegate);
	}
	return self;
}

simulated function UIText SetTitle(string NewText, optional delegate<OnTextSizeRealized> TextSizeRealizedDelegate)
{
	if(Text != NewText)
	{
		Text = NewText;
		SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(Text, Screen.bIsIn3D, true), TextSizeRealizedDelegate);
	}
	return self;
}

simulated function UIText SetSubTitle(string NewText, optional delegate<OnTextSizeRealized> TextSizeRealizedDelegate)
{
	if(Text != NewText)
	{
		Text = NewText;
		SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(NewText, Screen.bIsIn3D, true, true), TextSizeRealizedDelegate);
	}
	return self;
}

simulated function UIText SetHtmlText(string NewText, optional delegate<OnTextSizeRealized> TextSizeRealizedDelegate, optional bool bForce = false)
{
	if(bForce || HtmlText != NewText)
	{
		HtmlText = NewText;

		TextSizeRealized = false;

		if(TextSizeRealizedDelegate != none)
			OnTextSizeRealized = TextSizeRealizedDelegate;

		mc.BeginFunctionOp("setText");
		mc.QueueString(HtmlText);
		mc.QueueBoolean(OnTextSizeRealized != none); // only trigger TextSizeRealized if we care about it
		mc.EndOp();
	}
	return self;
}

simulated function SetScroll(float percent)
{
	if(ScrollPercent != percent)
	{
		ScrollPercent = percent;
		mc.FunctionNum("setScrollPercent", percent);
	}
}

simulated function UIText SetCenteredText(string NewText, optional UIPanel CenterOnPanel, optional delegate<OnTextSizeRealized> TextSizeRealizedDelegate)
{
	if( CenterOnPanel != none )
		SetSize(CenterOnPanel.Width, CenterOnPanel.Height);

	return SetHtmlText(class'UIUtilities_Text'.static.AlignCenter(NewText), TextSizeRealizedDelegate);
}

// Width and Height of a TextControl work differently from regular UIControls
simulated function SetWidth(float NewWidth)
{
	if(Width != NewWidth)
	{
		Width = NewWidth;
		mc.FunctionNum("setTextWidth", Width);
	}
}

simulated function SetHeight(float NewHeight)
{
	if(Height != NewHeight)
	{
		Height = NewHeight;
		mc.FunctionNum("setTextHeight", Height);    
	}
}

simulated function UIPanel SetSize(float NewWidth, float NewHeight)
{
	SetWidth(NewWidth);
	SetHeight(NewHeight);
	return self;
}

simulated function UIPanel EnableScrollbar()
{
	mc.FunctionNum("EnableScrollbar", Height);
	return self;
}


simulated function DebugControl()
{
	mc.FunctionBool("border", true);
}

simulated function OnCommand(string cmd, string arg)
{
	local array<string> sizeData;
	if(cmd == "RealizeSize")
	{
		sizeData = SplitString(arg, ",");
		Width = float(sizeData[0]);
		Height = float(sizeData[1]);
		TextSizeRealized = true;
		if(OnTextSizeRealized != none)
			OnTextSizeRealized();
	}	
}

simulated function UIPanel ProcessMouseEvents(optional delegate<OnMouseEventDelegate> MouseEventDelegate)
{
	`RedScreen(Class.Name @ "can't process mouse events.");
	return self;
}

defaultproperties
{
	LibID = "TextControl";
	bIsNavigable = false;
	height = 32; // default height for a single line text field
	ScrollPercent = 0;
}
