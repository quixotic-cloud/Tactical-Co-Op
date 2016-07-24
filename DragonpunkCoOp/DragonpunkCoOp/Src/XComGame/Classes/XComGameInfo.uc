//=============================================================================
// The GameInfo defines the game being played: the game rules, scoring, what actors
// are allowed to exist in this game type, and who may enter the game.  While the
// GameInfo class is the public interface, much of this functionality is delegated
// to several classes to allow easy modification of specific game components.  These
// classes include GameInfo, AccessControl, Mutator, BroadcastHandler, and GameRules.
// A GameInfo actor is instantiated when the level is initialized for gameplay (in
// C++ UGameEngine::LoadMap() ).  The class of this GameInfo actor is determined by
// (in order) either the URL, or the
// DefaultGame entry in the game's .ini file (in the Engine.Engine section), unless
// its a network game in which case the DefaultServerGame entry is used.
// The GameType used can be overridden in the GameInfo script event SetGameType(), called
// on the game class picked by the above process.
//
// Copyright 1998-2008 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class XComGameInfo extends GameInfo
	native
	abstract;

var protectedwrite X2GameRuleset GameRuleset;
var deprecated XGCharacterGenerator m_CharacterGen;
var X2SimpleBodyPartFilter SharedBodyPartFilter;

var class TacticalSaveGameClass;
var class StrategySaveGameClass;
var class TransportSaveGameClass;

var config array<string> ModNames;
var array<XComMod> Mods;

// These are needed in XComTacticalGame and XComHeadquartersGame
var array<string> PawnAnimSetNames;
var array<AnimSet> PawnAnimSets;

var privatewrite    bool    m_bSeamlessTraveled;


// These are needed in XComHeadquartersGame only, but because they are
// needed by XComGame classes, we need them to be defined here. -- jboswell
var(HQ) string PawnAnimTreeName;
var(HQ) AnimTree PawnAnimTree;

var(HQ) string InterceptorMeshName;
var(HQ) string FirestormMeshName;
var(HQ) string InterceptorAnimSetName;
var(HQ) string FirestormAnimSetName;
var(HQ) array<string> JetWeaponMeshNames;
var(HQ) array<string> PerkContentNames;

var(HQ) SkeletalMesh InterceptorMesh;
var(HQ) SkeletalMesh FirestormMesh;
var(HQ) AnimSet InterceptorAnimSet;
var(HQ) AnimSet FirestormAnimSet;
var(HQ) array<StaticMesh> JetWeaponMeshes;
var(HQ) array<XComPerkContent> PerkContents;

var(HQ) array<string> DressMedalNames;
var(HQ) array<SkeletalMesh> DressMedalMeshes;

var(HQ) string MECAnimSetHQName;
var(HQ) AnimSet MECAnimSetHQ;
var(HQ) string MECAnimTreeHQName;
var(HQ) AnimTree MECAnimTreeHQ;
var(HQ) string MECCivvieAnimTreeHQName;
var(HQ) AnimTree MECCivvieAnimTreeHQ;
var(HQ) string EmptyMECViewerAnimTreeHQName;
var(HQ) AnimTree EmptyMECViewerAnimTreeHQ;
var(HQ) string MECPreviewMaterialName;
var(HQ) Material MECPreviewMaterialHQ;

var(HQ) string XRayFemaleMeshName;
var(HQ) SkeletalMesh XRayFemaleMesh;
var(HQ) string XRayMaleMeshName;
var(HQ) SkeletalMesh XRayMaleMesh;

//Used to identify which objects should be marked as removed at the end of a tactical battle
var privatewrite config array<name> TransientTacticalClassNames; 

var privatewrite config bool bArchiveHistory; //Flag to indicate whether old history data should be kept in archive form

event InitGame( string Options, out string ErrorMessage )
{
	super.InitGame(Options, ErrorMessage);

	m_bSeamlessTraveled = WorldInfo.IsInSeamlessTravel();

	SharedBodyPartFilter = new class'X2SimpleBodyPartFilter';

//   ParseAutomatedTestingOptions(Options);
}

event GameEnding()
{
	if (`XWORLD != none)
	{
		`XWORLD.Cleanup();
	}

	super.GameEnding();
}

