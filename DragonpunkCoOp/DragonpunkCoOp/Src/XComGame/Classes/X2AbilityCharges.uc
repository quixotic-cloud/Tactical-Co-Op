//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCharges.uc
//  AUTHOR:  Joshua Bouscher  --  2/5/2015
//  PURPOSE: Base class for setting charges on an X2AbilityTemplate.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCharges extends Object;

var int InitialCharges;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit) { return InitialCharges; }