//---------------------------------------------------------------------------------------
//  FILE:    X2TacticalGameRuleset.uc
//  AUTHOR:  Ryan McFall  --  10/9/2013
//  PURPOSE: This actor extends X2GameRuleset to provide special logic and behavior for
//			 the tactical game mode in X-Com 2.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TacticalGameRuleset extends X2GameRuleset 
	dependson(X2GameRulesetVisibilityManager, X2TacticalGameRulesetDataStructures, XComGameState_BattleData)
	config(GameCore)
	native(Core);

// Moved this here from UICombatLose.uc because of dependency issues
enum UICombatLoseType
{
	eUICombatLose_FailableGeneric,
	eUICombatLose_UnfailableGeneric,
	eUICombatLose_UnfailableHQAssault,
	eUICombatLose_UnfailableObjective,
	eUICombatLose_UnfailableCommanderKilled,
};

//******** General Purpose Variables **********
var protected XComTacticalController TacticalController;        //Cache the local player controller. Used primarily during the unit actions phase
var protected XComParcelManager ParcelManager;                  //Cached copy of the parcel mgr
var protected XComPresentationLayer Pres;						//Cached copy of the presentation layer (UI)
var protected bool bShowDropshipInteriorWhileGeneratingMap;		//TRUE if we should show the dropship interior while the map is created for this battle
var protected vector DropshipLocation;
var protected Rotator DropshipRotation;
var protected array<GameRulesCache_Unit> UnitsCache;            //Book-keeping for which abilities are available / not available
var protected StateObjectReference CachedBattleDataRef;         //Reference to the singleton BattleData state for this battle
var protected StateObjectReference CachedXpManagerRef;          //Reference to the singleton XpManager state for this battle
var protected X2UnitRadiusManager UnitRadiusManager;
var protected string BeginBlockWaitingLocation;                 //Debug text relating to where the current code is executing
var protectedwrite array<StateObjectReference> CachedDeadUnits;
`define SETLOC(LocationString) BeginBlockWaitingLocation = GetStateName() $ ":" @ `LocationString;
var private string NextSessionCommandString;
var XComNarrativeMoment TutorialIntro;
var privatewrite bool bRain; //Records TRUE/FALSE whether there is rain in this map
//****************************************

//******** TurnPhase_UnitActions State Variables **********
var protected int UnitActionPlayerIndex;	                    //Index into BattleData.PlayerTurnOrder that keeps track of which player in the list is currently taking unit actions
var StateObjectReference CachedUnitActionPlayerRef;				//Reference to the XComGameState_Player that is currently taking unit actions
var protected StateObjectReference UnitActionUnitRef;           //Reference to the XComGameState_Unit that the player has currently selected
var protected StateObjectReference PriorityUnitRef;             //If a priority unit is designated ( forces this unit to take an action ) then this holds the reference to it
var protected float WaitingForNewStatesTime;                    //Keeps track of how long the unit actions phase has been waiting for a decision from the player.
var privatewrite bool bLoadingSavedGame;						//This variable is true for the duration of TurnPhase_UnitActions::BeginState if the previous state was loading
var private bool bSkipAutosaveAfterLoad;                        //If loading a game, this flag is set to indicate that we don't want to autosave until the next turn starts
var private bool bAlienActivity;                                //Used to give UI indication to player it is the alien's turn
var private bool bSkipRemainingTurnActivty;						//Used to end a player's turn regardless of action availability
//****************************************

//******** EndTacticalGame State Variables **********
var bool bWaitingForMissionSummary;                             //Set to true when we show the mission summary, cleared on pressing accept in that screen
var private bool bTacticalGameInPlay;							// True from the CreateTacticalGame::EndState() -> EndTacticalGame::BeginState(), query using TacticalGameIsInPlay()
var UICombatLoseType LoseType;									// If the mission is lost, this is the type of UI that should be used
var bool bPromptForRestart; 
//****************************************

//******** Config Values **********
var config int UnitHeightAdvantage;                             //Unit's location must be >= this many tiles over another unit to have height advantage against it
var config int UnitHeightAdvantageBonus;                        //Amount of additional Aim granted to a unit with height advantage
var config int UnitHeightDisadvantagePenalty;                   //Amount of Aim lost when firing against a unit with height advantage
var config int XComIndestructibleCoverMaxDifficulty;			//The highest difficulty at which to give xcom the advantage of indestructible cover (from missed shots).
var config float HighCoverDetectionModifier;					// The detection modifier to apply to units when they enter a tile with high cover.
var config float NoCoverDetectionModifier;						// The detection modifier to apply to units when they enter a tile with no high cover.
var config array<string> ForceLoadCinematicMaps;                // Any maps required for Cinematic purposes that may not otherwise be loaded.
var config array<string> arrHeightFogAdjustedPlots;				// any maps required to adjust heightfog actor properties through a remote event.
var config float DepletedAvatarHealthMod;                       // the health mod applied to the first avatar spawned in as a result of skulljacking the codex
var config bool ActionsBlockAbilityActivation;					// the default setting for whether or not X2Actions block ability activation (can be overridden on a per-action basis)
var config float ZipModeMoveSpeed;								// in zip mode, all movement related animations are played at this speed
var config float ZipModeTrivialAnimSpeed;						// in zip mode, all trivial animations (like step outs) are played at this speed
var config float ZipModeDelayModifier;							// in zip mode, all action delays are modified by this value
var config float ZipModeDoomVisModifier;						// in zip mode, the doom visualization timers are modified by this value
//****************************************

var int LastNeutralReactionEventChainIndex; // Last event chain index to prevent multiple civilian reactions from same event. Also used for simultaneous civilian movement.

//******** Delegates **********
delegate SetupStateChange(XComGameState SetupState);
//****************************************

simulated native function int GetLocalClientPlayerObjectID();

// Added for debugging specific ability availability. Called only from cheat manager.
function UpdateUnitAbility( XComGameState_Unit kUnit, name strAbilityName )
{
	local XComGameState_Ability kAbility;
	local StateObjectReference AbilityRef;
	local AvailableAction kAction;

	AbilityRef = kUnit.FindAbility(strAbilityName);
	if (AbilityRef.ObjectID > 0)
	{
		kAbility = XComGameState_Ability(CachedHistory.GetGameStateForObjectID(AbilityRef.ObjectID));
		kAbility.UpdateAbilityAvailability(kAction);
	}
}

function UpdateAndAddUnitAbilities( out GameRulesCache_Unit kUnitCache, XComGameState_Unit kUnit, out array<int> CheckAvailableAbility, out array<int> UpdateAvailableIcon)
{
	local XComGameState_Ability kAbility;
	local AvailableAction kAction, EmptyAction;	
	local int i, ComponentID, HideIf;
	local StateObjectReference OtherAbilityRef;
	local XComGameState_Unit kSubUnit;
	local X2AbilityTemplate AbilityTemplate;

	for (i = 0; i < kUnit.Abilities.Length; ++i)
	{
		kAction = EmptyAction;
		kAbility = XComGameState_Ability(CachedHistory.GetGameStateForObjectID(kUnit.Abilities[i].ObjectID));
		`assert(kAbility != none);
		kAbility.UpdateAbilityAvailability(kAction);
		kUnitCache.AvailableActions.AddItem(kAction);			
		kUnitCache.bAnyActionsAvailable = kUnitCache.bAnyActionsAvailable || kAction.AvailableCode == 'AA_Success';
		if (kAction.eAbilityIconBehaviorHUD == eAbilityIconBehavior_HideIfOtherAvailable)
		{
			AbilityTemplate = kAbility.GetMyTemplate();
			for (HideIf = 0; HideIf < AbilityTemplate.HideIfAvailable.Length; ++HideIf)
			{
				OtherAbilityRef = kUnit.FindAbility(AbilityTemplate.HideIfAvailable[HideIf]);
				if (OtherAbilityRef.ObjectID != 0)
				{
					CheckAvailableAbility.AddItem(OtherAbilityRef.ObjectID);
					UpdateAvailableIcon.AddItem(kUnitCache.AvailableActions.Length - 1);
				}
			}
		}
	}

	if (!kUnit.m_bSubsystem) // Should be no more than 1 level of recursion depth.
	{
		foreach kUnit.ComponentObjectIds(ComponentID)
		{
			kSubUnit = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(ComponentID));
			if (kSubUnit != None)
			{
				UpdateAndAddUnitAbilities(kUnitCache, kSubUnit, CheckAvailableAbility, UpdateAvailableIcon);
			}
		}
	}
}

/// <summary>
/// The local player surrenders from the match, mark as a loss.
/// </summary>
function LocalPlayerForfeitMatch();

/// <summary>
/// Will add a game state to the history marking that the battle is over
/// </summary>
simulated function EndBattle(XGPlayer VictoriousPlayer, optional UICombatLoseType UILoseType = eUICombatLose_FailableGeneric, optional bool GenerateReplaySave = false)
{
	local XComGameStateContext_TacticalGameRule Context;
	local int ReplaySaveID;
	local StateObjectReference SquadMemberRef;
	local XComGameState_Unit SquadMemberState;
	local bool SquadDead;

	LoseType = UILoseType;

	if(class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress())
	{
		SquadDead = true;
		foreach `XCOMHQ.Squad(SquadMemberRef)
		{
			if (SquadMemberRef.ObjectID != 0)
			{
				SquadMemberState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SquadMemberRef.ObjectID));
				if (SquadMemberState != None && SquadMemberState.IsAlive())
				{
					SquadDead = false;
					break;
				}
			}
		}

		if (!SquadDead)
			LoseType = eUICombatLose_UnfailableObjective; //The squad made it out, but we lost - must have been an objective. Don't show "all xcom killed!" screen.
		else
			LoseType = eUICombatLose_UnfailableGeneric;
	}

	bPromptForRestart = !VictoriousPlayer.IsHumanPlayer() && LoseType != eUICombatLose_FailableGeneric;

	// Don't end battles in PIE, at least not for now
	if(WorldInfo.IsPlayInEditor()) return;

	Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_TacticalGameEnd);
	Context.PlayerRef.ObjectID = VictoriousPlayer.ObjectID;
	SubmitGameStateContext(Context);

	if(GenerateReplaySave)
	{
		ReplaySaveID = `AUTOSAVEMGR.GetNextSaveID();
		`ONLINEEVENTMGR.SaveGame(ReplaySaveID, false, false);
	}
}

/// <summary>
/// </summary>
simulated function bool HasTacticalGameEnded()
{
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule Context;

	History = `XCOMHISTORY;
	foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
	{
		if(Context.GameRuleType == eGameRule_TacticalGameEnd)
		{
			return true;
		}
		else if(Context.GameRuleType == eGameRule_TacticalGameStart)
		{
			return false;
		}
	}

	return HasTimeExpired();
}

simulated function bool HasTimeExpired()
{
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));

	return Timer != none && Timer.GetCurrentTime() <= 0;
}

/// <summary>
/// This method builds a local list of state object references for objects that are relatively static, and that we 
/// may need to access frequently. Using the cached ObjectID from a game state object reference is much faster than
/// searching for it each time we need to use it.
/// </summary>
simulated function BuildLocalStateObjectCache()
{	
	local XComGameState_XpManager XpManager;	
	local XComWorldData WorldData;	
	local XComGameState_BattleData BattleDataState;

	super.BuildLocalStateObjectCache();

	//Get a reference to the BattleData for this tactical game
	BattleDataState = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	CachedBattleDataRef = BattleDataState.GetReference();

	foreach CachedHistory.IterateByClassType(class'XComGameState_XpManager', XpManager, eReturnType_Reference)
	{
		CachedXpManagerRef = XpManager.GetReference();
		break;
	}

	TacticalController = XComTacticalController(GetALocalPlayerController());	
	TacticalController.m_kPathingPawn.InitEvents();
	ParcelManager = `PARCELMGR;
	Pres = XComPresentationLayer(XComPlayerController(GetALocalPlayerController()).Pres);	

	//Make sure that the world's OnNewGameState delegate is called prior to the visibility systems, as the vis system is dependent on the
	//world data. Unregistering these delegates is handled natively
	WorldData = `XWORLD;
	WorldData.RegisterForNewGameState();
	WorldData.RegisterForObliterate();

	VisibilityMgr = Spawn(class'X2GameRulesetVisibilityManager', self);
	VisibilityMgr.RegisterForNewGameStateEvent();

	if (BattleDataState.MapData.ActiveMission.sType == "Terror")
	{
		UnitRadiusManager = Spawn( class'X2UnitRadiusManager', self );
	}

	CachedHistory.RegisterOnObliteratedGameStateDelegate(OnObliterateGameState);
	CachedHistory.RegisterOnNewGameStateDelegate(OnNewGameState);
}

function OnObliterateGameState(XComGameState ObliteratedGameState)
{
	local int i, CurrentHistoryIndex;
	CurrentHistoryIndex = CachedHistory.GetCurrentHistoryIndex();
	for( i = 0; i < UnitsCache.Length; i++ )
	{
		if( UnitsCache[i].LastUpdateHistoryIndex > CurrentHistoryIndex )
		{
			UnitsCache[i].LastUpdateHistoryIndex = INDEX_NONE; // Force this to get updated next time.
		}
	}
}

function OnNewGameState(XComGameState NewGameState)
{
	local XComGameStateContext_TacticalGameRule TacticalContext;
	TacticalContext = XComGameStateContext_TacticalGameRule( NewGameState.GetContext() );

	if (IsInState( 'TurnPhase_UnitActions' ) && (TacticalContext != none) && (TacticalContext.GameRuleType == eGameRule_SkipTurn))
	{
		bSkipRemainingTurnActivty = true;
	}
}

/// <summary>
/// Return a state object reference to the static/global battle data state
/// </summary>
simulated function StateObjectReference GetCachedBattleDataRef()
{
	return CachedBattleDataRef;
}

/// <summary>
/// Called by the tactical game start up process when a new battle is starting
/// </summary>
simulated function StartNewGame()
{
	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();

	GotoState('CreateTacticalGame');
}

/// <summary>
/// Called by the tactical game start up process the player is resuming a previously created battle
/// </summary>
simulated function LoadGame()
{
	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();

	GotoState('LoadTacticalGame');
}

/// <summary>
/// Called by the tactical game start up process when a new challenge mission is starting
/// </summary>
simulated function StartChallengeGame()
{
	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();

	GotoState('CreateChallengeGame');
}


/// <summary>
/// Returns true if the visualizer is currently in the process of showing the last game state change
/// </summary>
simulated function bool WaitingForVisualizer()
{
	return class'XComGameStateVisualizationMgr'.static.VisualizerBusy() || (`PRES.m_kEventNotices != None && `PRES.m_kEventNotices.AnyNotices());
}

simulated function AddDefaultPathingCamera()
{
	local XComPlayerController Controller;	

	Controller = XComPlayerController(GetALocalPlayerController());

	// add a default camera.
	if(Controller != none)
	{
		if (Controller.IsMouseActive())
		{
			XComCamera(Controller.PlayerCamera).CameraStack.AddCamera(new class'X2Camera_FollowMouseCursor');
		}
		else
		{
			XComCamera(Controller.PlayerCamera).CameraStack.AddCamera(new class'X2Camera_FollowCursor');
		}
	}
}

/// <summary>
/// Returns cached information about the unit such as what actions are available
/// </summary>
simulated function bool GetGameRulesCache_Unit(StateObjectReference UnitStateRef, out GameRulesCache_Unit OutCacheData)
{
	local AvailableAction kAction;	
	local XComGameState_Unit kUnit;
	local int CurrentHistoryIndex;
	local int ExistingCacheIndex;
	local int i;
	local array<int> CheckAvailableAbility;
	local array<int> UpdateAvailableIcon;
	local GameRulesCache_Unit EmptyCacheData;
	local XComGameState_BaseObject StateObject;

	//Correct us of this method does not 'accumulate' information, so reset the output 
	OutCacheData = EmptyCacheData;

	if (UnitStateRef.ObjectID < 1) //Caller passed in an invalid state object ID
	{
		return false;
	}

	kUnit = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(UnitStateRef.ObjectID));

	if (kUnit == none) //The state object isn't a unit!
	{
		StateObject = CachedHistory.GetGameStateForObjectID(UnitStateRef.ObjectID);
		`redscreen("WARNING! Tried to get cached abilities for non unit game state object:\n"$StateObject.ToString());
		return false;
	}

	if (kUnit.m_bSubsystem) // Subsystem abilities are added to base unit's abilities.
	{
		return false;
	}

	if(kUnit.bDisabled			||          // skip disabled units
	   kUnit.bRemovedFromPlay	||			// removed from play ( ie. exited level )
	   kUnit.GetMyTemplate().bIsCosmetic )	// unit is visual flair, like the gremlin and should not have actions
	{
		return false;
	}

	CurrentHistoryIndex = CachedHistory.GetCurrentHistoryIndex();

	// find our cache data, if any (UnitsCache should be converted to a Map_Mirror when this file is nativized, for faster lookup)
	ExistingCacheIndex = -1;
	for(i = 0; i < UnitsCache.Length; i++)
	{
		if(UnitsCache[i].UnitObjectRef == UnitStateRef)
		{
			if(UnitsCache[i].LastUpdateHistoryIndex == CurrentHistoryIndex)
			{
				// the cached data is still current, so nothing to do
				OutCacheData = UnitsCache[i];
				return true;
			}
			else
			{
				// this cache is outdated, update
				ExistingCacheIndex = i;
				break;
			}
		}
	}

	// build the cache data
	OutCacheData.UnitObjectRef = kUnit.GetReference();
	OutCacheData.LastUpdateHistoryIndex = CurrentHistoryIndex;
	OutCacheData.AvailableActions.Length = 0;
	OutCacheData.bAnyActionsAvailable = false;

	UpdateAndAddUnitAbilities(OutCacheData, kUnit, CheckAvailableAbility, UpdateAvailableIcon);
	for (i = 0; i < CheckAvailableAbility.Length; ++i)
	{
		foreach OutCacheData.AvailableActions(kAction)
		{
			if (kAction.AbilityObjectRef.ObjectID == CheckAvailableAbility[i])
			{
				if (kAction.AvailableCode == 'AA_Success' || kAction.AvailableCode == 'AA_NoTargets')
					OutCacheData.AvailableActions[UpdateAvailableIcon[i]].eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
				else
					OutCacheData.AvailableActions[UpdateAvailableIcon[i]].eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
						
				break;
			}
		}
	}

	if(ExistingCacheIndex == -1)
	{
		UnitsCache.AddItem(OutCacheData);
	}
	else
	{
		UnitsCache[ExistingCacheIndex] = OutCacheData;
	}

	return true;
}

