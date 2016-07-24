//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISpecialMissionHUD.uc
//  AUTHORS: Brit Steiner 
//
//  PURPOSE: Container for special mission specific UI elements
//  NOTE: Reuses the flash elements from the MP HUD. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISpecialMissionHUD extends UIScreen;


//----------------------------------------------------------------------------
// MEMBERS
//

var UISpecialMissionHUD_Arrows				m_kArrows;
var UISpecialMissionHUD_TurnCounter			m_kGenericTurnCounter;
var UISpecialMissionHUD_TurnCounter			m_kTurnCounter2;
var UISpecialMissionHUD_Noise				m_kNoiseIndicators; 

var localized string m_strExtractionsTitle; 
var localized string m_strExtractionsBody; 
var localized string m_strHiveTitle; 
var localized string m_strHiveBody; 

//----------------------------------------------------------------------------
// METHODS
//

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIPanel CounterContainer; 
	local XComGameState_UITimer UiTimer;

	super.InitScreen(InitController, InitMovie, InitName);

	// ArrowPointers - Always initialize
	m_kArrows = Spawn(class'UISpecialMissionHUD_Arrows', self).InitArrows();

	// Noise indicators - Always initialize
	m_kNoiseIndicators = Spawn(class'UISpecialMissionHUD_Noise', self).InitNoise();
	
	// Turn counter HUD element 
	CounterContainer = Spawn(class'UIPanel', self).InitPanel('counters', );
	CounterContainer.Show(); //on the flash stage

	m_kGenericTurnCounter = Spawn(class'UISpecialMissionHUD_TurnCounter', CounterContainer);
	m_kGenericTurnCounter.InitTurnCounter('counter1'); //on the flash stage 

	//do we need this counter, or can we go ahead and remove it? It doesn't seem to do anything very useful.
	m_kTurnCounter2 = Spawn(class'UISpecialMissionHUD_TurnCounter', CounterContainer);
	m_kTurnCounter2.InitTurnCounter('counter2'); //on the flash stage 

	UiTimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));
	if (UiTimer != none)
	{
		if (UiTimer.ShouldShow)
		{
			//this is the info of the last loaded game state so we don't have to
			//submit a new gamestate
			m_kGenericTurnCounter.SetUIState(UiTimer.UiState);
			m_kGenericTurnCounter.SetLabel(UiTimer.DisplayMsgTitle);
			m_kGenericTurnCounter.SetSubLabel(UiTimer.DisplayMsgSubtitle);
			m_kGenericTurnCounter.SetCounter(string(UiTimer.TimerValue));
		}
	}
}

// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();

	RealizePosition();
	// Update position of turn counters if communication widget is visible
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( Movie.Pres.GetUIComm(), 'bIsVisible',  self, RealizePosition);
}

 // Move turn counters under the comm link when it's visible.
simulated function RealizePosition()
{
	local string sContainerPath;

	sContainerPath = MCPath $ ".counters";

	if( Movie.Pres.GetUIComm().bIsVisible )
		Movie.ActionScriptVoid(sContainerPath $ "." $ "AnchorBelowCommLink");
	else
		Movie.ActionScriptVoid(sContainerPath $ "." $ "AnchorToTopRight");
}

simulated function DialogueExtraction()
{
	local TDialogueBoxData kData;

	kData.eType = eDialog_Alert;
	kData.strTitle = m_strExtractionsTitle;
	kData.strText = m_strExtractionsBody;
	kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	
	Movie.Pres.UIRaiseDialog(kData);
}

simulated function DialogueHive()
{
	local TDialogueBoxData kData;

	kData.eType = eDialog_Alert;
	kData.strTitle = m_strHiveTitle;
	kData.strText = m_strHiveBody;
	kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	
	Movie.Pres.UIRaiseDialog(kData);
}

simulated function OnCommand( string cmd, string arg )
{
	//Currently, onyl the noise indicators animation complete signals back in this screen. 
	m_kNoiseIndicators.OnCommand(cmd, arg);
}

simulated function Remove()
{
	super.Remove();
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	MCName = "theSpecialMissionHUD";
	Package = "/ package/gfxSpecialMissionHUD/SpecialMissionHUD";

	InputState = eInputState_None;
	bHideOnLoseFocus = false;
}
