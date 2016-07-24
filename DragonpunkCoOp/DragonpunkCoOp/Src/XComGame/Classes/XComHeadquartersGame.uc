//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComHeadquartersGame extends XComGameInfo;

var PlayerController        CursorController;
var PlayerController 	    PlayerController;
var protected XGStrategy    m_kGameCore;
var string                  m_strSaveFile;
var deprecated XGCharacterGenerator    CharacterGenerator;

var bool                    m_bLoadDemoFromShell;
var bool                    m_bDebugStrategyFromShell;
var bool                    m_bControlledStartFromShell;
var bool                    m_bEnableIronmanFromShell; 

var XComEarth			    m_kEarth;

function XGStrategy GetGameCore()
{
	return m_kGameCore;
}

function XComEarth GetEarth()
{
	return m_kEarth;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//								HEADQUARTERS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

state Headquarters
{
	event BeginState( name p )
	{
	}

	event EndState( name n )
	{
	}
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//								INIT
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function StartMatch()
{
	local bool bStandardLoad;
	local XComOnlineEventMgr OnlineEventMgr;

	super.StartMatch();

	InitEarth();

	// Ensure that the player has the correct rich presence
	PlayerController.ClientSetOnlineStatus();

	OnlineEventMgr = `ONLINEEVENTMGR;
	bStandardLoad = OnlineEventMgr.bPerformingStandardLoad;

	if (bStandardLoad) 
	{

		//We came from a load menu
		OnlineEventMgr.FinishLoadGame();			
		
		m_kGameCore = spawn( class'XGStrategy', self );
		m_kGameCore.OnLoadedGame();
	}	
	else 
	{
		if( `XCOMHISTORY.GetNumGameStates() < 1 )
		{
			class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart();
		}

		//We came from starting a new game
		m_kGameCore = spawn( class'XGStrategy', self );
		m_kGameCore.Init();
	}

	ModStartMatch();
}

simulated function class<X2GameRuleset> GetGameRulesetClass()
{
	return class'X2StrategyGameRuleset';
}

function InitEarth()
{
	m_kEarth = Spawn(class'XComEarth');
	m_kEarth.InitTiles();
}

event GameEnding()
{
	super.GameEnding();
	Uninit();
}

function Uninit()
{
	if(m_kGameCore != none)
	{
		m_kGameCore.Uninit();
		m_kGameCore.Destroy();
		m_kGameCore = none;
	}
}

auto State PendingMatch
{
Begin:
	while (!`MAPS.IsStreamingComplete())
	{   
		Sleep(0.1f);
	}

	while (`HQPC == None || `HQPRES == None || !`HQPRES.Get2DMovie().bIsInited)
	{
		Sleep(0.1f);
	}

	StartMatch();
End:
}

event InitGame( string Options, out string ErrorMessage )
{
	local string InOpt; 

	super.InitGame(Options, ErrorMessage);
	m_strSaveFile = ParseOption(Options, "SaveFile");

	InOpt = ParseOption(Options, "DebugStrategyFromShell");
	if (InOpt != "")
	{
		m_bDebugStrategyFromShell = true;
		`log("+++++ DEBUG STRATEGY activated from shell +++++");
	}
	
	InOpt = ParseOption(Options, "ControlledStartFromShell");
	if (InOpt != "")
	{
		m_bControlledStartFromShell = true;
		`log("+++++ CONTROLLED START activated from shell +++++");
	}	
}

