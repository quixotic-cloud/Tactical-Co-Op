//---------------------------------------------------------------------------------------
//  FILE:    X2DarkEventTemplate.uc
//  AUTHOR:  Mark Nauta
//  PURPOSE: Define Dark Events
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2DarkEventTemplate extends X2GameplayMutatorTemplate;

var() localized string					QuoteText; // Quote from one of big 3 for UI card
var() localized string					QuoteTextAuthor; // Quote author field from one of big 3 for UI card
var() localized string					PreMissionText;
var() localized string					PostMissionSuccessText;
var() localized string					PostMissionFailureText;

var() string							ImagePath; // Image for UI card
var() bool								bRepeatable; // Can this Dark Event succeed multiple times throughout the game
var() bool								bTactical; // Does this objective affect the tactical game directly (display on skyranger intro screen)
var() bool								bLastsUntilNextSupplyDrop; // Does this event last until the next supply drop instead of using a duration
var() int								MaxSuccesses; // If repeatable, max number of successes.  If zero or less -> infinitely repeatable
var() int								MinActivationDays; // How many days after being played will the event activate (lower bound)
var() int								MaxActivationDays; // How many days after being played will the event activate (upper bound)
var() int								MinDurationDays; // How many days after being activated will the event stay active (lower bound)
var() int								MaxDurationDays; // How many days after being activated will the event stay active (upper bound)
var() bool								bInfiniteDuration; // If true, this DE never expires and should be shown in the active DE list
var() int								StartingWeight;
var() int								MinWeight;
var() int								MaxWeight;
var() int								WeightDeltaPerPlay;
var() int								WeightDeltaPerActivate;
var() array<name>						MutuallyExclusiveEvents; // Can't be paired in same drawing with these events
var() bool								bNeverShowObjective; // To hide this from the UI Objective list 

var() Delegate<CanActivateDelegate>		CanActivateFn;
var() Delegate<CanCompleteDelegate>		CanCompleteFn;
var() Delegate<GetSummaryDelegate>		GetSummaryFn;
var() Delegate<GetPreMissionTextDelegate> GetPreMissionTextFn;

delegate bool CanActivateDelegate(XComGameState_DarkEvent DarkEventState);
delegate bool CanCompleteDelegate(XComGameState_DarkEvent DarkEventState);
delegate string GetSummaryDelegate(string strSummaryText);
delegate string GetPreMissionTextDelegate(string strPreMissionText);

//---------------------------------------------------------------------------------------
DefaultProperties
{
}