//---------------------------------------------------------------------------------------
//  FILE:    X2MissionSourceTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2MissionSourceTemplate extends X2StrategyElementTemplate;

var() bool						bIncreasesForceLevel;  // Does going on this mission increase the Alien's force level?
var() bool						bStart; // Is this the starting mission?
var() bool						bRequiresSkyrangerTravel;
var() bool						bGoldenPath; // Is this a story "golden path" mission?
var() bool						bChallengeMode; // Is this a challenge mode mission?
var() bool						bMultiplayer; // Is this a multiplayer mission?
var() bool						bAlienNetwork; // Is this an alien network mission?
var() bool						bShowRewardOnPin;
var() bool						bSkipRewardsRecap;
var() bool						bDisconnectRegionOnFail;
var() bool						bIntelHackRewards; // Does this mission allow the purchase of intel hack rewards?
var() bool						bIgnoreDifficultyCap; // Does this mission ignore the campaign difficulty cap?
var() int						DifficultyValue; // Used by GetMissionDifficulty, can add to other values, be used directly as the difficulty, etc.
var() string					OverworldMeshPath; // Used for its 3D map icon
var() string					MissionImage; // Image used for UIMission
var() name						ResistanceActivity; // Used for tracking resistance activites for the Monthly Report
var() array<RewardDeckEntry>    RewardDeck; // Some Calendar Missions use a reward deck (use this data to build the deck stored in calendar)
var() string					CustomLoadingMovieName_Intro; //A custom loading movie to play when entering the mission, include the extension of the movie file
var() string					CustomLoadingMovieName_IntroSound; //Wise event to play with the movie
var() string					CustomLoadingMovieName_Outro; //A custom loading movie to play when leaving the mission, include the extension of the movie file
var() string					CustomLoadingMovieName_OutroSound; //Wise event to play with the movie
var() name						CustomMusicSet; //Use to specify a particular music set from the available sets

// Doom Related Variables
var() config bool				bMakesDoom;
var() config int				MinStartingDoom;
var() config int				MaxStartingDoom;

// UFO
var() config int				SpawnUFOChance;

var localized String			MissionPinLabel;
var localized String			MissionFlavorText;
var localized String			BattleOpName;
var localized String			DoomLabel;
var localized String			MissionExpiredText;
var localized String			MissionLaunchWarningText; // Display in the popup warning the player about launching the mission with the current squad
var localized String			CannotLaunchMissionTooltip; // Tooltip if the mission cannot be launched for a specific reason

var Delegate<OnTriadSuccessDelegate> OnTriadSuccessFn;
var Delegate<OnTriadFailureDelegate> OnTriadFailureFn;
var Delegate<OnSuccessDelegate> OnSuccessFn;
var Delegate<OnFailureDelegate> OnFailureFn;
var Delegate<OnExpireDelegate>  OnExpireFn;
var Delegate<GetMissionDifficulty> GetMissionDifficultyFn;
var Delegate<GetMissionRewardString> GetMissionRewardStringFn;
var Delegate<CalculateDoomRemoval> CalculateDoomRemovalFn;
var Delegate<CalculateStartingDoom> CalculateStartingDoomFn;
var Delegate<GetOverworldMeshPath> GetOverworldMeshPathFn;
var Delegate<WasMissionSuccessful> WasMissionSuccessfulFn;
var Delegate<CanLaunchMissionDelegate> CanLaunchMissionFn; // Determine if the mission should be prevented from launching
var Delegate<RequireLaunchMissionPopupDelegate> RequireLaunchMissionPopupFn; // Determine if a popup should be shown before launching the mission

// Calendar Mission functions
var Delegate<CreateMissionsDelegate> CreateMissionsFn;
var Delegate<SpawnMissionsDelegate> SpawnMissionsFn;
var Delegate<MissionPopupDelegate> MissionPopupFn;

delegate OnTriadSuccessDelegate(XComGameState NewGameState, XComGameState_MissionSite MissionState);
delegate OnTriadFailureDelegate(XComGameState NewGameState, XComGameState_MissionSite MissionState);
delegate OnSuccessDelegate(XComGameState NewGameState, XComGameState_MissionSite MissionState);
delegate OnFailureDelegate(XComGameState NewGameState, XComGameState_MissionSite MissionState);
delegate OnExpireDelegate(XComGameState NewGameState, XComGameState_MissionSite MissionState);
delegate int GetMissionDifficulty(XComGameState_MissionSite MissionState);
delegate string GetMissionRewardString(XComGameState_MissionSite MissionState);
delegate CalculateDoomRemoval(XComGameState_MissionSite MissionState);
delegate int CalculateStartingDoom();
delegate string GetOverworldMeshPath(XComGameState_MissionSite MissionState);
delegate bool WasMissionSuccessful(XComGameState_BattleData BattleDataState);
delegate CreateMissionsDelegate(XComGameState NewGameState, int MissionMonthIndex);
delegate SpawnMissionsDelegate(XComGameState NewGameState, int MissionMonthIndex);
delegate MissionPopupDelegate();
delegate bool CanLaunchMissionDelegate(XComGameState_MissionSite MissionState);
delegate bool RequireLaunchMissionPopupDelegate(XComGameState_MissionSite MissionState);

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bShouldCreateDifficultyVariants = true
	bRequiresSkyrangerTravel = true
	CustomLoadingMovieName_IntroSound = "LoadingScreenVS_Propaganda" // fallback if a custom intro movie is specified but no sound is
}