//---------------------------------------------------------------------------------------
//  FILE:    X2TechTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TechTemplate extends X2StrategyElementTemplate
	native(Core);

var config int			PointsToComplete;
var config int			TutorialPointsToComplete; // Some techs adjust time if in a tutorial playthrough (will be ignored if 0)
var config int			RepeatPointsIncrease; // For repeatable techs, added to total points each time tech is researched
var bool				bShadowProject;
var bool				bAutopsy;
var bool				bArmor; // Used by Suit Up continent bonus for instant armor / vest projects
var bool				bRandomWeapon; // Used by Fire When Ready continent bonus for instant ammo, grenades, heavy weapon projects
var bool				bProvingGround;
var bool				bCheckForceInstant; // If true, when a non-instant tech is completed, this tech will check its Instant Reqs and become instant if they are met
var bool				bRepeatable;
var bool				bJumpToLabs;  // On complete does this tech automatically jump to the labs
var string				strImage;
var array<Name>			ItemRewards;
var Name				RewardDeck; // Deck a random reward should be drawn from
var int					SortingTier; // The importance "tier" of this tech, used for sorting in lists

// Requirements and Cost
var config StrategyRequirement Requirements;
var config array<StrategyRequirement> AlternateRequirements; // Other possible StrategyRequirements for this tech
var config StrategyRequirement InstantRequirements; // If these requirements are met, the tech will become instant
var config StrategyCost	Cost;

// Sounds
var string				TechAvailableNarrative;
var string				TechStartedNarrative;

// Text
var localized string    DisplayName; // Actual Tech Name
var localized string    Summary; // Shows on Choose Research Screen
var localized string	CodeName; // Tech's codename (research complete screen)
var localized string	LongDescription; // Research complete screen in Tygan's voice
var localized string	UnlockedDescription; // The string which will appear on the research report for this tech indicating new availability
var localized string	AlertString; // If this tech needs a specialized string to appear in an alert, put it here

var delegate<OnResearchCompleted> ResearchCompletedFn;
var delegate<IsPriority> IsPriorityFn;

delegate OnResearchCompleted(XComGameState NewGameState, XComGameState_Tech TechState);
delegate bool IsPriority();

