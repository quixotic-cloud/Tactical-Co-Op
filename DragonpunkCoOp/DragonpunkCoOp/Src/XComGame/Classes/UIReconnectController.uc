//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIReconnectController.uc
//  AUTHOR:  dwuenschell
//  PURPOSE: Reconnect Controller UI
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIReconnectController extends UIProgressDialogue;

var bool m_bOnOptionsScreen;

//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================
simulated function bool OnCancel( optional string strOption = "" )
{
	if( m_bOnOptionsScreen )
	{
		XComPresentationLayerBase(Owner).m_kPCOptions.ResetMouseDevice();
	}

	return super.OnCancel();
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
defaultproperties
{
	m_bOnOptionsScreen = false;
}
