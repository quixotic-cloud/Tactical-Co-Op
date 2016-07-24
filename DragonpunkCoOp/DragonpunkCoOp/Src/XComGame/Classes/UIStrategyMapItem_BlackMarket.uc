//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_BlackMarket
//  AUTHOR:  Mark Nauta -- 08/2014
//  PURPOSE: This file represents a black market spot on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_BlackMarket extends UIStrategyMapItem;

var public localized String m_strScanToOpenLabel;
var public localized String m_strTooltipClosedMarket;
var public localized String m_strTooltipOpenMarket;

var UIScanButton ScanButton;

simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	// Spawn the children BEFORE the super.Init because inside that super, it will trigger UpdateFlyoverText and other functions
	// which may assume these children already exist. 
	
	super.InitMapItem(Entity);

	ScanButton = Spawn(class'UIScanButton', self).InitScanButton();
	ScanButton.SetX(25); //This location is to stop overlapping 3D art.
	ScanButton.SetY(-30);
	ScanButton.SetButtonIcon("");
	ScanButton.SetDefaultDelegate(OnDefaultClicked);
	ScanButton.SetFactionDelegate(OnFactionClicked);
	ScanButton.SetButtonType(eUIScanButtonType_BlackMarket);

	return self;
}

function UpdateFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local XComGameState_BlackMarket BlackMarketState;
	local string ScanTitle;
	local string ScanTimeValue;
	local string ScanTimeLabel;
	local string ScanInfo;
	local int DaysRemaining;

	if( !bIsInited ) return; 

	super.UpdateFromGeoscapeEntity(GeoscapeEntity);

	if (IsAvengerLandedHere())
		ScanButton.Expand();
	else
		ScanButton.DefaultState();

	BlackMarketState = GetBlackMarket();
	
	ScanTitle = GetBlackMarketTitle();

	if (!BlackMarketState.bIsOpen)
	{
		DaysRemaining = BlackMarketState.GetNumScanDaysRemaining();
		ScanTimeValue = string(DaysRemaining);
		ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
		ScanInfo = m_strScanToOpenLabel;
		ScanButton.AnimateIcon(`GAME.GetGeoscape().IsScanning() && IsAvengerLandedHere());
		ScanButton.SetScanMeter(BlackMarketState.GetScanPercentComplete());
		ScanButton.SetButtonIcon("");
		ScanButton.ShowScanIcon(true);
	}
	else
	{
		ScanButton.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_BlackMarket);
		ScanButton.ShowScanIcon(false);
	}

	ScanButton.SetText(ScanTitle, ScanInfo, ScanTimeValue, ScanTimeLabel);
	ScanButton.Realize();
}

function OnDefaultClicked()
{
	GetBlackMarket().AttemptSelectionCheckInterruption();
}

function OnFactionClicked()
{
	if( Movie.Pres.ScreenStack.GetScreen(class'UIBlackMarket') == none )
		GetBlackMarket().DisplayBlackMarket();
}

simulated function XComGameState_BlackMarket GetBlackMarket()
{
	return XComGameState_BlackMarket(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
}

function string GetBlackMarketTitle()
{
	return (MapPin_Header);
}

function GenerateTooltip(string tooltipHTML)
{
	local int TooltipID;

	TooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(tooltipHTML, 15, 0, string(MCPath), , false, , true, , , , , , 0.0 /*no delay*/);
	Movie.Pres.m_kTooltipMgr.TextTooltip.SetMouseDelegates(TooltipID, RefreshTooltip);
	Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(TooltipID, true);
	bHasTooltip = true;
}

function RefreshTooltip(UITooltip refToThisTooltip)
{
	UITextTooltip(refToThisTooltip).SetText((GetBlackMarket().bIsOpen) ? m_strTooltipOpenMarket : m_strTooltipClosedMarket);
}


defaultproperties
{
	bProcessesMouseEvents = false; 
}