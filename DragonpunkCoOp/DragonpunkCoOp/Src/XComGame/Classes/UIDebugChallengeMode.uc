//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDebugChallengeMode
//  AUTHOR:  Timothy Talley
//
//  PURPOSE: This screen provides the functionality for selecting squad details for the
//	         only attempt at the interval challenge. WIP: Possibly display past stats,
//           current number of attempts, and Interval Details i.e. Time Limit or Rewards.
//
//		Retrieve interval information
//		Choose squad loadout w/ commander unit
//		Generate map
//		Generate spawn points (random or same?)
//		Start Challenge
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDebugChallengeMode extends UIScreen
	dependson(X2ChallengeModeDataStructures)
	dependson(XComGameState_BattleData)
	dependson(UIProgressDialogue)
	dependson(UIInputDialogue);


//--------------------------------------------------------------------------------------- 
// Challenge Data
//
var privatewrite PlayerSeedInfo	        m_DownloadedInfo;
var privatewrite PlayerSeedInfo	        m_SelectedInfo;
var privatewrite array<PlayerSeedInfo>  m_LeaderboardData;
var privatewrite bool                   m_bUpdatingLeaderboardData;
var protected array<OnlineSaveGame>     m_arrSaveGames;
var privatewrite array<IntervalInfo>    m_arrIntervals;
var qword                               m_CurrentIntervalSeedID;


//--------------------------------------------------------------------------------------- 
// UI Layout Data
//
var UIPanel							    m_kAllContainer;
var UIX2PanelHeader						m_TitleHeader;
var UIX2PanelHeader						m_DebugHeader;
var localized string					m_strChallengeModeDebugTitle;
var localized string					m_strChallengeModeTitle;
var localized string					m_strLoadingDataTitle;
var localized string					m_strLoadingDataDescription;

var UIButton							m_CloseButton;			// Closes this menu
var UIButton							m_StartButton;			// Starts the Challenge
var UIButton							m_ReplaySelectedButton; // Replays the selected leaderboard challenge entry
var UIList								m_Leaderboard;          // Challenge Leaderboard information

// Utility Debug Controls
var UIButton							m_RefreshLeadersButton;	// Retrieves the latest leaderboard scores
var UIButton							m_GetSeedButton;		// Retrieves the seed for the Challenge
var UIButton							m_ResetButton;			// Resets the Challenge
var UIButton							m_SubmitButton;         // Submits the current History to the seed
var UIButton							m_PlayerIDButton;	    // PlayerID
var UIButton							m_IntervalSeedButton;	// Interval Seed
var UIButton							m_RandomSeedButton;		// Random # Seed
var UIButton							m_TimeLimitButton;		// Time Limit
var UIButton							m_TimeStartButton;		// Time Start
var UIButton							m_LoadSaveButton;       // Loads a save file into the current History for the "submit" process.
var UIButton							m_StartReplayButton;    // Starts the level with the current History information.
var UIDropdown							m_LoadSaveDropdown;	    // Pulldown list for loading saved games
var UIText								m_InformationText;      // Notifies the user of the current action being performed

// Event Data Utility Debug Controls
var UIButton							m_GetEventDataButton;   // Downloads the current event data, this should be automatic to the load process
var UIButton							m_SubmitEventDataButton;// Sends the current event data to the server
var UIButton							m_ResetEventDataButton; // Clears out any "Seen" Events and all Map data, must get the data again from the server to continue
var UIButton							m_ViewEventDataButton;  // Opens the Challenge Data Window showing all turns
var UISlider							m_TurnSlider;           // Changes the Turn in which the event would be triggered
var UIButton							m_TriggerEventButton;	// Simulates completing the selected Event Type from the dropdown.
var UIDropdown							m_EventTypeDropdown;	// Pulldown list for triggering a particular Event Type
var UIButton							m_GetIntervalsButton;   // Gets a list of all of the Intervals
var UIDropdown							m_IntervalDropdown;	    // List of all returned Intervals



// List of available rewards ??
var array<UICheckbox>					m_BoostBoxes;			// Checkbox Group of available "boosts" to use (or is this automatic?)
var UIDropdown							m_SquadChoiceDropdown;	// Pulldown list for Squad Choices
// Customize loadout for Commander
// Challenge Mode Leaderboard (Daily +7 / Top Ten (Average) / Fast Times?) per board (Friends / Local / Overall)

var UIButton			                m_ClickedButton;

//--------------------------------------------------------------------------------------- 
// X2 Battle Data
//
var name  								m_MissionRewardType;
var XComGameState						m_NewStartState;
var XComGameState_BattleData			m_BattleData;


//--------------------------------------------------------------------------------------- 
// Cache References
//
var private XComGameStateHistory		History;
var private OnlineSubsystem				OnlineSub;
var private XComOnlineEventMgr			OnlineEventMgr;
var private X2ChallengeModeInterface    ChallengeModeInterface;
var private X2TacticalChallengeModeManager    ChallengeModeManager;


//--------------------------------------------------------------------------------------- 
// Delegates
//
delegate TextInputClosedCallback(string newText);