simulated function ETeam GetUnitActionTeam()
{
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
	if( PlayerState != none )
	{
		return PlayerState.TeamFlag;
	}

	return eTeam_None;
}

simulated function bool UnitActionPlayerIsAI()
{
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
	if( PlayerState != none )
	{
		return PlayerState.GetVisualizer().IsA('XGAIPlayer');
	}

	return false;
}

/// <summary>
/// This event is called after a system adds a gamestate to the history, perhaps circumventing the ruleset itself.
/// </summary>
simulated function OnSubmitGameState()
{
	bWaitingForNewStates = false;
}

/// <summary>
/// Overridden per State - determines whether SubmitGameStates can add new states to the history or not. During some 
/// turn phases new state need to be added only at certain times.
/// </summary>
simulated function bool AddNewStatesAllowed()
{
	local bool bAddNewStatesAllowed;	
		
	bAddNewStatesAllowed = super.AddNewStatesAllowed();
	
	//Do not permit new states to be added while we are performing a replay
	bAddNewStatesAllowed = bAddNewStatesAllowed && !XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay;

	return bAddNewStatesAllowed;
}

/// <summary>
/// Overridden per state. Allows states to specify that unit visualizers should not be selectable (and human controlled) at the current time
/// </summary>
simulated function bool AllowVisualizerSelection()
{
	return true;
}

/// <summary>
/// Called whenever the rules authority changes state in the rule engine. This creates a rules engine sate change 
/// history frame that directs non-rules authority instances to change their rule engine state.
/// </summary>
function BeginState_RulesAuthority( delegate<SetupStateChange> SetupStateDelegate )
{
	local XComGameState EnteredNewPhaseGameState;
	local XComGameStateContext_TacticalGameRule NewStateContext;

	NewStateContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());	
	NewStateContext.GameRuleType = eGameRule_RulesEngineStateChange;
	NewStateContext.RuleEngineNextState = GetStateName();
	NewStateContext.SetContextRandSeedFromEngine();
	
	EnteredNewPhaseGameState = CachedHistory.CreateNewGameState(true, NewStateContext);

	if( SetupStateDelegate != none )
	{
		SetupStateDelegate(EnteredNewPhaseGameState);	
	}

	CachedHistory.AddGameStateToHistory(EnteredNewPhaseGameState);
}

/// <summary>
/// Called whenever a non-rules authority receives a rules engine state change history frame.
/// </summary>
simulated function BeginState_NonRulesAuthority(name DestinationState)
{
	local name NextTurnPhase;
	
	//Validate that this state change is legal
	NextTurnPhase = GetNextTurnPhase(GetStateName());
	`assert(DestinationState == NextTurnPhase);

	GotoState(DestinationState);
}

simulated function string GetStateDebugString();

simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string kStr;
	local int iX, iY;
	local XComCheatManager LocalCheatManager;
	
	LocalCheatManager = XComCheatManager(GetALocalPlayerController().CheatManager);

	if( LocalCheatManager != None && LocalCheatManager.bDebugRuleset )
	{
		iX=250;
		iY=50;

		kStr =      "=========================================================================================\n";
		kStr = kStr$"Rules Engine (State"@GetStateName()@")\n";
		kStr = kStr$"=========================================================================================\n";	
		kStr = kStr$GetStateDebugString();
		kStr = kStr$"\n";

		kCanvas.SetPos(iX, iY);
		kCanvas.SetDrawColor(0,255,0);
		kCanvas.DrawText(kStr);
	}
}

private function Object GetEventFilterObject(AbilityEventFilter eventFilter, XComGameState_Unit FilterUnit, XComGameState_Player FilterPlayerState)
{
	local Object FilterObj;

	switch(eventFilter)
	{
	case eFilter_None:
		FilterObj = none;
		break;
	case eFilter_Unit:
		FilterObj = FilterUnit;
		break;
	case eFilter_Player:
		FilterObj = FilterPlayerState;
		break;
	}

	return FilterObj;
}

//  THIS SHOULD ALMOST NEVER BE CALLED OUTSIDE OF NORMAL TACTICAL INIT SEQUENCE. USE WITH EXTREME CAUTION.
simulated function StateObjectReference InitAbilityForUnit(X2AbilityTemplate AbilityTemplate, XComGameState_Unit Unit, XComGameState StartState, optional StateObjectReference ItemRef, optional StateObjectReference AmmoRef)
{
	local X2EventManager EventManager;
	local XComGameState_Ability kAbility;
	local XComGameState_Player PlayerState;
	local Object FilterObj, AbilityObj;
	local AbilityEventListener kListener;
	local X2AbilityTrigger Trigger;
	local X2AbilityTrigger_EventListener AbilityTriggerEventListener;
	local XGUnit UnitVisualizer;
	local StateObjectReference AbilityReference;

	`assert(AbilityTemplate != none);

	//Add a new ability state to StartState
	kAbility = AbilityTemplate.CreateInstanceFromTemplate(StartState);

	if( kAbility != none )
	{
		//Set source weapon as the iterated item
		kAbility.SourceWeapon = ItemRef;
		kAbility.SourceAmmo = AmmoRef;

		//Give the iterated unit state the new ability
		`assert(Unit.bReadOnly == false);
		Unit.Abilities.AddItem(kAbility.GetReference());
		kAbility.InitAbilityForUnit(Unit, StartState);
		AbilityReference = kAbility.GetReference();

		StartState.AddStateObject(kAbility);

		EventManager = `XEVENTMGR;
		PlayerState = XComGameState_Player(StartState.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));
		if (PlayerState == none)
			PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));
		foreach AbilityTemplate.AbilityEventListeners(kListener)
		{
			AbilityObj = kAbility;
			
			FilterObj = GetEventFilterObject(kListener.Filter, Unit, PlayerState);
			EventManager.RegisterForEvent(AbilityObj, kListener.EventID, kListener.EventFn, kListener.Deferral, /*priority*/, FilterObj);
		}
		foreach AbilityTemplate.AbilityTriggers(Trigger)
		{
			if (Trigger.IsA('X2AbilityTrigger_EventListener'))
			{
				AbilityTriggerEventListener = X2AbilityTrigger_EventListener(Trigger);

				FilterObj = GetEventFilterObject(AbilityTriggerEventListener.ListenerData.Filter, Unit, PlayerState);
				AbilityTriggerEventListener.RegisterListener(kAbility, FilterObj);
			}
		}

		// In the case of Aliens, they're spawned with no abilities so we add their perks when we add their ability
		UnitVisualizer = XGUnit(Unit.GetVisualizer());
		if (UnitVisualizer != none)
		{
			UnitVisualizer.GetPawn().AppendAbilityPerks( AbilityTemplate.DataName, , AbilityTemplate.GetPerkAssociationName() );
			UnitVisualizer.GetPawn().StartPersistentPawnPerkFX( AbilityTemplate.DataName );
		}
	}
	else
	{
		`log("WARNING! AbilityTemplate.CreateInstanceFromTemplate FAILED for ability"@AbilityTemplate.DataName);
	}
	return AbilityReference;
}

simulated function InitializeUnitAbilities(XComGameState NewGameState, XComGameState_Unit NewUnit)
{		
	local XComGameState_Player kPlayer;
	local int i;
	local array<AbilitySetupData> AbilityData;
	local bool bIsMultiplayer;
	local X2AbilityTemplate AbilityTemplate;

	`assert(NewGameState != none);
	`assert(NewUnit != None);

	bIsMultiplayer = class'Engine'.static.GetEngine().IsMultiPlayerGame();

	kPlayer = XComGameState_Player(CachedHistory.GetGameStateForObjectID(NewUnit.ControllingPlayer.ObjectID));			
	AbilityData = NewUnit.GatherUnitAbilitiesForInit(NewGameState, kPlayer);
	for (i = 0; i < AbilityData.Length; ++i)
	{
		AbilityTemplate = AbilityData[i].Template;

		if( !AbilityTemplate.IsTemplateAvailableToAnyArea(AbilityTemplate.BITFIELD_GAMEAREA_Tactical) )
		{
			`log(`location @ "WARNING!! Ability:"@ AbilityTemplate.DataName@" is not available in tactical!");
		}
		else if( bIsMultiplayer && !AbilityTemplate.IsTemplateAvailableToAnyArea(AbilityTemplate.BITFIELD_GAMEAREA_Multiplayer) )
		{
			`log(`location @ "WARNING!! Ability:"@ AbilityTemplate.DataName@" is not available in multiplayer!");
		}
		else
		{
			InitAbilityForUnit(AbilityTemplate, NewUnit, NewGameState, AbilityData[i].SourceWeaponRef, AbilityData[i].SourceAmmoRef);
		}
	}
}

simulated function StartStateInitializeUnitAbilities(XComGameState StartState)
{	
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit UnitState;
	local X2ItemTemplate MissionItemTemplate;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// Select the mission item for the current mission (may be None)
	MissionItemTemplate = GetMissionItemTemplate();

	`assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom )
		{
			if(BattleData.DirectTransferInfo.IsDirectMissionTransfer && !UnitState.GetMyTemplate().bIsCosmetic)
			{
				// XCom's abilities will have also transferred over, and do not need to be reapplied
				continue;
			}

			// update the mission items for this XCom unit
			UpdateMissionItemsForUnit(MissionItemTemplate, UnitState, StartState);
		}

		// initialize the abilities for this unit
		InitializeUnitAbilities(StartState, UnitState);
	}
}

simulated function X2ItemTemplate GetMissionItemTemplate()
{
	if (`TACTICALMISSIONMGR.ActiveMission.RequiredMissionItem.Length > 0)
	{
		return class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(`TACTICALMISSIONMGR.ActiveMission.RequiredMissionItem[0]));
	}
	
	return none;
}

simulated function UpdateMissionItemsForUnit(X2ItemTemplate MissionItemTemplate, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Item MissionItemState;
	local StateObjectReference ItemStateRef;

	History = `XCOMHISTORY;

	// remove the existing mission item
	foreach UnitState.InventoryItems(ItemStateRef)
	{
		MissionItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemStateRef.ObjectID));

		if( MissionItemState != None && MissionItemState.InventorySlot == eInvSlot_Mission )
		{
			UnitState.RemoveItemFromInventory(MissionItemState, NewGameState);
		}
	}

	// award the new mission item
	if( MissionItemTemplate != None )
	{
		MissionItemState = MissionItemTemplate.CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(MissionItemState);
		UnitState.AddItemToInventory(MissionItemState, eInvSlot_Mission, NewGameState);
	}
}

simulated function StartStateCreateXpManager(XComGameState StartState)
{
	local XComGameState_XpManager XpManager;

	XpManager = XComGameState_XpManager(StartState.CreateStateObject(class'XComGameState_XpManager'));
	CachedXpManagerRef = XpManager.GetReference();
	XpManager.Init(XComGameState_BattleData(StartState.GetGameStateForObjectID(CachedBattleDataRef.ObjectID)));
	StartState.AddStateObject(XpManager);
}

simulated function StartStateInitializeSquads(XComGameState StartState)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Player PlayerState;
	local array<XComGameState_Unit> XComUnits;
	
	foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetTeam() == eTeam_XCom )
		{
			UnitState.SetBaseMaxStat(eStat_DetectionModifier, HighCoverDetectionModifier);
			XComUnits.AddItem(UnitState);

			// clear out the current hack reward on mission start
			UnitState.CurrentHackRewards.Remove(0, UnitState.CurrentHackRewards.Length);
		}
	}

	foreach StartState.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if (PlayerState.GetTeam() == eTeam_XCom)
		{
			PlayerState.SquadCohesion = class'X2ExperienceConfig'.static.GetSquadCohesionValue(XComUnits);
			break;
		}
	}
}

function ApplyStartOfMatchConditions()
{
	local XComGameState_Player PlayerState;
	local XComGameState_BattleData BattleDataState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComTacticalMissionManager MissionManager;
	local MissionSchedule ActiveMissionSchedule;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2TacticalGameRuleset TactialRuleset;
	local X2HackRewardTemplateManager TemplateMan;
	local X2HackRewardTemplate Template;
	local XComGameState NewGameState;
	local Name HackRewardName;

	History = `XCOMHISTORY;

	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.GetActiveMissionSchedule(ActiveMissionSchedule);

	// set initial squad concealment
	if( ActiveMissionSchedule.XComSquadStartsConcealed )
	{
		foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if( PlayerState.GetTeam() == eTeam_XCom )
			{
				PlayerState.SetSquadConcealment(true, 'StartOfMatchConcealment');
			}
		}
	}
	else
	{
		BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if(!BattleDataState.DirectTransferInfo.IsDirectMissionTransfer) // only apply phantom at the start of the first leg of a multi-part mission
		{
			foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				if( UnitState.FindAbility('Phantom').ObjectID > 0 )
				{
					UnitState.EnterConcealment();
				}
			}
		}
	}

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if( XComHQ != None )	//  TQL doesn't have an HQ object
	{
		UnitState = None;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.GetTeam() == eTeam_XCom )
			{
				break;
			}
		}
		`assert(UnitState != None); // there should always be at least one XCom member at the start of a match

		TemplateMan = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
		TactialRuleset = `TACTICALRULES;
			
		// any Hack Rewards whose name matches a TacticalGameplayTag should be applied now, to the first available XCom unit
		foreach XComHQ.TacticalGameplayTags(HackRewardName)
		{
			Template = TemplateMan.FindHackRewardTemplate(HackRewardName);

			if( Template != None )
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gain Tactical Hack Reward '" $ HackRewardName $ "'");

				UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				NewGameState.AddStateObject(UnitState);

				Template.OnHackRewardAcquired(UnitState, None, NewGameState);

				TactialRuleset.SubmitGameState(NewGameState);
			}
		}
	}
}

