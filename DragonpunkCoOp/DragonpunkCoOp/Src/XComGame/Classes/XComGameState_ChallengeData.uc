//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_ChallengeData.uc
//  AUTHOR:  Timothy Talley  --  11/21/2014
//  PURPOSE: Stores all the Challenge Mode Seed Data into the gamestate, which will also
//           be able to tell if the tactical game is a challenge mode game.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_ChallengeData extends XComGameState_BaseObject
	dependson(X2ChallengeModeDataStructures)
	native(Core);

var FullSeedData SeedData;
var string LeaderBoardName;

var name SquadSizeSelectorName;
var name ClassSelectorName;
var name AlienSelectorName;
var name RankSelectorName;
var name ArmorSelectorName;
var name PrimaryWeaponSelectorName;
var name SecondaryWeaponSelectorName;
var name UtilityItemSelectorName;
var name AlertForceLevelSelectorName;
var name EnemyForcesSelectorName;

cpptext
{
	virtual void Serialize(FArchive& Ar);
}

static function bool CreateChallengeData(XComGameState NewGameState, const out FullSeedData Data)
{
	local bool bSubmitNewGameState;
	local XComGameState_ChallengeData ChallengeEvent;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Check History to confirm that the Event Does not already Exist
	foreach History.IterateByClassType(class'XComGameState_ChallengeData', ChallengeEvent)
	{
		return false;
	}

	if (NewGameState == none)
	{
		// Create a new gamestate
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("XComGameState_ChallengeData: Create Event");
		bSubmitNewGameState = true;
	}
	else
	{
		bSubmitNewGameState = false;
	}

	// No existing EventType Object was found in the History, create one
	ChallengeEvent = XComGameState_ChallengeData(NewGameState.CreateStateObject(class'XComGameState_ChallengeData'));
	ChallengeEvent.SeedData = Data;

	// Add the event to the current state
	NewGameState.AddStateObject(ChallengeEvent);

	if (bSubmitNewGameState)
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
	}

	return true;
}

static function int CalcCurrentTurnNumber()
{
	local XComGameStateContext_TacticalGameRule GameRuleState;
	local XComGameState AssociatedGameStateFrame, StartState;
	local int CurrentTurn, HistoryIndex, NumGameStates;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Find the Current Turn
	CurrentTurn = 0;
	StartState = (History != none) ? History.GetStartState() : none;
	NumGameStates = (History != none) ? History.GetNumGameStates() : 0;
	for( HistoryIndex = ((StartState != none) ? StartState.HistoryIndex : 0) ; HistoryIndex < NumGameStates; ++HistoryIndex )
	{
		AssociatedGameStateFrame = History.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
		GameRuleState = XComGameStateContext_TacticalGameRule(AssociatedGameStateFrame.GetContext());
		if( GameRuleState != none && GameRuleState.GameRuleType == eGameRule_PlayerTurnBegin )
		{
			++CurrentTurn;
		}
	}
	return CurrentTurn;
}

defaultproperties
{

}