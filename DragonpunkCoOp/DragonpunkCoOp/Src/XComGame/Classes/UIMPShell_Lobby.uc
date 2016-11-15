//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_Lobby.uc
//  AUTHOR:  Todd Smith  --  6/25/2015
//  PURPOSE: Base lobby screen, currently just the squad editor
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_Lobby extends UIMPShell_SquadEditor;

const READY_BUTTON_OFFSET_X = -200;
const OPPONENT_SQUAD_COST_PANEL_OFFSET_X = 200;
const OPPONENT_SQUAD_COST_PANEL_OFFSET_Y = 100;
const INVITE_FRIEND_BUTTON_OFFSET_X = 100;
const INVITE_FRIEND_BUTTON_OFFSET_Y = 300;

// HAX: Wait 1.5 seconds for the 'OnDestroyedOnlineGame' delegate to get triggered. If it takes too long just quit.
const ONLINE_GAME_DESTROYED_TIMEOUT = 1.5;

enum eBeforeExit {
	eBeforeExit_Starting,
	eBeforeExit_SavedSettings,
	eBeforeExit_DestroyedGame
};

var localized string m_strMPLoadout_Select;
var localized string m_strMPLoadout_Back;

var localized string m_strMPLoadout_ClearUnit;
var localized string m_strMPLoadout_Loading;

var localized string m_strMPLoadout_Ready;
var localized string m_strMPLoadout_PressSTARTWhenReady;
var localized string m_strMPLoadout_CancelReady;
var localized string m_strMPLoadout_AllPlayersReady;
var localized string m_strMPLoadout_ReadyOverlayMessage;
var localized string m_strMPLoadout_PressStart;
var localized string m_strMPLoadout_Mouse_Start;

var localized string m_strMPLoadout_Error_SquadPoints;
var localized string m_strMPLoadout_Error_InvalidSquad;

var localized string m_strMPLoadout_InviteFriends;
var localized string m_strMPLoadout_InviteXboxLIVEParty;

var localized string m_strMPLoadout_ViewOpponentGamertag;
var localized string m_strMPLoadout_ViewOpponentProfile;

var localized string m_strConfirmExitTitle;
var localized string m_strConfirmExitText;
var localized string m_strm_strConfirmExitAcceptButton;
var localized string m_strm_strConfirmExitCancelButton;

var localized string m_strSaveChangesMadeTitle;
var localized string m_strSaveChangesMadeText;
var localized string m_strSaveChangesOverRankedPtsText;
var localized string m_strm_strSaveChangesMadeAcceptButton;
var localized string m_strm_strSaveChangesMadeCancelButton;

var localized string m_strConfirmDiscardChangesTitle;
var localized string m_strConfirmDiscardChangesText;
var localized string m_strm_strConfirmDiscardChangesAcceptButton;
var localized string m_strm_strConfirmDiscardChangesCancelButton;

var localized string m_strPlayerLeftDialog_Title;
var localized string m_strPlayerLeftDialog_Text;

var localized string  m_strSaveDisabledLoadout;

var localized string  m_strClearLoadout; 
var localized string  m_strRenameLoadout;
var localized string  m_strClearAllTitle;
var localized string  m_strClearAllText;
var localized string  m_strm_strClearAllAcceptButton;
var localized string  m_strm_strClearAllCancelButton;

var localized string  m_strQuickSaveTitle;
var localized string  m_strQuickSaveBody;
var localized string  m_strQuickSaveAccept;
var localized string  m_strQuickSaveCancel;

var localized string  m_strEnterNameHeader;
var localized string m_strInviteFriendButtonText;

var localized string m_strSquadCostErrorTitle;
var localized string m_strSquadCostErrorText;
var public string m_strNewNameRequested; 

var UIButton                  InviteFriendButton;
var UIButton                  ReadyButton;
var UILargeButton             StartButton;
var int                    m_iBeforeExitBitfield; // Uses eBeforeExit as flags
var XComGameStateHistory History;
var XComGameStateNetworkManager NetworkMgr;
var bool bWaitingForPlayerLoadout;
var bool bWaitingForHistory;
var bool bWaitingForHistoryComplete;
var bool bHistoryLoaded;
var bool bCanStartMatch;
var bool bOpponentJoined;
var XComGameState m_NewStartState;
var XComGameState_BattleDataMP m_BattleData;

var UIMPShell_SquadCostPanel_RemotePlayer m_kRemotePlayerInfo;

var public  XComMPLobbyGRI  m_kGRI;
var XComMPLobbyPRI  m_kLocalPRI;
var XComMPLobbyPRI  m_kRemotePRI;
var int             m_iPRIArrayWatchVariableHandle;
var int             m_iPartyChatStatusHandle;

