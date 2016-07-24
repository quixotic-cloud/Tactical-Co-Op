//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIImage.uc
//  AUTHOR:  Brittany Steiner 
//  PURPOSE: UIPanel to populate and manipulate a text field.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIImage extends UIPanel;

var string ImagePath;
var float ImageScale;

var delegate<OnClickedCallback> OnClickedDelegate;
delegate OnClickedCallback(UIImage Image);

simulated function UIImage InitImage(optional name InitName, optional string initImagePath,  optional delegate<OnClickedCallback> OnClickDel)
{
	if( OnClickDel != none )
	{
		OnClickedDelegate = OnClickDel;
		bProcessesMouseEvents = true; 
	}

	InitPanel(InitName);
	LoadImage(initImagePath);
	return self;
}

simulated function UIImage LoadImage(string NewPath)
{
	NewPath = class'UIUtilities_Image'.static.ValidateImagePath(NewPath);

	if(ImagePath != NewPath)
	{
		ImagePath = NewPath;
		if(ImagePath != "")
			MC.FunctionString("loadImage", ImagePath);
	}
	return self;
}

simulated function UIImage SetScale(float Scale)
{
	if(Scale != 0 && Scale != ImageScale)
	{
		ImageScale = Scale;
		MC.FunctionNum("setImageScale", ImageScale);
	}
	return self;
}

simulated function UIPanel SetSize(float ImageWidth, float ImageHeight)
{
	if(ImageHeight == 0) ImageHeight = ImageWidth;

	if(ImageWidth != Width || ImageHeight != Height)
	{
		Width = ImageWidth;
		Height = ImageHeight;

		MC.BeginFunctionOp("setImageSize");
		MC.QueueNumber(ImageWidth);
		MC.QueueNumber(ImageHeight);
		MC.EndOp();
	}
	return self;
}

// Images override Width / Height behavior to resize the image only, not the parent container (self)
simulated function SetWidth(float NewWidth) { SetSize(NewWidth, Height); }
simulated function SetHeight(float NewHeight) { SetSize(Width, NewHeight); }

simulated function OnMouseEvent(int cmd, array<string> args)
{
	// send a clicked callback
	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
	{
		if( OnClickedDelegate != none )
			OnClickedDelegate(self);
	}
	super.OnMouseEvent(cmd, args);
}

defaultproperties
{
	LibID = "ImageControl";
	bIsNavigable = false;
	bProcessesMouseEvents = false;
	ImageScale = 1;
}
