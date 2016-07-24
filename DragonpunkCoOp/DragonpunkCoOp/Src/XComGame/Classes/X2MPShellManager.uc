//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPShellManager.uc
//  AUTHOR:  Todd Smith  --  7/21/2015
//  PURPOSE: Manager for the multiplayer shell. Responsible for reading/writing profile
//           data. Feeding the data to shell/ui. Game creation and setup. etc.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPShellManager extends Actor
	dependson(X2MPData_Shell)
	config(MPGame);

var privatewrite array<TX2UIMaxSquadCostData> m_arrMaxSquadCostData;
var privatewrite array<TX2UITurnTimerData> m_arrTurnTimerData;
var privatewrite array<TX2UILobbyTypeData> m_arrLobbyTypeData;
var privatewrite array<TX2UIMapTypeData> m_arrMapTypeData;

var localized string m_strRankedMatch;
var localized string m_strQuickMatch;
var localized string m_strCustomMatch;

var localized string m_strRandomMap;
var localized string m_strInfiniteTime;
var localized string m_strTimeLimitPostfix;
var localized string m_strCancelGameSearchDueToLostConnection;

var privatewrite bool                   m_bActive;
var private XComGameStateHistory        m_kHistory;
var private XComGameState               m_kLoadoutGameState;               // Stores everything (units, items, etc) for the loadout.
var private XComGameState_Player        m_kLoadoutPlayerGameState;         // GameState data for the temporarily generated player for Loadouts.
var private StateObjectReference        m_kLocalPlayerGameStateRef;        // GameState Ref for the current player
var privatewrite array<XComGameState>   m_arrSquadLoadouts;
var privatewrite array<TX2UnitPresetData>   m_arrUnitPresets;
var privatewrite array<StateObjectReference> m_arrUnitInventory;
var privatewrite XGCharacterGenerator    m_kCharacterGenerator;

// online game system variables
var private TMPGameSettings             m_kGameSettings;

var TServerBrowserData m_tServerBrowserData;
var int m_iServerBrowserJoinGameSearchResultsIndex;
var array<OnlineGameSearchResult> arrOnlineGameSearchResultCache;

var TLeaderboardsData m_tLeaderboardsData;
var TLeaderboardsData m_tLeaderboardsTopPlayersData;
var TLeaderboardsData m_tLeaderboardsYourRankData;
var TLeaderboardsData m_tLeaderboardsFriendsData;
var EMPLeaderboardType m_eCachedLeaderboardFetchType;
var int m_CachedLeaderboardFetchStartIndex;
var int m_CachedLeaderboardFetchNumResults;
var bool m_bLeaderboardsTopPlayersDataLoaded;
var bool m_bLeaderboardsYourRankDataLoaded;
var bool m_bLeaderboardsFriendsDataLoaded;

var bool m_bInProcessOfJoiningGame;
var bool m_bPassedNetworkConnectivityCheck;
var bool m_bPassedOnlineConnectivityCheck;
var bool m_bPassedOnlinePlayPermissionsCheck;
var bool m_bPassedOnlineChatPermissionsCheck;

var privatewrite EQuitReason m_eCancelFindGamesQuitReason;

var private array<delegate<OnLeaderboardFetchComplete> > m_dOnLeaderboardFetchCompleteDelegates;
var private array<delegate<OnSearchGamesComplete> > m_dOnSearchGamesCompleteDelegates;
var private array< delegate<OnSaveProfileSettingsComplete> > m_SaveProfileSettingsCompleteDelegates;
var OnlineStatsRead            m_kOnlineStatsRead;
var XComShellPresentationLayer m_kShellPres;
var OnlineSubsystem            m_OnlineSub;
var XComOnlineEventMgr         m_OnlineEventMgr;
var XComPlayerController       m_kControllerRef;

var UINavigationHelp NavHelp;

delegate OnLeaderboardFetchComplete(const out TLeaderboardsData kLeaderboardsData);
delegate OnSearchGamesComplete(const out TServerBrowserData kServerData, bool bSuccess);
delegate OnSaveProfileSettingsComplete(bool bSuccess);

function Init(XComPlayerController controller)
{
	m_kControllerRef = controller;
	m_kShellPres = XComShellPresentationLayer(Owner);
	m_kHistory = `XCOMHISTORY;

	InitMaxSquadCostData();
	InitTurnTimerData();
	InitLobbyTypeData();
	InitMapTypeData();

	// Setup handling connection status delegates for the MP Lobby only. When in the Menus, this gets done in 'OnMPShellScreenInitialized()'
	if(m_kShellPres.IsA('X2MPLobbyPresentationLayer'))
	{
		ReadOnlineGameSettings();

		// Main shell handles these so that it can show a network disconnect dialog. it then passes down the message to us. -tsmith
		//m_OnlineSub.SystemInterface.AddLinkStatusChangeDelegate(LinkStatusChange);
		// m_OnlineSub.SystemInterface.AddConnectionStatusChangeDelegate(ConnectionStatusChange);
		m_OnlineEventMgr.AddLoginStatusChangeDelegate(LoginStatusChange);
		m_OnlineSub.SystemInterface.AddExternalUIChangeDelegate(ExternalUIChangedDelegate);
	}
}

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	m_OnlineEventMgr = `ONLINEEVENTMGR;
	m_OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();

	// HAX: Check to see if we have a no network connection system message so we don't show the same error twice.
	if( m_OnlineEventMgr.IsSystemMessageQueued(SystemMessage_QuitReasonLinkLost) || m_OnlineEventMgr.IsSystemMessageQueued(SystemMessage_QuitReasonLostConnection))
		m_OnlineEventMgr.bWarnedOfOnlineStatus = true;
	else
		m_OnlineEventMgr.bWarnedOfOnlineStatus = false;

	SubscribeToOnCleanupWorld();
	`log(`location @ "Subscribed to OnCleanupWorld!", true, 'XCom_Online');	
}

function OnMPShellScreenInitialized()
{
	UpdateConnectivityData();

	// main shell handles the link change and then passes down to us if its not handled -tsmith
	//m_OnlineSub.SystemInterface.AddLinkStatusChangeDelegate(LinkStatusChange);
	//m_OnlineSub.SystemInterface.AddConnectionStatusChangeDelegate(ConnectionStatusChange);
	m_OnlineEventMgr.AddLoginStatusChangeDelegate(LoginStatusChange);
	m_OnlineEventMgr.AddSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete);
	m_OnlineSub.SystemInterface.AddExternalUIChangeDelegate(ExternalUIChangedDelegate);
	m_OnlineSub.GameInterface.AddFindOnlineGamesCompleteDelegate(OnFindOnlineGamesCompleteErrorHandler);
}

function Activate()
{
	ReadSquadLoadouts();
	ReadUnitPresets();
	m_bActive = true;
}

function Deactivate()
{
	Cleanup();
	m_bActive = false;
}

/**
* Called when the world is being cleaned up. Allows the actor to free any dynamic content it has created.
*/
simulated event OnCleanupWorld()
{
	Cleanup();
}

function Cleanup()
{
	`log(`location, true, 'XCom_Online');

	m_OnlineEventMgr.ClearLoginStatusChangeDelegate(LoginStatusChange);
	m_OnlineEventMgr.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete);

	//m_OnlineSub.SystemInterface.ClearLinkStatusChangeDelegate(LinkStatusChange);
	//m_OnlineSub.SystemInterface.ClearConnectionStatusChangeDelegate(ConnectionStatusChange);
	m_OnlineSub.SystemInterface.ClearExternalUIChangeDelegate(ExternalUIChangedDelegate);

	m_OnlineSub.StatsInterface.ClearReadOnlineStatsCompleteDelegate(OnBeginLeaderboardsFetchComplete);

	m_OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnFailToJoinGame);
	m_OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OSSOnDestroyOnlineGameForJoinGame);
	m_OnlineSub.GameInterface.ClearJoinOnlineGameCompleteDelegate(OSSJoinOnlineGameCompleted);

	m_OnlineSub.GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSOnFindOnlineGamesComplete);
	m_OnlineSub.GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSRefreshOnCancelFindOnlineGamesComplete);
	m_OnlineSub.GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSOnCancelFindOnlineGamesComplete);
	m_OnlineSub.GameInterface.ClearFindOnlineGamesCompleteDelegate(CancelAutomatchCallback);
	m_OnlineSub.GameInterface.ClearFindOnlineGamesCompleteDelegate(OnFindOnlineGamesCompleteErrorHandler);

	m_OnlineSub.GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSRefreshOnCancelFindOnlineGamesComplete);
	m_OnlineSub.GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSOnCancelFindOnlineGamesComplete);
	m_OnlineSub.GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(CancelAutomatchCallback);

	m_OnlineSub.PlayerInterface.ClearLoginUICompleteDelegate(OnLoginUIComplete);

	m_dOnLeaderboardFetchCompleteDelegates.Remove(0, m_dOnLeaderboardFetchCompleteDelegates.Length); // Clear
	m_dOnSearchGamesCompleteDelegates.Remove(0, m_dOnSearchGamesCompleteDelegates.Length); // Clear

	if (m_kCharacterGenerator != none)
		m_kCharacterGenerator.Destroy();

	super.OnCleanupWorld();
}

function bool ReplaceSquadLoadout(XComGameState kOldLoadout, XComGameState kNewLoadout)
{
	local int i;
	local int iNewLoadoutID;
	local int iOldLoadoutID;
	local int iIterLoadoutID;

	iNewLoadoutID = XComGameStateContext_SquadSelect(kNewLoadout.GetContext()).iLoadoutId;
	iOldLoadoutID = XComGameStateContext_SquadSelect(kOldLoadout.GetContext()).iLoadoutId;
	for(i = 0; i < m_arrSquadLoadouts.length; i++)
	{
		iIterLoadoutID = XComGameStateContext_SquadSelect(m_arrSquadLoadouts[i].GetContext()).iLoadoutId;
		`log(self $ "::" $ GetFuncName() @ "OldLoadoutID=" $ iOldLoadoutID $ ", " $ "NewLoadout.ID=" $ iNewLoadoutID $ ", " $ "Loadouts["$i$"].id=" $ iIterLoadoutID,, 'uixcom_mp');
		if(iIterLoadoutID == iOldLoadoutID)
		{
			XComGameStateContext_SquadSelect(kNewLoadout.GetContext()).iLoadoutId = iOldLoadoutID;
			m_arrSquadLoadouts[i] = kNewLoadout;
			return true;
		}
	}

	return false;

}

function bool ReplaceUnitPreset(TX2UnitPresetData kOldPreset, TX2UnitPresetData kNewPreset)
{
	local int i;
	local int iOldPresetID;
	local int iIterPresetID;

	iOldPresetID = kOldPreset.iID;
	for(i = 0; i < m_arrUnitPresets.length; i++)
	{
		iIterPresetID = m_arrUnitPresets[i].iID;
		`log(self $ "::" $ GetFuncName() @ "OldPresetID=" $ iOldPresetID $ ", " $ "Presets["$i$"].id=" $ iIterPresetID,, 'uixcom_mp');
		if(iIterPresetID == iOldPresetID)
		{
			kNewPreset.iID = iOldPresetID;
			kNewPreset.strLanguageCreatedWith = kOldPreset.strLanguageCreatedWith;
			m_arrUnitPresets[i] = kNewPreset;
			return true;
		}
	}

	return false;
}

function RemoveUnitPreset(TX2UnitPresetData kPreset)
{
	local int i;
	for(i = 0; i < m_arrUnitPresets.length; i++)
	{
		if(m_arrUnitPresets[i].iID == kPreset.iID)
		{
			m_arrUnitPresets.Remove(i,1);
			return;
		}
	}
}

function int GetSquadLoadoutIndex(XComGameState kSquadLoadout)
{
	local int i;

	i = -1;
	for(i = 0; i < m_arrSquadLoadouts.length; i++)
	{
		if(m_arrSquadLoadouts[i] == kSquadLoadout)
			break;
	}
	return i;
}

