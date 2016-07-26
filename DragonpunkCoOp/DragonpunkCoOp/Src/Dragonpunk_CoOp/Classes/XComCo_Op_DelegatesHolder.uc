// This is an Unreal Script
                           
Class XComCo_Op_DelegatesHolder extends actor;

var string m_strMatchOptions;
var name m_nMatchingSessionName;
var X2MPShellManager m_kMPShellManager;

function MPAddLobbyDelegates()
{
	local OnlineGameInterfaceXCom GameInterface;

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.AddJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.AddLobbySettingsUpdateDelegate(OnLobbySettingsUpdate);
	GameInterface.AddLobbyMemberSettingsUpdateDelegate(OnLobbyMemberSettingsUpdate);
	GameInterface.AddLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	GameInterface.AddLobbyReceiveMessageDelegate(OnLobbyReceiveMessage);
	GameInterface.AddLobbyReceiveBinaryDataDelegate(OnLobbyReceiveBinaryData);
	GameInterface.AddLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.ClearGameInviteAcceptedDelegate(0,`ONLINEEVENTMGR.OnGameInviteAccepted);
	GameInterface.AddGameInviteAcceptedDelegate(0,OnGameInviteAccepted);
	GameInterface.AddLobbyInviteDelegate(OnLobbyInvite);

}

function MPClearLobbyDelegates()
{
	local OnlineGameInterfaceXCom GameInterface;

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.ClearJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.ClearLobbySettingsUpdateDelegate(OnLobbySettingsUpdate);
	GameInterface.ClearLobbyMemberSettingsUpdateDelegate(OnLobbyMemberSettingsUpdate);
	GameInterface.ClearLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	GameInterface.ClearLobbyReceiveMessageDelegate(OnLobbyReceiveMessage);
	GameInterface.ClearLobbyReceiveBinaryDataDelegate(OnLobbyReceiveBinaryData);
	GameInterface.ClearLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.ClearGameInviteAcceptedDelegate(0,OnGameInviteAccepted);
	GameInterface.AddGameInviteAcceptedDelegate(0,`ONLINEEVENTMGR.OnGameInviteAccepted);
	GameInterface.ClearLobbyInviteDelegate(OnLobbyInvite);

}

function OnLobbyInvite(UniqueNetId LobbyId, UniqueNetId FriendId, bool bAccepted)
{
	`log("bAccepted:"@bAccepted ,true,'Team Dragonpunk Co Op');
	if(bAccepted)
		OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).JoinLobby(LobbyID);
}

function OnJoinLobbyComplete(bool bWasSuccessful, const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, UniqueNetId LobbyUID, string Error)
{
	local string LobbyUIDString;
	LobbyUIDString = class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( LobbyUID );
	`log(`location @ `ShowVar(bWasSuccessful) @ `ShowVar(LobbyIndex) @ `ShowVar(LobbyUIDString) @ `ShowVar(Error),,'XCom_Online');
	if(bWasSuccessful)
	{
		`log("DRAGON PUNK DRAGON PUNK DRAGON PUNK DRAGON PUNK DRAGON PUNK DRAGON PUNK DRAGON PUNK",,'Team Dragonpunk Co Op');
		if( LobbyList.Length >= 2 )
		{
			OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).PublishSteamServer();
			SetLobbyServer(LobbyList[LobbyIndex].LobbyUID,OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).CurrentGameServerId);
			XComCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager).MPSendHistory();
			XComCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager).MPCheckConnections();
		}
	}
}

function OnLobbySettingsUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex)
{
	`log(`location @ `ShowVar(LobbyIndex),,'XCom_Online');
}

function OnLobbyMemberSettingsUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex),,'XCom_Online');
}

function OnLobbyMemberStatusUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, int InstigatorIndex, string Status)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(InstigatorIndex) @ `ShowVar(Status),,'XCom_Online');
}

function OnLobbyReceiveMessage(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, string Type, string Message)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(Type) @ `ShowVar(Message),,'XCom_Online');
}

function OnLobbyReceiveBinaryData(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, const out array<byte> Data)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(Data.Length),,'XCom_Online');
}

function OnLobbyJoinGame(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, UniqueNetId ServerId, string ServerIP)
{
	local string ServerIdString;
	ServerIdString = class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( ServerId );
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(ServerIdString) @ `ShowVar(ServerIP),,'XCom_Online');
}

function OnLobbyKicked(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int AdminIndex)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(AdminIndex),,'XCom_Online');
}

function SetLobbyServer(UniqueNetId LobbyIdHexString, UniqueNetId ServerIdHexString, optional string ServerIP)
{
	local OnlineGameInterfaceXCom GameInterface;

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.SetLobbyServer(LobbyIdHexString, ServerIdHexString, ServerIP);
}

