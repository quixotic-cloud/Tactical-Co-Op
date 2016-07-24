//---------------------------------------------------------------------------------------
//  FILE:    UIFacilityUpgrade_ListItem.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Displays a single upgrade option.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class UIFacilityUpgrade_ListItem extends UIPanel;

var UIText m_kName;
var UIText m_kStatus; // used for cost / ETA
var UIText m_kStatus2; // used to display assigned engineer
var UIText m_kDescription;
var UIBGBox m_BG;
var UIButton CancelUpgradeButton;

var bool m_bIsDisabled;
var X2FacilityUpgradeTemplate UpgradeTemplate;
var StateObjectReference FacilityRef;
var StateObjectReference UpgradeProject;

var localized string m_strCost;
var localized string m_strCompleted;
var localized string m_strInProgressETA;
var localized string m_strInProgressNoEngineer;
var localized string m_strAssignedEngineer;
var localized string m_strNoPower;

simulated function UIFacilityUpgrade_ListItem InitFacilityUpgradeListItem(X2FacilityUpgradeTemplate initUpgradeTemplate, StateObjectReference Facility)
{
	UpgradeTemplate = initUpgradeTemplate;
	FacilityRef = Facility;

	InitPanel(); // must do this before adding children or setting data

	m_BG = Spawn(class'UIBGBox', self);
	m_BG.InitBG('', 0, 0, width, height, eUIState_Normal);
	m_BG.ProcessMouseEvents(OnMouseEventDelegate); // BG processes all our Mouse Events

	m_kName = Spawn(class'UIText', self);
	m_kName.InitText('');
	m_kName.SetWidth(400);
	m_kName.SetPosition(10, 5);

	m_kDescription = Spawn(class'UIText', self); 
	m_kDescription.InitText('');
	m_kDescription.SetWidth(400);
	m_kDescription.SetPosition(10, 25);

	m_kStatus = Spawn(class'UIText', self); 
	m_kStatus.InitText('');
	m_kStatus.SetWidth(400);
	m_kStatus.SetPosition(400, 5);

	m_kStatus2 = Spawn(class'UIText', self); 
	m_kStatus2.InitText('');
	m_kStatus2.SetWidth(400);
	m_kStatus2.SetPosition(400, 25);

	UpdateData();
	return self;
}

simulated function UpdateData()
{	
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local bool CanBuild, HasPower;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	m_kName.SetText(Caps(UpgradeTemplate.DisplayName));
	//m_kDescription.SetText(UpgradeTemplate.Summary);

	CanBuild = XComHQ.MeetsRequirmentsAndCanAffordCost(UpgradeTemplate.Requirements, UpgradeTemplate.Cost, XComHQ.FacilityUpgradeCostScalars);
	
	if (UpgradeTemplate.iPower >= 0 || FacilityState.GetRoom().HasShieldedPowerCoil())
		HasPower = true;
	else
		HasPower = ((XComHQ.GetPowerConsumed() - UpgradeTemplate.iPower) <= XComHQ.GetPowerProduced());
	
	if (HasPower)
		m_kStatus.SetText(class'UIUtilities_Strategy'.static.GetStrategyCostString(UpgradeTemplate.Cost, XComHQ.FacilityUpgradeCostScalars));
	else
		m_kStatus.SetText(class'UIUtilities_Text'.static.GetColoredText(m_strNoPower, eUIState_Bad));

	if(!CanBuild || !HasPower)
	{
		SetDisabled(true);
	}
	else
	{
		SetDisabled(false);
	}
}

simulated function SetDisabled(bool isDisabled)
{
	if(m_bIsDisabled != isDisabled)
	{
		m_bIsDisabled = isDisabled;
		m_BG.SetBGColorState(m_bIsDisabled ? eUIState_Disabled : eUIState_Normal);
	}
}

simulated function InProgress(StateObjectReference _UpgradeProject)
{
	local XGParamTag kTag;
	local StateObjectReference UnitRef;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersProjectUpgradeFacility ProjectState;

	UpgradeProject = _UpgradeProject;
	
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	ProjectState = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(UpgradeProject.ObjectID));
	kTag.StrValue0 = class'UIUtilities_Text'.static.GetTimeRemainingString(ProjectState.GetCurrentNumHoursRemaining());
	m_kStatus.SetText(`XEXPAND.ExpandString(m_strInProgressETA));

	//Check to see if there is an engineer assigned to this upgrade
	UnitRef = UIFacilityUpgrade(screen).GetFacility().GetRoom().GetBuildSlot().GetAssignedStaffRef();
	if(UnitRef.ObjectID > 0)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		kTag.StrValue0 = Unit.GetName(eNameType_Full);
		m_kStatus2.SetText(`XEXPAND.ExpandString(m_strAssignedEngineer));
		m_BG.SetBGColorState(eUIState_Warning);
	}
	else
	{		
		m_kStatus2.SetText(m_strInProgressNoEngineer);		
		m_BG.SetBGColorState(eUIState_Warning);
	}	
}

simulated function Completed()
{
	m_bIsDisabled = true;
	m_BG.SetBGColorState(eUIState_Good);
	m_kStatus.SetText(m_strCompleted);
}

// mouse events get processed by out BG, by not calling super.ProcessMouseEvents(), we allow mouse events to reach the BG control
simulated function UIPanel ProcessMouseEvents(optional delegate<OnMouseEventDelegate> MouseEventDelegate)
{
	OnMouseEventDelegate = MouseEventDelegate;
	return self;
}

defaultproperties
{
	width = 800;
	height = 60;
	bProcessesMouseEvents = true;
}