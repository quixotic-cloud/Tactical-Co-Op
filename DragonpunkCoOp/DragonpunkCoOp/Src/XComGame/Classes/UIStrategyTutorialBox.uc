//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyTutorialBox.uc
//  AUTHOR:  Eric - 2/23/2012
//  PURPOSE: Used for tutorial tips in the strategy layer
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyTutorialBox extends UIScreen;

//----------------------------------------------------------------------------
// MEMBERS

var string m_strHelpText;
var bool m_bPlayingOutro;
var bool m_bIsStrategy;

//==============================================================================
// 		Init:
//==============================================================================

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	Show();

	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( PC.Pres.GetUIComm(), 'bIsVisible', self, TweenHelp);
}

simulated function OnInit()
{
	super.OnInit();
	
	m_bIsStrategy = XComTacticalController(PC) == none;

	AS_AnchorBasedOnStrategy(m_bIsStrategy);
	UpdateDisplay();
}

event Destroyed()
{
	super.Destroyed();
	Movie.RemoveHighestDepthScreen(self);
}

simulated function TweenHelp()
{
	ClearTimer('AdjustTipPosition');
	if (!Movie.Pres.GetUIComm().bIsVisible )
	{
		SetTimer(0.5, false, 'AdjustTipPosition');
	}
	else
	{
		AS_CommLinkAdjusted(Movie.Pres.GetUIComm().bIsVisible);
	}
}

function AdjustTipPosition()
{
	AS_CommLinkAdjusted(Movie.Pres.GetUIComm().bIsVisible);
}

simulated function AS_AnchorBasedOnStrategy(bool strategyLayer)
{
	Movie.ActionScriptVoid( MCPath $ ".AnchorBasedOnStrategy" );
}

//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================

function SetNewHelpText(string strHelpText)
{
	m_strHelpText = strHelpText;
	UpdateDisplay();
}

function UpdateDisplay()
{
	AS_SetText(m_strHelpText);
	if (m_bIsStrategy)
	{
		//if (Movie.Pres.ShouldAnchorTipsToRight())
		//{
		//	AS_AnchorToBottomRight();
		//}
		//else
		//{
		//	AS_AnchorToBottomLeft();
		//}
		AS_AnchorToBottomLeft();
	}
	AS_CommLinkAdjusted(Movie.Pres.GetUIComm().bIsVisible);
}

//==============================================================================

simulated function Show()
{
	if( m_strHelpText != "" )
	{
		Movie.InsertHighestDepthScreen(self);

		if (!bIsVisible)
		{
			//This sound was removed by Audio. They'll need to replace it if it is still used
			//PlaySound(SoundCue'SoundDesignTutorial.Help_Tip_Open_Cue', true);
		}

		super.Show();

		m_bPlayingOutro = false;
		Invoke("PlayIntro");
	}
}

simulated function Hide()
{
	if( bIsVisible )
	{
		Movie.RemoveHighestDepthScreen(self);

		Invoke("PlayOutro");
		m_bPlayingOutro = true;
		m_strHelpText = "";
	}
}

simulated function ToggleDepth(bool bOnTop)
{
	if (bOnTop)
	{
		Movie.RemoveHighestDepthScreen(self);
		Movie.InsertHighestDepthScreen(self);
	}
	else
	{
		Movie.RemoveHighestDepthScreen(self);
	}
}

simulated function OnCommand( string cmd, string arg )
{
	if( cmd == "OnOutroComplete" )
	{
		super.Hide();
		m_bPlayingOutro = false;
	}
}

//==============================================================================
//		FLASH COMMUNICATION:
//==============================================================================

simulated function AS_SetText( string text )
{
	Movie.ActionScriptVoid( MCPath $ ".SetText" );
}

// Default of UI is anchored to Top Left
// Here are a list of other methods to change the anchor position
simulated function AS_AnchorToTopRight()
{
	Movie.ActionScriptVoid( MCPath $ ".anchorToTopRight" );
}

simulated function AS_AnchorToBottomRight()
{
	Movie.ActionScriptVoid( MCPath $ ".anchorToBottomRight" );
}

simulated function AS_AnchorToBottomLeft()
{
	Movie.ActionScriptVoid( MCPath $ ".anchorToBottomLeft" );
}

simulated function AS_CommLinkAdjusted(bool adjusted)
{
	if (!m_bIsStrategy)
		Movie.ActionScriptVoid( MCPath $ ".CommLinkAdjusted" );
}

//----------------------------------------------------

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package   = "/ package/gfxStrategyTutorialBox/StrategyTutorialBox";
	MCName      = "theStrategyTutorialBox";
	
	InputState  = eInputState_None; 
	m_bPlayingOutro = false;
	bShowDuringCinematic = true;
}
