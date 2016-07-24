//---------------------------------------------------------------------------------------
//  FILE:    X2GameplayMutatorTemplate.uc
//  AUTHOR:  Mark Nauta
//  PURPOSE: Define region bonuses, dark events and other mutators on gameplay
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2GameplayMutatorTemplate extends X2StrategyElementTemplate;

var() localized string					DisplayName;
var() localized string					SummaryText;

var() string							Category;  // ContinentBonus, Dark Event, etc.
var() Delegate<OnActivatedDelegate>		OnActivatedFn;
var() Delegate<OnDeactivatedDelegate>	OnDeactivatedFn;
var() Delegate<GetMutatorValueDelegate> GetMutatorValueFn;

delegate OnActivatedDelegate(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false);
delegate OnDeactivatedDelegate(XComGameState NewGameState, StateObjectReference InRef);
delegate int GetMutatorValueDelegate();

//---------------------------------------------------------------------------------------
DefaultProperties
{
}