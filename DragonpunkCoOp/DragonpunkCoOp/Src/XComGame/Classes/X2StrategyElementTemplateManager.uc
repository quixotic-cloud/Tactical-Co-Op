//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElementTemplateManager.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElementTemplateManager extends X2DataTemplateManager
	native(Core);

struct MissionTextEntry
{
	var X2MissionFlavorTextTemplate TextTemplate;
	var int Score;
};

native static function X2StrategyElementTemplateManager GetStrategyElementTemplateManager();

function bool AddStrategyElementTemplate(X2StrategyElementTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2StrategyElementTemplate FindStrategyElementTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
	{
		return X2StrategyElementTemplate(kTemplate);
	}
	return none;
}

function array<X2AvengerAnimationTemplate> GetFacilityStaffAvengerAnimationTemplates(name FacilityName)
{
	local array<X2AvengerAnimationTemplate> arrAnimTemplates;
	local X2DataTemplate Template;
	local X2AvengerAnimationTemplate AnimTemplate;

	foreach IterateTemplates(Template, none)
	{
		AnimTemplate = X2AvengerAnimationTemplate(Template);

		if(AnimTemplate != none)
		{
			if(AnimTemplate.UsesStaffSlot && AnimTemplate.EligibleFacilities.Find(FacilityName) != INDEX_NONE)
			{
				arrAnimTemplates.AddItem(AnimTemplate);
			}
		}
	}

	return arrAnimTemplates;
}

private function int SortWeightedAvengerAnimationEntries(WeightedAvengerAnimationEntry Entry1, WeightedAvengerAnimationEntry Entry2)
{
	if(Entry1.Weight == Entry2.Weight)
	{
		return 0;
	}
	else
	{
		return Entry1.Weight > Entry2.Weight ? 1 : -1;
	}
}

function array<X2AvengerAnimationTemplate> GetRandomizedAnimationTemplates()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local array<WeightedAvengerAnimationEntry> RandomizedTemplates;
	local WeightedAvengerAnimationEntry Entry;
	local array<X2AvengerAnimationTemplate> Result;
	local array<X2StrategyElementTemplate> arrAllAnimTemplates;
	local X2StrategyElementTemplate TemplateIter;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	arrAllAnimTemplates = GetAllTemplatesOfClass(class'X2AvengerAnimationTemplate');

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach arrAllAnimTemplates(TemplateIter)
	{
		Entry.AnimTemplate = X2AvengerAnimationTemplate(TemplateIter);
		Entry.Weight = Entry.AnimTemplate.Weight;
		
		if(Entry.Weight > 0)
		{
			if(Entry.AnimTemplate.CanUseEmptyRoom && XComHQ.HasEmptyRoom())
			{
				Entry.Weight *= `SYNC_FRAND;
				RandomizedTemplates.AddItem(Entry);
			}
			else
			{
				for(idx = 0; idx < Entry.AnimTemplate.EligibleFacilities.Length; idx++)
				{
					if(XComHQ.HasFacilityByName(Entry.AnimTemplate.EligibleFacilities[idx]))
					{
						Entry.Weight *= `SYNC_FRAND;
						RandomizedTemplates.AddItem(Entry);
						break;
					}
				}
			}
		}
	}

	RandomizedTemplates.Sort(SortWeightedAvengerAnimationEntries);

	foreach RandomizedTemplates(Entry)
	{
		Result.AddItem(Entry.AnimTemplate);
	}

	return Result;
}

function array<X2StrategyElementTemplate> GetAllTemplatesOfClass(class<X2StrategyElementTemplate> TemplateClass, optional int UseTemplateGameArea=-1)
{
	local array<X2StrategyElementTemplate> arrTemplates;
	local X2DataTemplate Template;

	foreach IterateTemplates(Template, none)
	{
		if ((UseTemplateGameArea > -1) && !Template.IsTemplateAvailableToAllAreas(UseTemplateGameArea))
			continue;

		if (ClassIsChildOf(Template.Class, TemplateClass))
		{
			arrTemplates.AddItem(X2StrategyElementTemplate(Template));
		}
	}

	return arrTemplates;
}

function array<X2FacilityTemplate> GetBuildableFacilityTemplates()
{
	local array<X2FacilityTemplate> arrBuildTemplates;
	local array<X2StrategyElementTemplate> arrAllFacilities;
	local X2FacilityTemplate FacilityTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local int iFacility;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	arrAllFacilities = GetAllTemplatesOfClass(class'X2FacilityTemplate');

	for(iFacility = 0; iFacility < arrAllFacilities.Length; iFacility++)
	{
		FacilityTemplate = X2FacilityTemplate(arrAllFacilities[iFacility]);

		if(FacilityTemplate.bIsUniqueFacility && (XComHQ.HasFacility(FacilityTemplate) || XComHQ.IsBuildingFacility(FacilityTemplate)))
		{
			continue;
		}

		if(XComHQ.MeetsEnoughRequirementsToBeVisible(FacilityTemplate.Requirements))
		{
			arrBuildTemplates.AddItem(FacilityTemplate);
		}
	}

	return arrBuildTemplates;
}

function array<X2FacilityUpgradeTemplate> GetBuildableFacilityUpgradeTemplates()
{
	local array<X2FacilityUpgradeTemplate> arrFacilityUpgrades, arrUpgradeTemplates;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local XComGameStateHistory History;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		
	for (idx = 0; idx < XComHQ.Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(XComHQ.Facilities[idx].ObjectID));
		arrFacilityUpgrades = Facility.GetBuildableUpgrades();

		foreach arrFacilityUpgrades(UpgradeTemplate)
		{
			if (XComHQ.MeetsEnoughRequirementsToBeVisible(UpgradeTemplate.Requirements) && arrUpgradeTemplates.Find(UpgradeTemplate) == INDEX_NONE)
			{
				arrUpgradeTemplates.AddItem(UpgradeTemplate);
			}
		}
	}

	return arrUpgradeTemplates;
}

