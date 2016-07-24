//---------------------------------------------------------------------------------------
//  FILE:    XComOnlineProfileSettings.uc
//  AUTHOR:  Ryan McFall  --  08/17/2011
//  PURPOSE: This object stores properties that are supposed to exist in a player's 
//           roaming gamer profile. Stuff like look controller preferences, achievements,
//           campaign progress, etc. This is space / complexity limited on some platforms
//           such as XBox Live.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComOnlineProfileSettings extends OnlineProfileSettings
	dependson(XComOnlineProfileSettingsDataBlob)
	native(Core)
	config(Game);

const MAX_CONVERSION_ATTEMPTS = 3;

var XComOnlineProfileSettingsDataBlob Data; //Serialized into the player's profile ( online storage or local files )

var config bool bSaveImageCaptureManagerImages; //If TRUE, the image capture images will be stored in saved games

//X-Com 2
//==========================================================================================
var array<XComGameState>        MultiplayerLoadoutGameStates; // Each GameState includes all units, items, etc. for that single loadout.
var private XComGameState       CurrentLoadoutGameState;
var bool                        SessionAttemptedMy2KConversion;
//==========================================================================================

/// <summary>
/// Called immediately before writing the profile. Allows systems to update the profile at the time it is written
/// </summary>
function PreSaveData()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	
	History = `XCOMHISTORY;
	
	//Update the profile's campaign index if the current game's index is higher
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none && 
	   CampaignSettingsStateObject.GameIndex > `XPROFILESETTINGS.Data.m_iGames)
	{
		Data.m_iGames = CampaignSettingsStateObject.GameIndex;
	}

	class'X2CardManager'.static.GetCardManager().SaveDeckData(Data.SavedCardDecks);
}

/// <summary>
/// Called immediately after reading the profile. Allows systems to update themselves at the point the profile is read
/// </summary>
function PostLoadData()
{
	class'X2CardManager'.static.GetCardManager().LoadDeckData(Data.SavedCardDecks);
}

