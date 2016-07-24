//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MissionSiteAvengerDefense.uc
//  AUTHOR:  Joe Weinhoffer  --  06/26/2015
//  PURPOSE: This object represents the instance data for an Avenger Defense mission site 
//			on the world map
//          
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_MissionSiteAvengerDefense extends XComGameState_MissionSite
	native(Core);

var() StateObjectReference AttackingUFO;

//---------------------------------------------------------------------------------------
//----------- XComGameState_GeoscapeEntity Implementation -------------------------------
//---------------------------------------------------------------------------------------

function bool RequiresAvenger()
{
	// Avenger Defense requires the Avenger at the mission site
	return true;
}

function SelectSquad()
{
	local XGStrategy StrategyGame;

	BeginInteraction();

	StrategyGame = `GAME;
	StrategyGame.PrepareTacticalBattle(ObjectID);
	`HQPRES.UISquadSelect(true); // prevent backing out of the squad select screen
}

// Complete the squad select interaction; the mission will not begin until this destination has been reached
function SquadSelectionCompleted()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Skyranger SkyrangerState;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Load Squad onto Skyranger");
	SkyrangerState = XComGameState_Skyranger(NewGameState.CreateStateObject(class'XComGameState_Skyranger', XComHQ.SkyrangerRef.ObjectID));
	SkyrangerState.SquadOnBoard = true;
	NewGameState.AddStateObject(SkyrangerState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Transfer directly to the mission
	ConfirmMission();
}

function DestinationReached()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local array<XComGameState_Unit> AllSoldiers;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AllSoldiers = XComHQ.GetSoldiers();

	if(AllSoldiers.Length == 0)
	{
		class'X2StrategyElement_DefaultAlienAI'.static.PlayerLossAction();
		return;
	}

	BeginInteraction();
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Avenger Attacked Event");
	`XEVENTMGR.TriggerEvent('AvengerAttacked', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
				
	`HQPRES.UIUFOAttack(self);
}

function XComGameState_UFO GetAttackingUFO()
{
	return XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
}