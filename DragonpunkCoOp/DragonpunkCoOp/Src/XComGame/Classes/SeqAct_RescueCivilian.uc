//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_RescueCivilian.uc
//  AUTHOR:  David Burchanowski  --  10/30/2014
//  PURPOSE: Causes the specified civilian unit to escape the battlefield
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqAct_RescueCivilian extends SequenceAction;

var private XComGameState_Unit CivilianUnit;

event Activated()
{
	local XGUnit Civilian;
	local XGAIPlayer_Civilian CivilianPlayer;

	if(CivilianUnit == none)
	{
		`Redscreen("SeqAct_RescueCivilian: Civilian Unit is none.");
		return;
	}

	if(CivilianUnit.GetTeam() != eTeam_Neutral)
	{
		`Redscreen("SeqAct_RescueCivilian: Attempting to rescue a non-civilian unit.");
		return;
	}
	// Force visualization to start after the previous move that kicked this off finished.
	`TACTICALRULES.LastNeutralReactionEventChainIndex = `XCOMHISTORY.GetCurrentHistoryIndex();

	// Kick off civilian exit behavior.
	Civilian = XGUnit(CivilianUnit.GetVisualizer());
	XGAIBehavior_Civilian(Civilian.m_kBehavior).InitActivate(); // Give action points before attempting to move.
	Civilian.m_kBehavior.InitTurn(false);
	class'X2AIBTDefaultActions'.static.CivilianExitMap(CivilianUnit);
	CivilianPlayer = XGAIPlayer_Civilian(Civilian.GetPlayer());
	CivilianPlayer.AddToMoveList(Civilian);
}

defaultproperties
{
	ObjName="Rescue Civilian"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Civilian Unit",PropertyName=CivilianUnit,bWriteable=TRUE)
}