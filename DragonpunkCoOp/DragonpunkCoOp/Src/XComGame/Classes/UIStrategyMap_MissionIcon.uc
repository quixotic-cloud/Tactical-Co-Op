//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMap_MissionIcon.uc
//  AUTHOR:  Joe Cortese 7/13/2015
//  PURPOSE: UIPanel to load a dynamic image icon and set background coloring. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------
class UIStrategyMap_MissionIcon extends UIIcon
	config(UI);

var XComGameState_ScanningSite ScanSite;
var XComGameState_MissionSite MissionSite;
var UIStrategyMapItem MapItem;
var UIStrategyMap_MissionIconTooltip Tooltip;

var config float ZoomLevel;

var int idNum;

simulated function UIStrategyMap_MissionIcon InitMissionIcon( optional int iD)
{
	local name IconInitName;

	idNum = iD;

	IconInitName = name("StrategyIcon"$iD);
	Super.InitIcon(IconInitName, , true, false, iD == 0? 96 : 64);
	
	mc.FunctionNum("SetIDNum", iD);

	return self;
}

simulated function SetSortedPosition(int numScanSites, int numMissions)
{
	mc.BeginFunctionOp("SetSortedPosition");
	mc.QueueNumber(numScanSites);
	mc.QueueNumber(numMissions);
	mc.EndOp();
}

simulated function SetScanSite(XComGameState_ScanningSite Scanner)
{
	local XComGameState_BlackMarket BlackMarket;

	MapItem = `HQPRES.StrategyMap2D.GetMapItem(Scanner);
	ScanSite = Scanner;
	MissionSite = none;
	OnClickedDelegate = ScanSite.AttemptSelectionCheckInterruption;
	LoadIcon(ScanSite.GetUIButtonIcon());
	HideTooltip();
	SetMissionIconTooltip(ScanSite.GetUIButtonTooltipTitle(), ScanSite.GetUIButtonTooltipBody());
	Show();

	BlackMarket = XComGameState_BlackMarket(Scanner);
	if (BlackMarket != None)
		AS_SetLock(BlackMarket.CanBeScanned()); // Black market icon is opposite, locked when it needs a scan
	else
		AS_SetLock(!ScanSite.CanBeScanned());

	AS_SetGoldenPath(false);
}

simulated function SetMissionSite(XComGameState_MissionSite Mission)
{
	local bool bMissionLocked, bIsGoldenPath;

	MapItem = `HQPRES.StrategyMap2D.GetMapItem(Mission);
	MissionSite = Mission;
	ScanSite = none;
	OnClickedDelegate = MissionSite.AttemptSelectionCheckInterruption;
	LoadIcon(MissionSite.GetUIButtonIcon());
	HideTooltip();
	SetMissionIconTooltip(MissionSite.GetUIButtonTooltipTitle(), MissionSite.GetUIButtonTooltipBody());
	Show();

	bMissionLocked = (!MissionSite.GetWorldRegion().HaveMadeContact() && MissionSite.bNotAtThreshold);
	bIsGoldenPath = (MissionSite.GetMissionSource().bGoldenPath);

	if(MissionSite.Source == 'MissionSource_Broadcast')
		AS_SetLock(false); //Broadcast the Truth cannot be locked
	else
		AS_SetLock(bMissionLocked);

	AS_SetGoldenPath(bIsGoldenPath);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	super.OnMouseEvent(cmd, args);

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
		MapItem.OnMouseIn();
		if(ScanSite != none)
		{
			ScanSite = XComGameState_ScanningSite(`XCOMHISTORY.GetGameStateForObjectID(ScanSite.ObjectID)); // Force an update of Scan Site game state
			SetMissionIconTooltip(ScanSite.GetUIButtonTooltipTitle(), ScanSite.GetUIButtonTooltipBody());
			XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(ScanSite.Get2DLocation(), ZoomLevel);	
		}
		else if( MissionSite != none )
		{
			SetMissionIconTooltip(MissionSite.GetUIButtonTooltipTitle(), MissionSite.GetUIButtonTooltipBody());
			XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(MissionSite.Get2DLocation(), ZoomLevel);
		}
		else
		{
			XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(MissionSite.Get2DLocation(), ZoomLevel);	
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		MapItem.OnMouseOut();
		XComHQPresentationLayer(Movie.Pres).CAMRestoreSavedLocation();
		break;
	};
}

simulated function HideTooltip()
{
	if( Tooltip != none )
	{
		Tooltip.HideTooltip();
	}
}

simulated function SetMissionIconTooltip(string Title, string Body)
{
	if( Tooltip == none )
	{
		Tooltip = Spawn(class'UIStrategyMap_MissionIconTooltip', Movie.Pres.m_kTooltipMgr);
		Tooltip.InitMissionIconTooltip(Title, Body);

		//Tooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER); 
		Tooltip.bFollowMouse = true;

		Tooltip.targetPath = string(MCPath);
		Tooltip.bUsePartialPath = true;
		Tooltip.tDelay = 0.0;

		Tooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(Tooltip);
	}
	else
	{
		Tooltip.SetText(Title, Body);
	}
}

simulated function AS_SetLock(bool isLocked)
{
	MC.FunctionBool("SetLock", isLocked);
}

simulated function AS_SetAlert(bool bShow)
{
	MC.FunctionBool("SetAlert", bShow);
}

simulated function AS_SetGoldenPath(bool bShow)
{
	MC.FunctionBool("SetGoldenPath", bShow);
}

simulated function Remove()
{
	Movie.Pres.m_kTooltipMgr.RemoveTooltipByTarget(string(MCPath));
	super.Remove();
}

defaultproperties
{
	LibID = "StrategyMapMissionIcon";
}