var XComOnlineProfileSettings   m_kProfileSettings;
var bool            m_bProfileChangesMade;
var bool         m_bAllPlayersReady;
var bool            m_bPlayersWereReady;
var bool            m_bSavingProfileSettings;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComOnlineEventMgr OnlineEventMgr;
	//local string headerName;

	m_kGRI = XComMPLobbyGRI(WorldInfo.GRI);
	m_kLocalPRI = XComMPLobbyPRI(GetALocalPlayerController().PlayerReplicationInfo);
	m_kProfileSettings = `XPROFILESETTINGS;

		super.InitScreen(InitController, InitMovie, InitName);
	ReadLobbyLoadouts();
	m_kPawnMgr.SetCheckGameState(m_kSquadLoadout);
	m_kLocalPlayerInfo.SetPlayerLoadout(m_kSquadLoadout);

	if (!m_kMPShellManager.OnlineGame_GetIsRanked() && !m_kMPShellManager.OnlineGame_GetAutomatch())
	{
		m_bAllowEditing = true;
	}

	if (m_kMPShellManager.OnlineGame_GetIsRanked() == true)
	{
		//	headerName = class'X2MPData_Shell'.default.m_strRankedMatch;
	}
	else
	{
		//	headerName = class'X2MPData_Shell'.default.m_strUnrankedMatch;
		//	headerName @= class'X2MPData_Shell'.default.m_arrNetworkTypeNames[m_kMPShellManager.OnlineGame_GetNetworkType()];
	}
	//TEMP_ScreenNameHeader.SetText(headerName);

	Movie.Pres.AddPreClientTravelDelegate(PreClientTravel);
	PC.bVoluntarilyDisconnectingFromGame = false;

	OnlineEventMgr = `ONLINEEVENTMGR;
		OnlineEventMgr.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
	OnlineEventMgr.AddGameInviteCompleteDelegate(OnGameInviteComplete);
	OnlineEventMgr.AddNotifyConnectionProblemDelegate(OnConnectionProblem);
	class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.AddMutingChangeDelegate(OnMutingChange);

	StartButton = Spawn(class'UILargeButton', self).InitLargeButton('StartButton', class'UIStartScreen'.default.m_sPressStartPC, , StartButtonCallback);
	StartButton.AnchorTopCenter();
	StartButton.Hide();

	if (`ISCONTROLLERACTIVE)
	{
		StartButton.SetText(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, 20, 20, -10) @ class'UIStartScreen'.default.m_sPressStartPC);
		ReadyButton = Spawn(class'UILargeButton', self).InitLargeButton('ContinueButton', class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, -13) @ Caps(m_strReadyButtonText));
		ReadyButton.AnchorBottomRight();
	}
	else
	{
		ReadyButton = Spawn(class'UIButton', self).InitButton('ReadyButton', m_strReadyButtonText, ReadyButtonCallback);
		ReadyButton.AnchorTopCenter();
		ReadyButton.SetPosition(-450, 140);
	}


	History = `XCOMHISTORY;
	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.AddPlayerJoinedDelegate(PlayerJoined);
	NetworkMgr.AddPlayerLeftDelegate(PlayerLeft);
	NetworkMgr.AddReceiveLoadTacticalMapDelegate(ReceiveLoadTacticalMap);
	NetworkMgr.AddReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.AddReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.AddReceiveGameStateDelegate(ReceiveGameState);
	NetworkMgr.AddReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	NetworkMgr.AddReceiveRemoteCommandDelegate(OnRemoteCommand);
	NetworkMgr.AddNotifyConnectionClosedDelegate(OnConnectionClosed);
	SubscribeToOnCleanupWorld();

	InitWidgets();
	UpdateData();
	
	if( NetworkMgr.HasClientConnection() )
	{
		bCanStartMatch = false;
		GotoState('JoiningOpponent');
	}
	else if ( NetworkMgr.HasServerConnection() )
	{
		bCanStartMatch = true;
		GotoState('WaitingForOpponent');
	}
}
function UpdateNavHelp()
{
	if( `ISCONTROLLERACTIVE == false ) return; 
	
	NavHelp.ClearButtonHelp();

	if(!bIsFocused)
		return;

	NavHelp.AddBackButton(BackButtonCallback);
	NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericDetails, class'UIUtilities_Input'.const.ICON_LSCLICK_L3, InfoButtonCallback);

	if (m_kMPShellManager.OnlineGame_GetNetworkType() != eMPNetworkType_LAN && !m_kMPShellManager.OnlineGame_GetIsRanked() )
	{
		NavHelp.AddCenterHelp(m_strInviteFriendButtonText, class'UIUtilities_Input'.const.ICON_BACK_SELECT);
	}	
	else if(!IsInState('WaitingForOpponent') && (!NetworkMgr.HasServerConnection() ))
	{
		NavHelp.AddCenterHelp(m_strMPLoadout_ViewOpponentProfile, class'UIUtilities_Input'.const.ICON_RT_R2);
	}
	if(m_kLocalPlayerInfo.m_iSquadCost > 0 && (m_kLocalPlayerInfo.m_iSquadCost <= m_kGRI.m_iMPMaxSquadCost || m_kGRI.m_iMPMaxSquadCost  <= 0))
	{		
		ReadyButton.SetVisible(true);
		if(m_kLocalPlayerInfo.GetPlayerReady())
		{
			//NavHelp.AddRightHelp(m_strMPLoadout_CancelReady, class'UIUtilities_Input'.const.ICON_X_SQUARE);
			ReadyButton.SetText(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, 0) @ m_strMPLoadout_CancelReady);

			//TODO - should be removed when the auto-start feature is implemented after all players have "readied up" - JTA 2016/2/9
			if(NetworkMgr != None && NetworkMgr.HasServerConnection() && m_bAllPlayersReady)
				NavHelp.AddRightHelp(Caps(class'UIStartScreen'.default.m_sPressStartPC), class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
		}
		else
		{
			ReadyButton.SetText(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, 0) @ m_strMPLoadout_Ready);
		}
	}
	else
	{
		ReadyButton.SetVisible(false);
	}

	if( IsInState('EditingUnits') )
	{
		if(NetworkMgr.HasServerConnection() && m_bAllPlayersReady)
		{
			StartButton.Show();
			StartButton.SetPosition(-StartButton.Width * 0.5f, 140);
		}
		else if(m_kLocalPlayerInfo.GetPlayerReady())
		{
			StartButton.Hide();
			ReadyButton.SetText(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, 0) @ m_strMPLoadout_CancelReady);
		}
		else
		{
			StartButton.Hide();
			ReadyButton.SetText(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_X_SQUARE, 26, 26, 0) @ m_strMPLoadout_Ready);
			ReadyButton.SetDisabled(!(m_kLocalPlayerInfo.m_iSquadCost > 0 && (m_kLocalPlayerInfo.m_iSquadCost <= m_kGRI.m_iMPMaxSquadCost || m_kGRI.m_iMPMaxSquadCost  < 0)));
		}
	}
}

function Tick( float DeltaTime )
{
	local OnlineSubsystem OnlineSub; 
    local XComOnlineEventMgr OnlineEventMgr; 

    OnlineEventMgr = `ONLINEEVENTMGR; 
    OnlineSub = class'GameEngine'.static.GetOnlineSubsystem(); 

	super.Tick(DeltaTime);

	if(OnlineSub.VoiceInterface != none)
	{
		m_kLocalPlayerInfo.SetMicAvailable(!OnlineSub.VoiceInterface.IsHeadsetPresent(OnlineEventMgr.LocalUserIndex));
	}
}

simulated function PlayerTalking(UniqueNetId Player,bool bIsTalking)
{
	if(Player == m_kRemotePlayerInfo.GetPlayerGameState().GetGameStatePlayerNetId())
	{
		m_kRemotePlayerInfo.SetMicActive(bIsTalking);
	}
	else
	{
		m_kLocalPlayerInfo.SetMicActive(bIsTalking);
	}
}

simulated function OnInit()
{
	local OnlineSubsystem OnlineSub; 
   
    OnlineSub = class'GameEngine'.static.GetOnlineSubsystem(); 

	super.OnInit();

	UpdateButtons();

	OnlineSub.VoiceInterface.AddPlayerTalkingDelegate(PlayerTalking);

	// code added from XEU main menu (UIMultiplayerShell) -tsmith
	m_bProfileChangesMade = false;
	m_bPlayersWereReady = false;

	// @TODO tsmith: do we need this stuff, most importantly do we need the watch variable code.
	//RefreshMouseState();
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( Movie, 'IsMouseActive', self, RefreshMouseState);
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kLocalPlayerInfo, 'm_bDataChanged', self, LoadoutChanged);
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kLocalPRI, 'm_bPlayerReady', self, PlayerReadyChanged);
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kLocalPRI, 'm_iTotalSquadCost', self, RealizeReadyButtonEnable);
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kGRI, 'm_bAllPlayersReady', self, RefreshData);
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kGRI, 'm_bGameStarting', self, ShowStartingGamePopup);
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(m_kGRI, 'm_bGameStartAborted', self, ShowAbortedPopup);
	//// NOTE: Dont register watch variables for the remote PRI here, do it in the function RegisterRemotePRIWatchVariables because it may not be valid here -tsmith 

	//m_kPopupMessager = Spawn(class'UIMessageMgr', self);
	//m_kPopupMessager.InitScreen(PC, Movie, 'SpecialInstance_MPPopupMessenger');

	//Invoke("AnimateIn");

	//`log(`location @ "Remote player joined, assuming loadout is done loading.",,'XCom_Online');
	//m_kLocalPRI.SetPlayerLoaded(true);

	// Will display any pending information for the user since the screen has been transitioned. -ttalley
	`ONLINEEVENTMGR.PerformNewScreenInit();

	// Initialize delegates for connection error popus after the Shell is initialized - sbatista 3/22/12
	m_kMPShellManager.OnMPShellScreenInitialized();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	m_kMPShellManager.UpdateConnectivityData();
	if(m_kMPShellManager != none && !m_kMPShellManager.m_bPassedNetworkConnectivityCheck)
	{
		// we should have already been booted back to the main menu but i'm guessing there is a timing issue with this screen not being detected in the UI stack -tsmith
		m_kMPShellManager.m_OnlineEventMgr.ReturnToMPMainMenu(QuitReason_LostLinkConnection);
	}
	UpdateNavHelp();
}

function ReadLobbyLoadouts()
{
	// create an empty state, i.e. allocate memory so that we can read it in from disc. -tsmith
	m_kTempLobbyLoadout = m_kMPShellManager.CreateEmptyLoadout("LobbyLoadout");
	m_kProfileSettings.X2MPReadTempLobbyLoadout(m_kTempLobbyLoadout);
	m_kOriginalSquadLoadout = m_kTempLobbyLoadout;
	m_kSquadLoadout = m_kMPShellManager.CloneSquadLoadoutGameState(m_kOriginalSquadLoadout, true);
}

function InitSquadCostPanels()
{
	`log(`location,, 'XCom_Online');
	Super.InitSquadCostPanels();

	// @TODO tsmith: the cost values will be filled in by the actual squad
	m_kRemotePlayerInfo = Spawn(class'UIMPShell_SquadCostPanel_RemotePlayer', self);
	m_kRemotePlayerInfo.InitRemotePlayerSquadCostPanel(m_kMPShellManager);
	m_kRemotePlayerInfo.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_CENTER);
	m_kLocalPlayerInfo.SetPosition(-500, 0);
}

function InitWidgets()
{
	UpdateButtons();
	CreateSquadInfoItems();
}

function UpdateButtons()
{
	if(!Movie.IsMouseActive())
	{
		UpdateNavHelp();
		return;
	}
	NavHelp.ClearButtonHelp();

	NavHelp.AddBackButton(BackButtonCallback);

	if( IsInState('WaitingForOpponent') || !bOpponentJoined)
	{
		StartButton.Hide();
		
		if(m_kMPShellManager.OnlineGame_GetNetworkType() != eMPNetworkType_LAN && !m_kMPShellManager.OnlineGame_GetIsRanked() )
		{
			NavHelp.AddCenterHelp(m_strInviteFriendButtonText, "", InviteFriendButtonCallback);
		}
		
		if(m_kLocalPlayerInfo.GetPlayerReady())
		{
			ReadyButton.SetText(m_strMPLoadout_CancelReady);
		}
		else
		{
			ReadyButton.SetText(m_strReadyButtonText);
			ReadyButton.SetDisabled(!(m_kLocalPlayerInfo.m_iSquadCost > 0 && (m_kLocalPlayerInfo.m_iSquadCost <= m_kGRI.m_iMPMaxSquadCost || m_kGRI.m_iMPMaxSquadCost  < 0)));
		}
	}
	else if( IsInState('EditingUnits') )
	{
		if(NetworkMgr.HasServerConnection() && m_bAllPlayersReady)
		{
			StartButton.Show();
			StartButton.SetPosition(-StartButton.Width * 0.5f, 140);
		}
		else if(m_kLocalPlayerInfo.GetPlayerReady())
		{
			StartButton.Hide();
			ReadyButton.SetText(m_strMPLoadout_CancelReady);
		}
		else
		{
			StartButton.Hide();
			ReadyButton.SetText(m_strReadyButtonText);
			ReadyButton.SetDisabled(!(m_kLocalPlayerInfo.m_iSquadCost > 0 && (m_kLocalPlayerInfo.m_iSquadCost <= m_kGRI.m_iMPMaxSquadCost || m_kGRI.m_iMPMaxSquadCost  < 0)));
		}
	}

	ReadyButton.SetPosition(-450, 140);
}

function BackButtonCallback()
{
	DisplayConfirmExitDialog();
}

function ReadyButtonCallback(UIButton button)
{
	local TDialogueBoxData kDialogData;
	//Don't allow ready state to change if game has started
	if(IsInState('Client_LoadingMap'))
		return;
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(m_kLocalPlayerInfo.m_iSquadCost > 0 && (m_kLocalPlayerInfo.m_iSquadCost <= m_kGRI.m_iMPMaxSquadCost || m_kGRI.m_iMPMaxSquadCost  < 0))
	{
		m_kLocalPlayerInfo.TogglePlayerReady();

		if(m_kLocalPlayerInfo.GetPlayerReady())
			PlayAKEvent(AkEvent'SoundX2Multiplayer.MP_Player_Ready' );
		else
			PlayAKEvent(AkEvent'SoundX2Multiplayer.MP_Player_Ready_Cancel' );

		PlayerReadyChanged();

		UpdateData();
	}
	else
	{
		kDialogData.strTitle = m_strSquadCostErrorTitle;
		kDialogData.eType = eDialog_Warning;
		kDialogData.strText = m_strSquadCostErrorText;
		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;

		`PRES.UIRaiseDialog(kDialogData);
	}
}

function StartButtonCallback(UIButton button)
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');

	//As only the host has a visible start button only let the host start the game
	if(NetworkMgr.HasServerConnection() && m_bAllPlayersReady)
	{
		StartGame();
	}
}


function InviteFriendButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	OnInviteButtonClicked();
}

function ViewOpponentProfile()
{

}


//X-Com 2 MP Lobby integration
//=====================================================
function CreateServer(optional int Port=7777, optional bool bSteam=false)
{
	local string Error;
	local URL ServerURL;
	`log(`location,,'XCom_Online');
	ServerURL.Port = Port;
	if (bSteam)
	{
		ServerURL.Op.AddItem("steamsockets");
	}
	NetworkMgr.CreateServer(ServerURL, Error);
}

function CreateClient(string ServerURL, optional int Port=7777)
{
	local string Error;
	local URL ClientURL;
	`log(`location,,'XCom_Online');
	ClientURL.Host = ServerURL;
	ClientURL.Port = Port;
	NetworkMgr.CreateClient(ClientURL, Error);
}

function SetupMission()
{
	local XComGameState                     TacticalStartState;
	local XComTacticalMissionManager		MissionManager;
	local XComGameState_MissionSite			MPMission;

	TacticalStartState = History.GetStartState();

	// There should only be one Mission Site for MP in the Tactical Start State
	foreach TacticalStartState.IterateByClassType(class'XComGameState_MissionSite', MPMission)
	{
		`log(`location @ MPMission.ToString(),,'XCom_Online');
		break;
	}

	// Setup the Mission Data
	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.ForceMission = MPMission.GeneratedMission.Mission;
	MissionManager.MissionQuestItemTemplate = MPMission.GeneratedMission.MissionQuestItemTemplate;
}

