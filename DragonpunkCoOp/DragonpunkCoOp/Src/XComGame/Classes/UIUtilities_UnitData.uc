//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities_UnitData.uc
//  AUTHOR:  Todd Smith  --  7/15/2015
//  PURPOSE: contains helper functions and common data associated with units used by the ui
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities_UnitData extends Object;

struct UISummary_EarnedAbility
{
	var UISummary_Ability   kSummary;
	var name                nAbilityTypeName;
	var bool                bEarned;

	structdefaultproperties
	{
		bEarned = false;
	}
};

static function GetAbilitySummaries(XComGameState_Unit kUnit, out array<UISummary_EarnedAbility> arrAbilities)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2SoldierClassTemplate kSoldierClassTemplate;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplate kAbilityTemplate;
	local SCATProgression Progression;
	local UISummary_EarnedAbility kUISummary;
	local int iSoldierRank;
	local int i,j;

	kSoldierClassTemplate = kUnit.GetSoldierClassTemplate();
	iSoldierRank = kUnit.GetSoldierRank();
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	
	arrAbilities.Length = 0;
	for (i = 0; i <= iSoldierRank; ++i)
	{
		AbilityTree = kSoldierClassTemplate.GetAbilityTree(i);
		for (j = 0; j < AbilityTree.Length; ++j)
		{
			if (AbilityTree[j].AbilityName != '')
			{
				kAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[j].AbilityName);
				kUISummary.kSummary = kAbilityTemplate.GetUISummary_Ability(kUnit);
				kUISummary.nAbilityTypeName = AbilityTree[j].AbilityName;
				kUISummary.bEarned = false;
				
				foreach kUnit.m_SoldierProgressionAbilties(Progression)
				{
					if (Progression.iRank == i && Progression.iBranch == j)
					{
						kUISummary.bEarned = true;
						break;
					}
				}
				arrAbilities.AddItem(kUISummary);
			}
		}
	}
}

static function string GetStringFormatPoints(int points)
{
	return "[" $ points $ "pts. ]";
}