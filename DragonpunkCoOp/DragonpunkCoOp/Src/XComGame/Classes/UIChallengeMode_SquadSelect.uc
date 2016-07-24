//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChallengeMode_SquadSelect
//  AUTHOR:  Timothy Talley -- 02/23/2015
//
//  PURPOSE: Displays the Challenge Mode Squad selection options based on the mock-up at
//      N:\2KGBAL\Projects\XCOM 2\Art\UI\DailyChallenge
//
//
// - Section: Header
//     - Title
//     - Challenge Operation Name
//     - Boosts
// - Section: Objectives
//     - Object List
//     - Power Level
//     - Location
//     - (REMOVED) Edit Commander Button
// - (REMOVED) Section: Commander
//     - (REMOVED) Soldier Template
//     - (REMOVED) Commander Medals
// - (REMOVED) Section: Tactical Options
//     - (REMOVED) Option 1: (Activate) Boosts Solider [#] [stat] by [x] and Reduces Soldier [#] [stat] by [y]
//     - (REMOVED) Option 2: (Activate) 
// - Section: Squad
//     - Soldier #1 Template
//     - Soldier #2 Template
//     - Soldier #3 Template
//     - Soldier #4 Template
//     - Soldier #5 Template
//     - Soldier #6 Template
// - Button: Back
// - Button: View Medals
// - Button: Accept Challenge
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChallengeMode_SquadSelect extends UIScreen;


//--------------------------------------------------------------------------------------- 
// Section Headers / Backgrounds
//
var UIPanel							    m_kAllContainer;
var UIX2PanelHeader						m_MissionHeader;
var UIBGBox                             m_MissionHeaderBox;
// var UIX2PanelHeader					m_TacticalOptionsHeader;
// var UIBGBox                          m_TacticalOptionsHeaderBox;
var UIX2PanelHeader                     m_ObjectiveHeader;		// DEPRECATED bsteiner 3/24/2016
var UIBGBox                             m_ObjectiveHeaderBox;	// DEPRECATED bsteiner 3/24/2016

//--------------------------------------------------------------------------------------- 
// UI Objects
//
//var UIButton							m_ActivateOpt1Button;
//var UIButton							m_ActivateOpt2Button;
var UIButton							m_BackButton;
var UIButton							m_ViewMedalsButton;
var UIButton							m_AcceptChallengeButton;
var UIDropdown							m_IntervalDropdown;	        // List of all returned Intervals - TEMP


//--------------------------------------------------------------------------------------- 
// Localization Labels
//
var localized string					m_strChallengeModeTitle;
var localized string					m_strObjectiveTitle;
var localized string					m_strTacticalOptionsTitle;
var localized string					m_strDeactivateButtonLabel;
var localized string					m_strActivateButtonLabel;
var localized string					m_strBoostActiveLabel;
var localized string                    m_strBackButtonLabel;
var localized string					m_strViewMedalsButtonLabel;
var localized string					m_strAcceptChallengeButtonLabel;
var localized string					m_strMostlyTag;	
var array<UIChallengeMode_UnitSlot>     m_arrUnitSlots;	// DEPRECATED bsteiner 3/24/2016

var localized string					m_strDifficultyLabel;
var localized string					m_strLocationLabel;

var UIText								m_ObjectiveText;

const MAX_UNIT_SLOTS = 6;


//--------------------------------------------------------------------------------------- 
// Challenge Data
//
var array<IntervalInfo>		m_arrIntervals;
var qword                     m_CurrentIntervalSeedID;


//--------------------------------------------------------------------------------------- 
// X2 Battle Data
//
var XComGameState_BattleData			m_BattleData;
var XComGameState_ChallengeData			m_ChallengeData;
var XComGameState_ObjectivesList		m_ObjectivesList;


//--------------------------------------------------------------------------------------- 
// Cache References
//
var XComGameStateHistory		History;
var OnlineSubsystem				OnlineSub;
var XComOnlineEventMgr			OnlineEventMgr;
var X2ChallengeModeInterface    ChallengeModeInterface;
var X2TacticalChallengeModeManager    ChallengeModeManager;


