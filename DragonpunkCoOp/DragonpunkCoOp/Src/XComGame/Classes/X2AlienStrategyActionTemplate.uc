//---------------------------------------------------------------------------------------
//  FILE:    X2AlienStrategyActionTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AlienStrategyActionTemplate extends X2StrategyElementTemplate;

var () array<name> Conditions;
var () Delegate<PerformActionDelegate> PerformActionFn;

delegate PerformActionDelegate();

//---------------------------------------------------------------------------------------
// All conditions to perform this action are met
function bool CanPerformAction()
{
	local X2StrategyElementTemplateManager StratManager;
	local X2AlienStrategyConditionTemplate ConditionTemplate;
	local int idx;

	StratManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for(idx = 0; idx < Conditions.Length; idx++)
	{
		ConditionTemplate = X2AlienStrategyConditionTemplate(StratManager.FindStrategyElementTemplate(Conditions[idx]));

		if(ConditionTemplate == none || ConditionTemplate.IsConditionMetFn == none)
		{
			`assert(false); // Bad condition name or no IsMet function
		}

		// if one condition isn't met, can't perform the action
		if(!ConditionTemplate.IsConditionMetFn())
		{
			return false;
		}
	}

	// all conditions are met
	return true;
}


//---------------------------------------------------------------------------------------
DefaultProperties
{
}