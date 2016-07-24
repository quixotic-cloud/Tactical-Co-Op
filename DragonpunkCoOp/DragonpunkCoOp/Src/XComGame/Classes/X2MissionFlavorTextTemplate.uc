//---------------------------------------------------------------------------------------
//  FILE:    X2MissionFlavorTextTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2MissionFlavorTextTemplate extends X2StrategyElementTemplate
	config(GameBoard);

var localized array<string>	FlavorText;
var localized array<string> CouncilSpokesmanSuccessText;
var localized array<string> CouncilSpokesmanPartialSuccessText;
var localized array<string> CouncilSpokesmanFailureText;

var config array<name>		MissionSources;  // X2StrategyElement_DefaultMissionSources.uc
var config array<name>		MissionRewards;  // DefaultMissions.ini (look for your mission source)
var config array<string>	ObjectiveTypes;  // DefaultMissions.ini
var config array<string>	PlotTypes;       // DefaultParcels.ini
var config array<string>	Biomes;			 // DefaultGameData.ini  m_arrBiomeMappings
var config array<name>		QuestItems;		 // X2Item_DefaultQuestItems.uc
var config bool				bSpecialCondition; // This flavor text triggers due to a special condition, don't consider otherwise