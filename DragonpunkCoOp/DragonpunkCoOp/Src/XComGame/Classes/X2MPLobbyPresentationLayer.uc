//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPLobbyPresentationLayer.uc
//  AUTHOR:  Todd Smith  --  8/7/2015
//  PURPOSE: Presentation Layer for the multiplayer lobby
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPLobbyPresentationLayer extends XComShellPresentationLayer;

var privatewrite UIMPShell_Lobby X2_m_kMPLobbyScreen;
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
		m_kNavHelpScreen = Spawn(class'UIShell_NavHelpScreen', self);
		ScreenStack.Push(m_kNavHelpScreen);
	}

	if(m_kChatManager == none)
	{
		m_kChatManager = spawn( class'UIMultiplayerChatManager', self);
		ScreenStack.Push( m_kChatManager, GetModalMovie() );
	}
	
	if(X2_m_kMPLobbyScreen == none)
	{
		X2_m_kMPLobbyScreen = spawn( class'UIMPShell_Lobby', self );
		ScreenStack.Push( X2_m_kMPLobbyScreen );
	}
}
//--------------------------------------------------