function SetupMapData(XComGameState StrategyStartState, XComGameState TacticalStartState)
{
	local XComGameState_MissionSite			MPMission;
	local X2MissionSourceTemplate			MissionSource;
	local XComGameState_Reward				RewardState;
	local X2RewardTemplate					RewardTemplate;
	local X2StrategyElementTemplateManager	StratMgr;
	local array<XComGameState_WorldRegion>  arrRegions;
	local XComGameState_WorldRegion         RegionState;
	local string                            PlotType;
	local string                            Biome;
	local GeneratedMissionData              EmptyData;
	local XComTacticalMissionManager        MissionMgr;
	local XComParcelManager                 ParcelMgr;
	local array<PlotDefinition>             arrValidPlots;
	local array<PlotDefinition>             arrSelectedTypePlots;
	local PlotDefinition                    CheckPlot;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	MissionMgr = `TACTICALMISSIONMGR;
	ParcelMgr = `PARCELMGR;

	PlotType = m_kMPShellManager.OnlineGame_GetMapPlotName();
	Biome = m_kMPShellManager.OnlineGame_GetMapBiomeName();

	`log(self $ "::" $ GetFuncName() @ `ShowVar(PlotType) @ `ShowVar(Biome),, 'uixcom_mp');

	// Setup the MissionRewards
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(StrategyStartState);
	RewardState.SetReward(,0);
	StrategyStartState.AddStateObject(RewardState);

	// Setup the GeneratedMission
	MPMission = XComGameState_MissionSite(StrategyStartState.CreateStateObject(class'XComGameState_MissionSite'));
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_Multiplayer'));

	// Choose a random region
	foreach StrategyStartState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		arrRegions.AddItem(RegionState);
	}
	RegionState = arrRegions[`SYNC_RAND_STATIC(arrRegions.Length)];

	// Build the mission
	MPMission.GeneratedMission = EmptyData;
	MPMission.GeneratedMission.MissionID = MPMission.ObjectID;
	MPMission.GeneratedMission.Mission = MissionMgr.GetMissionDefinitionForSourceReward(MissionSource.DataName, RewardState.GetMyTemplate().DataName);
	MPMission.GeneratedMission.LevelSeed = class'Engine'.static.GetEngine().GetSyncSeed();
	MPMission.GeneratedMission.BattleDesc = "";
	MPMission.GeneratedMission.MissionQuestItemTemplate = MissionMgr.ChooseQuestItemTemplate(MissionSource.DataName, RewardState.GetMyTemplate(), MPMission.GeneratedMission.Mission);
	
	MPMission.GeneratedMission.BattleOpName = class'XGMission'.static.GenerateOpName(false);
	ParcelMgr.GetValidPlotsForMission(arrValidPlots, MPMission.GeneratedMission.Mission, Biome);
	if(PlotType == "")
	{
		MPMission.GeneratedMission.Plot = arrValidPlots[`SYNC_RAND_STATIC(arrValidPlots.Length)];
	}
	else
	{
		foreach arrValidPlots(CheckPlot)
		{
			if(CheckPlot.strType == PlotType)
				arrSelectedTypePlots.AddItem(CheckPlot);
		}

		MPMission.GeneratedMission.Plot = arrSelectedTypePlots[`SYNC_RAND_STATIC(arrSelectedTypePlots.Length)];
		`assert(MPMission.GeneratedMission.Plot.ObjectiveTags.Find("Multiplayer") != INDEX_NONE);
	}

	if(MPMission.GeneratedMission.Mission.sType == "")
	{
		`Redscreen("GetMissionDataForSourceReward() failed to generate a mission with: \n"
						$ " Source: " $ MissionSource.DataName $ "\n RewardType: " $ RewardState.GetMyTemplate().DisplayName);
	}

	if(Biome == "" && MPMission.GeneratedMission.Plot.ValidBiomes.Length > 0)
	{
		// This plot uses biomes but the user didn't select one, so pick one here
		Biome = MPMission.GeneratedMission.Plot.ValidBiomes[`SYNC_RAND(MPMission.GeneratedMission.Plot.ValidBiomes.Length)];
	}
	if(Biome != "")
	{
		MPMission.GeneratedMission.Biome = ParcelMgr.GetBiomeDefinition(Biome);
	}
	`assert(Biome == "" || MPMission.GeneratedMission.Plot.ValidBiomes.Find(Biome) != INDEX_NONE);

	// Add the mission to the start states
	StrategyStartState.AddStateObject(MPMission);
	MPMission = XComGameState_MissionSite(TacticalStartState.CreateStateObject(class'XComGameState_MissionSite', MPMission.ObjectID));
	TacticalStartState.AddStateObject(MPMission);

	// Setup the Battle Data
	m_BattleData.iLevelSeed				= MPMission.GeneratedMission.LevelSeed;
	m_BattleData.m_strDesc				= "Multiplayer"; //If you change this, be aware that this is how the ruleset knows the battle is a challenge mode battle
	
	m_BattleData.m_strOpName  = m_kMPShellManager.GetMatchString(true);
	m_BattleData.bRanked = m_kMPShellManager.OnlineGame_GetIsRanked();
	m_BattleData.bAutomatch = m_kMPShellManager.OnlineGame_GetAutomatch();

	m_BattleData.iMaxSquadCost = m_kMPShellManager.OnlineGame_GetMaxSquadCost();
	m_BattleData.iTurnTimeSeconds = m_kMPShellManager.OnlineGame_GetTurnTimeSeconds();
	m_BattleData.bMultiplayer = true;
	m_BattleData.strMapType = m_kMPShellManager.OnlineGame_GetLocalizedMapPlotName()@ m_kMPShellManager.OnlineGame_GetLocalizedMapBiomeName();

	m_BattleData.m_strMapCommand		= "open" @ MPMission.GeneratedMission.Plot.MapName $ "?game=XComGame.XComMPTacticalGame";
	m_BattleData.MapData.PlotMapName    = MPMission.GeneratedMission.Plot.MapName;
	m_BattleData.MapData.Biome          = MPMission.GeneratedMission.Biome.strType;
	m_BattleData.bUseFirstStartTurnSeed = true;
	m_BattleData.iFirstStartTurnSeed    = class'Engine'.static.GetARandomSeed();
	m_BattleData.GameSettings           = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
	if (m_BattleData.GameSettings == None)
	{
		m_BattleData.GameSettings       = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Lobby'));
	}

	`log(`location @ `ShowVar(m_BattleData.MapData.PlotMapName, PlotMapName) @ `ShowVar(m_BattleData.MapData.Biome, Biome) @ `ShowVar(m_BattleData.m_strMapCommand, MapCommand),,'XCom_Online');

	// Randomize the Player Order
	RandomizePlayerTurnOrder();
}

function RandomizePlayerTurnOrder()
{
	m_BattleData.PlayerTurnOrder.RandomizeOrder();
}

function SetupStartState()
{
	local XComGameState StrategyStartState, TacticalStartState;
	local XGTacticalGameCore GameCore;
	local int TurnTime;
	local XComGameState_TimerData Timer;
	local bool TimerCreated;

	`log(`location,,'XCom_Online');

	`ONLINEEVENTMGR.ReadProfileSettings();
	History.ResetHistory();
	//bsg-mfawcett(09.01.16): reset mission manager cards here so that we can correctly set up our mission (fixes issue with fresh profile going into MP lobby, backing out, then starting another MP lobby)
	`TACTICALMISSIONMGR.ResetCachedCards();

	///
	/// Setup the Strategy side ...
	///

	// Create the basic strategy objects
	StrategyStartState = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(, , , , , , false, , class'X2DataTemplate'.const.BITFIELD_GAMEAREA_Multiplayer, false /*SetupDLCContent*/);


	///
	/// Setup the Tactical side ...
	///

	// Setup the GameCore
	GameCore = `GAMECORE;
	if(GameCore == none)
	{
		GameCore = Spawn(class'XGTacticalGameCore', self);
		GameCore.Init();
		`GAMECORE = GameCore;
	}

	// Create the basic objects
	TacticalStartState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Multiplayer(m_BattleData);


	///
	/// Setup the Map
	///

	// Configure the map from the current strategy start state
	SetupMapData(StrategyStartState, TacticalStartState);

	//Add the start state to the history
	History.AddGameStateToHistory(TacticalStartState);
	m_NewStartState = TacticalStartState;

	// Create the turn timer for the players
	TurnTime = m_kMPShellManager.OnlineGame_GetTurnTimeSeconds();
	if(TurnTime == class'X2MPData_Common'.const.INFINITE_VALUE)
		TurnTime = 0;

	TimerCreated = false;
	foreach TacticalStartState.IterateByClassType(class'XComGameState_TimerData', Timer)
	{
		if(Timer != none)
			TimerCreated = true;
	}
	if(!TimerCreated && TurnTime > 0)
		class'XComGameState_TimerData'.static.CreateAppRelativeGameTimer(TurnTime,TacticalStartState,,,EGSTRT_PerTurn);
}


function ReadGameState()
{
	`log(`location,,'XCom_Online');
	//History.ReadHistoryFromFile("SaveData_Dev/", "MPTacticalGameStartState");
}

function LoadTacticalMap()
{
	//local XComGameStateNetworkManager NetworkMgr;
	local XComGameState_BattleDataMP BattleDataState;
	`log(`location,,'XCom_Online');
	SetupMission();
	BattleDataState = XComGameState_BattleDataMP(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleDataMP'));
	//NetworkMgr.SetPauseGameStateSending(true);

	Cleanup();
	`log(`location @ "'" $ BattleDataState.m_strMapCommand $ "'",,'XCom_Online');
	ConsoleCommand(BattleDataState.m_strMapCommand);
}

function SendHistory()
{
	`log(`location,,'XCom_Online');
	NetworkMgr.SendHistory(`XCOMHISTORY, `XEVENTMGR);
}

// Returns true if sent
function bool SendOrMergeGamestate(XComGameState GameState)
{
	local bool bGameStateSubmitted;
	bGameStateSubmitted = false;
	if (NetworkMgr.HasConnections())
	{
		if (History.GetStartState() != none)
		{
			NetworkMgr.SendMergeGameState(GameState);
		}
		else
		{
			// HACK: Setting the CachedHistory since the Tacticalrules have not been setup yet ...
			`TACTICALRULES.BuildLocalStateObjectCache();
			`TACTICALRULES.SubmitGameState(GameState);
			bGameStateSubmitted = true;
		}
	}
	return bGameStateSubmitted;
}

// XComGameStateNetworkManager::delegate OnPlayerJoined(string Address, const UniqueNetId UniqueId, bool bSupportsAuth)
function PlayerJoined(string RequestURL, string Address, const UniqueNetId UniqueId, bool bSupportsAuth)
{
	local string strUniqueId;
	bOpponentJoined = true;
	
	strUniqueId = class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueId);
	`log(`location @ `ShowVar(RequestURL) @ `ShowVar(Address) @ `ShowVar(strUniqueId) @ `ShowVar(bSupportsAuth),,'XCom_Online');
	
	RemotePlayerJoined(UniqueId);  // Player joined, update!
}

function PlayerLeft(const UniqueNetId UniqueId)
{
	local string strUniqueId;
	bOpponentJoined = false;
	
	strUniqueId = class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueId);
	`log(`location @ `ShowVar(strUniqueId),,'XCom_Online');
	RemotePlayerLeft(UniqueId); // Player left, update!
}

function ReceiveLoadTacticalMap()
{
	`log(`location @ `ShowVar(bHistoryLoaded),,'XCom_Online');
	if (bHistoryLoaded)
	{		
		LoadTacticalMap();
	}
	else
	{
		SetTimer(0.1f, false, NameOf(ReceiveLoadTacticalMap));
	}
}

function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	`log(`location,,'XCom_Online');
	bHistoryLoaded = true;
}

function ReceivePartialHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	`log(`location,,'XCom_Online');
	bHistoryLoaded = true;
}

function ReceiveGameState(XComGameState InGameState)
{
	`log(`location,,'XCom_Online');
	CalcAllPlayersReady();
	UpdateButtons();
}

function ReceiveMergeGameState(XComGameState InGameState)
{
	`log(`location,,'XCom_Online');
	CalcAllPlayersReady();
	UpdateButtons();
}

function SendPlayerUpdate()
{
	local XComGameState NewGameState;

	NewGameState = m_kLocalPlayerInfo.CreateUpdateGameStatePlayer();

	if( NewGameState == None )
	{
		`warn(`location @ "Empty GameState Player Update, not sending!");
		return;
	}

	// Send the Player's GameState to its Peer
	if (!SendOrMergeGamestate(NewGameState))
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

function OnInviteButtonClicked()
{
	local OnlineSubsystem onlineSub;
	local int LocalUserNum;
	`log("OnInviteButtonClicked: NetworkType=" $ m_kMPShellManager.OnlineGame_GetNetworkType(),,'uixcom');

	if(m_kMPShellManager.OnlineGame_GetNetworkType() == eMPNetworkType_LAN || m_kMPShellManager.OnlineGame_GetIsRanked())
		return;

	if (!CanInvite())
	{
		return;
	}
	onlineSub = `ONLINEEVENTMGR.OnlineSub;
	`assert(onlineSub != none);

	LocalUserNum = `ONLINEEVENTMGR.LocalUserIndex;

	if(WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))
	{
		`assert(onlineSub.PartyChatInterface != none);
		if(UsePartyInvite())
		{
			onlineSub.PartyChatInterface.ShowPartyUI(LocalUserNum);
		}
		else
		{
			onlineSub.PlayerInterface.ShowFriendsUI(LocalUserNum);
		}
	}
	else
	{
		onlineSub.PlayerInterfaceEx.ShowInviteUI(LocalUserNum);
	}
}
function OnGamertagButtonClicked()
{
	//if(m_kGRI.m_eMPNetworkType == eMPNetworkType_LAN || m_kRemotePRI == none)
	//	return;

	//`ONLINEEVENTMGR.ShowGamerCardUI(m_kRemotePRI.UniqueId);
}

function bool HasLoadoutChanged()
{
	return m_bProfileChangesMade;
}

function LoadoutChanged()
{
	//m_bProfileChangesMade = m_kLocalPlayerInfo.HasDataChanged();
	//RealizeReadyButtonEnable();
	//`log(self $ "::" $ GetFuncName() @ "Data Changed?" @ `ShowVar(m_bProfileChangesMade));
	//if (m_bProfileChangesMade)
	//{
	//	SendPlayerUpdate();
	//}
}

function PlayerReadyChanged()
{
	SendPlayerUpdate();
	CalcAllPlayersReady();
	UpdateButtons();
}

function CalcAllPlayersReady()
{
	local XComGameState_Player PlayerState;
	local bool bAllPlayersReady;

	bAllPlayersReady = true;
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(!PlayerState.bPlayerReady)
		{
			bAllPlayersReady = false;
			break;
		}
	}
	if(!m_bAllPlayersReady && bAllPlayersReady)
	{
		// we just got everyone ready play a sound
		Movie.Pres.PlayUISound(eSUISound_SoldierPromotion);
	}
	m_bAllPlayersReady = bAllPlayersReady;
}

function StartGame()
{	
	//We need to show immediate feedback that you've pressed start in the UI, before the data 
	//replicates back to trigger this message.
	ShowStartingGamePopup();
			
	/** DoStartGame() will trigger the game save and content begin loading, but that loading will cause the UI not to 
		complete its visual update. So, here, we're putting a short delay before calling save so that the UI 
		has been able to update visually. It will still hitch any looping animations while loading, which we 
		may want to fix later byt triggering the loading screen sooner.  -bsteiner 5.5.11
	*/
	SetTimer(0.5f, false, 'DoStartGame', self); 

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

function DoStartGame()
{
	// Save and replicate settings
	//UpdateSquadLoadoutSettings(m_kProfileSettings.GetDefaultLoadoutId());

	CleanUpPartyChatWatch();

	PushState('Server_LoadingMap');
}

function CancelGame()
{
	if (0 == m_iBeforeExitBitfield) // Disallow multiple cancels
	{
		History.ResetHistory();
		m_iBeforeExitBitfield = m_iBeforeExitBitfield | (1 << eBeforeExit_Starting);
		m_iBeforeExitBitfield = m_iBeforeExitBitfield | (1 << eBeforeExit_SavedSettings); // No need to save
		StartExitLoadoutScreen();
	}
}

function StartExitLoadoutScreen()
{
	local OnlineGameInterface kGameInterface;

	CleanUpPartyChatWatch();
	kGameInterface = `ONLINEEVENTMGR.OnlineSub.GameInterface;
	if (none != kGameInterface)
	{
		PC.bVoluntarilyDisconnectingFromGame = true;
		kGameInterface.AddDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
		kGameInterface.DestroyOnlineGame('Game');  // Clean-up the OSS Game Session
		
		// Only seems to be a problem on the Xbox
		if(WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))
		{
			// Add a timeout in case it takes too long to destroy the online game.
			SetTimer(ONLINE_GAME_DESTROYED_TIMEOUT, false, 'ExitNow');
		}
	}
	else
	{
		ExitNow();
	}
}

function ExitNow()
{
	m_iBeforeExitBitfield = m_iBeforeExitBitfield | (1 << eBeforeExit_DestroyedGame);
	AttemptExitLoadoutScreen();
}

function AttemptExitLoadoutScreen()
{
	local OnlineGameInterface kGameInterface;

	if (0 != (m_iBeforeExitBitfield & ((1 << eBeforeExit_SavedSettings) | (1 << eBeforeExit_DestroyedGame))))
	{
		// Clear the ExitNow timer in case the 'OnDestroyedOnlineGame' gets trigerred before the timer hits.
		if(WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))
			ClearTimer('ExitNow');

		kGameInterface = `ONLINEEVENTMGR.OnlineSub.GameInterface;
		kGameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);

		// @TODO tsmith: call animate out when the flash assets are in, otherwise ReturnToMPMainMenu never gets called bc AnimateOutComplete command never comes through
		`ONLINEEVENTMGR.ReturnToMPMainMenu();
		// NOTE: this triggers a call to flash which then calls OnCommand with the argument "AnimateOutComplete" which then correctly disconnects the game. -tsmith 
		//Invoke("AnimateOut");
	}
}

function DisplayConfirmExitDialog()
{
	local TDialogueBoxData kConfirmData;

	`ONLINEEVENTMGR.m_bMPConfirmExitDialogOpen = true;

	kConfirmData.strTitle = m_strConfirmExitTitle;
	kConfirmData.strText = m_strConfirmExitText;
	kConfirmData.strAccept = m_strm_strConfirmExitAcceptButton;
	kConfirmData.strCancel = m_strm_strConfirmExitCancelButton;

	kConfirmData.fnCallback = OnDisplayConfirmExitDialogAction;
		
	NavHelp.ClearButtonHelp(); //Nav Help will be refreshed when we gain focus again, if the user changes their mind
	Movie.Pres.UIRaiseDialog(kConfirmData);
}

function OnDisplayConfirmExitDialogAction(eUIAction eAction)
{
	local XComPresentationLayerBase Presentation;
	local XComShellPresentationLayer ShellPresentation;
	//local TProgressDialogData kDialogBoxData;
	`ONLINEEVENTMGR.m_bMPConfirmExitDialogOpen = false;

	if (eAction == eUIAction_Accept)
	{
		//Moved dialog popup inside of accept button press to only show the dialog if the user is backing out of the lobby
		Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
		ShellPresentation = XComShellPresentationLayer(Presentation);

		if (ShellPresentation != none)
		{
			//kDialogBoxData.strTitle = ShellPresentation.m_strOnlineCancelingMultiplayerSession_Title;
			//kDialogBoxData.strDescription = ShellPresentation.m_strOnlineCancelingMultiplayerSession_Text;
			//Presentation.UIProgressDialog(kDialogBoxData);

			if(NavHelp != None)
			{
				NavHelp.ClearButtonHelp();
			}
		}
		Cleanup();
		//OnBack();
		CancelGame();
	}
}

simulated function CloseScreen()
{
	Cleanup();
	CancelGame();
}

simulated function OnCommand( string cmd, string arg )
{
	if( cmd == "AnimateOutComplete")  
		`ONLINEEVENTMGR.ReturnToMPMainMenu();
	else
		super.OnCommand( cmd, arg );
}

function OnDestroyedOnlineGame(name SessionName,bool bWasSuccessful)
{
	local OnlineGameInterface kGameInterface;

	`log(self $ "::" $ GetFuncName() @ "- Attempting to exit.", true, 'XCom_Online');

	kGameInterface = `ONLINEEVENTMGR.OnlineSub.GameInterface;
	`log(`location @ "SessionName="$SessionName @ "bWasSuccessful="$bWasSuccessful);
	// Make sure that all sessions are fully closed
	if (kGameInterface.GetGameSettings('Game') == None && kGameInterface.GetGameSettings('Lobby') == None)
	{
		kGameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	

	m_iBeforeExitBitfield = m_iBeforeExitBitfield | (1 << eBeforeExit_DestroyedGame);
	AttemptExitLoadoutScreen();
	}
}

function OnSaveCompleteCancel(bool bWasSuccessful)
{
	`log(self $ "::" $ GetFuncName() @ "- Attempting to exit.", true, 'XCom_Online');

	`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate(OnSaveCompleteCancel);
	//We no longer exit from this screen, but instead exit from the loadout list screen.
	//SetTimer(1, false, 'OnSaveIndicatorCompleteCancel'); // Give a second for the save indicator to finish before exiting
}

function OnSaveIndicatorCompleteCancel()
{
	m_iBeforeExitBitfield = m_iBeforeExitBitfield | (1 << eBeforeExit_SavedSettings);
	AttemptExitLoadoutScreen();
}

function OnSaveCompleteLaunchGame(bool bWasSuccessful)
{

	//TODO: is there a possibility of the save failing and getting to this point? 
	// This may be possible to sense once the save is converted to player profiles. 
	// - bsteiner 
	//IF( SAVE FAILED )
	//{
	//  m_kGRI.m_bGameStarting = false;
	//  m_kGRI.b_GameStartAborted = true;
	//  show an aborted message 
	//}
	
	//`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate(OnSaveCompleteLaunchGame);
	//if(WorldInfo.Game != none)
	//{
	//	X2MPLobbyGame(WorldInfo.Game).LaunchGame();
	//}

	// @TODO tsmith: do the new way
}

function ShowStartingGamePopup()
{
	// TODO: @UI: show the real popup -tsmith 
	//m_kPopupMessager.Message("Starting game...", , , -1.0f);
	`log("Starting game...",,'uixcom');
	m_kGRI.m_bGameStarting = true; 
	//m_kLocalPlayerInfo.SetOverlayMessage( m_strMPLoadout_Loading );

	//// Clear all button help, game is starting
	//AS_SetBackButtonHelp();
	//AS_SetReadyButtonHelp();
	//m_kLocalPlayerInfo.SetNotReadyButtonHelp();
	//m_kLocalPlayerInfo.SetStartButtonHelp();
}

function ShowAbortedPopup()
{
	// TODO: @UI: show the real popup -tsmith 
	//m_kPopupMessager.Message("Starting game...", , , -1.0f);
	`log("Save aborted!",,);
	//m_kLocalPlayerInfo.SetOverlayMessage( m_strMPLoadout_AllPlayersReady );
}

function UpdateLocalPlayerFromSettings()
{
	//m_kLocalPlayerInfo.InitializeDataFromSave(`XPROFILESETTINGS, true);
	SendPlayerUpdate();
}

function SaveLocalPlayerProfileSettings()
{
	m_bSavingProfileSettings = true;
	UpdateSquadLoadoutSettings(m_kProfileSettings.GetCurrentLoadoutId());
	`ONLINEEVENTMGR.AddSaveProfileSettingsCompleteDelegate(OnSaveLocalPlayerProfileSettingsComplete);
	`ONLINEEVENTMGR.SaveProfileSettings(true /* bForceShowSaveIndicator */);
	`ONLINEEVENTMGR.DebugSaveProfileSettingsCompleteDelegate();
}

function OnSaveLocalPlayerProfileSettingsComplete(bool bWasSuccessful)
{
	`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate(OnSaveLocalPlayerProfileSettingsComplete);

	//m_kLocalPlayerInfo.ProfileSaved(); // Should change m_bProfileChangesMade, due to the watch on the m_kLocalPlayerInfo's m_bDataChanged variable

	RefreshData();

	m_bSavingProfileSettings = false;
}

function UpdateSquadLoadoutSettings(int iLoadoutId)
{
	//local XComOnlineProfileSettings ProfileSettings;

	//ScriptTrace();
	//`log(`location @ `ShowVar(iLoadoutId));
	//ProfileSettings = `XPROFILESETTINGS;

	//ProfileSettings.SetLoadoutGameStateFromId(m_kLocalPlayerInfo.GetLoadoutGameState(), iLoadoutId);
	//ProfileSettings.MPWriteLoadoutGameStates_Default(); // Update the underlying raw data to reflect the changes made to the profile settings.

	//if( m_strNewNameRequested != "" )
	//{
	//	ProfileSettings.SetLoadoutName( `XPROFILESETTINGS.GetCurrentLoadoutId(), m_strNewNameRequested );
	//	// Reset the requested name; thus only updating for the rename on this screen instead of the creation from the UIMultiplayerLoadoutList -ttalley
	//	// XCOM_EW: BUG 3946: [MP] Squad loadout name is copied when renaming or creating a loadout in the Edit loadouts menu.
	//	m_strNewNameRequested = "";
	//}
}

function RefreshData()
{
	//m_kLocalPlayerInfo.RefreshData();
	//m_kRemotePlayerInfo.RefreshData();
	//m_kGameInfo.RefreshData();	
	//RefreshDisplay();
}

simulated function RefreshDisplay()
{
	//RefreshLoadoutManagementButtons(true);

	//if( m_bReadyButtonEnabled )
	//{
	//	// Enable the Ready Button
	//	EnableDisableReadyButton(true);

	//	if( m_bPlayersWereReady && !(m_kGRI.m_bAllPlayersReady) )
	//	{
	//		m_kLocalPRI.SetPlayerReady(false);
	//		m_bPlayersWereReady = false;
	//	}

	//	if( m_kGRI.m_bGameStarting )
	//	{
	//		//EnableDisableReadyButton(false);
	//		m_kLocalPlayerInfo.SetLocked( true );
	//		m_kLocalPlayerInfo.SetOverlayMessage( m_strMPLoadout_Loading );

	//		// Clear all button help, game is starting
	//		AS_SetBackButtonHelp();
	//		AS_SetReadyButtonHelp();
	//		RefreshLoadoutManagementButtons(false);
	//		m_kLocalPlayerInfo.SetNotReadyButtonHelp();
	//		m_kLocalPlayerInfo.SetStartButtonHelp();
	//	}
	//	else if( m_kGRI.m_bAllPlayersReady ) 
	//	{
	//		m_kLocalPlayerInfo.SetLocked( true );
	//		m_bPlayersWereReady = true;
			
	//		// Set Overlay text
	//		if( bCanStartMatch )
	//		{
	//			m_kLocalPlayerInfo.SetOverlayMessage( m_strMPLoadout_AllPlayersReady);

	//			if(Movie.IsMouseActive())
	//			{
	//				m_kLocalPlayerInfo.SetStartButtonHelp(m_strMPLoadout_Mouse_Start, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_START);
	//			}
	//			else
	//			{
	//				// Sony TRC R048
	//				if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
	//					m_kLocalPlayerInfo.SetStartButtonHelp( m_strMPLoadout_PressStart, "");
	//				else
	//					m_kLocalPlayerInfo.SetStartButtonHelp( m_strMPLoadout_PressStart, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_START);
	//			}
	//		}
	//		else	
	//			m_kLocalPlayerInfo.SetOverlayMessage( m_strMPLoadout_ReadyOverlayMessage );

	//		AS_SetBackButtonHelp();
	//		AS_SetReadyButtonHelp();
	//		m_kLocalPlayerInfo.SetNotReadyButtonHelp(m_strMPLoadout_CancelReady, class'UIUtilities_Input'.static.GetBackButtonIcon());
	//		RefreshLoadoutManagementButtons(false);
	//	}
	//	else if( m_kLocalPRI.m_bPlayerReady ) 
	//	{
	//		// Set Overlay text
	//		m_kLocalPlayerInfo.SetLocked( true );
	//		m_kLocalPlayerInfo.SetOverlayMessage( m_strMPLoadout_ReadyOverlayMessage );

	//		AS_SetBackButtonHelp();
	//		AS_SetReadyButtonHelp();
	//		m_kLocalPlayerInfo.SetNotReadyButtonHelp(m_strMPLoadout_CancelReady, class'UIUtilities_Input'.static.GetBackButtonIcon());
	//		RefreshLoadoutManagementButtons(false);

	//		m_kLocalPlayerInfo.RefreshData();
	//		m_kRemotePlayerInfo.RefreshData();
	//		m_kGameInfo.RefreshData();

	//		PlaySound( SoundCue'SoundMultiplayer.PlayerReadyCue', true );
	//	}
	//	else 
	//	{
	//		// Set Overlay text
	//		m_kLocalPlayerInfo.SetLocked( false );
	//		m_kLocalPlayerInfo.SetOverlayMessage("");

	//		m_kLocalPlayerInfo.SetNotReadyButtonHelp();
	//		m_kLocalPlayerInfo.SetStartButtonHelp();

	//		AS_SetBackButtonHelp(m_strMPLoadout_Back, class'UIUtilities_Input'.static.GetBackButtonIcon());
			
	//		// PS3 TRC R048 start menu stuff
	//		if(WorldInfo.IsConsoleBuild(CONSOLE_PS3))
	//		{
	//			AS_SetReadyButtonHelp(m_strMPLoadout_PressSTARTWhenReady, "");
	//		}
	//		else			
	//		{
	//			AS_SetReadyButtonHelp(m_strMPLoadout_Ready, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_START);
	//		}
	//		RefreshLoadoutManagementButtons(true);
	//	}
	//}
	//else
	//{
	//	AS_SetBackButtonHelp(m_strMPLoadout_Back, class'UIUtilities_Input'.static.GetBackButtonIcon());
				
	//	// PS3 TRC R048 start menu stuff
	//	if(WorldInfo.IsConsoleBuild(CONSOLE_PS3))
	//	{
	//		AS_SetReadyButtonHelp(m_strMPLoadout_PressSTARTWhenReady, "");
	//	}
	//	else			
	//	{
	//		AS_SetReadyButtonHelp(m_strMPLoadout_Ready, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_START);
	//	}
	//	RefreshLoadoutManagementButtons(true);

	//	// Disable the Ready Button
	//	EnableDisableReadyButton(false);
	//	m_kLocalPlayerInfo.SetNotReadyButtonHelp();		

	//}

}

public function RefreshMouseState()
{
	//RefreshDisplay();
}

public function RemotePlayerJoined(UniqueNetId kPlayerId)
{
	`log(self $ "::" $ GetFuncName() @ "PlayerId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(kPlayerId), true, 'XCom_Online');
	if(InviteFriendButton != none)
	{
		InviteFriendButton.Hide();
	}

	//m_kLocalPRI.SetPlayerReady(false);
	//PlaySound( SoundCue'SoundMultiplayer.PlayerReadyCue', true );
	//UpdateRemotePlayerWatch();

	//RefreshData();
	////Update after data is refreshed
	//UpdateInviteButtonHelp();

	// Reset a "network error" that caused another client to leave.
	PC.WorldInfo.Game.bHasNetworkError = false;

	UpdateButtons();
}

public function RemotePlayerLeft(UniqueNetId kPlayerId)
{
	local TDialogueBoxData kRemotePlayerLeftDialogBoxData;
	local XComGameState_Player RemotePlayer;

	RemotePlayer = m_kRemotePlayerInfo.GetPlayerGameState();
	RemotePlayer.bPlayerReady = false;

	`log(self $ "::" $ GetFuncName() @ "Player=" $ RemotePlayer.GetGameStatePlayerName() @ "PlayerId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(kPlayerId), true, 'XCom_Online');

	kRemotePlayerLeftDialogBoxData.strTitle = m_strPlayerLeftDialog_Title;
	kRemotePlayerLeftDialogBoxData.strText = RemotePlayer.GetGameStatePlayerName() @ m_strPlayerLeftDialog_Text;
	XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres.UIRaiseDialog(kRemotePlayerLeftDialogBoxData);

	//m_kRemotePlayerInfo.ResetRemotePRI();
	//m_kRemotePRI = none;
	////UpdateRemotePlayerWatch();

	//m_kLocalPRI.SetPlayerReady(false);
	//PlaySound( SoundCue'SoundMultiplayer.PlayerReadyCue', true );

	//RefreshData();
	////Update after data is refreshed
	//UpdateInviteButtonHelp();

	if(InviteFriendButton != none)
	{
		InviteFriendButton.Show();
	}

	UpdateButtons();
}

function OnConnectionClosed(int ConnectionIdx)
{
	bOpponentJoined = false;
	UpdateButtons();
}

public function bool UsePartyInvite()
{
	local XComOnlineEventMgr EventMgr;
	local OnlinePartyChatInterface PartyChat;

	EventMgr = `ONLINEEVENTMGR;
	PartyChat = EventMgr.OnlineSub.PartyChatInterface;

	return PartyChat != none && PartyChat.IsInPartyChat(EventMgr.LocalUserIndex) && PartyChat.GetPartyMemberCount() > 1;
}

//------------------------------------------------------------------------------
function OpenRenameInterface()
{
	local TInputDialogData kData;
	local string strOldName, inputName;
	local int MAX_CHARS;

	MAX_CHARS = 50;

	strOldName = `XPROFILESETTINGS.GetCurrentLoadoutName();
	if( m_strNewNameRequested == "" )
		inputName = strOldName;
	else
		inputName = m_strNewNameRequested;

	//if(!WorldInfo.IsConsoleBuild() || `ISCONTROLLERACTIVE )
	//{
		// on PC, we have a real keyboard, so use that instead
		kData.fnCallbackAccepted = PCTextField_OnAccept_Rename;
		kData.fnCallbackCancelled = PCTextField_OnCancel_Rename;
		kData.strTitle = m_strEnterNameHeader;
		kData.iMaxChars = MAX_CHARS;
		kData.strInputBoxText = inputName;
		XComPresentationLayerBase(Owner).UIInputDialog(kData);
/*	}
	else
	{
		//`log("+++ Loading the VirtualKeyboard", ,'uixcom');
		Movie.Pres.UIKeyboard( m_strEnterNameHeader, 
										 inputName, 
										 VirtualKeyboard_OnAccept_Rename, 
										 VirtualKeyboard_OnCancel_Rename,
										 false, // Do not need to validate these names -ttalley
										 MAX_CHARS);
	}*/
}

reliable client function PCTextField_OnAccept_Rename( string userInput )
{
	VirtualKeyboard_OnAccept_Rename(userInput, true);
}
reliable client function PCTextField_OnCancel_Rename( string userInput )
{
	VirtualKeyboard_OnCancel_Rename();
}

reliable client function VirtualKeyboard_OnAccept_Rename( string userInput, bool bWasSuccessful )
{
	Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);

	if( userInput == "" ) bWasSuccessful = false; 

	if(!bWasSuccessful)
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true ); 
		VirtualKeyboard_OnCancel_Rename();
		return;
	}

	//`log(`location @ "Back in editor: " $userInput,,'uixcom');
	Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);

	class'UIUtilities_Text'.static.StripUnsupportedCharactersFromUserInput(userInput);
	FinishRenameSlot(userInput);
}

function VirtualKeyboard_OnCancel_Rename()
{
	//`log(`location @ "Back in editor.",,'uixcom');
	Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);
}

function FinishRenameSlot(string strNewLoadoutName)
{
	m_strNewNameRequested = strNewLoadoutName;
	// @TODO tsmith: save the profile data
	//m_kLocalPlayerInfo.SquadLevelDirtyRequest();
	//m_kLocalPlayerInfo.RefreshDisplay();
	//Do not automatically force a save! 
}

//-------------------------------

/**
 * Called when the local player is about to travel to a new map or IP address.  Provides subclass with an opportunity
 * to perform cleanup or other tasks prior to the travel.
 */
function PreClientTravel( string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel )
{
	CleanUpPartyChatWatch();
}

function OnGameInviteAccepted(bool bWasSuccessful)
{
	local XComPresentationLayerBase Presentation;
	local TProgressDialogData kDialogData;

	`log(`location @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	if(bWasSuccessful)
	{
		Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
		kDialogData.strTitle = `ONLINEEVENTMGR.m_sAcceptingGameInvitation;
		kDialogData.strDescription = `ONLINEEVENTMGR.m_sAcceptingGameInvitationBody;
		Presentation.UIProgressDialog(kDialogData);
	}
}

function OnGameInviteComplete(ESystemMessageType MessageType, bool bWasSuccessful)
{
	local XComPresentationLayerBase Presentation;

	if (!bWasSuccessful)
	{
		// Only close the progress dialog if there was a failure.
		Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
		Presentation.UICloseProgressDialog();
		`ONLINEEVENTMGR.QueueSystemMessage(MessageType);
	}
}

function OnConnectionProblem()
{
	// @TODO tsmith: implement without the GRI/PRI?

	////local XComGameInfo kGameInfo;
	//local XComPlayerController kRemoteController;

	//`log(`location,,'XCom_Online');
	//if(m_kGRI.m_bGameStarting)
	//{
	//	`log(`location @ "Game is starting, ignoring the connection problem as it is most likely caused by loading into the map.",,'XCom_Online');
	//	return;
	//}

	//if ((WorldInfo.NetMode != NM_Client) && (Role == ROLE_Authority))
	//{
	//	if (m_kRemotePRI != None && m_kRemotePRI.m_bPlayerLoaded)
	//	{
	//		`log(`location @ "Client 'left the lobby', kick the PC to free up space.",,'XCom_Online');
	//		//// Have the server kick the player
	//		//kGameInfo = `XCOMGAME;
		
	//		ForEach AllActors(class'XComPlayerController', kRemoteController)
	//		{
	//			`log(`location @ "Testing PC: " @ kRemoteController,,'XCom_Online');
	//			if (kRemoteController != PC)
	//			{
	//				`log(`location @ "Found Remote Controller!",,'XCom_Online');
	//				break;
	//			}
	//		}
	//		//kRemoteController = XComPlayerController(m_kRemotePlayerInfo.Owner);
	//		//`log(`location @ "Controller could be: " @ XComPlayerController(m_kRemotePlayerInfo.Owner),,'XCom_Online');
	//		if (kRemoteController != none)
	//		{
	//			`log(`location @ "Kicking the PC",,'XCom_Online');
	//			kRemoteController.Destroy();
	//		}
	//		//if (kGameInfo != none && kRemoteController != none)
	//		//{
	//		//	`log(`location @ "Logging out the PC",,'XCom_Online');
	//		//	kGameInfo.Logout(kRemoteController);
	//		//}
	//	}
	//	else
	//	{
	//		`log(`location @ "Ignoring disconnect while still loading.",,'XCom_Online');
	//	}
	//}
	//else
	//{
	//	if (m_kLocalPRI.m_bPlayerLoaded)
	//	{
	//		`log(`location @ "Host 'left the lobby', return to the MP Main Menu.",,'XCom_Online');
	//		// Connection to the host has been lost, return to MPMainMenu
	//		`ONLINEEVENTMGR.ReturnToMPMainMenu(QuitReason_OpponentDisconnected);
	//	}
	//	else
	//	{
	//		`log(`location @ "Ignoring disconnect while loading.",,'XCom_Online');
	//	}

	//}
}

function OnMutingChange()
{
	//m_kRemotePlayerInfo.RefreshDisplay();
}

function OnSaveCompleteToggleReady(bool bWasSuccessful)
{
	//`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate(OnSaveCompleteToggleReady);

	//m_kLocalPlayerInfo.ProfileSaved(); // Should change m_bProfileChangesMade, due to the watch on the m_kLocalPlayerInfo's m_bDataChanged variable

	//m_kLocalPRI.SetPlayerReady(true);

	//PlaySound( SoundCue'SoundMultiplayer.PlayerReadyCue', true );

	//RefreshData();

	//m_bSavingProfileSettings = false;
}

function ToggleReadyState(optional bool forceToggle = false)
{
//	if(m_bReadyButtonEnabled || forceToggle)
//	{
//		if ( (! m_kLocalPRI.m_bPlayerReady) && (m_bProfileChangesMade) )
//		{
//			m_bSavingProfileSettings = true;

//			UpdateSquadLoadoutSettings(m_kProfileSettings.GetDefaultLoadoutId());
//			UpdateSquadLoadoutSettings(m_kProfileSettings.GetCurrentLoadoutId());
//			`ONLINEEVENTMGR.AddSaveProfileSettingsCompleteDelegate(OnSaveCompleteToggleReady);
//			`ONLINEEVENTMGR.SaveProfileSettings(true /* bForceShowSaveIndicator */);
//			`ONLINEEVENTMGR.DebugSaveProfileSettingsCompleteDelegate();
//		}
//		else
//		{
//			m_kLocalPRI.SetPlayerReady( ! m_kLocalPRI.m_bPlayerReady );
			
//			PlaySound( SoundCue'SoundMultiplayer.PlayerReadyCue', true );

//			RefreshData();
//		}
//	}
//	else
//	{
//		if(m_kLocalPRI.m_iTotalSquadCost > m_kGRI.m_iMPMaxSquadCost && m_kGRI.m_iMPMaxSquadCost > 0)
//			Movie.Pres.ShowMultiplayerLoadoutWarningDialog(m_strMPLoadout_Error_SquadPoints);
//		else
//			Movie.Pres.ShowMultiplayerLoadoutWarningDialog(m_strMPLoadout_Error_InvalidSquad);
//	}
}

/** Tells this client that it should send voice data over the network */
function StartNetworkedVoice()
{
	local OnlineSubsystem OnlineSub;
	local XComOnlineEventMgr OnlineEventMgr;
	local XComOnlineProfileSettings ProfileSettings;

	OnlineEventMgr = `ONLINEEVENTMGR;
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	ProfileSettings = `XPROFILESETTINGS;

	if (OnlineSub != None && OnlineSub.VoiceInterface != None && !ProfileSettings.Data.m_bPushToTalk)
	{
		OnlineSub.VoiceInterface.StartNetworkedVoice(OnlineEventMgr.LocalUserIndex);
	}
}

/** Tells this client that it should not send voice data over the network */
function StopNetworkedVoice()
{
	local OnlineSubsystem OnlineSub;
	local XComOnlineEventMgr OnlineEventMgr;
	local XComOnlineProfileSettings ProfileSettings;

	OnlineEventMgr = `ONLINEEVENTMGR;
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	ProfileSettings = `XPROFILESETTINGS;

	if (OnlineSub != None && OnlineSub.VoiceInterface != None && !ProfileSettings.Data.m_bPushToTalk)
	{
		OnlineSub.VoiceInterface.StopNetworkedVoice(OnlineEventMgr.LocalUserIndex);
	}
}

//==============================================================================
//		CLEANUP:
//==============================================================================
simulated event OnCleanupWorld()
{
	Cleanup();

	super.OnCleanupWorld();
}

simulated event Destroyed() 
{
	UnsubscribeFromOnCleanupWorld();
	Cleanup();

	super.Destroyed();
}

function Cleanup()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local OnlineSubsystem OnlineSub; 
   
    OnlineSub = class'GameEngine'.static.GetOnlineSubsystem(); 
	CleanUpPartyChatWatch();
	Movie.Pres.ClearPreClientTravelDelegate(PreClientTravel);

	OnlineEventMgr = `ONLINEEVENTMGR;
	OnlineEventMgr.OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyedOnlineGame);
	OnlineEventMgr.ClearSaveProfileSettingsCompleteDelegate(OnSaveCompleteToggleReady);
	OnlineEventMgr.ClearSaveProfileSettingsCompleteDelegate(OnSaveCompleteLaunchGame);
	OnlineEventMgr.ClearSaveProfileSettingsCompleteDelegate(OnSaveCompleteCancel);
	OnlineEventMgr.ClearGameInviteAcceptedDelegate(OnGameInviteAccepted);
	OnlineEventMgr.ClearGameInviteCompleteDelegate(OnGameInviteComplete);
	OnlineEventMgr.ClearNotifyConnectionProblemDelegate(OnConnectionProblem);
	OnlineEventMgr.ClearSaveProfileSettingsCompleteDelegate(OnSaveLocalPlayerProfileSettingsComplete);
	class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.ClearMutingChangeDelegate(OnMutingChange);

	NetworkMgr.ClearPlayerJoinedDelegate(PlayerJoined);
	NetworkMgr.ClearPlayerLeftDelegate(PlayerLeft);
	NetworkMgr.ClearReceiveLoadTacticalMapDelegate(ReceiveLoadTacticalMap);
	NetworkMgr.ClearReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.ClearReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.ClearReceiveGameStateDelegate(ReceiveGameState);
	NetworkMgr.ClearReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	NetworkMgr.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
	NetworkMgr.ClearNotifyConnectionClosedDelegate(OnConnectionClosed);

	OnlineSub.VoiceInterface.ClearPlayerTalkingDelegate(PlayerTalking);

	super.Cleanup();
}

function CleanUpPartyChatWatch()
{

	//if(WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))
	//	WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iPartyChatStatusHandle);
}

simulated function OnRemoved()
{
	`log(`location,,'XCom_Online');
	super.OnRemoved();

	Movie.Pres.UIClearGrid();
	Cleanup();
}

simulated function OnCancel()
{
	if(!m_bSavingLoadout)
	{
		if(m_bLoadoutDirty)
		{
			m_bBackingOut = true;
			DisplaySaveSquadBeforeExitDialog();
		}
		else
		{
			DisplayConfirmExitDialog();			
		}
	}
}

//bsg-cballinger (7.10.2016): BEGIN, Overwrite functions in UIMPShell_SquadEditor, so they do not conflict with the user trying to back out of the lobby
function OnDisplaySaveSquadBeforeExitDialog(eUIAction eAction)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(eAction),, 'uixcom_mp');
	if(eAction == eUIAction_Accept)
	{
		m_kMPShellManager.AddSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_Exit);
		SaveLoadout();
	}
	else //clear squad saving/editing flags, so user can back out of lobby next time they press back
	{
		DirtiedUnit = none;
		m_bLoadoutDirty = false;
		m_bSavingLoadout = false;
	}
}


function SaveProfileSettingsComplete_Exit(bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_bSavingLoadout = false;
	m_kMPShellManager.ClearSaveProfileSettingsCompleteDelegate(SaveProfileSettingsComplete_Exit);
	if(bSuccess)
	{
		m_bLoadoutDirty = false;
		DirtiedUnit = none;
	}
	else
	{
		//ShowWriteProfileFailedDialog();
	}
}

//bsg-cballinger (7.10.2016): END
simulated function UpdateData(optional bool bFillSquad)
{
	super.UpdateData(bFillSquad);
	
	UpdateButtons();
}

//==============================================================================
// NETWORK 
//==============================================================================

function SendRemoteCommand(string Command)
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	NetworkMgr.SendRemoteCommand(Command, Parms);
	`log(`location @ "Sent Remote Command '"$Command$"'",,'XCom_Online');
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	`log(`location @ `ShowVar(Command),,'XCom_Online');
	if (Command ~= "ClientJoined")
	{
		if (GetStateName() == 'WaitingForOpponent')
		{
			PushState('EditingUnits');
		}
	}
	else if (Command ~= "NotifyLoadingMap")
	{
		PushState('Client_LoadingMap');
	}
	else if (Command ~= "RequestHistory")
	{
		SendHistory();
	}
}
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			StartButtonCallback(none);
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			ReadyButtonCallback(none);
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_SELECT:
			if (CanInvite())
			{
				InviteFriendButtonCallback();
				return true;
			}

		case class'UIUtilities_Input'.const.FXS_BUTTON_R3:
			//Disabling Rename functionality while in lobby - JTA 2016/6/17
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:
			ViewOpponentProfile();
			return true;
		default:
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

// Game Host
state WaitingForOpponent
{
	function EndState(Name NextStateName)
	{
		`log(`location @ "Leaving 'WaitingForOpponent' state!",,'XCom_Online');
	}

	function SetGameSettingsAsReady()
	{
		local XComOnlineGameSettings GameSettings;
		local OnlineGameInterface GameInterface;;
		GameInterface = class'GameEngine'.static.GetOnlineSubsystem().GameInterface;
		GameSettings = XComOnlineGameSettings(GameInterface.GetGameSettings('Game'));
		GameSettings.SetServerReady(true);
		GameInterface.UpdateOnlineGame('Game', GameSettings, true);
	}

Begin:
	`log(`location @ "Starting 'WaitingForOpponent' state!",,'XCom_Online');
	
	SetupStartState();
	bHistoryLoaded = true;
	m_kLocalPlayerInfo.InitPlayer(eTeam_One, m_kSquadLoadout);
	m_kRemotePlayerInfo.InitPlayer(eTeam_Two);

	//DoneSettingUpOnlineData();
	if (NetworkMgr.HasConnections())
	{
		SendRemoteCommand("HostJoined");
	}
	SetGameSettingsAsReady(); // Allows this game to be searchable.
}

// Game Peer
state JoiningOpponent
{
	function OnRemoteCommand(string Command, array<byte> RawParams)
	{
		if (Command ~= "HostJoined")
		{
			SendRemoteCommand("RequestHistory");
		}
	}

	function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
	{
		`log(`location,,'XCom_Online');
		bWaitingForHistory = false;
		global.ReceiveHistory(InHistory, EventManager);
	}

	function EndState(Name NextStateName)
	{
		`log(`location @ "Leaving 'JoiningOpponent' state!",,'XCom_Online');
	}

Begin:
	`log(`location @ "Starting 'JoiningOpponent' state!",,'XCom_Online');

	// Requesting the full history from the "server" since the Object IDs need to align. Otherwise, the player references are out of whack and the lobby will appear to be empty. (See X2 BUG 1564)
	bWaitingForHistory = true;
	SendRemoteCommand("RequestHistory");
	while (bWaitingForHistory)
	{
		sleep(0.0);
	}
	m_kLocalPlayerInfo.InitPlayer(eTeam_Two, m_kSquadLoadout);
	m_kRemotePlayerInfo.InitPlayer(eTeam_One);
	SendRemoteCommand("ClientJoined");

	// @TODO tsmith: in the old UI, this lets the player pick a squad.
	//DoneSettingUpOnlineData();
	PushState('EditingUnits');
}

// Both
state EditingUnits
{
	public function RemotePlayerLeft(UniqueNetId kPlayerId)
	{
		global.RemotePlayerLeft(kPlayerId);
		PopState();
	}

Begin:
	`log(`location @ "Starting 'EditingUnits' state!",,'XCom_Online');
	SendPlayerUpdate();

	StartNetworkedVoice();
	UpdateButtons();
}

state Client_LoadingMap
{
	function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
	{
		`log(`location,,'XCom_Online');
		bWaitingForHistory = false;
		global.ReceiveHistory(InHistory, EventManager);
	}

	function ReceivePartialHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
	{
		`log(`location,,'XCom_Online');
		bWaitingForHistory = false;
		global.ReceivePartialHistory(InHistory, EventManager);
	}

	function SendHistoryConfirmed()
	{
		local array<byte> Parms;
		Parms.Length = 0; // Removes script warning.
		NetworkMgr.SendRemoteCommand("HistoryConfirmed", Parms);
		`log(`location @ "'Client_LoadingMap' - Player has received the full history ...",,'XCom_Online');
	}

	public function RemotePlayerLeft(UniqueNetId kPlayerId)
	{
		global.RemotePlayerLeft(kPlayerId);
		`ONLINEEVENTMGR.ReturnToMPMainMenu();
	}

Begin:
	UpdateButtons();
	ShowStartingGamePopup();

	bWaitingForHistory = true;

	// Send the loadout details to the host
	NetworkMgr.SendGameState(m_kLocalPlayerInfo.GetLoadoutGameState(), -1);
	while(bWaitingForHistory)
	{
		sleep(0.0);
	}
	SendHistoryConfirmed();

	// Let the network quiet down prior to loading the map.
	while (NetworkMgr.HasPendingData())
	{
		sleep(0.0);
	}

	LoadTacticalMap();
}

state Server_LoadingMap
{
	function ObliterateUnitsAndItems(XComGameState GameState)
	{
		local XComGameState_Unit Unit;
		local XComGameState_Item Item;
		local array<XComGameState_BaseObject> ObliterateObjs;
		local int i;

		ObliterateObjs.Length = 0;
		foreach GameState.IterateByClassType(class'XComGameState_Item', Item)
		{
			ObliterateObjs.AddItem(Item);
		}
		foreach GameState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			ObliterateObjs.AddItem(Unit);
		}
		for (i = 0; i < ObliterateObjs.Length; ++i)
		{
			GameState.PurgeGameStateForObjectID(ObliterateObjs[i].ObjectID);
		}
	}

	function CopyLoadoutGameState(XComGameState_Player PlayerGameState, XComGameState LoadoutGameState, XComGameState NewGameState)
	{
		local XComGameState_Unit Unit;
		local XComGameState_Unit NewUnit;
		
		foreach LoadoutGameState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			NewUnit = class'X2MPShellManager'.static.CreateUnitLoadoutGameState(Unit, NewGameState, LoadoutGameState);
			if(NewUnit != none && PlayerGameState != None)
			{
				NewUnit.SetControllingPlayer(PlayerGameState.GetReference());
			}
		}
	}

	function ClearLoadoutsFromStartState()
	{
		local XComGameState StartState;
		StartState = History.GetStartState();

		// Clear out all Units / Items from the start state
		ObliterateUnitsAndItems(StartState);
	}

	function AddPlayersToStartState()
	{
		//local XComGameState StartState;
		//StartState = History.GetStartState();

		// TODO: Add Copy Mech.
	}

	function AddLoadoutsToStartState()
	{
		local XComGameState StartState;
		StartState = History.GetStartState();

		// Add all Units / Items for each Player
		CopyLoadoutGameState(m_kLocalPlayerInfo.GetPlayerGameState(), m_kLocalPlayerInfo.GetLoadoutGameState(), StartState);
		CopyLoadoutGameState(m_kRemotePlayerInfo.GetPlayerGameState(), m_kRemotePlayerInfo.GetLoadoutGameState(), StartState);
	}

	function NotifyLoadingMap()
	{
		local array<byte> Parms;
		Parms.Length = 0; // Removes script warning.
		NetworkMgr.SendRemoteCommand("NotifyLoadingMap", Parms);
		`log(`location @ "'LoadingMap' - Notifying the Peer that the Map is Loading ...",,'XCom_Online');
	}

	function OnRemoteCommand(string Command, array<byte> RawParams)
	{
		if (Command ~= "HistoryConfirmed")
		{
			bWaitingForHistoryComplete = false;
		}
		else
		{
			global.OnRemoteCommand(Command, RawParams);
		}
	}

	public function RemotePlayerLeft(UniqueNetId kPlayerId)
	{
		global.RemotePlayerLeft(kPlayerId);
		GotoState('WaitingForOpponent');
	}

Begin:
	UpdateButtons();
	`log(`location @ "Starting 'LoadingMap' state!",,'XCom_Online');

	`log(`location @ "Waiting for Player to send the Loadout ...",,'XCom_Online');
	bWaitingForPlayerLoadout = true;
	NotifyLoadingMap();
	while (bWaitingForPlayerLoadout && m_kRemotePlayerInfo.GetLoadoutGameState() == none)
	{
		sleep(0.0);
	}
	`log(`location @ "... Player Loadout Saved.",,'XCom_Online');

	ClearLoadoutsFromStartState();
	AddLoadoutsToStartState();

	`log(`location @ "Waiting for Peer to Update to their Full History ...",,'XCom_Online');
	bWaitingForHistoryComplete = true;
	NetworkMgr.SendPartialHistory(`XCOMHISTORY, `XEVENTMGR);
	while (bWaitingForHistoryComplete)
	{
		sleep(0.0);
	}

	// Let the network quiet down prior to loading the map.
	while (NetworkMgr.HasPendingData())
	{
		sleep(0.0);
	}
	`log(`location @ "... Full History Updated.",,'XCom_Online');
	LoadTacticalMap();
}

function bool CanInvite()
{
	if(	m_kMPShellManager.OnlineGame_GetNetworkType() != eMPNetworkType_LAN && !m_kMPShellManager.OnlineGame_GetIsRanked())
	{
		return true;
	}
	return false;
}
defaultproperties
{
	bOpponentJoined=false;
	bAlwaysTick = true;
	m_bAllowEditing= false;
	bHideOnLoseFocus = true;
	bProcessMouseEventsIfNotFocused=true
}