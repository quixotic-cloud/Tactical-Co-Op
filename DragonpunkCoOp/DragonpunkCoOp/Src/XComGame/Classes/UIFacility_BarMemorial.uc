//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIFacility_BarMemorial
//  AUTHOR:  Brian Whitman/Sam Batista
//  PURPOSE: Bar/Memorial Facility Screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIFacility_BarMemorial extends UIFacility;

var public localized string m_strListDeceased;
var public localized string m_strObituaries;

//----------------------------------------------------------------------------
// MEMBERS

simulated function CreateFacilityButtons()
{
	AddFacilityButton(m_strObituaries, OnShowObituaries);
}

simulated function OnPersonnelSelected(StateObjectReference selectedUnitRef)
{
	`HQPRES.UIBarMemorial_Details(selectedUnitRef);
}

simulated function OnShowObituaries()
{
	`HQPRES.UIPersonnel_BarMemorial(OnPersonnelSelected);
}

simulated function RealizeNavHelp()
{
	NavHelp.AddBackButton(OnCancel);
	NavHelp.AddGeoscapeButton();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if ( cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_ENTER ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR)
	{
		OnShowObituaries();
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

defaultproperties
{
}
