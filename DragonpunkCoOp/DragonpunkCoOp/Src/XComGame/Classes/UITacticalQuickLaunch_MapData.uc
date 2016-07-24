//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalQuickLaunch_MapData.uc
//  AUTHOR:  
//  PURPOSE: 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalQuickLaunch_MapData extends UIScreen
	dependson(XcomEnvLightingManager)
	config(TQL);

var XComOnlineProfileSettings m_kProfileSettings;
var private array<PlotDefinition> m_arrUIMaps;

var UIPanel		m_kMapContainer;
var UIBGBox		m_kMapBG;
var UIText		m_kMapTitle;
var UIList		m_kMapList;

var UIPanel		m_kButtonContainer;
var UIButton	m_kAcceptButton;

var UIDropdown	m_kPlotType;
var UIDropdown  m_kBiomeType;
var UIDropdown	m_kMissionType;
var UIDropdown	m_kQuestItemType;
var UIDropdown	m_kLayerType;
var UIDropdown	m_kAlertLevel;
var UIDropdown  m_kForceLevel;
var UIDropdown  m_kEnvLighting;
var UIDropdown	m_kCivilians;

var UIDropdown	m_kSquad;
var UIDropdown	m_kDifficulty;

var UIDropdown	m_kPrecipitation;

struct ConfigurableSoldier
{
	var name SoldierID;

	var int MinForceLevel;
	var int MaxForceLevel;

	var name CharacterTemplate;
	var name SoldierClassTemplate;
	var int  SoldierRank;
	var name PrimaryWeaponTemplate;
	var name SecondaryWeaponTemplate;
	var name HeavyWeaponTemplate;
	var name ArmorTemplate;
	var name UtilityItem1Template;
	var name UtilityItem2Template;
	var array<Name> EarnedClassAbilities;

	var int  CharacterPoolSelection;
};

// The list of soldiers who can be slotted into a squad
var config array<ConfigurableSoldier> Soldiers;

struct ConfigurableSquad
{
	var Name SquadID;
	var array<Name> SoldierIDs;
};

// The list of pre-configured squads that can be selected
var config array<ConfigurableSquad> Squads;


var bool        bSetPlotDataOnAccept;
var int         SelectedMapIndex;
var int			SelectedForceLevel;

