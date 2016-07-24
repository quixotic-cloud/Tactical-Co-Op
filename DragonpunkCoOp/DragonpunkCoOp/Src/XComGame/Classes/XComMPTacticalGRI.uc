//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------
class XComMPTacticalGRI extends XComTacticalGRI
	dependson(XComMPData);

var protected   repnotify XGPlayer          m_kActivePlayer;
var             repnotify XGPlayer          m_kWinningPlayer;
var                       XGPlayer          m_kLosingPlayer;
var                       XComMPTacticalPRI m_kWinningPRI;
var                       XComMPTacticalPRI m_kLosingPRI;
var EMPNetworkType                          m_eNetworkType;
var EMPGameType                             m_eGameType;
var int                                     m_iMapPlotType;
var int                                     m_iMapBiomeType;
var int                                     m_iTurnTimeSeconds;
var int                                     m_iMaxSquadCost;
var bool                                    m_bIsRanked;
var bool                                    m_bGameForfeited;
var bool                                    m_bGameDisconnected;

var bool                                    m_bCallStartMatch;

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated event ReplicatedEvent(name VarName)
{
	//if ( VarName == 'bMatchHasBegun' )
	//{
	//	if (bMatchHasBegun)
	//	{
	//		StartMatch();
	//	}

	//	super.ReplicatedEvent(VarName);
	//}
	//else 
		if( VarName == 'm_kActivePlayer' )
	{
		SetActivePlayer(m_kActivePlayer);
	}
	else if ( VarName == 'm_kWinningPlayer' && m_kWinningPlayer != none )
	{
		m_kBattle.GotoState('Done');
	}
	else
	{
		super.ReplicatedEvent(VarName);
	}
}
//-----------------------------------------------------------
//-----------------------------------------------------------
simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	if(Role < ROLE_Authority)
	{
		// set the random seed on the client so its different everytime, only used for client side/non-gameplay rolls.
		// the server already sets the seed in XComMPTacticalGame::InitGame because it needs to for random start point.-tsmith 
		class'Engine'.static.GetEngine().SetRandomSeeds(class'Engine'.static.GetEngine().GetARandomSeed());
	}

	ServerName = class'Engine'.static.GetUserNameComputerName();
}

simulated function bool IsInitialReplicationComplete()
{
	local bool bIsInitialReplicationComplete;
	local bool bAreLocalPlayersInitiallyReplicated;
	local XComMPTacticalController kLocalPC;

	bIsInitialReplicationComplete = false;
	foreach LocalPlayerControllers(class'XComMPTacticalController', kLocalPC)
	{
		`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(kLocalPC) @ `ShowVar(kLocalPC.IsInitialReplicationComplete()));
		bAreLocalPlayersInitiallyReplicated = kLocalPC.IsInitialReplicationComplete();
		if(!bAreLocalPlayersInitiallyReplicated)
		{
			break;
		}
	}

	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(bAreLocalPlayersInitiallyReplicated) @  `ShowVar(m_kPrecomputedPath) @ `ShowVar(m_kBattle) @ `ShowVar(m_kGameCore) @ `ShowVar(m_kMPData));

	bIsInitialReplicationComplete = bAreLocalPlayersInitiallyReplicated &&
		GetPrecomputedPath() != none &&
		m_kBattle != none &&
		m_kGameCore != none && m_kGameCore.m_bInitialized &&
		m_kMPData != none && m_kMPData.m_bInitialized;


	return bIsInitialReplicationComplete;
}

