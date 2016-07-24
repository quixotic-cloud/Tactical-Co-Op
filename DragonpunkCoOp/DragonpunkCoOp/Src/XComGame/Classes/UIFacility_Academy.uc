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

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if ( cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_ENTER ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR)
	{
		OnViewUpgrades();
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//==============================================================================