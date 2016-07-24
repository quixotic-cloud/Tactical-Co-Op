// ----------------------------------------------------
// hold all data for the battle itself
// units are owned by the players
// ----------------------------------------------------
class XGBattle extends Actor
	abstract
	dependson(XGBattleDesc)
	dependson(XComGameState)
	native(Core);

const TIMEOUT_TIME = 50.0f;

//@TODO - RAM - eliminate this when battle is eliminated
var XComGameState_BattleData            m_kDesc;

var XGLevel                             m_kLevel;
var XGPlayer                            m_arrPlayers[ENumPlayers.EnumCount];
var repnotify int                       m_iTurn; // incremented after all players have a taken a turn -tsmith 
var int                                 m_iNumPlayers;
var protectedwrite int                  m_iNumHumanPlayers;
var repnotify int                       m_iPlayerTurn; // incremented after each player takes turn -tsmith

var protected XComOnlineProfileSettings m_kProfileSettings;
var string                              m_strObjective; // custom override
var int                                 m_iResult;
var bool                                m_iResultCachedThisFrame;
var bool                                m_bIsInited;    // past the init state.
var bool                                m_bLoadingSave; // Set by the loading state if we were being created by a save

var XGPlayer                    m_kActivePlayer;
var int                         m_iClientLastReplicatedPlayerTurn;
var bool                        m_bSkipVisUpdate;

var bool m_bLevelStreamingComplete;
var bool m_bShowLoadingScreen;

var protected repnotify bool        m_bClientStart;
var protected bool                  m_bClientAlreadyStarted;

var XGPlayer m_kCloseCombatInstigator;
var bool     m_bCloseCombatFromPodMovement;

var array<Sequence> CachedStreamingSequences;

// 'Globals'
var Material        m_kAOEDamageMaterial;
var Material        m_kAOEDamageMaterial_FriendlyDestructible;

var bool m_bTacticalIntroDone;
var bool m_bFoundTacticalIntro;
var array<Vector> m_arrInitialUnitLocs;
var bool m_bPlayerTransition;
var bool m_bPlayCinematicIntro;
var bool m_bLoadKismetDataFromSave;

var const bool m_bAllowItemFragments;

// Volume Ducking
var XComVolumeDuckingMgr m_kVolumeDuckingMgr;

var SoundCue EnemySpottedCue;
var private bool    m_bSkipOuttroUI;
var bool m_bInPauseMenu;

var transient int SleepFrames;
var transient float TimeSpentWaitingForLoading;

var private transient bool m_bAtBottomOfRunningStateBeginBlock;
var private transient bool m_bServerAtBottomOfRunningStateBeginBlock;

var float fTimeoutTimer;

var int iLevelSeed;

var privatewrite int                                            m_iNumStopTurnTimerActionsExecuting;
var protected bool m_OneOrMoreEnemyVisualizeInRedAlert;

// --------------------------------------------------------------
// ------------OVERRIDDEN IN SUBCLASSES--------------------------
function UninitDescription();
protected function InitPlayers(optional bool bLoading = false);
protected function InitRules();
function array<XComSpawnPoint> GetSpawnPoints( ETeam eUnitTeam, optional int iNumSpawnPoints=-1 );
protected function CheckForVictory(bool bIgnoreBusy = false);
simulated function XComPresentationLayer PRES();
function XGSquad GetEnemySquad( XGPlayer kPlayer );
function XGPlayer GetEnemyPlayer( XGPlayer kPlayer );
function XComGameState_Player GetAIPlayerState();
function XGPlayer GetAIPlayer();
simulated function XGPlayer GetLocalPlayer();
protected function UpdateVisibility();
function bool TurnIsComplete();
function bool ReadyForNewTurn();
function BeginNewTurn(optional bool bIsLoading);
simulated function ClientBeginNewTurn();
function CompleteCombat();
function bool AnyEnemyInVisualizeAlert_Red();
function Update_GlobalEnemyVisualizeAlertFlags();
function int GetForceLevel()  
{
	return 1;
};
/*reliable server function CameraIsMoving( XComTacticalController kPC );
reliable server function CameraMoveComplete( XComTacticalController kPC );
reliable server function bool IsCameraMoving( XComTacticalController kPC );
*/

