//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_LandingSite\
//  AUTHOR:  Sam Batista -- 08/2014
//  PURPOSE: This file represents a landing spot on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_LandingSite extends UIStrategyMapItem;

var localized string LandingSiteTriadIconTooltip; 

simulated function OnInitFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	
}

simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	super.InitMapItem(Entity);

	//GenerateTriadTooltip(LandingSiteTriadIconTooltip);
	
	return self;
}

function GenerateTriadTooltip(string tooltipHTML)
{
	if (tooltipHTML != "")
	{
		Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(tooltipHTML, 15, 0, MCPath$".triadIcon", , false, , true);
		bHasTooltip = true;
	}
}

function UpdateFlyoverText()
{
	local XComGameState_Continent LandingSite;

	LandingSite = XComGameState_Continent(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));

	SetLabel(LandingSite.GetMyTemplate().DisplayName);
	UpdatePopSupportAndAlert();
	//UpdateTriadIcon(LandingSite.AlienNetworkMissionUnlocked(), LandingSite.AlienNetworkComponents.Length);
}

simulated function OnMouseIn()
{
	local UIStrategyMap StrategyMap;
	StrategyMap = UIStrategyMap(Movie.Stack.GetScreen(class'UIStrategyMap'));
	StrategyMap.UpdatePopSupportAndAlert(GeoscapeEntityRef);
	StrategyMap.StrategyMapHUD.ShowAllThresholdTooltips();
}

simulated function OnMouseOut()
{
	local UIStrategyMap StrategyMap;
	StrategyMap = UIStrategyMap(Movie.Stack.GetScreen(class'UIStrategyMap'));
	StrategyMap.UpdatePopSupportAndAlert();
	StrategyMap.StrategyMapHUD.HideAllThresholdTooltips();
}

simulated function UpdatePopSupportAndAlert(optional StateObjectReference MissionRef)
{
	local array<int> PopularSupportBlocks, AlertBlocks, ThresholdIndicies;
	local XComGameStateHistory History;
	local XComGameState_Continent ContinentState;

	History = `XCOMHISTORY;
	ContinentState = XComGameState_Continent(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));

	if(ContinentState != none)
	{
		// PopularSupport Data
		ThresholdIndicies[0] = ContinentState.GetMaxResistanceLevel();

		PopularSupportBlocks = class'UIUtilities_Strategy'.static.GetMeterBlockTypes(ContinentState.GetMaxResistanceLevel(), ContinentState.GetResistanceLevel(),
																					 0,
																					 ThresholdIndicies);

		// Alert Data
		AlertBlocks.Length = 0;
	}

	UpdatePopularSupportMeter(PopularSupportBlocks);
	UpdateAlertMeter(AlertBlocks);
}

// Takes in an array of numbers that indicate the type of block to spawn:
//	0 - empty
//  1 - filled
//	2 - blinking
simulated function UpdatePopularSupportMeter( optional array<int> BlockTypes )
{
	local int i;
	MC.BeginFunctionOp("UpdatePopularSupportMeter");
	for(i = 0; i < BlockTypes.Length; ++i)
		MC.QueueNumber(BlockTypes[i]);
	MC.EndOp();
}
simulated function UpdateAlertMeter( optional array<int> BlockTypes )
{
	// DISABLING ALERT: per design, but not deleting because they reserve the right to make it reappear differently. 2/3/2015 bsteiner 
	//local int i;
	MC.BeginFunctionOp("UpdateAlertMeter");
	/*for(i = 0; i < BlockTypes.Length; ++i)
		MC.QueueNumber(BlockTypes[i]);*/
	MC.EndOp();
	
}

simulated function UpdateTriadIcon(bool bUnlockedMission, int PipsToFill)
{
	MC.BeginFunctionOp("SetTriadIcon");
	MC.QueueBoolean(bUnlockedMission);
	MC.QueueNumber(PipsToFill);
	MC.EndOp();
}

defaultproperties
{
	bDisableHitTestWhenZoomedOut = false;
	bFadeWhenZoomedOut = false;
}