//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIShadowChamberArchives.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Screen that allows the player to review projects already completed. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIShadowChamberArchives extends UIChooseResearch;

var localized string m_strViewReport;

//----------------------------------------------------------------------------

simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	`HQPRES.ShadowChamberResearchReportPopup(m_arrRefs[itemIndex]);
}

simulated function RefreshNavHelp()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(OnCancel);
}

//----------------------------------------------------------------------------

simulated function array<StateObjectReference> GetTechs() 
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetCompletedShadowTechs(); 
}

simulated function array<Commodity> ConvertTechsToCommodities()
{
	local XComGameState_Tech TechState;
	local int iTech;
	local array<Commodity> arrCommodoties;
	local Commodity TechComm;
	local StrategyCost EmptyCost;
	local StrategyRequirement EmptyReqs;

	m_arrRefs.Remove(0, m_arrRefs.Length);
	m_arrRefs = GetTechs();
	m_arrRefs.Sort(SortTechsAlpha);

	for (iTech = 0; iTech < m_arrRefs.Length; iTech++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iTech].ObjectID));

		TechComm.Title = TechState.GetDisplayName();
		TechComm.Image = TechState.GetImage();
		TechComm.Desc = TechState.GetSummary();
		TechComm.bTech = true;

		//We are reviewing these in the archives, so no cost or requirements should display here. 
		TechComm.Cost = EmptyCost;
		TechComm.OrderHours = -1;
		TechComm.Requirements = EmptyReqs;

		arrCommodoties.AddItem(TechComm);
	}

	return arrCommodoties;
}

simulated function String GetButtonString(int ItemIndex)
{
	return m_strViewReport;
}

//==============================================================================

defaultproperties
{
	DisplayTag		= "UIBlueprint_ShadowChamber";
	CameraTag		= "UIBlueprint_ShadowChamber";

	m_bInfoOnly=true
	m_bShowButton = false
	m_eStyle = eUIConfirmButtonStyle_Default
}
