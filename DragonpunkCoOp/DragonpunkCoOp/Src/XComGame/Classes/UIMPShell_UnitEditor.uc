//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_UnitEditor.uc
//  AUTHOR:  Todd Smith  --  6/30/2015
//  PURPOSE: This file is used for the following stuff..blah
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_UnitEditor extends UIArmory_MainMenu;

var localized string m_strChooseAbilitiesButtonText;
var localized string m_strEditLoadoutButtonText;
var localized string m_strCustomizeCharacterButtonText;
var localized string m_strTotalUnitCostHeaderText;

var UIMPShell_SquadCostPanel MySquadCostPanel;

var XComGameState m_kEditSquad;
var XComGameState_Unit m_kEditUnit;

var X2MPShellManager m_kMPShellManager;

simulated function InitUnitEditorScreen(X2MPShellManager ShellManager, XComGameState_Unit EditUnit)
{
	m_kEditUnit = EditUnit;
	CheckGameState = m_kEditSquad;
	m_kMPShellManager = ShellManager;

	InitArmory(m_kEditUnit.GetReference());

	MySquadCostPanel = Spawn(class'UIMPShell_SquadCostPanel', self);
	MySquadCostPanel.InitSquadCostPanel(25000, m_kEditSquad, "");
	MySquadCostPanel.Show();

	CacheOriginalData(m_kEditUnit);
}

simulated function PopulateData()
{
	List.ClearItems();

	// Customize soldier:
	Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strCustomizeSoldier);

	// -------------------------------------------------------------------------------
	// Loadout:
	Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strLoadout);

	class'UIUtilities_Strategy'.static.PopulateAbilitySummary(self, m_kEditUnit);

	List.Navigator.SelectFirstAvailable();
}


simulated function OnAccept()
{
	if( UIListItemString(List.GetSelectedItem()).bDisabled )
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		return;
	}

	// Index order matches order that elements get added in 'PopulateData'
	switch( List.selectedIndex )
	{
	case 0: // CUSTOMIZE	
		PC.Pres.UICustomize_Menu( m_kEditUnit, ActorPawn);
		break;
	case 1: // LOADOUT
		UIArmory_Loadout_MP(`SCREENSTACK.Push(Spawn(class'UIArmory_Loadout_MP', self), Movie.Pres.Get3DMovie())).InitArmory_MP(m_kMPShellManager, m_kEditSquad, m_kEditUnit.GetReference(), , , , , , true);
		break;
	}
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

function CacheOriginalData(XComGameState_Unit kUnit)
{
}

simulated function OnReceiveFocus()
{
	PC.Pres.InitializeCustomizeManager(m_kEditUnit);
	super.OnReceiveFocus();
}

simulated function OnCancel()
{
	super.OnCancel();
	PC.Pres.GetUIPawnMgr().ReleasePawn(PC.Pres, m_kEditUnit.GetReference().ObjectID, false);
}

function SaveAsLoadoutButtonCallback(UIButton kButton)
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
}

simulated function UpdateNavHelp()
{
	if(bUseNavHelp)
	{
		NavHelp.ClearButtonHelp();
		NavHelp.AddBackButton(OnCancel);
	}
}

DefaultProperties
{
}