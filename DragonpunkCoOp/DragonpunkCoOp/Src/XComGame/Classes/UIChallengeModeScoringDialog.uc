//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChallengeModeScoringDialog.uc
//  AUTHORS: Russell Aasland
//
//  PURPOSE: Container for special challenge mode dialog showing possible points for challange match
//  NOTE: Reuses the flash elements from the MP HUD. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChallengeModeScoringDialog extends UIScreen;

var UIButton m_ContinueButton;

var localized string m_Header;
var localized string m_TotalLabel;
var localized array<string> m_ScoreLabels;
var localized string m_ScoreDescription1;
var localized string m_ScoreDescription2;
var localized string m_ButtonLabel;

simulated function InitScreen( XComPlayerController InitController, UIMovie InitMovie, optional name InitName )
{
	super.InitScreen( InitController, InitMovie, InitName );

	m_ContinueButton = Spawn( class'UIButton', self );
	m_ContinueButton.InitButton( 'continueButton', , OnContinueButtonPress );
}

// Flash side is initialized.
simulated function OnInit( )
{
	local int idx, count, score;
	local XComGameState_Analytics Analytics;
	local XComGameState_BattleData BattleData;
	local ChallengeModeScoringTableEntry ScoreEntry;

	super.OnInit( );

	Analytics = XComGameState_Analytics( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );
	BattleData = XComGameState_BattleData( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	ScoreEntry = Analytics.GetChallengePointsTable( );

	MC.BeginFunctionOp( "setScoreHeader" );
	MC.QueueString( m_Header );
	MC.EndOp( );

	MC.BeginFunctionOp( "setScoreTotal" );
	MC.QueueString( m_TotalLabel );
	MC.QueueString( string( CalcMaxChallengeScore( ScoreEntry ) ) );
	MC.EndOp( );

	count = 0;
	for (idx = 0; idx < m_ScoreLabels.Length; ++idx)
	{
		if (ScoreEntry.Points[idx] > 0)
		{
			score = ScoreEntry.Points[idx];
			if (idx == CMPN_KilledEnemy)
			{
				score += class'XComGameState_Analytics'.default.ChallengeModeEnemyBonusPerForceLevel * BattleData.m_iForceLevel;
			}

			MC.BeginFunctionOp( "addScoreRow" );
			MC.QueueNumber( count++ );
			MC.QueueString( m_ScoreLabels[idx] );
			MC.QueueString( string(score) );
			MC.EndOp( );
		}
	}

	MC.BeginFunctionOp( "setScoreDescription" );
	MC.QueueString( m_ScoreDescription1 );
	MC.QueueString( m_ScoreDescription2 );
	MC.EndOp( );

	MC.BeginFunctionOp( "setScoreButton" );
	MC.QueueString( m_ButtonLabel );
	MC.EndOp( );
}

simulated function Remove( )
{
	super.Remove( );
}

function OnContinueButtonPress( UIButton Button )
{
	`PRES.ScreenStack.PopFirstInstanceOfClass( class'UIChallengeModeScoringDialog' );
}

private function int CalcMaxChallengeScore( ChallengeModeScoringTableEntry ScoreEntry )
{
	local int MaxScore;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_ObjectivesList Objectives;
	local XComGameState_Unit Unit;
	local XComUnitPawn UnitPawn;

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );

	foreach History.IterateByClassType( class'XComGameState_ObjectivesList', Objectives )
	{
		break;
	}
	if (Objectives != none)
	{
		MaxScore += Objectives.ObjectiveDisplayInfos.Length * ScoreEntry.Points[ CMPN_CompletedObjective ];
	}

	foreach History.IterateByClassType( class'XComGameState_Unit', Unit )
	{
		UnitPawn = Unit.m_kPawn;

		switch (UnitPawn.m_eTeam)
		{
			case eTeam_XCom:
				MaxScore += ScoreEntry.Points[ CMPN_UninjuredSoldiers ];
				//MaxScore += ScoreEntry.Points[ CMPN_AliveSoldiers ]; mutually exclusive with Uninjured
				break;

			case eTeam_Alien: MaxScore += ScoreEntry.Points[ CMPN_KilledEnemy ] + BattleData.m_iForceLevel * class'XComGameState_Analytics'.default.ChallengeModeEnemyBonusPerForceLevel;
				break;

			case eTeam_Neutral: MaxScore += ScoreEntry.Points[ CMPN_CiviliansSaved ];
				break;
		}
	}

	// Add points for the 3 man reinforcement group that will show up
	MaxScore += (ScoreEntry.Points[ CMPN_KilledEnemy ] + BattleData.m_iForceLevel * class'XComGameState_Analytics'.default.ChallengeModeEnemyBonusPerForceLevel) * 3;

	return MaxScore;
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	MCName = "theScreen";
	Package = "/ package/gfxChallengeScoreScreen/ChallengeScoreScreen";
}