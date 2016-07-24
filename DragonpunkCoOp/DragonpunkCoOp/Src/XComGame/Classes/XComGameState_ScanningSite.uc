//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_ScanningSite.uc
//  AUTHOR:  Joe Weinhoffer  --  6/12/2015
//  PURPOSE: This object represents a Geoscape Entity which can be scanned by the Avenger
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_ScanningSite extends XComGameState_GeoscapeEntity
	native(Core)
	abstract
	config(GameBoard);

var private int ScanHoursRemaining;
var private int PausedDaysRemaining;
var private int TotalScanHours; // The total amount of time it will take to complete this scan. Used for UI display.
var protected bool bScanHasStarted;
var protected bool bScanPaused;
var protected bool bScanRepeatable; // Can this scan be completed multiple times. Will reset automatically after completion
var protected bool bCheckForOverlaps; // Should this scan site check for overlaps with HQ projects and missions
var protected TDateTime ScanEndDateTime; 

var config array<int> MinScanDays;
var config array<int> MaxScanDays;

var localized string m_strScanButtonLabel; 
var localized string m_strScanInteruptionText;
var localized string m_strDisplayLabel;
var localized string m_strRemainingLabel;

//#############################################################################################
//----------------   GEOSCAPE ENTITY IMPLEMENTATION   -----------------------------------------
//#############################################################################################

// Every scan site requires the Avenger to be present before scanning can begin
function bool RequiresAvenger()
{
	return true;
}

function bool HasTooltipBounds()
{
	return CanBeScanned();
}

function bool CanBeScanned()
{
	return true;
}

protected function bool CanInteract()
{
	return CanBeScanned();
}

//---------------------------------------------------------------------------------------
function DestinationReached()
{	
	OnXComEnterSite();

	// landing sound - eventually should be moved to visualizer
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_AvengerLand");
}

//---------------------------------------------------------------------------------------
function OnXComEnterSite()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Continent ContinentState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Arrive at Scanning Site");
	History = `XCOMHISTORY;

	// Update XCom's current continent, region, and location
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.CurrentLocation = self.GetReference();

	ContinentState = self.GetContinent();
	if (ContinentState != none)
	{
		XComHQ.Continent = ContinentState.GetReference();
	}

	RegionState = self.GetWorldRegion();
	if (RegionState != none)
	{
		XComHQ.Region = RegionState.GetReference();

		if (RegionState.CanBeScanned())
		{
			`XEVENTMGR.TriggerEvent('AvengerLandedScanRegion', , , NewGameState);
		}
	}

	NewGameState.AddStateObject(XComHQ);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	XGMissionControlUI(`HQPRES.GetMgr(class'XGMissionControlUI')).UpdateView();

	//Update the Avenger's Scanning and Resistance Network buttons
	`HQPRES.StrategyMap2D.UpdateButtonHelp();

	// Force map item to refresh its image
	RefreshMapItem();
}

//---------------------------------------------------------------------------------------
function OnXComLeaveSite()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference EmptyRef;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Leave Scan Site");
	History = `XCOMHISTORY;

	// Update XCom's current region
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.CurrentLocation = EmptyRef;
	XComHQ.Region = EmptyRef;
	XComHQ.Continent = EmptyRef;
	NewGameState.AddStateObject(XComHQ);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	XGMissionControlUI(`HQPRES.GetMgr(class'XGMissionControlUI')).UpdateView();

	// Force map item to refresh its image
	RefreshMapItem();
}

//---------------------------------------------------------------------------------------
simulated function RefreshMapItem()
{
	local UIStrategyMap StrategyMap;
	local XComGameState_GeoscapeEntity Entity;

	Entity = self; // hack to get around "self is not allowed in out parameter" error
	StrategyMap = UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap'));

	if (StrategyMap != none)
	{
		StrategyMap.GetMapItem(Entity).SetImage(GetUIPinImagePath());
		StrategyMap.GetMapItem(Entity).UpdateFlyoverText();
	}
}

//#############################################################################################
//----------------   SCANNING SITE IMPLEMENTATION   -------------------------------------------
//#############################################################################################

// Should be implemented in each subclass
function string GetDisplayName()
{
	return "NEEDS DISPLAY NAME";
}

