//---------------------------------------------------------------------------------------
//  FILE:    UIFacility.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility extends UIX2SimpleScreen
	dependson(UIPersonnel, UIRoomContainer);

var StateObjectReference FacilityRef;
var bool bInstantInterp;

var UIStaffContainer m_kStaffSlotContainer; // staff slot buttons at the top of the facility screen
var UIRoomContainer m_kRoomContainer; // non-staff room buttons at the bottom of the facility screen
var UIFacility_ResearchProgress m_kResearchProgressBar;
var UIText m_kTitle;

var UIPanel m_kRepairContainer;
var UIText m_kRepairDesc;

var UINavigationHelp NavHelp;
var UILargeButton UpgradeButton;

var bool bIgnoreSuperInput;
var string CameraTag;

var localized string m_strRename;
var localized string m_strDelete;
var localized string m_strUpgrade;
var localized string m_strReviewUpgrade;
var localized string m_strReviewUpgrades;
var localized string m_strRepair;
var localized string m_strAvengerLocationName;

var public delegate<OnStaffUpdated> onStaffUpdatedDelegate;
delegate onStaffUpdated();
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	//local float InterpTime;

	`log("UIFacility::InitScreen <<<<<<<<<<<<<<<<<<<<<<",,'DebugHQCamera');
	super.InitScreen(InitController, InitMovie, InitName);

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	Navigator.HorizontalNavigation = true;

	RealizeNavHelp();
	RealizeFacility();

	CreateFacilityButtons();

	`HQPRES.m_kAvengerHUD.HideEventQueue();

	`log("UIFacilty" @ `ShowVar(MCPath),,'DebugHQCamera');
	`log("exiting UIFacility::InitScreen >>",,'DebugHQCamera');
	Navigator.SelectFirstAvailable();
	`HQPRES.m_kFacilityGrid.SelectRoomByReference(FacilityRef);
}

// Tells the HQ camera to look at this room.
simulated function HQCamLookAtThisRoom()
{
	local float InterpTime;

	InterpTime = `HQINTERPTIME;

	if(bInstantInterp)
	{
		InterpTime = 0;
	}

	`log("HQCamLookAtThisRoom" @ `ShowVar(CameraTag) @ `ShowVar(InterpTime),,'DebugHQCamera');

	if(InterpTime > 0)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("AntFarm_Camera_Zoom_In");
	}

	if(CameraTag == "")
	{
		`HQPRES.CAMLookAtRoom(GetFacility().GetRoom(), InterpTime);
	}
	else
	{
		`HQPRES.CAMLookAtNamedLocation(CameraTag, InterpTime);
	}	
}

simulated function RealizeNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(OnCancel);
	NavHelp.AddGeoscapeButton();

	if(`ISCONTROLLERACTIVE)
		NavHelp.AddSelectNavHelp();
	
	if( GetFacility().CanUpgrade() || GetFacility().HasBeenUpgraded() )
		ShowUpgradeButton();
}

simulated function ShowUpgradeButton()
{
	local XComGameState_FacilityXCom Facility; 

	Facility =  GetFacility(); 

	if( UpgradeButton == none )
	{
		UpgradeButton = Spawn(class'UILargeButton', self);

		if( `ISCONTROLLERACTIVE == false )
		{
			UpgradeButton.InitLargeButton('UpgradeButton', , "", UpgradeFacility, );
			UpgradeButton.AnchorBottomRight();
		}
		else
		{
			UpgradeButton.LibID = 'X2ContinueButton';
			UpgradeButton.InitLargeButton('UpgradeButton',, "", UpgradeFacility,);
			UpgradeButton.AnchorTopCenter();
			UpgradeButton.OffsetY = 150;
			UpgradeButton.DisableNavigation();
		}
	}

	if( `ISCONTROLLERACTIVE )
	{
		if (Facility.CanUpgrade())
		{
			UpgradeButton.SetText(class'UIUtilities_Text'.static.InjectImage(
				class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -13) @ m_strUpgrade);
		}
		else if (Facility.Upgrades.Length > 1)
		{
			UpgradeButton.SetText(class'UIUtilities_Text'.static.InjectImage(
				class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -13) @ m_strReviewUpgrades);
		}
		else 
		{
			UpgradeButton.SetText(class'UIUtilities_Text'.static.InjectImage(
				class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -13) @ m_strReviewUpgrade);
		}	
	}
	else
	{
		if( Facility.CanUpgrade() )
			UpgradeButton.SetText(m_strUpgrade);
		else if( Facility.Upgrades.Length > 1 )
			UpgradeButton.SetText(m_strReviewUpgrades);
		else 
			UpgradeButton.SetText(m_strReviewUpgrade);
	}

	UpgradeButton.Show();
}

simulated function HideUpgradeButton()
{
	if( UpgradeButton != none )
	{
		UpgradeButton.Hide();
	}
}

simulated function UpgradeFacility(UIButton Button)
{
	`HQPRES.UIFacilityUpgrade(FacilityRef);
}

