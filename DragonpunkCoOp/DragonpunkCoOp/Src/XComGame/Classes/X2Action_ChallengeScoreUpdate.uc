//---------------------------------------------------------------------------------------
//  FILE:    X2Action_ChallengeScoreUpdate.uc
//  AUTHOR:  Russell Aasland
//  PURPOSE: Action for triggering visual changes to the challenge score
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Action_ChallengeScoreUpdate extends X2Action;

var UIChallengeModeHUD ChallengeHUD;

var ChallengeModePointName ScoringType;
var int AddedPoints;

function Init( const out VisualizationTrack InTrack )
{
	super.Init( InTrack );
}

event bool BlocksAbilityActivation( )
{
	return true;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event BeginState( Name PreviousStateName )
	{
		ChallengeHUD = `PRES.GetChallengeModeHUD();
		ChallengeHUD.TriggerChallengeBanner( );
	}

Begin:

	while (ChallengeHUD.IsWaitingForBanner())
	{
		Sleep( 0.0f );
	}
	
	CompleteAction( );
}

defaultproperties
{
	TimeoutSeconds = 20;
}