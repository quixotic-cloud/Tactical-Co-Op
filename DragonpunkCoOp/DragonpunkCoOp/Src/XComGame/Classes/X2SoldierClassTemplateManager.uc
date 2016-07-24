//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2SoldierClassTemplateManager.uc
//  AUTHOR:  Timothy Talley  --  01/18/2014
//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2SoldierClassTemplateManager extends X2DataTemplateManager
	native(Core) config(ClassData);

var config name     DefaultSoldierClass;
var config int      NickNameRank;
var config array<SoldierClassAbilityType> ExtraCrossClassAbilities;
var config array<SoldierClassStatType> GlobalStatProgression;           //  used for every rank > 0

native static function X2SoldierClassTemplateManager GetSoldierClassTemplateManager();

function bool AddSoldierClassTemplate(X2SoldierClassTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2SoldierClassTemplate FindSoldierClassTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2SoldierClassTemplate(kTemplate);
	return none;
}

function array<X2SoldierClassTemplate> GetAllSoldierClassTemplates(optional bool bExcludeMultiplayer = true)
{
	local array<X2SoldierClassTemplate> arrClassTemplates;
	local X2DataTemplate Template;
	local X2SoldierClassTemplate ClassTemplate;

	foreach IterateTemplates(Template, none)
	{
		ClassTemplate = X2SoldierClassTemplate(Template);

		if(ClassTemplate != none)
		{
			if(!bExcludeMultiplayer || !ClassTemplate.bMultiplayerOnly)
			{
				arrClassTemplates.AddItem(ClassTemplate);
			}
		}
	}

	return arrClassTemplates;
}

function array<SoldierClassAbilityType> GetCrossClassAbilities(optional X2SoldierClassTemplate ExcludeClass)
{
	local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate AbilityTemplate;
	local array<X2SoldierClassTemplate> arrClassTemplates;
	local X2SoldierClassTemplate ClassTemplate;
	local array<SoldierClassAbilityType> CrossClassAbilities, AbilityTree;
	local int iRank, iBranch, idx;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	arrClassTemplates = GetAllSoldierClassTemplates();
	CrossClassAbilities.Length = 0;

	foreach arrClassTemplates(ClassTemplate)
	{
		if(ClassTemplate.DataName != DefaultSoldierClass && ClassTemplate != ExcludeClass && ClassTemplate.bAllowAWCAbilities)
		{
			for(iRank = 0; iRank < ClassTemplate.GetMaxConfiguredRank(); iRank++)
			{
				AbilityTree = ClassTemplate.GetAbilityTree(iRank);
				for(iBranch = 0; iBranch < AbilityTree.Length; iBranch++)
				{
					AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityTree[iBranch].AbilityName);

					if(AbilityTemplate != none && AbilityTemplate.bCrossClassEligible && CrossClassAbilities.Find('AbilityName', AbilityTree[iBranch].AbilityName) == INDEX_NONE)
					{
						CrossClassAbilities.AddItem(AbilityTree[iBranch]);
					}
				}
			}
		}
	}

	for(idx = 0; idx < default.ExtraCrossClassAbilities.Length; idx++)
	{
		AbilityTemplate = AbilityMgr.FindAbilityTemplate(default.ExtraCrossClassAbilities[idx].AbilityName);

		if(AbilityTemplate != none && AbilityTemplate.bCrossClassEligible && CrossClassAbilities.Find('AbilityName', default.ExtraCrossClassAbilities[idx].AbilityName) == INDEX_NONE)
		{
			CrossClassAbilities.AddItem(default.ExtraCrossClassAbilities[idx]);
		}
	}

	return CrossClassAbilities;
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2SoldierClass'
}