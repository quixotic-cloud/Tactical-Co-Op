//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_UnitApproachedUnit.uc
//  AUTHOR:  David Burchanowski  --  10/29/2014
//  PURPOSE: Event for handling when a unit approaches another unit
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_UnitApproachedUnit extends SeqEvent_X2GameState
	native;

var private XComGameState_Unit ApproachingUnit;
var private XComGameState_Unit ApproachedUnit;
var() private int TriggerDistanceTiles; // when the unit draws within this many tiles to another unit, this event will fire
var() private bool RequiresCivilianTarget; // Only activate from civilian targets.
var() private bool RequiresNonAlienTarget; // Only activates to non-alien targets. (If checked, skips faceless civilians)
var() private bool SkipVisibilityCheck; // Activate regardless of unit-to-unit visibility; just check radius (for matching behavior of visible "rescue range")

native function EventListenerReturn OnUnitFinishedMove(Object EventData, Object EventSource, XComGameState GameState, Name EventID);

function RegisterEvent()
{
	local Object ThisObj;

	ThisObj = self;

	`XEVENTMGR.RegisterForEvent( ThisObj, 'UnitMoveFinished', OnUnitFinishedMove, ELD_OnStateSubmitted );
}

defaultproperties
{
	ObjName="Unit Approached Unit"
	TriggerDistanceTiles=3

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="ApproachingUnit",PropertyName=ApproachingUnit,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="ApproachedUnit",PropertyName=ApproachedUnit,bWriteable=TRUE)

	SkipVisibilityCheck=false
}

