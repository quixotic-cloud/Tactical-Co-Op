//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPanel.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Screen that allows the player to select tech to research.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIChooseResearch extends UISimpleCommodityScreen config(GameData);

var StateObjectReference CurrentTechRef;

var public bool bShadowChamber;
var public bool bInstantInterp;
var string ShadowChamberColor;
var public localized String m_strPriority;
var public localized String m_strInstant;
var public localized String m_strPaused;
var public localized String m_strResume;
var public localized String m_strStartShadowProjectTitle;
var public localized String m_strStartShadowProjectText;
var public localized String m_strSwitchShadowProjectTitle;
var public localized String m_strSwitchShadowProjectText;
var public localized String m_strSwitchResearchTitle;
var public localized String m_strSwitchResearchText;

var config array<name> MustChooseResearchObjectives; // Some tutorial objectives require research to be chosen (can't back out of screen)

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	RefreshNavHelp();

	OpenScreenEvent();
}

simulated function OpenScreenEvent()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Open Choose Research Event");
	`XEVENTMGR.TriggerEvent('OpenChooseResearch', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if( itemIndex != iSelectedItem )
	{	
		iSelectedItem = itemIndex;
	}

	if( CanAffordItem(iSelectedItem) )
	{
		if(OnTechTableOption(iSelectedItem))
		{
			PlaySFX("ResearchConfirm");
			Movie.Stack.Pop(self);
		}
	}
	else
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
	}
}

simulated function bool CanAffordItem(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrItems.Length )
	{
		return XComHQ.CanAffordCommodity(arrItems[ItemIndex]);
	}
	else
	{
		return false;
	}
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function GetItems()
{
	arrItems = ConvertTechsToCommodities();
}

simulated function array<Commodity> ConvertTechsToCommodities()
{
	local XComGameState_Tech TechState;
	local int iTech;
	local bool bPausedProject;
	local bool bCompletedTech;
	local array<Commodity> arrCommodoties;
	local Commodity TechComm;
	local StrategyCost EmptyCost;
	local StrategyRequirement EmptyReqs;

	m_arrRefs.Remove(0, m_arrRefs.Length);
	m_arrRefs = GetTechs();
	m_arrRefs.Sort(SortTechsTime);
	m_arrRefs.Sort(SortTechsTier);
	m_arrRefs.Sort(SortTechsPriority);
	m_arrRefs.Sort(SortTechsInstant);
	m_arrRefs.Sort(SortTechsCanResearch);

	for( iTech = 0; iTech < m_arrRefs.Length; iTech++ )
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iTech].ObjectID));
		bPausedProject = XComHQ.HasPausedProject(m_arrRefs[iTech]);
		bCompletedTech = XComHQ.TechIsResearched(m_arrRefs[iTech]);
		
		TechComm.Title = TechState.GetDisplayName();

		if (bPausedProject)
		{
			TechComm.Title = TechComm.Title @ m_strPaused;
		}
		else if (TechState.bForceInstant)
		{
			TechComm.Title = TechComm.Title @ m_strInstant;
		}

		TechComm.Image = TechState.GetImage();
		TechComm.Desc = TechState.GetSummary();		
		TechComm.OrderHours = XComHQ.GetResearchHours(m_arrRefs[iTech]);
		TechComm.bTech = true;
		
		if (bPausedProject || (bCompletedTech && !TechState.GetMyTemplate().bRepeatable))
		{
			TechComm.Cost = EmptyCost;
			TechComm.Requirements = EmptyReqs;
		}
		else
		{
			TechComm.Cost = TechState.GetMyTemplate().Cost;
			TechComm.Requirements = GetBestStrategyRequirementsForUI(TechState.GetMyTemplate());
			TechComm.CostScalars = XComHQ.ResearchCostScalars;
		}

		arrCommodoties.AddItem(TechComm);
	}

	return arrCommodoties;
}

simulated function bool NeedsAttention(int ItemIndex)
{
	local XComGameState_Tech TechState;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[ItemIndex].ObjectID));
	return TechState.IsPriority();
}

simulated function bool ShouldShowGoodState(int ItemIndex)
{
	local XComGameState_Tech TechState;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[ItemIndex].ObjectID));
	return TechState.bForceInstant;
}

//simulated function String GetItemDurationString(int ItemIndex)
//{
//	local String strTime;
//	if( ItemIndex > -1 && ItemIndex < arrItems.Length )
//	{
//		strTime = XComHQ.GetResearchEstimateString(m_arrRefs[ItemIndex]);
//		return class'UIUtilities_Strategy'.static.GetResearchProgressString(XComHQ.GetResearchProgress(m_arrRefs[ItemIndex])) $ " (" $ strTime $ ")";
//	}
//	else
//	{
//		return "";
//	}
//}
//simulated function EUIState GetDurationColor(int ItemIndex)
//{
//	return class'UIUtilities_Strategy'.static.GetResearchProgressColor(XComHQ.GetResearchProgress(m_arrRefs[ItemIndex]));
//}
//simulated function EUIState GetMainColor()
//{
//	if( bShadowChamber )
//		return eUIState_Psyonic;
//	else
//		return m_eMainColor;
//}
simulated function String GetButtonString(int ItemIndex)
{
	if (XComHQ.HasPausedProject(m_arrRefs[ItemIndex]))
	{
		return m_strResume;
	}
	else
	{
		return m_strBuy;
	}
}

//-----------------------------------------------------------------------------

//This is overwritten in the research archives. 
simulated function array<StateObjectReference> GetTechs() 
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableTechsForResearch(bShadowChamber);
}

simulated function StrategyRequirement GetBestStrategyRequirementsForUI(X2TechTemplate TechTemplate)
{
	local StrategyRequirement AltRequirement;

	if (!XComHQ.MeetsAllStrategyRequirements(TechTemplate.Requirements) && TechTemplate.AlternateRequirements.Length > 0)
	{
		foreach TechTemplate.AlternateRequirements(AltRequirement)
		{
			if (XComHQ.MeetsAllStrategyRequirements(AltRequirement))
			{
				return AltRequirement;
			}
		}
	}

	return TechTemplate.Requirements;
}

function int SortTechsInstant(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local XComGameState_Tech TechStateA, TechStateB;

	TechStateA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID));
	TechStateB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID));

	if (TechStateA.IsInstant() && !TechStateB.IsInstant())
	{
		return 1;
	}
	else if (!TechStateA.IsInstant() && TechStateB.IsInstant())
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortTechsPriority(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local XComGameState_Tech TechStateA, TechStateB;

	TechStateA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID));
	TechStateB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID));

	if(TechStateA.IsPriority() && !TechStateB.IsPriority())
	{
		return 1;
	}
	else if(!TechStateA.IsPriority() && TechStateB.IsPriority())
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortTechsCanResearch(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local X2TechTemplate TechTemplateA, TechTemplateB;
	local bool CanResearchA, CanResearchB;


	TechTemplateA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID)).GetMyTemplate();
	TechTemplateB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID)).GetMyTemplate();
	CanResearchA = XComHQ.MeetsRequirmentsAndCanAffordCost(TechTemplateA.Requirements, TechTemplateA.Cost, XComHQ.ResearchCostScalars, 0.0, TechTemplateA.AlternateRequirements);
	CanResearchB = XComHQ.MeetsRequirmentsAndCanAffordCost(TechTemplateB.Requirements, TechTemplateB.Cost, XComHQ.ResearchCostScalars, 0.0, TechTemplateB.AlternateRequirements);

	if (CanResearchA && !CanResearchB)
	{
		return 1;
	}
	else if (!CanResearchA && CanResearchB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortTechsTime(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local int HoursA, HoursB;

	HoursA = XComHQ.GetResearchHours(TechRefA);
	HoursB = XComHQ.GetResearchHours(TechRefB);

	if (HoursA < HoursB)
	{
		return 1;
	}
	else if (HoursA > HoursB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortTechsTier(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local int TierA, TierB;

	TierA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID)).GetMyTemplate().SortingTier;
	TierB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID)).GetMyTemplate().SortingTier;

	if (TierA < TierB) return 1;
	else if (TierA > TierB) return -1;
	else return 0;
}

function int SortTechsAlpha(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local X2TechTemplate TechTemplateA, TechTemplateB;

	TechTemplateA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID)).GetMyTemplate();
	TechTemplateB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID)).GetMyTemplate();

	if(TechTemplateA.DisplayName < TechTemplateB.DisplayName)
	{
		return 1;
	}
	else if(TechTemplateA.DisplayName > TechTemplateB.DisplayName)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function bool OnTechTableOption(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;

	TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iOption].ObjectID));

	if(!XComHQ.HasPausedProject(m_arrRefs[iOption]) && !XComHQ.MeetsRequirmentsAndCanAffordCost(TechState.GetMyTemplate().Requirements, TechState.GetMyTemplate().Cost, XComHQ.ResearchCostScalars, 0.0, TechState.GetMyTemplate().AlternateRequirements))
	{
		//SOUND().PlaySFX(SNDLIB().SFX_UI_No);
		return false;
	}

	if(bShadowChamber)
	{
		if(XComHQ.HasActiveShadowProject())
		{
			ConfirmSwitchShadowProjectPopup(m_arrRefs[iOption]);
			return false;
		}
		else
		{
			ConfirmStartShadowProjectPopup(m_arrRefs[iOption]);
			return false;
		}
	}
	else
	{
		if(XComHQ.HasResearchProject())
		{
			ConfirmSwitchResearchPopup(m_arrRefs[iOption]);
			return false;
		}
		else
		{
			if ((!TechState.IsInstant() && !TechState.GetMyTemplate().bAutopsy) || XComHQ.GetObjectiveStatus('T0_M6_WelcomeToLabsPt2') == eObjectiveState_InProgress)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Choose Research Event");
				`XEVENTMGR.TriggerEvent('ChooseResearch', TechState, TechState, NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}

			XComHQ.SetNewResearchProject(m_arrRefs[iOption]);
		}
	}
	
	return true;
}