simulated function LoadMap()
{
	local XComGameState_BattleData CachedBattleData;
		
	//Check whether the map has been generated already
	if( ParcelManager.arrParcels.Length == 0 )
	{	
		`MAPS.RemoveAllStreamingMaps(); //Generate map requires there to be NO streaming maps when it starts

		CachedBattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		ParcelManager.LoadMap(CachedBattleData);
	}
}

private function AddCharacterStreamingCinematicMaps(bool bBlockOnLoad = false)
{
	local X2CharacterTemplateManager TemplateManager;
	local XComGameStateHistory History;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit UnitState;
	local array<string> MapNames;
	local string MapName;

	History = `XCOMHISTORY;
	TemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	// Force load any specified maps
	MapNames = ForceLoadCinematicMaps;

	// iterate each unit on the map and add it's cinematic maps to the list of maps
	// we need to load
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		CharacterTemplate = TemplateManager.FindCharacterTemplate(UnitState.GetMyTemplateName());
		if (CharacterTemplate != None)
		{
			foreach CharacterTemplate.strMatineePackages(MapName)
			{
				if(MapName != "" && MapNames.Find(MapName) == INDEX_NONE)
				{
					MapNames.AddItem(MapName);
				}
			}
		}
	}

	// and then queue the maps for streaming
	foreach MapNames(MapName)
	{
		`log( "Adding matinee map" $ MapName );
		`MAPS.AddStreamingMap(MapName, , , bBlockOnLoad).bForceNoDupe = true;
	}
}

private function AddDropshipStreamingCinematicMaps()
{
	local XComTacticalMissionManager MissionManager;
	local MissionIntroDefinition MissionIntro;
	local AdditionalMissionIntroPackageMapping AdditionalIntroPackage;
	local XComGroupSpawn kSoldierSpawn;
	local XComGameState StartState;
	local Vector ObjectiveLocation;
	local Vector DirectionTowardsObjective;
	local Rotator ObjectiveFacing;

	StartState = CachedHistory.GetStartState();
	ParcelManager = `PARCELMGR; // make sure this is cached

	//Don't do the cinematic intro if the below isn't correct, as this means we are loading PIE, or directly into a map
	if( StartState != none && ParcelManager != none && ParcelManager.SoldierSpawn != none)
	{
		kSoldierSpawn = ParcelManager.SoldierSpawn;		
		ObjectiveLocation = ParcelManager.ObjectiveParcel.Location;
		DirectionTowardsObjective = ObjectiveLocation - kSoldierSpawn.Location;
		DirectionTowardsObjective.Z = 0;
		ObjectiveFacing = Rotator(DirectionTowardsObjective);
	}

	// load the base intro matinee package
	MissionManager = `TACTICALMISSIONMGR;
	MissionIntro = MissionManager.GetActiveMissionIntroDefinition();
	if( kSoldierSpawn != none && MissionIntro.MatineePackage != "" && MissionIntro.MatineeSequences.Length > 0)
	{	
		`MAPS.AddStreamingMap(MissionIntro.MatineePackage, kSoldierSpawn.Location, ObjectiveFacing, false).bForceNoDupe = true;
	}

	// load any additional packages that mods may require
	foreach MissionManager.AdditionalMissionIntroPackages(AdditionalIntroPackage)
	{
		if(AdditionalIntroPackage.OriginalIntroMatineePackage == MissionIntro.MatineePackage)
		{
			`MAPS.AddStreamingMap(AdditionalIntroPackage.AdditionalIntroMatineePackage, kSoldierSpawn.Location, ObjectiveFacing, false).bForceNoDupe = true;
		}
	}
}

function EndReplay()
{

}