// --------------------------------------------------------------------
// --------------------------------------------------------------------
function RestartPlayer( Controller NewPlayer )
{
    super.RestartPlayer( NewPlayer );
    // the pawn will new get hidden/shown on turn end/begin
    // this takes care of the XComDemoSpectator's pawn
	if (NewPlayer.Pawn != none)
		NewPlayer.Pawn.SetHidden( true );
}

// content loading callbacks -- jboswell
function native bool GetSupportedGameTypes(const out string InFilename, out GameTypePrefix OutGameType, optional bool bCheckExt = false) const;
function native bool GetMapCommonPackageName(const out string InFilename, out string OutCommonPackageName) const;
function native OnPostSeamlessTravel(); //Lets us do native things after seamless travel has completed
event string GetDifficultyFriendlyName(int DifficultyIndex);

static function native string GetGameVersion();


/**
 * Returns the default pawn class for the specified controller,
 *
 * @param	C - controller to figure out pawn class for
 *
 * @return	default pawn class
 */
function class<Pawn> GetDefaultPlayerClass(Controller C)
{
	// if we would load an xcom3dcursor, check to see if we want one of the
	// special subclasses of it - dburchanowski
	if(super.GetDefaultPlayerClass(C) == class'XComGame.XCom3DCursor')
	{
		`log(self $ "::" $ GetFuncName() @ `ShowVar(C.IsLocalPlayerController()) @ `ShowVar(XComPlayerController(C).IsMouseActive()), true, 'XCom_Net');
		// check to see if the player is using the mouse
		if(XComPlayerController(C).IsMouseActive())
		{
			return class'XComGame.XCom3DCursorMouse';
		}
	}

	return super.GetDefaultPlayerClass(C);
}


// jboswell: This will change the GameInfo class based on the map we are about to load
static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
	local class<GameInfo>   GameInfoClass;
	local string            GameInfoClassName;

	local string            GameInfoClassToUse;

	GameInfoClassName = class'GameInfo'.static.ParseOption(Options, "Game");

	// 1) test MP game type before the map name tests just in case an MP map name contains one of the search strings -tsmith 
	if (InStr(GameInfoClassName, "XComMPTacticalGame", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComMPTacticalGame";
	}
	else if (InStr(GameInfoClassName, "X2MPLobbyGame", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.X2MPLobbyGame";
	}
	else if(InStr(GameInfoClassName, "MPShell", , true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComMPShell";
	}

	// 2) pick a gametype based on the filename of the map
	else if (InStr(MapName, "Shell", , true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComShell";
	}
	else if (InStr(MapName, "Avenger_Root", , true) != INDEX_NONE || InStr(GameInfoClassName, "XComHeadquartersGame", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComHeadquartersGame";
	}
	else if (InStr(GameInfoClassName, "XComTacticalGameValidation", true, true) != INDEX_NONE)
	{
		GameInfoClassToUse = "XComGame.XComTacticalGameValidation";
	}
	else
	{
		GameInfoClassToUse = "XComGame.XComTacticalGame"; // likely it's a tactical map.
	}

	if (GameInfoClass == none)
	{
		GameInfoClass = class<GameInfo>(DynamicLoadObject(GameInfoClassToUse, class'Class'));
	}

	if (GameInfoClass != none)
	{
		return GameInfoClass;
	}
	else
	{
		`log("SetGameType: ERROR! failed loading requested gameinfo '" @ GameInfoClassToUse @ "', using default gameinfo.");
		return default.Class;
	}
}

