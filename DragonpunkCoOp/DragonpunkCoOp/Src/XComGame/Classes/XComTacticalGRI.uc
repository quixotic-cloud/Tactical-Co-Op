//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------
class XComTacticalGRI extends XComGameReplicationInfo		
		native(Core)
		dependson(XComContentManager,XComMapManager, XComGameState);

//const MAXCLUSTERBOMBS=6; // This should match the number of fire anim_notify events within the cluster bomb firing animation.

var deprecated XGCharacterGenerator 	m_CharacterGen;
var XGBattle 					        m_kBattle;
var protected XComOnlineProfileSettings m_kProfileSettings;

var SimpleShapeManager                  mSimpleShapeManager;
var XComTraceManager                    m_kTraceMgr;

var private XComPrecomputedPath					m_kPrecomputedPath;
var private XComPrecomputedPath                 m_kPrecomputedPath_Projectiles[`PRECOMPUTEDPATH_PROJECTILEPOOLSIZE];
var private int									m_kPrecomputedPath_ProjectilesIndex;

var class<XGPlayer>                     m_kPlayerClass;

var X2ReactionFireSequencer				ReactionFireSequencer;

var XComDirectedTacticalExperience      DirectedExperience;

//=======================================================================================
//X-Com 2 Refactoring
//
var() XComGameStateHistory                  HistoryObject; //Cache variable for debugging with remote control
var() X2TacticalChallengeModeManager        ChallengeModeManager;
//=======================================================================================

//-----------------------------------------------------------------------
// Delegates for other subsystems to get notified of tactial game events.
//-----------------------------------------------------------------------

enum EXComTacticalEvent
{
	PAWN_INDOOR_OUTDOOR,        // params is: XComPawn
	PAWN_SELECTED,              // params is: XComPawn
	PAWN_UNSELECTED,            // params is: XComPawn
	PAWN_CHANGED_FLOORS,        // params is: XComPawn
};

struct native XComDelegateListToEvent
{
	var EXComTacticalEvent EEvent;
	var array<delegate<XComTacticalDelegate> > DelegateList;
};

// A map of tactical events -> delegates that care about that event
var array<XComDelegateListToEvent> TacticalDelegateLists;

delegate XComTacticalDelegate(XComPawn kPawn);

private simulated function int FindDelegateListForEvent(EXComTacticalEvent EEvent)
{
	local int Index;
	
	for (Index = 0; Index < TacticalDelegateLists.Length; Index++)
	{
		if (EEvent == TacticalDelegateLists[Index].EEvent)
			return Index;
	}
	
	return -1;
}

simulated function ReceivedGameClass()
{
	local XComGameState_ChallengeData ChallengeData;
	local int i;

	super.ReceivedGameClass();

	mSimpleShapeManager = Spawn(class'SimpleShapeManager');

	m_kTraceMgr = spawn(class'XComTraceManager');

	ReactionFireSequencer = Spawn(class'X2ReactionFireSequencer');	
	`XCOMVISUALIZATIONMGR.RegisterObserver(ReactionFireSequencer);

	m_kPrecomputedPath = spawn(class'XComPrecomputedPath');
	for(i = 0; i < `PRECOMPUTEDPATH_PROJECTILEPOOLSIZE; ++i)
	{
		m_kPrecomputedPath_Projectiles[i] = spawn(class'XComPrecomputedPath');
	}
	

	HistoryObject = `XCOMHISTORY;

	m_kBattle = spawn( class 'XGBattle_SPAssault' );

	foreach HistoryObject.IterateByClassType(class'XComGameState_ChallengeData', ChallengeData)
	{
		ChallengeModeManager = Spawn(class'X2TacticalChallengeModeManager', self);
		ChallengeModeManager.Init();
		break;
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function StartMatch()
{
	local bool bTacticalQuickLaunch;
	local bool bAutoTests;
	local string MapName;

	super.StartMatch();

	MapName = WorldInfo.GetMapName(false);
	bTacticalQuickLaunch = MapName == "TacticalQuickLaunch";
	bAutoTests = WorldInfo.Game.MyAutoTestManager != none;

	if(bDropshipLaunch)
	{
		return; //Handled by our base class
	}
	else
	{
		if(bAutoTests)
		{
			// simple init to just drop the loading screen so we can see the tests running
			InitAutoTests();
		}
		else if(bTacticalQuickLaunch)
		{
			//If a quick launch was specified, show the quick launch UI and defer battle initialization
			InitTacticalQuickLaunch();
		}
		else
		{
			InitBattle();
		}
	}
}

//=======================================================================================
//X-Com 2 Refactoring
//
//RAM - most everything in here is temporary until we can kill off all the of XG<classname>
//      types. Eventually the XComGameState_<classname> objects will replace them entirely
//
simulated function BuildVisualizersForInitialGameState()
{		
	local XComGameStateHistory History;
	local XComGameState FullGameState;

	History = `XCOMHISTORY;

	//Get a full copy of the latest game state
	FullGameState = History.GetGameStateFromHistory(-1, eReturnType_Copy, false);

	//Build the battle object and do some initial processing	
	m_kBattle.GameStateInitializePlayers(FullGameState);
}

simulated function BuildStartStateForPIE()
{
	local XComGameStateHistory History;
	local XComGameState TacticalStartState;
	local XComGameState_BattleData BattleDataState;
	local XComOnlineProfileSettings Profile;
	local XComOnlineEventMgr OnlineEventMgr;
	local XComGameState_HeadquartersXCom HeadquartersStateObject;

	History = `XCOMHISTORY;
	History.ResetHistory();

	TacticalStartState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Singleplayer();

	Profile = `XPROFILESETTINGS;	
	//If we have a null profile, see if we can log in to make/load one
	if( Profile == none )
	{
		class'Engine'.static.GetEngine().CreateProfileSettings();
		Profile = XComOnlineProfileSettings(class'Engine'.static.GetEngine().GetProfileSettings());		
		Profile.SetToDefaults();

		OnlineEventMgr = `ONLINEEVENTMGR;
		OnlineEventMgr.ReadProfileSettings();
	}

	//Depending on whether we have a profile or not, load a squad from the profile or make one on the fly
	if( Profile != none )
	{
		Profile.ReadTacticalGameStartState(TacticalStartState);	
	}	
	else
	{
		class'XComOnlineProfileSettings'.static.AddDefaultSoldiersToStartState(TacticalStartState);
	}

	foreach TacticalStartState.IterateByClassType(class'XComGameState_HeadquartersXCom', HeadquartersStateObject)
	{
		break;
	}

	if (HeadquartersStateObject == none)
	{
		HeadquartersStateObject = XComGameState_HeadquartersXCom( TacticalStartState.CreateStateObject( class'XComGameState_HeadquartersXCom' ) );
		HeadquartersStateObject.AdventLootWeight = class'XComGameState_HeadquartersXCom'.default.StartingAdventLootWeight;
		HeadquartersStateObject.AlienLootWeight = class'XComGameState_HeadquartersXCom'.default.StartingAlienLootWeight;
		TacticalStartState.AddStateObject( HeadquartersStateObject );
	}
	
	//Find the battle data in the start state
	foreach TacticalStartState.IterateByClassType(class'XComGameState_BattleData', BattleDataState)
	{
		break;
	}
		
	BattleDataState.iLevelSeed = class'Engine'.static.GetEngine().GetSyncSeed();
	BattleDataState.MapData.PlotMapName = "";
	class'XComGameState_GameTime'.static.CreateGameStartTime(TacticalStartState);	

	History.AddGameStateToHistory(TacticalStartState);
}

simulated function InitTacticalQuickLaunch()
{
	local XComPresentationLayer Pres;

	Pres = XComPresentationLayer( XComPlayerController(GetALocalPlayerController()).Pres );
	if( Pres != none && !Pres.UIIsBusy() )
	{
		Pres.HideLoadingScreen();
		Pres.UITacticalQuickLaunch();
	}
	else
	{
		//Call this method again in .1 seconds to see if the presentation layer is ready or not. Flash takes a while to spin up....
		SetTimer(0.1f, false, nameof(InitTacticalQuickLaunch));
	}
}

simulated function InitAutoTests()
{
	local XComPresentationLayer Pres;

	Pres = XComPresentationLayer( XComPlayerController(GetALocalPlayerController()).Pres );
	if( Pres != none && !Pres.UIIsBusy() )
	{
		Pres.HideLoadingScreen();
	}
	else
	{
		//Call this method again in .1 seconds to see if the presentation layer is ready or not. Flash takes a while to spin up....
		SetTimer(0.1f, false, nameof(InitAutoTests));
	}
}
//=======================================================================================

//-----------------------------------------------------------
simulated function InitBattle()
{   	
	local bool bStandardLoad;
	local XComOnlineEventMgr OnlineEventMgr;
	local X2TacticalGameRuleset TacticalRules;
	local XComTacticalController LocalPlayerController;
	local XComWorldData WorldData;
	local XComGameStateHistory History;
	local XComGameState StartGameState;
	local XComGameState_BattleData BattleData;

	OnlineEventMgr = `ONLINEEVENTMGR;	
	m_kProfileSettings = `XPROFILESETTINGS;
	TacticalRules = `TACTICALRULES;
	WorldData = `XWORLD;
	History = `XCOMHISTORY;	
	bStandardLoad = OnlineEventMgr.bPerformingStandardLoad;			

	if (bStandardLoad)
	{
		// Serializes the save data into the XComGameStateHistory object
		OnlineEventMgr.FinishLoadGame();
	}
	
	//At present, launches from PIE will result in a history that is empty. In this situation
	//we use the start state contained in the profile automatically. Eventually, I would like
	//this PIE state to be read from something in the editor that allows users to customize
	//the start state
	if( History.GetNumGameStates() == 0 )
	{		
		BuildStartStateForPIE();		
	}	

	BuildVisualizersForInitialGameState();	
	
	if( (!m_kBattle.GetDesc().bUseFirstStartTurnSeed) && (!bStandardLoad || m_kBattle.GetDesc().m_arrSecondWave[eGO_RandomSeed] > 0) )
	{	
		class'Engine'.static.GetEngine().SetRandomSeeds(class'Engine'.static.GetEngine().GetARandomSeed());
	}

	//If the world volume does not exist, or is zero sized then don't launch game logic
	if( WorldData != none && WorldData.NumX > 0 )
	{
		StartGameState = History.GetStartState();
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		if( (StartGameState != none) && !BattleData.bIntendedForReloadLevel )
		{
			`log(self $ "::" $ GetFuncName() @ "XCOMHISTORY=" $ History @ "StartState=" $ StartGameState.ToString(), true, 'XCom_GameStates');
			if (`ONLINEEVENTMGR.bIsChallengeModeGame)
			{
				TacticalRules.StartChallengeGame();
			}
			else
			{
				//Save profile settings, as we want to record the present state of the card manager and other systems that 
				//attempt to maximize variety in the procedural maps
				`ONLINEEVENTMGR.SaveProfileSettings(false);

				TacticalRules.StartNewGame();
			}
		}
		else
		{
			`log(self $ "::" $ GetFuncName() @ "XCOMHISTORY=" $ History @ "StartState=NONE", true, 'XCom_GameStates');
			TacticalRules.LoadGame();
		}
	}
	else
	{
		//Entering this block means that the map that has been loaded as a 'tactical' game does not contain a suitable level volume to facilitate game play or
		//cursor navigation. This might be the case for maps which are cinematic or test-only. In this case, simply perform the minimal set of steps necessary 
		//for matinees / effects to work
		LocalPlayerController = XComTacticalController(GetALocalPlayerController());
		LocalPlayerController.ClientSetCameraFade(false);
		LocalPlayerController.SetInputState('Multiplayer_Inactive');

		if( class'XComEngine'.static.IsLoadingMoviePlaying() )
		{	
			`PRES.HideLoadingScreen();		
		}

		`XCOMGRI.DoRemoteEvent('XGBattle_Running_BeginBlockFinished'); //Let kismet know everything is ready
	}
}

simulated function UninitBattle()
{
	if (m_kBattle != None)
	{
		m_kBattle.Uninit();
		m_kBattle.Destroy();
		m_kBattle = None;
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function XGBattle GetBattle()
{
	return m_kBattle;
}

simulated function SaveData(int iSlot);
simulated function LoadData(string strSaveFile);

// jboswell: For native access to the gameplay globals
simulated event int GetCurrentPlayerTurn()
{
	return (m_kBattle != none) ? m_kBattle.m_iPlayerTurn : -1;
}

simulated event int GetNumberOfPlayers()
{
	return (m_kBattle != none) ? m_kBattle.m_iNumPlayers : -1;
}

// If kUnit is passed in, extend test down to the unit's feet.  Otherwise just test the location passed in.
native simulated function bool IsValidLocation(vector vLoc, optional XGUnitNativeBase kUnit, bool bLogFailures=false, bool bAvoidNoSpawnZones=false);
native simulated function vector GetClosestValidLocation(vector vLoc, XGUnitNativeBase kUnit, bool bAllowFlying=false, bool bPrioritizeZ=true, bool bAvoidNoSpawnZones=false);

native simulated function PostLoad_LoadRequiredContent(XComContentManager ContentMgr);

//-----------------------------------------------------------
//-----------------------------------------------------------
simulated function XComLadder FindLadder(Vector vLocation, optional int iRadius = 96, optional int iMaxHeightDiff = 100)
{
	local XComLadder kClosestLadder;
	local XComLadder kLadder;
	local float fClosestDistSq;
	local float fCurrentDistSq;

	fClosestDistSq = 9999*9999;
	kClosestLadder = none;

	foreach AllActors(class'XComLadder', kLadder)
	{
		if (kLadder.GetDistanceSqToClosestMoveToPoint(vLocation, iRadius*iRadius, iMaxHeightDiff, fCurrentDistSq))
		{
			if (fCurrentDistSq < fClosestDistSq)
			{
				fClosestDistSq = fCurrentDistSq;
				kClosestLadder = kLadder;
			}
		}
	}
	return kClosestLadder;
}

// TODO: Add matching UnRegisterDelegate event, e.g. TacticalDelegateLists[ListIndex].DelegateList.Remove(DelegateIndex--,1);
simulated function RegisterTacticalDelegate( delegate<XComTacticalDelegate> D, EXComTacticalEvent EEvent )
{
	local int Index;
	local int Length;
	
	// if it doesn't exists, add it now.
	Index = FindDelegateListForEvent(EEvent);
	if (Index == -1)
	{
		Index = TacticalDelegateLists.Length;
		TacticalDelegateLists.Length = Index + 1;
		
		TacticalDelegateLists[Index].EEvent = EEvent;
	}
	
	// if it already exists, don't add it again
	if (TacticalDelegateLists[Index].DelegateList.Find(D) != INDEX_NONE)
		return;
		
	Length = TacticalDelegateLists[Index].DelegateList.Length;
	TacticalDelegateLists[Index].DelegateList.Length = Length + 1;
	TacticalDelegateLists[Index].DelegateList[Length] = D;
}

// NOTE: params is special.  This class can represent ANY KIND OF OBJECT.
// In your delegate handler, you should dynamically cast and verify that it's 
// the type of object you are expecting.
//
// TODO: If we get a lot of params mismatched due to changed code,
// we should add another struct to verify the type of the params object
// passed in is the type we are expecting for this kind of event.
//
// TODO: Rename to DispatchEvent()
simulated function NotifyOfEvent( EXComTacticalEvent EEvent, XComPawn kPawn )
{
	local int ListIndex, DelegateIndex;
	local delegate<XComTacticalDelegate> DelegateToTrigger;
	
	ListIndex = FindDelegateListForEvent(EEvent);
	if (ListIndex == -1)
		return;

	for (DelegateIndex = 0; DelegateIndex < TacticalDelegateLists[ListIndex].DelegateList.Length; DelegateIndex++)
	{
		DelegateToTrigger = TacticalDelegateLists[ListIndex].DelegateList[DelegateIndex];
		
		// call the delegate
		DelegateToTrigger(kPawn);
	
		// (for future reference: if you wanted to remove it, you'd do this:)
	}
}

//this returns a usable precomputed path for the projectile
simulated function XComPrecomputedPath PrecomputedPathSingleProjectileUse()
{
	if( m_kPrecomputedPath_ProjectilesIndex + 1 >= `PRECOMPUTEDPATH_PROJECTILEPOOLSIZE )
	{
		m_kPrecomputedPath_ProjectilesIndex = 0;
	}
	m_kPrecomputedPath_Projectiles[m_kPrecomputedPath_ProjectilesIndex].bNoSpinUntilBounce = false;
	return m_kPrecomputedPath_Projectiles[m_kPrecomputedPath_ProjectilesIndex++];
}

simulated function XComPrecomputedPath GetPrecomputedPath()
{
	if( m_kPrecomputedPath != none )
	{
		m_kPrecomputedPath.bNoSpinUntilBounce = false;
	}
	return m_kPrecomputedPath;
}

static function X2ReactionFireSequencer GetReactionFireSequencer()
{
	return XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).ReactionFireSequencer;
}

//-----------------------------------------------------------
//-----------------------------------------------------------
replication
{
	if( Role == Role_Authority )
		m_kBattle, m_kPrecomputedPath;
}


//-----------------------------------------------------------
//-----------------------------------------------------------



//-----------------------------------------------------------
//-----------------------------------------------------------

defaultproperties
{
	SoundManagerClassToSpawn = class'XComTacticalSoundManager'
	SoundManager = none
	m_kPlayerClass = class'XGPlayer';
}


