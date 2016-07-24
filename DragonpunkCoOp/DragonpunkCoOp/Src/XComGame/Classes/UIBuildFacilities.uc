//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIBuildFacilities.uc
//  AUTHOR:  Brit Steiner - 4/20/2015
//  PURPOSE: This file corresponds to the facility overlay grid in the nav stack. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIBuildFacilities extends UIScreen;

var bool bInstantInterp;
var localized string BuildFacilitiesTitle;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.HasShieldedPowerCoil() && !XComHQ.bHasSeenPowerCoilShieldedPopup)
	{
		`HQPRES.UIPowerCoilShielded();
	}

	super.InitScreen(InitController, InitMovie, InitName);
	Show();
}

simulated function Show()
{
	local XComHQPresentationLayer HQPres; 
	local UIFacility_Storage Storage;
	local float InterpTime;

	super.Show();

	HQPres = `HQPRES;

	InterpTime = `HQINTERPTIME;

	if(bInstantInterp)
	{
		InterpTime = 0;
	}
	
	HQPres.CAMLookAtNamedLocation("FacilityBuildCam", InterpTime);
	HQPres.m_kAvengerHUD.Show();
	HQPres.m_kFacilityGrid.ActivateGrid();
	HQPres.m_kFacilityGrid.EnableNavigation();
	HQPres.m_kFacilityGrid.SetBorderLabel(BuildFacilitiesTitle);
	HQPres.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	HQPres.m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);

	Storage = UIFacility_Storage(Movie.Stack.GetScreen(class'UIFacility_Storage'));
	if( Storage != none )
		Storage.Hide();
}

simulated function Hide()
{
	local XComHQPresentationLayer HQPres;
	local UIFacility_Storage Storage;

	super.Hide();
	
	HQPres = `HQPRES;

	HQPres.m_kFacilityGrid.DeactivateGrid();
	HQPres.m_kFacilityGrid.DisableNavigation();

	Storage = UIFacility_Storage(Movie.Stack.GetScreen(class'UIFacility_Storage'));
	if( Storage != none )
		Storage.Show();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
	`HQPres.m_kFacilityGrid.EnableNavigation();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPres.m_kFacilityGrid.DisableNavigation();
}

simulated function OnRemoved()
{
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPRES;

	if( Movie.Stack.IsInStack(class'UIFacility_Storage') )
	{
		Hide();
	}
	else
	{
		HQPres.CAMLookAtNamedLocation("Base", `HQINTERPTIME);
	}

	class'UIUtilities_Sound'.static.PlayCloseSound();
	HQPres.m_kFacilityGrid.DeactivateGrid();
	HQPres.m_kFacilityGrid.DisableNavigation();
	super.OnRemoved();
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local XComHQPresentationLayer HQPres;
	HQPres = `HQPRES;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		Movie.Stack.Pop(self);
		return true;
	}

	if (HQPres.m_kFacilityGrid.Navigator.OnUnrealCommand(cmd, arg))
		return true;

	return super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Evaluate;
}