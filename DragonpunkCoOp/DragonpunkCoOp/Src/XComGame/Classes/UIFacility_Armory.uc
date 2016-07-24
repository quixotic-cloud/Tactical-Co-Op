//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIFacility_Armory
//  AUTHOR:  Sam Batista
//  PURPOSE: Armory Facility Screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIFacility_Armory extends UIFacility config(GameData);

var public localized string m_strPersonnel;
var public localized string m_strRecruit;
var public localized string m_strUpgradeWeapons;
var public localized string m_strRequireModularWeapon;
var public localized string m_strConfirmRecruit;
var public localized string m_strPromoteJaneTitle;
var public localized string m_strPromoteJaneBody;
var public localized string m_strPromoteJaneAccept;
var public localized string m_strPromoteJaneCancel;

var StateObjectReference RecruitReference;
var StateObjectReference JaneReference; // tutorial unit

var config name VisitArmoryObjective; // tutorial objective
var config string TutorialSoldierFullName;

//----------------------------------------------------------------------------
// MEMBERS
// ------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	`XCOMGRI.DoRemoteEvent('CIN_HideArmoryStaff'); //Hide the staff in the armory so that they don't overlap with the soldiers
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Movie.Pres.Get3DMovie().HideAllDisplays();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Movie.Pres.Get3DMovie().HideAllDisplays();
}

simulated function OpenCharacterPool()
{
	`HQPRES.UICharacterPool();
}

simulated function Personnel()
{
	`HQPRES.UIPersonnel(eUIPersonnel_Soldiers, OnPersonnelSelected);
	class'UIUtilities'.static.DisplayUI3D(class'UIArmory_MainMenu'.default.DisplayTag, name(class'UIArmory_MainMenu'.default.CameraTag), `HQINTERPTIME);
}

simulated function OnPersonnelSelected(StateObjectReference selectedUnitRef)
{
	`HQPRES.UIArmory_MainMenu(selectedUnitRef);
}

// @TODO sbatista - make this better pls
//------------------------------------------------------------------------------------
simulated public function Recruit()
{
	local UIRecruitSoldiers kScreen;
	kScreen = spawn( class'UIRecruitSoldiers', `HQPRES ); 
	`HQPRES.ScreenStack.Push( kScreen );	
}

simulated function OnCancel()
{
	if(NeedsPromoteJanePopup())
	{
		PromoteJanePopup();
	}
	else
	{
		LeaveArmory();
	}
}

simulated function LeaveArmory()
{
	super.OnCancel();

	`XCOMGRI.DoRemoteEvent('CIN_UnhideArmoryStaff'); //Show the armory staff now that we are done
}

// Tutorial Popup
simulated function bool NeedsPromoteJanePopup()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.GetObjectiveStatus(VisitArmoryObjective) == eObjectiveState_InProgress)
	{
		Soldiers = XComHQ.GetSoldiers();

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = Soldiers[idx];

			if(UnitState != none && UnitState.GetFullName() == TutorialSoldierFullName && (UnitState.CanRankUpSoldier() || UnitState.HasAvailablePerksToAssign()))
			{
				JaneReference = UnitState.GetReference();
				return true;
			}
		}
	}

	return false;
}

simulated function PromoteJanePopup()
{
	local TDialogueBoxData kData;

	kData.strTitle = m_strPromoteJaneTitle;
	kData.strText = m_strPromoteJaneBody;
	kData.strAccept = m_strPromoteJaneAccept;
	kData.strCancel = m_strPromoteJaneCancel;
	kData.eType = eDialog_Warning;
	kData.fnCallback = PromoteJanePopupCallback;

	Movie.Pres.UIRaiseDialog(kData);
}

simulated function PromoteJanePopupCallback(eUIAction eAction)
{
	if(eAction == eUIAction_Accept)
		OnPersonnelSelected(JaneReference);
	else
		LeaveArmory(); // If Cancel, allow you to leave this screen. 
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Evaluate;
	CameraTag = "UIDisplayCam_Armory";
}
