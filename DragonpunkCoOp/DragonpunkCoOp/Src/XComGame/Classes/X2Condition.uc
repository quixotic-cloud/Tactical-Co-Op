//---------------------------------------------------------------------------------------
//  FILE:    X2Condition.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition extends Object 
	native(Core) 
	abstract;

enum EValueCheck
{
	eCheck_Exact,
	eCheck_RangeInclusive,          // Does the value match the min or max?
	eCheck_RangeExclusive,          // Value is within the min or max but not at their values
	eCheck_GreaterThan,             // Checks the Max value
	eCheck_GreaterThanOrEqual,      // Checks the Max value
	eCheck_LessThan,                // Checks the Min value
	eCheck_LessThanOrEqual          // Checks the Min value
};

struct native CheckConfig
{
	var EValueCheck     CheckType;
	var int             Value;
	var int             ValueMin;   // Used for Range
	var int             ValueMax;   // Used for Range
};

// if true, this condition is only required to activate an ability. Further validations, such as on interruption and resume,
// are unneeded and will automatically pass. The original use case for this is visibility. You may have visibility to the target
// when an ability is activated, but can be interrupted in a location where you no longer have visibility to the target. In this case
// rechecking visibility makes no sense.
var private bool RequiredOnlyForActivation;

native function name MeetsCondition(XComGameState_BaseObject kTarget);
native function name MeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource);
native function name AbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget);

/*
 * These should ONLY be called from the native functions above.
 */
event name CallMeetsCondition(XComGameState_BaseObject kTarget) { return 'AA_Success'; }
event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) { return 'AA_Success'; }
event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget) { return 'AA_Success'; }

native function name PerformValueCheck(const int Value, const CheckConfig tConfig);