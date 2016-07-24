//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_TeamHasNoPlayableUnitsRemaining.uc
//  AUTHOR:  David Burchanowski  --  1/21/2014
//  PURPOSE: Event for letting kismet do things when a team has lost all playable units
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_TeamHasNoPlayableUnitsRemaining extends SeqEvent_X2GameState;

var private XGPlayer LosingPlayer;

event Activated()
{
	local XComGameStateHistory History;
	local X2TacticalGameRuleset TacticalRules;
	local int ImpulseIdx, LinkIdx, ObjIdx, iMinLength;
	local array<ETeam> Teams;
	local SeqVar_Object SeqObj;
	local array<Object> ObjValues;
	local XComGameState_Player LosingPlayerState, ThisPlayerState;

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;
	`assert(TacticalRules != none);

	Teams.AddItem(eTeam_XCom);
	Teams.AddItem(eTeam_Alien);
	Teams.AddItem(eTeam_Neutral);
	Teams.AddItem(eTeam_One);
	Teams.AddItem(eTeam_Two);

	for (ImpulseIdx = 0; ImpulseIdx < OutputLinks.Length; ++ImpulseIdx)
	{
		OutputLinks[ImpulseIdx].bHasImpulse = (LosingPlayer.m_eTeam == Teams[ImpulseIdx]);
	}

	LosingPlayerState = XComGameState_Player(History.GetGameStateForObjectID(LosingPlayer.ObjectID));
	ThisPlayerState = XComGameState_Player(History.GetGameStateForObjectID(TacticalRules.GetLocalClientPlayerObjectID()));
	ObjValues.AddItem(LosingPlayerState);
	ObjValues.AddItem(ThisPlayerState);

	iMinLength = Min(ObjValues.Length, VariableLinks.Length);
	for (ObjIdx = 0; ObjIdx < iMinLength; ++ObjIdx)
	{
		for (LinkIdx = 0; LinkIdx < VariableLinks[ObjIdx].LinkedVariables.Length; ++LinkIdx)
		{
			SeqObj = SeqVar_Object(VariableLinks[ObjIdx].LinkedVariables[LinkIdx]);
			SeqObj.SetObjectValue(ObjValues[ObjIdx]);
		}
	}
}

function FireEvent(XGPlayer InPlayer)
{
	LosingPlayer = InPlayer;
	CheckActivate(InPlayer, none);
}

defaultproperties
{
	ObjName="Team Has No Playable Units Remaining"

	OutputLinks(0)=(LinkDesc="XCom")
	OutputLinks(1)=(LinkDesc="Alien")
	OutputLinks(2)=(LinkDesc="Civilian")
	OutputLinks(3)=(LinkDesc="Team One")
	OutputLinks(4)=(LinkDesc="Team Two")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Losing Player",bWriteable=true)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="This Player",bWriteable=true)
}