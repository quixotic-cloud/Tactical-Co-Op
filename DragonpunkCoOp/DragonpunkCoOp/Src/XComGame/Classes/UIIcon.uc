//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIIcon.uc
//  AUTHOR:  Brittany Steiner 7/21/2014
//  PURPOSE: UIPanel to load a dynamic image icon and set background coloring. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIIcon extends UIPanel;

enum EBGShape
{
	eSquare,
	eDiamond,
	eCircle,
	eHexagon
};

var float IconScale;
var string ImagePath;
var string ImagePathBG;
var string ForegroundColor;
var string BGColor;
var string DefaultForegroundColor;
var string DefaultBGColor;
var EBGShape BGShape;
var bool BGVisible;
var bool IsDisabled;
var bool bEnableMouseAutoColor;
var string BGColorWhenEnabled; // cached bg color so we can restore it when re-enabling an icon
var UIImage BGImage; //Used to load in the BG if it's not a sdtandard shape. 
var bool bDisableSelectionBrackets;

delegate OnClickedDelegate();
delegate OnDoubleClickedDelegate();

simulated function UIIcon InitIcon( optional name InitName, 
											optional string initIcon,
											optional bool initIsClickable = true,
											optional bool initShowIconBG = true,
											optional int initIconSize,
											optional EUIState initBGState = eUIState_Normal,
											optional delegate<OnClickedDelegate> initClickedDelegate, 
											optional delegate<OnClickedDelegate> initDoubleClickedDelegate)
{
	bProcessesMouseEvents = initIsClickable;

	InitPanel(InitName);

	LoadIcon( initIcon );
	SetSize(initIconSize, initIconSize);

	if(initShowIconBG)
		ShowBG();
	else
		HideBG();

	SetBGColorState(initBGState);

	OnClickedDelegate = initClickedDelegate;
	OnDoubleClickedDelegate = initDoubleClickedDelegate;

	return self; 
}

simulated function OnInit()
{
	super.OnInit();
}

simulated function UIIcon LoadIcon(string newPath)
{
	if(ImagePath != newPath)
	{
		ImagePath = newPath;
		mc.FunctionString("loadIcon", ImagePath);
	}
	return self;
}

simulated function UIIcon LoadIconBG(string newPath)
{
	if(ImagePathBG != newPath)
	{
		ImagePathBG = newPath;
		mc.FunctionString("loadIconBG", ImagePathBG);
	}
	return self;
}

simulated function UIPanel SetSize(float IconWidth, float IconHeight)
{
	if(IconWidth != Width || IconHeight != Height)
	{
		Width = IconWidth;
		Height = IconHeight;

		mc.BeginFunctionOp("setIconSize");
		mc.QueueNumber(IconWidth);
		mc.QueueNumber(IconHeight);
		mc.EndOp();
	}
	return self;
}

simulated function UIIcon SetScale(float Scale)
{
	if(Scale != 0 && Scale != IconScale)
	{
		IconScale = Scale;
		MC.FunctionNum("setIconScale", IconScale);
	}
	return self;
}

// Icons override Width / Height behavior to resize the image only, not the parent container (self)
simulated function SetWidth(float NewWidth) { SetSize(NewWidth, Height); }
simulated function SetHeight(float NewHeight) { SetSize(Width, NewHeight); }

simulated function UIIcon SetForegroundColor(string newColor)
{
	if(ForegroundColor != newColor)
	{
		ForegroundColor = newColor;

		if(!IsDisabled)
			BGColorWhenEnabled = ForegroundColor;

		mc.FunctionString("setForegroundColor", ForegroundColor);
	}
	return self;
}

simulated function UIIcon SetForegroundColorState(EUIState newState)
{
	SetForegroundColor(class'UIUtilities_Colors'.static.GetHexColorFromState(newState));
	return self;
}

