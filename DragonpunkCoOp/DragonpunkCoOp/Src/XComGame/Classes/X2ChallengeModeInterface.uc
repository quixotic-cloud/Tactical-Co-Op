//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeModeInterface.uc
//  AUTHOR:  Timothy Talley  --  02/03/2015
//  PURPOSE: Interface for all Challenge Mode services.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
interface X2ChallengeModeInterface
	dependson(X2ChallengeModeDataStructures);


//---------------------------------------------------------------------------------------
//  System Functionality
//---------------------------------------------------------------------------------------
function bool ChallengeModeInit();
function bool ChallengeModeShutdown();
function bool ChallengeModeLoadGameData(array<byte> GameData, optional int SaveGameID=-1);
function bool RequiresSystemLogin();
function string GetSystemLoginUIClassName();
function bool IsDebugMenuEnabled();


//---------------------------------------------------------------------------------------
//  Get Seed Intervals
//---------------------------------------------------------------------------------------
/**
 * Requests data on all of the intervals
 */
function bool PerformChallengeModeGetIntervals();

/**
 * Received when the Challenge Mode data has been read.
 * 
 */
delegate OnReceivedChallengeModeIntervals(qword IntervalSeedID, int ExpirationDate, int TimeLength, EChallengeStateType IntervalState, string IntervalName, array<byte> StartState);
`AddClearDelegatesPrototype(ReceivedChallengeModeIntervals);



//---------------------------------------------------------------------------------------
//  Get Seed
//---------------------------------------------------------------------------------------
/**
 * Requests the Challenge Mode Seed from the server for the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
function bool PerformChallengeModeGetSeed(qword IntervalSeedID);

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
`AddClearDelegatesPrototype(ReceivedChallengeModeSeed);



//---------------------------------------------------------------------------------------
//  Get Challenge Mode Leaderboard
//---------------------------------------------------------------------------------------
/**
 * Requests the Leaderboard from the server
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
function bool PerformChallengeModeGetTopGameScores(qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been download and processing is ready to occur.
 * 
 * @param NumEntries, total number of board entries to expect
 */
delegate OnReceivedChallengeModeLeaderboardStart(int NumEntries, qword IntervalSeedID);
`AddClearDelegatesPrototype(ReceivedChallengeModeLeaderboardStart);


/**
 * Called once all of the leaderboard entries have been processed
 */
delegate OnReceivedChallengeModeLeaderboardEnd(qword IntervalSeedID);
`AddClearDelegatesPrototype(ReceivedChallengeModeLeaderboardEnd);


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
`AddClearDelegatesPrototype(ReceivedChallengeModeLeaderboardEntry);



//---------------------------------------------------------------------------------------
//  Get Event Map
//---------------------------------------------------------------------------------------
/**
 * Requests the Event Map Data for the challenge over the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
function bool PerformChallengeModeGetEventMapData(qword IntervalSeedID);

/**
 * Received when the Event Map data has been read.
 * 
 * @param IntervalSeedID, The associated Interval for the data
 * @param NumEvents, Number of registered events in the map data
 * @param NumTurns, Total number of moves per event
 * @param EventMap, Any array of integers representing the number of players that have completed the event, which is looked-up by index of EventType x TurnOccurred.
 */
delegate OnReceivedChallengeModeGetEventMapData(qword IntervalSeedID, int NumEvents, int NumTurns, array<INT> EventMap);
`AddClearDelegatesPrototype(ReceivedChallengeModeGetEventMapData);



//---------------------------------------------------------------------------------------
//  Post Event Map
//---------------------------------------------------------------------------------------
/**
 * Submits all of the Event results for the played challenge
 */
function bool PerformChallengeModePostEventMapData();

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModePostEventMapData(qword IntervalSeedID, bool bSuccess);
`AddClearDelegatesPrototype(ReceivedChallengeModePostEventMapData);



//---------------------------------------------------------------------------------------
//  Clear Interval - Admin Server Request
//---------------------------------------------------------------------------------------
/**
 * Clears all of the submitted and attempted Challenge Results over the specified interval
 * 
 * @param IntervalSeedID, defaults to the current interval
 */
function bool PerformChallengeModeClearInterval(qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearInterval(qword IntervalSeedID, bool bSuccess);
`AddClearDelegatesPrototype(ReceivedChallengeModeClearInterval);



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
function bool PerformChallengeModeClearSubmitted(UniqueNetId PlayerID, qword IntervalSeedID);

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, ID for the Interval that was cleared of all game submitted / attempted
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearSubmitted(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess);
`AddClearDelegatesPrototype(ReceivedChallengeModeClearSubmitted);



//---------------------------------------------------------------------------------------
//  Clear All - Admin Server Requests
//---------------------------------------------------------------------------------------
/**
 * Performs a full clearing of all user generated data.
 *
 */
function bool PerformChallengeModeClearAll();

/**
 * Received when the Challenge Mode data has been read.
 * 
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeClearAll(bool bSuccess);
`AddClearDelegatesPrototype(ReceivedChallengeModeClearAll);



//---------------------------------------------------------------------------------------
//  Get Game Save
//---------------------------------------------------------------------------------------
/**
 * Retrieves the stored save of the submitted game for the specified player and interval
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, Any known Interval call GetCurrentIntervalID() for a default ID
 */
function bool PerformChallengeModeGetGameSave(UniqueNetId PlayerID, qword IntervalSeedID);

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
`AddClearDelegatesPrototype(ReceivedChallengeModeGetGameSave);



//---------------------------------------------------------------------------------------
//  Post Game Save
//---------------------------------------------------------------------------------------
/**
 * Submits the completed Challenge game to the server for validation and scoring
 * 
 */
function bool PerformChallengeModePostGameSave();

/**
 * Response for the posting of completed game
 * 
 * @param Status, Response from the server
 */
delegate OnReceivedChallengeModePostGameSave(EChallengeModeErrorStatus Status);
`AddClearDelegatesPrototype(ReceivedChallengeModePostGameSave);



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
function bool PerformChallengeModeValidateGameScore(UniqueNetId PlayerID, int LevelSeed, int PlayerSeed, int TimeLimit, int GameScore, array<byte> GameData);

/**
 * Response for validating a game score
 * 
 * @param PlayerId, Unique Identifier for the particular player
 * @param IntervalSeedID, Specifies the entry's leaderboard (since there may be multiple days worth of leaderboards)
 * @param bSuccess, was the read successful.
 */
delegate OnReceivedChallengeModeValidateGameScore(UniqueNetId PlayerID, qword IntervalSeedID, bool bSuccess);
`AddClearDelegatesPrototype(ReceivedChallengeModeValidateGameScore);



//---------------------------------------------------------------------------------------
//  General Action
//---------------------------------------------------------------------------------------
//function bool PerformChallengeModeAction(UniqueNetId PlayerID, ICMS_Action Action=ICMS_GetSeed, qword IntervalSeedID);

///**
// * Callback whenever there is a response from the server for any reason.
// * 
// * @param Action, the type of action that the server was trying to perform
// * @param bSuccess, was the server able to perform the action
// */
//delegate OnReceivedChallengeModeActionFinished(ICMS_Action Action, bool bSuccess);
//`AddClearDelegatesPrototype(ReceivedChallengeModeActionFinished);



