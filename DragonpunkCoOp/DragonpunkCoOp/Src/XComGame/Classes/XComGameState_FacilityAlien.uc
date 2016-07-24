//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_FacilityAlien.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for an alien facility
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_FacilityAlien extends XComGameState_BaseObject
	native(Core);

// State vars
var() StateObjectReference Mission;
var() StateObjectReference Region;
var() Vector Location;
var() bool bAlienBase; // false for small facility, true for large base
var() TDateTime EvolveEndTime;
var() TDateTime DoomProjectEndTime;

//---------------------------------------------------------------------------------------
function Vector GetLocation()
{
	return Location;
}

//---------------------------------------------------------------------------------------
function Vector2D Get2DLocation()
{
	local Vector2D Output;

	Output.X = Location.X;
	Output.Y = Location.Y;

	return Output;
}

//#############################################################################################
DefaultProperties
{
}
