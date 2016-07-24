//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UILoginScreen
//  AUTHOR:  Timothy Talley
//
//  PURPOSE: Base screen for handling the login process to any Challenge Mode System.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UILoginScreen extends UIScreen;



//--------------------------------------------------------------------------------------- 
// Delegates
//
delegate OnClosedDelegate(bool bLoginSuccessful);



//==============================================================================
//		INITIALIZATION:
//==============================================================================
simulated function InitScreen( XComPlayerController InitController, UIMovie InitMovie, optional name InitName )
{
	super.InitScreen(InitController, InitMovie, InitName);
}