/*
function GenerateRandomSamples()
{
	local XGPlayer combatant;

	combatant = GetEnemyPlayer(m_kActivePlayer);

	if (combatant != none)
		combatant.GetSquad().GenerateRandomSamples();

	m_kActivePlayer.GetSquad().GenerateRandomSamples();
}*/

simulated function RefreshDesc()
{
	m_kDesc = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
}

simulated function XComGameState_BattleData GetDesc()
{
	if (m_kDesc == None)
		RefreshDesc();
	return m_kDesc;
}

simulated function CameraIsMoving( XComTacticalController kPC )
{
	kPC.m_bCamIsMoving = true;
}
simulated function CameraMoveComplete( XComTacticalController kPC )
{
    kPC.m_bCamIsMoving = false;
}

simulated function bool IsCameraMoving( XComTacticalController kPC )
{
	return kPC.m_bCamIsMoving;
}
//simulated function RequestContent();


replication
{
	if( bNetDirty && Role == ROLE_Authority )
		m_iTurn, m_iPlayerTurn, m_arrPlayers, m_iNumPlayers, m_bClientStart, 
		m_kCloseCombatInstigator, m_bCloseCombatFromPodMovement, m_kDesc,
		m_kActivePlayer, m_bPlayerTransition, m_iNumStopTurnTimerActionsExecuting, m_bServerAtBottomOfRunningStateBeginBlock;
}

function bool IsBattleDone(bool bIgnoreBusy = false) 
{ 
	return false;       //  @TODO nothing should call this function anymore
}

simulated event ReplicatedEvent( name VarName )
{
	super.ReplicatedEvent( VarName );
}


// --------------------------------------------------------------
// ------------ SHELL SETTINGS SAVE DATA METHODS ----------------
simulated function bool ProfileSettingsSaveDataIsValid()
{
	return m_kProfileSettings != none;
}

