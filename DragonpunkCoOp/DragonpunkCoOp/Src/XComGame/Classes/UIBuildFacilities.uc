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
var localized string Upgrade;
var localized string Remove;
var localized string Excavate;

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
	if( `ISCONTROLLERACTIVE )
	{
		UpdateNavHelp();
	}
	else
	{
		HQPres.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		HQPres.m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
	}

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
	if( `ISCONTROLLERACTIVE )
	{
		UpdateNavHelp();
	}
	else
	{
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
		`HQPres.m_kFacilityGrid.EnableNavigation();
	}
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

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	local XComGameState_HeadquartersRoom CurrentHighlightedRoom;
	local XComGameState_FacilityXCom CurrentHighlightedFacility;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	FacilityOverlay = UIFacilityGrid_FacilityOverlay(`HQPRES.m_kFacilityGrid.Navigator.GetSelected());

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(CloseScreen);
	NavHelp.AddGeoscapeButton();

	//Handle Facility-Specific NavHelp
	if(FacilityOverlay != None)
	{
		if( `ISCONTROLLERACTIVE )
		{
			//REMOVING / CANCELING (using the same hint for both)
			
			CurrentHighlightedRoom = FacilityOverlay.GetRoom();
			CurrentHighlightedFacility = FacilityOverlay.GetFacility();

			if(CurrentHighlightedFacility == None)
			{
				//bsg-jneal (7.16.16): Do not allow excavation or selection if the overlay is locked, such as during the tutorial
				if(!FacilityOverlay.bLocked)
				{
					//EXCAVATE
					if(FacilityOverlay.IsAvailableForClearing(CurrentHighlightedRoom))
						NavHelp.AddLeftHelp(Excavate,class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
					//SELECT
					else if(!FacilityOverlay.GetRoom().ClearingRoom) //bsg-jneal (7.23.16): no selection nav help if the current room is excavating
						NavHelp.AddSelectNavHelp();
				}
				//bsg-jneal (7.16.16): end
			}
			else
			{
				//UPGRADE
				if(CurrentHighlightedFacility.CanUpgrade())
					NavHelp.AddLeftHelp(Upgrade, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
			}
		
			//CANCEL
			if(FacilityOverlay.IsCancelAvailable())
				NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericCancel, class'UIUtilities_Input'.const.ICON_X_SQUARE);
		
			else if (CurrentHighlightedFacility.CanRemove())
				NavHelp.AddLeftHelp(Remove, class'UIUtilities_Input'.const.ICON_X_SQUARE);
			//</workshop>
		}
		else
		{
			//UPGRADE
			if(FacilityOverlay.GetFacility().CanUpgrade())
				NavHelp.AddLeftHelp(Upgrade, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
			//REMOVING / CANCELING (using the same hint for both)
			if(FacilityOverlay.GetFacility().CanRemove())
				NavHelp.AddLeftHelp(Remove, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
			//CANCEL
			if(FacilityOverlay.IsCancelAvailable())
				NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericCancel, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
		}
	}
}
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local XComHQPresentationLayer HQPres;
	local UIFacilityGrid_FacilityOverlay FacilityOverlay;
	HQPres = `HQPRES;
	FacilityOverlay = UIFacilityGrid_FacilityOverlay(HQPres.m_kFacilityGrid.Navigator.GetSelected());

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		Movie.Stack.Pop(self);
		return true;
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		FacilityOverlay.OnConfirm();
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		if(Self.bIsFocused)
		{
			if (FacilityOverlay.IsCancelAvailable())
			{
				FacilityOverlay.OnCancelConstruction(None);			
			}
			else if (FacilityOverlay.GetFacility().CanRemove())
			{
				FacilityOverlay.OnRemoveClicked(None);
			}
		}
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