//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIProgressBar.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Simple progress bar that displays percentage. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIProgressBar extends UIPanel;

var string BGColor;
var string FillColor;
var bool IsHighlighted;
var public bool bHighlightOnMouseEvent;

var UIPanel BGBar;
var UIPanel FillBar;
var float Percent; 

simulated function UIProgressBar InitProgressBar(	optional name InitName,
													optional float InitX, 
													optional float InitY, 
													optional float InitWidth, 
													optional float InitHeight, 
													optional float InitPercentFilled,
													optional EUIState InitFillColorState = eUIState_Normal)
{
	InitPanel(InitName);
	SetPosition(InitX, InitY);

	BGBar = Spawn(class'UIPanel', self).InitPanel('BGBoxSimpleBG', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
	BGBar.SetSize(InitWidth, InitHeight); 
	BGBar.SetColor(class'UIUtilities_Colors'.const.FADED_HTML_COLOR); //Remove this once we finalize visuals. 

	FillBar = Spawn(class'UIPanel', self).InitPanel('BGBoxSimpleFill', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
	//FillBar.SetPosition(0, 0); //TODO: may need to inset the bar once we finalize visuals. 
	FillBar.SetSize(InitWidth, InitHeight);
	
	SetColorState(InitFillColorState);

	SetSize(InitWidth, InitHeight);
	SetPercent(InitPercentFilled);

	return self;
}

simulated function UIPanel SetSize(float NewWidth, float NewHeight)
{
	if (Width != NewWidth || Height != NewHeight)
	{
		Width = NewWidth;
		Height = NewHeight;

		BGBar.SetSize(Width, Height);
		FillBar.SetHeight(Height);
		SetPercent(Percent); 
	}
	return self; 
}

simulated function UIProgressBar SetBGColor(string ColorLabel)
{
	BGBar.SetColor(ColorLabel);
	return self;
}

simulated function UIProgressBar SetBGColorState(EUIState ColorState)
{
	SetBGColor(class'UIUtilities_Colors'.static.GetColorLabelFromState(ColorState));
	return self;
}

simulated function UIPanel SetColor(string ColorLabel)
{
	FillBar.SetColor(ColorLabel);
	return self;
}

simulated function UIProgressBar SetColorState(EUIState ColorState)
{
	SetColor(class'UIUtilities_Colors'.static.GetHexColorFromState(ColorState));
	return self;
}

// Percent as value 0.0 to 1.0 
simulated function SetPercent(float DisplayPercent)
{
	if (DisplayPercent <= 0.01)
	{
		FillBar.Hide();
		FillBar.SetWidth(1); // NEVER set size to zero, or scaleform freaks out. 
	}
	else if( DisplayPercent > 1.0 && DisplayPercent <= 100.0 )
	{
		`log("Warning: You're not sending the percent bar a value between 0.0 and 1.0. (Your value, '" $ DisplayPercent $"', is between 0 and 100.) We'll auto convert for now, but you should fix this.");
		FillBar.SetWidth(DisplayPercent * Width * 0.01);
		FillBar.Show();
	}
	else if (DisplayPercent > 100.0)
	{
		`log("Warning: You're not sending the percent bar a value between 0.0 and 1.0. Your value, '" $ DisplayPercent $"', is over 100.0, so extra incorrect. Capping you at 1.0, but you should fix this.");
		FillBar.SetWidth(1.0 * Width);
		FillBar.Show();
	}
	else
	{
		FillBar.SetWidth(DisplayPercent * Width);
		FillBar.Show();
	}
}

simulated function UIProgressBar SetHighlighed(bool Highlight)
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

simulated function OnMouseEvent(int cmd, array<string> args)
{
	super.OnMouseEvent(cmd, args);

	// HAX: Controls in lists don't handle their own focus changes
	if( GetParent(class'UIList') != none ) return;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
			OnReceiveFocus();
			if(bHighlightOnMouseEvent)
				SetHighlighed(true);
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
			OnLoseFocus();
			if(bHighlightOnMouseEvent)
				SetHighlighed(false);
			break;
	}
}

defaultproperties
{
	bIsNavigable = false;
	bProcessesMouseEvents = false;
	bHighlightOnMouseEvent = false;
}