//Data that we set will go into this object
var XComGameStateHistory        History;
var XComGameState_BattleData    BattleDataState;
var XComGameState_CampaignSettings    CampaignState;
var XComGameState				ExistingStartState;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_kProfileSettings = `XPROFILESETTINGS;

	//=======================================================================================	
	//Cache the history objects

	History = `XCOMHISTORY;	
	
	ExistingStartState = Movie.Pres.TacticalStartState;

	//Store off the battle data object in the start state. It will be filled out with the results of the generation process
	foreach History.IterateByClassType(class'XComGameState_BattleData', BattleDataState)
	{
		break;
	}

	CampaignState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if( CampaignState == None )
	{
		CampaignState = XComGameState_CampaignSettings(ExistingStartState.CreateStateObject(class'XComGameState_CampaignSettings'));
		ExistingStartState.AddStateObject(CampaignState);
	}
	
	//=======================================================================================

	//Engine.GameViewport.GetViewportSize(ViewportSize);

	//=======================================================================================
	// X-Com 2 UI - new dynamic UI system
	//
	// Spawn UI Controls
	m_kButtonContainer  = Spawn(class'UIPanel', self);
	m_kAcceptButton     = Spawn(class'UIButton', m_kButtonContainer);

	m_kMapContainer     = Spawn(class'UIPanel', self);
	m_kMapBG            = Spawn(class'UIBGBox', m_kMapContainer);
	m_kMapTitle         = Spawn(class'UIText', m_kMapContainer);
	m_kMapList          = Spawn(class'UIList', m_kMapContainer);

	// Init UI Controls - NOTE: Order matters - it dictates basic navigation order
	m_kButtonContainer.InitPanel('buttonContainer');
	
	m_kAcceptButton.InitButton('acceptButton', "ACCEPT", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kAcceptButton.SetX(150); // position to the right of m_kCancelButton
	
	m_kMapContainer.InitPanel('mapContainer');
	m_kMapContainer.SetPosition(35, 40);

	m_kMapBG.InitBG('mapBG', -10, -10, 650, 675);
	m_kMapTitle.InitText('mapTitle', "MAP LIST", true);
	m_kMapList.InitList('mapList',0,50,600,600); // position list underneath m_kMapTitle
	m_kMapList.OnItemClicked = OnMapItemClicked;

	// Notify list of BG mouse events (so mousewheel scrolling works even if user is not highlighting a list item)
	m_kMapBG.ProcessMouseEvents(m_kMapList.OnChildMouseEvent);
	m_kMapBG.bHighlightOnMouseEvent = false;

	// position button underneath map list	
	m_kButtonContainer.SetPosition(-350, -50);
	m_kButtonContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT);

	// build the dropdowns
	m_kPrecipitation = Spawn(class'UIDropdown', self);
	m_kPrecipitation.InitDropdown('m_kPrecipitation', "Precipitate If Possible");
	m_kPrecipitation.SetPosition(700, 840);
	PopulatePrecipitationDropdownData();

	m_kDifficulty = Spawn(class'UIDropdown', self);
	m_kDifficulty.InitDropdown('m_kDifficulty', "Difficulty");
	m_kDifficulty.SetPosition(700, 770);
	PopulateDifficultyDropdownData();

	m_kSquad = Spawn(class'UIDropdown', self);
	m_kSquad.InitDropdown('m_kSquad', "Squad");
	m_kSquad.SetPosition(700, 700);
	PopulateSquadDropdownData();

	m_kCivilians = Spawn(class'UIDropdown', self);
	m_kCivilians.InitDropdown('m_kCivilians', "Civilians", SelectCivilians);
	m_kCivilians.SetPosition(700, 630);
	PopulateCivilianChoicesDropdownData();

	m_kEnvLighting = Spawn(class'UIDropdown', self);
	m_kEnvLighting.InitDropdown('m_kEnvLighting', "Environment Lighting", SelectEnvLighting);
	m_kEnvLighting.SetPosition(700, 560);
	PopulateEnvLightingDropdownData();

	m_kAlertLevel = Spawn(class'UIDropdown', self);
	m_kAlertLevel.InitDropdown('m_kAlertLevel', "Alert Level");
	m_kAlertLevel.SetPosition(700, 490);
	PopulateAlertLevelDropdownData();

	m_kForceLevel = Spawn(class'UIDropdown', self);
	m_kForceLevel.InitDropdown('m_kForceLevel', "Force Level", SelectForceLevel);
	m_kForceLevel.SetPosition(700, 420);
	PopulateForceLevelDropdownData();

	m_kLayerType = Spawn(class'UIDropdown', self);
	m_kLayerType.InitDropdown('m_kLayerType', "Layer Type");
	m_kLayerType.SetPosition(700, 350);
	PopulateLayerTypeDropdownData();

	m_kQuestItemType = Spawn(class'UIDropdown', self);
	m_kQuestItemType.InitDropdown('m_kQuestItemType', "Quest Item");
	m_kQuestItemType.SetPosition(700, 280);
	PopulateQuestItemTypeDropdownData();

	m_kMissionType = Spawn(class'UIDropdown', self);
	m_kMissionType.InitDropdown('m_kMissionType', "Mission Type", SetMissionType);
	m_kMissionType.SetPosition(700, 210);
	PopulateMissionTypeDropdownData();

	m_kBiomeType = Spawn(class'UIDropdown', self);
	m_kBiomeType.InitDropdown('m_kBiomeType', "Biome Type", SelectBiomeType);
	m_kBiomeType.SetPosition(700, 140);
	PopulateBiomeTypeDropdownData();

	m_kPlotType = Spawn(class'UIDropdown', self);
	m_kPlotType.InitDropdown('m_kPlotType', "Plot Type", SelectPlotType);
	m_kPlotType.SetPosition(700, 70);
	PopulatePlotTypeDropdownData();

	// Populate map list
	PopulateMapData();
}

function OnMapItemClicked(UIList listControl, int itemIndex)
{
	if(SelectedMapIndex != INDEX_NONE)
		UIListItemString(m_kMapList.GetItem(SelectedMapIndex)).SetText(m_arrUIMaps[SelectedMapIndex].MapName);

	SelectedMapIndex = itemIndex;
	UIListItemString(m_kMapList.GetItem(SelectedMapIndex)).SetText(FormatSelectedMapName(m_arrUIMaps[SelectedMapIndex].MapName));

	m_kPlotType.SetSelected(1); // Specific map
	BattleDataState.PlotSelectionType = ePlotSelection_Specify;
	BattleDataState.MapData.PlotMapName = m_arrUIMaps[SelectedMapIndex].MapName;
	BattleDataState.MapData.Biome = m_kBiomeType.selectedItem > 0 ? m_kBiomeType.GetSelectedItemText() : "";
	PopulateEnvLightingDropdownData();
	PopulateMissionTypeDropdownData();
}

simulated function bool ValidateValidMapForMissionType()
{
	local MissionDefinition Mission;
	local array<PlotDefinition> PossiblePlotDefinitions;
	local XComParcelManager ParcelManager;

	// if we are selecting a random mission, then just return true.
	if(BattleDataState.m_iMissionType < 0)
	{
		return true;
	}
	
	ParcelManager = `PARCELMGR;
	if(BattleDataState.PlotSelectionType == ePlotSelection_Random)
	{
		return true; // could be any plot, assume at least one of them works
	}
	else if(BattleDataState.PlotSelectionType == ePlotSelection_Type)
	{
		// get all plots for the desired type
		ParcelManager.GetPlotDefinitionsForPlotType(BattleDataState.PlotType, BattleDataState.MapData.Biome, PossiblePlotDefinitions);
	}
	else
	{
		// get our exact plot map
		PossiblePlotDefinitions.AddItem(ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName, BattleDataState.MapData.Biome));
	}

	// see if any of our possible maps will support the desired mission
	Mission = `TACTICALMISSIONMGR.arrMissions[BattleDataState.m_iMissionType];
	ParcelManager.RemovePlotDefinitionsThatAreInvalidForMission(PossiblePlotDefinitions, Mission);

	return PossiblePlotDefinitions.Length > 0;
}

