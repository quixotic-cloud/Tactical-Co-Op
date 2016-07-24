//=============================================================================
// XComMainMenuController
// XCom specific playercontroller
// PlayerControllers are used by human players to control pawns.
//-----------------------------------------------------------
// FIRAXIS SOURCE CODE
// Copyright 2009 Firaxis Games
//-----------------------------------------------------------
//=============================================================================
class XComMainMenuController extends XComPlayerController;

/**
 * Looks at the current game state and uses that to set the
 * rich presence strings
 *
 * Licensees (that's us!) should override this in their player controller derived class
 */
reliable client function ClientSetOnlineStatus()
{
	`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_MainMenu);
}

//-----------------------------------------------------------
defaultproperties
{
	CheatClass=class'XComCheatManager'
	InputClass=class'XComGame.XComInputBase'
}
