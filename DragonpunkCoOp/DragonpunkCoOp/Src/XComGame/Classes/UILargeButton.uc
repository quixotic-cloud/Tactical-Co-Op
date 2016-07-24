//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UILargeButton.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: UILargeButton to interface with X2LargeButton
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UILargeButton extends UIButton;

// Needs to match values in X2LargeButton.as
enum EUILargeButtonStyle
{
	eUILargeButtonStyle_READY, //Ready in MP 
	eUILargeButtonStyle_UPGRADE
};

var float OffsetX;
var float OffsetY;
var public bool bHideUntilRealized;
var string Title;               // supports HTML tags
var EUILargeButtonStyle Type; 

simulated function UILargeButton InitLargeButton(optional name InitName, optional string InitLabel, optional string InitTitle, optional delegate<OnClickedDelegate> InitOnClicked, optional EUILargeButtonStyle InitType = eUILargeButtonStyle_UPGRADE)
{
	super.InitButton(InitName, InitLabel, InitOnClicked);

	OnSizeRealized = RefreshLocationBasedOnAnchor;

	SetTitle(InitTitle);
	SetType(InitType);

	return self;
}

simulated function OnInit()
{
	super.OnInit();
}

simulated function Show()
{
	if(!bHideUntilRealized || SizeRealized)
	{
		super.Show();
	}
}

simulated function UILargeButton SetTitle(string newTitle)
{
	if( Title != newTitle )
	{
		Title = newTitle;
		mc.FunctionString("setHTMLTitle", Title);

		if(bHideUntilRealized)
			Hide();
	}
	return self;
}

simulated function UILargeButton SetType(EUILargeButtonStyle NewType)
{
	if( Type != NewType )
	{
		Type = NewType;
		MC.FunctionNum("setType", Type);
	}

	return self;
}

simulated function RefreshLocationBasedOnAnchor()
{
	switch( anchor )
	{
	case class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT:
		SetPosition(-Width - 12 + OffsetX, -Height - 12 + OffsetY); // giving it a little breathing space to edge of screen, aligned with shortcut hud. 
		break;
	case class'UIUtilities'.const.ANCHOR_MIDDLE_CENTER:
		SetPosition(-Width * 0.5 + OffsetX, -Height * 0.5 + OffsetY);
		break;
	case class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER:
		SetPosition(-Width * 0.5 + OffsetX, -Height + OffsetY);
		break;
	case class'UIUtilities'.const.ANCHOR_TOP_CENTER:
		SetPosition(-Width * 0.5 + OffsetX, OffsetY);
		break;
	}
	if(bHideUntilRealized)
		Show();
}

defaultproperties
{
	LibID = "X2LargeButton";
	Title = "UNINITIALIZED TITLE"; //To force initial update. 
	Type = eUILargeButtonStyle_UPGRADE;
	FontSize = FONT_SIZE_2D;
	bProcessesMouseEvents = true;
	bIsNavigable = true;
	Height = 66;
	Width = 300;
	OffsetX = 0;
	OffsetY = 0;
}

