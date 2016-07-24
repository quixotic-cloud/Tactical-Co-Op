//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeModeDataStructures.uc
//  AUTHOR:  Timothy Talley  --  02/13/2015
//  PURPOSE: Data Structures for all Challenge Mode services.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeModeDataStructures extends Object
	native(Core);


const CURRENT_INTERVAL_ID = -1;


// Used in ChallengeMode.ashx, update appropriately
enum ICMS_Action
{
	ICMS_None,
	ICMS_GetSeed,
	ICMS_ClearInterval,
	ICMS_ClearSubmitted,
	ICMS_ClearAll,
	ICMS_PostGameSave,
	ICMS_GetGameSave,
	ICMS_GetTopGameScores,
	ICMS_ValidateGameScore,
	ICMS_GetEventMapData,
	ICMS_PostEventMapData,
	ICMS_GetIntervals
};

// Used in ChallengeMode.ashx, update appropriately
enum EChallengeModeDataType
{
	ECMDT_SeedReturn,
	ECMDT_LeaderboardReturn,
	ECMDT_EventDataReturn,
	ECMDT_IntervalDataReturn
};

// Used in ChallengeMode.ashx, update appropriately
enum EChallengeModeErrorStatus
{
	CMES_None,
	CMES_Success,
	CMES_GameEntryExists,
	CMES_SeedNotStarted,
	CMES_TimeLimitExceeded
};

// Used in ChallengeMode.ashx, update appropriately
enum EChallengeModeEventType
{
	ECME_FirstXComKIA,
	ECME_FirstAlienKill,
	ECME_MissionObjectiveComplete,
	ECME_CommanderKIA,
	ECME_10EnemiesKIA,
	ECME_Placeholder6,
	ECME_Placeholder7,
	ECME_Placeholder8,
	ECME_Placeholder9,
	ECME_Placeholder10,
	ECME_Placeholder11,
	ECME_Placeholder12,
	ECME_Placeholder13,
	ECME_Placeholder14,
	ECME_Placeholder15,
	ECME_Placeholder16,
	ECME_Placeholder17,
	ECME_Placeholder18,
	ECME_Placeholder19,
	ECME_Placeholder20,
	ECME_Placeholder21,
	ECME_Placeholder22,
	ECME_Placeholder23,
	ECME_Placeholder24,
	ECME_Placeholder25,
	ECME_Placeholder26,
	ECME_Placeholder27,
	ECME_Placeholder28,
	ECME_Placeholder29,
	ECME_Placeholder30,
	ECME_Placeholder31,
	ECME_Placeholder32
};

// Used in ChallengeMode.ashx, update appropriately
struct native PostGameDataHeader
{
	var int		DataVersion;
	var int		DataCRC;
	var int		DataSize;
	var int		DataSeed;
	var float   DataRand;
};

// Used in ChallengeMode.ashx, update appropriately
struct native ChallengeModeResponseHeader
{
	var int ResponseType;
	var int ResponseSize;
};

// Used in ChallengeMode.ashx, update appropriately
struct native ChallengeModeGenericDataHeader
{
	var int DataVersion;
	var int DataType;
};

// Used in ChallengeMode.ashx, update appropriately
struct native ChallengeModeSeedData 
{
	var int DataVersion;
	var int DataType;
	var UniqueNetId PlayerID;
	var int PlayerSeed;
	var int IntervalSeedID;
	var int LevelSeed;
	var int TimeLimit;
	var qword StartTime;
	var qword EndTime;
	var int GameScore;
	var int VerifiedCount;
	var int PlayerNameSize;
	var int GameBlobSize;

	structdefaultproperties
	{
		DataVersion=1
		DataType=ECMDT_SeedReturn
	}
};

// Used in ChallengeMode.ashx, update appropriately
struct native ChallengeModeLeaderboardData 
{
	var int DataVersion;
	var int DataType;
	var int NumPlayers;

	structdefaultproperties
	{
		DataVersion=1
		DataType=ECMDT_LeaderboardReturn
	}
};

// Used in ChallengeMode.ashx, update appropriately
struct native ChallengeModeEventMap 
{
	var int DataVersion;
	var int DataType;
	var int IntervalSeedID;
	var int NumEvents;
	var int NumTurns;

	structdefaultproperties
	{
		DataVersion=1
		DataType=ECMDT_EventDataReturn
	}
};

// Used in my2KNotifications.h, update appropriately
enum ELoginState
{
	E2kLS_LoggedOut,
	E2kLS_LoggingIn,
	E2kLS_LoggedIn,
	E2kLS_Error
};

// Used in my2KNotifications.h, update from IChallengeNotify::StateType
// Used in ChallengeMode.ashx, update appropriately
enum EChallengeStateType
{
	ECST_Unknown, 
	ECST_Ready, 
	ECST_Started, 
	ECST_Submitted, 
	ECST_TimeExpired
};

// Used in ChallengeMode.ashx, update appropriately
struct native IntervalData
{
	var int DataVersion;
	var int DataType;
	var int ExpirationDate;
	var int TimeLength;
	var qword IntervalSeedID;
	var EChallengeStateType IntervalState;

	structdefaultproperties
	{
		DataVersion=1
		DataType=ECMDT_IntervalDataReturn
	}
};


//--------------------------------------------------------------------------------------- 
// Data Definitions
//
struct native SquadOptionInfo
{
	var string							SquadTemplateName;
	var int								Points;
	var bool							bAllowEditing;
	var bool							bAllowCommander;
};

struct native RewardInfo
{
	var string							RewardTemplateName;
	var string							RewardConditionName;
	var bool							bHidden;
};

struct native EventTracking
{
	var string							EventName;
	var array<int>						NumPlayersTriggered; // Each entry represents turn number
};

struct native IntervalInfo
{
	var qword						    IntervalSeedID;
	var int								LevelSeed;
	var int								TimeLimit;
	var qword							DateStart;  // Epoch Seconds UTC
	var qword							DateEnd;    // Epoch Seconds UTC
	var EChallengeStateType             IntervalState;
	var string                          IntervalName;
	var array<byte>                     StartState;
};

struct native FullSeedData
{
	var UniqueNetId                     PlayerID;
	var int								PlayerSeed;
	var qword							IntervalSeedID;
	var int								LevelSeed;
	var int								TimeLimit;
	var qword							StartTime;
	var qword							EndTime;
	var int								GameScore;
	var int								VerifiedCount;

	structcpptext
	{
		friend FArchive& operator<<(FArchive& Ar, FFullSeedData& T);
	}
};

struct native PlayerSeedInfo
{
	var FullSeedData			        SeedData;
	var array<byte>						GameData;
	var string							PlayerName;
	var bool							bValidated; // Local value, does not come from server.
	var bool							bLoaded;    // Local value, does not come from server.
};
