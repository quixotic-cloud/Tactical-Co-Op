//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIReplay
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: Provides an interface for operating X-Com 2's replay functionality
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIReplay extends UIScreen;

var UIPanel		m_kButtonContainer;
var UIButton	m_kStepForwardButton;
var UIButton	m_kStopButton;
var UIButton	m_kQuitButton;

var UIBGBox		m_kCurrentFrameInfoBG;
var UIText		m_kCurrentFrameInfoTitle;
var UIText		m_kCurrentFrameInfoText;

var UIBGBox		m_kMouseHitBG;

var int m_iPlayToFrame;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	super.InitScreen(InitController, InitMovie, InitName);

	m_kButtonContainer      = Spawn(class'UIPanel', self);
	m_kMouseHitBG           = Spawn(class'UIBGBox', m_kButtonContainer);	

	m_kMouseHitBG.InitBG('mouseHit', 0, 0, Movie.UI_RES_X, Movie.UI_RES_Y);	
	m_kMouseHitBG.SetAlpha(0.00001f);
	m_kMouseHitBG.ProcessMouseEvents(OnMouseHitLayerCallback);

	m_kStepForwardButton    = Spawn(class'UIButton', m_kButtonContainer);
	m_kStopButton           = Spawn(class'UIButton', m_kButtonContainer);
	m_kQuitButton			= Spawn(class'UIButton', m_kButtonContainer);

	m_kCurrentFrameInfoBG   = Spawn(class'UIBGBox', m_kButtonContainer);
	m_kCurrentFrameInfoTitle= Spawn(class'UIText', m_kButtonContainer);
	m_kCurrentFrameInfoText = Spawn(class'UIText', m_kButtonContainer);

	//Set up buttons
	m_kButtonContainer.InitPanel('buttonContainer');
	m_kButtonContainer.SetPosition(50, 50);
	
	m_kStepForwardButton.InitButton('stepForwardButton', "Step Forward", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	m_kStepForwardButton.SetX(250);
	m_kStepForwardButton.SetY(50);

	m_kStopButton.InitButton('stopButton', "Stop Replay", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kStopButton.SetX(50);
	m_kStopButton.SetY(50);

	m_kQuitButton.InitButton('quitButton', "Quit", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kQuitButton.SetX(50);
	m_kQuitButton.SetY(100);

	m_kCurrentFrameInfoBG.InitBG('infoBox', 700, 50, 500, 150);
	m_kCurrentFrameInfoTitle.InitText('infoBoxTitle', "<Empty>", true);
	m_kCurrentFrameInfoTitle.SetWidth(480);
	m_kCurrentFrameInfoTitle.SetX(710);
	m_kCurrentFrameInfoTitle.SetY(60);
	m_kCurrentFrameInfoText.InitText('infoBoxText', "<Empty>", true);
	m_kCurrentFrameInfoText.SetWidth(480);
	m_kCurrentFrameInfoText.SetX(710);
	m_kCurrentFrameInfoText.SetY(100);

	m_kButtonContainer.AddOnInitDelegate(PositionButtonContainer);
}

simulated function PositionButtonContainer( UIPanel Control )
{
	m_kButtonContainer.SetPosition(20, m_kButtonContainer.mc.GetNum("_y") - 40);
}

simulated function OnMouseHitLayerCallback( UIPanel control, int cmd )
{
	
}

simulated function OnButtonClicked(UIButton button)
{
	if(button == m_kStepForwardButton)
	{		
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		UpdateCurrentFrameInfoBox();
		if (XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInTutorial)
		{
			XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StepReplayForward();
			XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.GotoState('PlayUntilPlayerInputRequired');
		}
		else
		{
			XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StepReplayForward();
		}
	}
	else if ( button == m_kStopButton )
	{
		ToggleVisible();
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StopReplay();
		CloseScreen();
	}
	else if(button == m_kQuitButton)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		ConsoleCommand("disconnect");
	}
}

function ReplayToFrame(int iFrame)
{
	local XComReplayMgr kReplayMgr;

	kReplayMgr = XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr;
	`CHEATMGR.Slomo(100); // Speed up and replay
	if (kReplayMgr != None)
	{
		m_iPlayToFrame = Max(iFrame, kReplayMgr.CurrentHistoryFrame);
		m_iPlayToFrame = Min(iFrame, kReplayMgr.StepForwardStopFrame);
		DelayedReplayToFrame();
	}
}
function OnCompleteReplayToFrame()
{
	m_iPlayToFrame = -1;
	`CHEATMGR.Slomo(1); // Back to normal speed.
}

function DelayedReplayToFrame()
{
	local XComReplayMgr kReplayMgr;
	if (!class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
	{
		kReplayMgr = XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr;
		if (kReplayMgr != None)
		{
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			kReplayMgr.StepReplayForward();
			UpdateCurrentFrameInfoBox();

			if (kReplayMgr.CurrentHistoryFrame < m_iPlayToFrame)
			{
				SetTimer(0.1f, false, nameof(DelayedReplayToFrame));
			}
			else
			{
				OnCompleteReplayToFrame();
			}
		}
	}
	else
	{
		SetTimer(0.1f, false, nameof(DelayedReplayToFrame));
	}
}

simulated function UpdateCurrentFrameInfoBox(optional int Frame = -1)
{
	local string NewText;
	local int HistoryFrameIndex;

	if (Frame == -1)
	{
		HistoryFrameIndex = XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.CurrentHistoryFrame + 1;
	}
	else
	{
		HistoryFrameIndex = Frame;
	}

	NewText = "History Frame" @ HistoryFrameIndex @"/" @`XCOMHISTORY.GetNumGameStates();
	m_kCurrentFrameInfoTitle.SetText(NewText);

	NewText = `XCOMHISTORY.GetGameStateFromHistory(HistoryFrameIndex, eReturnType_Reference).GetContext().SummaryString();
	m_kCurrentFrameInfoText.SetText(NewText);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			// Consume this if you are watching a regular replay, else let it through for the tutorial. 
			if( `REPLAY.bInTutorial )
				bHandled = false;
			break;
		default:
			bHandled = false;
			break;
	}

	if (bHandled)
		return true;

	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	MCName          = "theScreen";
	InputState    = eInputState_Evaluate;

	bHideOnLoseFocus = false
}