//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_ProvingGround.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_ProvingGround extends UIFacility;

var public UIEventQueue m_NewBuildQueue;
var public UIFacility_ResearchProgress m_BuildProgress;

var public localized string m_strStartProject;
var public localized string m_strProjectedHours;
var public localized string m_strProjectedDays;
var public localized string m_strEmptyQueue;
var public localized string m_strCurrentProject;
var public localized string m_strCancelProvingGroundProjectTitle;
var public localized string m_strCancelProvingGroundProjectBody;
var localized String m_strProgress;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState_Tech TechState;
	local array<StateObjectReference> TechRefs;
	local int idx;

	super.InitScreen(InitController, InitMovie, InitName);
		
	// Build Queue
	m_NewBuildQueue = Spawn(class'UIEventQueue', self).InitEventQueue();
	m_BuildProgress = Spawn(class'UIFacility_ResearchProgress', self).InitResearchProgress();

	UpdateBuildQueue();
	UpdateBuildProgress();

	if (NeedResearchReportPopup(TechRefs))
	{
		`HQPRES.UIChooseProject();

		for (idx = 0; idx < TechRefs.Length; idx++)
		{
			// Check for additional unlocks from this tech to generate popups
			TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(TechRefs[idx].ObjectID));
			TechState.DisplayTechCompletePopups();
		}
	}
}

simulated function CreateFacilityButtons()
{
	AddFacilityButton(m_strStartProject, OnChooseProject);
}

simulated function String GetProgressString()
{
	if (XCOMHQ().HasProvingGroundProject())
	{
		return m_strProgress @ class'UIUtilities_Strategy'.static.GetResearchProgressString(XCOMHQ().GetResearchProgress(XCOMHQ().GetCurrentProvingGroundTech().GetReference()));
	}
	else
	{
		return "";
	}
}

simulated function EUIState GetProgressColor()
{
	return class'UIUtilities_Strategy'.static.GetResearchProgressColor(XCOMHQ().GetResearchProgress(XCOMHQ().GetCurrentProvingGroundTech().GetReference()));
}

simulated function UpdateBuildQueue()
{
	local int i;
	local XComGameState_Tech ProvingGroundTech;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local StateObjectReference BuildItemRef;
	local int ProjectHours;
	local array<HQEvent> BuildItems;
	local HQEvent BuildItem;
	
	Facility = GetFacility();

	for (i = 0; i < Facility.BuildQueue.Length; ++i)
	{
		BuildItemRef = Facility.BuildQueue[i];
		ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(`XCOMHISTORY.GetGameStateForObjectID(BuildItemRef.ObjectID));

		// Calculate the hours based on which type of Headquarters Project this queue item is
		if (i == 0)
		{
			ProjectHours = ProvingGroundProject.GetCurrentNumHoursRemaining();
		}
		else
		{
			ProjectHours += ProvingGroundProject.GetProjectedNumHoursRemaining();
		}

		ProvingGroundTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));

		BuildItem.Hours = ProjectHours;
		BuildItem.Data = ProvingGroundTech.GetMyTemplate().DisplayName;
		BuildItem.ImagePath = class'UIUtilities_Image'.const.EventQueue_Engineer;
		BuildItems.AddItem(BuildItem);
	}

	m_NewBuildQueue.OnUpButtonClicked = OnUpButtonClicked;
	m_NewBuildQueue.OnDownButtonClicked = OnDownButtonClicked;
	m_NewBuildQueue.OnCancelButtonClicked = CancelProjectPopup;
	m_NewBuildQueue.UpdateEventQueue(BuildItems, true, true);
	m_NewBuildQueue.HideDateTime();
}

simulated function UpdateBuildProgress()
{
	local int ProjectHours;
	local string days, progress;
	local XComGameState_Tech ProvingGroundTech;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;

	ProvingGroundProject = XCOMHQ().GetCurrentProvingGroundProject();

	if(ProvingGroundProject != none)
	{
		ProvingGroundTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));

		ProjectHours = ProvingGroundProject.GetCurrentNumHoursRemaining();

		if (ProjectHours < 0)
			days = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_PowerCore'.default.m_strStalledResearch, eUIState_Warning);
		else
			days = class'UIUtilities_Text'.static.GetTimeRemainingString(ProjectHours);

		progress = class'UIUtilities_Text'.static.GetColoredText(GetProgressString(), GetProgressColor());
		m_BuildProgress.Update(m_strCurrentProject, ProvingGroundTech.GetMyTemplate().DisplayName, days, progress, int(100 * ProvingGroundProject.GetPercentComplete()));
		m_BuildProgress.Show();
		m_NewBuildQueue.SetY(-250); // move up to make room for BuildProgress bar
	}
	else
	{
		m_BuildProgress.Hide();
		m_NewBuildQueue.SetY(-120); // restore to its original location
	}
}

simulated function bool IsProjectStalled()
{
	if( XCOMHQ().GetCurrentProvingGroundProject() != none )
		return XCOMHQ().GetCurrentProvingGroundProject().GetCurrentNumHoursRemaining() < 0;
	else
		return false;
}