function SetScanHoursRemaining(int MinDays, int MaxDays)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	ScanHoursRemaining = (MinDays * 24) + `SYNC_RAND((MaxDays * 24) - (MinDays * 24) + 1);

	if (XComHQ != none)
	{
		ScanHoursRemaining = float(ScanHoursRemaining) * XComHQ.CurrentScanRate;
	}

	TotalScanHours = ScanHoursRemaining;
}

// Should be called when the Avenger hits the scan button while at this location
function StartScan()
{		
	if (!bScanHasStarted) // This is the first time we have started scanning
		bScanHasStarted = true;
	
	bScanPaused = false;
	ScanEndDateTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(ScanEndDateTime, ScanHoursRemaining);

	if (bCheckForOverlaps)
	{
		CheckForEventOverlaps();
	}
}

// Should be called whenever the Avenger flies away from a scan site that is not completed, or something pauses the scan button
function PauseScan()
{
	if (bScanHasStarted && !bScanPaused)
	{
		bScanPaused = true;

		ScanHoursRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(ScanEndDateTime, GetCurrentTime());
		PausedDaysRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInDays(ScanEndDateTime, GetCurrentTime());
		ScanEndDateTime.m_iYear = 9999;
	}
}

function ResetScan(optional int MinDays = -1, optional int MaxDays = -1)
{
	// First reset the number of hours remaining
	if (MinDays == -1 && MaxDays == -1)
	{
		SetScanHoursRemaining(default.MinScanDays[`DIFFICULTYSETTING], default.MaxScanDays[`DIFFICULTYSETTING]);
	}
	else
	{
		SetScanHoursRemaining(MinDays, MaxDays);
	}
	
	// Then if the scan is not repeatable, pause it and reset entirely
	if (!bScanRepeatable)
	{
		bScanHasStarted = false;
		bScanPaused = false;
	}
	else // Otherwise, immediately start the scan again, which will now use the new ScanHoursRemaining
	{
		StartScan();
	}
}

//---------------------------------------------------------------------------------------
// Helper for Hack Rewards to modify remaining duration
function ModifyRemainingScanTime(float Modifier)
{
	ScanHoursRemaining = float(ScanHoursRemaining) * Modifier;
	PausedDaysRemaining = float(PausedDaysRemaining) * Modifier;
}

function bool IsScanComplete()
{
	if (bScanHasStarted && (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ScanEndDateTime, GetCurrentTime()) || ScanHoursRemaining <= 0))
	{
		return true;
	}
	
	return false;
}

function int GetNumScanDaysRemaining()
{	
	return FCeil(GetNumScanHoursRemaining() / 24.0f);
}

function int GetNumScanHoursRemaining()
{
	if (!bScanHasStarted || bScanPaused)
		return ScanHoursRemaining;
	else
		return class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(ScanEndDateTime, GetCurrentTime());
}

function ScanTimeETA(out int MinDays, out int MaxDays)
{
	MinDays = default.MinScanDays[`DIFFICULTYSETTING];
	MaxDays = default.MaxScanDays[`DIFFICULTYSETTING];
}

function string GetScanButtonLabel()
{
	return m_strScanButtonLabel;
}

function int GetScanPercentComplete()
{
	if( bScanHasStarted && TotalScanHours > 0)
	{
		return int(((TotalScanHours - GetNumScanHoursRemaining()) * 1.0f / TotalScanHours) * 100);
	}
	else 
	{
		return 0;
	}
}

simulated function string GetUIButtonIcon()
{
	return "";
}

simulated function string GetUIButtonTooltipTitle()
{
	return class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetDisplayName() $":" @ GetWorldRegion().GetDisplayName());
}

simulated function string GetUIButtonTooltipBody()
{
	local string TooltipStr, ScanTimeValue, ScanTimeLabel;
	local int DaysRemaining;
			
	DaysRemaining = GetNumScanDaysRemaining();
	ScanTimeValue = string(DaysRemaining);
	ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
	TooltipStr = ScanTimeValue @ ScanTimeLabel @ m_strRemainingLabel;
	
	return TooltipStr;
}

protected function string GetInterruptionPopupQueryText()
{
	return m_strScanInteruptionText;
}

private function CheckForEventOverlaps()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProject ProjectState;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local XComGameState_MissionCalendar CalendarState;
	local StateObjectReference ProjectRef;
	local bool bModified;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));

	foreach XComHQ.Projects(ProjectRef)
	{
		ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(ProjectRef.ObjectID));
		HealProject = XComGameState_HeadquartersProjectHealSoldier(ProjectState);

		// Heal projects can overlap since they don't give popups on the Geoscape
		if (HealProject == none)
		{
			if (ProjectState.CompletionDateTime == ScanEndDateTime)
			{
				// If the project's completion date and time is the same as the end of the scan, subtract an hour so the events don't stack
				// An hour is subtracted instead of added so the total "Days Remaining" does not change because of the offset.
				class'X2StrategyGameRulesetDataStructures'.static.AddHours(ScanEndDateTime, -1);
				bModified = true;
			}
		}
	}
	
	for (idx = 0; idx < CalendarState.CurrentMissionMonth.Length; idx++)
	{
		if (CalendarState.CurrentMissionMonth[idx].SpawnDate == ScanEndDateTime)
		{
			// If the mission's spawn date and time is the same as the end of the scan, subtract an hour so the events don't stack
			// An hour is subtracted instead of added so the total "Days Remaining" does not change because of the offset.
			class'X2StrategyGameRulesetDataStructures'.static.AddHours(ScanEndDateTime, -1);
			bModified = true;
		}
	}

	if (bModified)
	{
		CheckForEventOverlaps(); // Recursive to check if the new offset time overlaps with anything
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bCheckForOverlaps = true;
}