//==============================================================================
//		INITIALIZATION:
//==============================================================================
simulated function InitScreen( XComPlayerController InitController, UIMovie InitMovie, optional name InitName )
{
	local int StartX, OffsetX, StartY, OffsetY, ButtonCountX, ButtonCountY, Index;
	StartX = 700; OffsetX = 200; StartY = 175; OffsetY = 50; ButtonCountX = 0; ButtonCountY = 0;
	History = `XCOMHISTORY;
	OnlineSub = Class'GameEngine'.static.GetOnlineSubsystem();
	OnlineEventMgr = `ONLINEEVENTMGR;
	ChallengeModeInterface = `CHALLENGEMODE_INTERFACE;
	SubscribeToOnCleanupWorld();

	SetupDefaultInterval();

	super.InitScreen(InitController, InitMovie, InitName);

	m_kAllContainer = Spawn(class'UIPanel', self);

	m_kAllContainer.InitPanel('allContainer');
	m_kAllContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kAllContainer.SetPosition(30, 110).SetSize(600, 800);

	// Create Title text
	Spawn(class'UIBGBox', m_kAllContainer).InitBG('', 0, 0, m_kAllContainer.width, m_kAllContainer.height);
	m_TitleHeader = Spawn(class'UIX2PanelHeader', m_kAllContainer);
	m_TitleHeader.InitPanelHeader('', m_strChallengeModeTitle, "");
	m_TitleHeader.SetHeaderWidth(m_kAllContainer.width - 20);
	m_TitleHeader.SetPosition(10, 10);

	// Create Debug text
	Spawn(class'UIBGBox', m_kAllContainer).InitBG('', StartX - 50, 0, m_kAllContainer.width, m_kAllContainer.height);
	m_DebugHeader = Spawn(class'UIX2PanelHeader', m_kAllContainer);
	m_DebugHeader.InitPanelHeader('', m_strChallengeModeDebugTitle, "");
	m_DebugHeader.SetHeaderWidth(m_kAllContainer.width - 20);
	m_DebugHeader.SetPosition(StartX - 40, 10);

	//
	// Debug Buttons
	//
	m_PlayerIDButton = Spawn(class'UIButton', m_kAllContainer);
	m_IntervalSeedButton = Spawn(class'UIButton', m_kAllContainer);
	m_RandomSeedButton = Spawn(class'UIButton', m_kAllContainer);
	m_TimeLimitButton = Spawn(class'UIButton', m_kAllContainer);
	m_TimeStartButton = Spawn(class'UIButton', m_kAllContainer);
	m_ResetButton = Spawn(class'UIButton', m_kAllContainer);
	m_SubmitButton = Spawn(class'UIButton', m_kAllContainer);
	m_GetSeedButton = Spawn(class'UIButton', m_kAllContainer);
	m_Leaderboard = Spawn(class'UIList', m_kAllContainer);
	m_RefreshLeadersButton = Spawn(class'UIButton', m_kAllContainer);
	m_LoadSaveButton = Spawn(class'UIButton', m_kAllContainer);
	m_StartReplayButton = Spawn(class'UIButton', m_kAllContainer);
	m_LoadSaveDropdown = Spawn(class'UIDropdown', m_kAllContainer);
	m_InformationText = Spawn(class'UIText', m_kAllContainer);
	m_GetEventDataButton = Spawn(class'UIButton', m_kAllContainer);
	m_SubmitEventDataButton = Spawn(class'UIButton', m_kAllContainer);
	m_ResetEventDataButton = Spawn(class'UIButton', m_kAllContainer);
	m_ViewEventDataButton = Spawn(class'UIButton', m_kAllContainer);
	m_TurnSlider = Spawn(class'UISlider', m_kAllContainer);
	m_TriggerEventButton = Spawn(class'UIButton', m_kAllContainer);
	m_EventTypeDropdown = Spawn(class'UIDropdown', m_kAllContainer);
	m_GetIntervalsButton = Spawn(class'UIButton', m_kAllContainer);
	m_IntervalDropdown = Spawn(class'UIDropdown', m_kAllContainer);
	

	//
	// Player Seed Column
	//
	m_PlayerIDButton.InitButton('playerIDButton', "PlayerID", OnEditStringButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_PlayerIDButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_PlayerIDButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_IntervalSeedButton.InitButton('intervalSeedButton', "Interval Seed", OnEditIntButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_IntervalSeedButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_IntervalSeedButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_RandomSeedButton.InitButton('randomSeedButton', "Random Seed", OnEditIntButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_RandomSeedButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_RandomSeedButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_TimeLimitButton.InitButton('timeLimitButton', "Time Limit", OnEditIntButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_TimeLimitButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_TimeLimitButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_TimeStartButton.InitButton('timeStartButton', "Time Start (Epoch)", OnEditQWordButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_TimeStartButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_TimeStartButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	//
	// Challenge Utility Column
	//
	ButtonCountY++;
	m_RefreshLeadersButton.InitButton('getLeadersButton', "Refresh Leaderboard", OnGetLeadersButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_RefreshLeadersButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_RefreshLeadersButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));
	
	m_GetSeedButton.InitButton('getSeedButton', "Get Challenge Seed", OnGetSeedButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_GetSeedButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_GetSeedButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));
	
	m_ResetButton.InitButton('resetButton', "Reset Challenge", OnResetButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_ResetButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_ResetButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));
	
	m_SubmitButton.InitButton('submitButton', "Submit Challenge", OnSubmitButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_SubmitButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_SubmitButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));
	
	m_LoadSaveButton.InitButton('loadSaveButton', "Load Replay Save", OnLoadSaveButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_LoadSaveButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_LoadSaveButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_StartReplayButton.InitButton('startReplayButton', "Start Replay", OnStartTacticalMapPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_StartReplayButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_StartReplayButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	ButtonCountY++;
	m_LoadSaveDropdown.InitDropdown('loadSaveDropdown', "Save Games", LoadSaveDropdownSelectionChange);		
	m_LoadSaveDropdown.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_LoadSaveDropdown.SetPosition(StartX + (OffsetX * ButtonCountX) + 25, StartY + (OffsetY * ButtonCountY++));

	m_InformationText.InitText('infoText', "");
	m_InformationText.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_InformationText.SetPosition(StartX + (OffsetX * ButtonCountX) + 25, StartY + (OffsetY * ButtonCountY++));

	//
	// Event Data Column
	//
	ButtonCountY = 0; // Reset to the top
	++ButtonCountX; // Next column over
	m_GetIntervalsButton.InitButton('getIntervalsButton', "Get Intervals", OnGetIntervalsButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_GetIntervalsButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_GetIntervalsButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_GetEventDataButton.InitButton('getEventButton', "Get Event Data", OnGetEventDataButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_GetEventDataButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_GetEventDataButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_SubmitEventDataButton.InitButton('submitEventButton', "Submit Event Data", OnSubmitEventDataButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_SubmitEventDataButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_SubmitEventDataButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_ResetEventDataButton.InitButton('resetEventButton', "Local Data Reset", OnResetEventDataButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_ResetEventDataButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_ResetEventDataButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_ViewEventDataButton.InitButton('viewEventButton', "View Event Data", OnViewEventDataButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_ViewEventDataButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_ViewEventDataButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_TriggerEventButton.InitButton('triggerEventButton', "Trigger Event", OnTriggerEventButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_TriggerEventButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_TriggerEventButton.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	m_TurnSlider.InitSlider('turnSlider', "Event Turn", 0.0);
	m_TurnSlider.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_TurnSlider.SetPosition(StartX + (OffsetX * ButtonCountX), StartY + (OffsetY * ButtonCountY++));

	++ButtonCountY;
	m_EventTypeDropdown.InitDropdown('eventTypeDropdown', "Event Types", EventTypeDropdownSelectionChange);		
	m_EventTypeDropdown.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_EventTypeDropdown.SetPosition(StartX + (OffsetX * ButtonCountX) + 25, StartY + (OffsetY * ButtonCountY++));
	m_EventTypeDropdown.Clear(); // empty dropdown
	for( Index = 0; Index < ECME_MAX; ++Index )
	{
		m_EventTypeDropdown.AddItem(string(GetEnum(enum'EChallengeModeEventType', EChallengeModeEventType(Index))), string(Index));
	}
	m_EventTypeDropdown.SetSelected( 0 );

	++ButtonCountY;
	m_IntervalDropdown.InitDropdown('intervalDropdown', "Intervals", IntervalDropdownSelectionChange);		
	m_IntervalDropdown.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_IntervalDropdown.SetPosition(StartX + (OffsetX * ButtonCountX) + 25, StartY + (OffsetY * ButtonCountY++));
	UpdateIntervalDropdown();



	//
	// Non-debug functionality
	//
	m_CloseButton = Spawn(class'UIButton', m_kAllContainer);
	m_StartButton = Spawn(class'UIButton', m_kAllContainer);
	m_ReplaySelectedButton = Spawn(class'UIButton', m_kAllContainer);

	m_Leaderboard.InitList('', 10, 50, m_kAllContainer.width - 30, m_kAllContainer.height - 150);
	m_Leaderboard.OnItemDoubleClicked = OnLeaderboardDoubleClick;

	m_StartButton.InitButton('startButton', "", OnStartButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_StartButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_StartButton.SetPosition(50, 850);
	
	m_ReplaySelectedButton.InitButton('replaySelectedButton', "Replay Selected", OnReplaySelectedButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_ReplaySelectedButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_ReplaySelectedButton.SetPosition(250, 850);
	
	m_CloseButton.InitButton('closeButton', "Back to Main Menu", OnCloseButtonPress, eUIButtonStyle_HOTLINK_BUTTON);		
	m_CloseButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_CloseButton.SetPosition(450, 850);


	//
	// Setup Handlers
	//
	if( OnlineEventMgr != none )
	{
		OnlineEventMgr.AddUpdateSaveListStartedDelegate(OnReadSaveGameListStarted);
		OnlineEventMgr.AddUpdateSaveListCompleteDelegate(OnReadSaveGameListComplete);
		OnlineEventMgr.UpdateSaveGameList();
	}
	ChallengeModeManager = Spawn(class'X2TacticalChallengeModeManager', self);
	ChallengeModeManager.Init();

	ChallengeModeInterface.AddReceivedChallengeModeIntervalsDelegate(OnReceivedChallengeModeIntervals);
	ChallengeModeInterface.AddReceivedChallengeModeSeedDelegate(OnReceivedChallengeModeSeed);
	ChallengeModeInterface.AddReceivedChallengeModeLeaderboardStartDelegate(OnReceivedChallengeModeLeaderboardStart);
	ChallengeModeInterface.AddReceivedChallengeModeLeaderboardEndDelegate(OnReceivedChallengeModeLeaderboardEnd);
	ChallengeModeInterface.AddReceivedChallengeModeLeaderboardEntryDelegate(OnReceivedChallengeModeLeaderboardEntry);
	ChallengeModeInterface.AddReceivedChallengeModeGetEventMapDataDelegate(OnReceivedChallengeModeGetEventMapData);
	ChallengeModeInterface.AddReceivedChallengeModePostEventMapDataDelegate(OnReceivedChallengeModePostEventMapData);
	ChallengeModeInterface.AddReceivedChallengeModeClearIntervalDelegate(OnReceivedChallengeModeClearInterval);
	ChallengeModeInterface.AddReceivedChallengeModeClearSubmittedDelegate(OnReceivedChallengeModeClearSubmitted);
	ChallengeModeInterface.AddReceivedChallengeModeClearAllDelegate(OnReceivedChallengeModeClearAll);
	ChallengeModeInterface.AddReceivedChallengeModeGetGameSaveDelegate(OnReceivedChallengeModeGetGameSave);
	ChallengeModeInterface.AddReceivedChallengeModePostGameSaveDelegate(OnReceivedChallengeModePostGameSave);
	ChallengeModeInterface.AddReceivedChallengeModeValidateGameScoreDelegate(OnReceivedChallengeModeValidateGameScore);


	//
	// Update Data
	//
	InitializePlayerID();
	PerformChallengeModeGetSeed();
	PerformChallengeModeGetTopScores();

	UpdateData();
}

function SetupDefaultInterval()
{
	m_CurrentIntervalSeedID.A = -1;
	m_CurrentIntervalSeedID.B = -1;
	m_arrIntervals.Add(1);
	m_arrIntervals[m_arrIntervals.Length-1].IntervalSeedID = m_CurrentIntervalSeedID;
}

function PlayReplay()
{
	local XComGameState_BattleData BattleData;

	`ONLINEEVENTMGR.bInitiateReplayAfterLoad = true;
	// Load up the Replay ...
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	ConsoleCommand(BattleData.m_strMapCommand $ "?LoadingSave");
}