function int GetDistanceToTech(X2TechTemplate TechTemplate)
{
	local X2TechTemplate PrereqTechTemplate;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int Distance, idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Distance = 0;

	if(XComHQ.TechTemplateIsResearched(TechTemplate))
	{
		Distance = 0;
	}
	else if(TechTemplate.Requirements.RequiredTechs.Length == 0)
	{
		Distance = 1;
	}
	else
	{
		for(idx = 0; idx < TechTemplate.Requirements.RequiredTechs.Length; idx++)
		{
			PrereqTechTemplate = X2TechTemplate(FindStrategyElementTemplate(TechTemplate.Requirements.RequiredTechs[idx]));

			if(PrereqTechTemplate != none)
			{
				Distance += GetDistanceToTech(PrereqTechTemplate);
			}
		}
	}

	return Distance;
}

function X2MissionFlavorTextTemplate GetMissionFlavorText(XComGameState_MissionSite MissionState, optional bool bForceAllText=false, optional name ForceFlavorText)
{
	local X2StrategyElementTemplate Template;
	local array<X2StrategyElementTemplate> Templates;
	local X2MissionFlavorTextTemplate FlavorTextTemplate;
	local array<MissionTextEntry> ValidEntries;
	local MissionTextEntry NewEntry, EmptyEntry;
	local bool bSource, bReward, bObjective, bPlot, bBiome, bQuestItem;
	local int CurrentScore, MaxScore, idx;

	if(ForceFlavorText != '')
	{
		FlavorTextTemplate = X2MissionFlavorTextTemplate(FindStrategyElementTemplate(ForceFlavorText));

		if(FlavorTextTemplate != none)
		{
			return FlavorTextTemplate;
		}
	}

	Templates = GetAllTemplatesOfClass(class'X2MissionFlavorTextTemplate');
	MaxScore = 0;

	foreach Templates(Template)
	{
		FlavorTextTemplate = X2MissionFlavorTextTemplate(Template);

		if (FlavorTextTemplate != none)
		{
			if(FlavorTextTemplate.bSpecialCondition)
			{
				continue;
			}

			CurrentScore = 0;
			bSource = false;
			bReward = false;
			bObjective = false;
			bPlot = false;
			bBiome = false;
			bQuestItem = false;

			if(FlavorTextTemplate.MissionSources.Find(MissionState.GetMissionSource().DataName) != INDEX_NONE)
			{
				bSource = true;
				CurrentScore++;
			}
			else if(FlavorTextTemplate.MissionSources.Length == 0)
			{
				bSource = true;
			}

			if(FlavorTextTemplate.MissionRewards.Find(MissionState.GetRewardType().DataName) != INDEX_NONE)
			{
				bReward = true;
				CurrentScore++;
			}
			else if(FlavorTextTemplate.MissionRewards.Length == 0)
			{
				bReward = true;
			}
			
			if(FlavorTextTemplate.ObjectiveTypes.Find(MissionState.GeneratedMission.Mission.sType) != INDEX_NONE)
			{
				bObjective = true;
				CurrentScore++;
			}
			else if(FlavorTextTemplate.ObjectiveTypes.Length == 0)
			{
				bObjective = true;
			}

			if(FlavorTextTemplate.PlotTypes.Find(MissionState.GeneratedMission.Plot.strType) != INDEX_NONE)
			{
				bPlot = true;
				CurrentScore++;
			}
			else if(FlavorTextTemplate.PlotTypes.Length == 0)
			{
				bPlot = true;
			}

			if(FlavorTextTemplate.Biomes.Find(MissionState.GeneratedMission.Biome.strType) != INDEX_NONE)
			{
				bBiome = true;
				CurrentScore++;
			}
			else if(FlavorTextTemplate.Biomes.Length == 0)
			{
				bBiome = true;
			}

			if(FlavorTextTemplate.QuestItems.Find(MissionState.GeneratedMission.MissionQuestItemTemplate) != INDEX_NONE)
			{
				bQuestItem = true;
				CurrentScore++;
			}
			else if(FlavorTextTemplate.QuestItems.Length == 0)
			{
				bQuestItem = true;
			}

			if (bSource && bReward && bObjective && bPlot && bBiome && bQuestItem && (CurrentScore >= MaxScore || (bForceAllText && 
				FlavorTextTemplate.FlavorText.Length != 0 && FlavorTextTemplate.CouncilSpokesmanSuccessText.Length != 0 && 
				FlavorTextTemplate.CouncilSpokesmanFailureText.Length != 0)))
			{
				if(CurrentScore > MaxScore)
				{
					MaxScore = CurrentScore;
				}

				NewEntry = EmptyEntry;
				NewEntry.TextTemplate = FlavorTextTemplate;
				NewEntry.Score = CurrentScore;
				ValidEntries.AddItem(NewEntry);
			}
		}
	}

	if(!bForceAllText)
	{
		for(idx = 0; idx < ValidEntries.Length; idx++)
		{
			if(ValidEntries[idx].Score < MaxScore)
			{
				ValidEntries.Remove(idx, 1);
				idx--;
			}
		}
	}

	if (ValidEntries.Length > 0)
	{
		return ValidEntries[`SYNC_RAND(ValidEntries.Length)].TextTemplate;
	}

	return none;
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2StrategyElement';
}