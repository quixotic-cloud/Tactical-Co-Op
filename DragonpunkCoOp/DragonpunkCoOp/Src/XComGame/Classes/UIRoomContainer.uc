//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIRoomContainer.uc
//  AUTHOR:  Brian Whitman
//  PURPOSE: Room container that will load in and format generic room function buttons
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIRoomContainer extends UIPanel
	config(UI);

var const config float YOffsetFromBottomOfScreen;

var array<UIFacility_RoomFunc> RoomFuncs; 

var localized string RoomTitle; 

delegate onRoomFunction();

simulated function UIRoomContainer InitRoomContainer(optional name InitName, optional string Title = "")
{
	if (Title != "")
	{
		RoomTitle = Title;
	}

	InitPanel(InitName);
	AnchorBottomCenter();
	SetY(YOffsetFromBottomOfScreen);
	AS_SetTitle(RoomTitle); 
	return self;
}

simulated function AddRoomFunc(string label, delegate<onRoomFunction> onRoomFunctionDelegate)
{
	RoomFuncs.AddItem(Spawn(class'UIFacility_RoomFunc', self).InitRoomFunc(label, onRoomFunctionDelegate));
}

simulated function AS_SetTitle(string NewTitle)
{
	MC.FunctionString("setTitle", NewTitle);
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
	LibID = "RoomContainer";
	bIsNavigable = true;
}
