//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMapList.uc
//  AUTHOR:  Brit Steiner - 3/18/11
//  PURPOSE: This file corresponds to the server browser list screen in the shell. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 


class UIShell3D extends UIScreen;


var localized string m_strDemo;
var localized string m_sLoad;
var localized string m_sSpecial;
var localized string m_sOptions;
var localized string m_sStrategy;
var localized string m_sTactical;
var localized string m_sTutorial;
var localized string m_sFinalShellDebug;

//--------------------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	//local UIButton Button;
	super.InitScreen(InitController, InitMovie, InitName);
	UIMovie_3D(Movie).ShowDisplay('UIShellBlueprint');
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UIMovie_3D(Movie).ShowDisplay('UIShellBlueprint');
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
	InputState = eInputState_Evaluate;
}