function CloseShell()
{
	// we create the initial state from the history, other parts of the game require a clean history, therefore we must nuke it. -tsmith
	DestroyHistory();
	ConsoleCommand("open"@`Maps.SelectShellMap()$"?Game=XComGame.XComShell");
}

function DestroyHistory()
{
	m_kHistory.ObliterateGameStatesFromHistory(m_kHistory.GetNumGameStates());
	m_kHistory.ResetHistory();
}

function ReadOnlineGameSettings()
{
	local XComOnlineGameSettings kOnlineGameSettings;

	// @TODO tsmith: use these values everywhere the new system accesses the old GRI
	kOnlineGameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
	`log(self $ "::" $ GetFuncName() @ "OnlineGameSettings=" $ kOnlineGameSettings.ToString(),, 'XCom_Online');

	OnlineGame_SetType(kOnlineGameSettings.GetGameType());
	OnlineGame_SetNetworkType(kOnlineGameSettings.GetNetworkType());
	OnlineGame_SetMaxSquadCost(kOnlineGameSettings.GetMaxSquadCost());
	OnlineGame_SetTurnTimeSeconds(kOnlineGameSettings.GetTurnTimeSeconds());
	OnlineGame_SetMapPlotInt(kOnlineGameSettings.GetMapPlotTypeInt());
	OnlineGame_SetMapBiomeInt(kOnlineGameSettings.GetMapBiomeTypeInt());
	OnlineGame_SetIsRanked(kOnlineGameSettings.GetIsRanked());
	OnlineGame_SetAutomatch(kOnlineGameSettings.GetIsAutomatch());
}

function ReadSquadLoadouts()
{	
	local XComGameState kReadLoadoutState;
	local array<XComGameState> arrReadLoadouts;
	// NOTE: DestroyHistory will cause a crash due to GameStates getting GCd but still being in the History's list -tsmith
	m_kHistory.ResetHistory();

	`XPROFILESETTINGS.X2MPReadLoadoutGameStates(arrReadLoadouts);
	// need to clone the ones that were read in to make new object IDs as the History knows nothing about the old ones. -tsmith
	m_arrSquadLoadouts.Length = 0;
	foreach arrReadLoadouts(kReadLoadoutState)
	{
		m_arrSquadLoadouts.AddItem(CloneSquadLoadoutGameState(kReadLoadoutState));
	}
}

function WriteSquadLoadouts()
{
	`XPROFILESETTINGS.X2MPWriteLoadoutGameStates(m_arrSquadLoadouts);
}

function ReadUnitPresets()
{
	`XPROFILESETTINGS.X2MPReadUnitPresets(m_arrUnitPresets);
}

function WriteUnitPresets()
{
	`XPROFILESETTINGS.X2MPWriteUnitPresets(m_arrUnitPresets);
}

function SaveProfileSettings(optional bool bForceShowSaveIndicator=false)
{
	`ONLINEEVENTMGR.SaveProfileSettings(bForceShowSaveIndicator);
}

function SaveProfileSettingsComplete(bool bSuccess)
{
	local delegate<OnSaveProfileSettingsComplete> dSaveCompleteDelegate;

	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	foreach m_SaveProfileSettingsCompleteDelegates(dSaveCompleteDelegate)
	{
		dSaveCompleteDelegate(bSuccess);
	}
}

function AddSaveProfileSettingsCompleteDelegate( delegate<OnSaveProfileSettingsComplete> dSaveProfileSettingsCompleteDelegate )
{
	`log(`location @ `ShowVar(dSaveProfileSettingsCompleteDelegate), true, 'XCom_Online');
	if (m_SaveProfileSettingsCompleteDelegates.Find(dSaveProfileSettingsCompleteDelegate) == INDEX_None)
	{
		m_SaveProfileSettingsCompleteDelegates[m_SaveProfileSettingsCompleteDelegates.Length] = dSaveProfileSettingsCompleteDelegate;
	}
}

function ClearSaveProfileSettingsCompleteDelegate(delegate<OnSaveProfileSettingsComplete> dSaveProfileSettingsCompleteDelegate)
{
	local int i;

	`log(`location @ `ShowVar(dSaveProfileSettingsCompleteDelegate), true, 'XCom_Online');
	i = m_SaveProfileSettingsCompleteDelegates.Find(dSaveProfileSettingsCompleteDelegate);
	if (i != INDEX_None)
	{
		m_SaveProfileSettingsCompleteDelegates.Remove(i, 1);
	}
}

function XComGameState GetLoadoutFromId(int iLoadoutId)
{
	local XComGameState kLoadoutState;

	foreach m_arrSquadLoadouts(kLoadoutState)
	{
		`log(self $ "::" $ GetFuncName() @ "Name=" $ XComGameStateContext_SquadSelect(kLoadoutState.GetContext()).strLoadoutName @ "ID=" $ XComGameStateContext_SquadSelect(kLoadoutState.GetContext()).iLoadoutId,, 'uixcom_mp');
		if(XComGameStateContext_SquadSelect(kLoadoutState.GetContext()).iLoadoutId == iLoadoutId)
		{
			break;
		}
	}

	return kLoadoutState;
}

function InitMaxSquadCostData()
{
	local int i;
	local TX2UIMaxSquadCostData kData;

	m_arrMaxSquadCostData.Length = 0;
	for(i = 0; i < class'X2MPData_Shell'.default.m_arrMaxSquadCosts.Length; i++)
	{
		kData.iCost = class'X2MPData_Shell'.default.m_arrMaxSquadCosts[i];
		if(kData.iCost == class'X2MPData_Common'.const.INFINITE_VALUE) 
		{ 
			kData.strText = class'X2MPData_Shell'.default.m_strMPCustomMatchInfinitePointsString;
		}
		else
		{
			kData.strText = string(kData.iCost);
		}
		
		m_arrMaxSquadCostData.AddItem(kData); 
	}
}

function InitTurnTimerData()
{
	local int i;
	local TX2UITurnTimerData kData;

	m_arrTurnTimerData.Length = 0;
	for(i = 0; i < class'X2MPData_Shell'.default.m_arrTurnTimers.Length; i++)
	{
		kData.iTurnTime = class'X2MPData_Shell'.default.m_arrTurnTimers[i];
		if(kData.iTurnTime == class'X2MPData_Common'.const.INFINITE_VALUE) 
		{ 
			kData.strText = class'X2MPData_Shell'.default.m_strMPCustomMatchInfiniteTurnTimeString;
		}
		else
		{
			kData.strText = string(kData.iTurnTime);
		}
		
		m_arrTurnTimerData.AddItem(kData); 
	}
}

function InitLobbyTypeData()
{
	local int i;
	local TX2UILobbyTypeData kData;

	m_arrLobbyTypeData.Length = 0;
	for(i = 0; i < eMPNetworkType_MAX; i++)
	{
		kData.iLobbyType = EMPNetworkType(i);
		kData.strText = class'X2MPData_Shell'.default.m_arrNetworkTypeNames[i];
		m_arrLobbyTypeData.AddItem(kData);
	}
}

function InitMapTypeData()
{
	local XComTacticalMissionManager        MissionMgr;
	local MissionDefinition                 MissionDef;
	local XComParcelManager                 ParcelMgr;
	local array<PlotDefinition>             arrValidPlots;
	local PlotDefinition                    kPlotDef;
	local TX2UIMapTypeData                  kData, kEmptyData;
	local string                            strBiomeType;
	local int                               i, foundIdx;

	MissionMgr = `TACTICALMISSIONMGR;
	ParcelMgr = `PARCELMGR;

	MissionMgr.GetMissionDefinitionForType("Multiplayer", MissionDef);
	ParcelMgr.GetValidPlotsForMission(arrValidPlots, MissionDef);

	m_arrMapTypeData.Length = 0;
	foreach arrValidPlots(kPlotDef)
	{
`if(`isdefined(FINAL_RELEASE))
		if( kPlotDef.ExcludeFromRetailBuilds )
		{
			continue; // Skip this plot!
		}
`endif
		foundIdx = -1;
		for(i = 0; i < m_arrMapTypeData.Length; i++)
		{
			if(m_arrMapTypeData[i].strPlotType == kPlotDef.strType)
			{
				foundIdx = i;
				break;
			}
		}
		// if there is no plot type entry, create a new one -tsmith
		if(foundIdx == -1)
		{
			kData = kEmptyData;
			kData.strPlotType = kPlotDef.strType;
			kData.strText = kPlotDef.strType;
			kData.arrValidBiomes = kPlotDef.ValidBiomes;
			kData.FriendlyNameIndex = kPlotDef.FriendlyNameIndex;
			kData.ValidBiomeFriendlyNames = kPlotDef.ValidBiomeFriendlyNames;
			m_arrMapTypeData.AddItem(kData);
		}
		// otherwise find the plot type entry and add the biomes -tsmith
		else
		{
			kData = m_arrMapTypeData[foundIdx];
			i = 0;
			// add any new biomes -tsmith
			foreach kPlotDef.ValidBiomes(strBiomeType)
			{
				if(kData.arrValidBiomes.Find(strBiomeType) == INDEX_NONE)
				{
					kData.arrValidBiomes.AddItem(strBiomeType);
					kData.ValidBiomeFriendlyNames.AddItem(kPlotDef.ValidBiomeFriendlyNames[i]);
				}

				i++;
			}
			m_arrMapTypeData[foundIdx] = kData;
		}
	}
}

function TX2UIMapTypeData GetMapTypeDataFromFriendlyNameIndex(int idx)
{
	local TX2UIMapTypeData data;
	local int i;

	if(idx > -1)
	{
		for(i = 0; i < m_arrMapTypeData.Length; i++)
		{
			if(m_arrMapTypeData[i].FriendlyNameIndex == idx)
			{
				data = m_arrMapTypeData[i];
				break;
			}
		}
	}

	return data;
}

function PopulateInventoryForSoldier(StateObjectReference kUnitRef, XComGameState kEditState)
{
	local X2DataTemplate kEquipmentTemplate;
	local XComGameState_Item kItemState;
	local XComGameState_Unit kUnit;
	local TX2MPSoldierItemDefinition ItemDefinition;

	// only utility items are available for MP soldiers -tsmith
	m_arrUnitInventory.Length = 0;
	kUnit = XComGameState_Unit(kEditState.GetGameStateForObjectID(kUnitRef.ObjectID));
	if(kUnit.IsSoldier())
	{
		foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().MPAvailableSoldierItems(ItemDefinition)
		{
			kEquipmentTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemDefinition.ItemTemplateName);
			kItemState = X2EquipmentTemplate(kEquipmentTemplate).CreateInstanceFromTemplate(kEditState);
			kEditState.AddStateObject(kItemState);
			m_arrUnitInventory.AddItem(kItemState.GetReference());
		}
	}
	return;
}


function XComGameState_Unit AddRandomSoldierToLoadout(out XComGameState kLoadoutState)
{
	local X2CharacterTemplateManager    CharTemplateMgr;	
	local X2CharacterTemplate           CharacterTemplate;
	local TSoldier                      CharacterGeneratorResult;
	local XGCharacterGenerator          CharacterGenerator;
	local XComGameState_Unit			NewSoldierState;

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);
	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Soldier');
	`assert(CharacterTemplate != none);
	CharacterGenerator = class'Engine'.static.GetCurrentWorldInfo().Spawn(CharacterTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	NewSoldierState = CharacterTemplate.CreateInstanceFromTemplate(kLoadoutState);
	NewSoldierState.RandomizeStats();
	NewSoldierState.ApplyInventoryLoadout(kLoadoutState, 'RookieSoldier');
	// randomize a unit to get different promotions and abilities. -tsmith
	CharacterGeneratorResult = CharacterGenerator.CreateTSoldier();
	NewSoldierState.SetTAppearance(CharacterGeneratorResult.kAppearance);
	NewSoldierState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
	NewSoldierState.SetCountry(CharacterGeneratorResult.nmCountry);

	kLoadoutState.AddStateObject(NewSoldierState);

	return NewSoldierState;
}

function XComGameState_Unit AddNewUnitToLoadout(X2MPCharacterTemplate MPCharacterTemplate, out XComGameState kLoadoutState, optional int MPSquadLoadoutIndex = INDEX_NONE)
{
	local XComGameState_Unit NewUnitState;

	if(MPCharacterTemplate != none)
	{
		NewUnitState = CreateMPUnitState(MPCharacterTemplate, kLoadoutState);
		NewUnitState.MPSquadLoadoutIndex = MPSquadLoadoutIndex;
		kLoadoutState.AddStateObject(NewUnitState);
	}
	else
	{
		`warn(self $ "::" $ GetFuncName() @ "CharacterTemplate is none");
	}

	return NewUnitState;
}

function XComGameState_Unit CreateMPUnitState(X2MPCharacterTemplate MPCharacterTemplate, out XComGameState kLoadoutState)
{
	local int i;
	local XComGameState_Unit NewUnitState;
	local TSoldier CharacterGeneratorResult;
	local X2CharacterTemplate CharacterTemplate;

	CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(MPCharacterTemplate.CharacterTemplateName);
	NewUnitState = CharacterTemplate.CreateInstanceFromTemplate(kLoadoutState);
	NewUnitState.SetMPCharacterTemplate(MPCharacterTemplate.DataName);
	
	if(NewUnitState.IsSoldier())
	{
		NewUnitState.SetSoldierClassTemplate(MPCharacterTemplate.SoldierClassTemplateName);
		for(i = 0; i < MPCharacterTemplate.SoldierRank; i++)
		{
			NewUnitState.RankUpSoldier(kLoadoutState, MPCharacterTemplate.SoldierClassTemplateName);
		}
		class'X2MPData_Common'.static.GiveSoldierAbilities(NewUnitState, MPCharacterTemplate.Abilities);
		NewUnitState.SetBaseMaxStat(eStat_UtilityItems, float(MPCharacterTemplate.NumUtilitySlots));
		NewUnitState.SetCurrentStat(eStat_UtilityItems, float(MPCharacterTemplate.NumUtilitySlots));
		NewUnitState.SetBaseMaxStat(eStat_CombatSims, 0);
		NewUnitState.SetCurrentStat(eStat_CombatSims, 0);
		NewUnitState.SetBaseMaxStat(eStat_Will, 80);
		NewUnitState.SetCurrentStat(eStat_Will, 80);

		if(MPCharacterTemplate.DataName == 'PsiOperative')
		{
			NewUnitState.SetBaseMaxStat(eStat_PsiOffense, 95);
			NewUnitState.SetCurrentStat(eStat_PsiOffense, 95);
		}

		m_kCharacterGenerator = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);
		CharacterGeneratorResult = m_kCharacterGenerator.CreateTSoldier();
		NewUnitState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		NewUnitState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
		NewUnitState.SetCountry(CharacterGeneratorResult.nmCountry);
		
		NewUnitState.ApplyInventoryLoadout(kLoadoutState, MPCharacterTemplate.Loadout);
		NewUnitState.MPBaseLoadoutItems = NewUnitState.InventoryItems;
	}
	else
	{
		NewUnitState.SetCharacterName(" ", MPCharacterTemplate.DisplayName, "");
		NewUnitState.SetCountry('Country_Canada');
		NewUnitState.ApplyInventoryLoadout(kLoadoutState);
	}
	return NewUnitState;
}

function AddLoadoutToList(XComGameState kLoadout)
{
	if(m_arrSquadLoadouts.Find(kLoadout) == -1)
	{
		m_arrSquadLoadouts.AddItem(kLoadout);
	}
}

function DeleteLoadoutFromList(XComGameState kLoadout)
{
	m_arrSquadLoadouts.RemoveItem(kLoadout);
}

function AddPresetToList(TX2UnitPresetData kPreset)
{
	local int i;

	// find it ourselves because UE3 script throws compile errors when you try to do a Find on a dynamic array for structs .!..   -tsmith
	for(i = 0; i < m_arrUnitPresets.Length; i++)
	{
		if(m_arrUnitPresets[i].iID == kPreset.iID)
			return;
	}

	m_arrUnitPresets.AddItem(kPreset);
	
}

function DeletePreset(TX2UnitPresetData kPreset)
{
	m_arrUnitPresets.RemoveItem(kPreset);
}

function int GetNextLoadoutId()
{
	local XComGameStateContext_SquadSelect kSquadSelect;
	local int iHighestId, i;
	iHighestId = 0;
	for (i = 0; i < m_arrSquadLoadouts.Length; ++i)
	{
		kSquadSelect = XComGameStateContext_SquadSelect(m_arrSquadLoadouts[i].GetContext());
		iHighestId = Max(iHighestId, kSquadSelect.iLoadoutId);
	}
	return iHighestId + 1;
}

private function int GetNextPresetID()
{
	local int iHighestId, i;
	iHighestId = 0;
	for (i = 0; i < m_arrUnitPresets.Length; ++i)
	{
		iHighestId = Max(iHighestId, m_arrUnitPresets[i].iID);
	}
	return iHighestId + 1;
}

function XComGameState CreateEmptyLoadout(string strLoadoutName)
{
	return CreateSquadSelectState(GetNextLoadoutId(), strLoadoutName, `XPROFILESETTINGS.GetLanguage());
}

function TX2UnitPresetData CreateEmptyUnitPreset()
{
	local TX2UnitPresetData kPreset;

	kPreset.strLanguageCreatedWith = `XPROFILESETTINGS.GetLanguage();
	kPreset.iID = GetNextPresetID();

	return kPreset;
}

static function XComGameState CreateSquadSelectState(int iLoadoutId, string strNewLoadoutName, string strLanguage)
{
	local XComGameState_Player kGameStatePlayer;
	local XComGameState kSquadState;

	kSquadState = class'XComGameStateContext_SquadSelect'.static.CreateSquadSelect(iLoadoutId, true, true, strNewLoadoutName, strLanguage);

	// No game state existed before, create the first bits that need to be there to work correctly.
	kGameStatePlayer = XComGameState_Player(kSquadState.CreateStateObject(class'XComGameState_Player'));
	kGameStatePlayer.TeamFlag = eTeam_All; // Initially setting this to 'All' since we will search for this later to replace it with the correct one later.
	kSquadState.AddStateObject(kGameStatePlayer);

	return kSquadState;
}

function XComGameState CloneSquadLoadoutGameState(XComGameState FromGameState, optional bool bGenerateNewId=false)
{
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	local XComGameStateContext_SquadSelect LoadoutStateContext;
	local int iLoadoutId;

	LoadoutStateContext = XComGameStateContext_SquadSelect(FromGameState.GetContext());
	`assert(LoadoutStateContext != none);

	if(LoadoutStateContext != none)
	{
		if(bGenerateNewId)
			iLoadoutId = GetNextLoadoutId();
		else
			iLoadoutId = LoadoutStateContext.iLoadoutId;

		NewGameState = CreateSquadSelectState(iLoadoutId, LoadoutStateContext.strLoadoutName, LoadoutStateContext.strLanguageCreatedWith);
		foreach FromGameState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			CreateUnitLoadoutGameState(Unit, NewGameState, FromGameState);
		}
	}
	else
	{
		`warn("X2MPShellManager::" $ GetFuncName() @ `ShowVar(FromGameState) @ "does not have a context of type XComGameStateContext_SquadSelect");
	}

	return NewGameState;
}

