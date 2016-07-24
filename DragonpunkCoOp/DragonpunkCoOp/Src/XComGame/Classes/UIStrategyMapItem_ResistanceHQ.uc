//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_ResistanceHQ
//  AUTHOR:  Joe Weinhoffer
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_ResistanceHQ extends UIStrategyMapItem;

var UIScanButton ScanButton;
var localized string MapPin_TooltipResistanceGoods; 
var localized string MapPin_TooltipResistanceGoodsOutOfStock;

simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	// Spawn the children BEFORE the super.Init because inside that super, it will trigger UpdateFlyoverText and other functions
	// which may assume these children already exist. 
		
	super.InitMapItem(Entity);

	ScanButton = Spawn(class'UIScanButton', self).InitScanButton();
	ScanButton.SetX(-30); //This location is to stop overlapping the 3D art.
	ScanButton.SetY(35);
	ScanButton.SetButtonIcon("");
	ScanButton.SetDefaultDelegate(OnDefaultClicked);
	ScanButton.SetFactionDelegate(OnFactionClicked);
	ScanButton.SetButtonType(eUIScanButtonType_ResHQ);
	ScanButton.ShowScanIcon(true);
	GenerateTooltip(MapPin_Tooltip);
	
	return self;
}

function UpdateFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local string ScanTitle;
	local string ScanTimeValue;
	local string ScanTimeLabel;
	local string ScanInfo;

	if( !bIsInited ) return; 

	super.UpdateFromGeoscapeEntity(GeoscapeEntity);

	ScanTitle = GetHavenTitle();
	ScanTimeValue = "";
	ScanTimeLabel = "";
	ScanInfo = GetHavenScanDescription();

	if( IsAvengerLandedHere() )
		ScanButton.Expand();
	else
		ScanButton.DefaultState();

	if (GetHaven().HasResistanceGoods())
	{
		ScanButton.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_Resistance);
	}
	else
	{
		ScanButton.SetButtonIcon("");
	}

	ScanButton.PulseFaction(!GetHaven().HasSeenNewResGoods());
	ScanButton.SetText(ScanTitle, ScanInfo, ScanTimeValue, ScanTimeLabel);
	ScanButton.AnimateIcon(`GAME.GetGeoscape().IsScanning() && IsAvengerLandedHere());
	ScanButton.Realize();
}

function OnDefaultClicked()
{
	GetHaven().AttemptSelectionCheckInterruption();
}

function OnFactionClicked()
{
	GetHaven().DisplayResistanceGoods();
}

simulated function XComGameState_Haven GetHaven()
{
	return XComGameState_Haven(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
}

function string GetHavenTitle()
{
	return (MapPin_Header);
}

function string GetHavenScanDescription()
{
	return GetHaven().m_strScanButtonLabel;
}

function GenerateTooltip(string tooltipHTML)
{
	if(tooltipHTML != "" && ScanButton != none)
	{
		ScanButton.SetScannerTooltip(MapPin_Tooltip);
		if( GetHaven().HasResistanceGoods() )
			ScanButton.SetFactionTooltip(MapPin_TooltipResistanceGoods);
		else
			ScanButton.SetFactionTooltip(MapPin_TooltipResistanceGoodsOutOfStock);

		bHasTooltip = true;
	}
}

defaultproperties
{
	bProcessesMouseEvents = false;
}