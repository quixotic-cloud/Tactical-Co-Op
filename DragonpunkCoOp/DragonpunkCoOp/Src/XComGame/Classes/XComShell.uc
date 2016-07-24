
class XComShell extends XComGameInfo;

const EXECUTE_COMMAND_TIMEOUT = 0.5;

var UIShell         m_kShell;
var UIMovie			m_kUIMgr;
var string          m_sCommand;
var string          m_sMapName;
var float           m_commandExecuteTimeout;
var XComShellController m_kController;
var bool			bFlaggedReview; 
var string			MainMenuMusicAkEventPath;
var AkEvent			PlayMainMenuMusic;
var int				SoundID;

event InitGame( string Options, out string ErrorMessage )
{
	Super.InitGame(Options, ErrorMessage);
	bFlaggedReview = int(WorldInfo.Game.ParseOption(Options, "Review")) > 0;
	if( bFlaggedReview )
		`log("XComShell if flagging Review:" @ bFlaggedReview );
}

//
// Called after a successful login. This is the first place
// it is safe to call replicated functions on the PlayerController.
//
// this is also the first place where its safe to test for being a local player controller on the server
event PostLogin( PlayerController NewPlayer )
{
	super.PostLogin(NewPlayer);

	m_kController = XComShellController(NewPlayer);
	m_kController.m_kShell = self;
	XComShellPresentationLayer(m_kController.Pres).m_kXComShell = self;
	GotoState('Running');
	Disable('Tick');
	m_kUIMgr = m_kController.Pres.Get2DMovie();		
	`CONTENT.RequestObjectAsync(MainMenuMusicAkEventPath, self, OnPlayMainMenuAkEventLoaded);
}

function OnPlayMainMenuAkEventLoaded(object LoadedObject)
{
	PlayMainMenuMusic = AkEvent(LoadedObject);
	assert(PlayMainMenuMusic != none);
	StartMenuMusic();
}

function StopMenuMusic()
{
	StopAkSound(SoundID);
}

function StartMenuMusic()
{
	SoundID = PlayAkSound(string(PlayMainMenuMusic.Name));
}

simulated function ShutdownAndExecute( string command ) {}

state Running
{
	simulated function Tick(float dt)
	{
	}

	simulated function ShutdownAndExecute( string command )
	{
		m_sCommand = command;
		m_commandExecuteTimeout = 0;
		GotoState('ShuttingDown');
	}

Begin:

	// If the game is paused, this sleep will not finish until it is unpaused. This prevents the shell from rendering
	//   before any system menu (see XBOX Guide) is closed. If the scene is shown before it is allowed to tick, many things
	//   will not render properly. JMS
	Sleep(0.001f);

	// If we're coming to the shell from a loading screen, hide it -- jboswell
	m_kController.Pres.HideLoadingScreen();

}

state ShuttingDown
{
	simulated function Tick(float dt)
	{
		// Accumulate delta, and switch state if in this state too long.
		m_commandExecuteTimeout += dt;
		if ( m_commandExecuteTimeout > EXECUTE_COMMAND_TIMEOUT)
			GotoState('Running');
	}

Begin:	
	`log("XComShell executing:" @ m_sCommand,,'uicore');
	ConsoleCommand( m_sCommand );
}


defaultproperties
{
	PlayerControllerClass=class'XComGame.XComShellController'
	GameReplicationInfoClass=class'XComGame.XComShellGRI'
	AutoTestManagerClass = class'X2LevelGenerationAutoTestManager'
	bUseSeamlessTravel = true;
	bDelayedStart = false;
	HUDType=class'XComGame.XComShellHUD';
	MainMenuMusicAkEventPath="SoundMenuMusic.Play_Main_Menu_Music"
}