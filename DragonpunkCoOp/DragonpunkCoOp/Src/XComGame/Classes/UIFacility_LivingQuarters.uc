//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_Workshop.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_LivingQuarters extends UIFacility;

var public localized string m_strListLivingQuarters;
var public localized string m_strPersonnel;

//----------------------------------------------------------------------------
// MEMBERS

simulated function CreateFacilityButtons()
{
	AddFacilityButton(m_strPersonnel, OnShowPersonnel);
}

simulated function OnShowPersonnel()
{
	`HQPRES.UIPersonnel_LivingQuarters(OnPersonnelSelected);
}


simulated function OnPersonnelSelected(StateObjectReference selectedUnitRef)
{
	//TODO: add any logic here for selecting someone in the living quarters
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if ( cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_ENTER ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR)
	{
		OnShowPersonnel();
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Evaluate;
	bHideOnLoseFocus = false;
}