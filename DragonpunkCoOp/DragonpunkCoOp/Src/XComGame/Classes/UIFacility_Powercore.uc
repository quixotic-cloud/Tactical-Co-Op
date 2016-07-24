//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_Labs.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_Powercore extends UIFacility config(GameData);

var UIText  m_CurrentResearch;
var UIProgressBar PercentBar;

var localized string m_strResearch;
var localized string m_strReverseEngineer;
var localized string m_strCurrentResearch;
var localized string m_strNoActiveResearch;
var localized string m_strStalledResearch;
var localized string m_strArchives;
var localized string m_strLabsExitWithoutStaffTitle;
var localized string m_strLabsExitWithoutStaffBody;
var localized string m_strLabsExitWithoutStaffStay;
var localized string m_strLabsExitWithoutStaffLeave;
var localized string m_strLabsExitWithoutProjectTitle;
var localized string m_strLabsExitWithoutProjectBody;
var localized string m_strLabsExitWithoutProjectStay;
var localized string m_strLabsExitWithoutProjectLeave;
var localized String m_strProgress;
var localized String m_strSkill;
var localized String m_strStaffTooltip;

var name DisplayTag;
var bool bDelayingResearchReport;

var config array<name> DelayResearchReportTechs;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ, NewXComHQState;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> TechRefs;
	local int idx;

	super.InitScreen(InitController, InitMovie, InitName);

	BuildScreen();

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	if (NeedResearchReportPopup(TechRefs))
	{
		if (XComHQ.HasTechsAvailableForResearch())
		{
			`HQPRES.UIChooseResearch(bInstantInterp);
		}

		for (idx = 0; idx < TechRefs.Length; idx++)
		{
			// Check for additional unlocks from this tech to generate popups
			TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRefs[idx].ObjectID));
			TechState.DisplayTechCompletePopups();

			bDelayingResearchReport = false;
			`HQPRES.ResearchReportPopup(TechRefs[idx], bInstantInterp);
		}
	}
	else if (XComHQ != none && !XComHQ.bHasVisitedLabs)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("First visit to Labs");
		NewXComHQState = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewXComHQState.bHasVisitedLabs = true;
		NewGameState.AddStateObject(NewXComHQState);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else if(!bDelayingResearchReport && !XComHQ.HasActiveShadowProject())
	{
		if(XComHQ.HasResearchProject())
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Research In Progress Event");
			`XEVENTMGR.TriggerEvent('ResearchInProgress', , NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if(XComHQ.IsObjectiveCompleted('T0_M6_WelcomeToLabsPt2'))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Tygan Greeting");
			`XEVENTMGR.TriggerEvent('TyganGreeting', , NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

simulated function BuildScreen()
{
	BuildResearchPanel();
	BuildSkillPanel();
}

simulated function UpdateData()
{
	local string days, researchName, progress;
	local int HoursRemaining;

	if( m_kResearchProgressBar != none && XCOMHQ().GetCurrentResearchProject() != none)
	{
		researchName = XCOMHQ().GetCurrentResearchTech().GetDisplayName();
		
		HoursRemaining = XCOMHQ().GetCurrentResearchProject().GetCurrentNumHoursRemaining();
		if (HoursRemaining < 0)
			days = class'UIUtilities_Text'.static.GetColoredText(m_strStalledResearch, eUIState_Warning);
		else
			days = class'UIUtilities_Text'.static.GetTimeRemainingString(HoursRemaining);

		progress = class'UIUtilities_Text'.static.GetColoredText(GetProgressString(), GetProgressColor());
		m_kResearchProgressBar.Update(m_strCurrentResearch, researchName, days, progress, int(100 * XCOMHQ().GetCurrentResearchProject().GetPercentComplete()));
		m_kResearchProgressBar.Show();
	}
	else
	{
		m_kResearchProgressBar.Hide();
	}
}

simulated function BuildResearchPanel()
{
	CreateResearchBar();
	UpdateData();
}

simulated function BuildSkillPanel()
{
	m_kStaffSlotContainer.SetTitle(m_strSkill);
	m_kStaffSlotContainer.SetStaffSkill("img:///UILibrary_StrategyImages.AlertIcons.Icon_science", GetSkillString());
	m_kStaffSlotContainer.SetTooltipText(m_strStaffTooltip);
}

simulated function String GetResearchString()
{
	local String strResearch;
	local int HoursRemaining;

	if( XCOMHQ().HasResearchProject() )
	{
		strResearch = XCOMHQ().GetCurrentResearchTech().GetDisplayName();

		HoursRemaining = XCOMHQ().GetCurrentResearchProject().GetCurrentNumHoursRemaining();

		if( IsResearchStalled() )
		{
			strResearch = strResearch @ m_strStalledResearch;
		}
		else
		{
			strResearch = strResearch @ class'UIUtilities_Text'.static.GetTimeRemainingString(HoursRemaining);
		}

		return strResearch;
	}
	else
	{
		return m_strNoActiveResearch;
	}
}

simulated function String GetProgressString()
{
	if( XCOMHQ().HasResearchProject() && !IsResearchStalled() )
	{
		return m_strProgress @ class'UIUtilities_Strategy'.static.GetResearchProgressString(XCOMHQ().GetResearchProgress(XCOMHQ().GetCurrentResearchTech().GetReference()));
	}
	else
	{
		return "";
	}
}

simulated function EUIState GetProgressColor()
{
	return class'UIUtilities_Strategy'.static.GetResearchProgressColor(XCOMHQ().GetResearchProgress(XCOMHQ().GetCurrentResearchTech().GetReference()));
}

simulated function bool IsResearchStalled()
{
	if( XCOMHQ().GetCurrentResearchProject() != none )
	{
		return XCOMHQ().GetCurrentResearchProject().GetCurrentNumHoursRemaining() < 0;
	}
	else
	{
		return false;
	}
}

simulated function String GetSkillString()
{
	return String(XCOMHQ().GetNumberOfScientists());
}

simulated function RealizeStaffSlots()
{
	onStaffUpdatedDelegate = UpdateData;
	super.RealizeStaffSlots();
}

// ------------------------------------------------------------

/*
simulated public function UpdateCurrentResearch()
{
	local string Description, Time;
	local float PercentComplete;
	local int HoursRemaining, DisplayPercentComplete;
	local X2TechTemplate TechTemplate;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (!XComHQ.HasResearchProject())
	{
		m_CurrentResearch.SetText(m_strNoActiveResearch);
	}
	else
	{
		// Get data: 
		TechTemplate = XComHQ.GetCurrentTechBeingResearched();
		PercentComplete = XComHQ.GetCurrentResearchProject().GetPercentComplete();
		DisplayPercentComplete = Round(PercentComplete * 100.0);
		Description = TechTemplate.DisplayName;

		HoursRemaining = XComHQ.GetCurrentResearchProject().GetCurrentNumHoursRemaining();
		if (HoursRemaining < 0)
			Time = class'UIUtilities_Text'.static.GetColoredText(m_strStalledResearch, eUIState_Bad);
		else
			Time = class'UIUtilities_Text'.static.GetTimeRemainingString(HoursRemaining);

		// Display data: 
		m_CurrentResearch.SetText(m_strCurrentResearch $":" $"\n"
			$ Description $"\n"
			$ "Time Remaining:"
			@ Time $"\n"
			$ DisplayPercentComplete $"% complete");

		PercentBar.SetPercent(PercentComplete);
	}
}*/

/*
simulated public function PreviewResearch(int PreviewHours)
{
	local string Description, Time;
	local int CurrentHours;
	local float PercentComplete;
	local X2TechTemplate TechTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local EUIState ColorState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (!XComHQ.HasResearchProject())
	{
		m_CurrentResearch.SetText(m_strNoActiveResearch);
	}
	else
	{
		// Get data: 
		TechTemplate = XComHQ.GetCurrentTechBeingResearched();
		PercentComplete = XComHQ.GetCurrentResearchProject().GetPercentComplete();
		Description = TechTemplate.DisplayName;
		CurrentHours = XComHQ.GetCurrentResearchProject().GetCurrentNumHoursRemaining();

		if (CurrentHours < PreviewHours)
			ColorState = eUIState_Warning;
		else
			ColorState = eUIState_Good;

		Time = "Preview Time:" @ class'UIUtilities_Text'.static.GetTimeRemainingString(PreviewHours);
		Time = class'UIUtilities_Text'.static.GetColoredText(Time, ColorState);

		// Display data: 
		m_CurrentResearch.SetText(m_strCurrentResearch $":" $"\n"
			$ Description $"\n"
			$ Time $"\n"
			$ PercentComplete $"%");
	}

}*/

simulated function OnClickCurrentResearch(UIPanel control, int cmd)
{
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		if (Movie.Stack.GetScreen(class'UIChooseResearch') == none)
			`HQPRES.UIChooseResearch();
		break;
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	if( m_kTitle != none )
		m_kTitle.Hide();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if( m_kTitle != none )
		m_kTitle.Show();
	UpdateData();

	//`HQPRES.CAMLookAtNamedLocation(CameraTag, `HQINTERPTIME);
}

simulated function OnRemoved()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	super.OnRemoved();
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (!XComHQ.bHasVisitedEngineering && !XComHQ.HasFacilityByName('Laboratory'))
	{
		FacilityState = XComHQ.GetFacilityByName('Storage');

		if(!FacilityState.NeedsAttention())
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger attention for Storage");
			FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewGameState.AddStateObject(FacilityState);
			FacilityState.TriggerNeedsAttention();
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}

	`GAME.GetGeoscape().m_kBase.m_kAmbientVOMgr.TriggerTyganVOEvent();
}

simulated function OnCancel()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M1_WelcomeToLabs'))
	{
		if (!XComHQ.HasResearchProject() && !XComHQ.HasActiveShadowProject() && XComHQ.HasTechsAvailableForResearchWithRequirementsMet())
		{
			LeaveFacilityWithoutProjectPopup();
		}
		else
		{
			LeaveLabs();
		}
	}
}

simulated function LeaveLabs()
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entered Power Core");
	FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));
	NewGameState.AddStateObject(FacilityState);
	`XEVENTMGR.TriggerEvent('OnLabsExit', FacilityState, FacilityState, NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	super.OnCancel();
}

simulated function LeaveFacilityWithoutStaffPopup()
{
	local TDialogueBoxData kData;

	kData.strTitle = m_strLabsExitWithoutStaffTitle;
	kData.strText = m_strLabsExitWithoutStaffBody;
	kData.strAccept = m_strLabsExitWithoutStaffStay;
	kData.strCancel = m_strLabsExitWithoutStaffLeave;
	kData.eType = eDialog_Warning;
	kData.fnCallback = OnLeaveFacilityWithoutStaffPopupCallback;

	Movie.Pres.UIRaiseDialog(kData);
}

simulated function OnLeaveFacilityWithoutStaffPopupCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
		ClickStaffSlot(0);
	else
		LeaveLabs(); // If Cancel, allow you to leave this screen. 
}

simulated function LeaveFacilityWithoutProjectPopup()
{
	local TDialogueBoxData kData;

	kData.strTitle = m_strLabsExitWithoutProjectTitle;
	kData.strText = m_strLabsExitWithoutProjectBody;
	kData.strAccept = m_strLabsExitWithoutProjectStay;
	kData.strCancel = m_strLabsExitWithoutProjectLeave;
	kData.eType = eDialog_Warning;
	kData.fnCallback = OnLeaveFacilityWithoutProjectPopupCallback;

	Movie.Pres.UIRaiseDialog(kData);
}

simulated function OnLeaveFacilityWithoutProjectPopupCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
		`HQPRES.UIChooseResearch();
	else
		LeaveLabs(); // If Cancel, allow you to leave this screen. 
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

		if (TechState != none && !TechState.bSeenResearchCompleteScreen && !TechState.GetMyTemplate().bShadowProject && !TechState.GetMyTemplate().bProvingGround)
		{
			if(default.DelayResearchReportTechs.Find(TechState.GetMyTemplateName()) != INDEX_NONE)
			{
				bDelayingResearchReport = true;
			}
			else
			{
				TechRefs.AddItem(TechState.GetReference());
				bNeedPopup = true;
			}
		}
	}
	
	return bNeedPopup;
}

