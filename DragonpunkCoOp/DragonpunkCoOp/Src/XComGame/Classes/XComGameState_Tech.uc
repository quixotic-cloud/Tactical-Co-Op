//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Tech.uc
//  AUTHOR:  Mark Nauta
//         
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Tech extends XComGameState_BaseObject native(Core)
	dependson(X2StrategyGameRulesetDataStructures);

var() protected name                   m_TemplateName;
var() protected X2TechTemplate         m_Template;

var() bool							   bBlocked; // Some techs are gated by finishing TentPole missions etc.
var() bool							   bForceInstant; // This tech is forced to be instant, used for instant autopsies
var() bool							   bSeenInstantPopup; // Determines if we need to see a popup alerting the player that this tech is now instant
var() bool							   bSeenResearchCompleteScreen; // Determines if we need to see this tech's research complete screen on return to labs
var StateObjectReference			   RegionRef; // Some techs (like facility leads) need a region reference
var int								   IntelReward; // Intel techs need to store the intel they are awarding for display purposes
var X2ItemTemplate					   ItemReward; // Proving ground project techs may need to store a random item template they are awarding to the player
var array<X2ItemTemplate>			   ItemsUpgraded; // Proving ground project techs may upgrade items
var int								   TimesResearched; // Some repeatable techs increase in time to research the more you research them
var float							   TimeReductionScalar; // Techs can be rushed, value is fraction of total points it is reduced by
var int								   SavedDiscountPercent; // Saved discount percent from when the tech was activated. Used for giving correct refunds if cancelled.
var StateObjectReference			   UnitRewardRef; // If this tech rewards a unit, store it here

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

//---------------------------------------------------------------------------------------
simulated function X2TechTemplate GetMyTemplate()
{
	if (m_Template == none)
	{
		m_Template = X2TechTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
function OnCreation(X2TechTemplate Template)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
}

//---------------------------------------------------------------------------------------
static function SetUpTechs(XComGameState StartState)
{
	local array<X2StrategyElementTemplate> arrTechTemplates;
	local XComGameState_Tech TechStateObject;
	local X2TechTemplate TechTemplate;
	local int idx;

	// Grab all Tech Templates
	arrTechTemplates = GetMyTemplateManager().GetAllTemplatesOfClass(class'X2TechTemplate');

	// Iterate through the templates and build each Tech State Object
	for(idx = 0; idx < arrTechTemplates.Length; idx++)
	{
		TechTemplate = X2TechTemplate(arrTechTemplates[idx]);
		
		if (TechTemplate.RewardDeck != '')
		{
			SetUpTechRewardDeck(TechTemplate);
		}

		TechStateObject = XComGameState_Tech(StartState.CreateStateObject(class'XComGameState_Tech'));
		TechStateObject.OnCreation(X2TechTemplate(arrTechTemplates[idx]));
		StartState.AddStateObject(TechStateObject);
	}
}

//---------------------------------------------------------------------------------------
static function SetUpTechRewardDeck(X2TechTemplate TechTemplate)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2CardManager CardManager;
	local X2DataTemplate DataTemplate;
	local X2ItemTemplate ItemTemplate;

	CardManager = class'X2CardManager'.static.GetCardManager();
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemTemplateManager.IterateTemplates(DataTemplate, None)
	{
		ItemTemplate = X2ItemTemplate(DataTemplate);

		if (ItemTemplate != none && ItemTemplate.RewardDecks.Find(TechTemplate.RewardDeck) != INDEX_NONE)
		{
			CardManager.AddCardToDeck(TechTemplate.RewardDeck, string(ItemTemplate.DataName));
		}
	}
}

//---------------------------------------------------------------------------------------
function int GetProjectPoints()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings SettingsState;
	local int InitialProjectPoints;

	History = `XCOMHISTORY;
	SettingsState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	if(SettingsState.bTutorialEnabled && GetMyTemplate().TutorialPointsToComplete > 0)
	{
		InitialProjectPoints = GetMyTemplate().TutorialPointsToComplete;
	}
	else
	{
		InitialProjectPoints = GetMyTemplate().PointsToComplete;
	}

	InitialProjectPoints += (TimesResearched * GetMyTemplate().RepeatPointsIncrease);
	InitialProjectPoints = Round(float(InitialProjectPoints) * class'X2StrategyGameRulesetDataStructures'.default.ResearchProject_TimeScalar[`DIFFICULTYSETTING]);
	InitialProjectPoints -= Round(float(InitialProjectPoints) * TimeReductionScalar);

	return InitialProjectPoints;
}