simulated function CreateMPStartState()
{
	local XComGameStateHistory			History;
	local XComGameState					NewStartState;
	local XComGameState_BattleDataMP	BattleData;
	local XComGameState_Unit			NewSoldierState;
	local StateObjectReference			XComPlayerRef;
	
	//Determine which map to load
	local int							MapIdx, PlayerIdx, SoldierIdx;
	local XComParcelManager				ParcelMgr;
	local array<string>					CandidatePlotNames;

	// Create the new soldiers
	local X2CharacterTemplateManager    CharTemplateMgr;	
	local X2CharacterTemplate           CharacterTemplate;
	local TSoldier                      CharacterGeneratorResult;
	local XGCharacterGenerator          CharacterGenerator;

	History = `XCOMHISTORY;

	// Create the MP GameState
	if( `XCOMHISTORY.GetNumGameStates() < 1 )
	{
		`ONLINEEVENTMGR.ReadProfileSettings();

		///
		/// Setup the Tactical side ...
		///
		if(m_kGameCore == none)
		{
			m_kGameCore = Spawn(class'XGTacticalGameCore', self);
			m_kGameCore.Init();
		}

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
			if( ParcelMgr.arrPlots[MapIdx].strType == "VerticalSlice" )
			{
				CandidatePlotNames.AddItem(ParcelMgr.arrPlots[MapIdx].MapName);
			}
		}
		//*****************************************************

		MapIdx = `SYNC_RAND(CandidatePlotNames.Length);
		BattleData.MapData.PlotMapName = CandidatePlotNames[MapIdx];	
	
		//Configure/read the battle data. Configure various battle variables based on the mission state, selected map, time of day, etc.
		`assert(!BattleData.bReadOnly);
		BattleData.iLevelSeed = class'Engine'.static.GetEngine().GetSyncSeed(); //Pre-calculate the seed that will be used
		BattleData.m_strDesc    = "";
		BattleData.m_strOpName  = ""; //class'XGMission'.static.GenerateOpName(false);
		BattleData.m_strMapCommand = "open"@BattleData.MapData.PlotMapName$"?game=XComGame.XComTacticalGame";

		//Add the start state to the history
		History.AddGameStateToHistory(NewStartState);

		CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		`assert(CharTemplateMgr != none);

		CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Soldier');	
		`assert(CharacterTemplate != none);
		CharacterGenerator = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);
		`assert(CharacterGenerator != none);

		for( PlayerIdx = 0; PlayerIdx < BattleData.PlayerTurnOrder.Length; ++PlayerIdx)
		{
			XComPlayerRef = BattleData.PlayerTurnOrder[PlayerIdx];

			for( SoldierIdx = 0; SoldierIdx < class'XGTacticalGameCore'.default.NUM_STARTING_SOLDIERS; ++SoldierIdx )
			{
				NewSoldierState = CharacterTemplate.CreateInstanceFromTemplate(NewStartState);
				NewSoldierState.RandomizeStats();

				// VS Only ...
				if (SoldierIdx == 0)
				{
					// Setup Soldier Class Template
					NewSoldierState.SetSoldierClassTemplate('Ranger');
					NewSoldierState.BuySoldierProgressionAbility(NewStartState, 0, 0); // Setup the first rank ability
				}

				NewSoldierState.ApplyInventoryLoadout(NewStartState);

				CharacterGeneratorResult = CharacterGenerator.CreateTSoldier();
				NewSoldierState.SetTAppearance(CharacterGeneratorResult.kAppearance);
				NewSoldierState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
				NewSoldierState.SetCountry(CharacterGeneratorResult.nmCountry);
				class'XComGameState_Unit'.static.NameCheck(CharacterGenerator, NewSoldierState, eNameType_Full);

				NewSoldierState.SetHQLocation(eSoldierLoc_Dropship);
				NewSoldierState.SetControllingPlayer( XComPlayerRef );

				NewStartState.AddStateObject(NewSoldierState);
			}

			break; // TOOD: Remove this once the eTeam / Human / Alien player fixes are in.
		}
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
auto state PendingSetup
{
	simulated function StartMatch()
	{
		CreateMPStartState();
		m_bCallStartMatch = true;
	}

Begin:
	while(!`BATTLE.IsInitializationComplete())
	{
		sleep(0.1f);
	}
	if (m_bCallStartMatch)
	{
		global.StartMatch();
	}
	GotoState('FinishedSetup');
}

simulated state FinishedSetup
{
}

simulated function StartMatch()
{
	CreateMPStartState();
	super.StartMatch();

	// Ensure that the player has the correct rich presence
	//m_kActivePlayer.m_kPlayerController.ClientSetOnlineStatus();

	// loads the shell settings which contain the unit loadout types which will dynamically load proper asset packages -tsmith 
	//if(m_kBattle != none)
	//{
	//	m_kBattle.SetProfileSettings();		
	//	m_kBattle.Start();
	//}

	//ModStartMatch();
}

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function InitBattle()
{
	//@TODO - tsmith / rmcfall - Use regular tactical GRI instead. Remove this GRI object.
	super.InitBattle();
}

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function SetActivePlayer(XGPlayer kActivePlayer)
{
	m_kActivePlayer = kActivePlayer;

	if(m_kActivePlayer != none)
	{
		if(m_kActivePlayer.m_kPlayerController != none && m_kActivePlayer.m_kPlayerController.IsLocalPlayerController())
		{
			// its now my turn so show the overlay if its not already there -tsmith 
			`PRES.UIShowMyTurnOverlay();
		}
		else
		{
			`PRES.UIShowOtherTurnOverlay();
		}
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function XGPlayer GetActivePlayer()
{
	return m_kActivePlayer;
}

simulated function ReceivedGameClass()
{
	ReplayMgr = Spawn(class'XComMPReplayMgr', self);

	super.ReceivedGameClass();

	if(m_kMPData == none)
	{
		m_kMPData = new class'XComMPData';
		m_kMPData.Init(); 
	}
}

function string GetMapPlotName()
{
	return class'X2MPData_Shell'.default.arrMPMapFriendlyNames[m_iMapPlotType];
}

function string GetMapBiomeName()
{
	return class'X2MPData_Shell'.default.arrMPBiomeFriendlyNames[m_iMapBiomeType];
}

simulated function string GetMapDisplayName()
{
	return GetMapPlotName() @ GetMapBiomeName();
}

defaultproperties
{
	m_kPlayerClass = class'XGPlayer_MP';
	m_bOnReceivedGameClassGetNewMPINI=false;
	m_bCallStartMatch=false
}


