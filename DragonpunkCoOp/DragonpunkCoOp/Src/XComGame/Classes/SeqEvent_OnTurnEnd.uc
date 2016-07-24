//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_OnTurnEnd.uc
//  AUTHOR:  David Burchanowski  --  1/21/2014
//  PURPOSE: Fires when a player's turn ends
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_OnTurnEnd extends SeqEvent_X2GameState;

event Activated()
{
	local X2TacticalGameRuleset Rules;

	// determine which player is currently active and fire
	OutputLinks[0].bHasImpulse = false;
	OutputLinks[1].bHasImpulse = false;
	OutputLinks[2].bHasImpulse = false;

	Rules = `TACTICALRULES;

	switch(Rules.GetUnitActionTeam())
	{
	case eTeam_XCom:
		OutputLinks[0].bHasImpulse = true;
		break;
	case eTeam_Alien:
		OutputLinks[1].bHasImpulse = true;
		break;
	case eTeam_Neutral:
		OutputLinks[2].bHasImpulse = true;
		break;
	}
}

defaultproperties
{
	VariableLinks.Empty

	OutputLinks(0)=(LinkDesc="XCom")
	OutputLinks(1)=(LinkDesc="Alien")
	OutputLinks(2)=(LinkDesc="Civilian")

	bGameSequenceEvent=true
	bConvertedForReplaySystem=true

	ObjCategory="Gameplay"
	ObjName="On Turn End"
}
