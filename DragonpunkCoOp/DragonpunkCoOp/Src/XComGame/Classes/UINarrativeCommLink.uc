//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UINarrativeCommLink.uc
//  AUTHOR:  Brit Steiner - 10/11/11
//  PURPOSE: This file corresponds to the narrative comm link window with portrait in flash. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UINarrativeCommLink extends UIScreen
	dependson(XGNarrative, XGTacticalScreenMgr);

//----------------------------------------------------------------------------
// MEMBERS
var int m_iSubtitleWatchVar; 

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	Hide();
}

simulated function OnInit()
{
	super.OnInit();

	RefreshAnchorListener();

	// Make sure Flash side push to top
	Movie.InsertHighestDepthScreen(self);

	if (Movie.Pres.m_kNarrativeUIMgr != none)
	{
		Movie.Pres.m_kNarrativeUIMgr.BeginNarrative();
	}
}

simulated function RefreshAnchorListener()
{
	// Always anchor to top right, so that we'll no longer cover button helps etc. 
	if( XComPresentationLayer( Movie.Pres ) != none )
		Invoke("AnchorToTopRight");
	else if( XComHQPresentationLayer(Movie.Pres) != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD != none && XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.ResourceContainer.bIsEmpty )
		Invoke("AnchorToTopRightNoBuffer");
	else
		Invoke("AnchorToTopRightStrategy");

}

//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================

simulated function UpdateDisplay()
{
	local UINarrativeMgr kNarrativeMgr;	

	kNarrativeMgr = Movie.Pres.m_kNarrativeUIMgr;

	AS_SetTitle(kNarrativeMgr.CurrentOutput.strTitle);
	AS_SetPortrait(kNarrativeMgr.CurrentOutput.strImage);
	AS_SetText( kNarrativeMgr.CurrentOutput.strText );	
	AS_SetScroll( kNarrativeMgr.CurrentOutput.fDuration * 0.9 );	// 0.9 fudge factor, scroll faster then the audio content
	
	RefreshSubtitleVisibility();
}

simulated function RefreshSubtitleVisibility()
{
	local XComEngine kEngine;

	kEngine = XComEngine(PC.Player.Outer);
	if ( ( kEngine != none && kEngine.bSubtitlesEnabled ) || WorldInfo.IsPlayInEditor())
	{
		AS_ShowSubtitles();
	}
	else
	{
		AS_HideSubtitles();
	}
}

//==============================================================================

simulated function AS_SetTitle(string DisplayText)
{
	Movie.ActionScriptVoid(MCPath$".SetTitle");
}

simulated function AS_SetText(string DisplayText)
{
	Movie.ActionScriptVoid(MCPath$".SetText");
}

simulated function AS_SetType(int iType)
{
	Movie.ActionScriptVoid(MCPath$".SetType");
}

simulated function AS_SetPortrait(string strPortrait)
{
	Movie.ActionScriptVoid(MCPath$".SetPortrait");
}

simulated function AS_IsStrategy()
{
	Movie.ActionScriptVoid(MCPath$".isStrategy");
}

// Call only after text has been set. 
//Flash will automatically start the tween, and calculate the delay in and out, when you call this
simulated function AS_SetScroll(float fTotalTime)
{
	Movie.ActionScriptVoid(MCPath$".Scroll");
}

simulated function AS_ShowSubtitles()
{
	Movie.ActionScriptVoid(MCPath$".showSubtitles");
}

simulated function AS_HideSubtitles()
{
	Movie.ActionScriptVoid(MCPath$".hideSubtitles");
}

simulated function Show()
{
	super.Show();
	UpdateDisplay();
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxCommLink/CommLink";
	MCName = "theCommLink";	
	InputState = eInputState_None;
	bShowDuringCinematic = true;
}
