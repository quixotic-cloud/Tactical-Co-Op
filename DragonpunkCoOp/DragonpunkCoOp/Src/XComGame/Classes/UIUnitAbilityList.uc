//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUnitAbilityList.uc
//  AUTHOR:  Todd Smith  --  7/13/2015
//  PURPOSE: UIPanel that lists a unit's abilities. Used in the armory/squad editors
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUnitAbilityList extends UIPanel
	dependson(UIUtilities_UnitData);

const TEXT_POS_X = 20;

var UIBGBox BG;
var UIText TEMP_PanelText;
var XComGameState_Unit m_kUnit;
var array<UISummary_EarnedAbility> m_arrAbilities;

simulated function UIPanel InitAbilityListPanel(XComGameState_Unit InitUnit, optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	BG = Spawn(class'UIBGBox', self).InitBG('', 0, 0, width, height);
	BG.SetOutline(true);

	TEMP_PanelText = Spawn(class'UIText', self).InitText(, class'UIUtilities_Strategy'.default.m_strAbilityListTitle);
	TEMP_PanelText.SetPosition(TEXT_POS_X, 50);

	SetUnit(InitUnit);

	return self;
}

function SetUnit(XComGameState_Unit kUnit)
{
	m_kUnit = kUnit;
	UpdateData();
}

function UpdateData()
{
	local string strUIText;
	local UISummary_EarnedAbility kUISummary;

	class'UIUtilities_UnitData'.static.GetAbilitySummaries(m_kUnit, m_arrAbilities);

	strUIText = class'UIUtilities_Strategy'.default.m_strAbilityListTitle $ "\n\n";
	foreach m_arrAbilities(kUISummary)
	{
		if(kUISummary.bEarned)
		{
			strUIText $= kUISummary.kSummary.Name $ "\n" $ kUISummary.kSummary.Description $ "\n\n";
		}
	}
	TEMP_PanelText.SetText(strUIText);
}

defaultproperties
{
	width=600
	height=500
}