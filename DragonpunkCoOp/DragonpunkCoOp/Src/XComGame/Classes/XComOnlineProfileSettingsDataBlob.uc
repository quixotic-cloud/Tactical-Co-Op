//---------------------------------------------------------------------------------------
//  FILE:    XComOnlineProfileSettingsDataBlob.uc
//  AUTHOR:  Ryan McFall  --  08/22/2011
//  PURPOSE: This lightweight objects is what is serialized as a blob in XCom's online
//           player profile
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComOnlineProfileSettingsDataBlob extends Object
	dependson(XComContentManager, X2CardManager, X2TacticalGameRulesetDataStructures, X2MPData_Native)
	native(Core);

`if(`isdefined(FINAL_RELEASE))
`define FORCE_CONTROLLER 0
`else
`define FORCE_CONTROLLER 0
`endif

struct native MarketingPreset
{
	var string PresetName;
	var array<name> CheckboxSettings; //If a check box's name is in the list, it is checked
};

struct native NarrativeContentFlag
{
	var bool NarrativeContentEnabled;
	var name DLCName;
};

struct native CustomizationAlertInfo
{
	var int Category;
	var name DLCName;
};

var MarketingPreset MarketingPresets;

// Stores the player's selection for the part packs ( chance to see the various parts show up on generated soldiers )
var array<PartPackPreset> PartPackPresets;

// Single Player Tactical Debug Launch
var array<byte>                         TacticalGameStartState; //Compressed data representing the last game state used to launch a tactical game

//X-Com 2
//=====================================================
var array<SavedCardDeck>                SavedCardDecks; // Save data for the X2CardManager
var array<byte>                         X2MPLoadoutGameStates;
var array<byte>                         X2MPTempLobbyLoadout; // temporary loadout used when transitioning into an online game. necessary in the event a player makes changes to a squad but doesnt want to save it. -tsmith
var int                                 X2MPShellLastEditLoadoutId;  // loadout that was selected before creating/joining a game lobby -tsmith
var array<TX2UnitPresetData>            X2MPUnitPresetData;
var int                                 NumberOfMy2KConversionAttempts;
//=====================================================

var array<int>                          m_arrGameOptions;
var array<int>                          m_arrGamesSubmittedToMCP_Victory;
var array<int>                          m_arrGamesSubmittedToMCP_Loss;

var int                                 m_iPodGroup; // Deprecated

//  single player games started
var int  m_iGames;       

// Settings
var bool m_bMuteSoundFX;
var bool m_bMuteMusic;
var bool m_bMuteVoice;

var bool m_bVSync; 
var bool m_bAutoSave;

// Never use m_bActivateMouse.  Always use the accessor function IsMouseActive().  -dwuenschell
var protected bool m_bActivateMouse;
var transient bool m_bIsConsoleBuild;
var float	m_fScrollSpeed;
var bool	m_bGlamCam;
var bool	m_bForeignLanguages;
var bool	m_bAmbientVO;
var bool	m_bShowEnemyHealth; 
var bool	m_bEnableSoldierSpeech;
var bool	m_bSubtitles;
var bool	m_bPushToTalk;
var bool	m_bPlayerHasUncheckedBoxTutorialSetting;
var int		m_iMasterVolume;
var int		m_iVoiceVolume;
var int		m_iFXVolume;
var int		m_iMusicVolume;
var int		m_iGammaPercentage;
var float	m_fGamma;
var int		m_iLastUsedMPLoadoutId; // Multiple MP Squad Loadouts -ttalley
var float	UnitMovementSpeed; //Adjusts how fast units move around - 1.0f, the default settings, does not alter the movement rate from what was authored.

// For tracking achievements whose conditions do not have to be met in the same game
var array<bool> arrbSkulljackedUnits;
var int m_HeavyWeaponKillMask;
var int	m_ContinentBonusMask;
var int m_BlackMarketSuppliesReceived;
var int m_iGlobalAlienKills;
var int m_iVOIPVolume;