// creates a basic XComGameState_Unit that can be used to read/write to/from profle settings and loadouts in the ui.
// can also be used in seeding a tactical start state for singleplayer and multiplayer games.
static function XComGameState_Unit CreateUnitLoadoutGameState(XComGameState_Unit FromUnit, XComGameState NewGameState, XComGameState FromGameState)
{
	local XComGameState_Unit NewUnit;
	local X2CharacterTemplate CharacterTemplate;
	local name CharacterTemplateName;
	local X2MPCharacterTemplateManager MPCharacterTemplateManager;

	MPCharacterTemplateManager = class'X2MPCharacterTemplateManager'.static.GetMPCharacterTemplateManager();
	CharacterTemplateName = FromUnit.GetMyTemplateName();
	CharacterTemplateName = MPCharacterTemplateManager.FindCharacterTemplateMapOldToNew(FromUnit.GetMyTemplateName());
	CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CharacterTemplateName);
	if(CharacterTemplate == none)
	{
		`warn("CreateTemplatesFromCharacter: '" $ CharacterTemplateName $ "' is not a valid template.");
		return none;
	}

	NewUnit = CharacterTemplate.CreateInstanceFromTemplate(NewGameState);

	// Add Unit
	NewGameState.AddStateObject(NewUnit);
	UpdateUnit(FromUnit, NewUnit, NewGameState); //needs to be before adding to inventory or 2nd util item gets thrown out

	// Copy Inventory Customization
	CopyInventoryCustomization(FromUnit, FromGameState, NewUnit, NewGameState);

	NewUnit.MPSquadLoadoutIndex = FromUnit.MPSquadLoadoutIndex;

	return NewUnit;
}

static function UpdateUnit(XComGameState_Unit FromUnit, XComGameState_Unit NewUnit, XComGameState NewGameState)
{
	local int Index, SoldierRank;
	local name SoldierClassTemplateName;
	local X2MPCharacterTemplate MPCharacterTemplate;
	local CharacterPoolManager CharacterPoolMgr;

	NewUnit.SetMPCharacterTemplate(FromUnit.GetMPCharacterTemplateName());
	MPCharacterTemplate = NewUnit.GetMPCharacterTemplate();

	`log("X2MPShellManager:UpdateUnit -" @ FromUnit.GetMPName(eNameType_FullNick) @ "-" @ FromUnit.GetMyTemplateName() @ "-" @ FromUnit.GetMPCharacterTemplateName() @ "-" @ ((MPCharacterTemplate.Loadout == '') ? "''" : string(MPCharacterTemplate.Loadout)),,'XCom_Online');

	if (NewUnit.IsSoldier())
	{
		SoldierClassTemplateName = FromUnit.GetSoldierClassTemplate() != none ? FromUnit.GetSoldierClassTemplate().DataName : class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass;		
		NewUnit.SetTAppearance(FromUnit.kAppearance);
		NewUnit.SetSoldierClassTemplate(SoldierClassTemplateName); //Inventory needs this to work
		NewUnit.ResetSoldierRank();
		SoldierRank = FromUnit.GetRank();
		for(Index = 0; Index < SoldierRank; ++Index)
		{
			NewUnit.RankUpSoldier(NewGameState, SoldierClassTemplateName);
		}

		class'X2MPData_Common'.static.GiveSoldierAbilities(NewUnit, MPCharacterTemplate.Abilities);
		NewUnit.SetBaseMaxStat(eStat_UtilityItems, float(MPCharacterTemplate.NumUtilitySlots));
		NewUnit.SetCurrentStat(eStat_UtilityItems, float(MPCharacterTemplate.NumUtilitySlots));
		NewUnit.SetBaseMaxStat(eStat_CombatSims, 0);
		NewUnit.SetCurrentStat(eStat_CombatSims, 0);
		NewUnit.SetBaseMaxStat(eStat_Will, 80);
		NewUnit.SetCurrentStat(eStat_Will, 80);

		if(MPCharacterTemplate.DataName == 'PsiOperative')
		{
			NewUnit.SetBaseMaxStat(eStat_PsiOffense, 95);
			NewUnit.SetCurrentStat(eStat_PsiOffense, 95);
		}

		// Make sure that the appearance is valid.
		CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
		CharacterPoolMgr.FixAppearanceOfInvalidAttributes(NewUnit.kAppearance);
	}
	else
	{
		NewUnit.ClearSoldierClassTemplate();
	}
	
	// Add default loadout items
	NewUnit.ApplyInventoryLoadout(NewGameState, MPCharacterTemplate.Loadout);
	NewUnit.MPBaseLoadoutItems = NewUnit.InventoryItems;

	NewUnit.m_RecruitDate = FromUnit.m_RecruitDate;
	NewUnit.SetCharacterName(FromUnit.GetFirstName(), FromUnit.GetLastName(), FromUnit.GetNickName());
	NewUnit.SetBackground(FromUnit.GetBackground());
	NewUnit.SetCountry(FromUnit.GetCountry());
	NewUnit.UpdatePersonalityTemplate();
}

static function CopyInventoryCustomization(XComGameState_Unit FromUnit, XComGameState FromGameState, XComGameState_Unit NewUnit, XComGameState NewGameState)
{
	CopyCustomizationFromItems(eInvSlot_PrimaryWeapon, FromUnit, FromGameState, NewUnit, NewGameState);
	CopyCustomizationFromItems(eInvSlot_SecondaryWeapon, FromUnit, FromGameState, NewUnit, NewGameState);
	CopyCustomizationFromItems(eInvSlot_HeavyWeapon, FromUnit, FromGameState, NewUnit, NewGameState);
	CopyCustomizationFromItems(eInvSlot_Armor, FromUnit, FromGameState, NewUnit, NewGameState);
	CopyCustomizationFromItems(eInvSlot_Utility, FromUnit, FromGameState, NewUnit, NewGameState, true /*bCopyMissingItems*/);
}

