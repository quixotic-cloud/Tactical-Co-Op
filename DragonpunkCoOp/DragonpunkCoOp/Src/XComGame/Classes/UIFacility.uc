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
	local float InterpTime;

	super.InitScreen(InitController, InitMovie, InitName);

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	RealizeNavHelp();
	RealizeFacility();

	CreateFacilityButtons();

	`HQPRES.m_kAvengerHUD.HideEventQueue();

	InterpTime = `HQINTERPTIME;

	if(bInstantInterp)
	{
		InterpTime = 0;
	}

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
	NavHelp.AddBackButton(OnCancel);
	NavHelp.AddGeoscapeButton();
	
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
		UpgradeButton.InitLargeButton('UpgradeButton', , "", UpgradeFacility, );
		UpgradeButton.AnchorBottomRight();
	}

	if( Facility.CanUpgrade() )
		UpgradeButton.SetText(m_strUpgrade);
	else if( Facility.Upgrades.Length > 1 )
		UpgradeButton.SetText(m_strReviewUpgrades);
	else 
		UpgradeButton.SetText(m_strReviewUpgrade);

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
	}

	m_kRoomContainer.AddRoomFunc(ButtonLabel, CallbackFunction);
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
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B ||
		cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE || 
		cmd == class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN)
	{
			OnCancel();
			return true;
	}

	if (m_kStaffSlotContainer.OnUnrealCommand(cmd, arg))
		return true;

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	if( !bIsFocused )
	{
		super.OnReceiveFocus();
		NavHelp.ClearButtonHelp();
		RealizeNavHelp();
		RealizeFacility();

		if(CameraTag != "")
			`HQPRES.CAMLookAtNamedLocation(CameraTag, `HQINTERPTIME);
		else
			`HQPRES.CAMLookAtRoom(GetFacility().GetRoom(), `HQINTERPTIME);

		if (m_kRoomContainer != none)
		{
			m_kRoomContainer.Show();
		}
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