simulated function XComOnlineProfileSettings GetProfileSettings()
{
	if( m_kProfileSettings == none )
	{
		m_kProfileSettings = `XPROFILESETTINGS;
	}

	return m_kProfileSettings;
}

simulated function SetProfileSettings()
{
	m_kProfileSettings = `XPROFILESETTINGS;
}

simulated function bool ProfileSettingsAutoSave()
{
	return m_kProfileSettings.Data.m_bAutoSave;
}

simulated function bool ProfileSettingsMuteSoundFX()
{
	return m_kProfileSettings.Data.m_bMuteSoundFX;
}

simulated function bool ProfileSettingsMuteMusic()
{
	return m_kProfileSettings.Data.m_bMuteMusic;
}

simulated function bool ProfileSettingsMuteVoice()
{
	return m_kProfileSettings.Data.m_bMuteVoice;
}

simulated function bool ProfileSettingsGlamCam()
{
	return m_kProfileSettings.Data.m_bGlamCam;
}

simulated function bool ProfileSettingsActivateMouse()
{
	if(m_kProfileSettings != none)
	{
		return m_kProfileSettings.Data.IsMouseActive();
	}
	else
	{
		return false;
	}
}

simulated function ProfileSettingsDebugUseController()
{
	if(m_kProfileSettings != none)
	{
		m_kProfileSettings.Data.ActivateMouse(false);
	}
}

simulated function float ProfileSettingsEdgeScrollRate()
{
	// scale from 0.0-1.0 to 0.1-1.0. This prevents users from completely stopping the scroll.
	return lerp(0.1, 1.0, m_kProfileSettings != none ? m_kProfileSettings.Data.m_fScrollSpeed : 1.0f); 
}

// --------------------------------------------------------------

/*
simulated function FocusCameraOnFirstUnit()
{
	local XGUnit kUnit;
	kUnit = GetLocalPlayer().GetSquad().GetMemberAt(0);

	if (kUnit != none)
		PRES().CAMLookAt( kUnit.GetLocation() );
}
*/

/**
 * How close the turn timer is to expiring.
 * 
 * @param fThresholdSeconds - how much time left we are checking for, 0.0f for complete turn timer expiration.
 */
simulated function bool IsTurnTimerCloseToExpiring(float fThresholdSeconds=1.0f)
{
	// single player does not have turn timers -tsmith 
	return false;
}

function bool IsAlienTurn()
{
	if (m_kActivePlayer != none && GetAIPlayer() == m_kActivePlayer)
		return true;
	else return false;
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function InitDescription();

// --------------------------------------------------------------
// --------------------------------------------------------------
simulated function InitLevel()
{
	local XComBuildingVolume kBuildingVolume;
	local XGNarrative kNarr;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	`log(self $ "::" $ GetFuncName() $ ": " $ `ShowVar(WorldInfo.GetLocalURL()) $ ", " $ `ShowVar(WorldInfo.GetAddressURL()), true, 'XCom_Net');

	m_kLevel = Spawn( class'XGLevel' );
	m_kLevel.Init();
	foreach AllActors(class'XComBuildingVolume', kBuildingVolume)
		kBuildingVolume.m_kLevel = m_kLevel;

	if (PRES().m_kNarrative == none)
	{
		CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

		kNarr = spawn(class'XGNarrative');
		kNarr.InitNarrative(CampaignSettingsStateObject.bSuppressFirstTimeNarrative);
		PRES().SetNarrativeMgr(kNarr);
	}

	// jboswell: Let level init dynamic elements
	//m_kLevel.LoadStreamingLevels(false);

	LoadDynamicAOEMaterials();

	SetProfileSettings();
}

// --------------------------------------------------------------
// --------------------------------------------------------------
simulated protected function PostLevelLoaded()
{
	m_kLevel.InitFloorVolumes();
	m_kLevel.InitWaterVolumes();

	//`PARCELMGR.RebuildWorldData();
}


// --------------------------------------------------------------
// --------------------------------------------------------------
function AddPlayer( XGPlayer player )
{
	local int   i;
	local bool  bFoundSlotForPlayer;

	if( m_iNumPlayers < eNumPlayers_MAX )
	{
		for( i = 0; i < eNumPlayers_MAX; i++ )
		{
			if( m_arrPlayers[i] == none )
			{
				m_arrPlayers[i] = player;
				m_iNumPlayers++;
				if(player.IsHumanPlayer())
				{
					m_iNumHumanPlayers++;
				}
				bFoundSlotForPlayer = true;
				break;
			}
		}
		if( !bFoundSlotForPlayer )
		{
			`warn(self $ "::" $ GetFuncName() $ ": " $ `ShowVar(m_iNumPlayers) $ " is out of sync with the # of players actually in the players array!");
		}
	}
	else
	{
		`warn(self $ "::" $ GetFuncName() $ ": Can't add any more players! At MAX!");
	}
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function Uninit()
{
	local int i;
	for (i = 0; i < m_iNumPlayers; ++i)
	{
		m_arrPlayers[i].Uninit();
		m_arrPlayers[i].Destroy();
		m_arrPlayers[i] = none;
	}
	
	UninitDescription();
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function SwapTeams(XComGameState_Unit Unit, ETeam NewTeam)
{
	// if you're going to swap teams, you need to make sure to fill this out in your battle type
	`assert(false);
}

function bool IsPlayerPanicking()
{
	return false;
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function Start()
{
	GotoState('Starting');
	m_bClientStart = true;
	`XCOMGAME.StartNewGame(); //  @TODO jboushcer / rmcfall - this belongs somewhere else
}

function PostLoad()
{
	GotoState('Starting');
	m_bClientStart = true;
	`XCOMGAME.LoadGame(); //  @TODO jboushcer / rmcfall - this belongs somewhere else
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function bool IsPaused()
{
	// This should be overridden in states where necessary.  
	// If this returns true, gameplay and AI will not progress.
	return true;
}
// --------------------------------------------------------------
function Play();
function Pause()
{
	PushState( 'Paused' );
}

function bool IsVictory(bool bIgnoreBusyCheck)
{
	return false;
}

// --------------------------------------------------------------

simulated function ToggleFOW()
{
	SetFOW(!`XWORLD.bEnableFOW);
}

simulated function SetFOW(bool bNewFOW)
{
	local LocalPlayer LP;
	local int i, j;
	local PostProcessChain PPChain;
	local XComFOWEffect FOWEffect;
     
	`XWORLD.bEnableFOW = bNewFOW;

	LP = LocalPlayer(GetALocalPlayerController().Player);
	for(i=0;i<LP.PlayerPostProcessChains.Length;i++)
	{
		PPChain = LP.PlayerPostProcessChains[i];
		for(j=0;j<PPChain.Effects.Length;j++)
		{
			FOWEffect = XComFOWEffect(PPChain.Effects[j]);
			if(FOWEffect != none)
			{
				FOWEffect.bShowFOW = `XWORLD.bEnableFOW && `XWORLD.bDebugEnableFOW;
			}
		}
	}
}

simulated function SetEdge(bool bNewEdge)
{
	local LocalPlayer LP;
	local int i, j;
	local PostProcessChain PPChain;
	local XComEdgeEffect EdgeEffect;
     

	LP = LocalPlayer(GetALocalPlayerController().Player);
	for(i=0;i<LP.PlayerPostProcessChains.Length;i++)
	{
		PPChain = LP.PlayerPostProcessChains[i];
		for(j=0;j<PPChain.Effects.Length;j++)
		{
			EdgeEffect = XComEdgeEffect(PPChain.Effects[j]);
			if(EdgeEffect != none)
			{
				EdgeEffect.bShowInGame = bNewEdge;
			}
		}
	}
}

simulated function int GetSpawnGroup( out optional name groupTag )
{
	local int groupID;
	
	// If we override the group during testing, force it here.
	if( XComTacticalGame(WorldInfo.Game).ForcedSpawnGroupIndex != -1 )
	{
		groupID = XComTacticalGame(WorldInfo.Game).ForcedSpawnGroupIndex;
		groupTag = XComTacticalGame(WorldInfo.Game).ForcedSpawnGroupTag;
	}
	else
	{
		groupID = class'XComSpawnPointNativeBase'.static.GetSpawnGroupIndex(m_kDesc.m_iPlayCount);
	}

	return groupID;
}

// --------------------------------------------------------------
reliable client function PlayCinTacticalIntro()
{
	local SeqEvent_OnTacticalIntro TacticalIntro;
	local array<SequenceObject> Events;
	local array<XGUnit> arrSortedUnits;
	local int i,Idx, iUnitIdx, iMecIdx, iSoldierIdx, iShivIdx;
	local XGSquad kSquad;
	local XGUnit kUnit;
	local XComUnitPawn kPawn;
	local string strMap;
	local SkeletalMeshActor A,Dropship;

	GetLocalPlayer().m_kPlayerController.GetCursor().SetForceHidden(true);

	foreach AllActors(class'SkeletalMeshActor', A)
	{
		if ( A.Tag == 'CinematicDropship' )
		{
			Dropship = A;
			break;
		}
	}

	kSquad = m_arrPlayers[0].GetSquad();
	for( i = 0; i < kSquad.GetNumMembers(); i++ )
	{
		kUnit = kSquad.GetMemberAt(i);
		m_arrInitialUnitLocs.AddItem(kUnit.GetPawn().Location); // save this unsorted
		arrSortedUnits.AddItem(kUnit);
	}

	if (WorldInfo.GetGameSequence() != None)
	{
		WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_OnTacticalIntro', TRUE, Events);

		if (Events.Length == 0)
		{
			m_bTacticalIntroDone = true;
			return;
		}
		else
		{
			m_bFoundTacticalIntro = true;
		}
		
		for (Idx = 0; Idx < Events.Length; Idx++)
		{
			TacticalIntro = SeqEvent_OnTacticalIntro(Events[Idx]);
			if (TacticalIntro == None) continue;
			
			// If we're on the temple ship map, we reserve iUnitIdx(0) for the volunteer
			iUnitIdx = (m_kDesc.m_iMissionType == eMission_Final) ? 1 : 0;
			iSoldierIdx = iUnitIdx;

			TacticalIntro.iSpawnGroup = GetSpawnGroup();

			foreach arrSortedUnits(kUnit)
			{	
				kPawn = kUnit.GetPawn();					

				kPawn.SetBase(Dropship,, Dropship.SkeletalMeshComponent, 'CargoBaySocket');
				kPawn.SetupForMatinee(,true);
				kUnit.AddFlagToVisibleToTeams(m_arrPlayers[0].m_eTeam);

				if (false)//XGCharacter_Soldier(kUnit.GetCharacter()).m_kSoldier.iPsiRank == eRank_Volunteer)       jbouscher - REFACTORING CHARACTERS
				{
					TacticalIntro.Soldier1 = kPawn;
				}
				else
				{
					 AddPawnToTacticalIntro(kPawn, TacticalIntro, iUnitIdx, iMecIdx, iSoldierIdx, iShivIdx);
				}
			}

			strMap = WorldInfo.GetMapName();
			`XTACTICALSOUNDMGR.StopAllAmbience();
			TacticalIntro.strMapName = strMap;
			TacticalIntro.BattleObj = self;
			TacticalIntro.CheckActivate(self, self);
		}
	}
}

simulated static function AddPawnToTacticalIntro(XComPawn kPawn, 
													SeqEvent_OnTacticalIntro kIntro,
													out int iPlacedUnits, 
													out int iPlacedMecs, 
													out int iPlacedSoldiers,
													out int iPlacedShivs)
{
	local int iUnitIdx;

	// "collapse slots" means to leave no bubbles in any unit type. So if you have two mecs
	// and two soldiers, they will go in Mec1, Mec2, Soldier1, and Soldier2.
	// Without collapsing slots, you get Mec1, Mec2, Soldier3, Soldier4.

	if(XComHumanPawn(kPawn) != none)
	{
		iUnitIdx = kIntro.CollapseSlots ? iPlacedSoldiers : iPlacedUnits;
		switch(iUnitIdx)
		{
			case 0: kIntro.Soldier1 = kPawn; break;
			case 1: kIntro.Soldier2 = kPawn; break;
			case 2: kIntro.Soldier3 = kPawn; break;
			case 3: kIntro.Soldier4 = kPawn; break;
			case 4: kIntro.Soldier5 = kPawn; break;
			case 5: kIntro.Soldier6 = kPawn; break;
			default: kPawn.SetHidden(true); break;
		}
		kPawn.SetVisibleToTeams(eTeam_All);
		iPlacedUnits++;
		iPlacedSoldiers++;
	}
	else // it's a shiv
	{
		iUnitIdx = kIntro.CollapseSlots ? iPlacedShivs : iPlacedUnits;
		switch(iUnitIdx)
		{
			case 0: kIntro.Shiv1 = kPawn; break;
			case 1: kIntro.Shiv2 = kPawn; break;
			case 2: kIntro.Shiv3 = kPawn; break;
			case 3: kIntro.Shiv4 = kPawn; break;
			case 4: kIntro.Shiv5 = kPawn; break;
			case 5: kIntro.Shiv6 = kPawn; break;
			default: kPawn.SetHidden(true); break;
		}
		iPlacedUnits++;
		iPlacedShivs++;
	}
}

simulated function RestoreIntroPawns()
{
	local XGSquad kSquad;
	local XGUnit kUnit;
	local XComUnitPawn kPawn;
	local Vector vDir;
	local int i;

	kSquad = m_arrPlayers[0].GetSquad();
	for( i = 0; i < kSquad.GetNumMembers(); i++ )
	{
		kUnit = kSquad.GetMemberAt(i);
		kPawn = kUnit.GetPawn();

		kPawn.ReturnFromMatinee();

		kPawn.SetLocation(m_arrInitialUnitLocs[i]);
		vDir = kPawn.FocalPoint - kPawn.Location;
		vDir.z = 0;
		kPawn.SetRotation(Rotator(vDir));
		kPawn.SetHidden(false);
	}
}
//------------------------------------------------------------------------------------------------
// Display all player states.  (DEBUG)
simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string kStr;
	local XGPlayer kPlayer;
	local XGUnit kUnit;
	local int iX, iY, i;
	local vector vScreenPos;
	local XComParcel kParcel;
	local ObjectiveSpawnPossibility kOSP;
	if (XComTacticalCheatManager(GetALocalPlayerController().CheatManager).bPlayerStates)
	{
		iX=100;
		iY=50;
		for( i = 0; i < m_iNumPlayers; i++ )
		{
			kPlayer = m_arrPlayers[i];
			kStr= "Player"@i@" State:"@kPlayer.GetStateName();
			if( kPlayer == m_kActivePlayer )
			{
				kCanvas.SetDrawColor(0,255,0);
				kUnit = kPlayer.GetActiveUnit();
				if (kUnit != none)
				{
					kStr = kStr@" Active Unit="$kUnit@" State="$kUnit.GetStateName()@" Action=";
					if (kUnit.m_kBehavior != None)
						kStr = kStr@"DebugLoc="$kUnit.m_kBehavior.m_iDebugHangLocation;
				}
			}
			else
			{
				kCanvas.SetDrawColor(255,0,0);
			}
			kCanvas.SetPos(iX, iY + i*15);
			kCanvas.DrawText(kStr);
		}
	}
	if (XComTacticalCheatManager(GetALocalPlayerController().CheatManager).bShowParcelNames)
	{
		foreach WorldInfo.AllActors(class'XComParcel', kParcel)
		{
			kStr = kParcel.ParcelDef.MapName;
			vScreenPos = kCanvas.Project(kParcel.Location);
			kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
			kCanvas.SetDrawColor(255,255,255);
			kCanvas.DrawText(kStr);
		}
	}
	if (XComTacticalCheatManager(GetALocalPlayerController().CheatManager).bShowObjectivesLocations)
	{
		foreach WorldInfo.AllActors(class'ObjectiveSpawnPossibility', kOSP)
		{
			if (kOSP.bBeenUsed)
			{
				kStr = String(kOSP.Name);
				vScreenPos = kCanvas.Project(kOSP.GetSpawnLocation());
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
				kCanvas.SetDrawColor(255,128,0);
				kCanvas.DrawText(kStr);
			}
		}
	}
}

simulated function EndSpecialFOWUpdate()
{
	`XWORLD.bUseIntroFOWUpdate = false;
	`XWORLD.bFOWTextureBufferIsDirty = true;
}

// jboswell: Place to put save fixup hacks
simulated function PostLoadSaveGame();

simulated function CheckReadyToHideLoadingScreen(optional bool bOverride=false)
{
	if (m_bShowLoadingScreen || bOverride)
	{
		PRES().HideLoadingScreen();     // lower progress screen
	}
}

simulated function LoadDynamicAOEMaterials()
{
	// Load all of the global materials
	m_kAOEDamageMaterial = Material(DynamicLoadObject("UI_3D.Targeting.M_HitByAOE", class'Material'));
	m_kAOEDamageMaterial_FriendlyDestructible = Material(DynamicLoadObject("UI_3D.Targeting.M_FriendlyHitByAOE", class'Material'));
}

simulated stateonly function WaitForGameCoreInitializationToComplete();
simulated stateonly function WaitForInitializationToComplete();

simulated function bool AtBottomOfRunningStateBeginBlock()
{
	if(Role == ROLE_Authority)
	{
		return m_bAtBottomOfRunningStateBeginBlock;
	}
	else
	{
		return m_bAtBottomOfRunningStateBeginBlock && m_bServerAtBottomOfRunningStateBeginBlock;
	}
}

// --------------------------------------------------------------
simulated state ModalUI
{
	simulated event Tick( float fDeltaT )
	{
		super.Tick(fDeltaT);
		
		if(m_kVolumeDuckingMgr != none)
		{
			m_kVolumeDuckingMgr.Tick(fDeltaT);
		}
	}

Begin:

	`log( "======================>COMBAT IS WAITING ON UI<=================" );

	// Gameplay does not progress until the screen has been closed	
	while( PRES().UIIsBusy() )
		Sleep( 0.0 );
	
	PopState();
}

function QuitAndTransition()
{
	CompleteCombat();
}

// --------------------------------------------------------------
// --------------------------------------------------------------

public function InvalidPathSelection(XGUnit ActiveUnit)
{
	/*
	local XComTacticalGRI TacticalGRI;
	local XComDirectedTacticalExperience ActiveDirectedExperience;

	if( m_kDesc.m_bIsTutorial )
	{
		// First, play an invalid selection sound.
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );

		// For the tutorial, a DTE will be available.  If so, tell the DTE
		// that the user clicked on an invalid path.  On the third click,
		// we want to change the camera to where the user needs to go.
	
		TacticalGRI = `TACTICALGRI;
		if (TacticalGRI != none)
		{
			ActiveDirectedExperience = TacticalGRI.DirectedExperience;
			if( ActiveDirectedExperience != none )
			{
				ActiveDirectedExperience.InvalidMovement(ActiveUnit);
			}		
		}
	}
	*/
}

simulated function EnsureAbortDialogClosedAtEndOfLowFriends()
{
	// fix for bug 23336. This is highly unlikely to happen (who would take Zhang to the extraction point
	// last?), but in case it does make a nice save of a bad situation so the user can complete the mission.
	local XComPresentationLayerBase kPres;
	local XComPlayerController kController;

	kController = XComPlayerController(GetALocalPlayerController());
	if(kController == none) return;

	kPres = kController.Pres;
	if(kPres == none) return;

	// safety check, remove abort prompt if we've already won the match.
	kPres.Get2DMovie().DialogBox.ClearDialogs();
}

simulated function GameStateInitializePlayers(XComGameState AnalyzeGameState)
{
	local XComGameState_Player PlayerState;

	//Iterate the players contained in the game state and create their visualizers
	foreach AnalyzeGameState.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{	 
		class'XGPlayer'.static.CreateVisualizer(PlayerState);
	}
}

simulated function bool IsInitializationComplete()
{
	local XComOnlineEventMgr        OnlineEventMgr;
	local XComWorldData             WorldData;
	local XComGameStateHistory      History;
	local XComContentManager        ContentMgr;
	local X2TacticalGameRuleset     TacticalRules;
	local XComGameInfo              CurrentGameInfo;
	local WorldInfo                 CurrentWorldInfo;

	CurrentWorldInfo = class'Engine'.static.GetCurrentWorldInfo();
	CurrentGameInfo = `XCOMGAME;
	OnlineEventMgr = `ONLINEEVENTMGR;	
	m_kProfileSettings = `XPROFILESETTINGS;
	TacticalRules = `TACTICALRULES;
	WorldData = `XWORLD;
	History = `XCOMHISTORY;
	ContentMgr = `CONTENT;

	return (CurrentWorldInfo!=none) && (CurrentGameInfo!=none) && (OnlineEventMgr!=none) && (m_kProfileSettings!=none) && (TacticalRules!=none) && (WorldData!=none) && (History!=none) && (ContentMgr!=none);
}

// --------------------------------------------------------------
// --------------------------------------------------------------
defaultproperties
{
	m_strObjective = ""
	//RemoteRole = ROLE_SimulatedProxy
	//bAlwaysRelevant = true
	RemoteRole=ROLE_None
	bAlwaysRelevant=false
   	bSkipActorPropertyReplication = true
	m_bLevelStreamingComplete = false
	m_bShowLoadingScreen = true
	m_iNumPlayers = 0
	m_bTacticalIntroDone = false
	m_bIsInited = false;

	m_bPlayerTransition=false
	m_bPlayCinematicIntro=true
	m_bAllowItemFragments=true	
	m_bLoadKismetDataFromSave=false	

	m_iResultCachedThisFrame=false
}