simulated function OnButtonClicked(UIButton button)
{	
	local TDialogueBoxData kDialogData;

	if(button == m_kAcceptButton) // onAccept
	{
		SaveChanges();

		if(!ValidateValidMapForMissionType())
		{
			kDialogData.eType = eDialog_Normal;
			kDialogData.strText = "The selected mission type is not supported by the selected plot or plot type.";
			kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
			`PRES.UIRaiseDialog( kDialogData );

			return;
		}

		Movie.Stack.Pop(self);
	}
}

simulated private function SaveChanges()
{
	local XComGameState NewStartState;
	local XComTacticalMissionManager MissionManager;
	local int MissionIndex;

	CampaignState.SetDifficulty(m_kDifficulty.SelectedItem);

	// plot type and biome
	SelectPlotType(m_kPlotType);
	SelectBiomeType(m_kBiomeType);

	BattleDataState.bRainIfPossible = m_kPrecipitation.SelectedItem == 1;

	// save everything else
	if(m_kMissionType.GetSelectedItemData() == "Random")
	{
		// if random, just pick any mission
		BattleDataState.m_iMissionType = -1;
	}
	else
	{
		MissionManager = `TACTICALMISSIONMGR;
		for(MissionIndex = 0; MissionIndex < MissionManager.arrMissions.Length; MissionIndex++)
		{
			if(MissionManager.arrMissions[MissionIndex].sType == m_kMissionType.GetSelectedItemData())
			{
				BattleDataState.m_iMissionType = MissionIndex; // exact selection
				break;
			}
		}
	}

	BattleDataState.m_nQuestItem = name(m_kQuestItemType.GetSelectedItemData());
	BattleDataState.m_iLayer = m_kLayerType.selectedItem - 1;
	BattleDataState.SetAlertLevel(Clamp(
		int(m_kAlertLevel.GetSelectedItemText()), 
		class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty, 
		class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty));
	BattleDataState.SetForceLevel(SelectedForceLevel);

	// save environment map
	if(m_kEnvLighting.GetSelectedItemText() != "Random")
	{
		`ENVLIGHTINGMGR.SetCurrentMap(BattleDataState, m_kEnvLighting.GetSelectedItemText());
	}
	else
	{
		`ENVLIGHTINGMGR.SetCurrentMap(BattleDataState, "");
	}

	// update squad
	SelectSquad(m_kSquad.SelectedItem);


	// create a new game state
	NewStartState = `XCOMHISTORY.CreateNewGameState(false, ExistingStartState.GetContext());
	ExistingStartState.CopyGameState(NewStartState);

	//Add the start state to the history
	`XCOMHISTORY.AddGameStateToHistory(NewStartState);

	Movie.Pres.TacticalStartState = NewStartState;

	//Write GameState to profile
	`XPROFILESETTINGS.WriteTacticalGameStartState(ExistingStartState);

	`ONLINEEVENTMGR.SaveProfileSettings();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnButtonClicked(m_kAcceptButton);
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

simulated function PopulateMapData()
{
	local int i;
	local string MapName;
	local PlotDefinition PlotDef;
	local X2CardManager CardManager;
	
	m_arrUIMaps.Length = 0; 

	// build out a list of maps from the parcel manager data
	foreach class'XComParcelManager'.default.arrPlots(PlotDef)
	{	
		if(BattleDataState.PlotSelectionType == ePlotSelection_Type && PlotDef.strType != BattleDataState.PlotType)
		{
			continue;
		}

		if(BattleDataState.MapData.Biome != "" && PlotDef.ValidBiomes.Find(BattleDataState.MapData.Biome) == INDEX_NONE)
		{
			continue;
		}

		m_arrUIMaps.AddItem(PlotDef);
	}

	// and fill out the ui list object
	CardManager = class'X2CardManager'.static.GetCardManager();

	m_kMapList.ClearItems();
	for(i = 0; i < m_arrUIMaps.Length; ++i)
	{
		PlotDef = m_arrUIMaps[i];

		// make sure the plots are in the card manager. Prevents an errant redscreen when directly selecting a plot
		CardManager.AddCardToDeck('PlotTypes', PlotDef.strType);
		CardManager.AddCardToDeck('Plots', PlotDef.MapName);

		if(BattleDataState.MapData.PlotMapName == PlotDef.MapName)
		{
			SelectedMapIndex = i;
			MapName = FormatSelectedMapName(PlotDef.MapName);
		}
		else
			MapName = PlotDef.MapName;

		Spawn(class'UIListItemString', m_kMapList.itemContainer).InitListItem(MapName);
	}
}

simulated function PopulateBiomeTypeDropdownData()
{
	local PlotDefinition kPlotDef;
	local string strBiomeType;
	local array<string> arrUniqueTypes;

	m_kBiomeType.Clear();
	m_kBiomeType.AddItem("Unspecified");
	m_kBiomeType.SetSelected(0);

	foreach class'XComParcelManager'.default.arrPlots(kPlotDef)
	{
		foreach kPlotDef.ValidBiomes(strBiomeType)
		{
			if(arrUniqueTypes.Find(strBiomeType) == INDEX_NONE)
			{
				arrUniqueTypes.AddItem(strBiomeType);
			}
		}
	}

	foreach arrUniqueTypes(strBiomeType)
	{
		m_kBiomeType.AddItem(strBiomeType);

		if(strBiomeType == BattleDataState.MapData.Biome)
		{
			m_kBiomeType.SetSelected(m_kBiomeType.items.Length - 1);
		}
	}
}

simulated function PopulatePlotTypeDropdownData()
{
	local PlotTypeDefinition kPlotTypeDef;
	local string strPlotType;
	local array<string> arrUniqueTypes;

	m_kPlotType.Clear();

	m_kPlotType.AddItem("Random");
	m_kPlotType.AddItem("Use List Choice");
	if(BattleDataState.PlotSelectionType == ePlotSelection_Specify)
	{
		m_kPlotType.SetSelected(m_kPlotType.items.Length - 1);
	}

	foreach class'XComParcelManager'.default.arrPlotTypes(kPlotTypeDef)
	{
		if(arrUniqueTypes.Find(kPlotTypeDef.strType) == INDEX_NONE)
		{
			arrUniqueTypes.AddItem(kPlotTypeDef.strType);
		}
	}

	foreach arrUniqueTypes(strPlotType)
	{
		m_kPlotType.AddItem(strPlotType);

		if(BattleDataState.PlotSelectionType == ePlotSelection_Type && strPlotType == BattleDataState.PlotType)
		{
			m_kPlotType.SetSelected(m_kPlotType.items.Length - 1);
		}
	}
}

simulated function PopulateMissionTypeDropdownData()
{
	local XComTacticalMissionManager MissionManager;
	local XComParcelManager ParcelManager;
	local array<MissionDefinition> ValidMissionTypes;
	local array<PlotDefinition> PlotsForPlotType;
	local PlotDefinition PlotDef;
	local MissionDefinition MissionDef;
	local string PreviousMissionType;
	local int MissionIndex;

	MissionManager = `TACTICALMISSIONMGR;
	ParcelManager = `PARCELMGR;

	// save the previously selected mission type so we can reselect it if it is still a valid option
	PreviousMissionType = m_kMissionType.GetSelectedItemData();
	if(PreviousMissionType == "" 
		&& BattleDataState.m_iMissionType >= 0 
		&& BattleDataState.m_iMissionType < MissionManager.arrMissions.Length)
	{
		// this is the first time we have accessed this menu. Grab the saved mission option from the battle data
		PreviousMissionType = MissionManager.arrMissions[BattleDataState.m_iMissionType].sType;
	}

	m_kMissionType.Clear();

	// build a list of all missions that are supported by the selected plot or plot type

	switch(BattleDataState.PlotSelectionType)
	{
	case ePlotSelection_Random:
		// any mission is fine
		ValidMissionTypes = MissionManager.arrMissions;
		break;

	case ePlotSelection_Type:
		// add missions types that are supported by any of the plots in this plot type
		ParcelManager.GetPlotDefinitionsForPlotType(BattleDataState.PlotType, "", PlotsForPlotType);

		foreach PlotsForPlotType(PlotDef)
		{
			foreach MissionManager.arrMissions(MissionDef)
			{
				if(ValidMissionTypes.Find('sType', MissionDef.sType) == INDEX_NONE && ParcelManager.IsPlotValidForMission(PlotDef, MissionDef))
				{
					ValidMissionTypes.AddItem(MissionDef);
				}
			}
		}
		break;

	case ePlotSelection_Specify:
		PlotDef = ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName, "");

		// only add missions that are supported by the specified plot type
		foreach MissionManager.arrMissions(MissionDef)
		{
			if(ParcelManager.IsPlotValidForMission(PlotDef, MissionDef))
			{
				ValidMissionTypes.AddItem(MissionDef);
			}
		}
		break;

	default:
		`assert(false); // somebody has probably extended the selection enum and needs to update this block!
	}

	// add a "random" option
	m_kMissionType.AddItem("Random", "Random");
	m_kMissionType.SetSelected(0);

	// add all of the missions
	for(MissionIndex = 0; MissionIndex < ValidMissionTypes.Length; MissionIndex++)
	{
		MissionDef = ValidMissionTypes[MissionIndex];

		m_kMissionType.AddItem(class'X2MissionTemplateManager'.static.GetMissionTemplateManager().GetMissionDisplayName(MissionDef.MissionName), MissionDef.sType);

		// try to select the previously selected mission
		if(PreviousMissionType == MissionDef.sType)
		{
			m_kMissionType.SetSelected(MissionIndex + 1); // +1 because 0 is the random option
		}
	}

	SetMissionType(m_kMissionType);
}

simulated function PopulateQuestItemTypeDropdownData()
{
	local X2DataTemplate DataTemplate;
	local X2QuestItemTemplate QuestItemTemplate;
	local string DisplayString;

	m_kQuestItemType.Clear();

	foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(DataTemplate, none)
	{
		QuestItemTemplate = X2QuestItemTemplate(DataTemplate);
		if(QuestItemTemplate != none)
		{
			DisplayString = QuestItemTemplate.GetItemFriendlyName();
			m_kQuestItemType.AddItem(DisplayString, string(QuestItemTemplate.DataName));

			if(QuestItemTemplate.DataName == BattleDataState.m_nQuestItem)
			{
				m_kQuestItemType.SetSelected(m_kQuestItemType.Data.Length - 1);
			}
		}
	}
}

simulated function PopulateLayerTypeDropdownData()
{
	local ParcelDefinition kParcelDef;
	local string strLayerName;
	local array<string> arrLayerNames;

	// in lieu of hardcoding a list of available layers, we scan the parcel definitions
	// and find all layer names in them. This is very mod friendly and allows the lds to add new layer
	// types without having to modify the maplist logic at all
	foreach class'XComParcelManager'.default.arrAllParcelDefinitions(kParcelDef)
	{
		foreach kParcelDef.arrAvailableLayers(strLayerName)
		{
			if(arrLayerNames.Find(strLayerName) < 0)
			{
				arrLayerNames.AddItem(strLayerName);
			}
		}
	}

	m_kLayerType.Clear();
	m_kLayerType.AddItem("None");
	foreach arrLayerNames(strLayerName)
	{
		m_kLayerType.AddItem(strLayerName);
	}

	m_kLayerType.SetSelected(BattleDataState.m_iLayer + 1);
}

simulated function PopulateEnvLightingDropdownData()
{
	local XComEnvLightingManager LightingManager;
	local array<EnvironmentLightingDefinition> EnvLightingDefs;
	local string CurrentMapName;
	local int i;
	local string strMissionType;

	LightingManager = `ENVLIGHTINGMGR;

	strMissionType = `TACTICALMISSIONMGR.arrMissions[BattleDataState.m_iMissionType].sType;
	EnvLightingDefs = class'XComEnvLightingManager'.static.GetMatchingEnvLightingDefs(BattleDataState.PlotType, 
																					   BattleDataState.MapData.PlotMapName,
																					   BattleDataState.MapData.Biome,
																					   strMissionType);

	CurrentMapName = LightingManager.GetCurrentMapName();
	
	m_kEnvLighting.Clear();

	m_kEnvLighting.AddItem( "Random" );
	m_kEnvLighting.SetSelected(0);

	for( i = 0; i < EnvLightingDefs.Length; i++ )
	{
		m_kEnvLighting.AddItem( EnvLightingDefs[i].MapName );
		if( EnvLightingDefs[i].MapName == CurrentMapName )
		{
			m_kEnvLighting.SetSelected(i + 1);
		}
	}

	if(m_kEnvLighting.GetSelectedItemText() == "Random")
	{
		LightingManager.SetCurrentMap(BattleDataState, "");
	}
}

simulated function PopulateCivilianChoicesDropdownData()
{
	m_kCivilians.Clear();

	m_kCivilians.AddItem( "Pro-Advent" );
	m_kCivilians.AddItem( "Pro-XCom" );

	m_kCivilians.SetSelected( BattleDataState.GetPopularSupport( ) ); // default to Pro-Advent
}

simulated function PopulatePrecipitationDropdownData()
{
	m_kPrecipitation.Clear();

	m_kPrecipitation.AddItem("Off");
	m_kPrecipitation.AddItem("On");

	m_kPrecipitation.SetSelected(0);
}

simulated function PopulateDifficultyDropdownData()
{
	local int Index;

	m_kDifficulty.Clear();

	for( Index = 0; Index <= 3; ++Index )
	{
		m_kDifficulty.AddItem(class'UIShellDifficulty'.default.m_arrDifficultyTypeStrings[Index]);
	}

	m_kDifficulty.SetSelected(CampaignState.DifficultySetting);
}

simulated function PopulateAlertLevelDropdownData()
{
	local int Index;

	m_kAlertLevel.Clear();

	for( Index = class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty; Index <= class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty; ++Index )
	{
		m_kAlertLevel.AddItem(string(Index));
	}

	m_kAlertLevel.SetSelected(BattleDataState.GetAlertLevel() - class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty);
}

simulated function PopulateForceLevelDropdownData()
{
	local int iLevel;

	for (iLevel=1; iLevel <= `GAMECORE.MAX_FORCE_LEVEL_UI_VAL; ++iLevel)
	{
		m_kForceLevel.AddItem(string(iLevel));
	}

	SelectedForceLevel = Clamp(BattleDataState.GetForceLevel(), 1, `GAMECORE.MAX_FORCE_LEVEL_UI_VAL);
	m_kForceLevel.SetSelected(SelectedForceLevel - 1);
}

simulated function SelectForceLevel(UIDropdown dropdown)
{
	SelectedForceLevel = dropdown.selectedItem + 1;
}

simulated function SelectPlotType(UIDropdown dropdown)
{
	local XComParcelManager ParcelManager;
	local PlotDefinition PlotDef;
	local bool FoundBiomeType;
	local int itemIndex;
	itemIndex = dropdown.selectedItem;
	
	if( itemIndex == 0 )
	{
		BattleDataState.PlotSelectionType = ePlotSelection_Random;
	}
	else if( itemIndex == 1 )
	{
		BattleDataState.PlotSelectionType = ePlotSelection_Specify;		
		BattleDataState.MapData.PlotMapName = m_arrUIMaps[SelectedMapIndex].MapName;

		// clear the biome type if the currently selected plot doesn't support it
		ParcelManager = `PARCELMGR;
		PlotDef = ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName, BattleDataState.MapData.Biome);
		if(PlotDef.MapName == "") // invalid parcel
		{
			BattleDataState.MapData.Biome = "";
		}
	}
	else
	{
		BattleDataState.PlotSelectionType = ePlotSelection_Type;
		BattleDataState.PlotType = dropdown.GetSelectedItemText();	

		// clear the biome type if none of the plots in this plot type support it
		ParcelManager = `PARCELMGR;
		FoundBiomeType = false;
		foreach ParcelManager.arrPlots(PlotDef)
		{
			if(PlotDef.strType == BattleDataState.PlotType && PlotDef.ValidBiomes.Find(BattleDataState.MapData.Biome) != INDEX_NONE)
			{
				FoundBiomeType = true;
				break;
			}
		}

		if(!FoundBiomeType)
		{
			BattleDataState.MapData.Biome = "";
		}
	}

	// filter the mission list based on the selected map
	PopulateMissionTypeDropdownData();
	PopulateMapData();
	PopulateBiomeTypeDropdownData();
	PopulateEnvLightingDropdownData();
}

simulated function SetMissionType(UIDropdown dropdown)
{
	local XComTacticalMissionManager MissionManager;
	local int MissionIndex;

	// save everything else
	if (dropdown.GetSelectedItemData() == "Random")
	{
		// if random, just pick any mission
		BattleDataState.m_iMissionType = -1;
	}
	else
	{
		MissionManager = `TACTICALMISSIONMGR;
		for (MissionIndex = 0; MissionIndex < MissionManager.arrMissions.Length; MissionIndex++)
		{
			if (MissionManager.arrMissions[MissionIndex].sType == dropdown.GetSelectedItemData())
			{
				BattleDataState.m_iMissionType = MissionIndex; // exact selection
				break;
			}
		}
	}

	PopulateEnvLightingDropdownData();
}

