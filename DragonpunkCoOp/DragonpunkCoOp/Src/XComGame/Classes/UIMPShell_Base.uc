//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_Base.uc
//  AUTHOR:  Todd Smith  --  6/25/2015
//  PURPOSE: Base class for the MP shell screens. Contains boilerplate code for 
//           navigation, input, etc.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_Base extends UIScreen;

var string TEMP_strSreenNameText;
var UIX2PanelHeader TEMP_ScreenNameHeader;

var X2MPShellManager m_kMPShellManager;
var XComPhotographer_Strategy	StrategyPhotographer;
var string MPLevelName;
var string ShellLevelName;

var string CameraTag;
var string DisplayTag;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_kMPShellManager = XComShellPresentationLayer(InitController.Pres).m_kMPShellManager;
	StrategyPhotographer = Spawn(class'XComPhotographer_Strategy');
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			if(bIsInited)
				CloseScreen();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function CloseScreen()
{
	StrategyPhotographer.Destroy();
	// do any custom cleanup we need here. -tsmith
	super.CloseScreen();
}

simulated function OnRemoved()
{
	super.OnRemoved();
	
	Movie.Pres.UIClearGrid();
}


//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
	InputState = eInputState_Evaluate;
	TEMP_strSreenNameText="";
	MPLevelName="XComShell_Multiplayer.umap";

	DisplayTag="UIDisplay_MPShell"
	CameraTag="UIDisplay_MPShell"
}