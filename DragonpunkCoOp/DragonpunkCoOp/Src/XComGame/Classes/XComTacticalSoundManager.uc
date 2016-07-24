class XComTacticalSoundManager extends XComSoundManager config(GameData);

//Used to detect when we are in combat or not
var private int NumAlertedEnemies;
var privatewrite int NumCombatEvents;
var private bool bAmbienceStarted;
var private bool bDeferRequestStopHQ;

//WWise support
var config array<string> WiseSoundBankNames; //Sound banks for general use. These are loaded as part of initialization.
var array<AKBank> WiseSoundBanks; //Holds references to the wise sound banks for later use

//Combat sets
var config array<string> TacticalCombatMusicSets; //Each time the tactical music changes, a new set will be randomly selected

//Map ambiance event
var string MapAmbienceEventPath;
var AkEvent MapAmbienceEvent;

//Mission sound track event
var string MissionSoundtrackEventPath;
var AkEvent MissionSoundtrackEvent;

var AkEvent StopHQMusic;
var AkEvent StartHQMusic;

function Init()
{
	super.Init();
}

event PreBeginPlay()
{
	local int Index;

	super.PreBeginPlay();

	for(Index = 0; Index < WiseSoundBankNames.Length; ++Index)
	{
		`CONTENT.RequestObjectAsync(WiseSoundBankNames[Index], self, OnWiseBankLoaded);
	}

	`CONTENT.RequestObjectAsync(MapAmbienceEventPath, self, OnMapAmbianceLoaded);
	`CONTENT.RequestObjectAsync(MissionSoundtrackEventPath, self, OnMissionSoundtrackLoaded);
	`CONTENT.RequestObjectAsync(class'XComStrategySoundManager'.default.StopHQMusicEventPath, self, OnStopHQMusicAkEventLoaded);
	`CONTENT.RequestObjectAsync(class'XComStrategySoundManager'.default.PlayHQMusicEventPath, self, OnStartHQMusicAkEventLoaded);

	bUsePersistentSoundAkObject = true;

	SubscribeToOnCleanupWorld();
}

function Cleanup()
{
	local Object ThisObj;
	local int Index;

	StopAllAmbience();

	for(Index = 0; Index < WiseSoundBankNames.Length; ++Index)
	{
		`CONTENT.UnCacheObject(WiseSoundBankNames[Index]);
	}

	`CONTENT.UnCacheObject(MapAmbienceEventPath);
	`CONTENT.UnCacheObject(MissionSoundtrackEventPath);

	ThisObj = self;	
	`XEVENTMGR.UnRegisterFromEvent( ThisObj, 'PlayerTurnBegun' );
}

event Destroyed()
{
	local Object ThisObj;

	super.Destroyed();

	Cleanup();

	ThisObj = self;
	`XEVENTMGR.UnRegisterFromEvent(ThisObj, 'PlayerTurnBegun');
}