//******************************************************************************************
// Extended tactical launch - single player - functions
function ExtendedLaunch_InitToDefaults()
{
	local XComGameStateHistory History;
	local XComGameState TacticalGameStartState;
	local XComGameStateContext_TacticalGameRule StateChangeContext;

	if( Data == none )
	{
		Data = new(self) class'XComOnlineProfileSettingsDataBlob'; 

		//Mouse defaults to deactivated for consoles, but we want it to default active for PC. 
		data.m_bIsConsoleBuild = `GAMECORE.WorldInfo.IsConsoleBuild();

		//In Japanese or Korean, default to the subtitles on. 
		// Also in Simplified and traditionsl chinese
		if( GetLanguage() == "JPN" || GetLanguage() == "KOR" || GetLanguage() == "CHT" || GetLanguage() == "CHN")
		{
			data.m_bSubtitles = true; 
			ApplyUIOptions();
		}
		else
		{	
			data.m_bSubtitles = false; 
			ApplyUIOptions();
		}
	}
	
	//=============== Create a new tactical game start state =================
	History = `XCOMHISTORY;	
		
	StateChangeContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	StateChangeContext.GameRuleType = eGameRule_TacticalGameStart;
	TacticalGameStartState = History.CreateNewGameState(false, StateChangeContext);	
	
	//Add basic states to the start state ( battle, players, abilities, etc. )
	AddDefaultStateObjectsToStartState(TacticalGameStartState);

	//Fill the state with a set of default soldiers.
	AddDefaultSoldiersToStartState(TacticalGameStartState);
	

	//Write the new settings into the profile data
	WriteTacticalGameStartState(TacticalGameStartState);

	History.CleanupPendingGameState(TacticalGameStartState);
	//========================================================================

	// wipe all stats
	
	MPLoadoutSquads_InitToDefaults();

	Data.m_fGamma = GetGammaNative();
}

/// <summary>
/// AddDefaultSoldiersToStartState fills a given XComGameState with a set of soldiers intended to serve
/// as default settings for the tactical game.
/// </summary>
/// <param name="StartState">The state that will be filled with default soldiers. Should be empty of other soldiers</param>
static function AddDefaultSoldiersToStartState(XComGameState StartState, optional ETeam ePlayerTeam=eTeam_XCom)
{
	local XGCharacterGenerator CharacterGenerator;	
	local XComGameState_Unit BuildUnit;
	local XComGameState_Player TeamXComPlayer;
	local X2CharacterTemplate CharTemplate;
	local TSoldier Soldier;
	local int SoldierIndex;	

	//Find the player associated with the player's team
	foreach StartState.IterateByClassType(class'XComGameState_Player', TeamXComPlayer, eReturnType_Reference)
	{
		if( TeamXComPlayer != None && TeamXComPlayer.TeamFlag == ePlayerTeam )
		{
			break;
		}
	}

	CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Soldier');
	`assert(CharTemplate != none);
	CharacterGenerator = `XCOMGRI.Spawn(CharTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	for (SoldierIndex = 0; SoldierIndex < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(); ++SoldierIndex)
	{
		BuildUnit = CharTemplate.CreateInstanceFromTemplate(StartState);
		//  special hack to allow these soldiers to carry two utility items instead of just one (which is the default)
		BuildUnit.SetBaseMaxStat(eStat_UtilityItems, 2);
		BuildUnit.SetCurrentStat(eStat_UtilityItems, 2);
		if( TeamXComPlayer != None )
			BuildUnit.SetControllingPlayer( TeamXComPlayer.GetReference() );
		BuildUnit = XComGameState_Unit(StartState.AddStateObject(BuildUnit));

		Soldier = CharacterGenerator.CreateTSoldier();
		BuildUnit.SetTAppearance(Soldier.kAppearance);
		BuildUnit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
		BuildUnit.SetCountry(Soldier.nmCountry);
		if(!BuildUnit.HasBackground())
			BuildUnit.GenerateBackground();

		BuildUnit.ApplyInventoryLoadout(StartState);
	}
	CharacterGenerator.Destroy();
}

/// <summary>
/// Adds ancillary state objects to the tactical start state. Players, battle data, and others.
/// </summary>
/// <param name="StartState">The state that will be filled with default soldiers. Should be empty of other soldiers</param>
static function AddDefaultStateObjectsToStartState(XComGameState StartState)
{	
	local XComGameState_BattleData BattleDataState;
	local XComGameState_Player AddPlayerState;	
	local XComGameState_Cheats CheatState;

	BattleDataState = XComGameState_BattleData(StartState.CreateStateObject(class'XComGameState_BattleData'));	
	BattleDataState.iLevelSeed = class'Engine'.static.GetEngine().GetSyncSeed();
	BattleDataState = XComGameState_BattleData(StartState.AddStateObject(BattleDataState));

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_XCom);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());
	StartState.AddStateObject(AddPlayerState);

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Alien);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());
	StartState.AddStateObject(AddPlayerState);

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Neutral);
	BattleDataState.CivilianPlayerRef = AddPlayerState.GetReference();
	StartState.AddStateObject(AddPlayerState);

	CheatState = XComGameState_Cheats(StartState.CreateStateObject(class'XComGameState_Cheats'));
	StartState.AddStateObject(CheatState);
}

function HACK_RemoveInstanceDataFromGameState(out XComGameState StartState)
{
	local XComGameState_BaseObject StateObject;

	// clean up all state objects by calling EndTacticalPlay on them.  This IS a HACK
	foreach StartState.IterateByClassType(class'XComGameState_BaseObject',StateObject)
	{
		StateObject.EndTacticalPlay();
	}
}

event WriteTacticalGameStartState(XComGameState StartState)
{
	if( StartState != none )
	{
		HACK_RemoveInstanceDataFromGameState(StartState);
		// Write the new settings to the profile
		class'XComGameState'.static.WriteToByteArray(StartState, Data.TacticalGameStartState);
	}
}

event ReadTacticalGameStartState(XComGameState OutStartState)
{
	if( OutStartState != none )
	{
		// Write the new settings to the profile
		class'XComGameState'.static.ReadFromByteArray(OutStartState, Data.TacticalGameStartState);
	}
}