//==============================================================================
//		INITIALIZATION:
//==============================================================================
simulated function CacheUpdate()
{
	local XComChallengeModeManager ChallengesManager;
	local int ChallengeIdx, PlayerSeedId, DropdownIdx;
	History = `XCOMHISTORY;
	OnlineSub = Class'GameEngine'.static.GetOnlineSubsystem();
	OnlineEventMgr = `ONLINEEVENTMGR;
	ChallengeModeInterface = `CHALLENGEMODE_INTERFACE;
	ChallengesManager = XComEngine(Class'GameEngine'.static.GetEngine()).ChallengeModeManager;

	if (m_arrIntervals.Length > 0)
	{
		DropdownIdx = int(m_IntervalDropdown.GetSelectedItemData());
		PlayerSeedId = m_arrIntervals[DropdownIdx].IntervalSeedID.A;
		ChallengeIdx = ChallengesManager.FindChallengeIndex(PlayerSeedId);
		`log(`location @ `ShowVar(PlayerSeedId) @ `ShowVar(ChallengeIdx),,'FiraxisLive');
		if( ChallengeIdx > -1 )
		{
			History.ReadHistoryFromChallengeModeManager(ChallengeIdx);
			m_BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
			m_ChallengeData = XComGameState_ChallengeData(History.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData'));
			m_ObjectivesList = XComGameState_ObjectivesList(History.GetSingleGameStateObjectForClass(class'XComGameState_ObjectivesList'));
		}
	}
}

simulated function InitScreen( XComPlayerController InitController, UIMovie InitMovie, optional name InitName )
{
	local int ButtonWidth, FooterButtonYSpacing;
	FooterButtonYSpacing = 25;
	ButtonWidth = 150;

	CacheUpdate();
	SubscribeToOnCleanupWorld();

	super.InitScreen(InitController, InitMovie, InitName);

	m_kAllContainer = Spawn(class'UIPanel', self);

	m_kAllContainer.InitPanel('allContainer');
	m_kAllContainer.AnchorTopLeft();
	m_kAllContainer.SetPosition(10, 10).SetSize(Movie.UI_RES_X - 40, Movie.UI_RES_Y - 40);


	//
	// Create Header/Mission Section
	//
	m_MissionHeaderBox = Spawn(class'UIBGBox', m_kAllContainer).InitBG('', 0, 0, m_kAllContainer.width, 75).SetBGColor("gray");
	

	//
	// Buttons
	//
	m_BackButton = Spawn(class'UIButton', m_kAllContainer);
	m_BackButton.InitButton('backButton', m_strBackButtonLabel, OnButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_BackButton.SetPosition(0, m_kAllContainer.height - FooterButtonYSpacing);

	m_ViewMedalsButton = Spawn(class'UIButton', m_kAllContainer);
	m_ViewMedalsButton.InitButton('viewMedalsButton', m_strViewMedalsButtonLabel, OnButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_ViewMedalsButton.SetPosition((m_kAllContainer.width - ButtonWidth) * 0.5, m_kAllContainer.height - FooterButtonYSpacing);

	m_AcceptChallengeButton = Spawn(class'UIButton', m_kAllContainer);
	m_AcceptChallengeButton.InitButton('acceptChallengeButton', m_strAcceptChallengeButtonLabel, OnButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_AcceptChallengeButton.SetPosition(m_kAllContainer.width - ButtonWidth - 10, m_kAllContainer.height - FooterButtonYSpacing);


	//
	// TEMP: Interval Dropdown for easy selection ...
	//
	m_IntervalDropdown = Spawn(class'UIDropdown', m_kAllContainer);
	m_IntervalDropdown.InitDropdown('intervalDropdown', "Intervals", IntervalDropdownSelectionChange);
	m_IntervalDropdown.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_IntervalDropdown.SetPosition(m_MissionHeaderBox.X + 450, m_MissionHeaderBox.Y + 65);
	UpdateIntervalDropdown();


	//
	// Setup Handlers
	//
	ChallengeModeManager = Spawn(class'X2TacticalChallengeModeManager', self);
	ChallengeModeManager.Init();

	ChallengeModeInterface.AddReceivedChallengeModeIntervalsDelegate(OnReceivedChallengeModeIntervals);
	ChallengeModeInterface.AddReceivedChallengeModeSeedDelegate(OnReceivedChallengeModeSeed);
	ChallengeModeInterface.AddReceivedChallengeModeGetEventMapDataDelegate(OnReceivedChallengeModeGetEventMapData);


	//
	// Server Data Updates
	//
	RequestServerDataUpdate();
}

function UpdateObjectives()
{
	local ObjectiveDisplayInfo Info;
	local string s;

	foreach m_ObjectivesList.ObjectiveDisplayInfos(Info)
	{
		s $= Info.DisplayLabel $ ",";
	}
	MC.BeginFunctionOp("setObjectiveData");
	MC.QueueString(m_strObjectiveTitle);
	MC.QueueString(s);
	MC.QueueString("");//optional warning message send blank string if there is no message
	MC.QueueString(m_strDifficultyLabel);//difficulty label "DIFFICULTY"
	MC.QueueString("");//difficulty value EASY, HARD, IMPOSSIBLE
	MC.QueueString(m_strLocationLabel);//location label "LOCATION"
	MC.QueueString( m_BattleData.m_strLocation );//location value, location name
	MC.EndOp();
}

function UpdateSoldiers()
{
	local XComGameState_Unit Unit;
	local int Index;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if ((Unit.GetTeam() == eTeam_XCom) && (Unit.GetSoldierClassTemplate() != none))
		{
			if (Index < MAX_UNIT_SLOTS)
			{
				AddSlot(Index++, Unit);
			}
		}
	}
}

function AddSlot(int Index, XComGameState_Unit Unit)
{
	local SCATProgression SoldierProgression;
	local int LeftCount, RightCount;
	local X2SoldierClassTemplate ClassTemplate;
	local string ClassSpecialization;

	LeftCount = 0;
	RightCount = 0;
	foreach Unit.m_SoldierProgressionAbilties( SoldierProgression )
	{
		if (SoldierProgression.iRank > 0)
		{
			if (SoldierProgression.iBranch == 0)
			{
				++LeftCount;
			}
			else
			{
				++RightCount;
			}
		}
	}

	ClassTemplate = Unit.GetSoldierClassTemplate( );
	if (LeftCount == 7)
	{
		ClassSpecialization = ClassTemplate.LeftAbilityTreeTitle;
	}
	else if (RightCount == 7)
	{
		ClassSpecialization = ClassTemplate.RightAbilityTreeTitle;
	}
	else if (LeftCount >= 4)
	{
		ClassSpecialization = m_strMostlyTag $ " " $ ClassTemplate.LeftAbilityTreeTitle;
	}
	else // RightCount must be >= 4
	{
		ClassSpecialization = m_strMostlyTag $ " " $ ClassTemplate.RightAbilityTreeTitle;
	}

	MC.BeginFunctionOp("addUnit");
	MC.QueueNumber(Index);
	MC.QueueString(Unit.GetName(eNameType_Rank));
	MC.QueueString(Unit.GetName(eNameType_Last));
	MC.QueueString(Unit.GetName(eNameType_Nick));
	MC.QueueString(Unit.GetSoldierClassTemplate().IconImage);
	MC.QueueString(class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName()));
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Unit.GetSoldierClassTemplate().DisplayName));
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ClassSpecialization));
	MC.QueueString("");// TODO we need head shot image
	MC.EndOp();
}

function RequestServerDataUpdate()
{
	DisplayProgressMessage("Requesting all Intervals from the server ...");
	m_arrIntervals.Length = 0; // Clear
	`CHALLENGEMODE_MGR.ClearChallengeData();
	ChallengeModeInterface.PerformChallengeModeGetIntervals();
}


//==============================================================================
//		HELPER FUNCTIONALITY:
//==============================================================================
function DisplayProgressMessage(string ProgressMessage)
{
	// Log for now:
	`log(ProgressMessage,,'XCom_Online');
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

function UpdateDisplay()
{
	MC.BeginFunctionOp("setHeaderData");
	MC.QueueString(m_strChallengeModeTitle);
	MC.QueueString( m_BattleData.m_strOpName);
	MC.EndOp();

	UpdateObjectives();
	UpdateSoldiers();
}

function UpdateData()
{
	CacheUpdate();
	UpdateDisplay();
}

function UpdateIntervalDropdown()
{
	local int Index, SelectedIdx;
	local string DropdownEntryStr;
	SelectedIdx = 0;
	m_IntervalDropdown.Clear(); // empty dropdown
	for( Index = 0; Index < m_arrIntervals.Length; ++Index )
	{
		//DropdownEntryStr = QWordToString(m_arrIntervals[Index].IntervalSeedID);
		DropdownEntryStr = m_arrIntervals[Index].IntervalName;
		DropdownEntryStr $= ": " $ `ShowEnum(EChallengeStateType, m_arrIntervals[Index].IntervalState, State);
		m_IntervalDropdown.AddItem(DropdownEntryStr, string(Index));
		if( m_arrIntervals[Index].IntervalSeedID == m_CurrentIntervalSeedID )
		{
			SelectedIdx = Index;
		}
	}
	m_IntervalDropdown.SetSelected( SelectedIdx );
}