// Called by outside screens (objective alerts)
function TriggerResearchReport()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> TechRefs;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.TechsResearched.Length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(XComHQ.TechsResearched[idx].ObjectID));

		if(TechState != none && !TechState.bSeenResearchCompleteScreen && !TechState.GetMyTemplate().bShadowProject && !TechState.GetMyTemplate().bProvingGround)
		{
			TechRefs.AddItem(TechState.GetReference());
		}
	}

	if(XComHQ.HasTechsAvailableForResearch())
	{
		`HQPRES.UIChooseResearch(bInstantInterp);
	}

	for(idx = 0; idx < TechRefs.Length; idx++)
	{
		// Check for additional unlocks from this tech to generate popups
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRefs[idx].ObjectID));
		TechState.DisplayTechCompletePopups();
		bDelayingResearchReport = false;
		`HQPRES.ResearchReportPopup(TechRefs[idx], bInstantInterp);
	}
}

simulated function RealizeNavHelp()
{
	NavHelp.ClearButtonHelp();

	if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M1_WelcomeToLabs'))
	{
		NavHelp.AddBackButton(OnCancel);
	}

	NavHelp.AddGeoscapeButton();
}

//==============================================================================

defaultproperties
{
	bHideOnLoseFocus = false;
	DisplayTag="UIBlueprint_Powercore"
	CameraTag="UIBlueprint_Powercore"
	InputState = eInputState_Evaluate;
}