native function MPWriteLoadoutGameStates(array<XComGameState> GameStates, out array<byte> OutSerialized);
native function MPReadLoadoutGameStates(array<byte> InSerialized, out array<XComGameState> OutGameStates);

function string GetEmptyContextString()
{
	return "TEMP_EMPTY";
}

function X2MPReadLoadoutGameStates(out array<XComGameState> OutGameStates)
{
	OutGameStates.Length = 0;
	MPReadLoadoutGameStates(Data.X2MPLoadoutGameStates, OutGameStates);  
}

function X2MPWriteLoadoutGameStates(array<XComGameState> GameStates)
{
	Data.X2MPLoadoutGameStates.Length = 0;
	MPWriteLoadoutGameStates(GameStates, Data.X2MPLoadoutGameStates);
}

function X2MPReadTempLobbyLoadout(out XComGameState OutLoadoutState)
{
	if(OutLoadoutState != none)
	{
		if( Data.X2MPTempLobbyLoadout.Length > 0 )
		{
			class'XComGameState'.static.ReadFromByteArray(OutLoadoutState, Data.X2MPTempLobbyLoadout);
		}
		else
		{
			`warn(`location @ "X2MPTempLobbyLoadout is empty!");
		}
	}
	else
	{
		`warn(self $ "::" $ GetFuncName() @ "Loadout is none");
	}
}

function X2MPWriteTempLobbyLoadout(XComGameState LoadoutState)
{
	if(LoadoutState != none)
	{
		class'XComGameState'.static.WriteToByteArray(LoadoutState, Data.X2MPTempLobbyLoadout);
	}
	else
	{
		`warn(self $ "::" $ GetFuncName() @ "Loadout is none");
	}
}

function X2MPReadUnitPresets(out array<TX2UnitPresetData> OutUnitPresets)
{
	OutUnitPresets = Data.X2MPUnitPresetData;
}

function X2MPWriteUnitPresets(array<TX2UnitPresetData> UnitPresets)
{
	Data.X2MPUnitPresetData = UnitPresets;
}

//Called by the profile reader if the profile has been corrupted or is not present
event SetToDefaults()
{
	super.SetToDefaults();

	ExtendedLaunch_InitToDefaults();
}

simulated function ApplyOptionsSettings()
{
	ApplyAudioOptions();
	ApplyUIOptions();

	// KDERDA - don't think we need gamma on the online profile, but not removing altogether just in case
	//ApplyVideoOptions(); 
}

simulated function ApplyAudioOptions()
{
	//class'Engine'.Static.GetAudioDevice().TransientMasterVolume = Data.m_iMasterVolume/100.0f;
	SetGlobalAudioVolume(Data.m_iMasterVolume/100.0f);
	class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().SetAudioGroupVolume('Voice', Data.m_iVoiceVolume/100.0f);
	class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().SetAudioGroupVolume('SoundFX', Data.m_iFXVolume/100.0f);
	class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().SetAudioGroupVolume('Music', Data.m_iMusicVolume/100.0f);
	class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().SetAudioGroupVolume('CinematicSound', Data.m_iMusicVolume/100.0f);
	if (class'Engine'.static.GetOnlineSubsystem().VoiceInterface != none)
		class'Engine'.static.GetOnlineSubsystem().VoiceInterface.SetRemoteVoiceVolume(Data.m_iVOIPVolume/100.0f);
}

function Options_ResetToDefaults(bool bInShell)
{
	Data.Options_ResetToDefaults( bInShell );
	Data.m_fGamma = GetGammaNative();
}
simulated function ApplyUIOptions()
{
	`XENGINE.bSubtitlesEnabled = Data.m_bSubtitles;
}

simulated native function float GetGammaNative();
simulated native function SetGammaNative(float NewGamma);

simulated function ApplyVideoOptions()
{
	SetGammaNative(Data.m_fGamma);
}

native function SetGlobalAudioVolume(float fVolume);

// End extended tactical launch - single player - functions
//******************************************************************************************


//******************************************************************************************
// Squad Loadouts - multiplayer - functions
simulated function MPLoadoutSquads_InitToDefaults()
{
	local XComGameState LoadoutState;

	// TODO: different loadout state, then allow the player to modify that in the squad editor -tsmith
	LoadoutState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Multiplayer();
	
	//Fill the state with a set of default soldiers.
	AddDefaultSoldiersToStartState(LoadoutState);
	

	//Write the new settings into the profile data
	//MPWriteLoadoutGameState(LoadoutState);
	// TODO: this is just to hack around the fact that we cant combine the 2 players' loadout states into the start state yet.
	// we will do that when receiving loadouts. until then we just fake it with this loadout state. -tsmith
	//MPWriteTacticalGameStartState(LoadoutState);

	`XCOMHISTORY.CleanupPendingGameState(LoadoutState);
}

