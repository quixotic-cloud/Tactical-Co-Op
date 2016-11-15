//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_AdvancedWarfareCenterSlot.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_AdvancedWarfareCenterSlot extends UIFacility_StaffSlot
	dependson(UIPersonnel);

var localized string m_strRespecSoldierDialogTitle;
var localized string m_strRespecSoldierDialogText;
var localized string m_strStopRespecSoldierDialogTitle;
var localized string m_strStopRespecSoldierDialogText;
var localized string m_strNoSoldiersTooltip;
var localized string m_strSoldiersAvailableTooltip;

simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	local int TooltipID;

	super.InitStaffSlot(OwningContainer, LocationRef, SlotIndex, onStaffUpdatedDel);

	TooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(m_strNoSoldiersTooltip, 0, 0, string(MCPath), , , , true);
	Movie.Pres.m_kTooltipMgr.TextTooltip.SetMouseDelegates(TooltipID, RefreshTooltip);

	return self;
}

//-----------------------------------------------------------------------------
simulated function ShowDropDown()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local string StopTrainingText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlot.IsSlotEmpty())
	{
		StaffContainer.ShowDropDown(self);
	}
	else // Ask the user to confirm that they want to empty the slot and stop training
	{
		UnitState = StaffSlot.GetAssignedStaff();

		StopTrainingText = m_strStopRespecSoldierDialogText;
		StopTrainingText = Repl(StopTrainingText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));

		ConfirmEmptyProjectSlotPopup(m_strStopRespecSoldierDialogTitle, StopTrainingText);
	}
}

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_Unit Unit;
	local UICallbackData_StateObjectReference CallbackData;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = RespecSoldierDialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strRespecSoldierDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strRespecSoldierDialogText);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function RespecSoldierDialogCallback(eUIAction eAction, UICallbackData xUserData)
{
	local XComGameState NewGameState;
	local XComGameState_StaffSlot StaffSlot;
	local UICallbackData_StateObjectReference CallbackData;
	local StaffUnitInfo UnitInfo;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if (eAction == eUIAction_Accept)
	{
		StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

		if (StaffSlot != none)
		{
			UnitInfo.UnitRef = CallbackData.ObjectRef;

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Retrain Soldier Slot");
			StaffSlot.FillSlot(NewGameState, UnitInfo); // The Training project is started when the staff slot is filled
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
		}
		
		UpdateData();
	}
}

simulated function UpdateData()
{
	super.UpdateData();
	SetDisabled(!IsUnitAvailableForThisSlot());
}

simulated function RefreshTooltip(UITooltip Tooltip)
{
	if (IsUnitAvailableForThisSlot())
		UITextTooltip(Tooltip).SetText(m_strSoldiersAvailableTooltip);
	else
		UITextTooltip(Tooltip).SetText(m_strNoSoldiersTooltip);
}

simulated function bool IsUnitAvailableForThisSlot()
{
	local int i;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot SlotState;
	local StaffUnitInfo UnitInfo;
	local XComGameState_HeadquartersXCom HQState;

	History = `XCOMHISTORY;
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (SlotState.IsSlotFilled())
	{
		return true;
	}

	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();
	for (i = 0; i < HQState.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(HQState.Crew[i].ObjectID));
		UnitInfo.UnitRef = Unit.GetReference();

		if (SlotState.ValidUnitForSlot(UnitInfo))
		{
			return true;
		}
	}
	return false;
}

//==============================================================================

defaultproperties
{
	width = 370;
	height = 65;
}
