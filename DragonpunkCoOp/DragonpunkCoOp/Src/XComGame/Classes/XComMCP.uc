class XComMCP extends MCPBase
	implements(X2ChallengeModeInterface)
	dependson(XComMCPTypes, X2ChallengeModeDataStructures)
	config(Game)
	native;

`define CRLF	chr(13)$chr(10)
`define TAB	    chr(9)
`define TAB2	chr(9)$chr(9)
`define TAB3	chr(9)$chr(9)$chr(9)
`define TAB4	chr(9)$chr(9)$chr(9)$chr(9)


// Templates (URL, Timeout, etc) for each kind of request, from Game INI
var array<MCPEventRequest> EventItems;

// Requests currently in flight
var const array<MCPEventRequest> ActiveRequests;

var bool bEnableMcpService;
var bool McpStatsDisableReporting;

var private native transient Array_Mirror KeyCountEntries{TArray<FKeyCountsEntry>};
var private native transient Array_Mirror MetricEntries{TArray<FKeyCountsEntry>};

var private transient string StringBlob;
var private transient bool Tracking;

var localized string ServiceNotAvailable;

//---------------------------------------------
// Challenge Mode Variables
`DeclearAddClearDelegatesArray(ReceivedChallengeModeIntervals);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeSeed);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeLeaderboardStart);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeLeaderboardEnd);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeLeaderboardEntry);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeGetEventMapData);
`DeclearAddClearDelegatesArray(ReceivedChallengeModePostEventMapData);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeClearInterval);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeClearSubmitted);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeClearAll);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeGetGameSave);
`DeclearAddClearDelegatesArray(ReceivedChallengeModePostGameSave);
`DeclearAddClearDelegatesArray(ReceivedChallengeModeValidateGameScore);



//---------------------------------------------
// Cached online subsystem interface variables
var Onlinesubsystem	    OnlineSub;

var privatewrite array<XComMCPEventListener>    EventListeners;
var privatewrite EMCPInitStatus                 eInitStatus;

cpptext
{
	virtual void Tick(FLOAT DeltaTime);
	virtual UBOOL IsTickable() const;

	inline FMCPEventRequest* FindEventTemplate(BYTE eventType)
	{
		for (INT index = 0; index < EventItems.Num(); index++)
		{
			if (EventItems(index).EventType == eventType)
			{
				return &EventItems(index);
			}
		}
		return NULL;
	}

	void BindInstance();

	FString CollectPlayerSignature(int iControllerID);

	public:
		UBOOL EncryptData(const BYTE* source, INT Count, TArray<BYTE>& dest, const BYTE* EncryptionKey);
		UBOOL DecryptData(const TArray<BYTE>& source, TArray<BYTE>& dest, const BYTE* EncryptionKey);

    protected:
		void ProcessCompletedEvent(const FMCPEventRequest &Event, const FString& Buffer);
		void ProcessFailedEvent(FMCPEventRequest &Event);
		UBOOL QueryServer(BYTE EventType, const FString& Options, const FString& Body, BYTE InRequestType, UBOOL Force = FALSE);
		UBOOL QueryServer(BYTE EventType, const FString& Options, const TArray<BYTE>& Body, BYTE InRequestType, UBOOL Force = FALSE);

		void StringToByteArray(TArray<BYTE>& dest, const FString& source);
		FString FlushKeyCounts();
		void AddMemoryBlock(int Type);

		UBOOL PerformChallengeModeAction(FUniqueNetId PlayerID, BYTE Action, QWORD IntervalSeedID);

		INT ProcessChallengeModeSeedData(BYTE* Buffer);
		INT ProcessChallengeModeLeaderboardEntry(BYTE* Buffer);
		INT ProcessChallengeModeLeaderboardData(BYTE* Buffer);
		INT ProcessChallengeModeGetGameSaveData(BYTE* Buffer);
		INT ProcessChallengeModePostGameSaveData(BYTE* Buffer);
		INT ProcessChallengeModeValidateData(BYTE* Buffer);
		INT ProcessChallengeModeGetEventMapData(BYTE* Buffer);
		INT ProcessChallengeModePostEventMapData(BYTE* Buffer);
		INT ProcessChallengeModeClearIntervalData(BYTE* Buffer);
		INT ProcessChallengeModeClearSubmittedData(BYTE* Buffer);
		INT ProcessChallengeModeClearAllData(BYTE* Buffer);
}

//---------------------------------------------

native function Init(bool bLoggedIntoOnlineProfile);

function AddEventListener(XComMCPEventListener Listener)
{
	if(EventListeners.Find(Listener) == -1)
	{
		EventListeners.AddItem(Listener);
	}
}

function RemoveEventListener(XComMCPEventListener Listener)
{
	EventListeners.RemoveItem(Listener);
}

event NotifyNotifyMCPInitialized()
{
	local XComMCPEventListener Listener;
	foreach EventListeners(Listener)
	{
		Listener.OnMCPInitialized(eInitStatus);
	}
}

native function bool GetINIFromServer(string INIFilename);
event NotifyGetINIFromServerCompleted(bool bSuccess, string INIFilename, string INIContents)
{
	local XComMCPEventListener Listener;
	foreach EventListeners(Listener)
	{
		Listener.OnGetINIFromServerCompleted(bSuccess, INIFilename, INIContents);
	}
}

native function string CheckWhiteList(int iControllerID);

static native function AddKeyCount(string Key, int Value, int Type);

static private native function int GetPlayerUID(string PlayerName, string Ident);

static private native function SetSPPlayerUID(int uid);
static private native function int GetSPPlayerUID();

static private native function SnapshotMemory();

static private native function GameTrack();
static private native function GameAddData(string XmlData);
static private native function GameTrackEnd();

static private native function PostMemoryStats(string MissionName);

static native function int GetPlatform();
static native function string GetCurrentUTCTime();
static native function float GetMemoryUsage();

static private native function float GetInitMem();
static private native function float GetPeakMem();
static native function string GetBaseURL();

static native function SetMetricValue(string Key, int Value);
static native function PostMetricValues();


static function StartMatchSP(string MapName, XGPlayer kPlayer, XGPlayer kAi)
{
//	local string XmlData, PlayerName;
//	local int uid, LoadoutID;

//	XmlData = "<session map=\""$MapName$"\" platform=\""$GetPlatform()$"\" ismulti=\"false\"";
//	XmlData @= "date=\""$GetCurrentUTCTime()$"\" >"$`CRLF;