function ShowLoadingDialog()
{
	//local XComPresentationLayerBase Presentation;
	//local TProgressDialogData kDialogData;

	//Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(`ONLINEEVENTMGR.LocalUserIndex).Actor).Pres;
	//kDialogData.strTitle = m_strLoadingDataTitle;
	//kDialogData.strDescription = m_strLoadingDataDescription;
	//kDialogData.strAbortButtonText = "<DEFAULT ABORT>";
	//kDialogData.fnCallback = OnCancelButtonPress;
	//Presentation.UIProgressDialog(kDialogData);
}

function HideLoadingDialog()
{
	//local XComPresentationLayerBase Presentation;
	//Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(`ONLINEEVENTMGR.LocalUserIndex).Actor).Pres;
	//Presentation.UICloseProgressDialog();
}

function InitializePlayerID()
{
	local UniqueNetId PlayerId;

	OnlineSub.PlayerInterface.GetUniquePlayerId(`ONLINEEVENTMGR.LocalUserIndex, PlayerId);

	m_DownloadedInfo.SeedData.PlayerID = PlayerId;
	m_SelectedInfo.SeedData.PlayerID = PlayerId;
}

//function ChallengeModeRequest(ICMS_Action Action, optional UniqueNetID PlayerID)
//{
//	local UniqueNetID UsePlayerID;

//	// Show "Loading" while trying to talk with MCP ...
//	ShowLoadingDialog();

//	UsePlayerID = (PlayerID != UsePlayerID) ? PlayerID : m_SelectedInfo.SeedData.PlayerID;
//	`log(`location @ `ShowVar(OnlineSub.UniqueNetIdToString(UsePlayerID)),,'XCom_Online');
//	ChallengeModeInterface.PerformChallengeModeAction(UsePlayerID, Action);
//}

function PerformChallengeModeGetSeed()
{
	m_InformationText.SetText("Getting Seed information from the server ...");
	ChallengeModeInterface.PerformChallengeModeGetSeed(m_CurrentIntervalSeedID);
}

function PerformChallengeModeGetTopScores()
{
	m_InformationText.SetText("Refreshing leaderboard data from the server ...");
	m_LeaderboardData.Length = 0;
	UpdateData();
	m_bUpdatingLeaderboardData = false;
	ChallengeModeInterface.PerformChallengeModeGetTopGameScores(m_CurrentIntervalSeedID);
}

function ClearChallengeModeSeed()
{
	local PlayerSeedInfo ClearedInfo;
	m_InformationText.SetText("Clearing Seed Data ...");
	ChallengeModeInterface.PerformChallengeModeClearInterval(m_CurrentIntervalSeedID);

	// Reset the infos, but keep around the PlayerID
	m_DownloadedInfo = ClearedInfo;
	m_DownloadedInfo.SeedData.PlayerID = m_SelectedInfo.SeedData.PlayerID;
	m_SelectedInfo = ClearedInfo;
	m_SelectedInfo.SeedData.PlayerID = m_DownloadedInfo.SeedData.PlayerID;
}

function SubmitChallengeModeSeed()
{
	m_InformationText.SetText("Posting game data to the server ...");
	ChallengeModeInterface.PerformChallengeModePostGameSave();
}

function LoadSaveIntoHistory()
{
	local int DataIndex;
	local array<BYTE> EmptyData;

	m_InformationText.SetText("Loading save data into the History ...");
	EmptyData.Length = 0;
	if (m_LoadSaveDropdown.Items.Length > 0)
	{
		DataIndex = int(m_LoadSaveDropdown.GetSelectedItemData());
		if (ChallengeModeInterface.ChallengeModeLoadGameData(EmptyData, DataIndex))
		{
			m_InformationText.SetText("Game load successful!");
		}
		else
		{
			m_InformationText.SetText("Game load failed!");
		}
		SetPlayerSeedGameLoaded();
	}
}

function PerformChallengeModeGetIntervals()
{
	m_InformationText.SetText("Requesting all Intervals from the server ...");
	m_arrIntervals.Length = 0; // Clear
	ChallengeModeInterface.PerformChallengeModeGetIntervals();
}

function PerformChallengeModeGetEventData()
{
	m_InformationText.SetText("Loading Event Data from the server ...");
	ChallengeModeInterface.PerformChallengeModeGetEventMapData(m_CurrentIntervalSeedID);
}

function PerformChallengeModePostEventData()
{
	m_InformationText.SetText("Posting the current Event Data to the server ...");
	ChallengeModeInterface.PerformChallengeModePostEventMapData();
}

function PerformResetEventData()
{
	OnlineEventMgr.m_ChallengeModeEventMap.Length = 0;
	ChallengeModeManager.ResetAllData();
	m_InformationText.SetText("Event data has been reset.");
}

function PerformTriggerEvent()
{
	// Get the selected dropdown data
	local EChallengeModeEventType EventType;
	local int Turn, MaxTurns;

	EventType = EChallengeModeEventType(int(m_EventTypeDropdown.GetSelectedItemData()));
	MaxTurns = OnlineEventMgr.m_ChallengeModeEventMap.Length / ECME_MAX;
	Turn = Min(Round((m_TurnSlider.percent / 100) * MaxTurns), MaxTurns);
	
	ChallengeModeManager.OnEventTriggered(EventType, Turn, true);
	m_InformationText.SetText("Event has been triggered.");
}


//==============================================================================
//		DAILY CHALLENGE HANDLERS:
//==============================================================================
function OnReceivedChallengeModeIntervals(qword IntervalSeedID, int ExpirationDate, int TimeLength, EChallengeStateType IntervalState, string IntervalName, array<byte> StartState)
{
	local int Idx;
	`log(`location @ QWordToString(IntervalSeedID) @ `ShowVar(ExpirationDate) @ `ShowVar(TimeLength) @ `ShowEnum(EChallengeStateType, IntervalState, IntervalState),,'XCom_Online');
	Idx = m_arrIntervals.Length;
	m_arrIntervals.Add(1);
	m_arrIntervals[Idx].IntervalSeedID = IntervalSeedID;
	m_arrIntervals[Idx].DateEnd.B = ExpirationDate;
	m_arrIntervals[Idx].TimeLimit = TimeLength;
	m_arrIntervals[Idx].IntervalState = IntervalState;
	m_arrIntervals[Idx].IntervalName = IntervalName;
	m_arrIntervals[Idx].StartState = StartState;

	UpdateIntervalDropdown();
	m_InformationText.SetText("Received an Interval from the server. Total (" $ m_arrIntervals.Length $ ")");
}

function OnReceivedChallengeModeSeed(int LevelSeed, int PlayerSeed, int TimeLimit, qword StartTime, int GameScore)
{
	`log(`location @ `ShowVar(LevelSeed) @ `ShowVar(PlayerSeed) @ `ShowVar(TimeLimit) @ `ShowVar(StartTime.A) @ `ShowVar(StartTime.B) @ `ShowVar(GameScore),,'XCom_Online');
	m_DownloadedInfo.SeedData.LevelSeed = LevelSeed;
	m_DownloadedInfo.SeedData.PlayerSeed = PlayerSeed;
	m_DownloadedInfo.SeedData.TimeLimit = TimeLimit;
	m_DownloadedInfo.SeedData.StartTime = StartTime;
	m_DownloadedInfo.SeedData.GameScore = GameScore;

	m_SelectedInfo = m_DownloadedInfo;

	UpdateData();
	m_InformationText.SetText("Received Seed information from the server.");
}

function OnReceivedChallengeModeLeaderboardStart(int NumEntries, qword IntervalSeedID)
{
	`log(`location @ `ShowVar(NumEntries) @ QWordToString(IntervalSeedID),,'XCom_Online');
	m_LeaderboardData.Length = 0;
	m_bUpdatingLeaderboardData = true;
}

function OnReceivedChallengeModeLeaderboardEnd(qword IntervalSeedID)
{
	`log(`location @ QWordToString(IntervalSeedID),,'XCom_Online');
	m_bUpdatingLeaderboardData = false;
	UpdateData();
	m_InformationText.SetText("Finished refreshing leaderboard data.");
}

function OnReceivedChallengeModeLeaderboardEntry(UniqueNetId PlayerID, string PlayerName, qword IntervalSeedID, int GameScore, qword StartTime, qword EndTime)
{
	local int Index;
	`log(`location @ `ShowVar(OnlineSub.UniqueNetIdToString(PlayerID),PlayerID) @ `ShowVar(PlayerName) @ QWordToString(IntervalSeedID) @ `ShowVar(GameScore) @`ShowVar(m_bUpdatingLeaderboardData),,'XCom_Online');
	if (m_bUpdatingLeaderboardData)
	{
		Index = m_LeaderboardData.Length;
		m_LeaderboardData.Add(1);
	}
	else
	{
		Index = FindLeaderboardIndex(PlayerID, true, IntervalSeedID);
	}

	if (Index != -1)
	{
		m_LeaderboardData[Index].PlayerName				 = PlayerName;
		m_LeaderboardData[Index].SeedData.PlayerID		 = PlayerID;
		m_LeaderboardData[Index].SeedData.IntervalSeedID = IntervalSeedID;
		m_LeaderboardData[Index].SeedData.GameScore		 = GameScore;
		m_LeaderboardData[Index].SeedData.StartTime		 = StartTime;
		m_LeaderboardData[Index].SeedData.EndTime		 = EndTime;

		if (!m_bUpdatingLeaderboardData)
		{
			UpdateDisplay();
		}
	}
}

function OnReceivedChallengeModeGetGameSave(UniqueNetId PlayerID, string PlayerName, qword IntervalSeedID, int LevelSeed, int PlayerSeed, int TimeLimit, int GameScore, qword StartTime, qword EndTime, array<byte> GameData)
{
	local int Index;
	`log(`location @ `ShowVar(OnlineSub.UniqueNetIdToString(PlayerID),PlayerID) @ `ShowVar(PlayerName) @ QWordToString(IntervalSeedID) @ `ShowVar(LevelSeed) @ `ShowVar(PlayerSeed) @ `ShowVar(TimeLimit) @ `ShowVar(GameScore),,'XCom_Online');
	Index = FindLeaderboardIndex(PlayerID, true, IntervalSeedID);
	if (Index != -1)
	{
		// Set the leaderboard data
		m_LeaderboardData[Index].SeedData.PlayerID		 = PlayerID;
		m_LeaderboardData[Index].SeedData.IntervalSeedID = IntervalSeedID;
		m_LeaderboardData[Index].SeedData.LevelSeed		 = LevelSeed;
		m_LeaderboardData[Index].SeedData.PlayerSeed	 = PlayerSeed;
		m_LeaderboardData[Index].SeedData.TimeLimit		 = TimeLimit;
		m_LeaderboardData[Index].SeedData.GameScore		 = GameScore;
		m_LeaderboardData[Index].SeedData.StartTime		 = StartTime;
		m_LeaderboardData[Index].SeedData.EndTime		 = EndTime;
		m_LeaderboardData[Index].GameData				 = GameData;
		m_LeaderboardData[Index].PlayerName				 = PlayerName;

		UpdateDisplay();
	}
	m_InformationText.SetText("Leaderboard Game Data has been retrieved from the server.");
}

