//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_POI
//  AUTHOR:  Sam Batista -- 08/2014
//  PURPOSE: This file represents a point of interest spot on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_POI extends UIStrategyMapItem;

var UIScanButton ScanButton;

simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	// Spawn the children BEFORE the super.Init because inside that super, it will trigger UpdateFlyoverText and other functions
	// which may assume these children already exist. 

	super.InitMapItem(Entity);

	ScanButton = Spawn(class'UIScanButton', self).InitScanButton();
	ScanButton.SetButtonIcon("");
	ScanButton.SetDefaultDelegate(OnDefaultClicked);
	ScanButton.SetButtonType(eUIScanButtonType_Default);
	ScanButton.OnSizeRealized = OnButtonSizeRealized;

	return self;
}
simulated function OnButtonSizeRealized()
{
	ScanButton.SetX(-ScanButton.Width / 2.0);
}

function UpdateFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local XComGameState_PointOfInterest POIState;
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

	POIState = GetPOI();

	ScanTitle = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(POIState.GetDisplayName());
	DaysRemaining = POIState.GetNumScanDaysRemaining();
	ScanTimeValue = string(DaysRemaining);
	ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
	ScanInfo = POIState.GetRewardDescriptionString();

	if( `ISCONTROLLERACTIVE == false )
		ScanButton.PulseScanner(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M10_L0_FirstTimeScan') == eObjectiveState_InProgress && IsAvengerLandedHere());
	ScanButton.SetText(ScanTitle, ScanInfo, ScanTimeValue, ScanTimeLabel);
	ScanButton.AnimateIcon(`GAME.GetGeoscape().IsScanning() && IsAvengerLandedHere());
	ScanButton.SetScanMeter(POIState.GetScanPercentComplete());
	ScanButton.Realize();
}

function OnDefaultClicked()
{
	GetPOI().AttemptSelectionCheckInterruption();
}

simulated function XComGameState_PointOfInterest GetPOI()
{
	return XComGameState_PointOfInterest(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
}

simulated function OnReceiveFocus()
{
	ScanButton.OnReceiveFocus();
}

simulated function OnLoseFocus()
{
	ScanButton.OnLoseFocus();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return true;
	}

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		if (IsAvengerLandedHere())
		{
			ScanButton.ClickButtonScan();
		}
		else
		{
			OnDefaultClicked();
		}

		return true;		
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function bool IsSelectable()
{
	return true;
}
simulated function SetZoomLevel(float ZoomLevel)
{
	super.SetZoomLevel(ZoomLevel);

	ScanButton.SetY(70.0 * (1.0 - FClamp(ZoomLevel, 0.0, 0.95)));
}
defaultproperties
{
	bProcessesMouseEvents = false;
}