// adds a button to the facility room button bar
simulated function AddFacilityButton(string ButtonLabel, delegate<UIRoomContainer.onRoomFunction> CallbackFunction)
{
	if (m_kRoomContainer == none)
	{
		m_kRoomContainer = Spawn(class'UIRoomContainer', self);
		m_kRoomContainer.InitRoomContainer(, GetFacility().GetMyTemplate().DisplayName);
		Navigator.AddNavTargetDown(m_kRoomContainer);
	}

	m_kRoomContainer.AddRoomFunc(ButtonLabel, CallbackFunction);
	m_kRoomContainer.Navigator.RemoveNavTargetUp();
	
	if (m_kStaffSlotContainer.NumChildren() <= 0)
	{
		m_kRoomContainer.Navigator.SelectFirstAvailable();
		Navigator.SetSelected(m_kRoomContainer);
	}
	else
		m_kRoomContainer.Navigator.AddNavTargetUp(m_kStaffSlotContainer);
}

simulated function CreateStaffSlotContainer()
{
	if (m_kStaffSlotContainer == none)
	{
		m_kStaffSlotContainer = Spawn(class'UIFacilityStaffContainer', self);
		m_kStaffSlotContainer.InitStaffContainer();
		m_kStaffSlotContainer.SetMessage("");
	}
}

simulated function CreateResearchBar(optional delegate<OnMouseEventDelegate> MouseDelegate)
{
	if(m_kResearchProgressBar == none)
	{
		m_kResearchProgressBar = Spawn(class'UIFacility_ResearchProgress', self).InitResearchProgress();
		m_kResearchProgressBar.ProcessMouseEvents(MouseDelegate);
	}
}

simulated function RealizeFacility()
{
	local UIX2ScreenHeader Header; 

	`log("RealizeFacility",,'DebugHQCamera');
	if(FacilityRef.ObjectID > 0)
	{
		CreateStaffSlotContainer();
		RealizeStaffSlots(); 
		Header = `HQPRES.m_kAvengerHUD.FacilityHeader;
		Header.SetText(m_strAvengerLocationName, GetFacility().GetMyTemplate().DisplayName);
		Header.Show();
	}
}

simulated function RealizeStaffSlots()
{
	if (m_kStaffSlotContainer != none)
	{
		m_kStaffSlotContainer.Refresh(FacilityRef, onStaffUpdatedDelegate);

		if (m_kStaffSlotContainer.NumChildren() <= 0)
			Navigator.RemoveControl(m_kStaffSlotContainer);
		
		if(m_kRoomContainer != none)
		{
			m_kRoomContainer.Navigator.RemoveNavTargetUp();

			if(m_kStaffSlotContainer.NumChildren() > 0)
				m_kRoomContainer.Navigator.AddNavTargetUp(m_kStaffSlotContainer);
		}
	}
}
simulated function ClickStaffSlot( int Index )
{
	if (m_kStaffSlotContainer != none)
	{
		UIFacility_StaffSlot(m_kStaffSlotContainer.GetChildAt(Index)).QueueDropDownDisplay();
	}
}

// Force select a unit as if they were in the drop down list for this staff slot in this facility
// Be very careful calling this function, since it doesn't perform any validation
// Make sure before you call it that the unit is allowed to be staffed here!
simulated function SelectPersonnelInStaffSlot( int Index, StaffUnitInfo UnitInfo )
{
	if (m_kStaffSlotContainer != none)
	{
		UIFacility_StaffSlot(m_kStaffSlotContainer.GetChildAt(Index)).OnPersonnelSelected(UnitInfo);
	}	
}

simulated function CreateFacilityButtons();

simulated function XComGameState_FacilityXCom GetFacility()
{
	return XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
}

simulated function OnCancel()
{
	CloseScreen();
}

