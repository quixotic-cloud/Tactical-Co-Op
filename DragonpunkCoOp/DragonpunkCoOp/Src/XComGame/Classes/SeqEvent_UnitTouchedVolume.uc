//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_UnitTouchedVolume.uc
//  AUTHOR:  David Burchanowski  --  1/21/2014
//  PURPOSE: Event for handling when a unit touches a volume
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_UnitTouchedVolume extends SeqEvent_X2GameState
	native;

var() Volume TouchedVolume;
var private XComGameState_Unit TouchingUnit;

cpptext
{
#if WITH_EDITOR
protected:
	FString GetDisplayTitle() const;
#endif
};

function FireEvent(XComGameState_Unit Unit)
{
	TouchingUnit = Unit;
	CheckActivate(Unit.GetVisualizer(), none);
}

function EventListenerReturn OnUnitTouchedVolume(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit EventUnitState;

	EventUnitState = XComGameState_Unit(EventData);

	FireEvent(EventUnitState);

	return ELR_NoInterrupt;
}

function RegisterEvent()
{
	local Object ThisObj;

	ThisObj = self;

	`XEVENTMGR.RegisterForEvent( ThisObj, 'UnitTouchedVolume', OnUnitTouchedVolume, ELD_OnStateSubmitted,, TouchedVolume );
}

defaultproperties
{
	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=TouchingUnit,bWriteable=TRUE)

	ObjName="Unit Touched Volume"
}
