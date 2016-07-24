//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComPlayerController_PendingLevel.uc
//  AUTHOR:  Todd Smith  --  1/14/2011
//  PURPOSE: Taken from Gears2 code
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

/**
 * This player controller is used during pending level transitions and its only
 * purpose is to handle pending level errors differently than the engine's
 * player controller
 */
class XComPlayerController_PendingLevel extends XComPlayerController
	native(Core);

/**
 * Performs an engine level disconnect since the PlayerController "ConsoleCommand" will not
 * trigger while the pending level is occurring. -ttalley
 */
native function EngineLevelDisconnect();

simulated function OnDestroyedOnlineGame(name SessionName,bool bWasSuccessful)
{
	//`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful) @ `ShowVar(bIsAcceptingInvite));
	super.OnDestroyedOnlineGame(SessionName, bWasSuccessful);
	if ( ! bIsAcceptingInvite )
	{
		EngineLevelDisconnect();
	}
}

/**
 * Delegate called when the user accepts a game invite externally. This allows
 * the game code a chance to clean up before joining the game via
 * AcceptGameInvite() call.
 *
 * NOTE: There must be space for all signed in players to join the game. All
 * players must also have permission to play online too.
 *
 * @param InviteResult the search/settings for the game we're to join
 */
function OnGameInviteAccepted(const out OnlineGameSearchResult InviteResult, bool bWasSuccessful)
{
	//While we're a pending level controller, we can't handle game invites properly. 
	//Let the online event manager know so that the invite can reprocessed later when we can handle invites.
	`ONLINEEVENTMGR.ControllerNotReadyForInvite();
}