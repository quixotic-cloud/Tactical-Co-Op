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
	local StateObjectReference NoneRef; 
	if (selectedUnitRef == NoneRef)
	{
		// This prevents the screen from closing up automatically on confirm, if you've tried to confirm on a no-soldier screen. 
		// You can still back out though.
		UIPersonnel(Movie.Stack.GetScreen(class'UIPersonnel')).m_bRemoveWhenUnitSelected = false; 
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
	}
	else
	{
		`HQPRES.UIBarMemorial_Details(selectedUnitRef);
	}
}

simulated function OnShowObituaries()
{
	`HQPRES.UIPersonnel_BarMemorial(OnPersonnelSelected);
}

//==============================================================================

defaultproperties
{
}