//---------------------------------------------------------------------------------------
function bool IsInstant()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2TechTemplate TechTemplate;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	TechTemplate = GetMyTemplate();

	if (bForceInstant)
	{
		return true;
	}
	else if (TechTemplate.bAutopsy)
	{
		return XComHQ.bInstantAutopsies;
	}
	else if (TechTemplate.bArmor)
	{
		return XComHQ.bInstantArmors;
	}
	else if (TechTemplate.bRandomWeapon)
	{
		return XComHQ.bInstantRandomWeapons;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool IsPriority()
{
	if(GetMyTemplate().IsPriorityFn != none)
	{
		return GetMyTemplate().IsPriorityFn();
	}

	return false;
}

//---------------------------------------------------------------------------------------
function string GetDisplayName()
{
	return GetMyTemplate().DisplayName;
}

//---------------------------------------------------------------------------------------
function string GetSummary()
{
	return GetMyTemplate().Summary;
}

//---------------------------------------------------------------------------------------
function string GetCodeName()
{
	return GetMyTemplate().CodeName;
}

//---------------------------------------------------------------------------------------
function string GetLongDescription()
{
	return GetMyTemplate().LongDescription;
}

//---------------------------------------------------------------------------------------
function string GetImage()
{
	return GetMyTemplate().strImage;
}

//---------------------------------------------------------------------------------------
function OnResearchCompleted(XComGameState NewGameState)
{
	if(GetMyTemplate().ResearchCompletedFn != none)
	{
		GetMyTemplate().ResearchCompletedFn(NewGameState, self);
	}
}

//---------------------------------------------------------------------------------------
function bool CanBeRushed()
{
	return (TimeReductionScalar < 0.001f && !IsInstant() && !IsPriority() && !GetMyTemplate().bRepeatable);
}

//---------------------------------------------------------------------------------------
// stack when research report is needed (due to completed tech):
// UIProvingGroundProjectAvailable (for each new project)
// UIItemReceived (for each item given to the user)
// UIItemUpgraded (for each item automatically upgraded to an improved version)
// UIItemAvailable (for each unlocked item)
// UIUpgradeAvailable (for each unlocked facility upgrade)
// UIFacilityAvailable (for each unlocked facility)
// UIChooseResearch/Project
// UIFacility_Powercore/ProvingGround
function DisplayTechCompletePopups()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> NewResearch;
	local array<StateObjectReference> NewInstantResearch;
	local array<StateObjectReference> NewProjects;
	local array<X2ItemTemplate> NewItems;
	local array<X2FacilityTemplate> NewFacilities;
	local array<X2FacilityUpgradeTemplate> NewUpgrades;
	local int iItem, iProject, iUpgrade, iFacility, iResearch;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the research report as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tech research report popups seen");
	TechState = XComGameState_Tech(NewGameState.CreateStateObject(class'XComGameState_Tech', ObjectID));
	NewGameState.AddStateObject(TechState);
	TechState.bSeenResearchCompleteScreen = true;
	`XEVENTMGR.TriggerEvent('OnResearchReport', TechState, TechState, NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	if (XComHQ.IsObjectiveCompleted('T0_M6_WelcomeToLabsPt2'))
	{
		GetMyTemplate().GetUnlocks(NewResearch, NewProjects, NewItems, NewFacilities, NewUpgrades, NewInstantResearch);

		if (NewInstantResearch.Length > 0)
		{
			for (iResearch = 0; iResearch < NewInstantResearch.Length; iResearch++)
			{
				`HQPRES.UIInstantResearchAvailable(NewInstantResearch[iResearch]);
			}
		}

		if (XComHQ.bModularWeapons && !XComHQ.bHasSeenWeaponUpgradesPopup)
		{
			`HQPRES.UIWeaponUpgradesAvailable();
		}

		if (NewProjects.Length > 0 && TechState.TimesResearched == 1) // If this is a repeatable project, only show new projects available once
		{
			for (iProject = 0; iProject < NewProjects.Length; iProject++)
			{
				`HQPRES.UIProvingGroundProjectAvailable(NewProjects[iProject]);
			}
		}

		if (ItemsUpgraded.Length > 0)
		{
			for (iItem = 0; iItem < ItemsUpgraded.Length; iItem++)
			{
				`HQPRES.UIItemUpgraded(ItemsUpgraded[iItem]);
			}
		}

		if (NewItems.Length > 0)
		{
			for (iItem = 0; iItem < NewItems.Length; iItem++)
			{
				// If the item was already displayed as an upgrade or item reward, don't show it again
				if (ItemsUpgraded.Find(NewItems[iItem]) == INDEX_NONE && NewItems[iItem] != ItemReward)
				{
					`HQPRES.UIItemAvailable(NewItems[iItem]);
				}
			}
		}

		if (NewUpgrades.Length > 0)
		{
			for (iUpgrade = 0; iUpgrade < NewUpgrades.Length; iUpgrade++)
			{
				`HQPRES.UIUpgradeAvailable(NewUpgrades[iUpgrade]);
			}
		}

		if (NewFacilities.Length > 0)
		{
			for (iFacility = 0; iFacility < NewFacilities.Length; iFacility++)
			{
				`HQPRES.UIFacilityAvailable(NewFacilities[iFacility]);
			}
		}
		
		// If this tech rewards a unit, display a popup to alert the player
		if (TechState.UnitRewardRef.ObjectID != 0)
		{
			`HQPRES.UINewStaffAvailable(TechState.UnitRewardRef);
		}
	}
}

DefaultProperties
{    
}