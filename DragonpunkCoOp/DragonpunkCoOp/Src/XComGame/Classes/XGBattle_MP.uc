// ----------------------------------------------------------------------
// XGBattle_MP differs from XGBattle by implementing simultanious turns
// ----------------------------------------------------------------------
class XGBattle_MP extends XGBattle;
   
var protectedwrite array<XComMPTacticalController>  m_arrGameCoreInitializedClients;
var protectedwrite array<XComMPTacticalController>  m_arrInitializedClients;

// needed because we iterate in state code which doesnt allow local variables -tsmith 
var private         XComMPTacticalController        m_kCachedLocalPC;

var             protectedwrite  int                 m_iMaxTurnTimeSeconds;
var             protectedwrite  float               m_fTurnTimeLeftSeconds;
var             protectedwrite  int                 m_iTurnTimeLeftSeconds;
var repnotify   protectedwrite  int                 m_iReplicatedTurnTimeLeftSeconds;
var             protectedwrite  int                 m_iReplicatedTurnTimeThresholdSeconds;
var             private         int                 m_iLastTurnTimeLeftSeconds;
var             private         int                 m_iTurnTimeBeepThresholdSeconds;
var privatewrite                bool                m_bTurnComplete;

const MAX_CHARACTER_TYPES_USED = 64;
struct TCharacterTypesUsedInfo
{
	var name                                        m_arrCharacterTypesUsed[MAX_CHARACTER_TYPES_USED];
};

var repnotify TCharacterTypesUsedInfo               m_kCharacterTypesUsedInfo;
var privatewrite bool                               m_bCharacterTypesUsedInfoReceived;

replication
{
	if(bNetInitial && Role == ROLE_Authority)
		m_iMaxTurnTimeSeconds, m_kCharacterTypesUsedInfo;
	
	if(bNetDirty && Role == ROLE_Authority)
		m_iReplicatedTurnTimeLeftSeconds;
}

// --------------------------------------------------------------
simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'm_iReplicatedTurnTimeLeftSeconds' && m_iMaxTurnTimeSeconds > 0)
	{
		if(m_iReplicatedTurnTimeLeftSeconds < m_iTurnTimeLeftSeconds || ((m_iReplicatedTurnTimeLeftSeconds - m_iTurnTimeLeftSeconds) >= m_iReplicatedTurnTimeThresholdSeconds))
		{
			m_iTurnTimeLeftSeconds = m_iReplicatedTurnTimeLeftSeconds;
			m_fTurnTimeLeftSeconds = m_iTurnTimeLeftSeconds;
		}
		if(m_iReplicatedTurnTimeLeftSeconds <= 0)
		{
			`log(self $ "::" $ GetFuncName() @ `ShowVar(m_iReplicatedTurnTimeLeftSeconds) @ "Turn timer expired", true, 'XCom_Net');
			OnTurnTimerExpired();
		}
	}
	else if(VarName == 'm_kCharacterTypesUsedInfo')
	{
		`log(self $ "::" $ GetFuncName() @ "m_kCharacterTypesUsedInfo=\n" $ TCharacterTypesUsedInfo_ToString(m_kCharacterTypesUsedInfo), true, 'XCom_Net');
		m_bCharacterTypesUsedInfoReceived = true;
	}

	super.ReplicatedEvent(VarName);
}

// --------------------------------------------------------------
static final function string TCharacterTypesUsedInfo_ToString(const out TCharacterTypesUsedInfo kCharacterTypeUsedInfo)
{
	local string strRep;
	local int i;
	local name nCharacterType;

	strRep = "";
	for(i = 0; i < MAX_CHARACTER_TYPES_USED; i++)
	{
		nCharacterType = kCharacterTypeUsedInfo.m_arrCharacterTypesUsed[i];
		strRep $= "CharacterTypesUsed[" $ i @ nCharacterType $ "]=" $ kCharacterTypeUsedInfo.m_arrCharacterTypesUsed[i] $ "\n";
	}

	return strRep;
}


// --------------------------------------------------------------
simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	if(Role < ROLE_Authority)
	{
		if(m_kProfileSettings == none)
		{
			SetProfileSettings();
		}
	}
}
// --------------------------------------------------------------

simulated event PreBeginPlay()
{
	// clear acceoted invite during gameplay
	`ONLINEEVENTMGR.bAcceptedInviteDuringGameplay = false;

	if(WorldInfo.NetMode == NM_DedicatedServer)
	{
		m_arrGameCoreInitializedClients.Length = 0;
		m_arrInitializedClients.Length = 0;
	}
	else if(WorldInfo.NetMode == NM_ListenServer)
	{
		// we implicitly count server players as initialized clients. -tsmith 
		foreach LocalPlayerControllers(class'XComMPTacticalController', m_kCachedLocalPC)
		{
			m_arrGameCoreInitializedClients.AddItem(m_kCachedLocalPC);
			m_arrInitializedClients.AddItem(m_kCachedLocalPC);
		}
	}
}