simulated function int GetLoadoutUnitCount()
{
	return XComGameStateContext_SquadSelect(CurrentLoadoutGameState.GetContext()).GetUnitCount();
}

simulated function XComGameState_Unit GetLoadoutUnit(int iIndex)
{
	return XComGameStateContext_SquadSelect(CurrentLoadoutGameState.GetContext()).GetUnitAtLocation(iIndex);
}

simulated function int GetLoadoutCount()
{
	return MultiplayerLoadoutGameStates.Length;
}

simulated function XComGameStateContext_SquadSelect GetLoadout(int iIndex)
{
	return XComGameStateContext_SquadSelect(MultiplayerLoadoutGameStates[iIndex].GetContext());
}

simulated function int GetLoadoutIndexFromId(int iLoadoutId)
{
	local XComGameStateContext_SquadSelect SquadSelect;
	local int i;
	for (i = 0; i < MultiplayerLoadoutGameStates.Length; ++i)
	{
		SquadSelect = XComGameStateContext_SquadSelect(MultiplayerLoadoutGameStates[i].GetContext());
		if (iLoadoutId == SquadSelect.iLoadoutId)
		{
			return i;
		}
	}
	return -1;
}

simulated function XComGameStateContext_SquadSelect GetLoadoutFromId(int iLoadoutId)
{
	local int index;
	index = GetLoadoutIndexFromId(iLoadoutId);
	return XComGameStateContext_SquadSelect(MultiplayerLoadoutGameStates[index].GetContext());
}

simulated function int GetLoadoutId(int iIndex)
{
	return GetLoadout(iIndex).iLoadoutId;
}

simulated function int GetCurrentLoadoutId()
{
	return Data.m_iLastUsedMPLoadoutId;
}

simulated function SetLoadoutGameStateFromId(XComGameState kGameState, int iLoadoutId)
{
	local int iIndex;
	iIndex = GetLoadoutIndexFromId(iLoadoutId);
	if (iIndex >= 0 && iIndex < MultiplayerLoadoutGameStates.Length)
	{
		MultiplayerLoadoutGameStates[iIndex] = kGameState;
	}
}

simulated function SetCurrentLoadout(int iIndex)
{
	Data.m_iLastUsedMPLoadoutId = GetLoadoutId(iIndex);
	CurrentLoadoutGameState = MultiplayerLoadoutGameStates[iIndex];
}

simulated function SetCurrentLoadoutId(int iLoadoutId)
{
	Data.m_iLastUsedMPLoadoutId = iLoadoutId;
	CurrentLoadoutGameState = GetLoadoutFromId(iLoadoutId).AssociatedState;
}

simulated function int GetDefaultLoadoutId()
{
	return -1;
}

simulated function string GetCurrentLoadoutName()
{
	return GetLoadoutName(Data.m_iLastUsedMPLoadoutId);
}

simulated function SetLoadoutName(int iLoadoutId, string strNewName)
{
	GetLoadoutFromId(iLoadoutId).strLoadoutName = strNewName;
}

simulated function string GetLoadoutName(int iLoadoutId)
{
	return GetLoadoutFromId(iLoadoutId).strLoadoutName;
}

simulated function string GetLoadoutLanguage(int iLoadoutId)
{
	return GetLoadoutFromId(iLoadoutId).strLanguageCreatedWith;
}

