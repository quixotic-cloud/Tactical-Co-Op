//---------------------------------------------------------------------------------------
//  FILE:    X2ResistanceModeTemplate.uc
//  AUTHOR:  Joe Weinhoffer
//  PURPOSE: Define Resistance Modes
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ResistanceModeTemplate extends X2GameplayMutatorTemplate;

var() localized string					ScanLabel; // Label on Res HQ Scanning Site

var() string							ImagePath; // Image for UI card

var() Delegate<OnXCOMArrivesDelegate>	OnXCOMArrivesFn;
var() Delegate<OnXCOMLeavesDelegate>	OnXCOMLeavesFn;

delegate OnXCOMArrivesDelegate(XComGameState NewGameState, StateObjectReference InRef);
delegate OnXCOMLeavesDelegate(XComGameState NewGameState, StateObjectReference InRef);

//---------------------------------------------------------------------------------------
DefaultProperties
{
}