//----------------------------------------------------------------
simulated public function ConfirmStartShadowProjectPopup(StateObjectReference TechRef)
{
	local TDialogueBoxData kDialogData;

	CurrentTechRef = TechRef;

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strStartShadowProjectTitle;
	kDialogData.strText = m_strStartShadowProjectText;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

	kDialogData.fnCallback = ConfirmStartShadowProjectPopupCallback;
	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated function ConfirmStartShadowProjectPopupCallback(eUIAction eAction)
{
	if(eAction == eUIAction_Accept)
	{
		PlaySFX("ResearchConfirm");
		XComHQ.SetNewResearchProject(CurrentTechRef);
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		`HQPRES.ScreenStack.PopFirstInstanceOfClass(class'UIChooseResearch');
	}
	else if(eAction == eUIAction_Cancel)
	{

	}
}

//----------------------------------------------------------------
simulated public function ConfirmSwitchShadowProjectPopup(StateObjectReference TechRef)
{
	local TDialogueBoxData kDialogData;
	local XGParamTag LocTag;

	CurrentTechRef = TechRef;
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = XComHQ.GetCurrentShadowTech().GetDisplayName();

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strSwitchShadowProjectTitle;
	kDialogData.strText = `XEXPAND.ExpandString(m_strSwitchShadowProjectText);
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

	kDialogData.fnCallback = ConfirmSwitchShadowProjectPopupCallback;
	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated function ConfirmSwitchShadowProjectPopupCallback(eUIAction eAction)
{
	local XComGameState NewGameState;

	if(eAction == eUIAction_Accept)
	{
		PlaySFX("ResearchConfirm");
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pause Shadow Project");
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		XComHQ.PauseShadowProject(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		XComHQ.HandlePowerOrStaffingChange();
		XComHQ.SetNewResearchProject(CurrentTechRef);
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		`HQPRES.ScreenStack.PopFirstInstanceOfClass(class'UIChooseResearch');
	}
	else if(eAction == eUIAction_Cancel)
	{

	}
}


//----------------------------------------------------------------
simulated public function ConfirmSwitchResearchPopup(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local TDialogueBoxData kDialogData;
	local XGParamTag LocTag;

	CurrentTechRef = TechRef;
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = XComHQ.GetCurrentResearchTech().GetDisplayName();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Switch Research Event");
	`XEVENTMGR.TriggerEvent('SwitchFirstResearch', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strSwitchResearchTitle;
	kDialogData.strText = `XEXPAND.ExpandString(m_strSwitchResearchText);
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

	kDialogData.fnCallback = ConfirmSwitchResearchPopupCallback;
	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated function ConfirmSwitchResearchPopupCallback(eUIAction eAction)
{
	local XComGameState NewGameState;

	if( eAction == eUIAction_Accept )
	{
		PlaySFX("ResearchConfirm");
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pause Research Project");
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		XComHQ.PauseResearchProject(NewGameState);
		`XEVENTMGR.TriggerEvent('SwitchResearch', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		XComHQ.HandlePowerOrStaffingChange();
		XComHQ.SetNewResearchProject(CurrentTechRef);
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		`HQPRES.ScreenStack.PopFirstInstanceOfClass(class'UIChooseResearch');
	}
	else if( eAction == eUIAction_Cancel )
	{

	}
}

//----------------------------------------------------------------
simulated function OnCancelButton( UIButton kButton ) { OnCancel(); }
simulated function OnCancel()
{
	if(HasCurrentResearch() || !MustChooseResearch())
	{
		CloseScreen();
	}	
}

function bool HasCurrentResearch()
{
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(bShadowChamber)
	{
		return XComHQ.HasShadowProject();
	}
	else
	{
		return XComHQ.HasResearchProject();
	}
}

function bool MustChooseResearch()
{
	local int idx;

	for(idx = 0; idx < MustChooseResearchObjectives.Length; idx++)
	{
		if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus(MustChooseResearchObjectives[idx]) == eObjectiveState_InProgress)
		{
			return true;
		}
	}

	return false;
}

//==============================================================================

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	Movie.Pres.Get3DMovie().HideDisplay(DisplayTag);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	RefreshNavHelp();
	
	class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, `HQINTERPTIME);
}
simulated function RefreshNavHelp()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	if( !MustChooseResearch() || HasCurrentResearch() )
	{
		`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(OnCancel);
	}
}

simulated function SetShadowChamber()
{
	bShadowChamber = true;
	DisplayTag      = 'UIBlueprint_ShadowChamber';
	CameraTag       = 'UIBlueprint_ShadowChamber';
}

defaultproperties
{
	InputState    = eInputState_Consume;

	DisplayTag      = "UIBlueprint_Powercore";
	CameraTag       = "UIBlueprint_Powercore";
 
	bHideOnLoseFocus = true;

	ShadowChamberColor = "9400D3";
}
