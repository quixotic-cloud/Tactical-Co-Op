//---------------------------------------------------------------------------------------
 //  FILE:    UIPersonnel_DropDownToolTip.uc
 //  AUTHOR:  Brian Whitman --  6/2015
 //  PURPOSE: Tooltip to preview the staffer's info
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UIStaffIcon_Tooltip extends UITooltip;

var StateObjectReference SlotRef;
var StaffUnitInfo UnitInfo;

simulated function UIPanel UIStaffIcon_Tooltip(optional name InitName, optional name InitLibID)
{
	InitTooltip(InitName, InitLibID);

	Hide();
	
	return self; 
}

simulated function ShowTooltip()
{
	AS_UpdateTargetPath();
	super.ShowTooltip(); //Show called before data refresh, because later items may hide this tooltip when doing data checks. 
	AS_RefreshData();
}



simulated function AS_UpdateTargetPath()
{
	MC.FunctionString("setTargetPath", targetPath);
}

simulated function AS_RefreshData()
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit UnitState;
	local XComGameState TempState;
	local string StaffLocation, TimeStr, BonusStr, UnitTypeImage, DisplayName;
	local EStaffStatus Status;
	local EUIPersonnelType UnitPersonnelType;
	local int TimeValue, StatusState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));

	Status = class'X2StrategyGameRulesetDataStructures'.static.GetStafferStatus(UnitInfo, StaffLocation, TimeValue, StatusState);
	TimeStr = class'UIUtilities_Text'.static.GetTimeRemainingString(TimeValue);

	if (SlotState != None)
	{
		TempState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Temporarily assigning staffer to StaffSlot to preview bonus");
		SlotState.GetMyTemplate().FillFn(TempState, SlotRef, UnitInfo);
		SlotState = XComGameState_StaffSlot(TempState.GetGameStateForObjectID(SlotRef.ObjectID));
		BonusStr = SlotState.GetBonusDisplayString(SlotState.IsSlotEmpty());
		DisplayName = SlotState.GetNameDisplayString();		
		History.CleanupPendingGameState(TempState);
	}
	else
	{
		if (UnitInfo.bGhostUnit) // If the unit is an available ghost, get the display name for the template which created it
			DisplayName = UnitState.GetStaffSlot().GetMyTemplate().GhostName;
		else
			DisplayName = UnitState.GetName(eNameType_Full);
	}

	if( UnitState.IsSoldier() )
	{
		UnitPersonnelType = eUIPersonnel_Soldiers;
		UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Staff;
	}
	else if( UnitState.IsAnEngineer() )
	{
		UnitPersonnelType = eUIPersonnel_Engineers;
		UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Engineer;
	}
	else if( UnitState.IsAScientist() )
	{
		UnitPersonnelType = eUIPersonnel_Scientists;
		UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Science;
	}
	else
	{
		UnitPersonnelType = -1;
		UnitTypeImage = "";
	}
	
	MC.BeginFunctionOp("update");
	MC.QueueString(DisplayName);
	MC.QueueString(string(UnitState.GetSkillLevel()));
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Strategy'.default.m_strStaffStatus[Status], StatusState));
	MC.QueueString(TimeValue > 0 ? TimeStr : "");
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(StaffLocation, eUIState_Normal));
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(BonusStr, eUIState_Highlight));
	MC.QueueNumber(UnitPersonnelType);
	MC.QueueString(UnitTypeImage);
	MC.EndOp();

}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	LibID = "StaffIconToolTipMC";

	bUsePartialPath = true; 
	bFollowMouse = false;
	bRelativeLocation = true;
}