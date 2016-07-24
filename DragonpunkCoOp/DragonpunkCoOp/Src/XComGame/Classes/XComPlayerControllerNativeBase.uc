//-----------------------------------------------------------
// Common base for both types of player controllers
//-----------------------------------------------------------
class XComPlayerControllerNativeBase extends PlayerController
	native(Core);

var privatewrite bool   m_bIsMouseActive;
var privatewrite bool   m_bIsConsoleBuild;


replication
{
	// we have to replicate this down to the client because it gets copied via seamless travel and never read from the local profile settings
	// so the client will have this set as false while the tactical game is playing even if the profile settings flag is true -tsmith 
	if(bNetDirty && Role == ROLE_Authority)
		m_bIsMouseActive;
}

event bool IsMouseActive()
{
	return WorldInfo.IsPlayInEditor() || (m_bIsMouseActive && !m_bIsConsoleBuild);
}

event PreBeginPlay()
{
	local XComOnlineProfileSettings ProfileSettings;
	super.PreBeginPlay();
	m_bIsConsoleBuild = WorldInfo.IsConsoleBuild();
	ProfileSettings = `XPROFILESETTINGS;
	if(ProfileSettings != none)
	{
		`log(`location @ `ShowVar(ProfileSettings.Data.IsMouseActive()), true, 'uixcom');
		SetIsMouseActive( ProfileSettings.Data.IsMouseActive() );
	}
}

function SetIsMouseActive(bool bIsMouseActive)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bIsMouseActive) @ `ShowVar(m_bIsConsoleBuild), true, 'XCom_Net');
	m_bIsMouseActive = !m_bIsConsoleBuild && bIsMouseActive;
	if(Role < ROLE_Authority)
	{
		ServerSetIsMouseActive(m_bIsMouseActive);
	}
}

protected reliable server function ServerSetIsMouseActive(bool bIsMouseActive)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bIsMouseActive) @ `ShowVar(m_bIsConsoleBuild), true, 'XCom_Net');
	m_bIsMouseActive = !m_bIsConsoleBuild && bIsMouseActive;
}



/**
 * Notification that the ControllerId for this PC LocalPlayer is about to change.  Provides the PC a chance to cleanup anything that was
 * associated with the old ControllerId.  When this method is called, LocalPlayer.ControllerId is still the old value.
 */
function PreControllerIdChange()
{
	local LocalPlayer LP;

	LP = LocalPlayer(Player);
	if ( LP != None )
	{
		ClientStopNetworkedVoice();
		ClearOnlineDelegates();

		UnregisterPlayerDataStores();
	}
}

/**
 * Notification that the ControllerId for this PC's LocalPlayer has been changed.  Re-register all player data stores and any delegates that
 * require a ControllerId.
 */
function PostControllerIdChange()
{
	local LocalPlayer LP;

	LP = LocalPlayer(Player);
	if ( LP != None )
	{
		InitUniquePlayerId();
		RegisterPlayerDataStores();

		RegisterOnlineDelegates();
		ClientSetOnlineStatus();
	}
}

/**
 * Used to have script initialize the unique player id. This is the id used
 * in all network calls.
 */