//---------------------------------------------------------------------------------------
function GetUnlocks(out array<StateObjectReference> NewResearch, out array<StateObjectReference> NewProvingGroundProjects, out array<X2ItemTemplate> NewItems, out array<X2FacilityTemplate> NewFacilities, out array<X2FacilityUpgradeTemplate> NewUpgrades, out array<StateObjectReference> NewInstantResearch)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local XComGameState_Item ItemState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local array<StateObjectReference> CompletedResearch, CompletedProvingGroundProjects;
	local X2ItemTemplate ItemTemplate;
	local X2FacilityTemplate FacilityTemplate;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local StrategyRequirement AltReq;
	local int idx, iUpgrades;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// Get all new research
	NewResearch = XComHQ.GetAvailableTechsForResearch();
	for(idx = 0; idx < NewResearch.Length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(NewResearch[idx].ObjectID));
		
		if (TechState.bForceInstant && !TechState.bSeenInstantPopup)
		{
			NewInstantResearch.AddItem(NewResearch[idx]);
		}

		if(TechState.GetMyTemplate().Requirements.RequiredTechs.Find(DataName) == INDEX_NONE)
		{
			if (TechState.GetMyTemplate().AlternateRequirements.Length > 0)
			{
				foreach TechState.GetMyTemplate().AlternateRequirements(AltReq)
				{
					if (AltReq.RequiredTechs.Find(DataName) == INDEX_NONE)
					{
						// If both the default and alternate requirements do not require this tech, remove it from the list
			NewResearch.Remove(idx, 1);
			idx--;
						break;
		}
	}
			}
			else // There are no alternate requirements, so remove the tech from the new research list
			{				
				NewResearch.Remove(idx, 1);
				idx--;
			}
		}
	}

	// Check all completed research for techs unlocked by this tech, used for Archive Reports
	CompletedResearch = XComHQ.GetCompletedResearchTechs();
	for (idx = 0; idx < CompletedResearch.Length; idx++)
	{
		if (NewResearch.Find('ObjectID', CompletedResearch[idx].ObjectID) == INDEX_NONE)
		{
			TechState = XComGameState_Tech(History.GetGameStateForObjectID(CompletedResearch[idx].ObjectID));

			if (TechState.GetMyTemplate().Requirements.RequiredTechs.Find(DataName) != INDEX_NONE)
			{
				NewResearch.AddItem(CompletedResearch[idx]);
			}
			else if (TechState.GetMyTemplate().AlternateRequirements.Length > 0)
			{
				foreach TechState.GetMyTemplate().AlternateRequirements(AltReq)
				{
					if (AltReq.RequiredTechs.Find(DataName) != INDEX_NONE)
					{
						NewResearch.AddItem(CompletedResearch[idx]);
						break;
					}
		}
	}
		}
	}

	// Get all new proving ground projects
	NewProvingGroundProjects = XComHQ.GetAvailableProvingGroundProjects();
	for (idx = 0; idx < NewProvingGroundProjects.Length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(NewProvingGroundProjects[idx].ObjectID));

		if (TechState.GetMyTemplate().Requirements.RequiredTechs.Find(DataName) == INDEX_NONE)
		{
			if (TechState.GetMyTemplate().AlternateRequirements.Length > 0)
			{
				foreach TechState.GetMyTemplate().AlternateRequirements(AltReq)
				{
					if (AltReq.RequiredTechs.Find(DataName) == INDEX_NONE)
					{
						// If both the default and alternate requirements do not require this tech, remove it from the list
						NewProvingGroundProjects.Remove(idx, 1);
						idx--;
						break;
					}
				}
			}
			else // There are no alternate requirements, so remove the tech from the new proving ground project list
			{
			NewProvingGroundProjects.Remove(idx, 1);
			idx--;
		}
	}
	}
	
	// Check all completed proving ground projects for projects unlocked by this tech, used for Archive Reports
	CompletedProvingGroundProjects = XComHQ.GetCompletedProvingGroundTechs();
	for (idx = 0; idx < CompletedProvingGroundProjects.Length; idx++)
	{
		if (NewProvingGroundProjects.Find('ObjectID', CompletedProvingGroundProjects[idx].ObjectID) == INDEX_NONE)
		{
			TechState = XComGameState_Tech(History.GetGameStateForObjectID(CompletedProvingGroundProjects[idx].ObjectID));

			if (TechState.GetMyTemplate().Requirements.RequiredTechs.Find(DataName) != INDEX_NONE)
			{
				NewProvingGroundProjects.AddItem(CompletedProvingGroundProjects[idx]);
			}
			else if (TechState.GetMyTemplate().AlternateRequirements.Length > 0)
			{
				foreach TechState.GetMyTemplate().AlternateRequirements(AltReq)
				{
					if (AltReq.RequiredTechs.Find(DataName) != INDEX_NONE)
					{
						NewProvingGroundProjects.AddItem(CompletedProvingGroundProjects[idx]);
						break;
		}
	}
			}
		}
	}

	// Get all new items
	NewItems = class'X2ItemTemplateManager'.static.GetItemTemplateManager().GetBuildableItemTemplates();
	for(idx = 0; idx < NewItems.Length; idx++)
	{
		if(NewItems[idx].Requirements.RequiredTechs.Find(DataName) == INDEX_NONE)
		{
			if (NewItems[idx].AlternateRequirements.Length > 0)
			{
				foreach NewItems[idx].AlternateRequirements(AltReq)
				{
					if (AltReq.RequiredTechs.Find(DataName) == INDEX_NONE)
					{
						// If both the default and alternate requirements do not require this tech, remove it from the list
			NewItems.Remove(idx, 1);
			idx--;
						break;
					}
				}
			}
			else // There are no alternate requirements, so remove the tech from the new item list
			{
				NewItems.Remove(idx, 1);
				idx--;
		}
	}
	}

	// Check current inventory items for items unlocked by this tech, used for Archive Reports
	for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
	{		
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
		ItemTemplate = ItemState.GetMyTemplate();

		if (NewItems.Find(ItemTemplate) == INDEX_NONE)
		{			
			if (ItemTemplate.Requirements.RequiredTechs.Find(DataName) != INDEX_NONE)
			{
				NewItems.AddItem(ItemTemplate);
			}
			else if (ItemTemplate.AlternateRequirements.Length > 0)
			{
				foreach ItemTemplate.AlternateRequirements(AltReq)
				{
					if (AltReq.RequiredTechs.Find(DataName) != INDEX_NONE)
					{
						NewItems.AddItem(ItemTemplate);
						break;
					}
				}
			}
		}
	}

	// Get all new facilities
	NewFacilities = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetBuildableFacilityTemplates();
	for(idx = 0; idx < NewFacilities.Length; idx++)
	{
		if(NewFacilities[idx].Requirements.RequiredTechs.Find(DataName) == INDEX_NONE)
		{
			NewFacilities.Remove(idx, 1);
			idx--;
		}
	}

	// Get all new facility upgrades
	NewUpgrades = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetBuildableFacilityUpgradeTemplates();
	for (idx = 0; idx < NewUpgrades.Length; idx++)
	{
		if (NewUpgrades[idx].Requirements.RequiredTechs.Find(DataName) == INDEX_NONE)
		{
			NewUpgrades.Remove(idx, 1);
			idx--;
		}
	}

	// Check current facilities and their upgrades for any unlocked by this tech, used for Archive Reports
	for (idx = 0; idx < XComHQ.Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(XComHQ.Facilities[idx].ObjectID));
		FacilityTemplate = FacilityState.GetMyTemplate();

		if (NewFacilities.Find(FacilityTemplate) == INDEX_NONE)
		{
			if (FacilityTemplate.Requirements.RequiredTechs.Find(DataName) != INDEX_NONE)
			{
				NewFacilities.AddItem(FacilityTemplate);
			}

			for (iUpgrades = 0; iUpgrades < FacilityState.Upgrades.Length; iUpgrades++)
			{
				UpgradeState = XComGameState_FacilityUpgrade(History.GetGameStateForObjectID(FacilityState.Upgrades[iUpgrades].ObjectID));
				UpgradeTemplate = UpgradeState.GetMyTemplate();

				if (NewUpgrades.Find(UpgradeTemplate) == INDEX_NONE)
				{
					if (UpgradeTemplate.Requirements.RequiredTechs.Find(DataName) != INDEX_NONE)
					{
						NewUpgrades.AddItem(UpgradeTemplate);
					}
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bShouldCreateDifficultyVariants=true
}
