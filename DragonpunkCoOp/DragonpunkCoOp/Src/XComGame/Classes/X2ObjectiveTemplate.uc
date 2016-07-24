//---------------------------------------------------------------------------------------
//  FILE:    X2ObjectiveTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ObjectiveTemplate extends X2StrategyElementTemplate
	dependson(X2StrategyGameRulesetDataStructures);

// Display Info
var localized string		Title; 
var localized string		LocLongDescription;
var localized string		SubObjectiveText; // For objectives that don't have subobjectives
var string					ImagePath;

var bool					bMainObjective; // i.e. not a subobjective, appear as a header not a checkbox
var array<Name>				Steps; // subobjectives to complete the main objective, ADD IN ORDER

// If true, this objective will never be explicitly shown in the Objectives list UI.
var bool					bNeverShowObjective;

// Check this objective for completion when this event occurs.
var Name					CompletionEvent;

// If true, this Objective is completed during tactical missions, and therefor need simulated completion when playing through SimCombat.
var bool					TacticalCompletion;

// The objective to start when this objective is completed.
var array<Name>				NextObjectives;

// The event which causes this objective to become revealed.  If '', will become revealed when assigned.
var Name					RevealEvent;

// If > 0, how long after the objective is revealed (or the previous nag is issued) to kick off the next nag.
var int						NagDelayHours;

// This objective only exists in the tutorial, forced complete otherwise as it could block techs, items, etc.
var bool					bTutorialOnly;

// The set of narrative triggers that can be played for this objective.
var array<NarrativeTrigger> NarrativeTriggers;

// The set of requirements that must be met in order for this objective to be successfully assigned.
var StrategyRequirement		AssignmentRequirements;

// The set of requirements that must be met in order for this objective to successfully complete.
var StrategyRequirement		CompletionRequirements;

// Call to check if the prereqs for this objective have been met such that it is permitted to be assigned.
var Delegate<ObjectivePrereqsMetDelegate> ObjectivePrereqsMetFn;

// Call to check if the requirements of this objective have been met such that it is permitted to complete.
var Delegate<ObjectiveRequirementsMetDelegate> ObjectiveRequirementsMetFn;

// Call when this objective is assigned to perform specialized additional behavior
var Delegate<AssignObjectiveDelegate> AssignObjectiveFn;

// Call when this objective is completed to perform specialized additional behavior
var Delegate<CompleteObjectiveDelegate> CompleteObjectiveFn;

// Call to check if this objective is in progress (Applies to things like research, build item, make contact, etc.)
var Delegate<InProgressDelegate> InProgressFn;

// Call for objectives that require game data for their display string
var Delegate<GetDisplayStringDelegate> GetDisplayStringFn;

delegate bool ObjectivePrereqsMetDelegate(XComGameState NewGameState, XComGameState_Objective ObjectiveState);
delegate bool ObjectiveRequirementsMetDelegate(XComGameState NewGameState, XComGameState_Objective ObjectiveState);
delegate CompleteObjectiveDelegate(XComGameState NewGameState, XComGameState_Objective ObjectiveState);
delegate AssignObjectiveDelegate(XComGameState NewGameState, XComGameState_Objective ObjectiveState);
delegate bool InProgressDelegate();
delegate NarrativeCompleteDelegate();
delegate bool NarrativeRequirementsMet();
delegate string GetDisplayStringDelegate(XComGameState NewGameState, XComGameState_Objective ObjectiveState);

//---------------------------------------------------------------------------------------
function XComGameState_Objective CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Objective ObjectiveState; 
	local X2CardManager CardManager;
	local int Index;

	CardManager = class'X2CardManager'.static.GetCardManager();
	for( Index = 0; Index < NarrativeTriggers.Length; ++Index )
	{
		if( NarrativeTriggers[Index].NarrativeDeck != '' )
		{
			CardManager.AddCardToDeck(NarrativeTriggers[Index].NarrativeDeck, PathName(NarrativeTriggers[Index].NarrativeMoment));
		}
	}

	ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective'));
	ObjectiveState.OnCreation(self);

	return ObjectiveState;
}

function AddNarrativeTrigger(
	string NarrativeMomentPath,
	NarrativeAvailabilityWindow InAvailabilityWindow,
	Name InTriggeringEvent,
	Name InTriggeringTemplateName,
	EventListenerDeferral InEventDeferral,
	NarrativePlayCount PlayCount,
	Name InNarrativeDeck,
	optional delegate<NarrativeCompleteDelegate> InNarrativeCompleteFn,
	optional bool bWaitForCompletion = false,
	optional delegate<NarrativeRequirementsMet> InNarrativeRequirementsMetFn)
{
	local NarrativeTrigger NewNarrativeTrigger;

	if( NarrativeMomentPath != "" )
	{
		NewNarrativeTrigger.NarrativeMoment = XComNarrativeMoment(`CONTENT.RequestGameArchetype(NarrativeMomentPath));

		if( NewNarrativeTrigger.NarrativeMoment == None )
		{
			`Redscreen("[DanK] Could not find NarrativeMoment: " $ NarrativeMomentPath);
		}
	}

	NewNarrativeTrigger.AvailabilityWindow = InAvailabilityWindow;
	NewNarrativeTrigger.TriggeringEvent = InTriggeringEvent;
	NewNarrativeTrigger.TriggeringTemplateName = InTriggeringTemplateName;
	NewNarrativeTrigger.EventDeferral = InEventDeferral;
	NewNarrativeTrigger.PlayCount = PlayCount;
	NewNarrativeTrigger.NarrativeDeck = InNarrativeDeck;
	NewNarrativeTrigger.NarrativeCompleteFn = InNarrativeCompleteFn;
	NewNarrativeTrigger.bWaitForCompletion = bWaitForCompletion;
	NewNarrativeTrigger.NarrativeRequirementsMetFn = InNarrativeRequirementsMetFn;

	NarrativeTriggers.AddItem(NewNarrativeTrigger);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}