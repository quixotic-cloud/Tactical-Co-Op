//---------------------------------------------------------------------------------------
//  FILE:    UIFacilityUpgrade.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Displays a list of available upgrades for the currently selected Facility.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class UIFacilityUpgrade extends UIScreen;

// UI
var int m_iMaskWidth;
var int m_iMaskHeight;

var UIPanel m_kContainer;
var UIList m_kList;
var UINavigationHelp NavHelp;
var UIItemCard	ItemCard;
var UIButton CancelUpgradeButton;

// Gameplay
var XComGameState GameState; // setting this allows us to display data that has not yet been submitted to the history 
var StateObjectReference UnitRef; // used when reassigning staff
var StateObjectReference FacilityRef;
var XComGameState_HeadquartersXCom HQState;
var array<StateObjectReference> m_arrUpgrades;

var localized string m_strTitle;
var localized string m_strExistingUpgradeWarningTitle;
var localized string m_strExistingUpgradeWarningBody;
var localized string m_strCancelUpgradeButton;
var localized string m_strCancelUpgradeTitle;
var localized string m_strCancelUpgradeDescription;
var localized string FacilityStatus_UpgradeLabel;
var localized string FacilityStatus_UpgradingButNoStaff;

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIPanel kBG;
	local UIText kTitle;
	local XGParamTag kTag;
	local string strTitle;

	// Init UI
	super.InitScreen(InitController, InitMovie, InitName);

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.AddBackButton(OnCancel);

	// Create Container
	m_kContainer = Spawn(class'UIPanel', self).InitPanel('');

	// Create BG
	kBG = Spawn(class'UIBGBox', m_kContainer).InitBG('', 0, 0, 860, 500);

	// Center Container using BG
	m_kContainer.CenterWithin(kBG);
	m_kContainer.SetX(m_kContainer.X - 200);

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = Caps(GetFacility().GetMyTemplate().DisplayName);
	strTitle =  `XEXPAND.ExpandString(m_strTitle);

	// Create Title text
	kTitle = Spawn(class'UIText', m_kContainer).InitText();
	kTitle.SetTitle(class'UIUtilities_Text'.static.GetColoredText(strTitle, EUIState_Normal, 50));
	kTitle.SetPosition(10, 5);

	m_kList = Spawn(class'UIList', m_kContainer);
	m_kList.InitList('', 20, 115, m_iMaskWidth, m_iMaskHeight);
	m_kList.SetPosition(20, 115);
	m_kList.ClearSelection();
	m_kList.itemPadding = 10;
	m_kList.OnItemClicked = OnItemClicked;
	m_kList.OnSelectionChanged = RefreshInfoPanel; 
	m_kList.bStickyHighlight = false;
	
	CancelUpgradeButton = Spawn(class'UIButton', m_kContainer);
	CancelUpgradeButton.bIsNavigable = false;
	CancelUpgradeButton.InitButton('', m_strCancelUpgradeButton, OnCancelUpgrade, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	CancelUpgradeButton.SetPosition(20, 80);
	CancelUpgradeButton.Hide(); // start off hidden

	ItemCard = Spawn(class'UIItemCard', self).InitItemCard();
	ItemCard.SetPosition(1230, 90);

	// ---------------------------------------------------------

	UpdateData();
}

simulated function RefreshInfoPanel(UIList ContainerList, int ItemIndex)
{
	ItemCard.PopulateUpgradeCard(UIFacilityUpgrade_ListItem(ContainerList.GetItem(ItemIndex)).UpgradeTemplate, FacilityRef);
}

simulated function UpdateData()
{
	local int i;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_FacilityUpgrade FacilityUpgrade;
	local array<X2FacilityUpgradeTemplate> FacilityUpgrades;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;

	// Clear old data
	m_kList.ClearItems();

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	FacilityUpgrades = Facility.GetBuildableUpgrades();

	// Available upgrades
	for(i = 0; i < FacilityUpgrades.Length; i++)
	{
		Spawn(class'UIFacilityUpgrade_ListItem', m_kList.itemContainer).InitFacilityUpgradeListItem(FacilityUpgrades[i], FacilityRef);
	}

	// Current upgrade (only one at a time)
	UpgradeProject = class'UIUtilities_Strategy'.static.GetUpgradeProject(FacilityRef);
	if(UpgradeProject != none)
	{
		FacilityUpgrade = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(UpgradeProject.ProjectFocus.ObjectID));
		Spawn(class'UIFacilityUpgrade_ListItem', m_kList.itemContainer).InitFacilityUpgradeListItem(FacilityUpgrade.GetMyTemplate(), FacilityRef).InProgress(UpgradeProject.GetReference());
		CancelUpgradeButton.Show();
	}
	else
		CancelUpgradeButton.Hide();

	// Completed upgrades
	for(i = 0; i < Facility.Upgrades.Length; i++)
	{
		FacilityUpgrade = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(Facility.Upgrades[i].ObjectID));
		Spawn(class'UIFacilityUpgrade_ListItem', m_kList.itemContainer).InitFacilityUpgradeListItem(FacilityUpgrade.GetMyTemplate(), FacilityRef).Completed();
	}
}

simulated function XComGameState_FacilityXCom GetFacility()
{
	return XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
}

simulated function OnItemClicked(UIList list, int itemIndex)
{
	local XComGameState_FacilityXCom Facility;
	local UIFacilityUpgrade_ListItem UpgradeItem;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;

	UpgradeItem = UIFacilityUpgrade_ListItem(list.GetItem(itemIndex));

	if(!UpgradeItem.m_bIsDisabled)
	{
		UpgradeProject = class'UIUtilities_Strategy'.static.GetUpgradeProject(FacilityRef);

		// Can only construct one upgrade at a time
		if(UpgradeProject == none)
		{
			StartUpgradeFacility();
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		}
		else if(UpgradeProject.ObjectID == UpgradeItem.UpgradeProject.ObjectID)
		{
			// If the upgrade selected is the current upgrade project and it is not staffed, open the window to choose an engineer
			Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
			if (Facility.GetRoom().GetBuildSlot().IsSlotEmpty())
			{
				`HQPRES.UIPersonnel(eUIPersonnel_Engineers, OnEngineerSelected);
				Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			}
			else
				Movie.Pres.PlayUISound(eSUISound_MenuClose);
		}
		else
			WarnExistingUpgrade();
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function WarnExistingUpgrade()
{
	local TDialogueBoxData  kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle	= m_strExistingUpgradeWarningTitle;
	kDialogData.strText     = m_strExistingUpgradeWarningBody;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated function StartUpgradeFacility()
{
	local XComGameState NewGameState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local XComNarrativeMoment UpgradeNarrative;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	UpgradeTemplate = UIFacilityUpgrade_ListItem(m_kList.GetSelectedItem()).UpgradeTemplate;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Start Facility Upgrade");
	
	UpgradeState = UpgradeTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(UpgradeState);

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.PayStrategyCost(NewGameState, UpgradeState.GetMyTemplate().Cost, XComHQ.FacilityUpgradeCostScalars);
			
	FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));
	NewGameState.AddStateObject(FacilityState);
	FacilityState.Upgrades.AddItem(UpgradeState.GetReference());

	UpgradeState.Facility = FacilityRef;
	UpgradeState.OnUpgradeAdded(NewGameState, FacilityState);

	`XEVENTMGR.TriggerEvent('UpgradeCompleted', UpgradeState, FacilityState, NewGameState);

	if (FacilityState.GetMyTemplate().FacilityUpgradedNarrative != "")
	{
		UpgradeNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityState.GetMyTemplate().FacilityUpgradedNarrative));
		if (UpgradeNarrative != None)
		{
			`HQPRES.UINarrative(UpgradeNarrative);
		}
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Facility_Upgrade");

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();

	UpdateData();
	//`HQPRES.m_kAvengerHUD.UpdateResources();
	
	// Refresh XComHQ and see if we need to display a power warning
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.PowerState == ePowerState_Red && FacilityState.GetPowerOutput() < 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Warning No Power");
		`XEVENTMGR.TriggerEvent('WarningNoPower', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

simulated function OnEngineerSelected(StateObjectReference _UnitRef)
{
	local StaffUnitInfo UnitInfo;

	UnitRef = _UnitRef;
	UnitInfo.UnitRef = _UnitRef;
	if(class'UIUtilities_Strategy'.static.CanReassignStaff(UnitInfo, "upgrading" @ GetFacility().GetMyTemplate().DisplayName, ReassignUpgradeEngineerCallback))
		ReassignUpgradeEngineer();
}

simulated function ReassignUpgradeEngineerCallback(eUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		ReassignUpgradeEngineer();
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function ReassignUpgradeEngineer()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersRoom Room;
	local StaffUnitInfo UnitInfo;
	
	NewGameState = class'UIUtilities_Strategy'.static.RemoveUnitFromStaffingSlot(UnitRef);

	UnitInfo.UnitRef = UnitRef;

	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(GetFacility().Room.ObjectID));
	Room.GetBuildSlot().FillSlot(NewGameState, UnitInfo);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	class'UIUtilities_Strategy'.static.GetXComHQ().HandlePowerOrStaffingChange();

	UpdateData();

	Movie.Stack.PopFirstInstanceOfClass(class'UIPersonnel');
}

simulated function OnCancelUpgrade(UIButton kButton)
{
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject; 
	local XComGameState_FacilityUpgrade UpgradeState;
	local UICallbackData_StateObjectReference CallbackData;

	UpgradeProject = class'UIUtilities_Strategy'.static.GetXComHQ().GetUpgradeFacilityProject(FacilityRef);
	UpgradeState = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(UpgradeProject.ProjectFocus.ObjectID));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = UpgradeState.GetMyTemplate().DisplayName;
	
	kDialogData.eType = eDialog_Warning;
	kDialogData.strTitle = m_strCancelUpgradeTitle;
	kDialogData.strText = `XEXPAND.ExpandString(m_strCancelUpgradeDescription);

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = FacilityRef;
	kDialogData.xUserData = CallbackData;
	kDialogData.fnCallbackEx = CancelUpgradeDialogueCallback;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericConfirm;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

simulated public function CancelUpgradeDialogueCallback(eUIAction eAction, UICallbackData xUserData)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectUpgradeFacility ProjectState; 
	local UICallbackData_StateObjectReference CallbackData;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if (eAction == eUIAction_Accept)
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		ProjectState = class'UIUtilities_Strategy'.static.GetXComHQ().GetUpgradeFacilityProject(CallbackData.ObjectRef);

		if (ProjectState != none)
		{
			XComHQ.CancelUpgradeFacilityProject(ProjectState);
		}

		XComHQ.HandlePowerOrStaffingChange();
		`HQPRES.m_kAvengerHUD.UpdateResources();
		UpdateData();
	}
}

//------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnAccept();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//------------------------------------------------------

simulated function OnAccept()
{
	NavHelp.ClearButtonHelp();
	OnItemClicked(m_kList, m_kList.selectedIndex);
}

simulated function OnCancel()
{
	NavHelp.ClearButtonHelp();
	CloseScreen();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Hide();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Show();
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;

	m_iMaskWidth = 800;
	m_iMaskHeight = 400;

	bConsumeMouseEvents = true;
}
