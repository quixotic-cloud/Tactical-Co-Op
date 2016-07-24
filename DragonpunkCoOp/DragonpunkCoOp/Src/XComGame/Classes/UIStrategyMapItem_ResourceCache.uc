//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_ResourceCache
//  AUTHOR:  Sam Batista -- 08/2014
//  PURPOSE: This file represents a resource cache spot on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_ResourceCache extends UIStrategyMapItem;

var UIScanButton ScanButton;

simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	// Spawn the children BEFORE the super.Init because inside that super, it will trigger UpdateFlyoverText and other functions
	// which may assume these children already exist. 
	
	super.InitMapItem(Entity);

	ScanButton = Spawn(class'UIScanButton', self).InitScanButton();
	ScanButton.SetY(15);
	ScanButton.SetButtonIcon("");
	ScanButton.SetDefaultDelegate(OnDefaultClicked);
	ScanButton.SetButtonType(eUIScanButtonType_Supplies);
	
	return self;
}

function UpdateFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local string ScanTitle;
	local string ScanTimeValue;
	local string ScanTimeLabel;
	local string ScanInfo;
	local int DaysRemaining;

	if( !bIsInited ) return; 

	super.UpdateFromGeoscapeEntity(GeoscapeEntity);

	if( IsAvengerLandedHere() )
		ScanButton.Expand();
	else
		ScanButton.DefaultState();


	ScanTitle = MapPin_Header;
	DaysRemaining = GetCache().GetNumScanDaysRemaining();
	ScanTimeValue = string(DaysRemaining);
	ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
	ScanInfo = GetCache().GetTotalResourceAmount();

	ScanButton.SetText(ScanTitle, ScanInfo, ScanTimeValue, ScanTimeLabel);
	ScanButton.AnimateIcon(`GAME.GetGeoscape().IsScanning() && IsAvengerLandedHere());
	ScanButton.SetScanMeter(GetCache().GetScanPercentComplete());
	ScanButton.Realize();
}

function OnDefaultClicked()
{
	GetCache().AttemptSelectionCheckInterruption();
}

simulated function XComGameState_ResourceCache GetCache()
{
	return XComGameState_ResourceCache(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
}

defaultproperties
{
	bProcessesMouseEvents = false;
}