function OnReceivedChallengeModePostGameSave(EChallengeModeErrorStatus Status)
{
	m_InformationText.SetText("Server responded to 'Post Game Save' with" @ `ShowEnum(EChallengeModeErrorStatus, Status, Status));
}

function OnReceivedChallengeModeValidateGameScore(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess)
{
	local int Index;
	`log(`location @ `ShowVar(OnlineSub.UniqueNetIdToString(PlayerID),PlayerID) @ QWordToString(IntervalSeedID) @ `ShowVar(bSuccess),,'XCom_Online');
	Index = FindLeaderboardIndex(PlayerID, true, IntervalSeedID);
	if (Index != -1)
	{
		m_LeaderboardData[Index].bValidated = true;

		UpdateDisplay();
	}
	m_InformationText.SetText("Game data has been validated.");
}

function OnReceivedChallengeModeGetEventMapData(qword IntervalSeedID, int NumEvents, int NumTurns, array<INT> EventMap)
{
	`log(`location @ QWordToString(IntervalSeedID) @ `ShowVar(NumEvents) @ `ShowVar(NumTurns) @ `ShowVar(EventMap.Length),,'XCom_Online');
	OnlineEventMgr.m_ChallengeModeEventMap = EventMap;
	ChallengeModeManager.ResetAllData();
	m_InformationText.SetText("Done getting Event Data from the server.");
}

function OnReceivedChallengeModeClearAll(bool bSuccess)
{
	`log(`location @ `ShowVar(bSuccess),,'XCom_Online');
	m_InformationText.SetText("Server responded to 'Clear All' with '" $ bSuccess $ "'");
}

function OnReceivedChallengeModeClearInterval(qword IntervalSeedID, bool bSuccess)
{
	`log(`location @ QWordToString(IntervalSeedID) @ `ShowVar(bSuccess),,'XCom_Online');
	m_InformationText.SetText("Server responded to 'Clear Interval' ("$ QWordToString(IntervalSeedID) $") with '" $ bSuccess $ "'");
}

function OnReceivedChallengeModeClearSubmitted(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess)
{
	local string PlayerIDStr, IntervalSeedIDStr;
	PlayerIDStr = OnlineSub.UniqueNetIdToString(PlayerID);
	IntervalSeedIDStr = QWordToString(IntervalSeedID);
	`log(`location @ `ShowVar(PlayerIDStr,PlayerID) @ IntervalSeedIDStr @ `ShowVar(bSuccess),,'XCom_Online');
	m_InformationText.SetText("Server responded to 'Clear Submitted' ("$ PlayerIDStr $") ("$ IntervalSeedIDStr $") with '" $ bSuccess $ "'");
}

function OnReceivedChallengeModePostEventMapData(qword IntervalSeedID, bool bSuccess)
{
	`log(`location @ QWordToString(IntervalSeedID) @ `ShowVar(bSuccess),,'XCom_Online');
	m_InformationText.SetText("Server responded to 'Post Event Map' ("$ QWordToString(IntervalSeedID) $") with '" $ bSuccess $ "'");
}


simulated event OnReceiveChallengeModeActionFinished(ICMS_Action Action, bool bSuccess)
{
	local PlayerSeedInfo ClearInfo;
	switch(Action)
	{
	case ICMS_ClearInterval:
		ClearInfo.SeedData.PlayerID = m_SelectedInfo.SeedData.PlayerID;
		ClearInfo.PlayerName = m_SelectedInfo.PlayerName;
		m_SelectedInfo = ClearInfo;
		m_DownloadedInfo = ClearInfo;
		UpdateData();
		m_InformationText.SetText("Seed information has been cleared.");
		break;
	case ICMS_GetSeed:
	case ICMS_PostGameSave:
		UpdateData();
		break;
	case ICMS_GetEventMapData:
		m_InformationText.SetText("Event Data has been retrieved from the server.");
		break;
	case ICMS_PostEventMapData:
		m_InformationText.SetText("Event Data has been posted.");
		break;
	default:
		break;
	}
	HideLoadingDialog();
}

//==============================================================================
//		ONLINE EVENT MANAGER HANDLERS:
//==============================================================================

simulated function OnReadSaveGameListStarted()
{
	
}

simulated function OnReadSaveGameListComplete(bool bWasSuccessful)
{
	local int Index;

	if( bWasSuccessful )
		`ONLINEEVENTMGR.GetSaveGames(m_arrSaveGames);

	m_LoadSaveDropdown.Clear(); // empty dropdown

	for( Index = 0; Index < m_arrSaveGames.Length; ++Index )
	{
		//if (m_arrSaveGames[Index].bIsValid)
		//{
			m_LoadSaveDropdown.AddItem(m_arrSaveGames[Index].FriendlyName, string(Index));
		//}
	}

	if( m_LoadSaveDropdown.Items.Length > 0 )
	{
		m_LoadSaveDropdown.SetSelected( 0 );
	}
}

//==============================================================================
//		UI HANDLERS:
//==============================================================================

function OnCancelButtonPress()
{
	HideLoadingDialog();
	OnCancel();
}

function OnCloseButtonPress(UIButton Button)
{
	if (Button == m_CloseButton)
	{
		OnCancel(true);
	}
}

function OnStartButtonPress(UIButton Button)
{
	if (Button == m_StartButton)
	{
		OnAccept();
	}
}

function OnReplaySelectedButtonPress(UIButton Button)
{
	if (Button == m_ReplaySelectedButton)
	{
		ReplaySelectedLeaderboardEntry();
	}
}

function OnGetLeadersButtonPress(UIButton Button)
{
	if (Button == m_RefreshLeadersButton)
	{
		m_InformationText.SetText("Refreshing Leaderboard ...");
		PerformChallengeModeGetTopScores();
	}
}

function OnGetSeedButtonPress(UIButton Button)
{
	if (Button == m_GetSeedButton)
	{
		m_InformationText.SetText("Refreshing Seed Information ...");
		PerformChallengeModeGetSeed();
	}
}

function OnResetButtonPress(UIButton Button)
{
	if (Button == m_ResetButton)
	{
		m_InformationText.SetText("Clearing Seed Information ...");
		ClearChallengeModeSeed();
	}
}

function OnSubmitButtonPress(UIButton Button)
{
	if (Button == m_SubmitButton)
	{
		m_InformationText.SetText("Submitting Game Data ...");
		SubmitChallengeModeSeed();
	}
}

function OnLoadSaveButtonPress(UIButton Button)
{
	if (Button == m_LoadSaveButton)
	{
		m_InformationText.SetText("Loading Save Into History ...");
		LoadSaveIntoHistory();
	}
}

function OnStartTacticalMapPress(UIButton Button)
{
	if (Button == m_StartReplayButton)
	{
		PlayReplay();
	}
}

function OnGetIntervalsButtonPress(UIButton Button)
{
	if (Button == m_GetIntervalsButton)
	{
		PerformChallengeModeGetIntervals();
	}
}

function OnGetEventDataButtonPress(UIButton Button)
{
	if (Button == m_GetEventDataButton)
	{
		m_InformationText.SetText("Getting Event Data from Server ...");
		PerformChallengeModeGetEventData();
	}
}

function OnSubmitEventDataButtonPress(UIButton Button)
{
	if (Button == m_SubmitEventDataButton)
	{
		m_InformationText.SetText("Posting Event Data to Server ...");
		PerformChallengeModePostEventData();
	}
}

function OnResetEventDataButtonPress(UIButton Button)
{
	if (Button == m_ResetEventDataButton)
	{
		PerformResetEventData();
		m_InformationText.SetText("Event Data has been Reset.");
	}
}

function OnViewEventDataButtonPress(UIButton Button)
{
	if (Button == m_ViewEventDataButton)
	{
		m_InformationText.SetText("Viewing Event Data.");
		XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres.UIChallengeModeEventNotify(true);
	}
}

function OnTriggerEventButtonPress(UIButton Button)
{
	if (Button == m_TriggerEventButton)
	{
		m_InformationText.SetText("Event has been triggered.");
		PerformTriggerEvent();
	}
}



// String
function OnEditStringButtonPress(UIButton Button)
{
	EditButtonPress(Button, OnEditStringButtonPress_OnNameInputBoxClosed, GetStringButtonData(Button));
}

function OnEditStringButtonPress_OnNameInputBoxClosed(string text)
{
	SetStringButtonData(m_ClickedButton, text);
}

// Int
function OnEditIntButtonPress(UIButton Button)
{
	EditButtonPress(Button, OnEditIntButtonPress_OnNameInputBoxClosed, string(GetIntButtonData(Button)));
}

function OnEditIntButtonPress_OnNameInputBoxClosed(string text)
{
	local int Number;
	Number = (text != "") ? int(text) : 0;
	SetIntButtonData(m_ClickedButton, Number);
}

// QWord
function OnEditQWordButtonPress(UIButton Button)
{
	EditButtonPress(Button, OnEditQWordButtonPress_OnNameInputBoxClosed, QWordToString(GetQWordButtonData(Button)));
}

function OnEditQWordButtonPress_OnNameInputBoxClosed(string Text)
{
	SetQWordButtonData(m_ClickedButton, StringToQWord(Text));
}

function OnLeaderboardDoubleClick(UIList _list, int iItemIndex)
{
	local UniqueNetId PlayerID;

	PlayerID = m_LeaderboardData[iItemIndex].SeedData.PlayerID;
	if (m_LeaderboardData[iItemIndex].GameData.Length > 0) // Downloaded
	{
		if (!m_LeaderboardData[iItemIndex].bValidated)
		{
			// Show "Loading" while trying to talk with MCP ...
			ShowLoadingDialog();

			m_InformationText.SetText("Validating game ...");
			ChallengeModeInterface.PerformChallengeModeValidateGameScore(PlayerID, 
				m_LeaderboardData[iItemIndex].SeedData.LevelSeed,
				m_LeaderboardData[iItemIndex].SeedData.PlayerSeed,
				m_LeaderboardData[iItemIndex].SeedData.TimeLimit,
				m_LeaderboardData[iItemIndex].SeedData.GameScore,
				m_LeaderboardData[iItemIndex].GameData);
		}
		else
		{
			m_InformationText.SetText("Loading game data into history ...");
			if (ChallengeModeInterface.ChallengeModeLoadGameData(m_LeaderboardData[iItemIndex].GameData))
			{
				SetPlayerSeedGameLoaded(iItemIndex);
			}
		}
	}
	else
	{
		m_InformationText.SetText("Getting Game Save Data from the Server ...");
		ChallengeModeInterface.PerformChallengeModeGetGameSave(PlayerID, m_CurrentIntervalSeedID);
	}
}

function LoadSaveDropdownSelectionChange(UIDropdown kDropdown) { }
function EventTypeDropdownSelectionChange(UIDropdown kDropdown) { }
function IntervalDropdownSelectionChange(UIDropdown kDropdown)
{
	local int Idx;
	Idx = int(m_IntervalDropdown.GetSelectedItemData());
	m_CurrentIntervalSeedID = m_arrIntervals[Idx].IntervalSeedID;
}

function ReplaySelectedLeaderboardEntry()
{
	GotoState('ReplaySelected');
}

function OnAccept()
{
	// Make sure the settings are correct
	if (DataValidated())
	{
		// Start the mission
		GotoState('LaunchChallenge');
	}
	else
	{
		// Get the seed first
		m_InformationText.SetText("Getting Seed Information from the Server ...");
		PerformChallengeModeGetSeed();
	}
}

function OnCancel(optional bool bAll=false)
{
	// Return to Main Menu!
	Movie.Stack.Pop(self);
}

simulated function OnReceiveFocus()
{
	Show();
}

simulated function OnLoseFocus()
{
	Hide();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		OnAccept();
		return true;
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		OnCancel();
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}


//==============================================================================
//		HELPERS :
//==============================================================================
function SetPlayerSeedGameLoaded(optional int ItemIndex=-1)
{
	local int i;
	for (i = 0; i < m_LeaderboardData.Length; ++i)
	{
		m_LeaderboardData[i].bLoaded = (i == ItemIndex);
	}
	UpdateDisplay();
}

function string GetLeaderboardString(PlayerSeedInfo Info)
{
	local string PlayerName;
	local string Status;
	local qword TimeElapsed;
	TimeElapsed = GetQWordDifference(Info.SeedData.EndTime, Info.SeedData.StartTime);

	if (Info.bLoaded)
	{
		Status = "[Loaded]";
	}
	else if (Info.bValidated)
	{
		Status = "[Validated]";
	}
	else
	{
		Status = (Info.GameData.Length > 0 ? "[Downloaded]" : "");
	}

	if (Info.PlayerName != "")
	{
		PlayerName = Info.PlayerName;
	}
	else
	{
		PlayerName = "(" $ OnlineSub.UniqueNetIdToString(Info.SeedData.PlayerID) $ ")";
	}

	return PlayerName $ " - (Score: " $ Info.SeedData.GameScore $ ") (" $ FormatAsTimeElapsed(TimeElapsed) $ ")" @ Status;
}

function string FormatAsTimeElapsed(qword Time)
{
	local string Format;
	local int Hours, Minutes, Seconds;
	Hours = (Time.B / 3600) % 24;
	Minutes = (Time.B / 60) % 60;
	Seconds = Time.B % 60;
	Format = ((Hours > 0) ? string(Hours) : "00") $ ":"
		   $ ((Minutes > 0) ? string(Minutes) : "00") $ ":"
		   $ ((Seconds > 0) ? string(Seconds) : "00") $ ":";
	return Format;
}

function SetStringButtonData(UIButton Button, string Data)
{
	switch (Button)
	{
	case m_PlayerIDButton: OnlineSub.StringToUniqueNetId(Data, m_SelectedInfo.SeedData.PlayerID); break;
	default:
		break;
	}
}

function string GetStringButtonData(UIButton Button)
{
	switch (Button)
	{
	case m_PlayerIDButton: return OnlineSub.UniqueNetIdToString(m_SelectedInfo.SeedData.PlayerID); break;
	default:
		break;
	}
	return "";
}

function SetIntButtonData(UIButton Button, int Data)
{
	switch (Button)
	{
	case m_IntervalSeedButton: m_SelectedInfo.SeedData.LevelSeed = Data; break;
	case m_RandomSeedButton: m_SelectedInfo.SeedData.PlayerSeed = Data; break;
	case m_TimeLimitButton: m_SelectedInfo.SeedData.TimeLimit = Data; break;
	default:
		break;
	}
}

function int GetIntButtonData(UIButton Button)
{
	switch (Button)
	{
	case m_IntervalSeedButton: return m_SelectedInfo.SeedData.LevelSeed; break;
	case m_RandomSeedButton: return m_SelectedInfo.SeedData.PlayerSeed; break;
	case m_TimeLimitButton: return m_SelectedInfo.SeedData.TimeLimit; break;
	default:
		break;
	}
	return 0;
}

function SetQWordButtonData(UIButton Button, qword Data)
{
	switch (Button)
	{
	case m_TimeStartButton: m_SelectedInfo.SeedData.StartTime = Data; break;
	default:
		break;
	}
}

function qword GetQWordButtonData(UIButton Button)
{
	local qword QWordZero;
	switch (Button)
	{
	case m_TimeStartButton: return m_SelectedInfo.SeedData.StartTime; break;
	default:
		break;
	}
	return QWordZero;
}

function qword GetQWordDifference(qword LeftHand, qword RightHand)
{
	local qword Diff;
    Diff.A = LeftHand.A - RightHand.A;
    Diff.B = LeftHand.B - RightHand.B;
    // Check for the carry
    if (Diff.B > LeftHand.B)
        --Diff.A;
	return Diff;
}

function string QWordToString(qword Number)
{
	local UniqueNetId NetId;

	NetId.Uid.A = Number.A;
	NetId.Uid.B = Number.B;

	return OnlineSub.UniqueNetIdToString(NetId);
}

function qword StringToQWord(string Text)
{
	local UniqueNetId NetId;
	local qword Number;

	OnlineSub.StringToUniqueNetId(Text, NetId);

	Number.A = NetId.Uid.A;
	Number.B = NetId.Uid.B;

	return Number;
}

function EditButtonPress(UIButton Button, delegate<TextInputClosedCallback> fnCallback, string InputBoxText )
{
	local TInputDialogData kData;

	m_ClickedButton = Button;
	kData.fnCallback = fnCallback;
	kData.strTitle = Button.Text;
	kData.strInputBoxText = InputBoxText;
	Movie.Pres.UIInputDialog(kData);
}

function int FindLeaderboardIndex(UniqueNetId PlayerID, optional bool bUseSeed=false, optional qword IntervalSeedID)
{
	local int Index;

	for (Index = 0; Index < m_LeaderboardData.Length; ++Index)
	{
		if (m_LeaderboardData[Index].SeedData.PlayerID == PlayerID)
		{
			if (!bUseSeed || (m_LeaderboardData[Index].SeedData.IntervalSeedID == IntervalSeedID))
				break;
		}
	}

	if (m_LeaderboardData.Length == 0 || Index >= m_LeaderboardData.Length)
	{
		Index = -1;
	}

	return Index;
}


//==============================================================================
//		MEMBERS:
//==============================================================================
function UpdateIntervalDropdown()
{
	local int Index, SelectedIdx;
	local string DropdownEntryStr;
	SelectedIdx = 0;
	m_IntervalDropdown.Clear(); // empty dropdown
	for( Index = 0; Index < m_arrIntervals.Length; ++Index )
	{
		DropdownEntryStr = QWordToString(m_arrIntervals[Index].IntervalSeedID);
		DropdownEntryStr $= ": " $ `ShowEnum(EChallengeStateType, m_arrIntervals[Index].IntervalState, State);
		m_IntervalDropdown.AddItem(DropdownEntryStr, string(Index));
		if( m_arrIntervals[Index].IntervalSeedID == m_CurrentIntervalSeedID )
		{
			SelectedIdx = Index;
		}
	}
	m_IntervalDropdown.SetSelected( SelectedIdx );
}

function UpdateDisplay()
{
	local int i;

	if (!(m_SelectedInfo.SeedData.LevelSeed == -1 && m_SelectedInfo.SeedData.PlayerSeed == -1 && m_SelectedInfo.SeedData.TimeLimit == -1))
	{
		if (m_SelectedInfo.SeedData.GameScore == -1)
		{
			m_StartButton.SetText("Start Challenge");
		}
		else
		{
			m_StartButton.SetText("Already Completed");
		}
	}
	else
	{
		m_StartButton.SetText("Get Seed");
	}

	for( i = 0; (i < m_LeaderboardData.Length) && (i < m_Leaderboard.ItemCount); ++i )
	{
		UIListItemString(m_Leaderboard.GetItem(i)).SetText(GetLeaderboardString(m_LeaderboardData[i]));
	}
}

function UpdateData()
{
	local UIListItemString ListItem;

	if(m_Leaderboard.itemCount > m_LeaderboardData.length)
		m_Leaderboard.ClearItems();

	while(m_Leaderboard.itemCount < m_LeaderboardData.length)
	{
		ListItem = Spawn(class'UIListItemString', m_Leaderboard.itemContainer);
		ListItem.AddOnInitDelegate(OnInitUpdateDataListItem);
		ListItem.InitListItem();
	}
	
	UpdateDisplay();
}

function OnInitUpdateDataListItem(UIPanel InitedItem)
{
	UpdateDisplay();
}

function bool DataValidated()
{
	`log(`location @ `ShowVar(OnlineSub.UniqueNetIdToString(m_SelectedInfo.SeedData.PlayerID)) @ `ShowVar(m_SelectedInfo.SeedData.LevelSeed) @ `ShowVar(m_SelectedInfo.SeedData.PlayerSeed) @ `ShowVar(m_SelectedInfo.SeedData.TimeLimit) @ `ShowVar(m_SelectedInfo.SeedData.GameScore));
	// Confirm that there is Map, Player, and Time data without a score; otherwise they have already played the challenge.
	return m_SelectedInfo.SeedData.LevelSeed != -1 && m_SelectedInfo.SeedData.PlayerSeed != -1 && m_SelectedInfo.SeedData.TimeLimit != -1 && m_SelectedInfo.SeedData.GameScore == -1;
}

function CreateChallengeLoadout()
{
	// Random for now
	GenerateRandomLoadout();
}

function GenerateRandomLoadout()
{
	// Game State references
	local XComGameState_Unit			NewSoldierState;
	local XComGameState_Player			PlayerState;

	// Determine which map to load
	local int							PlayerIdx, SoldierIdx;

	// Create the new soldiers
	local X2CharacterTemplateManager    CharTemplateMgr;	
	local X2CharacterTemplate           CharacterTemplate;
	local TSoldier                      CharacterGeneratorResult;
	local XGCharacterGenerator          CharacterGenerator;

	m_InformationText.SetText("Generating Random Loadout ...");

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Soldier');
	`assert(CharacterTemplate != none);
	CharacterGenerator = Spawn(CharacterTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	for( PlayerIdx = 0; PlayerIdx < m_BattleData.PlayerTurnOrder.Length; ++PlayerIdx)
	{
		PlayerState = XComGameState_Player(m_NewStartState.GetGameStateForObjectID(m_BattleData.PlayerTurnOrder[PlayerIdx].ObjectID));
		if (PlayerState.IsAIPlayer())
		{
			continue;
		}

		for( SoldierIdx = 0; SoldierIdx < class'XGTacticalGameCore'.default.NUM_STARTING_SOLDIERS; ++SoldierIdx )
		{
			NewSoldierState = CharacterTemplate.CreateInstanceFromTemplate(m_NewStartState);
			NewSoldierState.RandomizeStats();

			NewSoldierState.ApplyInventoryLoadout(m_NewStartState, 'RookieSoldier');

			CharacterGeneratorResult = CharacterGenerator.CreateTSoldier();
			NewSoldierState.SetTAppearance(CharacterGeneratorResult.kAppearance);
			NewSoldierState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
			NewSoldierState.SetCountry(CharacterGeneratorResult.nmCountry);
			class'XComGameState_Unit'.static.NameCheck(CharacterGenerator, NewSoldierState, eNameType_Full);

			NewSoldierState.SetHQLocation(eSoldierLoc_Dropship);
			NewSoldierState.SetControllingPlayer(PlayerState.GetReference());

			m_NewStartState.AddStateObject(NewSoldierState);
		}
	}

	CharacterGenerator.Destroy();
}

function SetupMapData()
{
	local XComTacticalMissionManager		MissionManager;
	local XComGameState_MissionSite			ChallengeMission;
	local array<XComGameState_Reward>		MissionRewards;
	local XComGameState_Reward				RewardState;
	local X2RewardTemplate					RewardTemplate;
	local StateObjectReference				RegionRef;
	local Vector2D							RandomLocation;
	local X2StrategyElementTemplateManager	StratMgr;
	local X2MissionSourceTemplate			MissionSource;

	m_InformationText.SetText("Setting up map data ...");

	// Setup the MissionRewards
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(m_MissionRewardType));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(m_NewStartState);
	RewardState.SetReward(,0);
	m_NewStartState.AddStateObject(RewardState);
	MissionRewards.AddItem(RewardState);

	// Setup the GeneratedMission
	ChallengeMission = XComGameState_MissionSite(m_NewStartState.CreateStateObject(class'XComGameState_MissionSite'));
	RandomLocation = ChallengeMission.SelectRandomMissionLocation(RegionRef, m_NewStartState);
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_ChallengeMode'));
	ChallengeMission.BuildMission(MissionSource, RandomLocation, RegionRef, MissionRewards, true, true, /* iHours */, m_SelectedInfo.SeedData.TimeLimit, true, m_SelectedInfo.SeedData.LevelSeed);
	m_NewStartState.AddStateObject(ChallengeMission);

	// Setup the Battle Data
	m_BattleData.iLevelSeed				= ChallengeMission.GeneratedMission.LevelSeed;
	m_BattleData.iFirstStartTurnSeed	= m_SelectedInfo.SeedData.PlayerSeed;
	m_BattleData.bUseFirstStartTurnSeed	= true;
	m_BattleData.m_strDesc				= "Challenge Mode"; //If you change this, be aware that this is how the ruleset knows the battle is a challenge mode battle
	m_BattleData.m_strOpName			= class'XGMission'.static.GenerateOpName(false);
	m_BattleData.m_strMapCommand		= "open" @ ChallengeMission.GeneratedMission.Plot.MapName $ "?game=XComGame.XComTacticalGame";
	m_BattleData.MapData.PlotMapName    = ChallengeMission.GeneratedMission.Plot.MapName;
	m_BattleData.MapData.Biome          = ChallengeMission.GeneratedMission.Biome.strType;
	m_BattleData.SetForceLevel(1); // TODO: Add ForceLevel to the SeedData

	// Setup the Mission Data
	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.ForceMission = ChallengeMission.GeneratedMission.Mission;
	MissionManager.MissionQuestItemTemplate = ChallengeMission.GeneratedMission.MissionQuestItemTemplate;

	/*

	//Add any reward personnel to the battlefield
	for( RewardIndex = 0; RewardIndex < MissionState.Rewards.Length; ++RewardIndex )
	{
		RewardStateObject = XComGameState_Reward(History.GetGameStateForObjectID(MissionState.Rewards[RewardIndex].ObjectID));
		if( RewardStateObject.IsPersonnelType() )
		{
			//Add the reward unit to the battle
			SendSoldierState = XComGameState_Unit( NewStartState.CreateStateObject(class'XComGameState_Unit', RewardStateObject.RewardObjectReference.ObjectID) );
			`assert(SendSoldierState != none);
			SendSoldierState.SetControllingPlayer( BattleData.CivilianPlayerRef );
			NewStartState.AddStateObject(SendSoldierState);

			//Track which units the battle is considering to be rewards ( used later when spawning objectives )
			BattleData.RewardUnits.AddItem(RewardStateObject.RewardObjectReference);
		}
	}

	*/
}