simulated function CloseScreen()
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local Name FacilityExitedEventName;
	local X2FacilityTemplate FacilityTemplate;

	//You aren't allowed out until the camera finishes it's shtick. 
	if( XComHQPresentationLayer(Movie.Pres).CAMIsBusy() || !bIsInited ) return;

	Movie.Stack.PopFirstInstanceOfClass(class'UIFacility');
	Movie.Pres.PlayUISound(eSUISound_MenuClose);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Exited Facility");
	FacilityState = GetFacility();
	FacilityTemplate = FacilityState.GetMyTemplate();
	FacilityExitedEventName = Name("OnExitedFacility_" $ FacilityTemplate.DataName);
	`XEVENTMGR.TriggerEvent(FacilityExitedEventName, , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	// We should only exit out to the current room, unless we're going back to the facility summary screen, because that happens when the facility summary screen receives focus. (kmartinez)
	if(Movie.Stack.GetCurrentClass() != class'UIFacilitySummary')
		`HQPRES.LookAtSelectedRoom(GetFacility().GetRoom(), `HQINTERPTIME);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local UIAvengerShortcuts AvengerShortcuts;
	local bool bHandled;
	local bool bShortcutsHaveAttention;
	local bool bAPressed;
	local bool bUpgradeScreenPresent;
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	AvengerShortcuts = UIAvengerHUD(Movie.Stack.GetScreen(class'UIAvengerHUD')).Shortcuts;
	bShortcutsHaveAttention = AvengerShortcuts.bHasShortcutTabAttention && AvengerShortcuts.bIsVisible;
	bUpgradeScreenPresent = Movie.Stack.IsCurrentClass(class'UIChooseUpgrade');
	if (!bShortcutsHaveAttention && m_kStaffSlotContainer.OnUnrealCommand(cmd, arg))
	{
		return true;
	}
	if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || 
		cmd == class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN)
	{
			OnCancel();
			return true;
	}

	else if(cmd == class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER ||
			cmd == class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER)
	{
		//Shortcuts will gain attention here:
		//We need to unhighlight what we currently have highlighted.
		if(!bUpgradeScreenPresent)
			ClearFocusOffofFacilityButtons();
	}
	else if(cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A)
		bAPressed = true;

	if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_X)
	{
		if (UpgradeButton != None)
		{
			ClearFocusOffofFacilityButtons();
			UpgradeFacility(None);
			AvengerShortcuts.ResetAndClearTabShortcutFunctionality();
		}

		return true;
	}


	if(!bShortcutsHaveAttention)
	{
		if (!bIgnoreSuperInput)
		{
			bHandled = super.OnUnrealCommand(cmd, arg);
		}
	}
	else
	{
		if(!bAPressed)
			bHandled = super.OnUnrealCommand(cmd, arg);
	}
	if(bHandled)
	{
		AvengerShortcuts.ResetAndClearTabShortcutFunctionality();
	}
	return bHandled;
}

simulated function ClearFocusOffofFacilityButtons()
{
	local int i;

	m_kStaffSlotContainer.m_kPersonnelDropDown.Hide();
	Navigator.ClearSelectionHierarchy();
	m_kRoomContainer.OnLoseFocus();
	m_kStaffSlotContainer.OnLoseFocus();
	for(i = 0; i < m_kStaffSlotContainer.StaffSlots.Length; ++i)
	{
		m_kStaffSlotContainer.StaffSlots[i].OnLoseFocus();
	}
}
simulated function OnReceiveFocus()
{
	if( !bIsFocused )
	{
		super.OnReceiveFocus();
		RealizeNavHelp();
		RealizeFacility();	//this sets a nested control as selected.

		if(CameraTag != "")
			`HQPRES.CAMLookAtNamedLocation(CameraTag, `HQINTERPTIME);
		else
			`HQPRES.CAMLookAtRoom(GetFacility().GetRoom(), `HQINTERPTIME);

		if (m_kRoomContainer != none)
		{
			m_kRoomContainer.Show();
		}
		Navigator.SelectFirstAvailableIfNoCurrentSelection();
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	
	NavHelp.ClearButtonHelp();
	HideUpgradeButton();
	`HQPRES.m_kAvengerHUD.FacilityHeader.Hide();

	if (m_kRoomContainer != none)
	{
		m_kRoomContainer.Hide();
	}
	if(m_kStaffSlotContainer != none)
	{
		m_kStaffSlotContainer.Hide();
	}
}

simulated function OnRemoved()
{
	super.OnRemoved();

	NavHelp.ClearButtonHelp();
	HideUpgradeButton();
	`HQPRES.m_kAvengerHUD.FacilityHeader.Hide();

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_AvengerNoRoom");
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Evaluate;
	Package = "/ package/gfxFacilityHUD/FacilityHUD";
}
