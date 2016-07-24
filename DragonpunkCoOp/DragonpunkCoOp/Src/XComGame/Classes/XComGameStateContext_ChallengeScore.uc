//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_ChallengeScore.uc
//  AUTHOR:  Russell Aasland
//  PURPOSE: Context for changes to the challenge score
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameStateContext_ChallengeScore extends XComGameStateContext
	dependson( XComGameState_Analytics );

var ChallengeModePointName ScoringType;
var int AddedPoints;
var int CategoryPointValue;

function bool Validate( optional EInterruptionStatus InInterruptionStatus )
{
	return true;
}

function XComGameState ContextBuildGameState( )
{
	// this class isn't meant to be used with SubmitGameStateContext. Use plain vanilla SubmitGameState instead.
	`assert(false);
	return none;
}

static function XComGameState CreateChangeState( ChallengeModePointName Type )
{
	local XComGameStateContext_ChallengeScore container;
	container = XComGameStateContext_ChallengeScore(CreateXComGameStateContext());
	container.ScoringType = Type;
	return `XCOMHISTORY.CreateNewGameState( true, container );
}

protected function ContextBuildVisualization( out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray )
{
	local VisualizationTrack BuildTrack;
	local X2Action_ChallengeScoreUpdate Action;
	local XComGameStateHistory History;

	if (CategoryPointValue == 0) // no points actually awarded, no banner
	{
		return;
	}

	// Not Challenge Mode
	if (`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) == none)
	{
		return;
	}

	// we only want to act as a fence in instance where we create actions
	SetVisualizationFence( true, 20.0f );

	History = `XCOMHISTORY;

	BuildTrack.StateObject_OldState = `XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics');
	BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
	BuildTrack.TrackActor = History.GetVisualizer( `TACTICALRULES.GetLocalClientPlayerObjectID() );

	Action = X2Action_ChallengeScoreUpdate( class'X2Action_ChallengeScoreUpdate'.static.AddToVisualizationTrack( BuildTrack, self ) );
	Action.ScoringType = ScoringType;
	Action.AddedPoints = AddedPoints;

	VisualizationTracks.AddItem( BuildTrack );
}

function string SummaryString( )
{
	return "Challenge Score Change";
}