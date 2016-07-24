//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_StaffSlot.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_PsiLabSlot extends UIFacility_StaffSlot
	dependson(UIPersonnel);

var localized string m_strPsiTrainingDialogTitle;
var localized string m_strPsiTrainingDialogText;
var localized string m_strStopPsiTrainingDialogTitle;
var localized string m_strStopPsiTrainingDialogText;
var localized string m_strPauseAbilityTrainingDialogTitle;
var localized string m_strPauseAbilityTrainingDialogText;
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
	local string PopupText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlot.IsSlotEmpty())
	{
		StaffContainer.ShowDropDown(self);
	}
	else // Ask the user to confirm that they want to empty the slot and stop training
	{
		UnitState = StaffSlot.GetAssignedStaff();

		if (UnitState.GetStatus() == eStatus_PsiTesting)
		{
			PopupText = m_strStopPsiTrainingDialogText;
			PopupText = Repl(PopupText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));

			ConfirmEmptyProjectSlotPopup(m_strStopPsiTrainingDialogTitle, PopupText);
		}
		else if (UnitState.GetStatus() == eStatus_PsiTraining)
		{
			PopupText = m_strPauseAbilityTrainingDialogText;
			PopupText = Repl(PopupText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));

			ConfirmEmptyProjectSlotPopup(m_strPauseAbilityTrainingDialogTitle, PopupText, false);
		}
	}
}

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	
	if (Unit.GetSoldierClassTemplateName() == 'PsiOperative')
	{
		`HQPRES.UIChoosePsiAbility(UnitInfo.UnitRef, StaffSlotRef);
	}
	else
	{
		PsiPromoteDialog(Unit);
	}
}

simulated function PsiPromoteDialog(XComGameState_Unit Unit)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local UICallbackData_StateObjectReference CallbackData;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = PsiPromoteDialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strPsiTrainingDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strPsiTrainingDialogText);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function PsiPromoteDialogCallback(eUIAction eAction, UICallbackData xUserData)
{	
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_FacilityXCom FacilityState;
	local UICallbackData_StateObjectReference CallbackData;
	local StaffUnitInfo UnitInfo;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if(eAction == eUIAction_Accept)
	{		
		StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
		
		if (StaffSlot != none)
		{
			UnitInfo.UnitRef = CallbackData.ObjectRef;

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Psi Training Slot");
			StaffSlot.FillSlot(NewGameState, UnitInfo); // The Training project is started when the staff slot is filled
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
			
			XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
			FacilityState = StaffSlot.GetFacility();
			if (FacilityState.GetNumEmptyStaffSlots() > 0)
			{
				StaffSlot = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

				if ((StaffSlot.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
					(StaffSlot.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
				{
					`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlot.GetMyTemplate());
				}
			}
		}

		UpdateData();
	}
}

simulated function RefreshTooltip(UITooltip Tooltip)
{
	if (IsUnitAvailableForThisSlot())
		UITextTooltip(Tooltip).SetText(m_strSoldiersAvailableTooltip);
	else
		UITextTooltip(Tooltip).SetText(m_strNoSoldiersTooltip);
}

//==============================================================================

defaultproperties
{
	width = 370;
	height = 65;
}
