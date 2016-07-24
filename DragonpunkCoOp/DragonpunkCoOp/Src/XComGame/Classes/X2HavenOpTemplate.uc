//---------------------------------------------------------------------------------------
//  FILE:    X2HavenOpTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2HavenOpTemplate extends X2StrategyElementTemplate;

// Cost
var StrategyCost		Cost;

// Time
var int					HoursToComplete;

// Text
var localized string	DisplayName;
var localized string	Summary;
var localized string	EventLabel; // For Event queue if Op takes time

var delegate<OnLaunched> OnLaunchedFn; // called when selected
var delegate<OnCompleted> OnCompletedFn; // If Op takes time, called when timer completes
var delegate<Deactivate> DeactivateFn; // called at end of month or when timer ends (if timer spans end of month)

delegate OnLaunched(XComGameState NewGameState, X2HavenOpTemplate HavenOpTemplate, StateObjectReference HavenRef);
delegate OnCompleted(XComGameState NewGameState, X2HavenOpTemplate HavenOpTemplate, StateObjectReference HavenRef);
delegate Deactivate(XComGameState NewGameState, X2HavenOpTemplate HavenOpTemplate, StateObjectReference HavenRef);

//---------------------------------------------------------------------------------------
DefaultProperties
{
}