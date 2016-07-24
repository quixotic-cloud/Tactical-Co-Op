//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_MoveUnitToTile.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Moves a unit to a given tile (if possible) via kismet. For LD scripting demo/tutorial save creation.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_GetUnitByIndex extends SequenceAction;

var XComGameState_Unit Unit;
var int Index;

event Activated()
{
	local XGPlayer RequestedPlayer;
	local array<XComGameState_Unit> Units;

	RequestedPlayer = GetRequestedPlayer();
	RequestedPlayer.GetUnits(Units);

	if(Index >=0 && Index < Units.Length)
	{
		Unit = Units[Index];
	}
	else
	{
		`Redscreen("SeqAct_GetUnitByIndex: Index " $ Index $ " is out of range, player only has " $ Units.Length $ " units on team!");
	}
}

function protected XGPlayer GetRequestedPlayer()
{
	local XComTacticalGRI TacticalGRI;
	local XGBattle_SP Battle;
	local XGPlayer RequestedPlayer;

	TacticalGRI = `TACTICALGRI;
	Battle = (TacticalGRI != none)? XGBattle_SP(TacticalGRI.m_kBattle) : none;
	if(Battle != none)
	{
		if(InputLinks[0].bHasImpulse)
		{
			RequestedPlayer = Battle.GetHumanPlayer();
		}
		else if(InputLinks[1].bHasImpulse)
		{
			RequestedPlayer = Battle.GetAIPlayer();
		}
		else
		{
			RequestedPlayer = Battle.GetCivilianPlayer();
		}
	}

	return RequestedPlayer;
}

defaultproperties
{
	ObjCategory="Automation"
	ObjName="Get Unit By Index"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="XCom")
	InputLinks(1)=(LinkDesc="Alien")
	InputLinks(2)=(LinkDesc="Civilian")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit,bWriteable=true)
	VariableLinks(1)=(ExpectedType=class'SeqVar_INT',LinkDesc="Index",PropertyName=DestinationActor)
}