simulated function SelectBiomeType(UIDropdown dropdown)
{
	local int itemIndex;
	itemIndex = dropdown.selectedItem;
	
	if( itemIndex == 0 )
	{
		BattleDataState.Mapdata.Biome = "";
	}
	else
	{
		BattleDataState.Mapdata.Biome = dropdown.GetSelectedItemText();
	}

	PopulateMapData();
	PopulateEnvLightingDropdownData();
}

simulated function SelectEnvLighting(UIDropdown dropdown)
{
	if (dropdown.GetSelectedItemText() != "Random")
	{
		`ENVLIGHTINGMGR.SetCurrentMap(BattleDataState, dropdown.GetSelectedItemText());
	}
	else
	{
		`ENVLIGHTINGMGR.SetCurrentMap(BattleDataState, "");
	}
}

simulated function SelectCivilians(UIDropdown dropdown)
{
	BattleDataState.SetPopularSupport(dropdown.selectedItem);
	BattleDataState.SetMaxPopularSupport(dropdown.Items.Length - 1);
}

simulated function PopulateSquadDropdownData()
{
	local int Index;

	m_kSquad.Clear();

	m_kSquad.AddItem("Previous - Squad Select UI");
	m_kSquad.AddItem("Random - 4 Soldiers");
	m_kSquad.AddItem("Random - 5 Soldiers");
	m_kSquad.AddItem("Random - 6 Soldiers");

	for( Index = 0; Index < Squads.Length; ++Index )
	{
		m_kSquad.AddItem(string(Squads[Index].SquadID));
	}

	m_kSquad.SetSelected(0); // default to Previous
}

