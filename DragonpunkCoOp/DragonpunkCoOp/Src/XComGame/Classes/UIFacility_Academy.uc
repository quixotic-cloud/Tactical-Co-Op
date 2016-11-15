//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_Workshop.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_Academy extends UIFacility;

var public localized string m_strViewUnlocks;

//----------------------------------------------------------------------------
// MEMBERS

simulated function CreateFacilityButtons()
{
	AddFacilityButton(m_strViewUnlocks, OnViewUpgrades);
}

simulated function OnViewUpgrades()
{
	`HQPRES().UIOfficerTrainingSchool(FacilityRef);
}

simulated function OnRemoved()
{
	super.OnRemoved();
}


//==============================================================================