// Character Pool Usage
var ECharacterPoolSelectionMode m_eCharPoolUsage;
var bool bEnableZipMode;
var int MaxVisibleCrew;

// Character customization usage 
var array<int> m_arrCharacterCustomizationCategoriesClearedAttention; // DEPRECATED. Converted in XComCharacterCustomization.Init
var array<CustomizationAlertInfo> m_arrCharacterCustomizationCategoriesInfo; //Used from DLC2 forward, for all DLCs.

// DLC Narrative Tracking
var array<NarrativeContentFlag> m_arrNarrativeContentEnabled;

event bool IsMouseActive()
{
	if( m_bIsConsoleBuild ) {
		return false;
	}
	return m_bActivateMouse;
}

function ActivateMouse( bool activate )
{
	ScriptTrace();

`if(`FORCE_CONTROLLER)
	m_bActivateMouse = false;
`else
	m_bActivateMouse = activate;
`endif
	XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).SetIsMouseActive(m_bActivateMouse);
}

function int GetGamesStarted()
{
	return m_iGames;
}

function bool IfGameStatsSubmitted( int iGame, bool bVictory )
{
	if( bVictory )
		return m_arrGamesSubmittedToMCP_Victory.Find( iGame ) != -1;
	else
		return m_arrGamesSubmittedToMCP_Loss.Find( iGame ) != -1;

}
function GameStatsSubmitted( int iGame, bool bVictory )
{
	if( bVictory )
		m_arrGamesSubmittedToMCP_Victory.AddItem( iGame );
	else
		m_arrGamesSubmittedToMCP_Loss.AddItem( iGame );

}

function SetGameplayOption( EGameplayOption eOption, bool bEnable )
{
	if( m_arrGameOptions.Length == 0 )
		m_arrGameOptions.Add( eGO_Max );

	if(bEnable)
		m_arrGameOptions[eOption] = 1;
	else
		m_arrGameOptions[eOption] = 0;
}

function ClearGameplayOptions()
{
	local int iOption;

	for( iOption = 0; iOption < eGO_MAX; iOption++ )
	{
		SetGameplayOption(EGameplayOption(iOption), false );
	}
}

function bool IsSecondWaveUnlocked()
{
	return false;
}