static function CopyCustomizationFromItems(EInventorySlot ItemSlot, XComGameState_Unit FromUnit, XComGameState FromGameState, XComGameState_Unit NewUnit, XComGameState NewGameState, optional bool bCopyMissingItems=false)
{
	local array<XComGameState_Item> FromItems, NewItems;
	local string FromString, NewString;
	local int f;

	f = 0;
	if( ItemSlot == eInvSlot_Backpack || ItemSlot == eInvSlot_Utility || ItemSlot == eInvSlot_CombatSim )
	{
		FromItems = FromUnit.GetAllItemsInSlot(ItemSlot, FromGameState, true /*bExcludeHistory*/);
		NewItems = NewUnit.GetAllItemsInSlot(ItemSlot, NewGameState, true /*bExcludeHistory*/);
	}
	else
	{
		FromItems.AddItem(FromUnit.GetItemInSlot(ItemSlot, FromGameState, true));
		NewItems.AddItem(NewUnit.GetItemInSlot(ItemSlot, NewGameState, true));
	}

	for(f = 0; f < FromItems.Length; ++f )
	{
		FromString = ""; NewString = "";
		FromString = "  FromItems["$f$"]:" @ ((FromItems[f] != None) ? FromItems[f].GetMyTemplate().GetItemFriendlyName() : "None");
		if( f < NewItems.Length )
		{
			NewString = "  NewItems["$f$"]:" @ ((NewItems[f] != None) ? NewItems[f].GetMyTemplate().GetItemFriendlyName() : "None");
		}
		else if( bCopyMissingItems )
		{
			// Missing Item!
			NewItems.AddItem(CopyItemToUnit(FromItems[f], NewUnit, NewGameState));
			NewString = "  Adding - NewItems["$f$"]:" @ ((NewItems[f] != None) ? NewItems[f].GetMyTemplate().GetItemFriendlyName() : "None");
		}
		`log("X2MPShellManager:CopyCustomizationFromItems" @ `ShowEnum(EInventorySlot, ItemSlot, ItemSlot) @ FromString @ NewString,,'XCom_Online');
		if( FromItems[f] != none )
		{
			if( (NewItems[f] != none) && (FromItems[f].GetMyTemplateName() == NewItems[f].GetMyTemplateName()) )
			{
				// Copy the appearance information
				NewItems[f].WeaponAppearance = FromItems[f].WeaponAppearance;
			}
			else
			{
				`warn("X2MPShellManager:CopyCustomizationFromItems - Error copying: " @ FromString @ NewString);
			}
		}
	}
}

static function CopyFullInventory(XComGameState_Unit FromUnit, XComGameState FromGameState, XComGameState_Unit NewUnit, XComGameState NewGameState)
{
	CopyItemsToUnit(eInvSlot_PrimaryWeapon, FromUnit, FromGameState, NewUnit, NewGameState);
	CopyItemsToUnit(eInvSlot_SecondaryWeapon, FromUnit, FromGameState, NewUnit, NewGameState);
	CopyItemsToUnit(eInvSlot_HeavyWeapon, FromUnit, FromGameState, NewUnit, NewGameState);
	CopyItemsToUnit(eInvSlot_Armor, FromUnit, FromGameState, NewUnit, NewGameState);
	CopyItemsToUnit(eInvSlot_Utility, FromUnit, FromGameState, NewUnit, NewGameState);
}

static function CopyItemsToUnit(EInventorySlot ItemSlot, XComGameState_Unit FromUnit, XComGameState FromGameState, XComGameState_Unit NewUnit, XComGameState NewGameState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item FromItem;

	if( ItemSlot == eInvSlot_Backpack || ItemSlot == eInvSlot_Utility || ItemSlot == eInvSlot_CombatSim )
	{
		Items = FromUnit.GetAllItemsInSlot(ItemSlot, FromGameState, true /*bExcludeHistory*/);
	}
	else
	{
		Items.AddItem(FromUnit.GetItemInSlot(ItemSlot, FromGameState, true));
	}
	foreach Items(FromItem)
	{
		CopyItemToUnit(FromItem, NewUnit, NewGameState);
	}
}

static function XComGameState_Item CopyItemToUnit(XComGameState_Item FromItem, XComGameState_Unit NewUnit, XComGameState NewGameState)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate((FromItem == none) ? '' : FromItem.GetMyTemplateName()));

		if(EquipmentTemplate != none)
		{
			NewItem = EquipmentTemplate.CreateInstanceFromTemplate(NewGameState);
			NewItem.WeaponAppearance = FromItem.WeaponAppearance;
			NewUnit.AddItemToInventory(NewItem, EquipmentTemplate.InventorySlot, NewGameState);
			NewGameState.AddStateObject(NewItem);
		}
	return NewItem;
}


//////////////////////////////////////////////////
// ONLINE SUBSYSTEM FUNCTIONS 
//////////////////////////////////////////////////

function UpdateConnectivityData()
{
	m_kShellPres.OSSCheckNetworkConnectivity(false);
	m_kShellPres.OSSCheckOnlineConnectivity(false);
	m_kShellPres.OSSCheckOnlinePlayPermissions(false);
}

function OnlineGame_SetAutomatch(bool bAutomatch)
{
	m_kGameSettings.m_bMPAutomatch = bAutomatch;
	if(bAutomatch)
	{
		m_kGameSettings.m_iMPMaxSquadCost = m_arrMaxSquadCostData[m_arrMaxSquadCostData.Length - 2].iCost;
	}
}

function bool OnlineGame_GetAutomatch()
{
	return m_kGameSettings.m_bMPAutomatch;
}

function string GetMatchString(optional bool isCustom = true)
{
	if(OnlineGame_GetIsRanked())
	{
		return class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_Ranked];
	}
	else if(OnlineGame_GetAutomatch())
	{
		return class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_QuickMatch];
	}
	else if(isCustom)
	{
		return class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_CustomMatch];
	}
	else
	{
		return class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_EditSquad];
	}
}

function string GetTimeString()
{
	if(OnlineGame_GetTurnTimeSeconds() < 0)
	{
		return m_strInfiniteTime;
	}
	else
	{
		return OnlineGame_GetTurnTimeSeconds() @m_strTimeLimitPostfix;
	}
}

function string GetMapString()
{
	local string strMapString;

	strMapString = OnlineGame_GetLocalizedMapPlotName();
	if(m_kGameSettings.m_iMPMapBiomeType > -1)
	{
		strMapString @= OnlineGame_GetLocalizedMapBiomeName();
	}
	if(strMapString == "")
	{
		return m_strRandomMap;
	}
	else
	{
		return strMapString;
	}
}

function string GetPointsString()
{
	if(OnlineGame_GetMaxSquadCost() < 0)
	{
		return class'X2MPData_Shell'.default.m_strMPCustomMatchInfinitePointsString;
	}
	else
	{
		return string(OnlineGame_GetMaxSquadCost());
	}
}

/** 
 *  Network Type - Accessors
 */
function OnlineGame_SetNetworkType(EMPNetworkType eNetworkType)
{
	m_kGameSettings.m_eMPNetworkType = eNetworkType;
	
}

function EMPNetworkType OnlineGame_GetNetworkType()
{
	return m_kGameSettings.m_eMPNetworkType;
}

/** 
 *  Game Type - Accessors
 */
function OnlineGame_SetType(EMPGameType eGameType)
{
	m_kGameSettings.m_eMPGameType = eGameType;
}

function EMPGameType OnlineGame_GetType()
{
	return m_kGameSettings.m_eMPGameType;
}

/** 
 *  Turn Time In Seconds - Accessors
 */
function OnlineGame_SetTurnTimeSeconds(int iTurnTime)
{
	m_kGameSettings.m_iMPTurnTimeSeconds = iTurnTime;
}

function int OnlineGame_GetTurnTimeSeconds()
{
	return m_kGameSettings.m_iMPTurnTimeSeconds;
}

/** 
 *  Max Squad Cost - Accessors
 */
function OnlineGame_SetMaxSquadCost(int iSquadCost)
{
	m_kGameSettings.m_iMPMaxSquadCost = iSquadCost;
	
}

function int OnlineGame_GetMaxSquadCost()
{
	return m_kGameSettings.m_iMPMaxSquadCost;
}

/** 
 *  Is Ranked - Accessors
 */
function OnlineGame_SetIsRanked(bool bIsRanked)
{
	m_kGameSettings.m_bMPIsRanked = bIsRanked;
	if(bIsRanked)
	{
		m_kGameSettings.m_iMPMaxSquadCost = m_arrMaxSquadCostData[m_arrMaxSquadCostData.Length - 2].iCost;
	}
}

function bool OnlineGame_GetIsRanked()
{
	return m_kGameSettings.m_bMPIsRanked;
}

function int OnlineGame_GetMapPlotInt()
{
	return m_kGameSettings.m_iMPMapPlotType;
}
function int OnlineGame_GetMapBiomeInt()
{
	return m_kGameSettings.m_iMPMapBiomeType;
}

function OnlineGame_SetMapBiomeInt(int iMapBiomeType)
{
	m_kGameSettings.m_iMPMapBiomeType = iMapBiomeType;
}

function OnlineGame_SetMapPlotInt(int iMapPlotType)
{
	m_kGameSettings.m_iMPMapPlotType = iMapPlotType;
}

function string OnlineGame_GetMapBiomeName()
{
	local string strBiome;
	local TX2UIMapTypeData kMapTypeData;

	strBiome = "";
	if( m_kGameSettings.m_iMPMapBiomeType > -1 )
	{
		kMapTypeData = GetMapTypeDataFromFriendlyNameIndex(m_kGameSettings.m_iMPMapPlotType);
		strBiome = kMapTypeData.arrValidBiomes[m_kGameSettings.m_iMPMapBiomeType];
	}
	return strBiome;
}

function string OnlineGame_GetLocalizedMapBiomeName()
{
	if( m_kGameSettings.m_iMPMapBiomeType > -1 )
	{
		return class'X2MPData_Shell'.default.arrMPBiomeFriendlyNames[m_kGameSettings.m_iMPMapBiomeType];
	}
	return "";
}

function string OnlineGame_GetMapPlotName()
{
	local string strPlotType;
	local TX2UIMapTypeData kMapTypeData;

	strPlotType = "";
	if( m_kGameSettings.m_iMPMapPlotType > -1 )
	{
		kMapTypeData = GetMapTypeDataFromFriendlyNameIndex(m_kGameSettings.m_iMPMapPlotType);
		strPlotType = kMapTypeData.strPlotType;
	}
	return strPlotType;
}


function string OnlineGame_GetLocalizedMapPlotName()
{
	if( m_kGameSettings.m_iMPMapPlotType > -1 )
	{
		return class'X2MPData_Shell'.default.arrMPMapFriendlyNames[m_kGameSettings.m_iMPMapPlotType];
	}
	return "";
}

//function string OnlineGame_ToString()
//{
//	return m_kOnlineGameSettings.ToString();
//}

function bool OnlineGame_DoCustomGame()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	// If we're trying to play online but don't have the ability or permissions to do so, 
	// warn the user and prompt them to log into the online service is possible - sbatista
	if( !m_OnlineSub.SystemInterface.HasLinkConnection() || 
	  ( OnlineGame_GetNetworkType() != eMPNetworkType_LAN && 
	  ( !m_bPassedOnlineConnectivityCheck || !m_bPassedOnlinePlayPermissionsCheck )))
	{
		DisplayGeneralConnectionErrorDialog();
		return false;
	}

	OnlineGame_SetAutomatch(false);
	return m_kShellPres.OSSCreateUnrankedGame(false);
}

function OnlineGame_SearchGame()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	OSSBeginOnlineSearch();
}

function OnlineGame_DoRankedGame()
{
	local TDialogueBoxData kDialogBoxData;

	// TCR # 086: User is able to access all Multiplayer areas with a gamer profile that has multiplayer privileges set to "blocked". -ttalley
	if (m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex) != FPL_Disabled)
	{
		OnlineGame_SetNetworkType(eMPNetworkType_Public);
		OnlineGame_SetAutomatch(true);
		OnlineGame_SetIsRanked(true);
		m_kShellPres.OSSAutomatchRanked();
	}
	else
	{
		`warn("This account has invalid permissions to access Online Content" $
			", PRI=" $ m_kControllerRef.PlayerReplicationInfo $
			", UniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(m_kControllerRef.PlayerReplicationInfo.UniqueId) $
			", LocalUserNum=" $ m_OnlineEventMgr.LocalUserIndex $
			", LoginStatus=" $ m_OnlineSub.PlayerInterface.GetLoginStatus(m_OnlineEventMgr.LocalUserIndex) $
			", CanPlay=" $ m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex));

		kDialogBoxData = GetOnlinePlayPermissionDialogBoxData();
		m_kShellPres.UIRaiseDialog(kDialogBoxData);
	}
}