// Used in Tutorial mode to put the state back into 'PerformingReplay'
function ResumeReplay()
{
	GotoState('PerformingReplay');
}
function EventListenerReturn HandleNeutralReactionsOnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	// Kick off civilian movement when an enemy unit takes a shot nearby.
	local XComGameState_Ability ActivatedAbilityState;
	local XComGameStateContext_Ability ActivatedAbilityStateContext;
	local XComGameState_Unit SourceUnitState;
	local XComGameState_Item WeaponState;
	local int SoundRange;
	local float SoundRangeUnitsSq;
	local TTile SoundTileLocation;
	local Vector SoundLocation;
	local XComGameStateHistory History;
	local StateObjectReference CivilianPlayerRef;
	local array<GameRulesCache_VisibilityInfo> VisInfoList;
	local GameRulesCache_VisibilityInfo VisInfo;
	local XComGameState_Unit CivilianState;
	local array<XComGameState_Unit> Civilians;
	local XComGameState_BattleData Battle;
	local bool bAIAttacksCivilians;
	local XGUnit Civilian;
	local XGAIPlayer_Civilian CivilianPlayer;

	History = `XCOMHISTORY;
	Battle = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	bAIAttacksCivilians = Battle.AreCiviliansAlienTargets();
	if( bAIAttacksCivilians )
	{
		ActivatedAbilityStateContext = XComGameStateContext_Ability(GameState.GetContext());
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.SourceObject.ObjectID));
		ActivatedAbilityState = XComGameState_Ability(EventData);
		if( SourceUnitState.ControllingPlayerIsAI() && ActivatedAbilityState.DoesAbilityCauseSound() )
		{
			if( ActivatedAbilityStateContext != None && ActivatedAbilityStateContext.InputContext.ItemObject.ObjectID > 0 )
			{
				WeaponState = XComGameState_Item(GameState.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.ItemObject.ObjectID));
				if( WeaponState != None )
				{
					SoundRange = WeaponState.GetItemSoundRange();
					SoundRangeUnitsSq = Square(`METERSTOUNITS(SoundRange));
					// Find civilians within sound range of the source and target, and add them to the list of civilians to react.
					if( SoundRange > 0 )
					{
						CivilianPlayerRef = class'X2TacticalVisibilityHelpers'.static.GetPlayerFromTeamEnum(eTeam_Neutral);
						// Find civilians in range of the source location.
						SoundTileLocation = SourceUnitState.TileLocation;
						class'X2TacticalVisibilityHelpers'.static.GetAllTeamUnitsForTileLocation(SoundTileLocation, CivilianPlayerRef.ObjectID, eTeam_Neutral, VisInfoList);
						foreach VisInfoList(VisInfo)
						{
							if( VisInfo.DefaultTargetDist < SoundRangeUnitsSq )
							{
								CivilianState = XComGameState_Unit(History.GetGameStateForObjectID(VisInfo.SourceID));
								if( !CivilianState.bRemovedFromPlay && Civilians.Find(CivilianState) == INDEX_NONE )
								{
									Civilians.AddItem(CivilianState);
								}
							}
						}

						// Also find civilians in range of the target location.
						if( ActivatedAbilityStateContext.InputContext.TargetLocations.Length > 0 )
						{
							VisInfoList.Length = 0;
							SoundLocation = ActivatedAbilityStateContext.InputContext.TargetLocations[0];
							class'X2TacticalVisibilityHelpers'.static.GetAllTeamUnitsForLocation(SoundLocation, CivilianPlayerRef.ObjectID, eTeam_Neutral, VisInfoList);
							foreach VisInfoList(VisInfo)
							{
								if( VisInfo.DefaultTargetDist < SoundRangeUnitsSq )
								{
									CivilianState = XComGameState_Unit(History.GetGameStateForObjectID(VisInfo.SourceID));
									if( !CivilianState.bRemovedFromPlay && Civilians.Find(CivilianState) == INDEX_NONE )
									{
										Civilians.AddItem(CivilianState);
									}
								}
							}
						}

						// Adding civilian target unit if not dead.  
						CivilianState = XComGameState_Unit(History.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.PrimaryTarget.ObjectID));
						if( CivilianState.GetTeam() == eTeam_Neutral 
						   && CivilianState.IsAlive() 
						   && !CivilianState.bRemovedFromPlay 
						   && Civilians.Find(CivilianState) == INDEX_NONE )
						{
							Civilians.AddItem(CivilianState);
						}

						LastNeutralReactionEventChainIndex = History.GetEventChainStartIndex();
						CivilianPlayer = XGBattle_SP(`BATTLE).GetCivilianPlayer();
						CivilianPlayer.InitTurn();

						// Any civilians we've found in range will now run away.
						foreach Civilians(CivilianState)
						{
							Civilian = XGUnit(CivilianState.GetVisualizer());
							XGAIBehavior_Civilian(Civilian.m_kBehavior).InitActivate();
							CivilianState.AutoRunBehaviorTree();
							CivilianPlayer.AddToMoveList(Civilian);
						}
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn HandleNeutralReactionsOnMovement(Object EventData, Object EventSource, XComGameState GameState, Name EventID) 
{
	local XComGameState_Unit MovedUnit, CivilianState;
	local array<XComGameState_Unit> Civilians;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local XComGameState_BattleData Battle;
	local XGAIPlayer_Civilian CivilianPlayer;
	local XGUnit Civilian;
	local bool bAIAttacksCivilians, bCiviliansRunFromXCom;
	local int EventChainIndex;
	local TTile MovedToTile;
	local float MaxTileDistSq;
	local GameRulesCache_VisibilityInfo OutVisInfo;
	local ETeam MoverTeam;

	MovedUnit = XComGameState_Unit( EventData );
	MoverTeam = MovedUnit.GetTeam();
	if( MovedUnit.IsMindControlled() )
	{
		MoverTeam = MovedUnit.GetPreviousTeam();
	}
	if( (MovedUnit == none) || MovedUnit.GetMyTemplate().bIsCosmetic || (XGUnit(MovedUnit.GetVisualizer()).m_eTeam == eTeam_Neutral) )
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	Battle = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	bCiviliansRunFromXCom = Battle.CiviliansAreHostile();
	bAIAttacksCivilians = Battle.AreCiviliansAlienTargets();

	// In missions where AI doesn't attack civilians, do nothing if the player or the mover is concealed.
	if(!bAIAttacksCivilians )
	{
		// If XCom is in squad concealment, don't move.
		foreach History.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
		{
			if( PlayerState.PlayerClassName == Name("XGPlayer") )
			{
				if( PlayerState.bSquadIsConcealed )
				{
					return ELR_NoInterrupt; // Do not move if squad concealment is active.
				}
				break;
			}
		}

		if( MovedUnit.IsConcealed() && bCiviliansRunFromXCom )
		{
			return ELR_NoInterrupt;
		}
	}
	else
	{
		// Addendum from Brian - only move civilians from Aliens when the alien that moves is out of action points.
		if( MoverTeam == eTeam_Alien && MovedUnit.NumAllActionPoints() > 0 && MovedUnit.IsMeleeOnly() )
		{
			return ELR_NoInterrupt;
		}
	}

	// Only kick off civilian behavior once per event chain.
	EventChainIndex = History.GetEventChainStartIndex();
	if( EventChainIndex == LastNeutralReactionEventChainIndex )
	{
		return ELR_NoInterrupt;
	}
	LastNeutralReactionEventChainIndex = EventChainIndex;

	// All civilians in range now update.
	CivilianPlayer = XGBattle_SP(`BATTLE).GetCivilianPlayer();
	CivilianPlayer.InitTurn();
	CivilianPlayer.GetPlayableUnits(Civilians);

	MovedToTile = MovedUnit.TileLocation;
	MaxTileDistSq = Square(class'XGAIBehavior_Civilian'.default.CIVILIAN_NEAR_STANDARD_REACT_RADIUS);

	// Kick off civilian behavior tree if it is in range of the enemy.
	foreach Civilians(CivilianState)
	{
		// Let kismet handle XCom rescue behavior.
		if( bAIAttacksCivilians && !CivilianState.IsAlien() && MoverTeam == eTeam_XCom )
		{
			continue;
		}
		// Let the Ability trigger system handle Faceless units when XCom moves into range. 
		if( CivilianState.IsAlien() && MoverTeam == eTeam_XCom )
		{
			continue;
		}

		// Non-rescue behavior is kicked off here.
		if( class'Helpers'.static.IsTileInRange(CivilianState.TileLocation, MovedToTile, MaxTileDistSq) 
		   && VisibilityMgr.GetVisibilityInfo(MovedUnit.ObjectID, CivilianState.ObjectID, OutVisInfo)
			&& OutVisInfo.bVisibleGameplay )
		{
			Civilian = XGUnit(CivilianState.GetVisualizer());
			XGAIBehavior_Civilian(Civilian.m_kBehavior).InitActivate();
			CivilianState.AutoRunBehaviorTree();
			CivilianPlayer.AddToMoveList(Civilian);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn HandleUnitDiedCache(Object EventData, Object EventSource, XComGameState GameState, Name EventID) 
{
	local XComGameState_Unit DeadUnit;

	DeadUnit = XComGameState_Unit( EventData );

	if( (DeadUnit == none) || DeadUnit.GetMyTemplate().bIsCosmetic )
	{
		return ELR_NoInterrupt;
	}

	CachedDeadUnits.AddItem(DeadUnit.GetReference());

	return ELR_NoInterrupt;
}

function EventListenerReturn HandleAdditionalFalling(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateHistory History;
	local StateObjectReference UnitRef;
	local XComGameState_Unit DeadUnit;
	local XComWorldData WorldData;

	local XComGameState_LootDrop Loot, FallLoot;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	foreach CachedDeadUnits(UnitRef)
	{
		DeadUnit = XComGameState_Unit( History.GetGameStateForObjectID( UnitRef.ObjectID ) );

		if( DeadUnit != none && !WorldData.IsTileOutOfRange(DeadUnit.TileLocation) )
		{
			if ((XGUnit(DeadUnit.GetVisualizer()).GetPawn().RagdollFlag == ERagdoll_Never) && DeadUnit.bFallingApplied)
			{
				continue;
			}

			if (!WorldData.IsFloorTile( DeadUnit.TileLocation ))
			{
				WorldData.SubmitUnitFallingContext( DeadUnit, DeadUnit.TileLocation );
			}
		}
	}

	foreach History.IterateByClassType( class'XComGameState_LootDrop', Loot )
	{
		if (!WorldData.IsTileOutOfRange(DeadUnit.TileLocation) && !WorldData.IsFloorTile( Loot.TileLocation ))
		{
			if (NewGameState == none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Loot Falling" );
			}

			FallLoot = XComGameState_LootDrop( NewGameState.CreateStateObject( class'XComGameState_LootDrop', Loot.ObjectID ) );
			FallLoot.TileLocation.Z = WorldData.GetFloorTileZ( Loot.TileLocation, true );

			NewGameState.AddStateObject( FallLoot );

			NewGameState.GetContext( ).PostBuildVisualizationFn.AddItem( FallLoot.VisualizeLootFountainMove );
		}
	}

	if (NewGameState != none)
	{
		SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

simulated function bool CanToggleWetness()
{
	local XComGameState_BattleData BattleDataState;
	local PlotDefinition PlotDef;
	local bool bWet;
	local string strMissionType;	

	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	bWet = false;
	strMissionType = "";
	if (BattleDataState != none)
	{
		PlotDef = `PARCELMGR.GetPlotDefinition(BattleDataState.MapData.PlotMapName);

		// much hackery follows...
		// using LightRain for precipitation without sound effects and lightning, and LightStorm for precipitation with sounds effects and lightning
		switch (PlotDef.strType)
		{
		case "Shanty":
			// This could be cleaner without all the calls to XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(),
			// but attempting to use a variable required modifying what this class depends on. That resulted in some unreal weirdness that changed some headers
			// and functions that I never touched, which I wasn't comfortable with.
			XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(LightRain, 0, 0, 0);			
			break;
		case "Facility":
		case "DerelictFacility":
		case "LostTower":
			XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(NoStorm, 0, 0, 0);
			break;
		default:
			// PsiGate acts like Shanty above, but it's a mission, not a plotType
			strMissionType = BattleDataState.MapData.ActiveMission.sType;
			if (strMissionType == "GP_PsiGate")
			{
				XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(LightRain, 0, 0, 0);
			}
			else if (BattleDataState.bRainIfPossible)
			{
				// Nothing for Arid. Tundra gets snow only. Temperate gets wetness, precipitation, sound effects and lightning.
				if (BattleDataState.MapData.Biome == "" || BattleDataState.MapData.Biome == "Temperate" || PlotDef.strType == "CityCenter" || PlotDef.strType == "Slums")
				{					
					XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(LightStorm, 0, 0, 0);
					bWet = true;
				}
				else if (BattleDataState.MapData.Biome == "Tundra")
				{
					XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(LightRain, 0, 0, 0);
				}
				else
				{
					XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(NoStorm, 0, 0, 0);
				}
			}
			else
			{
				XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(NoStorm, 0, 0, 0);
			}
			break;
		}
	}
	else
	{
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().SetStormIntensity(NoStorm, 0, 0, 0);
	}

	return bWet;
}

// Do any specific remote events related to environment lighting
simulated function EnvironmentLightingRemoteEvents()
{
	local XComGameState_BattleData BattleDataState;

	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// Forge only check to change the height fog actors to mask out the underneath of forge parcel that can be seen through glass floors (yay run on sentence)
	if (BattleDataState.MapData.PlotMapName != "" && arrHeightFogAdjustedPlots.Find(BattleDataState.MapData.PlotMapName) != INDEX_NONE)
	{
		`XCOMGRI.DoRemoteEvent('ModifyHeightFogActorProperties');
	}
}

// Call after abilities are initialized in post begin play, which may adjust stats.
// This function restores all transferred units' stats to their pre-transfer values, 
// to help maintain the illusion of one continuous mission
simulated private function RestoreDirectTransferUnitStats()
{
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local DirectTransferInformation_UnitStats UnitStats;
	local XComGameState_Unit UnitState;

	BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(!BattleData.DirectTransferInfo.IsDirectMissionTransfer)
	{
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Restore Transfer Unit Stats");

	foreach BattleData.DirectTransferInfo.TransferredUnitStats(UnitStats)
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitStats.UnitStateRef.ObjectID));
		UnitState.SetCurrentStat(eStat_HP, UnitStats.HP);
		UnitState.AddShreddedValue(UnitStats.ArmorShred);
		UnitState.LowestHP = UnitStats.LowestHP;
		UnitState.HighestHP = UnitStats.HighestHP;
		NewGameState.AddStateObject(UnitState);
	}

	SubmitGameState(NewGameState);
}

simulated function BeginTacticalPlay()
{
	local XComGameState_BaseObject ObjectState, NewObjectState;
	local XComGameState_Ability AbilityState;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Begin Tactical Play");

	foreach CachedHistory.IterateByClassType(class'XComGameState_BaseObject', ObjectState)
	{
		NewObjectState = NewGameState.CreateStateObject(ObjectState.Class, ObjectState.ObjectID);
		NewGameState.AddStateObject(NewObjectState);
		NewObjectState.bInPlay = false;
	}

	bTacticalGameInPlay = true;

	// have any abilities that are post play activated start up
	foreach CachedHistory.IterateByClassType(class'XComGameState_Ability', AbilityState)
	{
		if(AbilityState.OwnerStateObject.ObjectID > 0)
		{
			AbilityState.CheckForPostBeginPlayActivation();
		}
	}

	// iterate through all existing state objects and call BeginTacticalPlay on them
	foreach NewGameState.IterateByClassType(class'XComGameState_BaseObject', ObjectState)
	{
		ObjectState.BeginTacticalPlay();
	}

	// if we're playing a challenge, don't do much encounter vo
	if (CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) != none)
	{
		`CHEATMGR.DisableFirstEncounterVO = true;
	}

	`XEVENTMGR.TriggerEvent('OnTacticalBeginPlay', self, , NewGameState);

	SubmitGameState(NewGameState);

	RestoreDirectTransferUnitStats();
}

simulated function EndTacticalPlay()
{
	local XComGameState_BaseObject ObjectState, NewObjectState;
	local XComGameState NewGameState;
	local X2EventManager EventManager;
	local Object ThisObject;
	local XComGameInfo GameInfo;

	bTacticalGameInPlay = false;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("End Tactical Play");

	GameInfo = `XCOMGAME;

	// iterate through all existing state objects and call EndTacticalPlay on them
	foreach CachedHistory.IterateByClassType(class'XComGameState_BaseObject', ObjectState)
	{
		if (GameInfo.TransientTacticalClassNames.Find( ObjectState.Class.Name ) == -1)
		{
			NewObjectState = NewGameState.CreateStateObject( ObjectState.Class, ObjectState.ObjectID );
			NewGameState.AddStateObject( NewObjectState );
			NewObjectState.EndTacticalPlay( );
		}
		else
		{
			ObjectState.EndTacticalPlay( );
		}		
	}

	EventManager = `XEVENTMGR;
		ThisObject = self;

	EventManager.UnRegisterFromEvent(ThisObject, 'UnitMoveFinished');
	EventManager.UnRegisterFromEvent(ThisObject, 'UnitDied');

	SubmitGameState(NewGameState);
}

static function CleanupTacticalMission(optional bool bSimCombat = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local int LootIndex, ObjectiveIndex;
	local X2ItemTemplateManager ItemTemplateManager;
	local XComGameState_Item ItemState;
	local XComGameState_Unit UnitState;
	local XComGameState_LootDrop LootDropState;
	local Name ObjectiveLootTableName;
	local X2LootTableManager LootManager;
	local array<Name> RolledLoot;
	local XComGameState_XpManager XpManager, NewXpManager;
	local int MissionIndex;
	local MissionDefinition RefMission;

	History = `XCOMHISTORY;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cleanup Tactical Mission");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.bReturningFromMission = true;
	XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.Remove(0, XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.Length);

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	NewGameState.AddStateObject(BattleData);

	// Sweep objective resolution:
	// if all tactical mission objectives completed, all bodies and loot are recovered
	if( BattleData.AllTacticalObjectivesCompleted() )
	{
		// recover all dead soldiers, remove all other soldiers from play/clear deathly ailments
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( XComHQ.IsUnitInSquad(UnitState.GetReference()) )
			{
				UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				NewGameState.AddStateObject(UnitState);
				UnitState.RemoveUnitFromPlay();
				UnitState.bBleedingOut = false;
				UnitState.bUnconscious = false;

				if( UnitState.IsDead() )
				{
					UnitState.bBodyRecovered = true;
				}
			}
		}

		foreach History.IterateByClassType(class'XComGameState_LootDrop', LootDropState)
		{
			for( LootIndex = 0; LootIndex < LootDropState.LootableItemRefs.Length; ++LootIndex )
			{
				ItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', LootDropState.LootableItemRefs[LootIndex].ObjectID));
				NewGameState.AddStateObject(ItemState);

				ItemState.OwnerStateObject = XComHQ.GetReference();
				XComHQ.PutItemInInventory(NewGameState, ItemState, true);

				BattleData.CarriedOutLootBucket.AddItem(ItemState.GetMyTemplateName());
			}
		}

		// 7/29/15 Non-explicitly-picked-up loot is now once again only recovered if the sweep objective was completed
		RolledLoot = BattleData.AutoLootBucket;
	}
	else
	{
		//It may be the case that the user lost as a result of their remaining units being mind-controlled. Consider them captured (before the mind-control effect gets wiped).
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if (XComHQ.IsUnitInSquad(UnitState.GetReference()))
			{
				if (UnitState.IsMindControlled())
				{
					UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
					UnitState.bCaptured = true;
					NewGameState.AddStateObject(UnitState);
				}
			}
		}
	}

	//Backwards compatibility support for campaigns started when mission objectives could only have one loot table
	MissionIndex = class'XComTacticalMissionManager'.default.arrMissions.Find('MissionName', BattleData.MapData.ActiveMission.MissionName);
	if ( MissionIndex > -1)
	{
		RefMission = class'XComTacticalMissionManager'.default.arrMissions[MissionIndex];
	}
	
	// add loot for each successful Mission Objective
	LootManager = class'X2LootTableManager'.static.GetLootTableManager();
	for( ObjectiveIndex = 0; ObjectiveIndex < BattleData.MapData.ActiveMission.MissionObjectives.Length; ++ObjectiveIndex )
	{
		if( BattleData.MapData.ActiveMission.MissionObjectives[ObjectiveIndex].bCompleted )
		{
			ObjectiveLootTableName = GetObjectiveLootTable(BattleData.MapData.ActiveMission.MissionObjectives[ObjectiveIndex]);
			if (ObjectiveLootTableName == '' && RefMission.MissionObjectives[ObjectiveIndex].SuccessLootTables.Length > 0)
			{
				//Try again with the ref mission, backwards compatibility support
				ObjectiveLootTableName = GetObjectiveLootTable(RefMission.MissionObjectives[ObjectiveIndex]);
			}

			if( ObjectiveLootTableName != '' )
			{
				LootManager.RollForLootTable(ObjectiveLootTableName, RolledLoot);
			}
		}
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	for( LootIndex = 0; LootIndex < RolledLoot.Length; ++LootIndex )
	{
		// create the loot item
		ItemState = ItemTemplateManager.FindItemTemplate(
			RolledLoot[LootIndex]).CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(ItemState);

		// assign the XComHQ as the new owner of the item
		ItemState.OwnerStateObject = XComHQ.GetReference();

		// add the item to the HQ's inventory of loot items
		XComHQ.PutItemInInventory(NewGameState, ItemState, true);
	}

	//  Distribute XP
	if( !bSimCombat )
	{
		XpManager = XComGameState_XpManager(History.GetSingleGameStateObjectForClass(class'XComGameState_XpManager', true)); //Allow null for sim combat / cheat start
		NewXpManager = XComGameState_XpManager(NewGameState.CreateStateObject(class'XComGameState_XpManager', XpManager == none ? -1 : XpManager.ObjectID));
		NewXpManager.DistributeTacticalGameEndXp(NewGameState);
		NewGameState.AddStateObject(NewXpManager);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function name GetObjectiveLootTable(MissionObjectiveDefinition MissionObj)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local name LootTableName;
	local int CurrentForceLevel, HighestValidForceLevel, idx;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	CurrentForceLevel = AlienHQ.GetForceLevel();

	if (MissionObj.SuccessLootTables.Length == 0)
	{
		return ''; 
	}

	HighestValidForceLevel = -1;

	for(idx = 0; idx < MissionObj.SuccessLootTables.Length; idx++)
	{
		if(CurrentForceLevel >= MissionObj.SuccessLootTables[idx].ForceLevel &&
		   MissionObj.SuccessLootTables[idx].ForceLevel > HighestValidForceLevel)
		{
			HighestValidForceLevel = MissionObj.SuccessLootTables[idx].ForceLevel;
			LootTableName = MissionObj.SuccessLootTables[idx].LootTableName;
		}
	}

	return LootTableName;
}

function StartStatePositionUnits()
{
	local XComGameState StartState;		
	local XComGameState_Player PlayerState;
	local XComGameState_Unit UnitState;
	
	local vector vSpawnLoc;
	local XComGroupSpawn kSoldierSpawn;
	local array<vector> FloorPoints;

	StartState = CachedHistory.GetStartState();
	ParcelManager = `PARCELMGR; // make sure this is cached

	//If this is a start state, we need to additional processing. Place the player's
	//units. Create and place the AI player units.
	//======================================================================
	if( StartState != none )
	{
		if(ParcelManager == none || ParcelManager.SoldierSpawn == none)
		{
			// We're probably loaded in PIE, which doesn't go through the parcel manager. Just grab any spawn point for
			// testing
			foreach `XWORLDINFO.AllActors(class'XComGroupSpawn', kSoldierSpawn) { break; }
		}
		else
		{
			kSoldierSpawn = ParcelManager.SoldierSpawn;
		}
			

		ParcelManager.ParcelGenerationAssert(kSoldierSpawn != none, "No Soldier Spawn found when positioning units!");
			
		kSoldierSpawn.GetValidFloorLocations(FloorPoints);

		ParcelManager.ParcelGenerationAssert(FloorPoints.Length > 0, "No valid floor points for spawn: " $ kSoldierSpawn);
						
		//Updating the positions of the units
		foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
		{				
			`assert(UnitState.bReadOnly == false);

			PlayerState = XComGameState_Player(StartState.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID, eReturnType_Reference));			
			if (PlayerState != None && PlayerState.TeamFlag == ETeam.eTeam_XCom && UnitState.ControllingPlayer.ObjectID == PlayerState.ObjectID)
			{
				vSpawnLoc = FloorPoints[`SYNC_RAND_TYPED(FloorPoints.Length)];
				FloorPoints.RemoveItem(vSpawnLoc);						

				UnitState.SetVisibilityLocationFromVector(vSpawnLoc);
				`XWORLD.SetTileBlockedByUnitFlag(UnitState);
			}
		}
	}
}

/// <summary>
/// Cycles through building volumes and update children floor volumes and extents. Needs to happen early in loading, before units spawn.
/// </summary>
simulated function InitVolumes()
{
	local XComBuildingVolume kVolume;
	local XComMegaBuildingVolume kMegaVolume;

	foreach WorldInfo.AllActors(class 'XComBuildingVolume', kVolume)
	{
		if (kVolume != none)   // Hack to eliminate tree break
		{
			kVolume.CacheBuildingVolumeInChildrenFloorVolumes();
			kVolume.CacheFloorCenterAndExtent();
		}
	}

	foreach WorldInfo.AllActors(class 'XComMegaBuildingVolume', kMegaVolume)
	{
		if (kMegaVolume != none)
		{
			kMegaVolume.InitInLevel();
			kMegaVolume.CacheBuildingVolumeInChildrenFloorVolumes();
			kMegaVolume.CacheFloorCenterAndExtent();
		}
	}
}

/// <summary>
/// This state is entered if the tactical game being played need to be set up first. Setup handles placing units, creating scenario
/// specific game states, processing any scenario kismet logic, etc.
/// </summary>
simulated state CreateTacticalGame
{
	simulated event BeginState(name PreviousStateName)
	{
		local X2EventManager EventManager;
		local Object ThisObject;

		// the start state has been added by this point
		//	nothing in this state should be adding anything that is not added to the start state itself
		CachedHistory.AddHistoryLock();

		EventManager = `XEVENTMGR;
		ThisObject = self;

		EventManager.RegisterForEvent(ThisObject, 'UnitMoveFinished', HandleNeutralReactionsOnMovement, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'AbilityActivated', HandleNeutralReactionsOnAbilityActivated, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'UnitDied', HandleUnitDiedCache, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'TileDataChanged', HandleAdditionalFalling, ELD_OnStateSubmitted);
	}
	
	simulated function StartStateSpawnAliens(XComGameState StartState)
	{
		local XComGameState_Player IteratePlayerState;
		local XComGameState_BattleData BattleData;
		local XComGameState_MissionSite MissionSiteState;
		local XComAISpawnManager SpawnManager;
		local int AlertLevel, ForceLevel;

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		ForceLevel = BattleData.GetForceLevel();
		AlertLevel = BattleData.GetAlertLevel();

		if( BattleData.m_iMissionID > 0 )
		{
			MissionSiteState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(BattleData.m_iMissionID));

			if( MissionSiteState != None && MissionSiteState.SelectedMissionData.SelectedMissionScheduleName != '' )
			{
				AlertLevel = MissionSiteState.SelectedMissionData.AlertLevel;
				ForceLevel = MissionSiteState.SelectedMissionData.ForceLevel;
			}
		}

		SpawnManager = `SPAWNMGR;
		SpawnManager.SpawnAllAliens(ForceLevel, AlertLevel, StartState, MissionSiteState);

		// After spawning, the AI player still needs to sync the data
		foreach StartState.IterateByClassType(class'XComGameState_Player', IteratePlayerState)
		{
			if( IteratePlayerState.TeamFlag == eTeam_Alien )
			{				
				XGAIPlayer( CachedHistory.GetVisualizer(IteratePlayerState.ObjectID) ).UpdateDataToAIGameState(true);
				break;
			}
		}
	}

	simulated function StartStateSpawnCosmeticUnits(XComGameState StartState)
	{
		local XComGameState_Item IterateItemState;
				
		foreach StartState.IterateByClassType(class'XComGameState_Item', IterateItemState)
		{
			IterateItemState.CreateCosmeticItemUnit(StartState);
		}
	}

	function SetupPIEGame()
	{
		local XComParcel FakeObjectiveParcel;
		local MissionDefinition MissionDef;

		local Sequence GameSequence;
		local Sequence LoadedSequence;
		local array<string> KismetMaps;

		local X2DataTemplate ItemTemplate;
		local X2QuestItemTemplate QuestItemTemplate;

		// Since loading a map in PIE just gives you a single parcel and possibly a mission map, we need to
		// infer the mission type and create a fake objective parcel so that the LDs can test the game in PIE

		// This would normally be set when generating a map
		ParcelManager.TacticalMissionManager = `TACTICALMISSIONMGR;

		// Get the map name for all loaded kismet sequences
		GameSequence = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
		foreach GameSequence.NestedSequences(LoadedSequence)
		{
			// when playing in PIE, maps names begin with "UEDPIE". Strip that off.
			KismetMaps.AddItem(split(LoadedSequence.GetLevelName(), "UEDPIE", true));
		}

		// determine the mission 
		foreach ParcelManager.TacticalMissionManager.arrMissions(MissionDef)
		{
			if(KismetMaps.Find(MissionDef.MapNames[0]) != INDEX_NONE)
			{
				ParcelManager.TacticalMissionManager.ActiveMission = MissionDef;
				break;
			}
		}

		// Add a quest item in case the mission needs one. we don't care which one, just grab the first
		foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(ItemTemplate, none)
		{
			QuestItemTemplate = X2QuestItemTemplate(ItemTemplate);

			if(QuestItemTemplate != none)
			{
				ParcelManager.TacticalMissionManager.MissionQuestItemTemplate = QuestItemTemplate.DataName;
				break;
			}
		}
		
		// create a fake objective parcel at the origin
		FakeObjectiveParcel = Spawn(class'XComParcel');
		ParcelManager.ObjectiveParcel = FakeObjectiveParcel;
	}

	simulated function GenerateMap()
	{
		local int ProcLevelSeed;
		local XComGameState_BattleData BattleData;
		local bool bSeamlessTraveled;		
		
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		bSeamlessTraveled = `XCOMGAME.m_bSeamlessTraveled;

		//Check whether the map has been generated already
		if(BattleData.MapData.ParcelData.Length > 0 && !bSeamlessTraveled)
		{
			// this data has a prebuilt map, load it
			LoadMap();
		}
		else if(BattleData.MapData.PlotMapName != "")
		{			
			// create a new procedural map 
			ProcLevelSeed = BattleData.iLevelSeed;

			//Unless we are using seamless travel, generate map requires there to be NO streaming maps when it starts
			if(!bSeamlessTraveled)
			{
				if(bShowDropshipInteriorWhileGeneratingMap)
				{	 
					ParcelManager.bBlockingLoadParcels = false;
				}
				else
				{
					`MAPS.RemoveAllStreamingMaps();
				}
				
				ParcelManager.GenerateMap(ProcLevelSeed);
			}
			else
			{
				//Make sure that we don't flush async loading, or else the transition map will hitch.
				ParcelManager.bBlockingLoadParcels = false; 

				//The first part of map generation has already happened inside the dropship. Now do the second part
				ParcelManager.GenerateMapUpdatePhase2();
			}
		}
		else // static, non-procedural map (such as the obstacle course)
		{
			`log("X2TacticalGameRuleset: RebuildWorldData");
			ParcelManager.InitPlacedEvacZone(); // in case we are testing placed evac zones in this map

			if(class'WorldInfo'.static.IsPlayInEditor())
			{
				SetupPIEGame();
			}
		}
	}

	function bool ShowDropshipInterior()
	{
		local XComGameState_BattleData BattleData;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_MissionSite MissionState;
		local bool bValidMapLaunchType;
		local bool bSkyrangerTravel;

		XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if(XComHQ != none)
		{
			MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
		}

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		//Not TQL, test map, PIE, etc.
		bValidMapLaunchType = `XENGINE.IsSinglePlayerGame() && BattleData.MapData.PlotMapName != "" && BattleData.MapData.ParcelData.Length == 0;

		//True if we didn't seamless travel here, and the mission type wanted a skyranger travel ( ie. no avenger defense or other special mission type )
		bSkyrangerTravel = !`XCOMGAME.m_bSeamlessTraveled && (MissionState == None || MissionState.GetMissionSource().bRequiresSkyrangerTravel);
				
		return bValidMapLaunchType && bSkyrangerTravel && !BattleData.DirectTransferInfo.IsDirectMissionTransfer;
	}

	simulated function CreateMapActorGameStates()
	{
		local XComDestructibleActor DestructibleActor;
		local X2WorldNarrativeActor NarrativeActor;
		local X2SquadVisiblePoint SquadVisiblePoint;

		local XComGameState StartState;
		local int StartStateIndex;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		foreach `BATTLE.AllActors(class'XComDestructibleActor', DestructibleActor)
		{
			DestructibleActor.GetState(StartState);
		}

		foreach `BATTLE.AllActors(class'X2WorldNarrativeActor', NarrativeActor)
		{
			NarrativeActor.CreateState(StartState);
		}

		foreach `BATTLE.AllActors(class'X2SquadVisiblePoint', SquadVisiblePoint)
		{
			SquadVisiblePoint.CreateState(StartState);
		}
	}

	simulated function BuildVisualizationForStartState()
	{
		local int StartStateIndex;		
		
		StartStateIndex = CachedHistory.FindStartStateIndex();
		//Make sure this is a tactical game start state
		`assert( StartStateIndex > -1 );
		`assert( XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(StartStateIndex).GetContext()) != none );
		
		//Bootstrap the visualization mgr. Enabling processing of new game states, and making sure it knows which state index we are at.
		VisualizationMgr.EnableBuildVisualization();
		VisualizationMgr.SetCurrentHistoryFrame(StartStateIndex);

		//This will set up the visualizers that init the camera, XGBattle, etc.
		VisualizationMgr.BuildVisualization(StartStateIndex); 
	}

	simulated function SetupFirstStartTurnSeed()
	{
		local XComGameState_BattleData BattleData;
		
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		if (BattleData.bUseFirstStartTurnSeed)
		{
			class'Engine'.static.GetEngine().SetRandomSeeds(BattleData.iFirstStartTurnSeed);
		}
	}

	simulated function SetupUnits()
	{
		local XComGameState StartState;
		local int StartStateIndex;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();
		
			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		// only spawn AIs in SinglePlayer...
		if (`XENGINE.IsSinglePlayerGame())
			StartStateSpawnAliens(StartState);

		// Spawn additional units ( such as cosmetic units like the Gremlin )
		StartStateSpawnCosmeticUnits(StartState);

		//Add new game object states to the start state.
		//*************************************************************************	
		StartStateCreateXpManager(StartState);
		StartStateInitializeUnitAbilities(StartState);      //Examine each unit's start state, and add ability state objects as needed
		StartStateInitializeSquads(StartState);
		//*************************************************************************

	}

	//Used by the system if we are coming from strategy and did not use seamless travel ( which handles this internally )
	function MarkPlotUsed()
	{
		local XComGameState_BattleData BattleDataState;

		BattleDataState = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		// notify the deck manager that we have used this plot
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('Plots', BattleDataState.MapData.PlotMapName);
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('PlotTypes', ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName).strType);
	}

	simulated function bool AllowVisualizerSelection()
	{
		return false;
	}

Begin:
	`SETLOC("Start of Begin Block");

	//Wait for the UI to initialize
	`assert(Pres != none); //Reaching this point without a valid presentation layer is an error
	
	// Added for testing with command argument for map name (i.e. X2_ObstacleCourse) otherwise mouse does not get initialized.
	//`ONLINEEVENTMGR.ReadProfileSettings();

	while( Pres.UIIsBusy() )
	{
		Sleep(0.0f);
	}
	
	//Show the soldiers riding to the mission while the map generates
	bShowDropshipInteriorWhileGeneratingMap = ShowDropshipInterior();
	if(bShowDropshipInteriorWhileGeneratingMap)
	{		
		`MAPS.AddStreamingMap(`MAPS.GetTransitionMap(), DropshipLocation, DropshipRotation, false);
		while(!`MAPS.IsStreamingComplete())
		{
			sleep(0.0f);
		}

		MarkPlotUsed();
				
		XComPlayerController(Pres.Owner).NotifyStartTacticalSeamlessLoad();

		WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

		//Let the dropship settle in
		Sleep(1.0f);

		//Stop any movies playing. HideLoadingScreen also re-enables rendering
		Pres.UIStopMovie();
		Pres.HideLoadingScreen();
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false);

		WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(FALSE);
	}
	else
	{
		//Will stop the HQ launch music if it is still playing ( which it should be, if we seamless traveled )
		`XTACTICALSOUNDMGR.StopHQMusicEvent();
	}

	//Generate the map and wait for it to complete
	GenerateMap();

	// Still rebuild the world data even if it is a static map except we need to wait for all the blueprints to resolve before
	// we build the world data.  In the case of a valid plot map, the parcel manager will build the world data at a step before returning
	// true from IsGeneratingMap
	if (XComGameState_BattleData( CachedHistory.GetGameStateForObjectID( CachedBattleDataRef.ObjectID ) ).MapData.PlotMapName == "")
	{
		while (!`MAPS.IsStreamingComplete( ))
		{
			sleep( 0.0f );
		}

		ParcelManager.RebuildWorldData( );
	}

	while( ParcelManager.IsGeneratingMap() )
	{
		Sleep(0.0f);
	}

	if( `XENGINE.IsSinglePlayerGame() )
	{
		AddDropshipStreamingCinematicMaps();
	}

	//Wait for the drop ship and all other maps to stream in
	while (!`MAPS.IsStreamingComplete())
	{
		sleep(0.0f);
	}

	if(bShowDropshipInteriorWhileGeneratingMap)
	{
		WorldInfo.bContinueToSeamlessTravelDestination = false;
		XComPlayerController(Pres.Owner).NotifyLoadedDestinationMap('');
		while(!WorldInfo.bContinueToSeamlessTravelDestination)
		{
			Sleep(0.0f);
		}

		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
		`XTACTICALSOUNDMGR.StopHQMusicEvent();

		`MAPS.ClearPreloadedLevels();
		`MAPS.RemoveStreamingMapByName(`MAPS.GetTransitionMap(), false);
	}

	if( XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl() != none )
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();
		
		bRain = CanToggleWetness();
		class'XComWeatherControl'.static.SetAllAsWet(bRain);
	}
	else
	{
		bRain = false;
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (WorldInfo.m_kDominantDirectionalLight != none &&
		WorldInfo.m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}
	
	InitVolumes();

	WorldInfo.MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	class'XComEngine'.static.ConsolidateVisGroupData();

	class'XComEngine'.static.TriggerTileDestruction();

	class'XComEngine'.static.AddEffectsToStartState();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

	`log("X2TacticalGameRuleset: Finished Generating Map", , 'XCom_GameStates');

	//Position units already in the start state
	//*************************************************************************
	StartStatePositionUnits();
	//*************************************************************************

	// "spawn"/prespawn player and ai units
	SetupUnits();

	// load cinematic maps for units
	AddCharacterStreamingCinematicMaps();

	//Wait for any loading movie to finish playing
	while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		Sleep(0.0f);
	}

	// Add the default camera
	AddDefaultPathingCamera();

	if (UnitRadiusManager != none)
	{
		UnitRadiusManager.SetEnabled( true );
	}

	//Visualize the start state - in the most basic case this will create pawns, etc. and position the camera.
	BuildVisualizationForStartState();
	
	//Let the visualization blocks accumulated so far run their course ( which may include intro movies, etc. ) before continuing. 
	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//Create game states for actors in the map - Moved to be after the WaitingForVisualizers Block, otherwise the advent tower blueprints were not loaded yet
	//*************************************************************************
	CreateMapActorGameStates();
	//*************************************************************************

	//This needs to be called after CreateMapActorGameStates, to make sure Destructibles have their state objects ready.
	`PRES.m_kUnitFlagManager.AddFlags();

	//Bootstrap the visibility mgr with the start state
	VisibilityMgr.InitialUpdate();

	// For things like Challenge Mode that require a level seed for all the level generation and a differing seed for each player that enters, set the 
	// specific seed for all random actions hereafter. Additionally, do this before the BeginState_rulesAuthority submits its state context so that the
	// seed is baked into the first context.
	SetupFirstStartTurnSeed();

	// remove the lock that was added in CreateTacticalGame.BeginState
	//	the history is fair game again...
	CachedHistory.RemoveHistoryLock();

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while entering a tactical battle! This WILL result in buggy behavior during game play continued with this save.");

	//After this point, the start state is committed
	BeginState_RulesAuthority(none);

	// if we've still got a movie playing, kill it and fade the screen. this should only really happen from the 'open' console command.
	if (class'XComEngine'.static.IsLoadingMoviePlaying( ))
	{
		Pres.HideLoadingScreen( );
		XComTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).ClientSetCameraFade( false, , , 1.0f );		
	}

	//This is guarded internally from redundantly starting. Various different ways of entering the mission may have called this earlier.
	`XTACTICALSOUNDMGR.StartAllAmbience();

	//Initialization continues in the PostCreateTacticalGame state.
	//Further changes are not part of the Tactical Game start state.

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This state is entered if the tactical game being played is resuming a previously saved game state. LoadTacticalGame handles resuming from a previous
/// game state as well initiating a replay of previous moves.
/// </summary>
simulated state LoadTacticalGame
{	
	simulated event BeginState(name PreviousStateName)
	{
		local X2EventManager EventManager;
		local Object ThisObject;

		EventManager = `XEVENTMGR;
		ThisObject = self;

		EventManager.RegisterForEvent(ThisObject, 'UnitMoveFinished', HandleNeutralReactionsOnMovement, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'AbilityActivated', HandleNeutralReactionsOnAbilityActivated, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'UnitDied', HandleUnitDiedCache, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'TileDataChanged', HandleAdditionalFalling, ELD_OnStateSubmitted);

		bTacticalGameInPlay = true;
		bProcessingLoad = true;
	}

	function BuildVisualizationForStartState()
	{
		local int StartStateIndex;		

		VisualizationMgr = `XCOMVISUALIZATIONMGR;

		StartStateIndex = CachedHistory.FindStartStateIndex();
		//Make sure this is a tactical game start state
		`assert( StartStateIndex > -1 );
		`assert( XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(StartStateIndex).GetContext()) != none );

		//This will set up the visualizers that init the camera, XGBattle, etc.
		VisualizationMgr.BuildVisualization(StartStateIndex); 
	}

	//Set up the visualization mgr to run from the correct frame
	function SyncVisualizationMgr()
	{
		local XComGameState FullGameState;
		local int StartStateIndex;

		if( `ONLINEEVENTMGR.bInitiateReplayAfterLoad )
		{
			//Start the replay from the most recent start state
			StartStateIndex = CachedHistory.FindStartStateIndex();
			FullGameState = CachedHistory.GetGameStateFromHistory(StartStateIndex, eReturnType_Copy, false);

			// init the UI before StartReplay() because if its the Tutorial, Start replay will hide the UI which needs to have been created already
			XComPlayerController(GetALocalPlayerController()).Pres.UIReplayScreen();

			XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.StartReplay(StartStateIndex);	

			`ONLINEEVENTMGR.bInitiateReplayAfterLoad = false;
		}
		else
		{
			//Continue the playthrough from the latest frame
			FullGameState = CachedHistory.GetGameStateFromHistory(-1, eReturnType_Copy, false);


		}

		VisualizationMgr.SetCurrentHistoryFrame(FullGameState.HistoryIndex);
		if( !XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay )
		{
			//If we are loading a saved game to play, sync all the visualizers to the current state and enable passive visualizer building
			VisualizationMgr.EnableBuildVisualization();		
			VisualizationMgr.OnJumpForwardInHistory();
			VisualizationMgr.BuildVisualization(FullGameState.HistoryIndex, true);
		}
	}

	simulated function SetupFirstStartTurnSeed()
	{
		local XComGameState_BattleData BattleData;

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		if (BattleData.bUseFirstStartTurnSeed)
		{
			class'Engine'.static.GetEngine().SetRandomSeeds(BattleData.iFirstStartTurnSeed);
		}
	}

	function SetupDeadUnitCache()
	{
		local XComGameState_Unit Unit;
		local XComGameState FullGameState;
		local int CurrentStateIndex;

		CachedDeadUnits.Length = 0;

		CurrentStateIndex = CachedHistory.GetCurrentHistoryIndex();
		FullGameState = CachedHistory.GetGameStateFromHistory(CurrentStateIndex, eReturnType_Copy, false);

		foreach FullGameState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			if( Unit.IsDead() )
			{
				CachedDeadUnits.AddItem(Unit.GetReference());
			}
		}
	}

	simulated function CreateMapActorGameStates()
	{
		local XComDestructibleActor DestructibleActor;

		local XComGameState StartState;
		local int StartStateIndex;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		// only make start states for destructible actors that have not been created by the load
		//	this can happen if parcels/doors change between when the save was created and when the save was loaded
		foreach `BATTLE.AllActors(class'XComDestructibleActor', DestructibleActor)
		{
			DestructibleActor.GetState(StartState);
		}
	}

	//Wait for ragdolls to finish moving
	function bool AnyUnitsRagdolling()
	{
		local XComUnitPawn UnitPawn;

		foreach AllActors(class'XComUnitPawn', UnitPawn)
		{
			if( UnitPawn.IsInState('RagdollBlend') )
			{
				return true;
			}
		}

		return false;
	}

	simulated function bool AllowVisualizerSelection()
	{
		return false;
	}

	function RefreshEventManagerUnitRegistration()
	{
		local XComGameState_Unit UnitState;

		foreach CachedHistory.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			UnitState.RefreshEventManagerRegistrationOnLoad();
		}
	}

Begin:
	`SETLOC("Start of Begin Block");

	LoadMap();

	AddCharacterStreamingCinematicMaps(true);

	while( ParcelManager.IsGeneratingMap() )
	{
		Sleep(0.0f);
	}

	if(XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl() != none)
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();

		bRain = CanToggleWetness();
		class'XComWeatherControl'.static.SetAllAsWet(bRain);
	}
	else
	{
		bRain = false;
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (WorldInfo.m_kDominantDirectionalLight != none &&
		WorldInfo.m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}

	InitVolumes();

	WorldInfo.MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	class'XComEngine'.static.ConsolidateVisGroupData();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

	RefreshEventManagerUnitRegistration();

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while loading a saved game! This WILL result in buggy behavior during game play continued with this save.");

	// Update visibility before updating the visualizers as this affects Tactical HUD ability caching
	VisibilityMgr.InitialUpdate();

	//If the load occurred from UnitActions, mark the ruleset as loading which will instigate the loading procedure for 
	//mid-UnitAction save (suppresses player turn events). This will be false for MP loads, and true for singleplayer saves.
	// raasland - except it wasn't being set to true for SP and breaking turn start tick effects
	bLoadingSavedGame = true;

	//Wait for the presentation layer to be ready
	while(Pres.UIIsBusy())
	{
		Sleep(0.0f);
	}
	
	// Add the default camera
	AddDefaultPathingCamera( );

	Sleep(0.1f);

	BuildVisualizationForStartState();

	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//Sync visualizers to the proper state ( variable depending on whether we are performing a replay or loading a save game to play )
	SyncVisualizationMgr();

	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//Wait for any units that are ragdolling to stop
	while(AnyUnitsRagdolling())
	{
		sleep(0.0f);
	}
		
	// remove all the replacement actors that have been replaced
	`SPAWNMGR.CleanupReplacementActorsOnLevelLoad();

	//Create game states for actors in the map - Moved to be after the WaitingForVisualizers Block, otherwise the advent tower blueprints were not loaded yet
	//	added here to account for actors which may have changed between when the save game was created and when it was loaded
	//*************************************************************************
	CreateMapActorGameStates();
	//*************************************************************************

	//This needs to be called after CreateMapActorGameStates, to make sure Destructibles have their state objects ready.
	Pres.m_kUnitFlagManager.AddFlags();

	//Flush cached visibility data now that the visualizers are correct for all the viewers and the cached visibility system uses visualizers as its inputs
	`XWORLD.FlushCachedVisibility();

	//Flush cached unit rules, because they can be affected by not having visualizers ready (pre-SyncVisualizationMgr)
	UnitsCache.Length = 0; 

	VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle(); //Force all visualizers to update their visualization state

	if (UnitRadiusManager != none)
	{
		UnitRadiusManager.SetEnabled( true );
	}

	CachedHistory.CheckNoPendingGameStates();

	SetupDeadUnitCache();
	
	//Signal that we are done
	bProcessingLoad = false; 

	//Destructible objects - those with states created in CreateMapActorGameStates - were not caught by the previous full visibility update.
	//Force another visibility update, just before we prod the HUD, to make sure that those are targetable immediately on load.
	//(By the looks of the existing comments, I don't think it's possible to order the code such that one update is sufficient.)
	//TTP 8268 / btopp 2015.10.15
	VisibilityMgr.InitialUpdate();

	Pres.m_kTacticalHUD.ForceUpdate(-1);

	if (`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		SetupFirstStartTurnSeed();
	}

	//Achievement event listeners do not survive the serialization process. Adding them here.
	`XACHIEVEMENT_TRACKER.Init();

	if(`REPLAY.bInTutorial)
	{
		// Force an update of the save game list, otherwise our tutorial replay save is shown in the load/save screen
		`ONLINEEVENTMGR.UpdateSaveGameList();

		//Allow the user to skip the movie now that the major work / setup is done
		`XENGINE.SetAllowMovieInput(true);

		while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
		{
			Sleep(0.0f);
		}
		
		TutorialIntro = XComNarrativeMoment(`CONTENT.RequestGameArchetype("X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_PostIntro"));
		Pres.UINarrative(TutorialIntro);		
	}

	//Movie handline - for both the tutorial and normal loading
	while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		Sleep(0.0f);
	}

	if(class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		//Set the screen to black - when the loading move is stopped the renderer and game will be initializing lots of structures so is not quite ready
		WorldInfo.GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
		Pres.HideLoadingScreen();		

		//Allow the game time to finish setting up following the loading screen being popped. Among other things, this lets ragdoll rigid bodies finish moving.
		Sleep(4.0f);
	}

	// once all loading and intro screens clear, we can start the actual tutorial
	if(`REPLAY.bInTutorial)
	{
		`TUTORIAL.StartDemoSequenceDeferred();
	}
	
	//Clear the camera fade if it is still set
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(false, , , 1.0f);	
	`XTACTICALSOUNDMGR.StartAllAmbience();

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This state is entered after CreateTacticalGame, to handle any manipulations that are not rolled into the start state.
/// It can be entered after LoadTacticalGame as well, if needed (i.e. if we're loading to a start state).
/// </summary>
simulated state PostCreateTacticalGame
{
	simulated function StartStateCheckAndBattleDataCleanup()
	{
		local XComGameState_BattleData BattleData;
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		if ((BattleData == none) ||
			(BattleData != none &&
			BattleData.bIntendedForReloadLevel == false))
			`assert( CachedHistory.GetStartState() == none );

			if (BattleData != none)
			{
				BattleData.bIntendedForReloadLevel = false;
			}
	}

	simulated event EndState(Name NextStateName)
	{
		VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle(); //Force all visualizers to update their visualization state
	}

	simulated function bool AllowVisualizerSelection()
	{
		return false;
	}

Begin:
	`SETLOC("Start of Begin Block");

	//Posts a game state updating all state objects that they are in play
	BeginTacticalPlay();

	//Let kismet know everything is ready
	`XCOMGRI.DoRemoteEvent('XGBattle_Running_BeginBlockFinished');

	CachedHistory.CheckNoPendingGameStates();

	// give the player a few seconds to get adjusted to the level
	sleep(0.5);

	// kick off the mission intro kismet, and wait for it to complete all latent actions
	WorldInfo.TriggerGlobalEventClass(class'SeqEvent_OnTacticalMissionStartBlocking', WorldInfo);

	while (WaitingForVisualizer())
	{
		sleep(0.0);
	}

	// set up start of match special conditions, including squad concealment
	ApplyStartOfMatchConditions();

	// kick off the gameplay start kismet, do not wait for it to complete latent actions
	WorldInfo.TriggerGlobalEventClass(class'SeqEvent_OnTacticalMissionStartNonBlocking', WorldInfo);

	StartStateCheckAndBattleDataCleanup();

	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This state is entered when creating a challenge mission. Setup handles creating scenario
/// specific game states, processing any scenario kismet logic, etc.
/// </summary>
simulated state CreateChallengeGame
{
	simulated event BeginState(name PreviousStateName)
	{
		local X2EventManager EventManager;
		local Object ThisObject;

		// the start state has been added by this point
		//	nothing in this state should be adding anything that is not added to the start state itself
		CachedHistory.AddHistoryLock();

		EventManager = `XEVENTMGR;
			ThisObject = self;

		EventManager.RegisterForEvent(ThisObject, 'UnitMoveFinished', HandleNeutralReactionsOnMovement, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'AbilityActivated', HandleNeutralReactionsOnAbilityActivated, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'UnitDied', HandleUnitDiedCache, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'TileDataChanged', HandleAdditionalFalling, ELD_OnStateSubmitted);

		SetUnitsForMatinee();
	}

	simulated event EndState(Name NextStateName)
	{
		VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle(); //Force all visualizers to update their visualization state
	}

	simulated function SetUnitsForMatinee()
	{
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_Unit Unit;
		local XComGameState StartState;

		StartState = CachedHistory.GetStartState();
		XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(StartState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.Squad.Length = 0;
		foreach StartState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			if (Unit.GetTeam() == eTeam_XCom)
			{
				XComHQ.Squad.AddItem(Unit.GetReference());
			}
		}
	}

	simulated function BuildVisualizationForStartState()
	{
		local int StartStateIndex;

		StartStateIndex = CachedHistory.FindStartStateIndex();
		//Make sure this is a tactical game start state
		`assert( StartStateIndex > -1 );
		`assert( XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(StartStateIndex).GetContext()) != none );

		//Bootstrap the visualization mgr. Enabling processing of new game states, and making sure it knows which state index we are at.
		VisualizationMgr.EnableBuildVisualization();
		VisualizationMgr.SetCurrentHistoryFrame(StartStateIndex);

		//This will set up the visualizers that init the camera, XGBattle, etc.
		VisualizationMgr.BuildVisualization(StartStateIndex);
	}

	simulated function SetupFirstStartTurnSeed()
	{
		local XComGameState_BattleData BattleData;

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		if (BattleData.bUseFirstStartTurnSeed)
		{
			class'Engine'.static.GetEngine().SetRandomSeeds(BattleData.iFirstStartTurnSeed);
		}
	}

Begin:
	`SETLOC("Start of Begin Block");

	//Wait for the UI to initialize
	`assert(Pres != none); //Reaching this point without a valid presentation layer is an error

	while (Pres.UIIsBusy())
	{
		Sleep(0.0f);
	}

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		LoadMap();
	}

	// Still rebuild the world data even if it is a static map except we need to wait for all the blueprints to resolve before
	// we build the world data.  In the case of a valid plot map, the parcel manager will build the world data at a step before returning
	// true from IsGeneratingMap
	if (XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID)).MapData.PlotMapName == "")
	{
		while (!`MAPS.IsStreamingComplete())
		{
			sleep(0.0f);
		}

		ParcelManager.RebuildWorldData();
	}

	while (ParcelManager.IsGeneratingMap())
	{
		Sleep(0.0f);
	}

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		AddDropshipStreamingCinematicMaps();
	}

	//Wait for the drop ship and all other maps to stream in
	while (!`MAPS.IsStreamingComplete())
	{
		sleep(0.0f);
	}

	if(XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl() != none)
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();

		bRain = CanToggleWetness();
		class'XComWeatherControl'.static.SetAllAsWet(bRain);
	}
	else
	{
		bRain = false;
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (WorldInfo.m_kDominantDirectionalLight != none &&
		WorldInfo.m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}

	WorldInfo.MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	class'XComEngine'.static.ConsolidateVisGroupData();

	class'XComEngine'.static.TriggerTileDestruction();

	class'XComEngine'.static.AddEffectsToStartState();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

	`log("X2TacticalGameRuleset: Finished Generating Map", , 'XCom_GameStates');

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		// load cinematic maps for units
		AddCharacterStreamingCinematicMaps();
	}

	// Add the default camera
	AddDefaultPathingCamera();

	if (UnitRadiusManager != none)
	{
		UnitRadiusManager.SetEnabled(true);
	}

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		//Visualize the start state - in the most basic case this will create pawns, etc. and position the camera.
		BuildVisualizationForStartState();

		//Let the visualization blocks accumulated so far run their course ( which may include intro movies, etc. ) before continuing. 
		while (WaitingForVisualizer())
		{
			sleep(0.0);
		}

		`PRES.m_kUnitFlagManager.AddFlags();
	}

	//Bootstrap the visibility mgr with the start state
	VisibilityMgr.InitialUpdate();

	// For things like Challenge Mode that require a level seed for all the level generation and a differing seed for each player that enters, set the 
	// specific seed for all random actions hereafter. Additionally, do this before the BeginState_rulesAuthority submits its state context so that the
	// seed is baked into the first context.
	SetupFirstStartTurnSeed();

	// remove the lock that was added in CreateTacticalGame.BeginState
	//	the history is fair game again...
	CachedHistory.RemoveHistoryLock();

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while entering a tactical battle! This WILL result in buggy behavior during game play continued with this save.");

	//After this point, the start state is committed
	BeginState_RulesAuthority(none);

	//Posts a game state updating all state objects that they are in play
	BeginTacticalPlay();

	//Let kismet know everything is ready
	`XCOMGRI.DoRemoteEvent('XGBattle_Running_BeginBlockFinished');

	CachedHistory.CheckNoPendingGameStates();

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		// give the player a few seconds to get adjusted to the level
		sleep(0.5);
	}

	// set up start of match special conditions, including squad concealment
	ApplyStartOfMatchConditions();

	if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
	{
		// an extra couple seconds before we potentially kick off narrative intro VO
		sleep(1.25);
	}

	// kick off the mission intro kismet, and wait for it to complete all latent actions
	WorldInfo.TriggerGlobalEventClass(class'SeqEvent_OnTacticalMissionStartBlocking', WorldInfo);

	while (WaitingForVisualizer())
	{
		sleep(0.0);
	}

	// kick off the gameplay start kismet, do not wait for it to complete latent actions
	WorldInfo.TriggerGlobalEventClass(class'SeqEvent_OnTacticalMissionStartNonBlocking', WorldInfo);

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This turn phase is entered at the end of the CreateChallengeGame state and waits for the user to confirm the start of the challenge mission.
/// </summary>
simulated state TurnPhase_StartTimer
{
	simulated event BeginState(name PreviousStateName)
	{
		local Object ThisObj;

		`PRES.UIChallengeStartTimerMessage();

		ThisObj = self;
		`XEVENTMGR.RegisterForEvent( ThisObj, 'MissionObjectiveMarkedFailed', OnChallengeObjectiveFailed, ELD_OnStateSubmitted );
	}

	simulated event EndState(Name NextStateName)
	{
		local XComGameState_TimerData Timer;

		Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
		if (Timer != none && !`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
		{
			//Reset the timer game state object to the desired time limit and begin the countdown.
			Timer.ResetTimer();
		}
		`XANALYTICS.Init();

		`ONLINEEVENTMGR.bIsChallengeModeGame = true;
	}

Begin:
	while (`PRES.WaitForChallengeAccept())
	{
		sleep(0.0);
	}
	GotoState(GetNextTurnPhase(GetStateName()));
}

function EventListenerReturn OnChallengeObjectiveFailed( Object EventData, Object EventSource, XComGameState GameState, Name EventID )
{
	local XComGameState_Player PlayerState;
	local XComGameState_TimerData TimerState;
	local XGPlayer Player;

	PlayerState = XComGameState_Player( CachedHistory.GetGameStateForObjectID( GetLocalClientPlayerObjectID() ) );
	Player = XGPlayer( PlayerState.GetVisualizer( ) );

	EndBattle( Player );

	TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_TimerData' ) );
	TimerState.bStopTime = true;

	return ELR_InterruptEventAndListeners;
}

/// <summary>
/// This turn phase is entered at the start of each turn and handles any start-of-turn scenario events. Unit/Terrain specific effects occur in subsequent phases.
/// </summary>
simulated state TurnPhase_Begin
{
	simulated event BeginState(name PreviousStateName)
	{
		BeginState_RulesAuthority(UpdateAbilityCooldowns);
	}

	simulated function UpdateAbilityCooldowns(XComGameState NewPhaseState)
	{
		local XComGameState_Ability AbilityState, NewAbilityState;
		local XComGameState_Player  PlayerState, NewPlayerState;
		local XComGameState_Unit UnitState, NewUnitState;
		local bool TickCooldown;

		if (!bLoadingSavedGame)
		{
			foreach CachedHistory.IterateByClassType(class'XComGameState_Ability', AbilityState)
			{
				// some units tick their cooldowns per action instead of per turn, skip them.
				UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
				`assert(UnitState != none);
				TickCooldown = AbilityState.iCooldown > 0 && !UnitState.GetMyTemplate().bManualCooldownTick;

				if( TickCooldown || AbilityState.TurnsUntilAbilityExpires > 0 )
				{
					NewAbilityState = XComGameState_Ability(NewPhaseState.CreateStateObject(class'XComGameState_Ability', AbilityState.ObjectID));//Create a new state object on NewPhaseState for AbilityState
					NewPhaseState.AddStateObject(NewAbilityState);

					if( TickCooldown )
					{
						NewAbilityState.iCooldown--;
					}

					if( NewAbilityState.TurnsUntilAbilityExpires > 0 )
					{
						NewAbilityState.TurnsUntilAbilityExpires--;
						if( NewAbilityState.TurnsUntilAbilityExpires == 0 )
						{
							NewUnitState = XComGameState_Unit(NewPhaseState.CreateStateObject(class'XComGameState_Unit', NewAbilityState.OwnerStateObject.ObjectID));
							NewPhaseState.AddStateObject(NewUnitState);
							NewUnitState.Abilities.RemoveItem(NewAbilityState.GetReference());
						}
					}
				}
			}

			foreach CachedHistory.IterateByClassType(class'XComGameState_Player', PlayerState)
			{
				if (PlayerState.HasCooldownAbilities() || PlayerState.SquadCohesion > 0)
				{
					NewPlayerState = XComGameState_Player(NewPhaseState.CreateStateObject(class'XComGameState_Player', PlayerState.ObjectID));
					NewPlayerState.UpdateCooldownAbilities();
					if (PlayerState.SquadCohesion > 0)
						NewPlayerState.TurnsSinceCohesion++;
					NewPhaseState.AddStateObject(NewPlayerState);
				}
			}
		}
	}

Begin:
	`SETLOC("Start of Begin Block");

	CachedHistory.CheckNoPendingGameStates();

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

function UpdateAIActivity(bool bActive)
{
	bAlienActivity = bActive;
}

simulated function bool UnitActionPlayerIsRemote()
{
	local XComGameState_Player PlayerState;
	local XGPlayer Player;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
	if( PlayerState != none )
	{
		Player = XGPlayer(PlayerState.GetVisualizer());
	}

	`assert(PlayerState != none);
	`assert(Player != none);

	return (PlayerState != none) && (Player != none) && Player.IsRemote();
}

function bool RulesetShouldAutosave()
{
	local XComGameState_Player PlayerState;
	local XComGameState_ChallengeData ChallengeData;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
	ChallengeData = XComGameState_ChallengeData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true));

	return !bSkipAutosaveAfterLoad && !HasTacticalGameEnded() &&!PlayerState.IsAIPlayer() && !`REPLAY.bInReplay && `TUTORIAL == none && ChallengeData == none;
}

/// <summary>
/// This turn phase forms the bulk of the X-Com 2 turn and represents the phase of the battle where players are allowed to 
/// select what actions they will perform with their units
/// </summary>
simulated state TurnPhase_UnitActions
{
	simulated event BeginState(name PreviousStateName)
	{
		local XComGameState_BattleData BattleData;	
		local bool bHasNextPlayer;

		if( !bLoadingSavedGame )
		{
			BeginState_RulesAuthority(SetupUnitActionsState);
		}

		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		`assert(BattleData.PlayerTurnOrder.Length > 0);

		InitializePlayerTurnOrder();

		if( bLoadingSavedGame )
		{
			//Skip to the current player			
			do
			{
				bHasNextPlayer = NextPlayer();
			}
			until( ActionsAvailable() || !bHasNextPlayer );
			class'Engine'.static.GetEngine().ReinitializeValueOnLoadComplete();
		}
		else
		{
			BeginUnitActions();
		}
		
		//Clear the loading flag - it is only relevant during the 'next player' determination
		bSkipAutosaveAfterLoad = bLoadingSavedGame;
		bLoadingSavedGame = false;
		bSkipRemainingTurnActivty = false;
	}

	simulated function InitializePlayerTurnOrder()
	{
		UnitActionPlayerIndex = -1;
	}

	simulated function SetupUnitActionsState(XComGameState NewPhaseState)
	{
		//  This code has been moved to the player turn observer, as units need to reset their actions
		//  only when their player turn changes, not when the over all game turn changes over.
		//  Leaving this function hook for future implementation needs. -jbouscher
	}

	simulated function SetupUnitActionsForPlayerTurnBegin(XComGameState NewGameState)
	{
		local XComGameState_Unit UnitState;
		local XComGameState_Unit NewUnitState;
		local XComGameState_Player NewPlayerState;

		// clear the streak counters on this player
		NewPlayerState = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player', CachedUnitActionPlayerRef.ObjectID));
		NewPlayerState.MissStreak = 0;
		NewPlayerState.HitStreak = 0;
		NewGameState.AddStateObject(NewPlayerState);

		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			// Only process units that belong to the player whose turn it now is
			if (UnitState.ControllingPlayer.ObjectID != CachedUnitActionPlayerRef.ObjectID)
			{
				continue;
			}

			// Create a new state object on NewPhaseState for UnitState
			NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewUnitState.SetupActionsForBeginTurn();
			// Add the updated unit state object to the new game state
			NewGameState.AddStateObject(NewUnitState);
		}	
	}

	simulated function BeginUnitActions()
	{
		NextPlayer();
	}

	simulated function bool NextPlayer()
	{
		EndPlayerTurn();

		if(HasTacticalGameEnded())
		{
			// if the tactical game has already completed, then we need to bail before
			// initializing the next player, as we do not want any more actions to be taken.
			return false;
		}

		++UnitActionPlayerIndex;
		return BeginPlayerTurn();
	}

	simulated function bool BeginPlayerTurn()
	{
		local XComGameStateContext_TacticalGameRule Context;
		local XComGameState_BattleData BattleData;
		local XComGameState_Player PlayerState;
		local X2EventManager EventManager;
		local XComGameState NewGameState;
		local XGPlayer PlayerStateVisualizer;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;

		EventManager = `XEVENTMGR;
		BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		`assert(BattleData.PlayerTurnOrder.Length > 0);

		if( UnitActionPlayerIndex < BattleData.PlayerTurnOrder.Length )
		{
			CachedUnitActionPlayerRef = BattleData.PlayerTurnOrder[UnitActionPlayerIndex];

			//Don't process turn begin/end events if we are loading from a save
			if( !bLoadingSavedGame )
			{
				// before the start of each player's turn, submit a game state resetting that player's units' per-turn values (like action points remaining)
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SetupUnitActionsForPlayerTurnBegin");
				SetupUnitActionsForPlayerTurnBegin(NewGameState);
				SubmitGameState(NewGameState);

				// Moved this down here since SetupUnitActionsForPlayerTurnBegin needs to reset action points before 
				// OnUnitActionPhaseBegun_NextPlayer calls GatherUnitsToMove.
				PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
				//Notify the player state's visualizer that they are now the unit action player
				`assert(PlayerState != none);
				PlayerStateVisualizer = XGPlayer(PlayerState.GetVisualizer());
				PlayerStateVisualizer.OnUnitActionPhaseBegun_NextPlayer();  // This initializes the AI turn 

				// Trigger the PlayerTurnBegun event
				EventManager.TriggerEvent( 'PlayerTurnBegun', PlayerState, PlayerState );

				// build a gamestate to mark this beginning of this players turn
				Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnBegin);
				Context.PlayerRef = CachedUnitActionPlayerRef;				
				
				SubmitGameStateContext(Context);
			}

			ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) );
			if ((ChallengeData != none) && !UnitActionPlayerIsAI( ))
			{
				TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_TimerData' ) );
				TimerState.bStopTime = false;
			}

			//Uncomment if there are persistent lines you want to refresh each turn
			//WorldInfo.FlushPersistentDebugLines();

			`XTACTICALSOUNDMGR.EvaluateTacticalMusicState();
			return true;
		}
		return false;
	}

	simulated function EndPlayerTurn()
	{
		local XComGameStateContext_TacticalGameRule Context;
		local XComGameState_Player PlayerState;
		local X2EventManager EventManager;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;

		EventManager = `XEVENTMGR;
		if( UnitActionPlayerIndex > -1 )
		{
			//Notify the player state's visualizer that they are no longer the unit action player
			PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
			`assert(PlayerState != none);
			XGPlayer(PlayerState.GetVisualizer()).OnUnitActionPhaseFinished_NextPlayer();

			//Don't process turn begin/end events if we are loading from a save
			if( !bLoadingSavedGame )
			{
				EventManager.TriggerEvent( 'PlayerTurnEnded', PlayerState, PlayerState );

				// build a gamestate to mark this end of this players turn
				Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnEnd);
				Context.PlayerRef = CachedUnitActionPlayerRef;				
				SubmitGameStateContext(Context);
			}


			ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) );
			if ((ChallengeData != none) && !UnitActionPlayerIsAI( ))
			{
				TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_TimerData' ) );
				TimerState.bStopTime = true;
			}
		}
	}

	simulated function bool UnitHasActionsAvailable(XComGameState_Unit UnitState)
	{
		local GameRulesCache_Unit UnitCache;
		local AvailableAction Action;

		if (UnitState == none)
			return false;

		//Check whether this unit is controlled by the UnitActionPlayer
		if (UnitState.ControllingPlayer.ObjectID == CachedUnitActionPlayerRef.ObjectID ||
			UnitState.ObjectID == PriorityUnitRef.ObjectID)
		{
			if (!UnitState.GetMyTemplate().bIsCosmetic &&
				!UnitState.IsPanicked() &&
				(UnitState.AffectedByEffectNames.Find(class'X2Ability_Viper'.default.BindSustainedEffectName) == INDEX_NONE))
			{
				GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache);
				foreach UnitCache.AvailableActions(Action)
				{
					if (Action.bInputTriggered && Action.AvailableCode == 'AA_Success')
					{
						return true;
					}
				}
			}
		}

		return false;
	}

	simulated function bool ActionsAvailable()
	{
		local XGPlayer ActivePlayer;
		local XComGameState_Unit UnitState;
		local XComGameState_Player PlayerState;
		local bool bActionsAvailable;

		// Turn was skipped, no more actions
		if (bSkipRemainingTurnActivty)
		{
			return false;
		}

		bActionsAvailable = false;

		ActivePlayer = XGPlayer(CachedHistory.GetVisualizer(CachedUnitActionPlayerRef.ObjectID));

		if (ActivePlayer.m_kPlayerController != none)
		{
			// Check current unit first, to ensure we aren't switching away from a unit that has actions (XComTacticalController::OnVisualizationIdle also switches units)
			UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(ActivePlayer.m_kPlayerController.ControllingUnit.ObjectID));
			bActionsAvailable = UnitHasActionsAvailable(UnitState);
		}

		if (!bActionsAvailable)
		{
			foreach CachedHistory.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				bActionsAvailable = UnitHasActionsAvailable(UnitState);

				if (bActionsAvailable)
				{
					break; // once we find an action, no need to keep iterating
				}
			}
		}

		if( bActionsAvailable )
		{
			bWaitingForNewStates = true;	//If there are actions available, indicate that we are waiting for a decision on which one to take

			if( !UnitActionPlayerIsRemote() )
			{				
				PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
				`assert(PlayerState != none);
				XGPlayer(PlayerState.GetVisualizer()).OnUnitActionPhase_ActionsAvailable(UnitState);
			}
		}

		return bActionsAvailable;
	}

	simulated function EndPhase()
	{
		if (HasTacticalGameEnded())
		{
			GotoState( 'EndTacticalGame' );
		}
		else
		{
			GotoState( GetNextTurnPhase( GetStateName() ) );
		}
	}

	function FailsafeCheckForTacticalGameEnded()
	{
		local int Index;
		local KismetGameRulesetEventObserver KismetObserver;

		if (!HasTacticalGameEnded())
		{
			//Do a last check at the end of the unit action phase to see if any players have lost all their playable units
			for (Index = 0; Index < EventObservers.Length; ++Index)
			{
				KismetObserver = KismetGameRulesetEventObserver(EventObservers[Index]);
				if (KismetObserver != none)
				{
					KismetObserver.CheckForTeamHavingNoPlayableUnitsExternal();
					break;
				}
			}
		}		
	}

	simulated function string GetStateDebugString()
	{
		local string DebugString;
		local XComGameState_Player PlayerState;
		local int UnitCacheIndex;
		local int ActionIndex;
		local XComGameState_Unit UnitState;				
		local XComGameState_Ability AbilityState;
		local AvailableAction AvailableActionData;
		local string EnumString;

		PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));

		DebugString = "Unit Action Player  :"@((PlayerState != none) ? string(PlayerState.GetVisualizer()) : "PlayerState_None")@" ("@CachedUnitActionPlayerRef.ObjectID@") ("@ (UnitActionPlayerIsRemote() ? "REMOTE" : "") @")\n";
		DebugString = DebugString$"Begin Block Location: " @ BeginBlockWaitingLocation @ "\n\n";
		DebugString = DebugString$"Internal State:"@ (bWaitingForNewStates ? "Waiting For Player Decision" : "Waiting for Visualizer") @ "\n\n";
		DebugString = DebugString$"Unit Cache Info For Unit Action Player:\n";

		for( UnitCacheIndex = 0; UnitCacheIndex < UnitsCache.Length; ++UnitCacheIndex )
		{
			UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(UnitsCache[UnitCacheIndex].UnitObjectRef.ObjectID));

			//Check whether this unit is controlled by the UnitActionPlayer
			if( UnitState.ControllingPlayer.ObjectID == CachedUnitActionPlayerRef.ObjectID ) 
			{			
				DebugString = DebugString$"Unit: "@((UnitState != none) ? string(UnitState.GetVisualizer()) : "UnitState_None")@"("@UnitState.ObjectID@") [HI:"@UnitsCache[UnitCacheIndex].LastUpdateHistoryIndex$"] ActionPoints:"@UnitState.NumAllActionPoints()@" (Reserve:" @ UnitState.NumAllReserveActionPoints() $") - ";
				for( ActionIndex = 0; ActionIndex < UnitsCache[UnitCacheIndex].AvailableActions.Length; ++ActionIndex )
				{
					AvailableActionData = UnitsCache[UnitCacheIndex].AvailableActions[ActionIndex];

					AbilityState = XComGameState_Ability(CachedHistory.GetGameStateForObjectID(AvailableActionData.AbilityObjectRef.ObjectID));
					EnumString = string(AvailableActionData.AvailableCode);
					
					DebugString = DebugString$"("@AbilityState.GetMyTemplateName()@"-"@EnumString@") ";
				}
				DebugString = DebugString$"\n";
			}
		}

		return DebugString;
	}

	event Tick(float DeltaTime)
	{		
		local XComGameState_Player PlayerState;
		local XGAIPlayer AIPlayer;
		local int fTimeOut;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;
		local XGPlayer Player;

		//rmcfall - if the AI player takes longer than 25 seconds to make a decision a blocking error has occurred in its logic. Skip its turn to avoid a hang.
		//This logic is redundant to turn skipping logic in the behaviors, and is intended as a last resort
		if( UnitActionPlayerIsAI() && bWaitingForNewStates && !(`CHEATMGR != None && `CHEATMGR.bAllowSelectAll) )
		{
			PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
			AIPlayer = XGAIPlayer(PlayerState.GetVisualizer());

			if (AIPlayer.m_eTeam == eTeam_Neutral)
			{
				fTimeOut = 5.0f;
			}
			else
			{
				fTimeOut = 25.0f;
			}
			WaitingForNewStatesTime += DeltaTime;
			if (WaitingForNewStatesTime > fTimeOut && !`REPLAY.bInReplay)
			{
				`LogAIActions("Exceeded WaitingForNewStates TimeLimit"@WaitingForNewStatesTime$"s!  Calling AIPlayer.EndTurn()");
				AIPlayer.OnTimedOut();
				class'XGAIPlayer'.static.DumpAILog();
				AIPlayer.EndTurn(ePlayerEndTurnType_AI);
			}
		}

		ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) );
		if ((ChallengeData != none) && !UnitActionPlayerIsAI() && !WaitingForVisualizer())
		{
			TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData') );
			if (TimerState.GetCurrentTime() <= 0)
			{
				PlayerState = XComGameState_Player( CachedHistory.GetGameStateForObjectID( CachedUnitActionPlayerRef.ObjectID ) );
				Player = XGPlayer(PlayerState.GetVisualizer());

				EndBattle( Player );
			}
		}
	}

	function StateObjectReference GetCachedUnitActionPlayerRef()
	{
		return CachedUnitActionPlayerRef;
	}

	function CheckForAutosave()
	{
		if(bSkipAutosaveAfterLoad)
		{
			bSkipAutosaveAfterLoad = false; // clear the flag so that the next autosave goes through
		}
		else if (RulesetShouldAutosave())
		{
			`AUTOSAVEMGR.DoAutosave(); 
		}
	}

Begin:
	`SETLOC("Start of Begin Block");
	CachedHistory.CheckNoPendingGameStates();

	//Loop through the players, allowing each to perform actions with their units
	do
	{	
		sleep(0.0); // Wait a tick for the game states to be updated before switching the sending
		
		//Before switching players, wait for the current player's last action to be fully visualized
		while( WaitingForVisualizer() )
		{
			`SETLOC("Waiting for Visualizer: 1");
			sleep(0.0);
		}

		// autosave after the visualizer finishes doing it's thing and control is being handed over to the player. 
		// This guarantees that any pre-turn behavior tree or other ticked decisions have completed modifying the history.
		CheckForAutosave();

		`SETLOC("Check for Available Actions");
		while( ActionsAvailable() && !HasTacticalGameEnded() )
		{
			WaitingForNewStatesTime = 0.0f;

			//Wait for new states created by the player / AI / remote player. Manipulated by the SubmitGameStateXXX methods
			while( bWaitingForNewStates && !HasTimeExpired())
			{
				`SETLOC("Available Actions");
				sleep(0.0);
			}
			`SETLOC("Available Actions: Done waiting for New States");

			CachedHistory.CheckNoPendingGameStates();

			if( `CHEATMGR.bShouldAutosaveBeforeEveryAction )
			{
				`AUTOSAVEMGR.DoAutosave();
			}
			sleep(0.0);
		}

		`SETLOC("Checking for Tactical Game Ended");
		//Perform fail safe checking for whether the tactical battle is over
		FailsafeCheckForTacticalGameEnded();

		while( WaitingForVisualizer() )
		{
			`SETLOC("Waiting for Visualizer: 2");
			sleep(0.0);
		}

		// Moved to clear the SkipRemainingTurnActivty flag until after the visualizer finishes.  Prevents an exploit where
		// the end/back button is spammed during the player's final action. Previously the Skip flag was set to true 
		// while visualizing the action, after the flag was already cleared, causing the subsequent AI turn to get skipped.
		bSkipRemainingTurnActivty = false;
		`SETLOC("Going to the Next Player");
	}
	until( !NextPlayer() ); //NextPlayer returns false when the UnitActionPlayerIndex has reached the end of PlayerTurnOrder in the BattleData state.
	
	//Wait for the visualizer to perform the visualization steps for all states before we permit the rules engine to proceed to the next phase
	while( WaitingForVisualizer() )
	{
		`SETLOC("Waiting for Visualizer: 3");
		sleep(0.0);
	}

	// Failsafe. Make sure there are no active camera anims "stuck" on
	GetALocalPlayerController().PlayerCamera.StopAllCameraAnims(TRUE);

	`SETLOC("Updating AI Activity");
	UpdateAIActivity(false);

	CachedHistory.CheckNoPendingGameStates();

	`SETLOC("Ending the Phase");
	EndPhase();
	`SETLOC("End of Begin Block");
}

/// <summary>
/// This turn phase is entered at the end of each turn and handles any end-of-turn scenario events.
/// </summary>
simulated state TurnPhase_End
{
	simulated event BeginState(name PreviousStateName)
	{
		BeginState_RulesAuthority(none);
	}

Begin:
	`SETLOC("Start of Begin Block");

	////Wait for all players to reach this point in their rules engine
	//while( WaitingForPlayerSync() )
	//{
	//	sleep(0.0);
	//}

	CachedHistory.CheckNoPendingGameStates();

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

/// <summary>
/// This phase is entered following the successful load of a replay. Turn logic is not intended to be applied to replays by default, but may be activated and
/// used to perform unit tests / validation of correct operation within this state.
/// </summary>
simulated state PerformingReplay
{
	simulated event BeginState(name PreviousStateName)
	{
		bTacticalGameInPlay = true;
	}

	function EndReplay()
	{
		GotoState(GetNextTurnPhase(GetStateName()));
	}

Begin:
	`SETLOC("End of Begin Block");
}

function ExecuteNextSessionCommand()
{
	//Tell the content manager to build its list of required content based on the game state that we just built and added.
	`CONTENT.RequestContent();
	ConsoleCommand(NextSessionCommandString);
}

/// <summary>
/// This state is entered when a tactical game ended state is pushed onto the history
/// </summary>
simulated state EndTacticalGame
{
	simulated event BeginState(name PreviousStateName)
	{
		local XGPlayer ActivePlayer;
		local XComGameState_ChallengeData ChallengeData;

		ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) );

		// make sure that no controllers are active
		if(CachedUnitActionPlayerRef.ObjectID > 0) 
		{
			ActivePlayer = XGPlayer(CachedHistory.GetVisualizer(CachedUnitActionPlayerRef.ObjectID));
			ActivePlayer.m_kPlayerController.Visualizer_ReleaseControl();
		}

		//Show the UI summary screen before we clean up the tactical game
		if(!bPromptForRestart && !`REPLAY.bInTutorial && !IsFinalMission())
		{
			if (ChallengeData == none)
			{
				`PRES.UIMissionSummaryScreen( );
			}
			else
			{
				`PRES.UIChallengeModeSummaryScreen( );
			}

			`XTACTICALSOUNDMGR.StartEndBattleMusic();
		}

		//The tutorial is just a replay that the player clicks through by performing the actions in the replay. 
		if(!`REPLAY.bInTutorial && (ChallengeData == none))
		{			
			CleanupTacticalMission();
			EndTacticalPlay();
		}
		else
		{
			bTacticalGameInPlay = false;
		}

		//Disable visibility updates
		`XWORLD.bDisableVisibilityUpdates = true;
	}

	simulated function SubmitChallengeMode()
	{
		local XComGameState_ChallengeData ChallengeData;
		local X2ChallengeModeInterface ChallengeModeInterface;

		ChallengeModeInterface = `CHALLENGEMODE_INTERFACE;
		ChallengeData = XComGameState_ChallengeData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true));

		if (ChallengeData != none && ChallengeModeInterface != none)
		{
			ChallengeModeInterface.PerformChallengeModePostGameSave();
			ChallengeModeInterface.PerformChallengeModePostEventMapData();
		}
	}

	simulated function bool IsFinalMission()
	{
		local XComGameState_MissionSite MissionState;
		local XComGameState_HeadquartersXCom XComHQ;

		XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

		if(MissionState.GetMissionSource().DataName == 'MissionSource_Final')
		{
			return true;
		}

		return false;
	}

	simulated function NextSessionCommand()
	{	
		local XComGameState_BattleData BattleData;
		local XComGameState_CampaignSettings NewCampaignSettingsStateObject;
		local XComGameState StrategyStartState;
		local XComGameState_MissionSite MissionState;
		local XComGameState_HeadquartersXCom XComHQ;	
		local XComNarrativeMoment TutorialReturn;
		local XGUnit Unit;
		local XComPawn DisablePawn;
		local bool bLoadingMovieOnReturn;

		// at the end of the session, the event listener needs to be cleared of all events and listeners; reset it
		`XEVENTMGR.ResetToDefaults(false);

		//Determine whether we were playing a one-off tactical battle or if we are in a campaign.
		BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if (BattleData.m_strDesc ~= "Challenge Mode")
		{
			ConsoleCommand("disconnect"); // TODO: Goto the Challenge Mode Screen ...
		}
		else if(BattleData.bIsTacticalQuickLaunch && !`REPLAY.bInTutorial) //Due to the way the tutorial was made, the battle data in it may record that it is a TQL match
		{
			ConsoleCommand("disconnect");
		}
		else
		{	
			XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
						
			//Figure out whether we need to go to a loading screen or not
			NextSessionCommandString = class'XComGameStateContext_StrategyGameRule'.default.StrategyMapCommand;
			bLoadingMovieOnReturn = !MissionState.GetMissionSource().bRequiresSkyrangerTravel || !class'XComMapManager'.default.bUseSeamlessTravelToStrategy || MissionState.GetMissionSource().CustomLoadingMovieName_Outro != "";

			//If we are in the tutorial, create a strategy game start
			if(`REPLAY.bInTutorial)
			{
				//Special case for units since they have attached pawns.
				foreach WorldInfo.AllActors(class'XGUnit', Unit)
				{
					Unit.Uninit();
				}

				//Covers pathing pawns, cosmetic pawns, etc.
				foreach WorldInfo.AllActors(class'XComPawn', DisablePawn)
				{
					DisablePawn.SetTickIsDisabled(true);
				}

				// Complete tutorial achievement
				`ONLINEEVENTMGR.UnlockAchievement( AT_CompleteTutorial );
				`FXSLIVE.AnalyticsGameTutorialCompleted( );

				//Destroy all the visualizers being used by the history, and then reset the history
				CachedHistory.DestroyVisualizers();
				CachedHistory.ResetHistory();

				StrategyStartState = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(, , true, `ONLINEEVENTMGR.CampaignDifficultySetting, true);

				//Copy the original campaign settings into the new
				NewCampaignSettingsStateObject = XComGameState_CampaignSettings(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
				class'XComGameState_CampaignSettings'.static.CopySettingsFromOnlineEventMgr(NewCampaignSettingsStateObject);
				NewCampaignSettingsStateObject.SetStartTime(StrategyStartState.TimeStamp);
				
				bLoadingMovieOnReturn = true; //Play commander awakens as a loading movie
				`XENGINE.PlaySpecificLoadingMovie("CIN_TP_CommanderAwakens.bk2", "X2_010_CommanderAwakens");

				TutorialReturn = XComNarrativeMoment(`CONTENT.RequestGameArchetype("X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_SkyrangerReturn"));
				`PRES.UINarrative(TutorialReturn);
			}
			else
			{
				class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStartFromTactical();
			}

			//Change the session command based on whether we want to use a loading screen or seamless travel
			if(bLoadingMovieOnReturn)
			{				
				if(MissionState.GetMissionSource().CustomLoadingMovieName_Outro != "")
				{
					`XENGINE.PlaySpecificLoadingMovie(MissionState.GetMissionSource().CustomLoadingMovieName_Outro, MissionState.GetMissionSource().CustomLoadingMovieName_OutroSound);
				}
				else if(MissionState.GetMissionSource().bRequiresSkyrangerTravel)
				{
					`XENGINE.PlaySpecificLoadingMovie("Black.bik");
				}				

				ReplaceText(NextSessionCommandString, "servertravel", "open");
			}

			
			if(bLoadingMovieOnReturn)
			{				
				`XENGINE.PlayLoadMapMovie(-1);
				SetTimer(0.5f, false, nameof(ExecuteNextSessionCommand));
			}
			else
			{
				ExecuteNextSessionCommand();
			}
		}
	}

	simulated function PromptForRestart()
	{
		`PRES.UICombatLoseScreen(LoseType);
	}

Begin:
	`SETLOC("Start of Begin Block");

	SubmitChallengeMode();
	
	if (bPromptForRestart)
	{
		PromptForRestart();
	}
	else
	{
		//This variable is cleared by the mission summary screen accept button
		bWaitingForMissionSummary = !`REPLAY.bInTutorial && !IsFinalMission();
		while (bWaitingForMissionSummary)
		{
			Sleep(0.0f);
		}

		//Turn the visualization mgr off while the map shuts down / seamless travel starts
		VisibilityMgr.UnRegisterForNewGameStateEvent();
		VisualizationMgr.DisableForShutdown();

		//Schedule a 1/2 second fade to black, and wait a moment. Only if the camera is not already faded
		if(!WorldInfo.GetALocalPlayerController().PlayerCamera.bEnableFading)
		{
			`PRES.HUDHide();
			WorldInfo.GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.75);			
			Sleep(1.0f);
		}

		//Trigger the launch of the next session
		NextSessionCommand();
	}
	`SETLOC("End of Begin Block");
}

simulated function name GetLastStateNameFromHistory(name DefaultName='')
{
	local int HistoryIndex;
	local XComGameStateContext_TacticalGameRule Rule;
	local name StateName;

	StateName = DefaultName;
	for( HistoryIndex = CachedHistory.GetCurrentHistoryIndex(); HistoryIndex > 0; --HistoryIndex )
	{
		Rule = XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(HistoryIndex).GetContext());
		if( Rule != none && Rule.GameRuleType == eGameRule_RulesEngineStateChange)
		{
			StateName = Rule.RuleEngineNextState;
			break;
		}
	}
	return StateName;
}

simulated function bool LoadedGameNeedsPostCreate()
{
	local XComGameState_BattleData BattleData;
	BattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

	if (BattleData == None)
		return false;

	if (BattleData.bInPlay)
		return false;

	if (!BattleData.bIntendedForReloadLevel)
		return false;

	return true;
}

simulated function name GetNextTurnPhase(name CurrentState, optional name DefaultPhaseName='TurnPhase_End')
{
	local name LastState;
	switch (CurrentState)
	{
	case 'CreateTacticalGame':
		return 'PostCreateTacticalGame';
	case 'LoadTacticalGame':
		if( XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay )
		{
			return 'PerformingReplay';
		}
		if (LoadedGameNeedsPostCreate())
		{
			return 'PostCreateTacticalGame';
		}
		LastState = GetLastStateNameFromHistory();
		return (LastState == '' || LastState == 'LoadTacticalGame') ? 'TurnPhase_UnitActions' : GetNextTurnPhase(LastState, 'TurnPhase_UnitActions');
	case 'PostCreateTacticalGame':
		if (CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) != none)
			return 'TurnPhase_StartTimer';

		return 'TurnPhase_Begin';
	case 'TurnPhase_Begin':		
		return 'TurnPhase_UnitActions';
	case 'TurnPhase_UnitActions':
		return 'TurnPhase_End';
	case 'TurnPhase_End':
		return 'TurnPhase_Begin';
	case 'PerformingReplay':
		if (!XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay || XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInTutorial)
		{
			//Used when resuming from a replay, or in the tutorial and control has "returned" to the player
			return 'TurnPhase_Begin';
		}
	case 'CreateChallengeGame':
		return 'TurnPhase_StartTimer';
	case 'TurnPhase_StartTimer':
		return 'TurnPhase_Begin';
	}
	`assert(false);
	return DefaultPhaseName;
}

function StateObjectReference GetCachedUnitActionPlayerRef()
{
	local StateObjectReference EmptyRef;
	// This should generally not be called outside of the TurnPhase_UnitActions
	// state, except when applying an effect that has bIgnorePlayerCheckOnTick
	// set
	return EmptyRef;
}

final function bool TacticalGameIsInPlay()
{
	return bTacticalGameInPlay;
}

function bool IsWaitingForNewStates()
{
	return bWaitingForNewStates;
}

DefaultProperties
{	
	EventObserverClasses[0] = class'X2TacticalGameRuleset_MovementObserver'	
	EventObserverClasses[1] = class'X2TacticalGameRuleset_AttackObserver'
	EventObserverClasses[2] = class'KismetGameRulesetEventObserver'
	
	ContextBuildDepth = 0
}
