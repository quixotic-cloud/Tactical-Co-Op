//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectProvingGround.uc
//  AUTHOR:  Joe Weinhoffer  --  05/19/2015
//  PURPOSE: This object represents the instance data for an XCom HQ proving ground project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectProvingGround extends XComGameState_HeadquartersProjectResearch native(Core);

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int iTotalWork;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	iTotalWork = XComHQ.ProvingGroundRate;

	// Can't make progress when paused
	if (!FrontOfBuildQueue() && !bAssumeActive)
	{
		return 0;
	}
	else
	{
		// Check for Higher Learning
		iTotalWork += Round(float(iTotalWork) * (float(XComHQ.EngineeringEffectivenessPercentIncrease) / 100.0));
	}

	return iTotalWork;
}

//---------------------------------------------------------------------------------------
// Is it currently at the front of the build queue
function bool FrontOfBuildQueue()
{
	local XComGameState_FacilityXCom Facility;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(AuxilaryReference.ObjectID));

	if (Facility != none)
	{
		if (Facility.BuildQueue[0].ObjectID == self.ObjectID)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}