function SetMaxTurnTime(float fMaxTurnTimeSeconds)
{
	m_iMaxTurnTimeSeconds = fMaxTurnTimeSeconds;
}

/**
 * How close the turn timer is to expiring.
 * 
 * @param fThresholdSeconds - how much time left we are checking for, 0.0f for complete turn timer expiration.
 */
simulated function bool IsTurnTimerCloseToExpiring(float fThresholdSeconds=1.0f)
{
	return m_iMaxTurnTimeSeconds > 0 && (m_fTurnTimeLeftSeconds <= fThresholdSeconds);
}

// --------------------------------------------------------------
// --------------------------------------------------------------
protected function InitPlayers(optional bool bLoading = false)
{	
	
}

function DebugInitializeTransferSoldiersFromProfileSettings(XComMPTacticalPRI kPRI)
{
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function InitDescription()
{
	//@TODO - rmcfall - deprecated for XCom 2
}

function UninitDescription()
{
	//@TODO - rmcfall - deprecated for XCom 2
}

// --------------------------------------------------------------
// --------------------------------------------------------------
simulated protected function UpdateVisibility()
{
	if (!`BATTLE.m_bSkipVisUpdate)
	{
		m_arrPlayers[0].UpdateVisibility();
		m_arrPlayers[1].UpdateVisibility();
	}
}


// --------------------------------------------------------------
// --------------------------------------------------------------
simulated function XGSquad GetEnemySquad( XGPlayer kPlayer )
{
	//if( kPlayer.m_eTeam == eTeam_One )
	
	if( m_arrPlayers[0] == kPlayer )
		return m_arrPlayers[1].GetSquad();
	else
		return m_arrPlayers[0].GetSquad();
	
}

simulated function XGPlayer GetEnemyPlayer( XGPlayer kPlayer )
{
	if( m_arrPlayers[0] == kPlayer )
		return m_arrPlayers[1];
	else
		return m_arrPlayers[0];
}

simulated function XGPlayer GetLocalPlayer()
{
	return XComTacticalController(GetALocalPlayerController()).m_XGPlayer;
}

// --------------------------------------------------------------
// --------------------------------------------------------------
// Note: if iNumSpawnPoints == -1, then we return all spawn points found
function array<XComSpawnPoint> GetSpawnPoints( ETeam eUnitTeam, optional int iNumSpawnPoints=-1 )
{
	local array<XComSpawnPoint> arrSpawnPoints;
	local XComSpawnPoint StartSpot;
	
	foreach DynamicActors( class 'XComSpawnPoint', StartSpot )
	{
		if( iNumSpawnPoints != -1 && arrSpawnPoints.Length == iNumSpawnPoints )
			return arrSpawnPoints;
		
		if( eUnitTeam == eTeam_One && StartSpot.UnitType == UNIT_TYPE_MPTeamOne )
			arrSpawnPoints.AddItem( StartSpot );
		else if( eUnitTeam == eTeam_Two && StartSpot.UnitType == UNIT_TYPE_MPTeamTwo )
			arrSpawnPoints.AddItem( StartSpot );
	}
	
	return arrSpawnPoints;
}

// --------------------------------------------------------------
// Are all players ready to begin a new turn?
function bool ReadyForNewTurn()
{
	return m_kActivePlayer.IsInState( 'Active', true );
}

// --------------------------------------------------------------
// This function is called every frame.  It checks to see if all 
// players have decided to end their turn, at which point
// a new turn starts.
// --------------------------------------------------------------
function bool TurnIsComplete()
{
	if((m_iMaxTurnTimeSeconds > 0.0f &&  m_fTurnTimeLeftSeconds <= 0.0f) && m_kActivePlayer != none && m_kActivePlayer.m_ePlayerEndTurnType == ePlayerEndTurnType_TurnNotOver)
	{
		return OnTurnTimerExpired();
	}
	else
	{
		return m_kActivePlayer != none && m_kActivePlayer.IsTurnDone();
	}
}

simulated function bool OnTurnTimerExpired()
{
	if(!m_bTurnComplete)
	{
		// NOTE: this MUST happen before ending the fire action so the UI screens that may be on the UI stack get popped in the correct order. -tsmith 
		if(m_kActivePlayer.m_kPlayerController != none && m_kActivePlayer.m_kPlayerController.IsLocalPlayerController())
		{
			m_kActivePlayer.m_kPlayerController.Pres.OnTurnTimerExpired();
		}
		if(m_kActivePlayer.m_kPlayerController != none && m_kActivePlayer.m_kPlayerController.IsLocalPlayerController())
		{
			// local player can just end the turn, server must wait for client notification of turn end. -tsmith 
			m_kActivePlayer.m_kPlayerController.PerformEndTurn(ePlayerEndTurnType_TimerExpired);
			m_bTurnComplete = true;
		}
		else
		{
			// we are the server, active player is client player, must wait until we have received notification the client has completed turn -tsmith 
			if(Role == ROLE_Authority)
			{
				m_bTurnComplete = m_kActivePlayer.m_ePlayerEndTurnType == ePlayerEndTurnType_TimerExpired;
			}
		}
	}

	return m_bTurnComplete;
}


// --------------------------------------------------------------
// --------------------------------------------------------------
function bool IsBattleDone(bool bIgnoreBusy = false) 
{
	local XComMPTacticalGRI kMPGRI;
	local bool bIsBattleDone;
	
	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);
	bIsBattleDone = kMPGRI.m_kWinningPlayer != none;

	if(!bIsBattleDone)
	{
		CheckForVictory(bIgnoreBusy);
		bIsBattleDone = kMPGRI.m_kWinningPlayer != none;
	}
	
	return bIsBattleDone;
}

// --------------------------------------------------------------
// --------------------------------------------------------------
protected function CheckForVictory(bool bIgnoreBusy = false)
{
	local XComMPTacticalGRI kMPGRI;
	local XComMPTacticalController kWinningPC;
	local XComMPTacticalController kLosingPC;

	if( XComTacticalGame(WorldInfo.Game).bNoVictory )
	{
		return;
	}

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);
	if( kMPGRI != none )
	{
		// only end the game once, ending it more than once causes bad things: stat resubmission,etc. -tsmith 
		if(kMPGRI.m_kWinningPlayer == none)
		{
			if( AllPlayerUnitsAreDead(m_arrPlayers[1]) )
			{
				kWinningPC = XComMPTacticalController(m_arrPlayers[0].m_kPlayerController);
				kLosingPC = XComMPTacticalController(m_arrPlayers[1].m_kPlayerController);
				
			}
			else if( AllPlayerUnitsAreDead(m_arrPlayers[0]) )
			{
				kWinningPC = XComMPTacticalController(m_arrPlayers[1].m_kPlayerController);
				kLosingPC = XComMPTacticalController(m_arrPlayers[0].m_kPlayerController);
			}

			if( kWinningPC != none )
			{
				DoGameWon(kWinningPC, kLosingPC);
			}
		}
	}

}

// --------------------------------------------------------------
// --------------------------------------------------------------
function DoGameWon(XComMPTacticalController kWinner, XComMPTacticalController kLoser)
{
	local XComMPTacticalGRI kMPGRI;
	local XComMPTacticalPRI kMPWinningPRI;
	local XComMPTacticalPRI kMPLosingPRI;
	local int iOldWinnersRankedSkillRating;
	local int iOldLosersRankedSkillRating;

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);
	if(kMPGRI != none && kMPGRI.m_kWinningPlayer == none)
	{
		kMPGRI.bMatchIsOver = true;
		kMPGRI.m_kWinningPlayer = kWinner.m_XGPlayer;
		kMPGRI.m_kLosingPlayer = kLoser.m_XGPlayer;

		kMPWinningPRI = XComMPTacticalPRI(kMPGRI.m_kWinningPlayer.m_kPlayerController.PlayerReplicationInfo);
		kMPLosingPRI = XComMPTacticalPRI(kMPGRI.m_kLosingPlayer.m_kPlayerController.PlayerReplicationInfo);

		iOldWinnersRankedSkillRating = kMPWinningPRI.m_iRankedDeathmatchSkillRating;
		iOldLosersRankedSkillRating = kMPLosingPRI.m_iRankedDeathmatchSkillRating;
		
		kMPWinningPRI.WonMatch(kMPGRI.m_bIsRanked, iOldLosersRankedSkillRating);
		kMPLosingPRI.LostMatch(kMPGRI.m_bIsRanked, iOldWinnersRankedSkillRating);

		kMPWinningPRI.bForceNetUpdate = true;
		kMPLosingPRI.bForceNetUpdate = true;
		kMPGRI.m_kWinningPRI = kMPWinningPRI;
		kMPGRI.m_kLosingPRI = kMPLosingPRI;
		kMPGRI.bForceNetUpdate = true;

		`log(kMPWinningPRI.PlayerName $ " has won!!", true, 'XCom_Net');

		//GetResults().SetWinner( kMPGRI.m_kWinningPlayer );
		XComMPTacticalGame(WorldInfo.Game).EndGame(kMPWinningPRI, "He pWnd the other d00d");
		GotoState( 'Done' );
	}
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function bool AllPlayerUnitsAreDead(XGPlayer kPlayer)
{
	local int       i;
	local XGUnit    kUnit;
	local XGSquad   kSquad;

	kSquad = kPlayer.GetSquad();
	// changing to check current members, not permanent members, so that we will lose if all of our units have been mind controlled/possessed/not currently on our team.  -tsmith 
	for( i = 0; i < kSquad.GetNumMembers(); i++ )
	{
        kUnit = kSquad.GetMemberAt( i );

		if( !kUnit.IsDead() && !kUnit.IsCriticallyWounded())
			return false;
	}

	return true;
}
// --------------------------------------------------------------
// --------------------------------------------------------------
simulated function XComPresentationLayer PRES()
{
	return XComPresentationLayer(XComTacticalController(GetALocalPlayerController()).Pres);
}

// --------------------------------------------------------------
// The default state of a running game
simulated state Running
{
	simulated event Tick( float fDeltaT )
	{
		local bool bSuppressionMoviePlaying;

		super.Tick(fDeltaT);

		if( GetALocalPlayerController().PlayerInput.IsInState('Multiplayer_GameOver') )
			return;

		// only count down if we are using turn timers and we have fully initialed the running state. dont count down if the glam cams are running. -tsmith 
		if(m_iMaxTurnTimeSeconds > 0 && AtBottomOfRunningStateBeginBlock())
		{
			bSuppressionMoviePlaying = (m_kActivePlayer != none && m_kActivePlayer.GetActiveUnit() != none);
			
			if (bSuppressionMoviePlaying == false && m_iNumStopTurnTimerActionsExecuting == 0)
			{
				// suppression movie is not playing so go ahead and decrement delta time
				m_fTurnTimeLeftSeconds -= fDeltaT;
			}

			m_fTurnTimeLeftSeconds = FClamp(m_fTurnTimeLeftSeconds, 0, m_iMaxTurnTimeSeconds);
			m_iTurnTimeLeftSeconds = FCeil(m_fTurnTimeLeftSeconds);
			if(Role == ROLE_Authority)
			{
				m_iReplicatedTurnTimeLeftSeconds = m_iTurnTimeLeftSeconds;
				bNetDirty = true;
				bForceNetUpdate = true;
			}
			
			if(m_kActivePlayer != none && m_kActivePlayer.m_kPlayerController != none && m_kActivePlayer.m_kPlayerController.IsLocalPlayerController())
			{
				//Beef once at 30 sec left
				if(m_iLastTurnTimeLeftSeconds > 30 && m_iTurnTimeLeftSeconds <= 30)
				{
					PlaySound(SoundCue'SoundMultiplayer.30SecondsLeftCue', true);
				}
				// Beep every second for the final countdown
				if(m_iTurnTimeLeftSeconds < m_iTurnTimeBeepThresholdSeconds
					&& m_iTurnTimeLeftSeconds != 0
					&& m_iLastTurnTimeLeftSeconds > m_iTurnTimeLeftSeconds
					&& m_iLastTurnTimeLeftSeconds != m_iTurnTimeLeftSeconds) 
				{
					PlaySound(SoundCue'SoundMultiplayer.CountdownBeepCue', true);
				}
			}

			if(Role < ROLE_Authority)
			{
				if(m_iTurnTimeLeftSeconds <= 0)
				{
					`log(self $ "::" $ GetFuncName() @ "Turn Timer Expired", true, 'XCom_Net');
					OnTurnTimerExpired();
				}
			}

			m_iLastTurnTimeLeftSeconds = m_iTurnTimeLeftSeconds;
		}
	}
}

// --------------------------------------------------------------
simulated stateonly function WaitForGameCoreInitializationToComplete()
{
	local XComMPTacticalController kLocalPC;

	foreach LocalPlayerControllers(class'XComMPTacticalController', kLocalPC)
	{
		// need to keep using the long timeout until the battle is fully initialized. -tsmith 
		kLocalPC.GotoState('WaitingForGameInitialization');
	}
	PushState('WaitingForGameCoreInitializationToComplete');
}

simulated function bool IsGameCoreInitializationComplete()
{
	local bool bIsGameCoreInitializationComplete;
	local XComMPTacticalGRI kGRI;

	if(Role == ROLE_Authority)
	{
		bIsGameCoreInitializationComplete = m_arrGameCoreInitializedClients.Length == m_iNumHumanPlayers;
	}
	else
	{
		kGRI = XComMPTacticalGRI(WorldInfo.GRI);
		bIsGameCoreInitializationComplete = 
			m_bCharacterTypesUsedInfoReceived &&
			kGRI != none &&
			kGRI.m_kGameCore != none && kGRI.m_kGameCore.m_bInitialized &&
			kGRI.m_kMPData != none && kGRI.m_kMPData.m_bInitialized;
	}

	return bIsGameCoreInitializationComplete;
}

simulated state WaitingForGameCoreInitializationToComplete
{
Begin:
	while(!IsGameCoreInitializationComplete())
	{
		`log(self $ "::" $ GetStateName() @ "Waiting for game core initialization to complete...", true, 'XCom_Net');
		Sleep(0.1f);
	}

	//foreach LocalPlayerControllers(class'XComMPTacticalController', m_kCachedLocalPC)
	//{
	//	m_kCachedLocalPC.ServerClientIsGameCoreInitialized();
	//}

	PopState();
}

function AddGameCoreInitializedClient(XComMPTacticalController kGameCoreInitializedClient)
{
	if(m_arrGameCoreInitializedClients.Find(kGameCoreInitializedClient) == -1)
	{
		m_arrGameCoreInitializedClients.AddItem(kGameCoreInitializedClient);
	}
}

// --------------------------------------------------------------
simulated stateonly function WaitForInitializationToComplete()
{
	PushState('WaitingForInitializationToComplete');
}

simulated function bool IsInitializationComplete()
{
	return super.IsInitializationComplete();
	//local bool bIsInitializationComplete;

	//if(Role == ROLE_Authority)
	//{
	//	bIsInitializationComplete = m_arrInitializedClients.Length == m_iNumHumanPlayers;
	//}
	//else
	//{
	//	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(WorldInfo.GRI) @ `ShowVar(XComMPTacticalGRI(WorldInfo.GRI).IsInitialReplicationComplete()));
	//	// clients check all dependent startup data to be replicated -tsmith 
	//	bIsInitializationComplete = 
	//		WorldInfo.GRI != none &&
	//		XComMPTacticalGRI(WorldInfo.GRI).IsInitialReplicationComplete() &&
	//		AllPlayersInitiallyReplicated();
	//}

	//return bIsInitializationComplete;
}

simulated function bool AllPlayersInitiallyReplicated()
{
	local bool bAllPlayersInitiallyReplicated;
	local int i;
	local int iNumPlayersInitiallyReplicated;

	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_iNumPlayers));

	bAllPlayersInitiallyReplicated = false;
	iNumPlayersInitiallyReplicated = 0;
	if(m_iNumPlayers > 0)
	{
		for(i = 0; i < m_iNumPlayers; i++)
		{
			`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_arrPlayers[i]) @ `ShowVar(m_arrPlayers[i].IsInitialReplicationComplete()));
			if(m_arrPlayers[i] != none && m_arrPlayers[i].IsInitialReplicationComplete())
			{
				iNumPlayersInitiallyReplicated++;
			}
		}

		bAllPlayersInitiallyReplicated = iNumPlayersInitiallyReplicated == m_iNumPlayers;
	}

	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(bAllPlayersInitiallyReplicated));
	

	return bAllPlayersInitiallyReplicated;
}

simulated state WaitingForInitializationToComplete
{
Begin:
	while(!IsInitializationComplete())
	{
		`log(self $ "::" $ GetStateName() @ "Waiting for initialization to complete...", true, 'XCom_Net');
		Sleep(0.1f);
	}

	foreach LocalPlayerControllers(class'XComMPTacticalController', m_kCachedLocalPC)
	{
		// battle is fully initialized, player can go to normal state. -tsmith 
		m_kCachedLocalPC.GotoState('PlayerWalking');
	}
	
	if(Role < ROLE_Authority && `XPROFILESETTINGS == none)
	{
		class'Engine'.static.GetEngine().CreateProfileSettings();
		`XPROFILESETTINGS.ExtendedLaunch_InitToDefaults();
		SetProfileSettings();
	}

	`XCOMGRI.DoRemoteEvent('OnMultiplayerGame', true /*bRunOnClient*/);

	//foreach LocalPlayerControllers(class'XComMPTacticalController', m_kCachedLocalPC)
	//{
	//	m_kCachedLocalPC.ServerClientIsInitialized();
	//}

	PopState();
}

function AddInitializedClient(XComMPTacticalController kInitializedClient)
{
	if(m_arrInitializedClients.Find(kInitializedClient) == -1)
	{
		m_arrInitializedClients.AddItem(kInitializedClient);
	}
}

// --------------------------------------------------------------
// --------------------------------------------------------------
simulated state OuttroUI
{
Begin:

	if( `ISDEBUG )
		PopState();
	
	//PRES().UIMissionSummary_MP( m_kResults );

	//hide all the unit flags
	PRES().m_kUnitFlagManager.Hide();
	
	PushState( 'ModalUI' );
	
	PopState();
}



// --------------------------------------------------------------
simulated state PlayerEndTurnUI
{
Begin:
	PRES().UICloseChat();
	PRES().UIEndTurn(eTurnOverlay_Remote);
	PlaySound(SoundCue'SoundUI.HUDOffCue', true);
	PlaySound(SoundCue'SoundMultiplayer.TurnOverCue', true);
	PushState('ModalUI');
	PopState();
}

// --------------------------------------------------------------
simulated state PlayerBeginTurnUI
{
Begin:
	PRES().UICloseChat();
	PRES().UIEndTurn(eTurnOverlay_Local);
	PlaySound(SoundCue'SoundUI.HUDOnCue', true);
	PlaySound(SoundCue'SoundMultiplayer.StartTurnCue', true);
	PushState('ModalUI');
	PopState();
}

// --------------------------------------------------------------
// --------------------------------------------------------------
defaultproperties
{
	m_bShowLoadingScreen=false;
	m_iTurnTimeBeepThresholdSeconds = 11;
	m_iReplicatedTurnTimeThresholdSeconds = 2;
	m_bPlayCinematicIntro=false
	m_bAllowItemFragments=false
}