//==============================================================================
//		STANDARD UI HANDLERS:
//==============================================================================
function OnButtonPress(UIButton Button)
{
	if (Button == m_BackButton)
	{
		OnCancel();
	}
	else if (Button == m_AcceptChallengeButton)
	{
		OnAccept();
	}
}

function OnAccept()
{
	// Start the mission
	GotoState('LaunchChallenge');
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

function IntervalDropdownSelectionChange(UIDropdown kDropdown)
{
	local int Idx;
	Idx = int(m_IntervalDropdown.GetSelectedItemData());
	m_CurrentIntervalSeedID = m_arrIntervals[Idx].IntervalSeedID;
	UpdateData();
}

//==============================================================================
//		DAILY CHALLENGE HANDLERS:
//==============================================================================
function OnReceivedChallengeModeIntervals(qword IntervalSeedID, int ExpirationDate, int TimeLength, EChallengeStateType IntervalState, optional string IntervalName, optional array<byte> StartState)
{
	local int Idx;
	`log(`location @ QWordToString(IntervalSeedID) @ `ShowVar(ExpirationDate) @ `ShowVar(TimeLength) @ `ShowEnum(EChallengeStateType, IntervalState, IntervalState) @ `ShowVar(IntervalName),,'XCom_Online');
	Idx = m_arrIntervals.Length;
	m_arrIntervals.Add(1);
	m_arrIntervals[Idx].IntervalSeedID = IntervalSeedID;
	m_arrIntervals[Idx].DateEnd.B = ExpirationDate;
	m_arrIntervals[Idx].TimeLimit = TimeLength;
	m_arrIntervals[Idx].IntervalState = IntervalState;
	m_arrIntervals[Idx].IntervalName = IntervalName;
	m_arrIntervals[Idx].StartState = StartState;

	UpdateIntervalDropdown();
	if (m_arrIntervals.Length == 1)
	{
		m_CurrentIntervalSeedID = IntervalSeedID;
		UpdateData();
	}
	DisplayProgressMessage("Received an Interval from the server. Total (" $ m_arrIntervals.Length $ ")");
}

