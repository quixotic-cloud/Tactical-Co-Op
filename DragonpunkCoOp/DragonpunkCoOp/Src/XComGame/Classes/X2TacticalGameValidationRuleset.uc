//---------------------------------------------------------------------------------------
//  FILE:    X2TacticalGameValidationRuleset.uc
//  AUTHOR:  Rick Matchett  --  08/04/2015
//  PURPOSE: Allows the history to be populated with input states from a second saved history.
//			 Used for validating submitted challenge mode game saves.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TacticalGameValidationRuleset extends X2TacticalGameRuleset;

simulated state TurnPhase_Validator
{

Begin:
	CachedHistory.ValidateHistory();
	`log("Validation Complete");
	GotoState('');
}

simulated function name GetNextTurnPhase(name CurrentState, optional name DefaultPhaseName='TurnPhase_End')
{
	switch (CurrentState)
	{
	case 'CreateChallengeGame':
		return 'TurnPhase_Validator';
	}
	`assert(false);
	return DefaultPhaseName;
}

defaultproperties
{

}
