//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChallengeModeHUD.uc
//  AUTHORS: Russell Aasland
//
//  PURPOSE: Container for special challenge mode specific UI elements
//  NOTE: Reuses the flash elements from the MP HUD. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChallengeModeHUD extends UIScreen;

var XComGameState_Analytics Analytics;
var bool WaitingOnBanner;

var localized string m_ScoreLabel;
var localized array<string> m_BannerLabels;

simulated function InitScreen( XComPlayerController InitController, UIMovie InitMovie, optional name InitName )
{
	local Object ThisObj;

	super.InitScreen( InitController, InitMovie, InitName );

	// Analytics are a singleton type so we can get it once and look at it during the tick.
	Analytics = XComGameState_Analytics( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent( ThisObj, 'ChallengeModeScoreChange', ChallengeScoreChanged );
}

// Flash side is initialized.
simulated function OnInit( )
{
	local string sContainerPath;

	super.OnInit();
	Show();

	MC.BeginFunctionOp( "setChallengeScoreDirect" );
	MC.QueueNumber( 0 );
	MC.EndOp( );

	Movie.ActionScriptVoid( Movie.Pres.GetUIComm( ).MCPath $ "." $ "setCommlinkChallengeOffset" );
	Movie.ActionScriptVoid( Movie.Pres.GetUIComm( ).MCPath $ "." $ "AnchorToTopRight" );

	sContainerPath = XComPresentationLayer( Movie.Pres ).GetSpecialMissionHUD( ).MCPath $ ".counters";
	Movie.ActionScriptVoid( sContainerPath $ "." $ "setCounterChallengeOffset" );	
}

simulated function Remove( )
{
	super.Remove( );
}

simulated event Tick( float DeltaTime )
{
	local XComGameState_TimerData Timer;
	local int TotalSeconds, Minutes, Seconds;

	Timer = XComGameState_TimerData( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_TimerData', true ) );

	if ((Timer != none) && Timer.bIsChallengeModeTimer)
	{
		if (!`TACTICALRULES.UnitActionPlayerIsAI())
		{
			Timer.bStopTime = class'XComGameStateVisualizationMgr'.static.VisualizerBusy( ) && !`Pres.UIIsBusy( );
		}

		if (!Timer.bStopTime)
		{
			TotalSeconds = Timer.GetCurrentTime( );
			if (TotalSeconds >= 0)
			{
				Minutes = (TotalSeconds / 60);
				Seconds = TotalSeconds % 60;

				MC.BeginFunctionOp( "setChallengeTimer" );

				MC.QueueNumber( Minutes );
				MC.QueueNumber( Seconds );

				MC.EndOp( );

				if (Minutes < 10)
				{
					if (Minutes < 5)
					{
						MC.FunctionVoid( "setChallengeTimerWarning" );
					}
					else
					{
						MC.FunctionVoid( "setChallengeTimerCaution" );
					}
				}
			}
		}
		else
		{
			Timer.AddPauseTime( DeltaTime );
		}
	}
}

function UpdateChallengeScore( ChallengeModePointName ScoringType, int AddedPoints )
{
	MC.BeginFunctionOp("setChallengeScore");

	MC.QueueString( m_ScoreLabel );
	MC.QueueNumber( AddedPoints );
	MC.QueueString( m_BannerLabels[ ScoringType ] );

	MC.EndOp( );
}

function TriggerChallengeBanner(  )
{
	MC.FunctionVoid( "setChallengeBanner" );

	WaitingOnBanner = true;
}

simulated function OnCommand( string cmd, string arg )
{
	switch( cmd )
	{
		case "ChallengeBannerComplete": WaitingOnBanner = false;
			break;
	}
}

function bool IsWaitingForBanner( )
{
	return WaitingOnBanner;
}

function EventListenerReturn ChallengeScoreChanged(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_ChallengeScore Context;

	Context = XComGameStateContext_ChallengeScore( GameState.GetContext( ) );

	UpdateChallengeScore( Context.ScoringType, Context.AddedPoints );

	return ELR_NoInterrupt;
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	MCName = "theScreen";
	Package = "/ package/gfxChallengeHUD/ChallengeHUD";

	InputState = eInputState_None;
	bHideOnLoseFocus = false;

	WaitingOnBanner = false;
}