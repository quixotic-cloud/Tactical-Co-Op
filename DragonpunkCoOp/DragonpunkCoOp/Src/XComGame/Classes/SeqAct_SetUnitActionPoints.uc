//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_SetUnitActionPoints.uc
//  AUTHOR:  David Burchanowski  --  4/14/2016
//  PURPOSE: Allows the LDs to manually adjust a unit or unit's action points
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_SetUnitActionPoints extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

enum SeqAct_SetUnitActionPoints_SetType
{
	SetType_Add,
	SetType_Remove,
	SetType_Set,
};

var XComGameState_Unit UnitState;
var() int ActionPoints;
var() SeqAct_SetUnitActionPoints_SetType SetType;

function Activated();
function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks);

function ModifyKismetGameState(out XComGameState GameState)
{
	local array<XComGameState_Unit> StatesToSet;
	local XComGameState_Unit StateToSet;
	local XGBattle_SP Battle;
	local int Index;

	Battle = XGBattle_SP(`BATTLE);
	
	// get the list of units to apply the effect to
	if(InputLinks[0].bHasImpulse)
	{
		StatesToSet.AddItem(UnitState);
	}
	else if(InputLinks[1].bHasImpulse)
	{
		Battle.GetHumanPlayer().GetPlayableUnits(StatesToSet);
	}
	else if(InputLinks[2].bHasImpulse)
	{
		Battle.GetAIPlayer().GetPlayableUnits(StatesToSet);
	}
	else if(InputLinks[3].bHasImpulse)
	{
		Battle.GetCivilianPlayer().GetPlayableUnits(StatesToSet);
	}

	// and then apply the desired operation to each unit
	foreach StatesToSet(StateToSet)
	{
		StateToSet = XComGameState_Unit(GameState.CreateStateObject(StateToSet.Class, StateToSet.ObjectID));

		switch(SetType)
		{
		case SetType_Set:
			StateToSet.ActionPoints.Length = 0;
			// intentional fallthrough
		case SetType_Add:
			for(Index = 0; Index < ActionPoints; Index++)
			{
				StateToSet.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
			}
			break;
		case SetType_Remove:
			StateToSet.ActionPoints.Length = Max(0, StateToSet.ActionPoints.Length - ActionPoints);
			break;
		}

		GameState.AddStateObject(StateToSet);
	}
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Set Action Points"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Single Unit")
	InputLinks(1)=(LinkDesc="XCom Squad")
	InputLinks(2)=(LinkDesc="Alien Squad")
	InputLinks(3)=(LinkDesc="Civilian Squad")
	
	bAutoActivateOutputLinks=true
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=UnitState)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Int',LinkDesc="Action Points",PropertyName=ActionPoints)
}