simulated function SelectSquad(int SelectionIndex)
{
	local array<Name> SelectedSquadMembers;

	if( SelectionIndex == 0 )
	{
		// do nothing, use the previously selected squad
		return;
	}
	else if( SelectionIndex == 1 )
	{
		// choose 4 random squad members for current force level
		SelectNSquadMembers(4, SelectedSquadMembers);
	}
	else if( SelectionIndex == 2 )
	{
		// choose 5 random squad members for current force level
		SelectNSquadMembers(5, SelectedSquadMembers);
	}
	else if( SelectionIndex == 3 )
	{
		// choose 6 random squad members for current force level
		SelectNSquadMembers(6, SelectedSquadMembers);
	}
	else
	{
		// select the squad at index SelectionIndex-4 from the Squads array
		SelectedSquadMembers = Squads[SelectionIndex - 4].SoldierIDs;
	}

	ApplySquad(SelectedSquadMembers);
}

function SelectNSquadMembers(int N, out array<Name> SquadMembers)
{
	local int Index;
	local array<Name> PossibleSquadMembers;

	for( Index = 0; Index < Soldiers.Length; ++Index )
	{
		if( Soldiers[Index].MinForceLevel <= SelectedForceLevel &&
			Soldiers[Index].MaxForceLevel >= SelectedForceLevel )
		{
			PossibleSquadMembers.AddItem(Soldiers[Index].SoldierID);
		}
	}


	for( Index = 0; Index < N; ++Index )
	{
		SquadMembers.AddItem(PossibleSquadMembers[`SYNC_RAND(PossibleSquadMembers.Length)]);
	}
}

function ApplySquad(const out array<Name> SelectedSquadMembers)
{
	local int SquadIndex, SoldierIndex;
	local XComGameState_Player TeamXComPlayer;

	PurgeGameState(ExistingStartState);

	//Find the player associated with the player's team
	foreach ExistingStartState.IterateByClassType(class'XComGameState_Player', TeamXComPlayer)
	{
		if( TeamXComPlayer != None && TeamXComPlayer.TeamFlag == eTeam_XCom )
		{
			break;
		}
	}

	for( SquadIndex = 0; SquadIndex < SelectedSquadMembers.Length; ++SquadIndex )
	{
		for( SoldierIndex = 0; SoldierIndex < Soldiers.Length; ++SoldierIndex )
		{
			if( Soldiers[SoldierIndex].SoldierID == SelectedSquadMembers[SquadIndex] )
			{
				// Add this soldier's config as a new squad unit to the start state
				AddSoldierToGameState(SoldierIndex, ExistingStartState, TeamXComPlayer);
				break;
			}
		}
	}
}

function AddSoldierToGameState(int SoldierIndex, XComGameState NewGameState, XComGameState_Player ControllingPlayer)
{
	local XComGameState_Unit Unit;
	local X2CharacterTemplate CharacterTemplate;

	CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(Soldiers[SoldierIndex].CharacterTemplate);
	if( CharacterTemplate == none )
	{
		`warn("CreateTemplatesFromCharacter: '" $ Soldiers[SoldierIndex].CharacterTemplate $ "' is not a valid template.");
		return;
	}

	Unit = CharacterTemplate.CreateInstanceFromTemplate(NewGameState);
	if( ControllingPlayer != none )
	{
		Unit.SetControllingPlayer(ControllingPlayer.GetReference());
	}

	// Add Unit
	NewGameState.AddStateObject(Unit);
	// Add Inventory
	Unit.SetSoldierClassTemplate(Soldiers[SoldierIndex].SoldierClassTemplate); //Inventory needs this to work
	UpdateUnit(SoldierIndex, Unit, NewGameState); //needs to be before adding to inventory or 2nd util item gets thrown out
	AddFullInventory(SoldierIndex, NewGameState, Unit);

	// add required loadout items
	if( Unit.GetMyTemplate().RequiredLoadout != '' )
	{
		Unit.ApplyInventoryLoadout(NewGameState, Unit.GetMyTemplate().RequiredLoadout);
	}
}

simulated function AddFullInventory(int SoldierIndex, XComGameState GameState, XComGameState_Unit Unit)
{
	// Add inventory
	AddItemToUnit(GameState, Unit, Soldiers[SoldierIndex].PrimaryWeaponTemplate);
	AddItemToUnit(GameState, Unit, Soldiers[SoldierIndex].SecondaryWeaponTemplate);
	AddItemToUnit(GameState, Unit, Soldiers[SoldierIndex].ArmorTemplate);
	AddItemToUnit(GameState, Unit, Soldiers[SoldierIndex].HeavyWeaponTemplate);
	AddItemToUnit(GameState, Unit, Soldiers[SoldierIndex].UtilityItem1Template);
	AddItemToUnit(GameState, Unit, Soldiers[SoldierIndex].UtilityItem2Template);
}

simulated function AddItemToUnit(XComGameState NewGameState, XComGameState_Unit Unit, name EquipmentTemplateName)
{
	local XComGameState_Item ItemInstance;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(EquipmentTemplateName));

	if( EquipmentTemplate != none )
	{
		ItemInstance = EquipmentTemplate.CreateInstanceFromTemplate(NewGameState);
		Unit.AddItemToInventory(ItemInstance, EquipmentTemplate.InventorySlot, NewGameState);
		NewGameState.AddStateObject(ItemInstance);
	}
}

simulated function UpdateUnit(int SoldierIndex, XComGameState_Unit Unit, XComGameState UseGameState)
{
	local TSoldier Soldier;
	local XGCharacterGenerator CharacterGenerator;
	local CharacterPoolManager CharacterPool;
	local XComGameState_Unit CharacterPoolUnit;
	local int Index;
	local SCATProgression Progression;
	local array<SCATProgression> SoldierProgression;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2SoldierClassTemplate UnitSoldierClassTemplate;
	local string RedScreenMsg;

	CharacterPool = `CHARACTERPOOLMGR;

	if( Unit.IsSoldier() )
	{
		if( Soldiers[SoldierIndex].CharacterPoolSelection > 0 )
		{
			CharacterPoolUnit = CharacterPool.CharacterPool[Soldiers[SoldierIndex].CharacterPoolSelection - 1];

			CharacterGenerator = `XCOMGRI.Spawn(CharacterPoolUnit.GetMyTemplate().CharacterGeneratorClass);
			//Generate a charater of the proper gender and race
			Soldier = CharacterGenerator.CreateTSoldierFromUnit(CharacterPoolUnit, UseGameState);

			//Fill in the appearance data manually ( it is set below into the unit state object )
			Soldier.kAppearance = CharacterPoolUnit.kAppearance;
			Soldier.nmCountry = CharacterPoolUnit.GetCountry();

			Soldier.strFirstName = CharacterPoolUnit.GetFirstName();
			Soldier.strLastName = CharacterPoolUnit.GetLastName();
			Soldier.strNickName = CharacterPoolUnit.GetNickName();
		}
		else
		{
			CharacterGenerator = `XCOMGRI.Spawn(Unit.GetMyTemplate().CharacterGeneratorClass);
			Soldier = CharacterGenerator.CreateTSoldierFromUnit(Unit, UseGameState);
		}
		CharacterGenerator.Destroy();

		Unit.SetTAppearance(Soldier.kAppearance);
		Unit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
		Unit.SetCountry(Soldier.nmCountry);

		Unit.SetSoldierClassTemplate(Soldiers[SoldierIndex].SoldierClassTemplate);
		Unit.ResetSoldierRank();
		for( Index = 0; Index < Soldiers[SoldierIndex].SoldierRank; ++Index )
		{
			Unit.RankUpSoldier(UseGameState, Soldiers[SoldierIndex].SoldierClassTemplate);
		}

		UnitSoldierClassTemplate = Unit.GetSoldierClassTemplate();

		for( Progression.iRank = 0; Progression.iRank < UnitSoldierClassTemplate.GetMaxConfiguredRank(); ++Progression.iRank )
		{
			AbilityTree = UnitSoldierClassTemplate.GetAbilityTree(Progression.iRank);
			for( Progression.iBranch = 0; Progression.iBranch < AbilityTree.Length; ++Progression.iBranch )
			{
				if( Soldiers[SoldierIndex].EarnedClassAbilities.Find(AbilityTree[Progression.iBranch].AbilityName) != INDEX_NONE )
				{
					SoldierProgression.AddItem(Progression);
				}
			}
		}

		if( Soldiers[SoldierIndex].EarnedClassAbilities.Length != SoldierProgression.Length )
		{
			RedScreenMsg = "Soldier '" $ Soldiers[SoldierIndex].SoldierID $ "' has invalid ability definition: \n-> Configured Abilities:";
			for( Index = 0; Index < Soldiers[SoldierIndex].EarnedClassAbilities.Length; ++Index )
			{
				RedScreenMsg = RedScreenMsg $ "\n\t" $ Soldiers[SoldierIndex].EarnedClassAbilities[Index];
			}
			RedScreenMsg = RedScreenMsg $ "\n-> Selected Abilities:";
			for( Index = 0; Index < SoldierProgression.Length; ++Index )
			{
				AbilityTree = UnitSoldierClassTemplate.GetAbilityTree(SoldierProgression[Index].iRank);
				RedScreenMsg = RedScreenMsg $ "\n\t" $ AbilityTree[SoldierProgression[Index].iBranch].AbilityName;
			}
			`RedScreen(RedScreenMsg);
		}

		Unit.SetSoldierProgression(SoldierProgression);
		Unit.SetBaseMaxStat(eStat_UtilityItems, 2);
		Unit.SetCurrentStat(eStat_UtilityItems, 2);
	}
	else
	{
		Unit.ClearSoldierClassTemplate();
	}
}

// Purge the GameState of any XComGameState_Unit or XComGameState_Item objects
function PurgeGameState(XComGameState GameState)
{
	local int i;
	local array<int> arrObjectIDs;
	local XComGameState_Unit Unit;
	local XComGameState_Item Item;

	// Enumerate objects
	foreach GameState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		arrObjectIDs.AddItem(Unit.ObjectID);
	}
	foreach GameState.IterateByClassType(class'XComGameState_Item', Item)
	{
		arrObjectIDs.AddItem(Item.ObjectID);
	}

	// Purge objects
	for( i = 0; i < arrObjectIDs.Length; ++i )
	{
		GameState.PurgeGameStateForObjectID(arrObjectIDs[i]);
	}
}

function string FormatSelectedMapName(string MapName)
{
	return class'UIUtilities_Text'.static.GetColoredText("[X]" @ MapName, eUIState_Good, 22);
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

simulated function OnReceiveFocus()
{
	Show();
}

simulated function OnLoseFocus()
{
	Hide();
}

defaultproperties
{
	SelectedMapIndex = INDEX_NONE;
}