function CreateChallengeStartState()
{
	local XGTacticalGameCore GameCore;

	m_InformationText.SetText("Creating Challenge Start State ...");

	///
	/// Setup the Tactical side ...
	///
	`ONLINEEVENTMGR.ReadProfileSettings();
	GameCore = `GAMECORE;
	if(GameCore == none)
	{
		GameCore = Spawn(class'XGTacticalGameCore', self);
		GameCore.Init();
	}

	//Create the basic strategy objects
	class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(,false, , , , , false);

	//Create the tactical rule-set
	m_NewStartState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Singleplayer(m_BattleData);
	class'XComGameState_ChallengeData'.static.CreateChallengeData(m_NewStartState, m_SelectedInfo.SeedData);

	//Create a countdown timer from the time when the seed was first provided; this will allow for re-entry for multiple attempts, but the second try will not give the player any more time.
	//@TODO: Uncomment once UI is in place.
	//class'XComGameState_TimerData'.static.CreateRealtimeGameTimer(m_SelectedInfo.SeedData.TimeLimit, m_NewStartState, m_SelectedInfo.SeedData.StartTime.B, EGSTDT_Down);
}

function SetupStartState()
{
	History.ResetHistory();

	class'Engine'.static.GetEngine().SetRandomSeeds(m_SelectedInfo.SeedData.LevelSeed);

	CreateChallengeStartState();
	SetupMapData();
	CreateChallengeLoadout();

	m_InformationText.SetText("Done Setting up Start State.");


	//Add the start state to the history
	History.AddGameStateToHistory(m_NewStartState);
}