function OnReceivedChallengeModeSeed(int LevelSeed, int PlayerSeed, int TimeLimit, qword StartTime, int GameScore)
{
	//Firaxis Live implementation does not use the function parameters here.

	//UpdateData();
	DisplayProgressMessage("Received Seed information from the server.");
}

function OnReceivedChallengeModeGetEventMapData(qword IntervalSeedID, int NumEvents, int NumTurns, array<INT> EventMap)
{
	`log(`location @ QWordToString(IntervalSeedID) @ `ShowVar(NumEvents) @ `ShowVar(NumTurns) @ `ShowVar(EventMap.Length),,'XCom_Online');
	OnlineEventMgr.m_ChallengeModeEventMap = EventMap;
	ChallengeModeManager.ResetAllData();
	DisplayProgressMessage("Done getting Event Data from the server.");
}

simulated event OnReceiveChallengeModeActionFinished(ICMS_Action Action, bool bSuccess)
{
	switch(Action)
	{
	case ICMS_GetSeed:
		UpdateData();
		break;
	case ICMS_GetEventMapData:
		DisplayProgressMessage("Event Data has been retrieved from the server.");
		break;
	default:
		break;
	}
}

//==============================================================================
//		STATES:
//==============================================================================
state LaunchChallenge
{
	function OnReceivedChallengeModeGetEventMapData(qword IntervalSeedID, int NumEvents, int NumTurns, array<INT> EventMap)
	{
		global.OnReceivedChallengeModeGetEventMapData(IntervalSeedID, NumEvents, NumTurns, EventMap);
		ChallengeModeInterface.PerformChallengeModeGetSeed(m_CurrentIntervalSeedID);
	}

	function OnReceivedChallengeModeSeed(int LevelSeed, int PlayerSeed, int TimeLimit, qword StartTime, int GameScore)
	{
		global.OnReceivedChallengeModeSeed(LevelSeed, PlayerSeed, TimeLimit, StartTime, GameScore);
		LoadTacticalMap();
	}

	function LoadTacticalMap()
	{
		`ONLINEEVENTMGR.bIsChallengeModeGame = true;
		Cleanup(); // Unregisters any delegates prior to the map change
		SetChallengeData();
		ConsoleCommand(m_BattleData.m_strMapCommand);
	}

	function SetChallengeData()
	{
		m_ChallengeData.SeedData.IntervalSeedID = m_CurrentIntervalSeedID;
		OnlineSub.PlayerInterface.GetUniquePlayerId(`ONLINEEVENTMGR.LocalUserIndex, m_ChallengeData.SeedData.PlayerID);
	}

Begin:
	// Get the latest Event Data from the server ...
	DisplayProgressMessage("Loading Event Data from the server ...");
	`CHALLENGEMODE_MGR.SetSelectedChallengeIndex(int(m_IntervalDropdown.GetSelectedItemData()));
	ChallengeModeInterface.PerformChallengeModeGetEventMapData(m_CurrentIntervalSeedID);
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

simulated function Cleanup()
{
	ChallengeModeInterface.ClearReceivedChallengeModeIntervalsDelegate(OnReceivedChallengeModeIntervals);
	ChallengeModeInterface.ClearReceivedChallengeModeSeedDelegate(OnReceivedChallengeModeSeed);
	ChallengeModeInterface.ClearReceivedChallengeModeGetEventMapDataDelegate(OnReceivedChallengeModeGetEventMapData);
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package   = "/ package/gfxDailyChallenge/DailyChallenge";
	MCName      = "theScreen";

	InputState= eInputState_Evaluate;
}