function OnlineGame_DoAutomatchGame()
{
	local TDialogueBoxData kDialogBoxData;

	// TCR # 086: User is able to access all Multiplayer areas with a gamer profile that has multiplayer privileges set to "blocked". -ttalley
	if (m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex) != FPL_Disabled)
	{
		OnlineGame_SetNetworkType(eMPNetworkType_Public);
		OnlineGame_SetAutomatch(true);
		OnlineGame_SetIsRanked(false);
		m_kShellPres.OSSAutomatchUnranked();
	}
	else
	{
		`warn("This account has invalid permissions to access Online Content" $
			", PRI=" $ m_kControllerRef.PlayerReplicationInfo $
			", UniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(m_kControllerRef.PlayerReplicationInfo.UniqueId) $
			", LocalUserNum=" $ m_OnlineEventMgr.LocalUserIndex $
			", LoginStatus=" $ m_OnlineSub.PlayerInterface.GetLoginStatus(m_OnlineEventMgr.LocalUserIndex) $
			", CanPlay=" $ m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex));

		kDialogBoxData = GetOnlinePlayPermissionDialogBoxData();
		m_kShellPres.UIRaiseDialog(kDialogBoxData);
	}
}

/**
 * Small hack to combine the Ranked and Network types to get around the 8 search terms for the PS3 -ttalley
 */
function OnlineGame_SetRankedNetworkType(EMPNetworkType eNetworkType, bool bIsRanked)
{
	// @TODO tsmith: need to create new game settings if the ranked status changes.

	//local ERankedOverloadProperty eRankedNetworkType;
	//switch(eNetworkType)
	//{
	//case eMPNetworkType_Public:
	//	eRankedNetworkType = (bIsRanked ? EROP_Ranked : EROP_Unranked_Public);
	//	break;
	//case eMPNetworkType_Private:
	//	eRankedNetworkType = EROP_Unranked_Private;
	//	break;
	//case eMPNetworkType_LAN:
	//default:
	//	eRankedNetworkType = EROP_Offline;
	//	break;
	//}
	//SetIntProperty(PROPERTY_MP_ISRANKED, eRankedNetworkType);
}

function LoginStatusChange(ELoginStatus NewStatus,UniqueNetId NewId)
{
	`log(`location @ `ShowVar(NewStatus) @ "NewId:" @ NewId.Uid.A $ NewId.Uid.B, true, 'XCom_Online');

	UpdateConnectivityData();

	m_OnlineEventMgr.RefreshLoginStatus();
	if ( !m_OnlineEventMgr.bHasLogin )
	{
		// If the user has logged out of their gamer profile then return to the start screen
		m_OnlineEventMgr.ReturnToStartScreen(QuitReason_SignOut);
	}
	// BUG 9757: [ONLINE]PS3 TRC R038 - Users will remain in a non-functioning Leaderboards menu when losing network connection while in the Leaderboards menu.
	// BUG 12075: PS3 TRC R036: The user will remain in the Leaderboards and will receive no error messaging if the user signs out of or loses connection to PlayStation®Network while viewing the Leaderboards.
	else if ( ! m_bPassedNetworkConnectivityCheck )
	{
		// BUG 3776: An extraneous error message will appear and cause limited functionality when selecting "Ranked Match" after the user is disconnected during the loading screen after leaving a Ranked match.
		if ( ! m_OnlineEventMgr.bWarnedOfOnlineStatus )
		{
			// Return to Start Screen ...
			// BUG 4896: [ONLINE] - Users are taken to the MULTIPLAYER Lobby after disconnecting the Ethernet cable while loading into an Unranked game.
			if(m_OnlineSub.SystemInterface.HasLinkConnection())
				HandleOnlineConnectionLost(QuitReason_LostConnection);
			else
				HandleOnlineConnectionLost(QuitReason_LostLinkConnection);

			m_OnlineEventMgr.bWarnedOfOnlineStatus = true;
		}
	}
	else if ( NewStatus != LS_LoggedIn )
	{
			// TTP 18533: If the user is not logged in to online services but still has their gamer
			// profile login then give the lost connection message instead of the sign out message.
			HandleOnlineConnectionLost(QuitReason_LostConnection);
	}
	else if ( NewStatus == LS_LoggedIn )
	{
		m_OnlineEventMgr.bWarnedOfOnlineStatus = false; // Reset this value when the user logs in

		// TTP 17261: PS3 TRC R040: The title does not present a "content restriction" message to the user if they boot the title with a content restricted child sub-account and select Multiplayer while not signed into PSN and then connect to PSN in the Main Menu.
		if (m_kShellPres.OSSCheckOnlinePlayPermissions())
		{
			// No need to show the chat permissions dialog if all online functionality is disabled.
			m_kShellPres.OSSCheckOnlineChatPermissions();
		}
	}
}

function LinkStatusChange(bool bIsConnected)
{
	`log(`location @ `ShowVar(bIsConnected), true, 'XCom_Online');

	UpdateConnectivityData();

	if(!bIsConnected)
	{
		HandleOnlineConnectionLost(QuitReason_LostLinkConnection);
	}
}

function ConnectionStatusChange(EOnlineServerConnectionStatus ConnectionStatus)
{
	local bool bPreviousLink, bPreviousConnection;
	bPreviousLink = m_bPassedNetworkConnectivityCheck;
	bPreviousConnection = m_bPassedOnlineConnectivityCheck;

	`log(`location @ `ShowVar(ConnectionStatus) @ `ShowVar(bPreviousLink) @ `ShowVar(bPreviousConnection), true, 'XCom_Online');

	UpdateConnectivityData();

	switch(ConnectionStatus)
	{
	case OSCS_Connected:
		break;
	case OSCS_ConnectionDropped:
	case OSCS_NoNetworkConnection:
	case OSCS_NotConnected:
		if( bPreviousLink )
		{
			HandleOnlineConnectionLost(QuitReason_LostLinkConnection);
		}
		break;
	case OSCS_ServiceUnavailable:
	case OSCS_UpdateRequired:
	case OSCS_ServersTooBusy:
	case OSCS_DuplicateLoginDetected:
	case OSCS_InvalidUser:
	default:
		if( bPreviousConnection )
		{
			HandleOnlineConnectionLost(QuitReason_LostConnection);
		}
		break;
	}
}

// Fix for bug 11251 - "A client will be taken to their own lobby as they accept an invite and 
//                      attempt to create their own match in the multiplayer menus."
function ExternalUIChangedDelegate(bool bOpen)
{
	if(m_kShellPres == none || !bOpen || // Log spam shield
		!`ONLINEEVENTMGR.IsAcceptingGameInvite()) // XCOM_EW: BUG 1684: [MP/Steam]User will be returned to the Custom match menu when closing Steam Profile of player in Game Browser. -ttalley
		return;

	if(`ONLINEEVENTMGR.m_bMPConfirmExitDialogOpen)
	{
		m_kShellPres.Get2DMovie().DialogBox.OnCancel();
	}
}


function OnFailToJoinGame(name SessionName,bool bWasSuccessful)
{
	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful) @ `ShowVar(m_bInProcessOfJoiningGame) @ `ShowVar(m_kShellPres),,'XCom_Online');

	m_OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnFailToJoinGame);

	if(!m_bInProcessOfJoiningGame)
	{
		`log(`location @ "Clearing delegates and dialogs.",,'XCom_Online');

		// Close progress dialog
		m_kShellPres.UICloseProgressDialog();
	}
	else
	{
		`log(`location @ "Still in the process of joining a game.",,'XCom_Online');
	}
}

function OSSJoinOnlineGameCompleted(name SessionName,bool bWasSuccessful)
{
	local ESystemMessageType eSystemError;
	local string sURL;

	m_bInProcessOfJoiningGame = false;

	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful) @ `ShowVar(m_OnlineSub));

	// Figure out if we have an online subsystem registered
	if (m_OnlineSub != None)
	{
		// Remove the delegate from the list
		m_OnlineSub.GameInterface.ClearJoinOnlineGameCompleteDelegate(OSSJoinOnlineGameCompleted);

		if (bWasSuccessful)
		{
			// Get the platform specific information
			if (m_OnlineSub.GameInterface.GetResolvedConnectString('Game',sURL))
			{
				// Call the game specific function to appending/changing the URL
				//sURL = BuildJoinURL(sURL);

				`Log("  Join Game Successful, Traveling: "$sURL$"", true, 'XCom_Online');

				//ConsoleCommand(sURL);
				m_kShellPres.StartNetworkGame(SessionName, sURL);
			}
		}
		else
		{
			`log("  Join Game FAILED!!!! Destroying online game session 'Game' if it exists", true, 'XCom_Online');
			m_OnlineSub.GameInterface.DestroyOnlineGame('Game');
			eSystemError = SystemMessage_GameUnavailable;
			if (SessionName == 'RoomFull' || SessionName == 'LobbyFull' || SessionName == 'GroupFull')
			{
				eSystemError = SystemMessage_GameFull;
			}
			m_OnlineEventMgr.QueueSystemMessage(eSystemError);
		}
	}
}

function OSSOnFindOnlineGamesComplete( bool bWasSuccessful )
{
	`log(`location @ `ShowVar(m_kShellPres.m_kOnlineGameSearch.bIsSearchInProgress) @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	// Wait until the search as completed
	if( !m_kShellPres.m_kOnlineGameSearch.bIsSearchInProgress )
	{
		// Clean up delegate reference
		m_OnlineSub.GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSOnFindOnlineGamesComplete);
	
		m_kShellPres.m_bOnlineGameSearchInProgress = false;

		// Close progress dialog
		m_kShellPres.ScreenStack.PopIncludingClass(class'UIProgressDialogue', false);

		UpdateServerBrowserData();
		CallSearchGamesCompleteDelegates(m_tServerBrowserData, bWasSuccessful);
	}

	// Service connection error prevented the completion; this will be handled else where.
	if(!bWasSuccessful)
	{
		`log(self $ "::" $ GetFuncName() @ "FindOnlineGames failed!:", true, 'XCom_Online');
	}
}

function UpdateServerBrowserData()
{
	local int i;
	local XGParamTag kTag;
	local TServerInfo kServer;
	local TServerBrowserData kData;
	local XComOnlineGameSettings kGameSettings;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));


	`log(self $ "::" $ GetFuncName() @ "IsSearchInProgress=" $ m_kShellPres.m_bOnlineGameSearchInProgress $ 
		", GameSearch.bIsSearchInProgress=" $ m_kShellPres.m_kOnlineGameSearch.bIsSearchInProgress $ 
		", SearchResults.Length=" $ m_kShellPres.m_kOnlineGameSearch.Results.Length, true, 'XCom_Online');

	kTag.StrValue0 = Caps(class'X2MPData_Shell'.default.m_arrNetworkTypeNames[OnlineGame_GetNetworkType()]);
	kData.strTitle = `XEXPAND.ExpandString(class'X2MPData_Shell'.default.m_strMPServerBrowserTitle);

	if(m_kShellPres.m_bOnlineGameSearchInProgress)
	{
		kData.strStatusLabel = class'X2MPData_Shell'.default.m_strMPServerBrowserSearchInProgressLabel;
	}
	else
	{
		if(m_kShellPres.m_kOnlineGameSearch.Results.Length > 0)
		{
			`log(self $ "::" $ GetFuncName() @ "The following games are available:\n", true, 'XCom_Online');
			
			//clear the server cache
			arrOnlineGameSearchResultCache.Remove(0, arrOnlineGameSearchResultCache.Length);

			for(i = 0; i < m_kShellPres.m_kOnlineGameSearch.Results.Length; ++i)
			{
				kGameSettings = XComOnlineGameSettings(m_kShellPres.m_kOnlineGameSearch.Results[i].GameSettings);
				`log("     " $ i $ ")" @ kGameSettings.OwningPlayerName @ kGameSettings.ToString(), true, 'XCom_Online');

				kServer.strHost = kGameSettings.OwningPlayerName;
				kServer.strPoints = (kGameSettings.GetMaxSquadCost() > 0) ? string(kGameSettings.GetMaxSquadCost()) : class'X2MPData_Shell'.default.m_strMPCustomMatchInfinitePointsString;
				kServer.strTurnTime = (kGameSettings.GetTurnTimeSeconds() > 0) ? string(kGameSettings.GetTurnTimeSeconds()) : class'X2MPData_Shell'.default.m_strMPCustomMatchInfiniteTurnTimeString;
				kServer.strMapPlotType = class'X2MPData_Shell'.default.arrMPMapFriendlyNames[kGameSettings.GetMapPlotTypeInt()];
				kServer.strMapBiomeType = class'X2MPData_Shell'.default.arrMPMapFriendlyNames[kGameSettings.GetMapBiomeTypeInt()];
				KServer.iPing = kGameSettings.PingInMs;

				kServer.iOnlineGameSearchResultIndex = i;
				kData.arrServers.AddItem( kServer );
				arrOnlineGameSearchResultCache.AddItem( m_kShellPres.m_kOnlineGameSearch.Results[i] );
			}
		}
		else
			kData.strStatusLabel = class'X2MPData_Shell'.default.m_strMPServerBrowserNoServersFoundLabel;
	}
	
	m_tServerBrowserData = kData;
}

function OSSOnCancelFindOnlineGamesComplete(bool bWasSuccessful)
{
	// Clean up delegate reference
	m_OnlineSub.GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSOnCancelFindOnlineGamesComplete);

	m_kShellPres.m_bOnlineGameSearchInProgress = false;

	// Close progress dialog
	m_kShellPres.ScreenStack.PopIncludingClass(class'UIProgressDialogue', false);

	// @TODO UI: use the new UI. the new server browser should use delegates.
	//// Update data either way (if screen is open, this function gets called if the screen gets closed while searching)
	//if(m_kShellPres.m_kServerBrowser != none)
	//	m_kShellPres.m_kServerBrowser.UpdateData();

	if(!bWasSuccessful)
	{
		// TODO: @UI proper error message/popup -tsmith 
		`log(self $ "::" $ GetFuncName() @ "Refresh : CancelFindOnlineGames failed!", true, 'XCom_Online');
	}
}

function CancelAutomatchCallback(bool bWasSuccessful)
{
	local OnlineGameInterfaceImpl kGameInterfaceImpl;
	kGameInterfaceImpl = OnlineGameInterfaceImpl(m_OnlineSub.GameInterface);
	`log(`location @ `ShowVar(kGameInterfaceImpl) @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	if (kGameInterfaceImpl != none)
	{
		if (kGameInterfaceImpl.CancelFindOnlineGamesCompleteDelegates.Length > 0)
		{
			`log(`location @ "-> CancelFindOnlineGamesCompleteDelegates:" @ `ShowVar(kGameInterfaceImpl.CancelFindOnlineGamesCompleteDelegates.Length), true, 'XCom_Online');
			kGameInterfaceImpl.CancelFindOnlineGamesCompleteDelegates.Remove(0, kGameInterfaceImpl.CancelFindOnlineGamesCompleteDelegates.Length); // Clear
		}
	}
}

