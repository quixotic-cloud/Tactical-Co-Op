// This is an Unreal Script
                           
class XComOnlineEventMgr_Co_Op_Override extends XComOnlineEventMgr;

static function bool IsInvitedToCoOp()
{
	local XComOnlineGameSettings lastestInviteSettings;

	lastestInviteSettings=XComOnlineGameSettings(`ONLINEEVENTMGR.m_tAcceptedGameInviteResults[`ONLINEEVENTMGR.m_tAcceptedGameInviteResults.Length].GameSettings);
	return(lastestInviteSettings.GetMaxSquadCost()>=2147483647 && lastestInviteSettings.GetTurnTimeSeconds()==3600);
}
function OnGameInviteAccepted(const out OnlineGameSearchResult InviteResult, bool bWasSuccessful)
{
	local UISquadSelect SquadSelectScreen;
	local bool bIsMoviePlaying;
	
	`log("Dragonpunk test test test",true,'Team Dragonpunk');

	/*if(XComOnlineGameSettings(InviteResult.GameSettings).GetMaxSquadCost()<2147483647)
		StockOnGameInviteAccepted(InviteResult,bWasSuccessful);
	else
	{
		`log(`location @ `ShowVar(InviteResult.GameSettings) @ `ShowVar(m_tAcceptedGameInviteResults.Length) @ `ShowEnum(ELoginStatus, OnlineSub.PlayerInterface.GetLoginStatus(LocalUserIndex), LoginStatus), true, 'XCom_Online');

		if (!bWasSuccessful)
		{
			if (OnlineSub.PlayerInterface.GetLoginStatus(LocalUserIndex) != LS_LoggedIn)
			{
				if (class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3))
				{
					OnlineSub.PlayerInterface.AddLoginUICompleteDelegate(OnLoginUIComplete);
					OnlineSub.PlayerInterface.ShowLoginUI(true); // Show Online Only
				}
				else
				{
					InviteFailed(SystemMessage_LostConnection);
					`log("InviteFailed(SystemMessage_LostConnection)",true,'Team Dragonpunk');

				}
			}
			else
			{
				InviteFailed(SystemMessage_BootInviteFailed);
				`log("InviteFailed(SystemMessage_BootInviteFailed)",true,'Team Dragonpunk');
			}
			return;
		}

		if (InviteResult.GameSettings == none)
		{
			// XCOM_EW: BUG 5321: [PCR] [360Only] Client receives the incorrect message 'Game Full' and 'you haven't selected a storage device' when accepting a game invite which has been dismissed.
			// BUG 20260: [ONLINE] - Users will soft crash when accepting an invite to a full lobby.
			InviteFailed(SystemMessage_InviteSystemError, !IsCurrentlyTriggeringBootInvite()); // Travel to the MP Menu only if the invite was made while in-game.
			return;
		}

		if (CheckInviteGameVersionMismatch(XComOnlineGameSettings(InviteResult.GameSettings)))
		{
			InviteFailed(SystemMessage_VersionMismatch, true);
			`log("InviteFailed(SystemMessage_VersionMismatch)",true,'Team Dragonpunk');
			return;
		}


		// Mark that we accepted an invite. and active game is now marked failed
		SetShuttleToMPInviteLoadout(true);
		bAcceptedInviteDuringGameplay = true;
		m_tAcceptedGameInviteResults[m_tAcceptedGameInviteResults.Length] = InviteResult;

		// If on the boot-train, ignore the rest of the checks and reprocess once at the next valid time.
		if (bWasSuccessful && !bHasProfileSettings)
		{
			`log(`location @ " -----> Shutting down the playing movie and returning to the MP Main Menu, then accepting the invite again.",,'XCom_Online');
			return;
		}

		bIsMoviePlaying = `XENGINE.IsAnyMoviePlaying();
		if (bIsMoviePlaying || IsPlayerReadyForInviteTrigger() )
		{
			if (bIsMoviePlaying)
			{
				// By-pass movie and continue accepting the invite.
				`XENGINE.StopCurrentMovie();
			}
			if(!`SCREENSTACK.IsCurrentScreen('UISquadSelect'))
			{
				SquadSelectScreen=(`SCREENSTACK.Screens[0].Spawn(Class'UISquadSelect',none));
				`SCREENSTACK.Push(SquadSelectScreen);
				`log("Pushing SquadSelectUI to screen stack",true,'Team Dragonpunk');
			}
			else
			{
				`log("Already in Squad Select UI",true,'Team Dragonpunk');
			}
		}
		else
		{
			`log(`location @ "Waiting for whatever to finish and transition to the UISquadSelect screen.",true,'Team Dragonpunk');
		}
	}*/
}
function bool CheckInviteGameVersionMismatch(XComOnlineGameSettings InviteGameSettings)
{
	local string ByteCodeHash;
	local int InstalledDLCHash;
	local int InstalledModsHash;
	local string INIHash;
	local string TempToLog;
	local array<string> TempLog;
	
	ByteCodeHash = class'Helpers'.static.NetGetVerifyPackageHashes();
	InstalledDLCHash = class'Helpers'.static.NetGetInstalledMPFriendlyDLCHash();
	InstalledModsHash = class'Helpers'.static.NetGetInstalledModsHash();
	INIHash = class'Helpers'.static.NetGetMPINIHash();

	TempLog=class'Helpers'.static.GetInstalledModNames();
	foreach TempLog(TempToLog)
	{
		`log("Installed Mods:"@TempToLog,true,'Team Dragonpunk');
	}
	`log("Installed Mods Hash:"@InstalledModsHash @InstalledModsHash== InviteGameSettings.GetInstalledModsHash(),true,'Team Dragonpunk');

	TempLog=class'Helpers'.static.GetInstalledDLCNames();
	foreach TempLog(TempToLog)
	{
		`log("Installed DLCs:"@TempToLog,true,'Team Dragonpunk');
	}
	`log("Installed DLCs Hash:"@InstalledDLCHash @InstalledDLCHash== InviteGameSettings.GetInstalledDLCHash(),true,'Team Dragonpunk');
	`log("INI HASH:"@INIHash @INIHash== InviteGameSettings.GetINIHash() ,true,'Team Dragonpunk');
	`log("ByteCode HASH:"@ByteCodeHash @ByteCodeHash==InviteGameSettings.GetByteCodeHash(),true,'Team Dragonpunk');


	`log(`location @ "InviteGameSettings=" $ InviteGameSettings.ToString(),, 'Team Dragonpunk');
	`log(`location @ `ShowVar(ByteCodeHash) @ `ShowVar(InstalledDLCHash) @ `ShowVar(InstalledModsHash) @ `ShowVar(INIHash),, 'Team Dragonpunk');
	return false; //ByteCodeHash != InviteGameSettings.GetByteCodeHash() ||
			//InstalledDLCHash != InviteGameSettings.GetInstalledDLCHash() ||
			//InstalledModsHash != InviteGameSettings.GetInstalledModsHash();
}