//
// Log a player in.
// Fails login if you set the Error string.
// PreLogin is called before Login, but significant game time may pass before
// Login is called, especially if content is downloaded.
//
event PlayerController Login
(
	string Portal,
	string Options,
	const UniqueNetID UniqueID, 
	out string ErrorMessage
)
{
	local NavigationPoint StartSpot;
	local PlayerController NewPlayer;
	local string          InName, InCharacter/*, InAdminName*/, InPassword;
	local byte            InTeam;
	local bool bSpectator, bAdmin, bPerfTesting;
	local rotator SpawnRotation;
	local vector SpawnLocation;
	bAdmin = false;

	// Kick the player if they joined during the handshake process
	if (bUsingArbitration && bHasArbitratedHandshakeBegun)
	{
		ErrorMessage = GameMessageClass.Default.MaxedOutMessage;
		return None;
	}

	if ( BaseMutator != None )
		BaseMutator.ModifyLogin(Portal, Options);

	bPerfTesting = ( ParseOption( Options, "AutomatedPerfTesting" ) ~= "1" );
	bSpectator = bPerfTesting || ( ParseOption( Options, "SpectatorOnly" ) ~= "1" );

	// Get URL options.
	//InName     = Left(ParseOption ( Options, "Name"), 20);
	// since we have moved the name option to the end of the list in UWorld::SpawnPlayActor, grab everything following ?Name=
	InName = Split(Options, "?Name=", true);
	InTeam     = GetIntOption( Options, "Team", 255 ); // default to "no team"
	//InAdminName= ParseOption ( Options, "AdminName");
	InPassword = ParseOption ( Options, "Password" );
	//InChecksum = ParseOption ( Options, "Checksum" );

	if ( AccessControl != None )
	{
		bAdmin = AccessControl.ParseAdminOptions(Options);
	}

	// Make sure there is capacity except for admins. (This might have changed since the PreLogin call).
	if ( !bAdmin && AtCapacity(bSpectator) )
	{
		ErrorMessage = GameMessageClass.Default.MaxedOutMessage;
		return None;
	}

	// If admin, force spectate mode if the server already full of reg. players
	if ( bAdmin && AtCapacity(false) )
	{
		bSpectator = true;
	}

	// Pick a team (if need teams)
	InTeam = PickTeam(InTeam,None);

	// Find a start spot.
	StartSpot = FindPlayerStart( None, InTeam, Portal );

	if( StartSpot == None )
	{		
		NewPlayer = SpawnPlayerController(SpawnLocation, SpawnRotation);
	}
	else
	{
		SpawnRotation.Yaw = StartSpot.Rotation.Yaw;
		NewPlayer = SpawnPlayerController(StartSpot.Location, SpawnRotation);
	}

	// Handle spawn failure.
	if( NewPlayer == None )
	{
		`log("Couldn't spawn player controller of class "$PlayerControllerClass);
		ErrorMessage = GameMessageClass.Default.FailedSpawnMessage;
		return None;
	}

	NewPlayer.StartSpot = StartSpot;

	// Set the player's ID.
	NewPlayer.PlayerReplicationInfo.PlayerID = CurrentID++;

	// Init player's name
	if( InName=="" )
	{
		InName=DefaultPlayerName$NewPlayer.PlayerReplicationInfo.PlayerID;
	}

	ChangeName( NewPlayer, InName, false );

	InCharacter = ParseOption(Options, "Character");
	NewPlayer.SetCharacter(InCharacter);

	if ( bSpectator || NewPlayer.PlayerReplicationInfo.bOnlySpectator || !ChangeTeam(newPlayer, InTeam, false) )
	{
		NewPlayer.GotoState('Spectating');
		NewPlayer.PlayerReplicationInfo.bOnlySpectator = true;
		NewPlayer.PlayerReplicationInfo.bIsSpectator = true;
		NewPlayer.PlayerReplicationInfo.bOutOfLives = true;
		return NewPlayer;
	}

	// perform auto-login if admin password/name was passed on the url
	if ( AccessControl != None && AccessControl.AdminLogin(NewPlayer, InPassword) )
	{
		AccessControl.AdminEntered(NewPlayer);
	}


	// if delayed start, don't give a pawn to the player yet
	// Normal for multiplayer games
	if ( bDelayedStart )
	{
		NewPlayer.GotoState('PlayerWaiting');
		return NewPlayer;
	}

	return newPlayer;
}

//
// Called after a successful login. This is the first place
// it is safe to call replicated functions on the PlayerController.
//
// this is also the first place where its safe to test for being a local player controller on the server
event PostLogin( PlayerController NewPlayer )
{
	super.PostLogin(NewPlayer);

	XComPlayerController(NewPlayer).PostLogin();
}

function Input_ConfirmAction()
{
}

function Input_CycleAction()
{
}

`if(`notdefined(FINAL_RELEASE))
function bool AllowCheats(PlayerController P)
{
	return true;
}
`endif

function string GetSavedGameDescription();
function string GetSavedGameCommand();
function string GetSavedGameMapName();

event GetSeamlessTravelActorList(bool bToTransitionMap, out array<Actor> ActorList)
{
	`log("XComGameInfo: Starting seamless travel to" @ (bToTransitionMap ? "transition map" : "destination map"),,'DevStreaming');
	super.GetSeamlessTravelActorList(bToTransitionMap, ActorList);
}

event PostSeamlessTravel()
{
	`log("XComGameInfo.PostSeamlessTravel",,'DevStreaming');
	super.PostSeamlessTravel();

	OnPostSeamlessTravel();

	`MAPS.ClearPreloadedLevels();
}

simulated function XGTacticalGameCore TACTICAL()
{
	return `GAMECORE;
}

// override in each gameInfo for Project
// specific implementation of each GetItemCard
simulated function TItemCard GetItemCard()
{
	local TItemCard kItemCard;
	return kItemCard;
}

simulated function ModStartMatch()
{
	local XComMod Mod;

	foreach Mods(Mod)
	{
		Mod.StartMatch();
	}
}

/**
 * Tells the online system to end the game and tells all clients to do the same
 */
function EndOnlineGame()
{
	if (GameInterface != None)
	{
		GameInterface.AddEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
	}
	super.EndOnlineGame();
}

simulated function OnEndOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful));
	SetTimer(1.5f, false, nameof(DelayedEndOnlineGameComplete)); // Let the replication go through for ClientEndOnlineGame ... -ttalley
}

