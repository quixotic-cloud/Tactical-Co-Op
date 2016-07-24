//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ActivateAbility.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Activates the given units named ability on the target at TargetIndex. For LD scripting demo/tutorial save creation.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_ActivateAbility extends SequenceAction
	dependson(X2GameRuleset);

var XComGameState_Unit Unit;
var() string AbilityTemplateName;
var() int TargetIndex;

event Activated()
{
	local X2TacticalGameRuleset Rules;
	local XComGameStateHistory History;
	local GameRulesCache_Unit OutCacheData;
	local XComGameState_Ability Ability;
	local int ActionIndex;

	if (Unit == none)
	{
		`RedScreen("SeqAct_ActivateAbility: No unit provided");
		return;
	}

	// grab the available action information for the specified unit
	Rules = `TACTICALRULES;
	if(!Rules.GetGameRulesCache_Unit(Unit.GetReference(), OutCacheData))
	{
		`RedScreen("SeqAct_ActivateAbility: Couldn't find available action info for unit: " $ Unit.GetFullName());
		return;
	}

	// find the requested ability in the unit's available actions and activate it
	History = `XCOMHISTORY;
	for(ActionIndex = 0; ActionIndex < OutCacheData.AvailableActions.Length; ActionIndex++)
	{
		Ability = XComGameState_Ability(History.GetGameStateForObjectID(OutCacheData.AvailableActions[ActionIndex].AbilityObjectRef.ObjectID));
		if(string(Ability.GetMyTemplateName()) == AbilityTemplateName)
		{
			if(TargetIndex >= OutCacheData.AvailableActions[ActionIndex].AvailableTargets.Length)
			{
				`RedScreen("SeqAct_ActivateAbility: Target Index is out of range for unit: " $ Unit.GetFullName() $ " with ability " $ AbilityTemplateName);
				return;
			}

			class'XComGameStateContext_Ability'.static.ActivateAbility(OutCacheData.AvailableActions[ActionIndex], TargetIndex);
		
			return; // all done!
		}
	}

	// mayday, we couldn't find this ability
	`RedScreen("SeqAct_ActivateAbility: Could not find ability on " $ Unit.GetFullName() $ " with name " $ AbilityTemplateName);
}

defaultproperties
{
	ObjCategory="Automation"
	ObjName="Activate Ability"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="Ability Template",PropertyName=AbilityTemplateName)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Int',LinkDesc="TargetIndex",PropertyName=TargetIndex)
}