//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISchematicArchives.uc
//  AUTHOR:  Joe Weinhoffer 
//  PURPOSE: Screen that allows the player to review proving ground projects already completed. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UISchematicArchives extends UIChooseResearch;

//----------------------------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	SetX(500);
}

simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	// Do nothing here, prevent projects from being restarted
}

simulated function array<StateObjectReference> GetTechs()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetCompletedProvingGroundTechs();
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

	for( iTech = 0; iTech < m_arrRefs.Length; iTech++ )
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iTech].ObjectID));

		TechComm.Title = TechState.GetDisplayName();
		TechComm.Image = TechState.GetImage();
		TechComm.Desc = TechState.GetSummary();
		TechComm.bTech = true;

		//WE are reviewing these in the archives, so no cost or requirements should display here. 
		TechComm.Cost = EmptyCost;
		TechComm.OrderHours = -1;
		TechComm.Requirements = EmptyReqs;

		arrCommodoties.AddItem(TechComm);
	}

	return arrCommodoties;
}

//==============================================================================

defaultproperties
{
	m_bInfoOnly = true
	m_bShowButton = false

	DisplayTag      = "UIBlueprint_BuildItems";
	CameraTag       = "UIBlueprint_BuildItems";

	m_eStyle = eUIConfirmButtonStyle_None
}