simulated function DelayedEndOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful));
	GameInterface.ClearEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
	GameInterface.AddDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	GameInterface.DestroyOnlineGame(PlayerReplicationInfoClass.default.SessionName);
}

simulated function OnDestroyedOnlineGame(name SessionName,bool bWasSuccessful)
{
	local PlayerController PC;

	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful));
	GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);

	foreach WorldInfo.AllControllers(class'PlayerController',PC)
	{
		if ( PC.IsLocalPlayerController() )
		{
			XComTacticalController(PC).FinishGameOver();
		}
	}
}

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	SubscribeToOnCleanupWorld();
	CreateGameRuleset();
}

/**
* Called when the world is being cleaned up. Allows the actor to free any dynamic content it has created.
*/
simulated event OnCleanupWorld()
{
	if (GameInterface != None)
	{
		GameInterface.ClearEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
		GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	}

	super.OnCleanupWorld();
}

simulated event Destroyed()
{
	if (GameInterface != None)
	{
		GameInterface.ClearEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
		GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	}
	super.Destroyed();
}

simulated event CreateGameRulesetNative()
{
	GameRuleset = Spawn(class'X2TacticalGameRuleset', self);
	GameRuleset.BuildLocalStateObjectCache();
}

simulated function CreateGameRuleset()
{
	local class<X2GameRuleset> Ruleset;

	Ruleset = GetGameRulesetClass();
	if (Ruleset != none)
		GameRuleset = Spawn(Ruleset, self);
}

simulated function StartNewGame()
{	
	if (GameRuleset != none)
		GameRuleset.StartNewGame();	
}

simulated function LoadGame()
{	
	if (GameRuleset != none)
		GameRuleset.LoadGame();	
}

simulated function class<X2GameRuleset> GetGameRulesetClass();

// Here you define the properties and classes your game type will use
// Such as the HUD, scoreboard, player controller, replication (networking) controller
defaultproperties
{
	GameReplicationInfoClass=class'XComGame.XComGameReplicationInfo'
	PlayerReplicationInfoClass=class'XComGame.XComPlayerReplicationInfo'
	PlayerControllerClass=class'XComGame.XComTacticalController'
	DefaultPawnClass=class'XComGame.XCom3DCursor'
	// TODO: @SinglePlayer: you will need to specify your own online game settings class, the base xcom one is abstract -tsmith 
	//OnlineGameSettingsClass=class'XComGame.XComOnlineGameSettings'
	bRestartLevel=false
	HUDType=class'XComGame.XComHUD'
}