event PlayerController Login
(
	string Portal,
	string Options,
	const UniqueNetID UniqueID,
	out string ErrorMessage
)
{
	local NavigationPoint StartSpot;
	local string          InName, InCharacter/*, InAdminName*/, InPassword;
	local byte            InTeam;
	local bool bSpectator, bAdmin, bPerfTesting;
	local rotator SpawnRotation;
	bAdmin = false;

	`log( "XComHeadquarters::Login" );

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

	if( StartSpot == none )
	{
		ErrorMessage = GameMessageClass.Default.FailedPlaceMessage;
		return None;
	}

	SpawnRotation.Yaw = StartSpot.Rotation.Yaw;
	PlayerController = spawn(PlayerControllerClass,,,StartSpot.Location,SpawnRotation);

	// Handle spawn failure.
	if( PlayerController == none )
	{
		`log("Couldn't spawn player controller of class "$PlayerControllerClass);
		ErrorMessage = GameMessageClass.Default.FailedSpawnMessage;
		return None;
	}

	PlayerController.StartSpot = StartSpot;

	// Set the player's ID.
	PlayerController.PlayerReplicationInfo.PlayerID = CurrentID++;

	// Init player's name
	if( InName=="" )
	{
		InName=DefaultPlayerName$PlayerController.PlayerReplicationInfo.PlayerID;
	}

	ChangeName( PlayerController, InName, false );

	InCharacter = ParseOption(Options, "Character");
	PlayerController.SetCharacter(InCharacter);

	if ( bSpectator || PlayerController.PlayerReplicationInfo.bOnlySpectator || !ChangeTeam(PlayerController, InTeam, false) )
	{
		PlayerController.GotoState('Spectating');
		PlayerController.PlayerReplicationInfo.bOnlySpectator = true;
		PlayerController.PlayerReplicationInfo.bIsSpectator = true;
		PlayerController.PlayerReplicationInfo.bOutOfLives = true;
		return PlayerController;
	}

	// perform auto-login if admin password/name was passed on the url
	if ( AccessControl != None && AccessControl.AdminLogin(PlayerController, InPassword) )
	{
		AccessControl.AdminEntered(PlayerController);
	}

	// if delayed start, don't give a pawn to the player yet
	// Normal for multiplayer games
	if ( bDelayedStart )
	{
		PlayerController.GotoState('PlayerWaiting');
		return PlayerController;
	}

	return PlayerController;
}

function string GetSavedGameDescription()
{
	local string GeoTimeDesc;
	local int GeoHour, GeoMinute;
	local TDateTime GeoTime;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	GeoTime = `STRATEGYRULES.GameTime;
	class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(XComHQ.Get2DLocation(), GeoTime);

	GeoHour = class'X2StrategyGameRulesetDataStructures'.static.GetHour(GeoTime);
	GeoMinute = class'X2StrategyGameRulesetDataStructures'.static.GetMinute(GeoTime);
	`ONLINEEVENTMGR.FormatTimeStamp(GeoTimeDesc, GeoTime.m_iYear, GeoTime.m_iMonth, GeoTime.m_iDay, GeoHour, GeoMinute);

	if( GetLanguage() == "INT" )
	{
		GeoTimeDesc = `ONLINEEVENTMGR.FormatTimeStampFor12HourClock(GeoTimeDesc);
	}

	return class'XGLocalizedData'.default.Geoscape $ "\n" $ GeoTimeDesc;
}

function string GetSavedGameCommand()
{
	return "open Avenger_Root?game=XComGame.XComHeadQuartersGame";
}

function string GetSavedGameMapName()
{
	return "StrategyMap";
}

// This will be called when going from Strategy -> Tactical, once when heading to the
// transition map, and once again when heading to the destination map
event GetSeamlessTravelActorList(bool bToTransitionMap, out array<Actor> ActorList)
{
	super.GetSeamlessTravelActorList(bToTransitionMap, ActorList);
}

// This will be called when going from Tactical -> Strategy, after the strategy
// map is loaded and ready to go
event PostSeamlessTravel()
{
	`log("XComGameInfo.PostSeamlessTravel",,'DevStreaming');
	super.PostSeamlessTravel();
}

// Called on player controllers that are transitioned from Tactical -> Strategy,
// this is called instead of Login()
event HandleSeamlessTravelPlayer(out Controller C)
{
	// Handle all the transitional logic
	super.HandleSeamlessTravelPlayer(C);

	PlayerController = XComHeadquartersController(C);
}

defaultproperties
{
	PlayerControllerClass=class'XComGame.XComHeadquartersController'
	//HUDType=class'XComGame.XComHQHUD';

	// Changing this to XComHeadquartersPawn causes forced first-person mode?!
	// Note also that XComHeadquartersGlobe is not even a Pawn, but third-person is allowed
	DefaultPawnClass=class'XComGame.XComHeadquartersPawn'

	bRestartLevel=false
	bUseSeamlessTravel=true

	PawnAnimSetNames(0)="CHH_SoldierBaseMale_ANIMSET.Anims.AS_MasterBaseMale"

	PawnAnimTreeName="CH_BaseChar_ANIMTREE.AT_BaseChar"

	InterceptorMeshName="VEH_Interceptor_ANIM.Meshes.SM_Interceptor"
	InterceptorAnimSetName="Interceptors.Anims.AS_Interceptor"
	FirestormMeshName="VEH_Firestorm_ANIM.Meshes.SM_Firestorm"
	FirestormAnimSetName="Interceptors.Anims.AS_Firestorm"
}
