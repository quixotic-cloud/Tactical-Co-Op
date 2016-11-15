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

var int ScannerTooltipId;
var int FactionTooltipId;
var bool bNeedsUpdate;
var bool bScanHintResGoods;
//</workshop>
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
	//ScanButton.SetButtonType(eUIScanButtonType_Default);
	ScanButton.ShowScanIcon(true);
	ScanButton.MC.FunctionVoid("SetScanHintDefaultSelection" );
	ScanButton.OnSizeRealized = OnButtonSizeRealized;
	GenerateTooltip(MapPin_Tooltip);
	
	return self;
}
simulated function OnButtonSizeRealized()
{
	ScanButton.SetX(-ScanButton.Width / 2.0);
}

function UpdateFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local string ScanTitle;
	local string ScanTimeValue;
	local string ScanTimeLabel;
	local string ScanInfo;
	local bool bAvengerLandedHere; 

	if( !bIsInited ) return; 

	super.UpdateFromGeoscapeEntity(GeoscapeEntity);

	ScanTitle = GetHavenTitle();
	ScanTimeValue = "";
	ScanTimeLabel = "";
	ScanInfo = GetHavenScanDescription();
	
	bAvengerLandedHere = IsAvengerLandedHere();

	if( bAvengerLandedHere )
		ScanButton.Expand();
	else
	{
		ScanButton.DefaultState();
	}

	if (GetHaven().HasResistanceGoods())
	{
		ScanButton.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_Resistance);
		if( bAvengerLandedHere && !bScanHintResGoods )
		{
			ScanButton.MC.FunctionVoid("SetScanHintResistanceGoods"); //bsg-jneal (7.21.16): set the left button help icon to be X/SQUARE instead of select when at the HQ with goods unlocked
			bScanHintResGoods = true;
		}

		if( !bAvengerLandedHere && bScanHintResGoods )
		{
			ScanButton.MC.FunctionVoid("SetScanHintDefaultSelection");
			bScanHintResGoods = false;
		}
	}
	else
	{
		ScanButton.SetButtonIcon("");
		if( bScanHintResGoods )
		{
			ScanButton.MC.FunctionVoid("SetScanHintDefaultSelection");
			bScanHintResGoods = false;
		}
	}

	ScanButton.PulseFaction(!GetHaven().HasSeenNewResGoods());
	ScanButton.SetText(ScanTitle, ScanInfo, ScanTimeValue, ScanTimeLabel);
	ScanButton.AnimateIcon(`GAME.GetGeoscape().IsScanning() && IsAvengerLandedHere());
	ScanButton.Realize();
	if (bNeedsUpdate)
	{
		ScanButton.bExpandOnRealize = true;
		ScanButton.bDirty = true;
		ScanButton.Realize();
		if ( bAvengerLandedHere && bIsFocused) //bsg-jneal (8.31.16): only receive focus on the scan button if this map item is focused, fixes an incorrect focus state on init
		{
			ScanButton.OnReceiveFocus();
		}

		bNeedsUpdate = false;
	}
	if (GetHaven().HasResistanceGoods())
	{
		CachedTooltipId = FactionTooltipId;
	}
	else
	{
		CachedTooltipId = ScannerTooltipId;
	}
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
		ScannerTooltipId = ScanButton.SetScannerTooltip(MapPin_Tooltip);
		if (GetHaven().HasResistanceGoods())
		{
			FactionTooltipId = ScanButton.SetFactionTooltip(MapPin_TooltipResistanceGoods);
		}
		else
		{
			FactionTooltipId = ScanButton.SetFactionTooltip(MapPin_TooltipResistanceGoodsOutOfStock);
		}

		bHasTooltip = true;
	}
}

simulated function OnReceiveFocus()
{
	ScanButton.OnReceiveFocus();
	bNeedsUpdate = true;
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
	//bsg-jneal (7.29.16): check for resistance goods on X button now instead of A
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		if (GetHaven().HasResistanceGoods())
		{
			OnFactionClicked();
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
	bNeedsUpdate = true;
}