function OSSOnCancelFindOnlineGamesCompleteDueToConnectionLost(bool bWasSuccessful)
{
	m_OnlineSub.GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSOnCancelFindOnlineGamesCompleteDueToConnectionLost);
	m_kShellPres.m_bOnlineGameSearchInProgress = false;
	m_OnlineEventMgr.ReturnToMPMainMenu(m_eCancelFindGamesQuitReason);
}

function OnFindOnlineGamesCompleteErrorHandler(bool bWasSuccessful)
{
	m_OnlineEventMgr.ActivateAllSystemMessages();
}

function OnLoginUIComplete(bool success)
{
	m_OnlineSub.PlayerInterface.ClearLoginUICompleteDelegate(OnLoginUIComplete);
	UpdateConnectivityData();
}

function OnPreClientTravel(string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel)
{
	m_kShellPres.ClearPreClientTravelDelegate(OnPreClientTravel);
	m_OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnFailToJoinGame);

	// Close progress dialog
	m_kShellPres.UICloseProgressDialog();
}

function AddLeaderboardFetchCompleteDelegate(delegate<OnLeaderboardFetchComplete> dOnLeaderboardFetchComplete)
{
	if (m_dOnLeaderboardFetchCompleteDelegates.Find(dOnLeaderboardFetchComplete) == INDEX_NONE)
	{
		m_dOnLeaderboardFetchCompleteDelegates[m_dOnLeaderboardFetchCompleteDelegates.Length] = dOnLeaderboardFetchComplete;
	}
}
function ClearLeaderboardFetchCompleteDelegate(delegate<OnLeaderboardFetchComplete> dOnLeaderboardFetchComplete)
{
	local int RemoveIndex;

	RemoveIndex = m_dOnLeaderboardFetchCompleteDelegates.Find(dOnLeaderboardFetchComplete);
	if (RemoveIndex != INDEX_NONE)
	{
		m_dOnLeaderboardFetchCompleteDelegates.Remove(RemoveIndex,1);
	}
}

function AddSearchGamesCompleteDelegate(delegate<OnSearchGamesComplete> dOnSearchGamesComplete)
{
	if (m_dOnSearchGamesCompleteDelegates.Find(dOnSearchGamesComplete) == INDEX_NONE)
	{
		m_dOnSearchGamesCompleteDelegates[m_dOnSearchGamesCompleteDelegates.Length] = dOnSearchGamesComplete;
	}
}
function ClearSearchGamesCompleteDelegate(delegate<OnSearchGamesComplete> dOnSearchGamesComplete)
{
	local int RemoveIndex;

	RemoveIndex = m_dOnSearchGamesCompleteDelegates.Find(dOnSearchGamesComplete);
	if (RemoveIndex != INDEX_NONE)
	{
		m_dOnSearchGamesCompleteDelegates.Remove(RemoveIndex,1);
	}
}

function CallSearchGamesCompleteDelegates(const out TServerBrowserData kData, bool bSuccess)
{
	local delegate<OnSearchGamesComplete> dOnSearchGamesComplete;

	foreach m_dOnSearchGamesCompleteDelegates(dOnSearchGamesComplete)
	{
		if(dOnSearchGamesComplete != none)
		{
			dOnSearchGamesComplete(kData, bSuccess);
		}
	}
}



//==============================================================================
// 		ONLINE SUBSYSTEM - LEADERBOARDS
//==============================================================================

function bool OSSBeginLeaderboardsFetch(EMPLeaderboardType eLeaderBoardType, optional int StartIndex = 1, optional int NumRows = 20)
{
	local OnlineStatsInterface kStatsInterface;
	local bool bSuccess;
	local float fCurrentTime;

	m_tLeaderboardsData.eLeaderboardType = eLeaderBoardType;
	bSuccess = false;
	fCurrentTime = WorldInfo.RealTimeSeconds;

	if ( m_tLeaderboardsData.bFetching )
	{
		`warn(`location @ "Unable to fetch leaderboard data, async process has not yet returned.");
		m_kShellPres.PlayUISound(eSUISound_MenuClose);
		return false;
	}

	if(fCurrentTime - m_tLeaderboardsData.fLastFetchTime < class'X2MPData_Shell'.const.LEADERBOARD_REFRESH_TIME)
	{
		`warn(`location @ "Unable to fetch leaderboard data, leaderboard refresh time has not been reached yet.  ("$(fCurrentTime - m_tLeaderboardsData.fLastFetchTime)$" seconds elapsed)");
		m_kShellPres.PlayUISound(eSUISound_MenuClose);
		return false;
	}

	m_tLeaderboardsData.bFetching = true;
	// Reset leaderboard data
	m_tLeaderboardsData.iSelectedIndex = 0;
	m_tLeaderboardsData.iMaxResults = 0;
	m_tLeaderboardsData.strStatusLabel = class'X2MPData_Shell'.default.m_strMPLeaderboardsSearchInProgressLabel;
	m_tLeaderboardsData.arrResults.Remove(0, m_tLeaderboardsData.arrResults.Length); // Clear
	// Read the stats interface
	kStatsInterface = m_OnlineSub.StatsInterface;
	if(kStatsInterface != none)
	{
		if(m_kOnlineStatsRead != none)
		{
			kStatsInterface.FreeStats(m_kOnlineStatsRead);
			m_kOnlineStatsRead = none;
			// HACK: Restart the fetch, after the stats have been freed; unfortunately it takes a full tick (FOnlineAsyncTaskPSNScoreBoardReadBase::Tick)
			// before the cancel happens, it would have been nice to have a "cancel" callback. -ttalley
			SetTimer(0.2, false, nameof(TimerOSSBeginLeaderboardsFetch));
			m_eCachedLeaderboardFetchType = eLeaderBoardType;
			m_CachedLeaderboardFetchStartIndex = StartIndex;
			m_CachedLeaderboardFetchNumResults = NumRows;
			m_tLeaderboardsData.bFetching = false;
			return true; // Skip the creation until the cancel has been performed.
		}
		m_kOnlineStatsRead = new class'XComOnlineStatsReadDeathmatchRanked';
		
		m_tLeaderboardsData.fLastFetchTime = fCurrentTime;
		kStatsInterface.AddReadOnlineStatsCompleteDelegate(OnBeginLeaderboardsFetchComplete);
		switch(m_tLeaderboardsData.eLeaderboardType)
		{
		case eMPLeaderboard_YourRank:
			`log("Accessing Leaderboard Data - YourRank", true, 'XCom_Online');
			bSuccess = kStatsInterface.ReadOnlineStatsByRankAroundPlayer(m_OnlineEventMgr.LocalUserIndex, m_kOnlineStatsRead, NumRows);
			break;
		case eMPLeaderboard_TopPlayers:
			`log("Accessing Leaderboard Data - TopPlayers", true, 'XCom_Online');
			bSuccess = kStatsInterface.ReadOnlineStatsByRank(m_kOnlineStatsRead, StartIndex, NumRows);
			break;
		case eMPLeaderboard_Friends:
			`log("Accessing Leaderboard Data - Friends", true, 'XCom_Online');
			bSuccess = kStatsInterface.ReadOnlineStatsByRankForFriendsList(m_OnlineEventMgr.LocalUserIndex, m_kOnlineStatsRead);
			break;
		}
		if (!bSuccess)
		{
			`log(`location @ "Unable to fetch stats, interface returned false.",,'XCom_Online');
			CancelLeaderboardsFetch();
		}
	}

	return bSuccess;
}

function TimerOSSBeginLeaderboardsFetch()
{
	OSSBeginLeaderboardsFetch(m_eCachedLeaderboardFetchType, m_CachedLeaderboardFetchStartIndex, m_CachedLeaderboardFetchNumResults);
}

function OnBeginLeaderboardsFetchComplete(bool bWasSuccessful)
{
	local delegate<OnLeaderboardFetchComplete> dOnLeaderboardFetchComplete;
	local OnlineStatsInterface kStatsInterface;
	kStatsInterface = m_OnlineSub.StatsInterface;
	if(kStatsInterface != none)
	{
		kStatsInterface.ClearReadOnlineStatsCompleteDelegate(OnBeginLeaderboardsFetchComplete);
	}

	UpdateLeaderboardsData();

	// Trigger delegates
	foreach m_dOnLeaderboardFetchCompleteDelegates(dOnLeaderboardFetchComplete)
	{
		dOnLeaderboardFetchComplete(m_tLeaderboardsData);
	}

	m_tLeaderboardsData.bFetching = false;

	switch ( m_tLeaderboardsData.eLeaderboardType )
	{
		case eMPLeaderboard_TopPlayers:
			m_tLeaderboardsTopPlayersData = m_tLeaderboardsData;
			m_bLeaderboardsTopPlayersDataLoaded = true;
			break;
		case eMPLeaderboard_YourRank:
			m_tLeaderboardsYourRankData = m_tLeaderboardsData;
			m_bLeaderboardsYourRankDataLoaded = true;
			break;
		case eMPLeaderboard_Friends:
			m_tLeaderboardsFriendsData = m_tLeaderboardsData;
			m_bLeaderboardsFriendsDataLoaded = true;
			break;
	}
	m_tLeaderboardsData.fLastFetchTime = WorldInfo.RealTimeSeconds;
}

function CancelLeaderboardsFetch()
{
	if(m_kOnlineStatsRead != none)
	{
		m_OnlineSub.StatsInterface.FreeStats(m_kOnlineStatsRead);
		m_kOnlineStatsRead = none;
	}
	m_OnlineSub.StatsInterface.ClearReadOnlineStatsCompleteDelegate(OnBeginLeaderboardsFetchComplete);
	
	// Reset Leaderboard data
	m_tLeaderboardsData.iSelectedIndex = 0;
	m_tLeaderboardsData.arrResults.Remove(0, m_tLeaderboardsData.arrResults.Length); // Clear
	m_tLeaderboardsData.iMaxResults = m_tLeaderboardsData.arrResults.Length;
	m_tLeaderboardsData.strStatusLabel = class'X2MPData_Shell'.default.m_strMPLeaderboardsNoResultsFoundLabel;
	m_tLeaderboardsData.bFetching = false;
}

//==============================================================================
// 		ONLINE SUBSYSTEM - AUTOMATCH
//==============================================================================
function OnRankedAutomatch()
{
	local TDialogueBoxData kDialogBoxData;

	// TCR # 086: User is able to access all Multiplayer areas with a gamer profile that has multiplayer privileges set to "blocked". -ttalley
	if (m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex) != FPL_Disabled)
	{
		// @TODO tsmith: do we need our own reset?
		//GetShellGRI().ResetToDefaults();
		OnlineGame_SetIsRanked(true);
		m_kShellPres.OSSAutomatchRanked();
	}
	else
	{
		`warn("This account has invalid permissions to access Online Content" $
			", PRI=" $ m_kControllerRef.PlayerReplicationInfo $
			", UniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(m_kControllerRef.PlayerReplicationInfo.UniqueId) $
			", LocalUserNum=" $ m_OnlineEventMgr.LocalUserIndex $
			", LoginStatus=" $ m_OnlineSub.PlayerInterface.GetLoginStatus(m_OnlineEventMgr.LocalUserIndex) $
			", CanPlay=" $ m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex));

		kDialogBoxData = GetOnlinePlayPermissionDialogBoxData();
		m_kShellPres.UIRaiseDialog(kDialogBoxData);
	}
}

