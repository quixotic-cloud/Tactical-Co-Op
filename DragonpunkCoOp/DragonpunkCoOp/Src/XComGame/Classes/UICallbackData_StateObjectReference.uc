//---------------------------------------------------------------------------------------
//  FILE:    UICallbackData_StateObjectReference.uc
//  AUTHOR:  Sam Batista
//  PURPOSE: Designed to carry user data between dialog messages, effectively allowing
//      single shot data to be handed to the "completed" function.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class UICallbackData_StateObjectReference extends UICallbackData;

var StateObjectReference ObjectRef;

defaultproperties
{
}