simulated function int GetNextLoadoutId()
{
	local XComGameStateContext_SquadSelect kSquadSelect;
	local int iHighestId, i;
	iHighestId = 0;
	for (i = 0; i < MultiplayerLoadoutGameStates.Length; ++i)
	{
		kSquadSelect = XComGameStateContext_SquadSelect(MultiplayerLoadoutGameStates[i].GetContext());
		iHighestId = Max(iHighestId, kSquadSelect.iLoadoutId);
	}
	return iHighestId + 1;
}

simulated function XComGameState CreateSquadSelectState(int iLoadoutId, string strNewLoadoutName, string strLanguage)
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

simulated function int CreateNewLoadout(string strNewLoadoutName)
{
	local XComGameState kSquadState;

	kSquadState = CreateSquadSelectState(GetNextLoadoutId(), strNewLoadoutName, GetLanguage());
	MultiplayerLoadoutGameStates.AddItem(kSquadState);

	return XComGameStateContext_SquadSelect(kSquadState.GetContext()).iLoadoutId;
}

simulated function int CloneLoadout(int iOldLoadoutId, string strNewLoadoutName)
{
	local XComGameStateContext_SquadSelect OldSquad;
	local XComGameState SquadState;

	OldSquad = GetLoadoutFromId(iOldLoadoutId);
	SquadState = class'XComGameStateContext_SquadSelect'.static.CopySquadSelect(GetNextLoadoutId(), OldSquad, true, false, strNewLoadoutName, GetLanguage());
	return XComGameStateContext_SquadSelect(SquadState.GetContext()).iLoadoutId;
}

simulated function DeleteLoadoutData(int iLoadoutId, optional bool bRemoveLoadoutId=false)
{
	local XComGameStateContext_SquadSelect SquadSelect;
	local int LoadoutIndex;
	LoadoutIndex = GetLoadoutIndexFromId(iLoadoutId);
	if (bRemoveLoadoutId)
	{
		// Obliterate everything!
		MultiplayerLoadoutGameStates.Remove(LoadoutIndex, 1);
	}
	else
	{
		// Only nuke the contents ...
		SquadSelect = XComGameStateContext_SquadSelect(MultiplayerLoadoutGameStates[LoadoutIndex].GetContext());
		SquadSelect.ClearSquad();
	}
}
// End Squad Loadouts - multiplayer - functions
//******************************************************************************************

function bool ShouldDisplayMy2KConversionAttempt()
{
	if( !SessionAttemptedMy2KConversion && (Data.NumberOfMy2KConversionAttempts < MAX_CONVERSION_ATTEMPTS) )
	{
		++Data.NumberOfMy2KConversionAttempts;
		SessionAttemptedMy2KConversion = true;
		return true;
	}
	return false;
}

defaultproperties
{
	// If you change any profile ids or anything inside the data blob ( including any game state objects ), increment this number!!!!
	VersionNumber=109

	SessionAttemptedMy2KConversion=false

	// Gamer profile settings that should be read to meet TCR
	ProfileSettingIds(0)=PSI_ControllerVibration
	ProfileSettingIds(1)=PSI_YInversion
	ProfileSettingIds(2)=PSI_ControllerSensitivity	
	ProfileSettingIds(3)=PSI_GameSpecificSettingsBlob //Just store a blob that contains this object in binary form

	// Game specific settings that should be stored in the roaming profile   

	// Defaults for the values if not specified by the online service
	DefaultSettings(0)=(Owner=OPPO_OnlineService,ProfileSetting=(PropertyId=PSI_ControllerVibration,Data=(Type=SDT_Int32,Value1=PCVTO_On)))
	DefaultSettings(1)=(Owner=OPPO_OnlineService,ProfileSetting=(PropertyId=PSI_YInversion,Data=(Type=SDT_Int32,Value1=PYIO_Off)))
	DefaultSettings(2)=(Owner=OPPO_OnlineService,ProfileSetting=(PropertyId=PSI_ControllerSensitivity,Data=(Type=SDT_Int32,Value1=PCSO_Medium)))
	DefaultSettings(3)=(Owner=OPPO_Game         ,ProfileSetting=(PropertyId=PSI_GameSpecificSettingsBlob,Data=(Type=SDT_Blob,Value1=0)))
}
