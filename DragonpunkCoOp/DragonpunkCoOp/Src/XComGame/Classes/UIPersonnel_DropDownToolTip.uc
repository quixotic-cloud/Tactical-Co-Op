//---------------------------------------------------------------------------------------
 //  FILE:    UIPersonnel_DropDownToolTip.uc
 //  AUTHOR:  Brian Whitman --  6/2015
 //  PURPOSE: Tooltip to preview the staffer's info
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UIPersonnel_DropDownToolTip extends UITooltip;

var StateObjectReference SlotRef;
var StaffUnitInfo UnitInfo;

simulated function UIPanel InitDropDownToolTip(optional name InitName, optional name InitLibID)
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
	local XComGameState_HeadquartersProject Project;
	local XComGameState TempState;
	local string StaffLocation, StatusString, TimeStr, BonusStr;
	local EStaffStatus Status;
	local bool bPreview;
	local int TimeValue, StatusState;

	History = `XCOMHISTORY;

	Status = class'X2StrategyGameRulesetDataStructures'.static.GetStafferStatus(UnitInfo, StaffLocation, TimeValue, StatusState);
	StatusString = class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Strategy'.default.m_strStaffStatus[Status], StatusState);
	TimeStr = class'UIUtilities_Text'.static.GetTimeRemainingString(TimeValue);
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));
	bPreview = SlotState.IsSlotEmpty(); // only show the preview stats if the slot is currently empty

	TempState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Temporarily assigning staffer to StaffSlot to preview bonus");
	SlotState.GetMyTemplate().FillFn(TempState, SlotRef, UnitInfo);
	SlotState = XComGameState_StaffSlot(TempState.GetGameStateForObjectID(SlotRef.ObjectID));
	BonusStr = Caps(SlotState.GetBonusDisplayString(bPreview));
	History.CleanupPendingGameState(TempState);
	
	// If the unit is available and the staff slot has an associated project, check to see if one exists for this unit
	if (Status == eStaffStatus_Available && SlotState.GetMyTemplate().AssociatedProjectClass != none)
	{		
		foreach History.IterateByClassType(class'XComGameState_HeadquartersProject', Project)
		{
			if (Project.Class == SlotState.GetMyTemplate().AssociatedProjectClass)
			{
				// An associated project was found, so display the estimated time to complete
				if (Project.ProjectFocus == UnitInfo.UnitRef ||
					(Project.AuxilaryReference.ObjectID != 0 && Project.AuxilaryReference == SlotState.Room))
				{
					TimeValue = Project.GetProjectedNumHoursRemaining();
					TimeStr = class'UIUtilities_Text'.static.GetTimeRemainingString(TimeValue);
					break;
				}
			}
		}
	}

	MC.BeginFunctionOp("update");
	MC.QueueString( StatusString );
	MC.QueueString( TimeValue > 0 ? TimeStr : "" );
	MC.QueueString( StaffLocation );
	MC.QueueString( BonusStr );
	MC.EndOp();

}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	LibID = "StaffToolTipMC";

	bUsePartialPath = true; 
	bFollowMouse = false;
	bRelativeLocation = true;
}