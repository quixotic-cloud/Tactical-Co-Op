//---------------------------------------------------------------------------------------
//  FILE:    X2NarrativeMoment.uc
//  AUTHOR:  Dan Kaplan  --  4/10/2015
//  PURPOSE: A Narrative Moment that supports a UI-Only modal
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2NarrativeMoment extends XComNarrativeMoment
	PerObjectConfig;


// The UI screen class to create
var() class<UIScreen>				UIScreenClass;

// The Text that will fill out the header of the UIScreen when eType == eNarrMoment_UIOnly.
var() localized string				UIHeaderText;

// The Text that will fill out the body of the UIScreen when eType == eNarrMoment_UIOnly.
var() localized string				UIBodyText;

// The path to the image that will fill out the UIScreen when eType == eNarrMoment_UIOnly.
var() string						UIImagePath;

// The Text that will fill out the array of additional strings of the UIScreen when eType == eNarrMoment_UIOnly.
var() localized array<string>		UIArrayText;

function PopulateUIData(UIPanel Control)
{
	local UIAlert AlertControl;

	AlertControl = UIAlert(Control);

	if( AlertControl != None )
	{
		AlertControl.ObjectiveUIHeaderText = UIHeaderText;
		AlertControl.ObjectiveUIBodyText = UIBodyText;
		AlertControl.ObjectiveUIImagePath = UIImagePath;
		AlertControl.ObjectiveUIArrayText = UIArrayText;
		AlertControl.eAlert = eAlert_Objective;
		AlertControl.SoundToPlay = "GeoscapeAlerts_NewObjective";
	}
}

defaultproperties
{
}



