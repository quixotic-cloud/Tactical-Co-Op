// This is an Unreal Script
                           
Class X2MPCOOPPresentationLayer extends XComShellPresentationLayer;


var privatewrite UISquadSelect X2_m_kSquadSelectScreen;
var privatewrite UIMultiplayerChatManager m_kChatManager;

//----------------------------------------------------------------------------
// Initialization
//

simulated function Init()
{
	`log(self $ "::" $ GetFuncName(),,'uixcom_mp');
	super.Init();

	m_kMPShellManager.Activate();

	PushState( 'LoadingFromDisk' );
}

// Called from InterfaceMgr when it's ready to rock..
simulated function InitUIScreens()
{
	`log(self $ "::" $ GetFuncName(),,'uixcom_mp');
	
	super.InitUIScreens();
	m_bPresLayerReady = true;
 	
	UIMPLobbyScreen();
	//HideLoadingScreen();
}

simulated function HideLoadingScreen()
{
	`log("########### Finished loading and initializing map",,'uicore');
	if (InStr(class'Engine'.static.GetLastMovieName(), "load", false, true) != INDEX_NONE ||
		InStr(class'Engine'.static.GetLastMovieName(), "1080_PropLoad_001", false, true) != INDEX_NONE)
	{
		SetTimer(1.0f, false, 'HideLoadingScreenDelayed');
		//class'Engine'.static.StopMovie(true);				
	}
}

simulated function HideLoadingScreenDelayed()
{
	class'Engine'.static.StopMovie(false);	
	class'Helpers'.static.SetGameRenderingEnabled(true, 0);
}

/**
* Called when the world is being cleaned up. Allows the actor to free any dynamic content it has created.
*/
simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
}

function UIMPLobbyScreen()
{
	if(m_kNavHelpScreen == none)
	{
		if(`SCREENSTACK.GetCurrentClass()==class'UISquadSelect')
			m_kNavHelpScreen=UIShell_NavHelpScreen(`SCREENSTACK.GetFirstInstanceOf(class'UIShell_NavHelpScreen'));
		if(m_kNavHelpScreen==none)
		{
			m_kNavHelpScreen = Spawn(class'UIShell_NavHelpScreen', self);
			ScreenStack.Push(m_kNavHelpScreen);
		}
	}
	if(m_kChatManager == none)
	{
		m_kChatManager = spawn( class'UIMultiplayerChatManager', self);
		ScreenStack.Push( m_kChatManager, GetModalMovie() );
	}
	
	if(X2_m_kSquadSelectScreen == none)
	{
		
		if(`SCREENSTACK.GetCurrentClass()==class'UISquadSelect')
		{
			X2_m_kSquadSelectScreen=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		}
		else
		{
			X2_m_kSquadSelectScreen = spawn( class'UISquadSelect', self );
			ScreenStack.Push( X2_m_kSquadSelectScreen );
		}	
	}
}

function SendRemoteCommand(string Command) //Copied from UIMPShell_Lobby
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`XCOMNETMANAGER.SendRemoteCommand(Command, Parms);
	`log(`location @ "Sent Remote Command '"$Command$"'",,'Team Dragonpunk Co Op');
}
//--------------------------------------------------