// fired when a build queue UI list item has its up button clicked.
// All of these callbacks are guaranteed to only be called if there is another item
// above or below, so we don't need to do range checks.
simulated function OnUpButtonClicked(int ListItemIndex)
{
	local StateObjectReference BuildItemRef;
	local XComGameState_FacilityXCom NewFacilityState;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Edit Build Queue: Move Item Up");
	NewFacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));

	// swap projects
	BuildItemRef = NewFacilityState.BuildQueue[ListItemIndex];
	NewFacilityState.BuildQueue[ListItemIndex] = NewFacilityState.BuildQueue[ListItemIndex - 1];
	NewFacilityState.BuildQueue[ListItemIndex - 1] = BuildItemRef;
	NewGameState.AddStateObject(NewFacilityState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	class'UIUtilities_Strategy'.static.GetXComHQ().HandlePowerOrStaffingChange();
	UpdateBuildQueue();
	UpdateBuildProgress();

	`HQPRES.m_kAvengerHUD.UpdateResources();
	UpdateBuildProgress();
}

// fired when a build queue UI list item has its down button clicked
simulated function OnDownButtonClicked(int ListItemIndex)
{
	local StateObjectReference BuildItemRef;
	local XComGameState_FacilityXCom NewFacilityState;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Edit Build Queue: Move Item Top");
	NewFacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));

	// swap projects
	BuildItemRef = NewFacilityState.BuildQueue[ListItemIndex];
	NewFacilityState.BuildQueue[ListItemIndex] = NewFacilityState.BuildQueue[ListItemIndex + 1];
	NewFacilityState.BuildQueue[ListItemIndex + 1] = BuildItemRef;
	NewGameState.AddStateObject(NewFacilityState);
		
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	class'UIUtilities_Strategy'.static.GetXComHQ().HandlePowerOrStaffingChange();
	UpdateBuildQueue();
	UpdateBuildProgress();
		
	`HQPRES.m_kAvengerHUD.UpdateResources();
	UpdateBuildProgress();
}

simulated function CancelProjectPopup(int ListItemIndex)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local XComGameState_Tech ProvingGroundTech;
	local StateObjectReference BuildItemRef;
	local TDialogueBoxData kData;
	local XGParamTag ParamTag;
	local UICallbackData_StateObjectReference CallbackData;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	BuildItemRef = FacilityState.BuildQueue[ListItemIndex];
	ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(`XCOMHISTORY.GetGameStateForObjectID(BuildItemRef.ObjectID));
	ProvingGroundTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = ProvingGroundTech.GetDisplayName();

	kData.strTitle = m_strCancelProvingGroundProjectTitle;
	kData.strText = `XEXPAND.ExpandString(m_strCancelProvingGroundProjectBody);
	kData.strAccept = m_strOK;
	kData.strCancel = m_strCancel;
	kData.eType = eDialog_Alert;

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = BuildItemRef;
	kData.xUserData = CallbackData;
	kData.fnCallbackEx = OnCancelProjectPopupCallback;

	Movie.Pres.UIRaiseDialog(kData);
}

simulated function OnCancelProjectPopupCallback(eUIAction eAction, UICallbackData xUserData)
{
	local UICallbackData_StateObjectReference CallbackData;
	local StateObjectReference BuildItemRef;
	local XComGameState NewGameState;
	
	if (eAction == eUIAction_Accept)
	{
		CallbackData = UICallbackData_StateObjectReference(xUserData);
		BuildItemRef = CallbackData.ObjectRef;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Edit Build Queue: Remove Proving Ground Project");
		class'XComGameStateContext_HeadquartersOrder'.static.CancelProvingGroundProject(NewGameState, BuildItemRef);
		class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		class'UIUtilities_Strategy'.static.GetXComHQ().HandlePowerOrStaffingChange();
		UpdateBuildQueue();

		`HQPRES.m_kAvengerHUD.UpdateResources();
		UpdateBuildProgress();
	}
}

simulated function OnChooseProject()
{
	`HQPRES().UIChooseProject();
}

// ------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		OnChooseProject();
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		OnCancel();
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function RealizeStaffSlots()
{
	onStaffUpdatedDelegate = UpdateBuildQueue;
	super.RealizeStaffSlots();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	if (m_kTitle != none)
		m_kTitle.Hide();

	m_NewBuildQueue.DeactivateButtons();
}

simulated function OnReceiveFocus()
{
	UpdateBuildQueue();
	UpdateBuildProgress();
	super.OnReceiveFocus();

	if (m_kTitle != none)
		m_kTitle.Show();
}

function bool NeedResearchReportPopup(out array<StateObjectReference> TechRefs)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local int idx;
	local bool bNeedPopup;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	bNeedPopup = false;

	for (idx = 0; idx < XComHQ.TechsResearched.Length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(XComHQ.TechsResearched[idx].ObjectID));

		if (TechState != none && !TechState.bSeenResearchCompleteScreen && !TechState.GetMyTemplate().bShadowProject && TechState.GetMyTemplate().bProvingGround)
		{
			TechRefs.AddItem(TechState.GetReference());
			bNeedPopup = true;
		}
	}

	return bNeedPopup;
}

//==============================================================================

defaultproperties
{
	bHideOnLoseFocus = false;
}