function OnCreateLobbyComplete(bool bWasSuccessful, UniqueNetId LobbyId, string Error)
{
	`log(`location @ `ShowVar(class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( LobbyId )) @ `ShowVar(bWasSuccessful) @ `ShowVar(Error),,'XCom_Online');
	//OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).JoinLobby(LobbyId);
}

function OnGameInviteAccepted(const out OnlineGameSearchResult InviteResult, bool bWasSuccessful)
{
	local UISquadSelect SquadSelectScreen;
	local bool bIsMoviePlaying;
	
	`log("Dragonpunk test test test NOT IN XComOnlineEventMgr",true,'Team Dragonpunk Co Op');

	if(XComOnlineGameSettings(InviteResult.GameSettings).GetMaxSquadCost()<2147483647)
		`ONLINEEVENTMGR.OnGameInviteAccepted(InviteResult,bWasSuccessful);
	else
	{

		if (!bWasSuccessful)
		{
			if (class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.GetLoginStatus(`ONLINEEVENTMGR.LocalUserIndex) != LS_LoggedIn)
			{
				if (class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3))
				{
					class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.AddLoginUICompleteDelegate(`ONLINEEVENTMGR.OnLoginUIComplete);
					class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.ShowLoginUI(true); // Show Online Only
				}
				else
				{
					`ONLINEEVENTMGR.InviteFailed(SystemMessage_LostConnection);
					`log("InviteFailed(SystemMessage_LostConnection)",true,'Team Dragonpunk Co Op');

				}
			}
			else
			{
				`ONLINEEVENTMGR.InviteFailed(SystemMessage_BootInviteFailed);
				`log("InviteFailed(SystemMessage_BootInviteFailed)",true,'Team Dragonpunk Co Op');
			}
			return;
		}

		if (InviteResult.GameSettings == none)
		{
			// XCOM_EW: BUG 5321: [PCR] [360Only] Client receives the incorrect message 'Game Full' and 'you haven't selected a storage device' when accepting a game invite which has been dismissed.
			// BUG 20260: [ONLINE] - Users will soft crash when accepting an invite to a full lobby.
			`ONLINEEVENTMGR.InviteFailed(SystemMessage_InviteSystemError, !`ONLINEEVENTMGR.IsCurrentlyTriggeringBootInvite()); // Travel to the MP Menu only if the invite was made while in-game.
			return;
		}

		if (CheckInviteGameVersionMismatch(XComOnlineGameSettings(InviteResult.GameSettings)))
		{
			`ONLINEEVENTMGR.InviteFailed(SystemMessage_VersionMismatch, true);
			`log("InviteFailed(SystemMessage_VersionMismatch)",true,'Team Dragonpunk Co Op');
			return;
		}


		// Mark that we accepted an invite. and active game is now marked failed
		`ONLINEEVENTMGR.SetShuttleToMPInviteLoadout(true);
		`ONLINEEVENTMGR.bAcceptedInviteDuringGameplay = true;
		class'XComOnlineEventMgr_Co_Op_Override'.static.AddItemToAcceptedInvites(InviteResult);

		// If on the boot-train, ignore the rest of the checks and reprocess once at the next valid time.
		if (bWasSuccessful && !`ONLINEEVENTMGR.bHasProfileSettings)
		{
			`log(`location @ " -----> Shutting down the playing movie and returning to the MP Main Menu, then accepting the invite again.",,'XCom_Online');
			return;
		}

		bIsMoviePlaying = `XENGINE.IsAnyMoviePlaying();
		if (bIsMoviePlaying || `ONLINEEVENTMGR.IsPlayerReadyForInviteTrigger() )
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
				`log("Pushing SquadSelectUI to screen stack",true,'Team Dragonpunk Co Op');
			}
			else
			{
				`log("Already in Squad Select UI",true,'Team Dragonpunk Co Op');
			}
			OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).AcceptGameInvite(LocalPlayer(PlayerController(XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).Owner).Player).ControllerId,'XComOnlineCoOpGame_TeamDragonpunk');
		}
		else
		{
			`log(`location @ "Waiting for whatever to finish and transition to the UISquadSelect screen.",true,'Team Dragonpunk Co Op');
		}
	}
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
		`log("Installed Mods:"@TempToLog,true,'Team Dragonpunk Co Op');
	}
	`log("Installed Mods Hash:"@InstalledModsHash @InstalledModsHash== InviteGameSettings.GetInstalledModsHash(),true,'Team Dragonpunk Co Op');

	TempLog=class'Helpers'.static.GetInstalledDLCNames();
	foreach TempLog(TempToLog)
	{
		`log("Installed DLCs:"@TempToLog,true,'Team Dragonpunk Co Op');
	}
	`log("Installed DLCs Hash:"@InstalledDLCHash @InstalledDLCHash== InviteGameSettings.GetInstalledDLCHash(),true,'Team Dragonpunk Co Op');
	`log("INI HASH:"@INIHash @INIHash== InviteGameSettings.GetINIHash() ,true,'Team Dragonpunk Co Op');
	`log("ByteCode HASH:"@ByteCodeHash @ByteCodeHash==InviteGameSettings.GetByteCodeHash(),true,'Team Dragonpunk Co Op');


	`log(`location @ "InviteGameSettings=" $ InviteGameSettings.ToString(),, 'Team Dragonpunk Co Op');
	`log(`location @ `ShowVar(ByteCodeHash) @ `ShowVar(InstalledDLCHash) @ `ShowVar(InstalledModsHash) @ `ShowVar(INIHash),, 'Team Dragonpunk Co Op');
	return false; //ByteCodeHash != InviteGameSettings.GetByteCodeHash() ||
			//InstalledDLCHash != InviteGameSettings.GetInstalledDLCHash() ||
			//InstalledModsHash != InviteGameSettings.GetInstalledModsHash();
}