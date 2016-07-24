//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMPLobbyGRI.uc
//  AUTHOR:  Todd Smith  --  4/15/2010
//  PURPOSE: GameReplicationInfo class for the lobby game
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComMPLobbyGRI extends XComShellGRI;

var bool        m_bAllPlayersReady;
var int         m_iNumHumanPlayers;     
var bool        m_bGameStarting;
var bool        m_bGameStartAborted;

var bool                                    m_bCallStartMatch;


replication
{
	if(bNetDirty && Role == ROLE_Authority)
		m_bAllPlayersReady, m_iNumHumanPlayers, m_bGameStarting, m_bGameStartAborted;
}

simulated function CreateMPStartState()
{
	// Game State references
	local XComGameStateHistory			History;
	local XComGameState					NewStartState;
	local XComGameState_BattleDataMP	BattleData;
	
	// Determine which map to load
	local int							MapIdx, ObjIdx;
	local XComParcelManager				ParcelMgr;
	local array<string>					CandidatePlotNames;
	local XComTacticalMissionManager    MissionManager;

	History = `XCOMHISTORY;
	MissionManager = `TACTICALMISSIONMGR;
	`ONLINEEVENTMGR.ReadProfileSettings();

	// Clear out everything, since we want a clean start into Tactical
	History.ResetHistory();

	///
	/// Setup the Tactical side ...
	///
	if(m_kGameCore == none)
	{
		m_kGameCore = Spawn(class'XGTacticalGameCore', self);
		m_kGameCore.Init();
	}

	//Create the basic strategy objects
	class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(,false, , , , , false);

	//Create the basic objects
	NewStartState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Multiplayer(BattleData);

	////Add some stock soldiers
	//class'XComOnlineProfileSettings'.static.AddDefaultSoldiersToStartState(NewStartState);

	//Choose the map we will be entering. If the number of game state is one, it means we are starting a campaign.
	ParcelMgr = `PARCELMGR;
		
	//Get the map info from the appropriate location ...
	//*****************************************************
	for( MapIdx = 0; MapIdx < ParcelMgr.arrPlots.Length; ++MapIdx )
	{
		CandidatePlotNames.AddItem(ParcelMgr.arrPlots[MapIdx].MapName);		
	}
	//*****************************************************

	MapIdx = `SYNC_RAND(CandidatePlotNames.Length);
	BattleData.MapData.PlotMapName = CandidatePlotNames[MapIdx];	
	
	//Configure/read the battle data. Configure various battle variables based on the mission state, selected map, time of day, etc.
	`assert(!BattleData.bReadOnly);
	BattleData.iLevelSeed = class'Engine'.static.GetEngine().GetSyncSeed(); //Pre-calculate the seed that will be used
	BattleData.m_strDesc    = "Multiplayer Deathmatch";
	if(m_bMPIsRanked)
	{
		BattleData.m_strOpName  = class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_Ranked];
		BattleData.bRanked = true;
		BattleData.bAutomatch = false;
	}
	else if(m_bMPAutomatch)
	{
		BattleData.m_strOpName  = class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_QuickMatch];
		BattleData.bRanked = false;
		BattleData.bAutomatch = true;
	}
	else
	{
		BattleData.m_strOpName  = class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_CustomMatch];
		BattleData.bRanked = false;
		BattleData.bAutomatch = false;
	}

	BattleData.iMaxSquadCost = m_iMPMaxSquadCost;
	BattleData.iTurnTimeSeconds = m_iMPTurnTimeSeconds;

	BattleData.m_strMapCommand = "open"@BattleData.MapData.PlotMapName$"?game=XComGame.XComTacticalGame";
	for (ObjIdx = 0; ObjIdx < MissionManager.default.arrMissions.Length; ++ObjIdx)
	{
		if (MissionManager.default.arrMissions[ObjIdx].sType ~= "MP_Deathmatch")
		{
			BattleData.m_iMissionType = ObjIdx;
			BattleData.m_iSubObjective = ObjIdx;
			break;
		}
	}

	CreateDefaultLoadout(NewStartState, BattleData);
	class'XComGameState_GameTime'.static.CreateGameStartTime(NewStartState);

	//Add the start state to the history
	History.AddGameStateToHistory(NewStartState);
}