// Moved to script because of craziness involving converting eOptions into FStrings - sbatista 5/11/12
function bool IsGameplayToggleUnlocked( EGameplayOption eOption )
{
	if( !IsSecondWaveUnlocked() ) return false;
	
	switch( eOption )
	{
		//  Impossible only options
		case eGO_LoseGearOnDeath: 
		case eGO_DegradingElerium:  
		case eGO_DecliningFunding: 
		case eGO_MorePower:
			return true;
		//  Hard+ options
		case eGO_PanicAffectsFunding:
		case eGO_VariableAbductionRewards:
		case eGO_EscalatingSatelliteCosts:
		case eGO_UltraRarePsionics:
		case eGO_ThirstForBlood:
			return true;
		//  Normal+ options
		case eGO_WoundsAffectStats:
		case eGO_CritOnFlank: 
		case eGO_InterrogateForPsi:
		case eGO_Marathon:
			return true;
		//  Easy+ options
		case eGO_MindHatesMatter:
			return true;
		//  No game completion required
		case eGO_RandomDamage:
		case eGO_RandomFunding:
		case eGO_RandomRookieStats:
		case eGO_RandomStatProgression:
		case eGO_RandomPerks:
		case eGO_RandomSeed:
		case eGO_AimingAngles:
			return true;
		default:
			`log("WARNING: unexpected gameplay option" @ eOption @ "NOT enabling it");
			return false;
	}
}

native function bool GetGameplayOption( EGameplayOption eOption );

function Options_ResetToDefaults( bool bInShell )
{

	//In Japanese or Korean, default to the subtitles on. 
	if( GetLanguage() == "JPN" || GetLanguage() == "KOR" )
	{
		m_bSubtitles = true; 
	}
	else
	{	
		m_bSubtitles = false; 
	}
	`XENGINE.bSubtitlesEnabled = m_bSubtitles;

	m_bMuteSoundFX  = class'XComOnlineProfileSettingsDataBlob'.default.m_bMuteSoundFX;
	m_bMuteMusic    = class'XComOnlineProfileSettingsDataBlob'.default.m_bMuteMusic;
	m_bMuteVoice    = class'XComOnlineProfileSettingsDataBlob'.default.m_bMuteVoice;
	m_bVSync        = class'XComOnlineProfileSettingsDataBlob'.default.m_bVSync; 
	m_bAutoSave     = class'XComOnlineProfileSettingsDataBlob'.default.m_bAutoSave;

	m_bIsConsoleBuild   = `GAMECORE.WorldInfo.IsConsoleBuild();

	//UI: We can not let you change input device while in game. The Ui will explode. Legacy issues. -bsteiner
	if( bInShell )
	{
`if(`FORCE_CONTROLLER)
		m_bActivateMouse    = false;
`else
		m_bActivateMouse    = class'Engine'.static.IsSteamBigPicture() ? false : !m_bIsConsoleBuild;
`endif
		XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).SetIsMouseActive(m_bActivateMouse);
	}

	m_fScrollSpeed      = class'XComOnlineProfileSettingsDataBlob'.default.m_fScrollSpeed;
	m_bForeignLanguages = class'XComOnlineProfileSettingsDataBlob'.default.m_bForeignLanguages;
	m_bAmbientVO		= class'XComOnlineProfileSettingsDataBlob'.default.m_bAmbientVO;
	m_bGlamCam          = class'XComOnlineProfileSettingsDataBlob'.default.m_bGlamCam;
	m_bShowEnemyHealth  = class'XComOnlineProfileSettingsDataBlob'.default.m_bShowEnemyHealth; 
	m_bEnableSoldierSpeech = class'XComOnlineProfileSettingsDataBlob'.default.m_bEnableSoldierSpeech;

	m_iMasterVolume = class'XComOnlineProfileSettingsDataBlob'.default.m_iMasterVolume;
	m_iVoiceVolume  = class'XComOnlineProfileSettingsDataBlob'.default.m_iVoiceVolume;
	m_iFXVolume     = class'XComOnlineProfileSettingsDataBlob'.default.m_iFXVolume;
	m_iMusicVolume  = class'XComOnlineProfileSettingsDataBlob'.default.m_iMusicVolume;
	m_iVOIPVolume   = class'XComOnlineProfileSettingsDataBlob'.default.m_iVOIPVolume;

	m_bPlayerHasUncheckedBoxTutorialSetting = class'XComOnlineProfileSettingsDataBlob'.default.m_bPlayerHasUncheckedBoxTutorialSetting;

	m_arrNarrativeContentEnabled.Length = 0;
}

defaultproperties
{
	m_bMuteSoundFX=false
	m_bMuteMusic=false
	m_bMuteVoice=false
`if(`FORCE_CONTROLLER)
	m_bActivateMouse=false
`else
	m_bActivateMouse=true
`endif
	m_fScrollSpeed=50
	m_bGlamCam=true
	m_bVSync=true
	m_bShowEnemyHealth=true;
	m_bEnableSoldierSpeech=true
	m_bForeignLanguages=false
	m_bAmbientVO=true

	m_iMasterVolume = 80
	m_iVoiceVolume = 80
	m_iFXVolume = 80
	m_iMusicVolume = 80
	m_iVOIPVolume = 80
	m_iGammaPercentage = 50
	m_fGamma = 2.2
	m_bIsConsoleBuild = false
	m_bPlayerHasUncheckedBoxTutorialSetting = false;
	UnitMovementSpeed = 1.0f;
	
	m_bAutoSave=true

	m_eCharPoolUsage=eCPSM_PoolOnly
	MaxVisibleCrew=30
}