function OnUnrankedAutomatch()
{
	local TDialogueBoxData kDialogBoxData;

	// TCR # 086: User is able to access all Multiplayer areas with a gamer profile that has multiplayer privileges set to "blocked". -ttalley
	if (m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex) != FPL_Disabled)
	{
		// @TODO tsmith: do we need our own reset?
		//GetShellGRI().ResetToDefaults();
		OnlineGame_SetIsRanked(false);
		m_kShellPres.OSSAutomatchUnranked();
	}
	else
	{
		`warn("This account has invalid permissions to access Online Content" $
			", PRI=" $ m_kControllerRef.PlayerReplicationInfo $
			", UniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(m_kControllerRef.PlayerReplicationInfo.UniqueId) $
			", LocalUserNum=" $ m_OnlineEventMgr.LocalUserIndex $
			", LoginStatus=" $ m_OnlineSub.PlayerInterface.GetLoginStatus(m_OnlineEventMgr.LocalUserIndex) $
			", CanPlay=" $ m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex));

		kDialogBoxData = GetOnlinePlayPermissionDialogBoxData();
		m_kShellPres.UIRaiseDialog(kDialogBoxData);
	}
}

function OSSBeginOnlineSearch() {
	local XGParamTag kTag;
	local TProgressDialogData kProgressDialogData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	kProgressDialogData.strTitle = class'X2MPData_Shell'.default.m_strMPSearcingForGamesProgressDialogTitle;

	kTag.StrValue0 = Caps(class'XComMPData'.static.GetNetworkTypeName(OnlineGame_GetNetworkType()));
	kProgressDialogData.strDescription = `XEXPAND.ExpandString(class'X2MPData_Shell'.default.m_strMPSearcingForGamesProgressDialogText);

	kProgressDialogData.fnCallback = OSSCancelOnlineSearch;
	m_kShellPres.UIProgressDialog(kProgressDialogData);

	m_kShellPres.OSSFind(CreateOnlineGameSearch(), OSSOnFindOnlineGamesComplete);
}

function OSSCancelOnlineSearch() 
{
	local TProgressDialogData kProgressDialogData;

	kProgressDialogData.strTitle = class'X2MPData_Shell'.default.m_strMPCancelSearchProgressDialogTitle;
	kProgressDialogData.strDescription = class'X2MPData_Shell'.default.m_strMPCancelSearchProgressDialogText;
	kProgressDialogData.strAbortButtonText = ""; // Do not allow cancelling this operation
	kProgressDialogData.fnCallback = none;
	m_kShellPres.UIProgressDialog(kProgressDialogData);

	m_kShellPres.OSSCancelFind(OSSOnCancelFindOnlineGamesComplete);
}

function OSSCancelOnlineSearchDueToConnectionLost(delegate<OnlineGameInterface.OnCancelFindOnlineGamesComplete> OnCancelFindOnlineGamesCompleteDelegate) 
{
	m_kShellPres.OSSCancelFind(OnCancelFindOnlineGamesCompleteDelegate);
}

function OSSRefreshOnCancelFindOnlineGamesComplete(bool bWasSuccessful)
{
	m_OnlineSub.GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSRefreshOnCancelFindOnlineGamesComplete);
	if(bWasSuccessful)
	{
		m_kShellPres.m_bOnlineGameSearchInProgress = false;
		OSSBeginOnlineSearch();
	}
	else
	{
		// @TODO tsmith: Redscreen instead?
		// This is probably really bad.
		m_kShellPres.PopupDebugDialog("UI ERROR", "XComMultiplayerUI::OSSRefreshOnCancelFindOnlineGamesComplete - failed to cancel online search."$
												  "\nPlease inform the UI team and provide a log with 'uixcom' and 'XCom_Online' unsuppressed.");
		`log(self $ "::" $ GetFuncName() @ "Refresh : CancelFindOnlineGames failed!", true, 'XCom_Online');
	}
}

function OSSJoin(int iGameIndex)
{
	local XGParamTag kTag;
	local TProgressDialogData kProgressDialogData;
	local OnlineGameSearchResult kGameResult;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	m_iServerBrowserJoinGameSearchResultsIndex = iGameIndex;

	//use the new GameSearchResultCache instead of m_kShellPres.m_kOnlineGameSearch, if refresh was canceled m_kShellPres.m_kOnlineGameSearch would be wiped out
	if(arrOnlineGameSearchResultCache.Length > 0)
	{
		if(iGameIndex >= 0 && iGameIndex < arrOnlineGameSearchResultCache.Length)
		{
			kGameResult = arrOnlineGameSearchResultCache[iGameIndex];
			m_bInProcessOfJoiningGame = true;

			kProgressDialogData.strTitle = class'X2MPData_Shell'.default.m_strMPJoiningGameProgressDialogTitle;
			kTag.StrValue0 = kGameResult.GameSettings.OwningPlayerName;
			kProgressDialogData.strDescription = `XEXPAND.ExpandString(class'X2MPData_Shell'.default.m_strMPJoiningGameProgressDialogText);
			m_kShellPres.UIProgressDialog(kProgressDialogData);

			m_kShellPres.AddPreClientTravelDelegate(OnPreClientTravel);
			m_OnlineSub.GameInterface.AddDestroyOnlineGameCompleteDelegate(OnFailToJoinGame);
			m_kShellPres.OSSJoin(kGameResult, OSSJoinOnlineGameCompleted, OSSOnDestroyOnlineGameForJoinGame);
		}
		else
		{
			`log(self $ "::" $ GetFuncName() @ "Invalid game index!", true, 'XCom_Online');
		}
	}
	else
	{
		`log(self $ "::" $ GetFuncName() @ "No online games to join", true, 'XCom_Online');
	}

}


/**
 * Delegate fired when a destroying an online game has completed
 *
 * @param SessionName the name of the session this callback is for
 * @param bWasSuccessful true if the async action completed without error, false if there was an error
 */
function OSSOnDestroyOnlineGameForJoinGame(name SessionName,bool bWasSuccessful)
{
	m_OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OSSOnDestroyOnlineGameForJoinGame);
	OSSJoin(m_iServerBrowserJoinGameSearchResultsIndex);
}

public function SetupGameSearch(XComOnlineGameSearch kGameSearch)
{
	local int iSquadCostMin, iSquadCostMax;
	local int iTurnTimeMin, iTurnTimeMax;
	local int iMapPlotMin, iMapPlotMax;
	local int iMapBiomeMin, iMapBiomeMax;

	kGameSearch.SetNetworkType(OnlineGame_GetNetworkType());
	kGameSearch.SetGameType(OnlineGame_GetType());
	kGameSearch.SetIsRanked(OnlineGame_GetIsRanked());

	//
	// POINTS
	if (OnlineGame_GetMaxSquadCost() != class'X2MPData_Common'.const.ANY_VALUE)
	{
		iSquadCostMin = OnlineGame_GetMaxSquadCost();
		iSquadCostMax = OnlineGame_GetMaxSquadCost();
	}
	else
	{
		iSquadCostMin = MinInt;
		iSquadCostMax = MaxInt;
	}
	kGameSearch.SetSquadCostMin(iSquadCostMin);
	kGameSearch.SetSquadCostMax(iSquadCostMax);

	//
	// TURN TIME
	if (OnlineGame_GetTurnTimeSeconds() != class'X2MPData_Common'.const.ANY_VALUE)
	{
		iTurnTimeMin = OnlineGame_GetTurnTimeSeconds();
		iTurnTimeMax = OnlineGame_GetTurnTimeSeconds();
	}
	else
	{
		iTurnTimeMin = MinInt;
		iTurnTimeMax = MaxInt;
	}
	kGameSearch.SetTurnTimeMin(iTurnTimeMin);
	kGameSearch.SetTurnTimeMax(iTurnTimeMax);

	//
	// MAP PLOT TYPE
	if (OnlineGame_GetMapPlotInt() != class'X2MPData_Common'.const.ANY_VALUE)
	{
		iMapPlotMin = OnlineGame_GetMapPlotInt();
		iMapPlotMax = OnlineGame_GetMapPlotInt();
	}
	else
	{
		iMapPlotMin = MinInt;
		iMapPlotMax = MaxInt;
	}

	kGameSearch.SetMapPlotTypeMinMax(iMapPlotMin, iMapPlotMax);

	//
	// MAP BIOME TYPE
	if (OnlineGame_GetMapBiomeInt() != class'X2MPData_Common'.const.ANY_VALUE)
	{
		iMapBiomeMin = OnlineGame_GetMapBiomeInt();
		iMapBiomeMax = OnlineGame_GetMapBiomeInt();
	}
	else
	{
		iMapBiomeMin = MinInt;
		iMapBiomeMax = MaxInt;
	}

	kGameSearch.SetMapBiomeTypeMinMax(iMapBiomeMin, iMapBiomeMax);
}

