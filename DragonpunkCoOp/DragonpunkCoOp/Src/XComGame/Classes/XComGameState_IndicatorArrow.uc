//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_IndicatorArrow.uc
//  AUTHOR:  David Burchanowski  --  12/17/2013
//  PURPOSE: This object represents the instance data for a 2d arrow that points
//           at various points of interest in the 3D world.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_IndicatorArrow extends XComGameState_BaseObject
	dependson(XGTacticalScreenMgr);

var XComGameState_Unit Unit;    // If this arrow follows a unit, this will be non-null
var vector Location;            // If Unit is null, then this arrow points to a fixed place. This is the location to point to.
var float Offset;               // Offset, in unreal units vertically, from the focus location to draw the arrow
var EUIState ArrowColor;        // Arrow color. This needs to be updated when sam has time
var int CounterValue;          // Number that displays on the arrow. Useful for countdowns and such
var string Icon;			   // UI Icon to display. 

/// Creates an arrow pointing to the specified unit
static function XComGameState_IndicatorArrow CreateArrowPointingAtUnit(XComGameState_Unit InUnit, 
																		optional float InOffset = 128, 
																		optional EUIState InColor = eUIState_Normal,
																		optional int InCounterValue = -1,
																		optional string InIcon = "")
{
	return CreateArrow(InUnit, vect(0, 0, 0), InOffset, InColor, InCounterValue, InIcon);
}

/// Creates an arrow pointing to the specified location
static function XComGameState_IndicatorArrow CreateArrowPointingAtLocation(Vector InLocation, 
																			optional float InOffset = 128, 
																			optional EUIState InColor = eUIState_Normal,
																			optional int InCounterValue = -1,
																			optional string InIcon = "")
{
	return CreateArrow(none, InLocation, InOffset, InColor, InCounterValue, InIcon);
}

/// Simple helper function reduce code duplication
static private function XComGameState_IndicatorArrow CreateArrow(XComGameState_Unit InUnit, Vector InLocation, float InOffset, EUIState InColor, int InCounterValue, string InIcon)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_IndicatorArrow Arrow;
	local XComGameState_Unit PointToUnit;

	History = `XCOMHISTORY;
	NewGameState = History.GetStartState();
	if (NewGameState == None)
	{		
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("XComGameState_IndicatorArrow::CreateArrow()");
	}

	//Add the unit we are pointing at to the game state so that the visualizer actions are aware of the relationship between the arrow and the unit
	if(InUnit != none)
	{
		`assert(InUnit.ObjectID > 0);
		PointToUnit = XComGameState_Unit( NewGameState.CreateStateObject(class'XComGameState_Unit', InUnit.ObjectID) );
		NewGameState.AddStateObject(PointToUnit);
	}

	Arrow = XComGameState_IndicatorArrow(NewGameState.CreateStateObject(class'XComGameState_IndicatorArrow'));
	Arrow.Unit = PointToUnit;
	Arrow.Location = InLocation;
	Arrow.Offset = InOffset;
	Arrow.ArrowColor = InColor;
	Arrow.CounterValue = InCounterValue;
	Arrow.Icon = InIcon;
	
	NewGameState.AddStateObject(Arrow);
	if (NewGameState != History.GetStartState())
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	return Arrow;
}

/// Removes the arrow, if any, that is pointing to the specified unit
static function RemoveArrowPointingAtUnit(XComGameState_Unit InUnit)
{
	RemoveArrow(InUnit, vect(0, 0, 0));
}

/// Removes the arrow, if any, that is pointing to the specified location
static function RemoveArrowPointingAtLocation(vector InLocation)
{
	RemoveArrow(none, InLocation);
}

/// Simple helper function reduce code duplication
static private function RemoveArrow(XComGameState_Unit InUnit, vector InLocation)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_IndicatorArrow Arrow;

	History = `XCOMHISTORY;
	NewGameState = History.GetStartState();
	if (NewGameState == None)
	{		
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("XComGameState_IndicatorArrow::RemoveArrow()");
	}

	// remove all arrows pointing to the specified unit or location.
	foreach History.IterateByClassType(class'XComGameState_IndicatorArrow', Arrow)
	{
		if((InUnit != none && Arrow.Unit != none && InUnit.ObjectID == Arrow.Unit.ObjectID) // same unit
			|| (InUnit == none && InLocation == Arrow.Location)) // same location
		{
			NewGameState.RemoveStateObject(Arrow.ObjectID);
		}
	}

	if (NewGameState != History.GetStartState())
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function bool PointsToUnit()
{
	return Unit != none;
}

function bool PointsToLocation()
{
	return !PointsToUnit();
}

function string ToString(optional bool bAllFields)
{
	return "Indicator Arrows";
}

DefaultProperties
{	
}