simulated event OnCleanupWorld()
{
	local Object ThisObj;

	Cleanup();

	ThisObj = self;	
	`XEVENTMGR.UnRegisterFromEvent( ThisObj, 'PlayerTurnBegun' );
}

function OnWiseBankLoaded(object LoadedArchetype)
{
	local AkBank LoadedBank;

	LoadedBank = AkBank(LoadedArchetype);	
	WiseSoundBanks.AddItem(LoadedBank);
}

function OnMapAmbianceLoaded(object LoadedArchetype)
{
	MapAmbienceEvent = AkEvent(LoadedArchetype);
}

function OnMissionSoundtrackLoaded(object LoadedArchetype)
{
	MissionSoundtrackEvent = AkEvent(LoadedArchetype);
}

function OnStopHQMusicAkEventLoaded(object LoadedObject)
{
	StopHQMusic = AkEvent(LoadedObject);
	assert(StopHQMusic != none);
	if(bDeferRequestStopHQ)
	{
		StopHQMusicEvent();
	}
}

function StopHQMusicEvent()
{	
	if(StopHQMusic != none)
	{
		PlayAkEvent(StopHQMusic);
	}
	else
	{
		bDeferRequestStopHQ = true;
	}
}

function OnStartHQMusicAkEventLoaded(object LoadedObject)
{
	StartHQMusic = AkEvent(LoadedObject);
	assert(StartHQMusic != none);	
}

function StartEndBattleMusic()
{
	StopSounds();
	PlayAkEvent(StartHQMusic);
	PlayAfterActionMusic();
}

function PlayAfterActionMusic()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local bool bCasualties, bVictory;
	local int idx;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	bCasualties = false;

	if(BattleData != none)
	{
		bVictory = BattleData.bLocalPlayerWon;
	}
	else
	{
		bVictory = XComHQ.bSimCombatVictory;
	}

	if(!bVictory)
	{
		SetSwitch('StrategyScreen', 'PostMissionFlow_Fail');
		//PlaySoundEvent("PlayPostMissionFlowMusic_Failure");
	}
	else
	{
		for(idx = 0; idx < XComHQ.Squad.Length; idx++)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

			if(UnitState != none && UnitState.IsDead())
			{
				bCasualties = true;
				break;
			}
		}

		if(bCasualties)
		{
			SetSwitch('StrategyScreen', 'PostMissionFlow_Pass');
			//PlaySoundEvent("PlayPostMissionFlowMusic_VictoryWithCasualties");
		}
		else
		{
			SetSwitch('StrategyScreen', 'PostMissionFlow_FlawlessVictory');
			//PlaySoundEvent("PlayPostMissionFlowMusic_FlawlessVictory");
		}
	}
}

function OnTurnVisualized(ETeam NewTeamTurn)
{	
	switch(NewTeamTurn)
	{
	case eTeam_XCom:
		SetState( 'TacticalGameTurn', 'XCOM' );
		SetSwitch( 'TacticalGameTurn', 'XCOM' );
		break;
	case eTeam_Alien:
		SetState( 'TacticalGameTurn', 'Alien' );
		SetSwitch( 'TacticalGameTurn', 'Alien' );
		break;
	case eTeam_Neutral:
		SetState( 'TacticalGameTurn', 'XCOM' );
		SetSwitch( 'TacticalGameTurn', 'XCOM' );
		break;
	case eTeam_One:
		SetState( 'TacticalGameTurn', 'XCOM' );
		SetSwitch( 'TacticalGameTurn', 'XCOM' );
		break;
	case eTeam_Two:
		SetState('TacticalGameTurn', 'Alien');
		SetSwitch('TacticalGameTurn', 'Alien');
		break;
	}
}

function EvaluateTacticalMusicState()
{
	local X2TacticalGameRuleset Ruleset;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Player LocalPlayerState;
	local XComGameState_Player PlayerState;
	local int NumAlertedEnemiesPrevious;

	Ruleset = `TACTICALRULES;
	History = `XCOMHISTORY;

	//Get the game state representing the local player
	LocalPlayerState = XComGameState_Player(History.GetGameStateForObjectID(Ruleset.GetLocalClientPlayerObjectID()));

	//Sync our internally tracked count of alerted enemies with the state of the game
	NumAlertedEnemiesPrevious = NumAlertedEnemies;
	NumAlertedEnemies = 0;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		//Discover whether this unit is an enemy
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));
		if( PlayerState != none && LocalPlayerState.IsEnemyPlayer(PlayerState) )
		{
			//If the enemy unit is higher than green alert ( hunting or fighting ), 
			// Changed to only trigger on red alert.  Yellow alert can happen too frequently for cases of not being sighted. (Jumping through window, Protect Device mission)
			// Also, Terror missions the aliens are killing civilians while in green alert, this way combat music is purely a they have seen you case.

			//Get the currently visualized state for this unit ( so we don't read into the future )
			UnitState = XGUnit(UnitState.GetVisualizer()).GetVisualizedGameState();
			if( UnitState.IsAlive() && UnitState.GetCurrentStat(eStat_AlertLevel) > 1 )
			{
				++NumAlertedEnemies;
			}
		}
	}

	if( NumAlertedEnemiesPrevious > 0 && NumAlertedEnemies == 0 )
	{
		//Transition out of combat		
		SetSwitch( 'TacticalCombatState', 'Explore' );

		SelectRandomTacticalMusicSet();
	}
	else if( NumAlertedEnemiesPrevious == 0 && NumAlertedEnemies > 0 )
	{
		//Transition into combat
		SetSwitch( 'TacticalCombatState', 'Combat' );

		SelectRandomTacticalMusicSet();

		NumCombatEvents++;

		if (NumCombatEvents == 1)
		{
			foreach History.IterateByClassType( class'XComGameState_Unit', UnitState )
			{
				if (XGUnit( UnitState.GetVisualizer( ) ).m_eTeam == eTeam_Neutral)
				{
					XGUnit( UnitState.GetVisualizer( ) ).IdleStateMachine.CheckForStanceUpdate( );
				}
			}
		}
	}
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	//In previous systems, this would turn on/off environmental sounds such as rain depending on where the unit is
}

function SelectRandomTacticalMusicSet()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local XComGameState_Cheats CheatState;
	local int RandomIndex;
	local name SelectSet;

	// first check if a specific music set has been selected from kismet
	CheatState = class'XComGameState_Cheats'.static.GetVisualizedCheatsObject();
	if(CheatState != none && CheatState.TacticalMusicSetOverride != '')
	{
		SetSwitch('TacticalCombatMusicSet', CheatState.TacticalMusicSetOverride);
	}
	else
	{
		// check if this mission requests specific music, otherwise play a random set
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

		if(MissionState == none || MissionState.GetMissionSource().CustomMusicSet == '')
		{
			if(TacticalCombatMusicSets.Length > 0)
			{
				RandomIndex = `SYNC_RAND(TacticalCombatMusicSets.Length);
				SelectSet = name(TacticalCombatMusicSets[RandomIndex]);
				if(`REPLAY.bInTutorial)
				{
					SetSwitch('TacticalCombatMusicSet', 'Tutorial');
				}
				else
				{
					SetSwitch('TacticalCombatMusicSet', SelectSet);
				}
			}
		}
		else
		{		
			SetSwitch('TacticalCombatMusicSet', MissionState.GetMissionSource().CustomMusicSet);
		}
	}
}

function name GetSwitchNameFromEnvLightingString( string sLighting )
{
	// Note: I originaly used Repl, to simply cut off the "EnvLighting_" prefix,
	// but some of these names are subject to change, and so I'm making the
	// conversion explicit for now.  mdomowicz 2015_08_10
	switch (sLighting)
	{
		case "EnvLighting_Sunrise":            return 'Sunrise';
		case "EnvLighting_Shanty_Sunrise":     return 'Sunrise';
		case "EnvLighting_Day":                return 'Day';
		case "EnvLighting_Shanty_Day":         return 'Day';
		case "EnvLighting_Rain":               return 'Rain';
		case "EnvLighting_Sunset":             return 'Sunset';
		case "EnvLighting_NatureNight":        return 'NatureNight';
		case "EnvLighting_Shanty_NatureNight": return 'NatureNight';
		case "EnvLighting_Day_Arid":           return 'Day_Arid';
		case "EnvLighting_Shanty_Day_Arid":    return 'Day_Arid';
		case "EnvLighting_Sunset":             return 'Sunset';
		case "EnvLighting_Shanty_Sunset":      return 'Sunset';
		case "EnvLighting_Day_Tundra":         return 'Day_Tundra';
		case "EnvLighting_NatureNight_Tundra": return 'NatureNight_Tundra';
		case "EnvLighting_UrbanNight":         return 'UrbanNight';
		case "EnvLighting_Facility":           return 'Facility';
	}

	return '';
}

//Parameterized starting the mission sound track, since this is done automatically as part of the in-game intros
function StartAllAmbience(bool bStartMissionSoundtrack=true)
{
	local XComGameState_BattleData BattleData;

	local string sBiome;
	local string sEnvironmentLightingMapName;
	local PlotDefinition PlotDef;
	local name nBiomeSwitch;
	local name nClimateSwitch;
	local name nLightingSwitch;

	if(!bAmbienceStarted)
	{
		// Get the relevant environment ambiance settings.
		BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
		sBiome = BattleData.MapData.Biome;
		sEnvironmentLightingMapName = BattleData.MapData.EnvironmentLightingMapName;
		PlotDef = `PARCELMGR.GetPlotDefinition(BattleData.MapData.PlotMapName);

		// Convert the ambiance settings to their corresponding AkAudio Switch names.
		nBiomeSwitch = Name(PlotDef.AudioPlotTypeOverride != "" ? PlotDef.AudioPlotTypeOverride : PlotDef.strType);
		nClimateSwitch = Name(sBiome);
		nLightingSwitch = GetSwitchNameFromEnvLightingString(sEnvironmentLightingMapName);

		// Set the ambiance switches, and play the ambiance event.
		StopAllAmbience();
		if(`TACTICALRULES.bRain)
		{
			SetState('Weather', 'Rain');
		}
		else
		{
			SetState('Weather', 'NoRain');
		}
		SetState('Climate', nClimateSwitch);
		SetState('Lighting', nLightingSwitch);
		SetState('Biome', nBiomeSwitch);
		PlayAkEvent(MapAmbienceEvent);

		//There are some assumptions here on what the state of the game will be when loading or starting up. If the X-Com 
		//team is not guaranteed to be the first, then update the code below.
		SetSwitch('TacticalGameTurn', 'XCOM');
		SelectRandomTacticalMusicSet();
		SetSwitch('TacticalCombatState', 'Explore');		
		if(bStartMissionSoundtrack)
		{
			PlayAkEvent(MissionSoundtrackEvent);
		}

		NumCombatEvents = 0;
		bAmbienceStarted = true;
	}
}

function StopAllAmbience()
{
	SetSwitch( 'TacticalCombatState', 'None' );
	SetState( 'Biome', 'None' );
	SetState( 'Climate', 'None' );
	SetState( 'Lighting', 'None' );
}

defaultproperties
{
	MapAmbienceEventPath = "SoundAmbienceMapLoops.PlayMapAmbience"
	MissionSoundtrackEventPath = "SoundMissionSoundtracks.PlayMissionSoundtrack"
}