//==============================================================================
//		STATES:
//==============================================================================
state LaunchChallenge
{
	function OnReceivedChallengeModeGetEventMapData(qword IntervalSeedID, int NumEvents, int NumTurns, array<INT> EventMap)
	{
		m_InformationText.SetText("Configuring Challenge Map ...");
		global.OnReceivedChallengeModeGetEventMapData(IntervalSeedID, NumEvents, NumTurns, EventMap);
		LoadTacticalMap();
	}

	function LoadTacticalMap()
	{
		`log(`location,,'XCom_Online');

		SetupStartState();
		Cleanup(); // Unregisters any delegates prior to the map change
		ConsoleCommand(m_BattleData.m_strMapCommand);
	}

Begin:
	//Get the latest Event Data from the server ...
	PerformChallengeModeGetEventData();
}
state ReplaySelected
{
	// Ignore additional button presses when already processing this state.
	function ReplaySelectedLeaderboardEntry()
	{
		return;
	}

	// Given an index into the leaderboard data where the data is at its start state this will operate in order for each subsuquent call with the same index value
	//  1) Issues command to download the game data from the server
	//  2) Performs a validation on the game data prior to running the replay, and submits the result to the server
	//  3) Starts the game replay
	function PerformNextActionBasedOnEntryState(int iItemIndex)
	{
		local UniqueNetId PlayerID;

		PlayerID = m_LeaderboardData[iItemIndex].SeedData.PlayerID;
		if (m_LeaderboardData[iItemIndex].GameData.Length > 0) // Downloaded
		{
			if (!m_LeaderboardData[iItemIndex].bValidated) // Needs Validation prior to Starting Game Mode
			{
				m_InformationText.SetText("Validating game data ...");
				ChallengeModeInterface.PerformChallengeModeValidateGameScore(PlayerID, 
					m_LeaderboardData[iItemIndex].SeedData.LevelSeed, 
					m_LeaderboardData[iItemIndex].SeedData.PlayerSeed, 
					m_LeaderboardData[iItemIndex].SeedData.TimeLimit, 
					m_LeaderboardData[iItemIndex].SeedData.GameScore, 
					m_LeaderboardData[iItemIndex].GameData);
			}
			else // Validated, ready for load / start
			{
				m_InformationText.SetText("Starting Replay from Leaderboard ...");
				if (ChallengeModeInterface.ChallengeModeLoadGameData(m_LeaderboardData[iItemIndex].GameData))
				{
					SetPlayerSeedGameLoaded(iItemIndex);
					PlayReplay();
				}
			}
		}
		else // Needs to download prior to processing
		{
			m_InformationText.SetText("Getting leaderboard game data from the server ...");
			ChallengeModeInterface.PerformChallengeModeGetGameSave(PlayerID, m_CurrentIntervalSeedID);
		}
	}

	function DelayedNextAction()
	{
		PerformNextActionBasedOnEntryState(m_Leaderboard.SelectedIndex);
	}

	function OnReceivedChallengeModeValidateGameScore(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess)
	{
		m_InformationText.SetText("Leaderboard Game Data has been Validated.");
		global.OnReceivedChallengeModeValidateGameScore(PlayerID, IntervalSeedID, bSuccess);
		SetTimer(0.5, False, nameof(DelayedNextAction));
	}

	function OnReceivedChallengeModeGetGameSave(UniqueNetId PlayerID, string PlayerName, qword IntervalSeedID, int LevelSeed, int PlayerSeed, int TimeLimit, int GameScore, qword StartTime, qword EndTime, array<byte> GameData)
	{
		m_InformationText.SetText("Done getting game data from the server.");
		global.OnReceivedChallengeModeGetGameSave(PlayerID, PlayerName, IntervalSeedID, LevelSeed, PlayerSeed, TimeLimit, GameScore, StartTime, EndTime, GameData);
		SetTimer(0.5, False, nameof(DelayedNextAction));
	}

Begin:
	// Start the downloading / validating process using the currently selected leaderboard index
	PerformNextActionBasedOnEntryState(m_Leaderboard.SelectedIndex);
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

simulated private function Cleanup()
{
	if( OnlineEventMgr != none )
	{
		OnlineEventMgr.ClearUpdateSaveListStartedDelegate(OnReadSaveGameListStarted);
		OnlineEventMgr.ClearUpdateSaveListCompleteDelegate(OnReadSaveGameListComplete);
	}

	ChallengeModeInterface.ClearReceivedChallengeModeIntervalsDelegate(OnReceivedChallengeModeIntervals);
	ChallengeModeInterface.ClearReceivedChallengeModeSeedDelegate(OnReceivedChallengeModeSeed);
	ChallengeModeInterface.ClearReceivedChallengeModeLeaderboardStartDelegate(OnReceivedChallengeModeLeaderboardStart);
	ChallengeModeInterface.ClearReceivedChallengeModeLeaderboardEndDelegate(OnReceivedChallengeModeLeaderboardEnd);
	ChallengeModeInterface.ClearReceivedChallengeModeLeaderboardEntryDelegate(OnReceivedChallengeModeLeaderboardEntry);
	ChallengeModeInterface.ClearReceivedChallengeModeGetEventMapDataDelegate(OnReceivedChallengeModeGetEventMapData);
	ChallengeModeInterface.ClearReceivedChallengeModePostEventMapDataDelegate(OnReceivedChallengeModePostEventMapData);
	ChallengeModeInterface.ClearReceivedChallengeModeClearIntervalDelegate(OnReceivedChallengeModeClearInterval);
	ChallengeModeInterface.ClearReceivedChallengeModeClearSubmittedDelegate(OnReceivedChallengeModeClearSubmitted);
	ChallengeModeInterface.ClearReceivedChallengeModeClearAllDelegate(OnReceivedChallengeModeClearAll);
	ChallengeModeInterface.ClearReceivedChallengeModeGetGameSaveDelegate(OnReceivedChallengeModeGetGameSave);
	ChallengeModeInterface.ClearReceivedChallengeModePostGameSaveDelegate(OnReceivedChallengeModePostGameSave);
	ChallengeModeInterface.ClearReceivedChallengeModeValidateGameScoreDelegate(OnReceivedChallengeModeValidateGameScore);
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	m_MissionRewardType = "Reward_Supplies"
}