function XComOnlineGameSearch CreateOnlineGameSearch()
{
	local XComOnlineGameSearch kGameSearch;

	switch(OnlineGame_GetType())
	{
	case eMPGameType_Deathmatch:
		kGameSearch = new class'XComOnlineGameSearchDeathmatchCustom';
		SetupGameSearch(kGameSearch);
		break;
	default:
		`log(`location @ "Deathmatch is the only game type currently supported", true, 'XCom_Online');
	}

	`log(`location @ `ShowVar(kGameSearch), true, 'XCom_Online');
	return kGameSearch;
}

/**
 * Builds the string needed to join a game from the resolved connection:
 *		"open 172.168.0.1"
 *
 * NOTE: Overload this method to modify the URL before exec-ing it
 *
 * @param sResolvedConnectionURL the platform specific URL information
 *
 * @return the final URL to use to open the map
 */
function string BuildJoinURL(string sResolvedConnectionURL)
{
	local string sConnectURL;

	sConnectURL = "open " $ sResolvedConnectionURL;

	return sConnectURL;
}

function UpdateLeaderboardsData()
{
	local int iRowIdx, iEntryIdx;
	local XComOnlineStatsReadDeathmatchRanked kStats;
	local UniqueNetId iID;
	local XComOnlineEventMgr OnlineEventMgr;

	if (m_kOnlineStatsRead == none) // Player not logged-in
		return;

	OnlineEventMgr = `ONLINEEVENTMGR;

	kStats = XComOnlineStatsReadDeathmatchRanked(m_kOnlineStatsRead);

	// Reset Leaderboard data
	m_tLeaderboardsData.iSelectedIndex = 0;
	m_tLeaderboardsData.arrResults.Remove(0, m_tLeaderboardsData.arrResults.Length); // Clear
	
	for (iRowIdx = 0; iRowIdx < kStats.Rows.Length; ++iRowIdx)
	{
		// Add entry to the board
		m_tLeaderboardsData.arrResults.Add(1);

		// Setup the entry
		iID = kStats.Rows[iRowIdx].PlayerId;

		m_tLeaderboardsData.arrResults[iEntryIdx].strPlayerName = kStats.Rows[iRowIdx].NickName;
		m_tLeaderboardsData.arrResults[iEntryIdx].iRank = kStats.GetRankForPlayer(iID);
		m_tLeaderboardsData.arrResults[iEntryIdx].playerID = iID;
		m_tLeaderboardsData.arrResults[iEntryIdx].iWins = kStats.GetRankedMatchesWonForPlayer(iID);
		m_tLeaderboardsData.arrResults[iEntryIdx].iLosses = kStats.GetRankedMatchesLostForPlayer(iID);
		m_tLeaderboardsData.arrResults[iEntryIdx].iDisconnects = kStats.GetDisconnectsForPlayer(iID) + ((kStats.DidPlayerCompleteLastRankedmatch(iID) > 0) ? 1 : 0); // Add a did not complete match as a disconnect

		// Find the correct player info in the cache
		if (OnlineEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_kUniqueID == iID)
		{
			// Check that the cache data is newer
			if ((OnlineEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iWins
				+OnlineEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iLosses
				+OnlineEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iDisconnects)
				> 
				(m_tLeaderboardsData.arrResults[iEntryIdx].iWins
				+m_tLeaderboardsData.arrResults[iEntryIdx].iLosses
				+m_tLeaderboardsData.arrResults[iEntryIdx].iDisconnects))
			{
				// Data is newer, overwrite the results
				m_tLeaderboardsData.arrResults[iEntryIdx].iWins = OnlineEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iWins;
				m_tLeaderboardsData.arrResults[iEntryIdx].iLosses = OnlineEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iLosses;
				m_tLeaderboardsData.arrResults[iEntryIdx].iDisconnects = OnlineEventMgr.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_iDisconnects;
			}
		}
		/* Wait until we implement the remote player caching ... which may be never -ttalley
		else if (OnlineEventMgr.m_kMPLastMatchInfo.m_kRemotePlayerInfo.m_kUniqueID == iID)
		{
			// Check that the cache data is newer
			if ((OnlineEventMgr.m_kMPLastMatchInfo.m_kRemotePlayerInfo.m_iWins
				+OnlineEventMgr.m_kMPLastMatchInfo.m_kRemotePlayerInfo.m_iLosses
				+OnlineEventMgr.m_kMPLastMatchInfo.m_kRemotePlayerInfo.m_iDisconnects)
				> 
				(m_tLeaderboardsData.arrResults[iEntryIdx].iWins
				+m_tLeaderboardsData.arrResults[iEntryIdx].iLosses
				+m_tLeaderboardsData.arrResults[iEntryIdx].iDisconnects))
			{
				// Data is newer, overwrite the results
				m_tLeaderboardsData.arrResults[iEntryIdx].iWins = OnlineEventMgr.m_kMPLastMatchInfo.m_kRemotePlayerInfo.m_iWins;
				m_tLeaderboardsData.arrResults[iEntryIdx].iLosses = OnlineEventMgr.m_kMPLastMatchInfo.m_kRemotePlayerInfo.m_iLosses;
				m_tLeaderboardsData.arrResults[iEntryIdx].iDisconnects = OnlineEventMgr.m_kMPLastMatchInfo.m_kRemotePlayerInfo.m_iDisconnects;
			}
		}
		*/

		`log("Adding Leaderboard Data:"
			 @ " strPlayerName '" $ m_tLeaderboardsData.arrResults[iEntryIdx].strPlayerName $ "'"
			 @ " iScore" @ kStats.GetScoreForPlayer(iID)
			 @ " iRank" @ m_tLeaderboardsData.arrResults[iEntryIdx].iRank
			 @ " playerID" @ m_tLeaderboardsData.arrResults[iEntryIdx].playerID.Uid.A $ m_tLeaderboardsData.arrResults[iEntryIdx].playerID.Uid.B
			 @ " iWins" @ m_tLeaderboardsData.arrResults[iEntryIdx].iWins
			 @ " iLosses" @ m_tLeaderboardsData.arrResults[iEntryIdx].iLosses
			 @ " iDisconnects" @ m_tLeaderboardsData.arrResults[iEntryIdx].iDisconnects
			 , true, 'XCom_Online');

		++iEntryIdx;
	}

	//adjust status label to account for if player was excluded from Friend Ranks leaderboard, was checking against kStats.Rows[] before
	m_tLeaderboardsData.strStatusLabel = (m_tLeaderboardsData.arrResults.Length > 0) ? "" : class'X2MPData_Shell'.default.m_strMPLeaderboardsNoResultsFoundLabel;

	// Right now these are 1 for 1, but if we allow for arrResults to grow due to
	// subsequent requests then iMaxResults will be true maximum
	m_tLeaderboardsData.iMaxResults = m_tLeaderboardsData.arrResults.Length;
}

// @TODO tsmith: implement using the new UI code
// This function is aware of what screen the user is in and is responsible for returning the user to the MP Menu if 
// they lose connectivity to online services. By passing in a QuitReason, we can reuse this function for when the Ethernet Link
// is lost, as well as general online connectivity errors.
function HandleOnlineConnectionLost(EQuitReason Reason)
{
	local OnlineGameSettings GameSettings;
	local OnlineSubsystem OnlineSub;
	local TProgressDialogData kProgressDialogData;

	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();

	if (OnlineSub != None && OnlineSub.GameInterface != None)
	{
		GameSettings = OnlineSub.GameInterface.GetGameSettings(m_kControllerRef.PlayerReplicationInfo.SessionName);
	}

	`log(`location @ "->" @ `ShowVar(m_kShellPres.GetStateName(), CurrentPresState) @ `ShowVar(Reason, QuitReason) @ `ShowVar(m_bPassedNetworkConnectivityCheck) @ `ShowVar(m_bPassedOnlineConnectivityCheck),,'XCom_Online');

	// HANDLE CONNECTION ERRORS WITHIN MULTIPLAYER LOBBY 
	if(m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_Lobby'))
	{
		// do nothing if we are in a lan lobby and we have a low level connection -tsmith
		if(!(GameSettings.bIsLanMatch && m_bPassedNetworkConnectivityCheck))
		{
			m_OnlineEventMgr.ReturnToMPMainMenu(Reason);
		}
		return;
	}

	// HANDLE CONNECTION ERRORS IN OFFLINE SQUAD EDITOR (We do nothing) 
	if(m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_SquadEditor_Preset') || m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_SquadLoadoutList_Preset'))
	{
		if(m_bPassedNetworkConnectivityCheck)
			m_kShellPres.UIRaiseDialog(GetOnlineNoNetworkConnectionDialogBoxData());
		else
			m_kShellPres.UIRaiseDialog(GetOnlineConnectionFailedDialogData());

		return;
	}

	// HANDLE CONNECTION ERRORS WHEN AUTOMATCHING
	if(m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_SquadLoadoutList_QuickMatch') || 
		m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_SquadLoadoutList_RankedGame') || 
		m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_SquadLoadoutList_CustomGameCreate') || 
		m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_SquadLoadoutList_CustomGameSearch') || 
		m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_CustomGameCreateMenu') ||
		m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_CustomGameMenu_Search'))
	{
		if(m_kShellPres.m_bOnlineGameSearchInProgress)
		{
			m_eCancelFindGamesQuitReason = Reason;
			kProgressDialogData.strTitle = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_Default_Title;
			kProgressDialogData.strDescription = m_strCancelGameSearchDueToLostConnection;
			kProgressDialogData.strAbortButtonText = ""; // Do not allow cancelling this operation
			kProgressDialogData.fnCallback = none;
			m_kShellPres.UIProgressDialog(kProgressDialogData);
			OSSCancelOnlineSearchDueToConnectionLost(OSSOnCancelFindOnlineGamesCompleteDueToConnectionLost);
		}
		else
		{
			m_OnlineEventMgr.ReturnToMPMainMenu(Reason);
		}
		return;
	}

	// HANDLE LEADERBOARD
	if(m_kShellPres.ScreenStack.IsInStack(class'UIMPShell_Leaderboards'))
	{
		if(m_tLeaderboardsData.bFetching)
		{
			CancelLeaderboardsFetch();	
		}
		m_OnlineEventMgr.ReturnToMPMainMenu(Reason);
		return;
	}

	//// If we're in the menus and we get an ethernet plug, we will get two messages: LostConnection & LostLinkConnection
	//// In order to properly sanitize the messages, we need to wait until we get both LostConnection & LostLinkConnection messages.
	//// Delaying the  message processing should let us make sure we have all messages required for the Sanitation step.
	//if(m_kShellPres.ScreenStack.IsInStack(class'UIMultiplayerShell'))
	//{
	//	`log("DELAYING DISPLAY OF SYSTEM MESSAGES",,'XCom_Online');
	//	// Make sure we don't activate the messages until the timer triggers
	//	m_kShellPres.m_bBlockSystemMessageDisplay = true;
	//	SetTimer(0.1, false, nameof(ProcessDelayedSystemMessages));
	//}

	m_OnlineEventMgr.QueueSystemMessage(m_OnlineEventMgr.GetSystemMessageForQuitReason(Reason));
}

function ProcessDelayedSystemMessages()
{
	`log("NOW DISPLAYING SYSTEM MESSAGES",,'XCom_Online');
	m_kShellPres.m_bBlockSystemMessageDisplay = false;
	m_kShellPres.ProcessSystemMessages();
}

// Dialog box helpers
//------------------------------------------------------------------------------
function DisplayGeneralConnectionErrorDialog()
{
	if( !m_OnlineSub.SystemInterface.HasLinkConnection() )
	{
		m_kShellPres.UIRaiseDialog(GetOnlineNoNetworkConnectionDialogBoxData());
	}
	else
	{
		if (m_bPassedOnlineConnectivityCheck && 
			m_OnlineSub.PlayerInterface.CanPlayOnline(m_OnlineEventMgr.LocalUserIndex) == FPL_Disabled)
		{
			m_kShellPres.UIRaiseDialog(GetOnlinePlayPermissionDialogBoxData());
		}
		else
		{
			if (WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))
			{
				m_kShellPres.UIRaiseDialog(GetOnlineLoginFailedDialogData());
			}
			else if (WorldInfo.IsConsoleBuild(CONSOLE_PS3))
			{
				m_OnlineSub.PlayerInterface.AddLoginUICompleteDelegate(OnLoginUIComplete);
				if (!m_OnlineSub.PlayerInterface.ShowLoginUI(true)) // Show Online Only
				{
					m_OnlineSub.PlayerInterface.ClearLoginUICompleteDelegate(OnLoginUIComplete);
				}
			}
		}
	}
}

function TDialogueBoxData GetOnlineConnectionFailedDialogData()
{
	local TDialogueBoxData kDialogBoxData;

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineConnectionFailedDialog_XBOX_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineConnectionFailedDialog_XBOX_Text;
	}
	else
	{	
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineConnectionFailedDialog_Default_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineConnectionFailedDialog_Default_Text;
	}
	kDialogBoxData.strAccept = class'X2MPData_Shell'.default.m_strOnlineConnectionFailedDialog_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.eType = eDialog_Warning;

	return kDialogBoxData;
}

function TDialogueBoxData GetOnlineNoNetworkConnectionDialogBoxData()
{
	local TDialogueBoxData kDialogBoxData;

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_XBOX_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_XBOX_Text;
	}
	else if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_PS3_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_PS3_Text;
	}
	else
	{	
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_Default_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_Default_Text;
	}
	kDialogBoxData.strAccept = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.eType = eDialog_Warning;

	return kDialogBoxData;
}

function TDialogueBoxData GetOnlinePlayPermissionDialogBoxData()
{
	local TDialogueBoxData kDialogBoxData;

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_XBOX_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_XBOX_Text;
	}
	else if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
	{
		kDialogBoxData.strTitle = "";
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_PS3_Text;
	}
	else
	{	
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_Default_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_Default_Text;
	}
	kDialogBoxData.strAccept = class'X2MPData_Shell'.default.m_strOnlinePlayPermissionFailedDialog_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.eType = eDialog_Warning;

	return kDialogBoxData;
}

function TDialogueBoxData GetOnlineChatPermissionDialogBoxData()
{
	local TDialogueBoxData kDialogBoxData;

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineChatPermissionFailedDialog_Default_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineChatPermissionFailedDialog_XBOX_Text;
	}
	else if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineChatPermissionFailedDialog_PS3_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineChatPermissionFailedDialog_PS3_Text;
	}
	else
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineChatPermissionFailedDialog_Default_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineChatPermissionFailedDialog_Default_Text;
	}
	kDialogBoxData.strAccept = class'X2MPData_Shell'.default.m_strOnlineChatPermissionFailedDialog_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.eType = eDialog_Warning;

	return kDialogBoxData;
}

function TDialogueBoxData GetOnlineLoginFailedDialogData()
{
	local TDialogueBoxData kDialogBoxData;

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineLoginFailedDialog_XBOX_Text;
	}
	else if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
	{
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineLoginFailedDialog_PS3_Text;
	}
	else
	{	
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineLoginFailedDialog_Default_Text;
	}
	kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineLoginFailedDialog_Default_Title;
	kDialogBoxData.strAccept = class'X2MPData_Shell'.default.m_strOnlineLoginFailedDialog_ButtonText;
	// only one button, hence the empty string for this button text -tsmith 
	kDialogBoxData.strCancel = "";
	kDialogBoxData.eType = eDialog_Warning;

	return kDialogBoxData;
}



defaultproperties
{
	m_iServerBrowserJoinGameSearchResultsIndex = -1;
	m_bInProcessOfJoiningGame=false
}