simulated function CreateDefaultLoadout(XComGameState NewGameState, XComGameState_BattleDataMP BattleData)
{
	local PlayerReplicationInfo         PRI;
	local StateObjectReference ControllingPlayer;

	// Game State references
	local XComGameState_Unit			NewSoldierState;
	local XComGameState_Player			PlayerState;
	
	// Determine which map to load
	local int							PlayerIdx, SoldierIdx;

	// Create the new soldiers
	local X2CharacterTemplateManager    CharTemplateMgr;	
	local X2CharacterTemplate           CharacterTemplate;
	local TSoldier                      CharacterGeneratorResult;
	local XGCharacterGenerator          CharacterGenerator;
	
	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Soldier');	
	`assert(CharacterTemplate != none);
	CharacterGenerator = Spawn(CharacterTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	for( PlayerIdx = 0; PlayerIdx < BattleData.PlayerTurnOrder.Length; ++PlayerIdx)
	{
		PRI = (PRIArray.Length > PlayerIdx) ? PRIArray[PlayerIdx] : None;
		PlayerState = XComGameState_Player(NewGameState.GetGameStateForObjectID(BattleData.PlayerTurnOrder[PlayerIdx].ObjectID));

		if (PRI != none)
		{
			PlayerState.SetGameStatePlayerName(PRI.PlayerName);
		}

		for( SoldierIdx = 0; SoldierIdx < class'XGTacticalGameCore'.default.NUM_STARTING_SOLDIERS; ++SoldierIdx )
		{
			NewSoldierState = CharacterTemplate.CreateInstanceFromTemplate(NewGameState);
			NewSoldierState.RandomizeStats();

			// VS Only ...
			if (SoldierIdx == 0)
			{
				// Setup Soldier Class Template
				NewSoldierState.SetSoldierClassTemplate('Ranger');
				NewSoldierState.BuySoldierProgressionAbility(NewGameState, 0, 0); // Setup the first rank ability
			}

			NewSoldierState.ApplyInventoryLoadout(NewGameState, 'RookieSoldier');

			CharacterGeneratorResult = CharacterGenerator.CreateTSoldier();
			NewSoldierState.SetTAppearance(CharacterGeneratorResult.kAppearance);
			NewSoldierState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
			class'XComGameState_Unit'.static.NameCheck(CharacterGenerator, NewSoldierState, eNameType_Full);

			NewSoldierState.SetHQLocation(eSoldierLoc_Dropship);

			ControllingPlayer.ObjectID = PlayerState.ObjectID;
			NewSoldierState.SetControllingPlayer( ControllingPlayer );

			NewGameState.AddStateObject(NewSoldierState);
		}
	}
}

function CalcAllPlayersReady()
{
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local bool bAllPlayersReady;

	History = `XCOMHISTORY;
	bAllPlayersReady = true;
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(!PlayerState.bPlayerReady)
		{
			bAllPlayersReady = false;
			break;
		}
	}
	m_bAllPlayersReady = bAllPlayersReady;
}

//-----------------------------------------------------------
//-----------------------------------------------------------
auto state PendingSetup
{

Begin:
	while(!`BATTLE.IsInitializationComplete())
	{
		sleep(0.1f);
	}
	//CreateMPStartState();
	GotoState('FinishedSetup');
}

simulated state FinishedSetup
{
}

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function InitBattle()
{
	//@TODO - tsmith / rmcfall - Use regular tactical GRI instead. Remove this GRI object.
	super.InitBattle();
}

// Overridding the base class version to make sure that we just always do "StartNewGame" since it is not 
// trying to "load" from a saved game, nor is the StartState the topmost - MP adds and changes states to
// configure the joined players etc.
simulated function StartOrLoadGame()
{
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	`log(self $ "::" $ GetFuncName() @ "XCOMHISTORY=" $ History @ "StartState=" $ History.GetStartState().ToString(), true, 'XCom_GameStates');
	TacticalRules.StartNewGame();
}



/** Called when the GameClass property is set (at startup for the server, after the variable has been replicated on clients) */
simulated function ReceivedGameClass()
{
	super.ReceivedGameClass();

	if(m_kMPData == none)
	{
		m_kMPData = new class'XComMPData';
	}
	m_kMPData.Init();
}

defaultproperties
{
	m_iNumHumanPlayers=2
	m_kPlayerClass = class'XGPlayer_MP';
	m_bOnReceivedGameClassGetNewMPINI=false;
	m_bCallStartMatch=false
}
