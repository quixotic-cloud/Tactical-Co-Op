//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChooseProject.uc
//  AUTHOR:  Joe Weinhoffer
//  PURPOSE: Screen that allows the player to select proving ground project tech to research.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIChooseProject extends UISimpleCommodityScreen;

var StateObjectReference CurrentProjectRef;

var public localized String m_strPriority;
var public localized String m_strPaused;
var public localized String m_strResume;

var bool bPlayedConfirmationVO;

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}

	if (CanAffordItem(iSelectedItem))
	{
		PlaySFX("BuildItem");
		OnTechTableOption(iSelectedItem);

		GetItems();
		PopulateData();
	}
	else
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
	}
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function GetItems()
{
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	arrItems = ConvertTechsToCommodities();
}

simulated function array<Commodity> ConvertTechsToCommodities()
{
	local XComGameState_Tech TechState;
	local int iProject;
	local bool bPausedProject;
	local array<Commodity> arrCommodoties;
	local Commodity TechComm;
	local StrategyCost EmptyCost;
	local StrategyRequirement EmptyReqs;

	m_arrRefs.Remove(0, m_arrRefs.Length);
	m_arrRefs = GetProjects();
	m_arrRefs.Sort(SortProjectsTime);
	m_arrRefs.Sort(SortProjectsTier);
	m_arrRefs.Sort(SortProjectsPriority);
	m_arrRefs.Sort(SortProjectsCanResearch);

	for (iProject = 0; iProject < m_arrRefs.Length; iProject++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iProject].ObjectID));
		bPausedProject = XComHQ.HasPausedProject(m_arrRefs[iProject]);
		
		TechComm.Title = TechState.GetDisplayName();

		if (bPausedProject)
		{
			TechComm.Title = TechComm.Title @ m_strPaused;
		}
		TechComm.Image = TechState.GetImage();
		TechComm.Desc = TechState.GetSummary();
		TechComm.OrderHours = XComHQ.GetResearchHours(m_arrRefs[iProject]);
		TechComm.bTech = true;

		if (bPausedProject)
		{
			TechComm.Cost = EmptyCost;
			TechComm.Requirements = EmptyReqs;
		}
		else
		{
			TechComm.Cost = TechState.GetMyTemplate().Cost;
			TechComm.Requirements = GetBestStrategyRequirementsForUI(TechState.GetMyTemplate());
			TechComm.CostScalars = XComHQ.ProvingGroundCostScalars;
			TechComm.DiscountPercent = XComHQ.ProvingGroundPercentDiscount;
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

//simulated function String GetItemReqString(int ItemIndex)
//{
//	if (ItemIndex > -1 && ItemIndex < arrItems.Length)
//	{
//		return class'UIUtilities_Strategy'.static.GetTechReqString(arrItems[ItemIndex]);
//	}
//	else
//	{
//		return "";
//	}
//}
//simulated function String GetItemDurationString(int ItemIndex)
//{
//	local String strTime;
//	if (ItemIndex > -1 && ItemIndex < arrItems.Length)
//	{
//		strTime = XComHQ.GetResearchEstimateString(m_arrProjects[ItemIndex]);
//		return class'UIUtilities_Strategy'.static.GetResearchProgressString(XComHQ.GetResearchProgress(m_arrProjects[ItemIndex])) $ " (" $ strTime $ ")";
//	}
//	else
//	{
//		return "";
//	}
//}
//simulated function EUIState GetDurationColor(int ItemIndex)
//{
//	return class'UIUtilities_Strategy'.static.GetResearchProgressColor(XComHQ.GetResearchProgress(m_arrProjects[ItemIndex]));
//}

//-----------------------------------------------------------------------------

//This is overwritten in the research archives. 
simulated function array<StateObjectReference> GetProjects()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableProvingGroundProjects();
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

function int SortProjectsPriority(StateObjectReference TechRefA, StateObjectReference TechRefB)
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

function int SortProjectsCanResearch(StateObjectReference TechRefA, StateObjectReference TechRefB)
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

function int SortProjectsTime(StateObjectReference TechRefA, StateObjectReference TechRefB)
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

function int SortProjectsTier(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local int TierA, TierB;

	TierA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID)).GetMyTemplate().SortingTier;
	TierB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID)).GetMyTemplate().SortingTier;

	if (TierA < TierB) return 1;
	else if (TierA > TierB) return -1;
	else return 0;
}

