//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_KismetVariable.uc
//  AUTHOR:  David Burchanowski  --  1/15/2014
//  PURPOSE: This object represents the instance data for kismet
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_KismetVariable extends XComGameState_BaseObject native(Core);

/// <summary>
// variable name of this kismet variable.
/// </summary>
var privatewrite string VarName;

// only one of these will be filled out, depending on var type.
// what a lovely place for a union.
var private int IntValue;
var private float FloatValue;
var private bool BoolValue;
var private string StringValue;
var private vector VectorValue;
var private string ObjectName;

native function string ToString(optional bool bAllFields);

DefaultProperties
{	
}
