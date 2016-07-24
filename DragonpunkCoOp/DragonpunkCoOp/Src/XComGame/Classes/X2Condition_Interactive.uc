//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_Interactive.uc
//  AUTHOR:  David Burchanowski
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_Interactive extends X2Condition
	dependson(X2Condition_UnitInteractions);

var UnitInterationType InteractionType;
var name RequiredAbilityName;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	return 'AA_Success';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit UnitState;
	local array<XComInteractPoint> InteractionPoints;
	local XComInteractiveLevelActor InteractiveActor; 

	UnitState = XComGameState_Unit(kSource);
	if( UnitState == none )
		return 'AA_NotAUnit';

	// check to see if we have an interaction point for the selected target
	InteractiveActor = XComInteractiveLevelActor(kTarget.GetVisualizer());
	InteractionPoints = class'X2Condition_UnitInteractions'.static.GetUnitInteractionPoints(UnitState, InteractionType);
	if(InteractionPoints.Find('InteractiveActor', InteractiveActor) == INDEX_NONE)
	{
		return 'AA_NoTargets';
	}

	// validate that this is the correct ability type
	if(InteractionType == eInteractionType_Normal && InteractiveActor.InteractionAbilityTemplateName != RequiredAbilityName)
	{
		return 'AA_NoTargets';
	}
	else if(InteractionType == eInteractionType_Hack 
		&& InteractiveActor.HackAbilityTemplateName != RequiredAbilityName 
		&& RequiredAbilityName != '')
	{
		return 'AA_NoTargets';
	}

	return 'AA_Success';
}

DefaultProperties
{
}