//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_RoomFunc.uc
//  AUTHOR:  Brian Whitman
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_RoomFunc extends UIPanel
	dependson(UIRoomContainer);

var public delegate<UIRoomContainer.onRoomFunction> onRoomFunctionDelegate;

//-----------------------------------------------------------------------------

simulated function UIFacility_RoomFunc InitRoomFunc(string label, delegate<UIRoomContainer.onRoomFunction> onRoomFunctionDel)
{
	InitPanel();

	onRoomFunctionDelegate = onRoomFunctionDel;
	MC.FunctionString("update", label);
	
	ProcessMouseEvents(OnClickRoomFunc);

	return self;
}

simulated function OnClickRoomFunc( UIPanel kControl, int cmd )
{	
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		onRoomFunctionDelegate();
		break;
	}
}

//==============================================================================

defaultproperties
{
	LibID = "RoomButton";
}