event InitUniquePlayerId()
{
	local LocalPlayer LocPlayer;
	local OnlineGameSettings GameSettings;
	local UniqueNetId PlayerId;

	if ( PlayerReplicationInfo != None )
	{
		LocPlayer = LocalPlayer(Player);
		// If we have both a local player and the online system, register ourselves
		if (LocPlayer != None &&
			PlayerReplicationInfo != None &&
			OnlineSub != None &&
			OnlineSub.PlayerInterface != None)
		{
			// Get our local id from the online subsystem
			OnlineSub.PlayerInterface.GetUniquePlayerId(LocPlayer.ControllerId,PlayerId);
			PlayerReplicationInfo.SetUniqueId(PlayerId);

			if (WorldInfo.NetMode == NM_Client)
			{
				// Grab the game so we can check for being invited
				if (OnlineSub.GameInterface != None)
				{
					GameSettings = OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName);
				}

				ServerSetUniquePlayerId(PlayerId, GameSettings != None && GameSettings.bWasFromInvite);
				bReceivedUniqueId = true;

				// Don't send a skill if we don't have one, or it hasn't been read yet
				if (PlayerReplicationInfo.PlayerSkill > 0)
				{
					ServerSetPlayerSkill(PlayerReplicationInfo.PlayerSkill);
				}
			}

		}
	}
	else
	{
		`log(self $ "::" $ GetFuncName() @ "PlayerReplicationInfo is None....aborting.", true, 'XCom_Online');
		if(!OnlineSub.SystemInterface.HasLinkConnection())
			`ONLINEEVENTMGR.ReturnToStartScreen(QuitReason_LostLinkConnection); // BUG 15434: [ONLINE]PS3 TRC R180 - A client stays on a loading screen for 70+ seconds, when the host loses their connection as the client is loading in to their game. -ttalley
		else
			`ONLINEEVENTMGR.ReturnToStartScreen(QuitReason_LostConnection); // BUG 15434: [ONLINE]PS3 TRC R180 - A client stays on a loading screen for 70+ seconds, when the host loses their connection as the client is loading in to their game. -ttalley

	}
}

/**
 * Registers the unique id of the player with the server so it can be replicated
 * to all clients.
 *
 * @param UniqueId the buffer that holds the unique id
 * @param bWasInvited whether the player was invited to play or is joining via search
 */
reliable server function ServerSetUniquePlayerId(UniqueNetId UniqueId,bool bWasInvited)
{
	local UniqueNetId ZeroId;
	local OnlineGameSettings GameSettings;

	if (!bPendingDestroy && !bReceivedUniqueId)
	{
		if (OnlineSub != None && OnlineSub.GameInterface != None)
		{
			GameSettings = OnlineSub.GameInterface.GetGameSettings(PlayerReplicationInfo.SessionName);
		}
		// if this player is banned, kick him
		//@todo: we should be doing this in the PreLogin/Login phase
		if (WorldInfo.Game.AccessControl.IsIDBanned(UniqueId))
		{
			`Log(PlayerReplicationInfo.GetPlayerAlias() @ "is banned, kicking...");
			ClientWasKicked();
			Destroy();
		}
		// Don't allow players to bypass sign in
		else if (WorldInfo.IsConsoleBuild()
			&&	GameSettings != None
			&&	!GameSettings.bIsLanMatch
			&&	UniqueId == ZeroId)
		{
			`Log(PlayerReplicationInfo.GetPlayerAlias() @ "is not validated/signed in, kicking...");
			ClientWasKicked();
			Destroy();
		}
		else
		{
			PlayerReplicationInfo.SetUniqueId(UniqueId);

			if (OnlineSub != None && OnlineSub.GameInterface != None)
			{
				// Go ahead and register the player as part of the session
				OnlineSub.GameInterface.RegisterPlayer(PlayerReplicationInfo.SessionName,PlayerReplicationInfo.UniqueId,bWasInvited);
			}
			// Notify the game that we can now be muted and mute others
			if (WorldInfo.NetMode != NM_Client)
			{
				WorldInfo.Game.UpdateGameplayMuteList(self);
				// Now that the unique id is replicated, this player can contribute to skill
				WorldInfo.Game.RecalculateSkillRating();
			}

			bReceivedUniqueId = true;
		}
	}
}

/**
 * Sends the server the player's skill for this game type so it can be replicated.
 *
 * @param PlayerSkill the player's skill for this game type
 */
reliable server function ServerSetPlayerSkill(int PlayerSkill)
{
	PlayerReplicationInfo.PlayerSkill = PlayerSkill;
}

/**
 * Looks at the current game state and uses that to set the
 * rich presence strings
 *
 * Licensees (that's us!) should override this in their player controller derived class
 */
reliable client function ClientSetOnlineStatus()
{
	`ONLINEEVENTMGR.RefreshOnlineStatus();
}

event Possess(Pawn aPawn, bool bVehicleTransition)
{
 	super.Possess(aPawn, bVehicleTransition);
	aPawn.SetTeamType(m_eTeam);
}

simulated native function SetTeamType(ETeam eNewTeam);
simulated native function SetVisibleToTeams(byte eVisibleToTeamsFlags);

/**
 * Called when the local player controller's m_eTeam variable has replicated.
 */
simulated function OnLocalPlayerTeamTypeReceived(ETeam eLocalPlayerTeam)
{
	super.OnLocalPlayerTeamTypeReceived(eLocalPlayerTeam);
	// our team has changed. set our visibility as this also sets our pawn's (the cursor's) visibility WRT our team. -tsmith
	SetVisibleToTeams(m_eTeamVisibilityFlags);
}

simulated event ReplicatedEvent(name VarName)
{
	local Actor kActor;

	if(VarName == 'm_eTeam')
	{
		foreach AllActors(class'Actor', kActor)
		{
			kActor.OnLocalPlayerTeamTypeReceived(m_eTeam);
		}
	}
	// Only init the player id if we haven't sent it to the server in the past
	else if (VarName == 'PlayerReplicationInfo' && PlayerReplicationInfo != none && !bReceivedUniqueId)
	{
		// Now the PRI is valid so we can use it for the UniqueId
		// NOTE: Even if we already have a UniqueId set, we still call InitUniquePlayerId, so the server
		//   can make sure the player is registered with the online subsystem and VOIP is setup OK.  Also,
		//   this is how we currently check for banned players
		InitUniquePlayerId();
	}
	super.ReplicatedEvent(VarName);
}

DefaultProperties
{
	// we need to always tick so that InputRepeatTimer fires when paused
	bAlwaysTick = true
}