simulated function UIIcon SetBGColor(string newColor)
{
	if(BGColor != newColor)
	{
		BGColor = newColor;

		if(!IsDisabled)
			BGColorWhenEnabled = BGColor;

		mc.FunctionString("setBGColor", BGColor);
	}
	return self;
}

simulated function UIIcon SetBGColorState(EUIState newState)
{
	SetBGColor(class'UIUtilities_Colors'.static.GetHexColorFromState(newState));
	return self;
}

simulated function UIIcon EnableMouseAutomaticColorStates( EUIState defaultBGState, optional EUIState defaultForegroundState = eUIState_MAX )
{
	if( defaultBGState == eUIState_MAX )
		EnableMouseAutomaticColor( class'UIUtilities_Colors'.const.BLACK_HTML_COLOR, class'UIUtilities_Colors'.static.GetHexColorFromState(defaultForegroundState));
	else
		EnableMouseAutomaticColor( class'UIUtilities_Colors'.static.GetHexColorFromState(defaultBGState), class'UIUtilities_Colors'.static.GetHexColorFromState(defaultForegroundState));
	return self; 
}

simulated function UIIcon EnableMouseAutomaticColor( string defaultBGColorString, optional string defaultForegroundColorString = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR )
{
	bEnableMouseAutoColor = true; 

	DefaultBGColor = defaultBGColorString; 
	DefaultForegroundColor = defaultForegroundColorString;

	SetBGColor(DefaultBGColor);
	SetForegroundColor(DefaultForegroundColor);
	
	return self; 
}

simulated function UIIcon DisableMouseAutomaticColor()
{
	bEnableMouseAutoColor = false; 
	return self; 
}

simulated function UIIcon SetBGShape(EBGShape newShape)
{
	if(BGShape != newShape)
	{
		BGShape = newShape;
		switch(BGShape)
		{
		case eSquare:	mc.FunctionString("setBGShape", "square");	break;
		case eDiamond:	mc.FunctionString("setBGShape", "diamond"); break;
		case eCircle:	mc.FunctionString("setBGShape", "circle");	break;
		case eHexagon:	mc.FunctionString("setBGShape", "hexagon"); break;
		}
	}
	return self;
}

simulated function UIIcon ShowBG()
{
	if(!BGVisible)
	{
		BGVisible = true;
		mc.FunctionVoid("showBG");
	}
	return self;
}

simulated function UIIcon HideBG()
{
	if(BGVisible)
	{
		BGVisible = false;
		mc.FunctionVoid("hideBG");
	}
	return self;
}

simulated function UIPanel SetDisabled(bool disabled)
{
	if( IsDisabled != disabled )
	{
		IsDisabled = disabled;

		if(IsDisabled)
			SetBGColorState(eUIState_Disabled);
		else
			SetBGColor(BGColorWhenEnabled);
	}
	return self;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	super.OnMouseEvent(cmd, args);

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		if( bEnableMouseAutoColor )
		{
			//Swapped while mouse is hovering. 
			SetForegroundColor(DefaultBGColor); 
			SetBGColor(DefaultForegroundColor);
		}
		else if( !bDisableSelectionBrackets )
		{
			mc.FunctionVoid("showSelectionBrackets");
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		if( bEnableMouseAutoColor )
		{
			SetForegroundColor(DefaultForegroundColor);
			SetBGColor(DefaultBGColor);
		}
		else if( !bDisableSelectionBrackets )
		{
			mc.FunctionVoid("hideSelectionBrackets");
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
		if(!IsDisabled && OnClickedDelegate != none)
			OnClickedDelegate();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		if(!IsDisabled && OnDoubleClickedDelegate != none)
			OnDoubleClickedDelegate();
		break;
	}
}

defaultproperties
{
	LibID = "IconControl";

	bIsNavigable = true;
	bProcessesMouseEvents = true;
	bEnableMouseAutoColor = false; 
	bDisableSelectionBrackets = false;
	BGVisible = true;

	BGColor = "0x9acbcb"; // matches class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR
}
