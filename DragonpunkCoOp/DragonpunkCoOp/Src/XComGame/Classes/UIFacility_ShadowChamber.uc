//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_ShadowChamber.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_ShadowChamber extends UIFacility config(GameData);

var localized string m_strResearch;
var localized string m_strCurrentResearch;
var localized string m_strNoActiveResearch;
var localized string m_strStalledResearch;
var localized string m_strPauseResearch;
var localized String m_strSciSkill;
var localized String m_strEngSkill;
var localized String m_strProgress;

var string ColorString;

var bool bDelayingResearchReport;
var config array<name> DelayResearchReportTechs;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> TechRefs;
	local int idx;

	super.InitScreen(InitController, InitMovie, InitName);

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	BuildScreen();

	if(NeedResearchReportPopup(TechRefs))
	{
		//if (XCOMHQ().HasTechsAvailableForResearch(true))
		//{
		//	`HQPRES.UIChooseShadowProject(bInstantInterp);
		//}

		for (idx = 0; idx < TechRefs.Length; idx++)
		{
			// Check for additional unlocks from this tech to generate popups
			TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRefs[idx].ObjectID));
			TechState.DisplayTechCompletePopups();
			bDelayingResearchReport = false;
			`HQPRES.ResearchReportPopup(TechRefs[idx], bInstantInterp);
		}
	}

	if (XComHQ.IsObjectiveCompleted('T2_M4_BuildStasisSuit') && XComHQ.IsObjectiveCompleted('T4_M2_S2_ResearchPsiGate') && XComHQ.GetObjectiveStatus('T5_M1_AutopsyTheAvatar') == eObjectiveState_InProgress)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Avatar Autopsy Ready");
		`XEVENTMGR.TriggerEvent('AvatarAutopsyReady', , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
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

	if( m_kResearchProgressBar != none && XCOMHQ().GetCurrentShadowTech() != none)
	{
		researchName = XCOMHQ().GetCurrentShadowTech().GetDisplayName();
		
		HoursRemaining = XCOMHQ().GetCurrentShadowProject().GetCurrentNumHoursRemaining();
		if (HoursRemaining < 0)
			days = class'UIUtilities_Text'.static.GetColoredText(m_strStalledResearch, eUIState_Warning);
		else
			days = class'UIUtilities_Text'.static.GetTimeRemainingString(HoursRemaining);

		progress = class'UIUtilities_Text'.static.GetColoredText(GetProgressString(), GetProgressColor());
		m_kResearchProgressBar.Update(m_strCurrentResearch, researchName, days, progress, int(100 * XCOMHQ().GetCurrentShadowProject().GetPercentComplete()));
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
	m_kStaffSlotContainer.SetTitle(m_strSciSkill);
	m_kStaffSlotContainer.SetStaffSkill("img:///UILibrary_StrategyImages.AlertIcons.Icon_science", GetScienceSkillString());
}

simulated function String GetProgressString()
{
	if( XCOMHQ().HasActiveShadowProject() )
	{
		return m_strProgress @ class'UIUtilities_Strategy'.static.GetResearchProgressString(XCOMHQ().GetResearchProgress(XCOMHQ().GetCurrentShadowTech().GetReference()));
	}
	else
	{
		return "";
	}
}

simulated function EUIState GetProgressColor()
{
	//return class'UIUtilities_Strategy'.static.GetResearchProgressColor(XCOMHQ().GetResearchProgress(XCOMHQ().GetCurrentTechBeingResearched()));
	return eUIState_Psyonic;
}

simulated function String GetEngSkillString()
{
	return String(XCOMHQ().GetNumberOfEngineers());
}
simulated function String GetScienceSkillString()
{
	return String(XCOMHQ().GetNumberOfScientists());
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

	for(idx = 0; idx < XComHQ.TechsResearched.Length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(XComHQ.TechsResearched[idx].ObjectID));

		if(TechState != none && !TechState.bSeenResearchCompleteScreen && TechState.GetMyTemplate().bShadowProject && !TechState.GetMyTemplate().bProvingGround)
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

		if(TechState != none && !TechState.bSeenResearchCompleteScreen && TechState.GetMyTemplate().bShadowProject && !TechState.GetMyTemplate().bProvingGround)
		{
			TechRefs.AddItem(TechState.GetReference());
		}
	}

	//if(XComHQ.HasTechsAvailableForResearch(true))
	//{
	//	`HQPRES.UIChooseShadowProject(false);
	//}

	for(idx = 0; idx < TechRefs.Length; idx++)
	{
		// Check for additional unlocks from this tech to generate popups
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRefs[idx].ObjectID));
		TechState.DisplayTechCompletePopups();
		bDelayingResearchReport = false;
		`HQPRES.ResearchReportPopup(TechRefs[idx], false);
	}
}

// ------------------------------------------------------------

simulated function RealizeNavHelp()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	super.RealizeNavHelp();
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.HasActiveShadowProject())
	{
		NavHelp.AddRightHelp(m_strPauseResearch, class'UIUtilities_Input'.const.ICON_A_X, `HQPRES.PauseShadowProjectPopup);
		
		if( UpgradeButton != none ) 
		{
			RefreshUpgradeLocationBasedOnAnchor();
		}
	}
}

simulated function ShowUpgradeButton()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	
	super.ShowUpgradeButton();

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if( XComHQ.HasActiveShadowProject() && UpgradeButton != none )
	{
		UpgradeButton.OnSizeRealized = RefreshUpgradeLocationBasedOnAnchor;
	}
}

simulated function RefreshUpgradeLocationBasedOnAnchor()
{
	UpgradeButton.RefreshLocationBasedOnAnchor();
	
	//Avoid the pause research button.
	UpgradeButton.SetY( -Upgradebutton.Height - 50);
}

simulated function OnClickCurrentResearch(UIPanel control, int cmd)
{
	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		if(Movie.Stack.GetScreen(class'UIChooseResearch') == none)
			`HQPRES.UIChooseShadowProject();
		break;
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateData();
}

simulated function OnCancel()
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entered Power Core");
	FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));
	NewGameState.AddStateObject(FacilityState);
	`XEVENTMGR.TriggerEvent('OnShadowChamberExit', FacilityState, FacilityState, NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	super.OnCancel();
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Evaluate;
	ColorString = "9400D3";
	bHideOnLoseFocus = false;
}
