//---------------------------------------------------------------------------------------
//  FILE:    XComStrategySoundManager.uc
//  AUTHOR:  Mark Nauta  --  09/16/2014
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComStrategySoundManager extends XComSoundManager config(GameData);

// Wwise support
var config array<string> WiseSoundBankNames; //Sound banks for general use. These are loaded as part of initialization.
var array<AKBank> WiseSoundBanks; //Holds references to the wise sound banks for later use

// HQ Music
var config string PlayHQMusicEventPath;
var config string StopHQMusicEventPath;
var AkEvent PlayHQMusic;
var AkEvent StopHQMusic;
var transient bool bSkipPlayHQMusicAfterTactical;

//---------------------------------------------------------------------------------------
function Init()
{
	super.Init();	
	bUsePersistentSoundAkObject = true;
}

event PreBeginPlay()
{
	local int idx;
	local XComContentManager ContentMgr;

	super.PreBeginPlay();

	ContentMgr = `CONTENT;

		// Load Banks
	for(idx = 0; idx < WiseSoundBankNames.Length; idx++)
	{
		ContentMgr.RequestObjectAsync(WiseSoundBankNames[idx], self, OnWiseBankLoaded);
	}

	// Load Music Events
	ContentMgr.RequestObjectAsync(PlayHQMusicEventPath, self, OnPlayHQMusicAkEventLoaded);
	ContentMgr.RequestObjectAsync(StopHQMusicEventPath, self, OnStopHQMusicAkEventLoaded);

	SubscribeToOnCleanupWorld();
}

simulated event OnCleanupWorld()
{
	Cleanup();

	super.OnCleanupWorld();
}

event Destroyed()
{
	super.Destroyed();

	Cleanup();
}

function Cleanup()
{	
	local int Index;

	for(Index = 0; Index < WiseSoundBankNames.Length; ++Index)
	{
		`CONTENT.UnCacheObject(WiseSoundBankNames[Index]);
	}

	`CONTENT.UnCacheObject(PlayHQMusicEventPath);
	`CONTENT.UnCacheObject(StopHQMusicEventPath);
}

//---------------------------------------------------------------------------------------
function OnWiseBankLoaded(object LoadedArchetype)
{
	local AkBank LoadedBank;

	LoadedBank = AkBank(LoadedArchetype);
	if (LoadedBank != none)
	{		
		WiseSoundBanks.AddItem(LoadedBank);
	}
}

//---------------------------------------------------------------------------------------
function OnPlayHQMusicAkEventLoaded(object LoadedObject)
{
	PlayHQMusic = AkEvent(LoadedObject);
	assert(PlayHQMusic != none);
}

//---------------------------------------------------------------------------------------
function OnStopHQMusicAkEventLoaded(object LoadedObject)
{
	StopHQMusic = AkEvent(LoadedObject);
	assert(StopHQMusic != none);
}

//---------------------------------------------------------------------------------------
function PlayHQMusicEvent()
{
	if(!`XSTRATEGYSOUNDMGR.bSkipPlayHQMusicAfterTactical)
	{
		StopSounds();
		PlayAkEvent(PlayHQMusic);
	}
	else
	{
		`XSTRATEGYSOUNDMGR.bSkipPlayHQMusicAfterTactical = false; // This flag is set in the state where X-Com returns from a mission. In this situation the HQ music is already playing
	}
}

//---------------------------------------------------------------------------------------
function StopHQMusicEvent()
{
	if(!`XSTRATEGYSOUNDMGR.bSkipPlayHQMusicAfterTactical)
	{
		PlayAkEvent(StopHQMusic);
	}
}

//---------------------------------------------------------------------------------------
function PlayBaseViewMusic()
{
	SetSwitch('StrategyScreen', 'Avenger');

	if( class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T1_M6_KillAvatar') )
	{
		SetSwitch('HQChapter', 'Chapter03');
	}
	else if( class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T3_M2_BuildShadowChamber') )
	{
		SetSwitch('HQChapter', 'Chapter02');
	}
	else
	{
		SetSwitch('HQChapter', 'Chapter01');
	}
}

//---------------------------------------------------------------------------------------
function PlayGeoscapeMusic()
{
	SetSwitch('StrategyScreen', 'Geoscape');
}

//---------------------------------------------------------------------------------------
function PlaySquadSelectMusic()
{
	SetSwitch('StrategyScreen', 'ChooseSquad');
}

function PlayCreditsMusic()
{
	SetSwitch('StrategyScreen', 'PostMissionFlow_FlawlessVictory');
}

function PlayLossMusic()
{
	SetSwitch('StrategyScreen', 'PostMissionFlow_Fail');
}

//---------------------------------------------------------------------------------------
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

//---------------------------------------------------------------------------------------
DefaultProperties
{
}