//	GameTrack();
//	GameAddData(XmlData);
	
//	PlayerName = LocalPlayer(kPlayer.GetALocalPlayerController().Player).GetNickname();
//	uid = GetPlayerUID(PlayerName, "");
//	SetSPPlayerUID(uid);
//	LoadoutID = 0;

//	AddMatchPlayerSP(kPlayer, PlayerName, uid, LoadoutID);
//	AddMatchPlayerSP(kAi, "CPU", 1, LoadoutID);

//	SnapshotMemory();
}

static function EndMatchSP()
{
//	local string XmlData;
//	local int uid;

//	if (XGBattle_SP(`BATTLE).IsVictory(false))
//	{
//		uid = GetSPPlayerUID();
//	}
//	else
//	{
//		uid = 1;
//	}

//	XmlData = "<result winner=\""$uid$"\" imem=\""$GetInitMem()$"\" pmem=\""$GetPeakMem()$"\" />"$`CRLF;

//	GameAddData(XmlData);
//	GameTrackEnd();
	//SubmitRecapStats(`ONLINEEVENTMGR.GetCurrentGame(), `BATTLE.GetStats(), EDifficultyLevel( `BATTLE.GetDifficulty() ), `BATTLE.DidYouWin(), false);
	PostMemoryStats(XGBattle_SP(`BATTLE).GetDesc().MapData.PlotMapName);
}

native protected function EventCompleted(bool bWasSuccessful, EOnlineEventType EventType);

delegate OnEventCompleted(bool bWasSuccessful, EOnlineEventType EventType)
{
	EventCompleted(bWasSuccessful, eventType);
}

native function bool PingMCP(delegate<OnEventCompleted> dOnPingCompleted);

native function UploadPlayerInfo(byte LocalUserNum);


function OnReadProfileSettingsCompleteDelegate(byte LocalUserNum, EStorageResult eResult)
{
	UploadPlayerInfo(LocalUserNum);
}

function OnWriteProfileSettingsCompleteDelegate(byte LocalUserNum, bool bWasSuccessful)
{
	UploadPlayerInfo(LocalUserNum);
}

function OnReadPlayerStorageCompleteDelegate(byte LocalUserNum, EStorageResult eResult)
{
	UploadPlayerInfo(LocalUserNum);
}

function OnWritePlayerStorageCompleteDelegate(byte LocalUserNum, bool bWasSuccessful)
{
	UploadPlayerInfo(LocalUserNum);
}

event FinishInit()
{
	local int iUserNum, iMaxUserNum;
	iMaxUserNum = 1;
	if (class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360))
	{
		iMaxUserNum = 4;
	}
	for (iUserNum = 0; iUserNum < iMaxUserNum; ++iUserNum)
	{
		//Player Profile
		OnlineSub.PlayerInterface.AddReadProfileSettingsCompleteDelegate(iUserNum, OnReadProfileSettingsCompleteDelegate);
		OnlineSub.PlayerInterface.AddWriteProfileSettingsCompleteDelegate(iUserNum, OnWriteProfileSettingsCompleteDelegate);
		OnlineSub.PlayerInterface.AddReadPlayerStorageCompleteDelegate(iUserNum, OnReadPlayerStorageCompleteDelegate);
		OnlineSub.PlayerInterface.AddWritePlayerStorageCompleteDelegate(iUserNum, OnWritePlayerStorageCompleteDelegate);
	}
}

//---------------------------------------------------------------------------//
//
// Challenge Mode Interface Implementation
//
//---------------------------------------------------------------------------//

//---------------------------------------------------------------------------------------
//  System Functionality
//---------------------------------------------------------------------------------------
function bool ChallengeModeInit()
{
	return true;
}

function bool ChallengeModeShutdown()
{
	// Clear out all Delegates!
	`ClearDelegatesArray(ReceivedChallengeModeIntervals);
	`ClearDelegatesArray(ReceivedChallengeModeSeed);
	`ClearDelegatesArray(ReceivedChallengeModeLeaderboardStart);
	`ClearDelegatesArray(ReceivedChallengeModeLeaderboardEnd);
	`ClearDelegatesArray(ReceivedChallengeModeLeaderboardEntry);
	`ClearDelegatesArray(ReceivedChallengeModeGetEventMapData);
	`ClearDelegatesArray(ReceivedChallengeModePostEventMapData);
	`ClearDelegatesArray(ReceivedChallengeModeClearInterval);
	`ClearDelegatesArray(ReceivedChallengeModeClearSubmitted);
	`ClearDelegatesArray(ReceivedChallengeModeClearAll);
	`ClearDelegatesArray(ReceivedChallengeModeGetGameSave);
	`ClearDelegatesArray(ReceivedChallengeModePostGameSave);
	`ClearDelegatesArray(ReceivedChallengeModeValidateGameScore);
	return true;
}

native function bool ChallengeModeLoadGameData(array<byte> GameData, optional int SaveGameID=-1);

function bool RequiresSystemLogin()
{
	return false;
}

static function string GetSystemLoginUIClassName()
{
	return "";
}

static function bool IsDebugMenuEnabled()
{
	return true;
}

//---------------------------------------------------------------------------------------
//  Get Seed Intervals
//---------------------------------------------------------------------------------------
/**
 * Requests data on all of the intervals
 */
native function bool PerformChallengeModeGetIntervals();

/**
 * Received when the Challenge Mode data has been read.
 * 
 */
delegate OnReceivedChallengeModeIntervals(qword IntervalSeedID, int ExpirationDate, int TimeLength, EChallengeStateType IntervalState, string IntervalName, array<byte> StartState);
`AddClearDelegates(ReceivedChallengeModeIntervals);



//---------------------------------------------------------------------------------------
//  Get Seed
//---------------------------------------------------------------------------------------
/**
 * Requests the Challenge Mode Seed from the server for the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeGetSeed(qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param LevelSeed, seed shared among all challengers to populate the map, aliens, etc.
 * @param PlayerSeed, seed specific to the player to randomize the shots so they are unable to "plan" via YouTube.
 * @param TimeLimit, amount of time before the seed expires.
 * @param StartTime, amount of time in seconds from Epoch to when the Seed was distributed the first time.
 * @param GameScore, positive values indicate the final result of a finished interval.
 */
delegate OnReceivedChallengeModeSeed(int LevelSeed, int PlayerSeed, int TimeLimit, qword StartTime, int GameScore);
`AddClearDelegates(ReceivedChallengeModeSeed);



//---------------------------------------------------------------------------------------
//  Get Challenge Mode Leaderboard
//---------------------------------------------------------------------------------------
/**
 * Requests the Leaderboard from the server
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeGetTopGameScores(qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been download and processing is ready to occur.
 * 
 * @param NumEntries, total number of board entries to expect
 */
delegate OnReceivedChallengeModeLeaderboardStart(int NumEntries, qword IntervalSeedID);
`AddClearDelegates(ReceivedChallengeModeLeaderboardStart);


/**
 * Called once all of the leaderboard entries have been processed
 */
delegate OnReceivedChallengeModeLeaderboardEnd(qword IntervalSeedID);
`AddClearDelegates(ReceivedChallengeModeLeaderboardEnd);


/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param PlayerName, Name to show on the leaderboard
 * @param IntervalSeedID, Specifies the entry's leaderboard (since there may be multiple days worth of leaderboards)
 * @param GameScore, Value of the entry
 * @param TimeStart, Epoch time in UTC whenever the player first started the challenge
 * @param TimeEnd, Epoch time in UTC whenever the player finished the challenge
 */
delegate OnReceivedChallengeModeLeaderboardEntry(UniqueNetId PlayerID, string PlayerName, qword IntervalSeedID, int GameScore, qword TimeStart, qword TimeEnd);
`AddClearDelegates(ReceivedChallengeModeLeaderboardEntry);



//---------------------------------------------------------------------------------------
//  Get Event Map
//---------------------------------------------------------------------------------------
/**
 * Requests the Event Map Data for the challenge over the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeGetEventMapData(qword IntervalSeedID);

/**
 * Received when the Event Map data has been read.
 * 
 * @param IntervalSeedID, The associated Interval for the data
 * @param NumEvents, Number of registered events in the map data
 * @param NumTurns, Total number of moves per event
 * @param EventMap, Any array of integers representing the number of players that have completed the event, which is looked-up by index of EventType x TurnOccurred.
 */
delegate OnReceivedChallengeModeGetEventMapData(qword IntervalSeedID, int NumEvents, int NumTurns, array<INT> EventMap);
`AddClearDelegates(ReceivedChallengeModeGetEventMapData);



//---------------------------------------------------------------------------------------
//  Post Event Map
//---------------------------------------------------------------------------------------
/**
 * Submits all of the Event results for the played challenge
 */
native function bool PerformChallengeModePostEventMapData();

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModePostEventMapData(qword IntervalSeedID, bool bSuccess);
`AddClearDelegates(ReceivedChallengeModePostEventMapData);



//---------------------------------------------------------------------------------------
//  Clear Interval - Admin Server Request
//---------------------------------------------------------------------------------------
/**
 * Clears all of the submitted and attempted Challenge Results over the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeClearInterval(qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearInterval(qword IntervalSeedID, bool bSuccess);
`AddClearDelegates(ReceivedChallengeModeClearInterval);



//---------------------------------------------------------------------------------------
//  Clear Submitted - Admin Server Requests
//---------------------------------------------------------------------------------------
/**
 * Clears all of the submitted and attempted Challenge Results over the specified interval 
 * for only the specified player.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeClearSubmitted(UniqueNetId PlayerID, qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearSubmitted(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess);
`AddClearDelegates(ReceivedChallengeModeClearSubmitted);



//---------------------------------------------------------------------------------------
//  Clear All - Admin Server Requests
//---------------------------------------------------------------------------------------
/**
 * Performs a full clearing of all user generated data.
 *
 */
native function bool PerformChallengeModeClearAll();

/**
 * Called whenever all the data is cleared
 * 
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearAll(bool bSuccess);
`AddClearDelegates(ReceivedChallengeModeClearAll);



//---------------------------------------------------------------------------------------
//  Get Game Save
//---------------------------------------------------------------------------------------
/**
 * Retrieves the stored save of the submitted game for the specified player and interval
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, defaults to the current interval
 */
native function bool PerformChallengeModeGetGameSave(UniqueNetId PlayerID, qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param PlayerName, Name to show on the leaderboard
 * @param IntervalSeedID, Specifies the entry's leaderboard (since there may be multiple days worth of leaderboards)
 * @param LevelSeed, Seed used for the level generation
 * @param PlayerSeed, Seed specific for that player
 * @param TimeLimit, Time allowed to play the level
 * @param GameScore, Value of the entry
 * @param TimeStart, Epoch time in UTC whenever the player first started the challenge
 * @param TimeEnd, Epoch time in UTC whenever the player finished the challenge
 * @param GameData, History data for replay / validation
 */
delegate OnReceivedChallengeModeGetGameSave(UniqueNetId PlayerID, string PlayerName, qword IntervalSeedID, int LevelSeed, int PlayerSeed, int TimeLimit, int GameScore, qword TimeStart, qword TimeEnd, array<byte> GameData);
`AddClearDelegates(ReceivedChallengeModeGetGameSave);



//---------------------------------------------------------------------------------------
//  Post Game Save
//---------------------------------------------------------------------------------------
/**
 * Submits the completed Challenge game to the server for validation and scoring
 * 
 */
native function bool PerformChallengeModePostGameSave();

/**
 * Response for the posting of completed game
 * 
 * @param Status, Response from the server
 */
delegate OnReceivedChallengeModePostGameSave(EChallengeModeErrorStatus Status);
`AddClearDelegates(ReceivedChallengeModePostGameSave);



//---------------------------------------------------------------------------------------
//  Validate Game Score
//---------------------------------------------------------------------------------------
/**
 * Processes the loaded game for validity and submits the score to the server as a 
 * validated score.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param LevelSeed, Seed used for the level generation
 * @param PlayerSeed, Seed specific for that player
 * @param TimeLimit, Time allowed to play the level
 * @param GameScore, Value of the entry
 * @param GameData, History data for replay / validation
 */
native function bool PerformChallengeModeValidateGameScore(UniqueNetId PlayerID, int LevelSeed, int PlayerSeed, int TimeLimit, int GameScore, array<byte> GameData);

/**
 * Response for validating a game score
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, Specifies the entry's leaderboard (since there may be multiple days worth of leaderboards)
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeValidateGameScore(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess);
`AddClearDelegates(ReceivedChallengeModeValidateGameScore);



defaultproperties
{
	eInitStatus=EMCPIS_NotInitialized;
	bEnableMcpService=true
	McpStatsDisableReporting=false

	EventItems(0)=(EventUrl="Auth.ashx",EventType=EOET_Auth,TimeOut=10.0)
	EventItems(1)=(EventUrl="Recap.ashx",EventType=EOET_Recap,TimeOut=10.0)
	EventItems(2)=(EventUrl="Global.ashx",EventType=EOET_GetRecap,TimeOut=10.0)
	EventItems(3)=(EventUrl="Dict.ashx",EventType=EOET_GetDict,TimeOut=30.0)
	EventItems(4)=(EventUrl="Ping.ashx",EventType=EOET_PingMCP,TimeOut=4.0,bResultIsCached=false)
	EventItems(5)=(EventUrl="PlayerInfo.ashx",EventType=EOET_PlayerInfo,TimeOut=10.0,bResultIsCached=false)
	EventItems(6)=(EventUrl="MissionInfo.ashx",EventType=EOET_MissionInfo,TimeOut=10.0,bResultIsCached=false)
	EventItems(7)=(EventUrl="ChallengeMode.ashx",EventType=EOET_ChallengeMode,TimeOut=30.0,bResultIsCached=false)
}