function bool OnTechTableOption(int iOption)
{
	local XComGameState_Tech TechState;

	TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iOption].ObjectID));
		
	if (!XComHQ.HasPausedProject(m_arrRefs[iOption]) && 
		!XComHQ.MeetsRequirmentsAndCanAffordCost(TechState.GetMyTemplate().Requirements, TechState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars, XComHQ.ProvingGroundPercentDiscount, TechState.GetMyTemplate().AlternateRequirements))
	{
		//SOUND().PlaySFX(SNDLIB().SFX_UI_No);
		return false;
	}
	
	StartNewProvingGroundProject(m_arrRefs[iOption]);
	
	return true;
}

//-------------------------------------------------
//---------------------------------------------------------------------------------------
function StartNewProvingGroundProject(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Proving Ground Project");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
			
	FacilityState = XComHQ.GetFacilityByName('ProvingGround');
	FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
	NewGameState.AddStateObject(FacilityState);

	ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectProvingGround'));
	NewGameState.AddStateObject(ProvingGroundProject);
	ProvingGroundProject.SetProjectFocus(TechRef, NewGameState, FacilityState.GetReference());
	ProvingGroundProject.SavedDiscountPercent = XComHQ.ProvingGroundPercentDiscount; // Save the current discount in case the project needs a refund
	XComHQ.Projects.AddItem(ProvingGroundProject.GetReference());
	
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
	XComHQ.PayStrategyCost(NewGameState, TechState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars, XComHQ.ProvingGroundPercentDiscount);

	//Add proving ground project to the build queue
	FacilityState.BuildQueue.AddItem(ProvingGroundProject.GetReference());

	if (!TechState.IsInstant() && !bPlayedConfirmationVO)
	{
		`XEVENTMGR.TriggerEvent('ChooseProvingGroundProject', , , NewGameState);
		bPlayedConfirmationVO = true;
	}
			
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if (ProvingGroundProject.bInstant)
	{
		ProvingGroundProject.OnProjectCompleted();
	}
	else if (FacilityState.GetNumEmptyStaffSlots() > 0)
	{
		StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

		if ((StaffSlotState.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
			(StaffSlotState.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
		{
			`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlotState.GetMyTemplate());
		}
	}
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.HandlePowerOrStaffingChange();

	RefreshQueue();

	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
	//We don't want to force this to be visible; it will turn on when the strategy screen listener triggers it on at the top base view. 
	`HQPRES.m_kAvengerHUD.Objectives.Hide();
}

simulated function RefreshQueue()
{
	local UIScreen QueueScreen;

	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_ProvingGround');
	if (QueueScreen != None)
	{
		UIFacility_ProvingGround(QueueScreen).UpdateBuildQueue();
		UIFacility_ProvingGround(QueueScreen).UpdateBuildProgress();
		UIFacility_ProvingGround(QueueScreen).m_NewBuildQueue.DeactivateButtons();
	}

	`HQPRES.m_kAvengerHUD.UpdateResources();
}

//----------------------------------------------------------------
simulated function OnCancelButton(UIButton kButton) { OnCancel(); }
simulated function OnCancel()
{
	CloseScreen();
}

//==============================================================================

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(OnCancel);
}

defaultproperties
{
	InputState = eInputState_Consume;

	DisplayTag      = "UIBlueprint_ProvingGrounds";
	CameraTag       = "UIBlueprint_ProvingGrounds";

	bHideOnLoseFocus = true;
}
