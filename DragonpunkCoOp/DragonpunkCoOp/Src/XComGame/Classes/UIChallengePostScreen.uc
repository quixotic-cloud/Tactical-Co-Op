//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChallengePostScreen.uc
//  AUTHORS: Russell Aasland
//
//  PURPOSE: Container for special challenge mode specific UI elements
//  NOTE: Reuses the flash elements from the MP HUD. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChallengePostScreen extends UIScreen;

var localized string m_Header;
var localized string m_ScoreLabel;
var localized string m_RankLabel;
var localized string m_LeaderboardLabel;
var localized string m_Description;
var localized string m_ButtonLabel;

var string m_ImagePath;

var UIButton m_ContinueButton;
var UIButton m_LeaderboardButton;

simulated function InitScreen( XComPlayerController InitController, UIMovie InitMovie, optional name InitName )
{
	super.InitScreen( InitController, InitMovie, InitName );

	m_ContinueButton = Spawn( class'UIButton', self );
	m_ContinueButton.InitButton( 'continueButton', , OnContinueButtonPress );

	m_LeaderboardButton = Spawn( class'UIButton', self );
	m_LeaderboardButton.InitButton( 'leaderboardButton', , OnLeaderboardButtonPress );
}

// Flash side is initialized.
simulated function OnInit( )
{
	local string TempBlank;

	local XComGameState_Analytics Analytics;
	local WorldInfo LocalWorldInfo;
	local int Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond;
	local string TimeString;

	super.OnInit( );

	Analytics = XComGameState_Analytics( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );

	LocalWorldInfo = class'Engine'.static.GetCurrentWorldInfo( );

	LocalWorldInfo.GetSystemTime( Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond );
	`ONLINEEVENTMGR.FormatTimeStampSingleLine12HourClock( TimeString, Year, Month, Day, Hour, Minute );

	TempBlank = "XXXXXXXXXX";

	MC.BeginFunctionOp( "setScreenData" );

	MC.QueueString( m_ImagePath ); //strImage
	MC.QueueString( m_Header ); //strHeader
	MC.QueueString( GetALocalPlayerController().PlayerReplicationInfo.PlayerName ); //strGamertag
	MC.QueueString( TimeString ); //strTime
	MC.QueueString( m_ScoreLabel ); //strScoreLabel
	MC.QueueString( string( int(Analytics.GetFloatValue( 'CM_TOTAL_SCORE' ) ) ) ); //strScoreValue
	MC.QueueString( m_RankLabel ); //strRankLabel
	MC.QueueString( TempBlank ); //strRankValue1
	MC.QueueString( TempBlank ); //strRankValue2
	MC.QueueString( m_LeaderboardLabel ); //strLeaderboardLabel
	MC.QueueString( m_Description ); //strDescription
	MC.QueueString( m_ButtonLabel ); //strContinue

	MC.EndOp( );
}

simulated function Remove( )
{
	super.Remove( );
}

function OnContinueButtonPress( UIButton Button )
{
	CloseScreen( );

	// Clear Modal before pop state does it's Pop is kicked off.
	`XENGINE.SetAlienFXColor( eAlienFX_Cyan );

	if (!Movie.Pres.IsA( 'XComHQPresentationLayer' ))
		`TACTICALRULES.bWaitingForMissionSummary = false;
	else
	{
		`HQPRES.UIAfterAction( true );
	}
}

function OnLeaderboardButtonPress( UIButton Button )
{
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	MCName = "theScreen";
	Package = "/ package/gfxChallengePostGame/ChallengePostGame";

	m_ImagePath = "img:///UILibrary_Common.ChallengeMode.Challenge_XComPoster01";
}