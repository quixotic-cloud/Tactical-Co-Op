//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_UnitTouchedExitVolume.uc
//  AUTHOR:  David Burchanowski  --  1/21/2014
//  PURPOSE: Event for handling when a unit sees another unit or interactive object
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_UnitSawObject extends SeqEvent_X2GameState;

var() const private bool FireForUnits;
var() const private bool FireForNonDoorInteractiveObjects;
var() const private bool FireForDoors; // "doors" includes windows

var private XComGameState_Unit SeeingUnit;
var private XComGameState_Unit OtherUnit;
var private XComGameState_InteractiveObject OtherObject;

private function bool ShouldFireEventForObject(XComGameState_BaseObject TargetObject)
{
	local XComGameState_InteractiveObject InteractiveObject;

	if (XComGameState_Unit(TargetObject) != none && !XComGameState_Unit(TargetObject).GetMyTemplate().bIsCosmetic)
	{
		return FireForUnits;
	}

	InteractiveObject = XComGameState_InteractiveObject(TargetObject);
	if(InteractiveObject != none)
	{
		if(InteractiveObject.IsDoor())
		{
			return FireForDoors;
		}
		else
		{
			return FireForNonDoorInteractiveObjects;
		}
	}

	return false;
}

function EventListenerReturn OnVisibilityChange(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit SourceUnitState;
	local XComGameState_BaseObject TargetObject;
	local X2GameRulesetVisibilityManager VisManager;
	local GameRulesCache_VisibilityInfo CurrentVisibility;
	local GameRulesCache_VisibilityInfo PreviousVisibility;

	// check for early out conditions
	SourceUnitState = XComGameState_Unit(EventSource);
	if(SourceUnitState == none) return ELR_NoInterrupt;

	TargetObject = XComGameState_BaseObject(EventData);
	if(TargetObject == none) return ELR_NoInterrupt;

	if(!ShouldFireEventForObject(TargetObject))
	{
		return ELR_NoInterrupt;
	}

	VisManager = `TACTICALRULES.VisibilityMgr;
	
	// get the current and previous visibility states for the changed object
	VisManager.GetVisibilityInfo(SourceUnitState.ObjectID, TargetObject.ObjectID, CurrentVisibility, GameState.HistoryIndex);

	if(GameState.HistoryIndex > 0)
	{
		VisManager.GetVisibilityInfo(SourceUnitState.ObjectID, TargetObject.ObjectID, PreviousVisibility, GameState.HistoryIndex - 1);
	}

	// check if the changed object became visible this frame
	if(CurrentVisibility.bVisibleGameplay && !PreviousVisibility.bVisibleGameplay)
	{
		SeeingUnit = SourceUnitState;
		OtherUnit = XComGameState_Unit(TargetObject);
		OtherObject = XComGameState_InteractiveObject(TargetObject);

		CheckActivate(SourceUnitState.GetVisualizer(), none);
	}

	return ELR_NoInterrupt;
}

function RegisterEvent()
{
	local Object ThisObj;

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'ObjectVisibilityChanged', OnVisibilityChange, ELD_OnStateSubmitted);
}

defaultproperties
{
	ObjName="Unit Saw Object"

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="SeeingUnit",PropertyName=SeeingUnit,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="SeenUnit",PropertyName=OtherUnit,bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="SeenObject",PropertyName=OtherObject,bWriteable=TRUE)

	FireForUnits=true
	FireForNonDoorInteractiveObjects=true
	FireForDoors=false
}