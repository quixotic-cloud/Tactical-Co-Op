//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_PsiLab.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_PsiLab extends UIFacility;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;

	super.InitScreen(InitController, InitMovie, InitName);

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (!XComHQ.bHasSeenPsiLabIntroPopup)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
		`HQPRES.UIPsiLabIntro(Facility.GetMyTemplate());
	}
}

//==============================================================================

defaultproperties
{
	bHideOnLoseFocus = false;
}