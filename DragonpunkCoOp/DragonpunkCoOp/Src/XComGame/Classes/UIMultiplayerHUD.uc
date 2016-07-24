//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMultiplayerHUD.uc
//  AUTHORS: Sam Batista
//
//  PURPOSE: Container for multiplayer specific UI elements
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMultiplayerHUD extends UIScreen;


//----------------------------------------------------------------------------
// METHODS
//

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);	

}


/*simulated event Tick(float deltaTime)
{
	local XComGameState_TimerData Timer;

	super.Tick(deltaTime);

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));;
	if(Timer != none)
	{
		if(Timer.HasTimeExpired())
		{
			m_kTurnTimer.ExpireCounter(true);
		}
		else
		{
			m_kTurnTimer.SetCounter(string(Timer.GetCurrentTime()), true);
		}
	}
	else
	{
		m_kTurnTimer.ShowInfinity(true);
	}
}*/

// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();	
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	// @TODO UI: uncomment when the  UIMultiplayerHUD_TurnTimer has been fixed.
	//Package = "/ package/gfxMultiplayerHUD/MultiplayerHUD";
	//MCName = "theMultiplayerHUD";
	InputState = eInputState_None;
	bHideOnLoseFocus = false;
}
