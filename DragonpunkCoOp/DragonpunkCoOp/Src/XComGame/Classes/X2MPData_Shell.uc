//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPData_Shell.uc
//  AUTHOR:  Todd Smith  --  7/8/2015
//  PURPOSE: static/localized data used by the multiplayer shell
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPData_Shell extends Object
	dependson(X2MPData_Common)
	config(MPGame);

enum EMPLeaderboardType
{
	eMPLeaderboard_TopPlayers,
	eMPLeaderboard_YourRank,
	eMPLeaderboard_Friends
};
enum EMPLeaderboardRange
{
	eMP_LR_AllTime,
	eMP_LR_Monthly,
	eMP_LR_Weekly
};

struct TX2UIMaxSquadCostData
{
	var string strText;
	var int iCost;
};

struct TX2UITurnTimerData
{
	var string strText;
	var int iTurnTime;
};

struct TX2UILobbyTypeData
{
	var string strText;
	var EMPNetworkType iLobbyType;
};

struct TX2UIMapTypeData
{
	var string strText;
	var string strPlotType;
	var array<string> arrValidBiomes;
	var MultiplayerPlotIndex FriendlyNameIndex;
	var array<MultiplayerBiomeIndex> ValidBiomeFriendlyNames;
};

 // SERVER BROWSER
struct TServerInfo
{
	var string strHost;
	var string strMapPlotType;
	var string strMapBiomeType;
	var string strPoints;
	var string strTurnTime;
	var int    iPing;
	var int    iOnlineGameSearchResultIndex;
	
	structdefaultproperties
	{
		iPing = -1;
		iOnlineGameSearchResultIndex = -1;
	}
};
struct TServerBrowserData
{
	var string strTitle;
	var string strStatusLabel;
	var array<TServerInfo> arrServers;
};
// Used by XComShellGRI and UIUtilities to obtain the "Any" map image
const ANY_MAP_NAME = "ANY";
// LEADERBOARDS
struct TLeaderboardEntry
{
	var string strPlayerName;
	var int iRank;
	var int iWins;
	var int iLosses;
	var int iDisconnects;
	var UniqueNetId playerID;
};
struct TLeaderboardsData
{
	var EMPLeaderboardType       eLeaderboardType;
	var EMPLeaderboardRange      eLeaderboardRange;
	var int                      iSelectedIndex;
	var int                      iMaxResults;       // Total results across any/all pages (that will be loaded)
	var string                   strStatusLabel;
	var array<TLeaderboardEntry> arrResults;
	var bool                     bFetching;
	var float                    fLastFetchTime;
	structdefaultproperties
	{
		eLeaderboardType = eMPLeaderboard_TopPlayers;
		eLeaderboardRange = eMP_LR_AllTime;
		bFetching = false;
		fLastFetchTime = 0;
		iMaxResults = 0;
	}
};

const LEADERBOARD_REFRESH_TIME = 1.0f;

var config array<int>                           m_arrMaxSquadCosts;
var config array<int>                           m_arrTurnTimers;

// LOCALIZED STRINGS
//------------------------------------------------------------------------------

// MULTIPLAYER SHELL
var localized string							m_strMPMainMenuTitle;
var localized string							m_strMPSubMenuTitle;

// CUSTOM MATCH
var localized string							m_strMPCustomMatchAnyString;
var localized string							m_strMPCustomMatchInfinitePointsString;
var localized string							m_strMPCustomMatchInfiniteTurnTimeString;
var localized string							m_strMPCustomMatchHostTitle;
var localized string							m_strMPCustomMatchSearchTitle;

var localized string							m_strMPCustomMatchTimerValue;

// SERVER BROWSER
var localized string							m_strMPSearcingForGamesProgressDialogTitle;
var localized string							m_strMPSearcingForGamesProgressDialogText;
var localized string							m_strMPCancelSearchProgressDialogTitle;
var localized string							m_strMPCancelSearchProgressDialogText;
var localized string							m_strMPJoiningGameProgressDialogTitle;
var localized string							m_strMPJoiningGameProgressDialogText;

var localized string							m_strMPServerBrowserTitle;
var localized string							m_strMPServerBrowserSearchInProgressLabel;
var localized string							m_strMPServerBrowserNoServersFoundLabel;

// MAPS
var localized array<String> arrMPMapFriendlyNames;
var localized array<String> arrMPBiomeFriendlyNames;

// LEADERBOARDS
var localized string							m_strMPLeaderboardsSearchInProgressLabel;
var localized string							m_strMPLeaderboardsNoResultsFoundLabel;

var localized string							m_strMPFetchingLeaderboardsProgressDialogTitle;
var localized string							m_strMPFetchingLeaderboardsProgressDialogText;

// ONLINE INFORMATIO							
var localized string							m_strOnlineLoginFailedDialog_Default_Title;
var localized string							m_strOnlineLoginFailedDialog_Default_Text;
var localized string							m_strOnlineLoginFailedDialog_XBOX_Text;
var localized string							m_strOnlineLoginFailedDialog_PS3_Text;
var localized string							m_strOnlineLoginFailedDialog_ButtonText;
var localized string							m_strOnlinePlayPermissionFailedDialog_Default_Title;
var localized string							m_strOnlinePlayPermissionFailedDialog_Default_Text;
var localized string							m_strOnlinePlayPermissionFailedDialog_XBOX_Title;
var localized string							m_strOnlinePlayPermissionFailedDialog_XBOX_Text;
var localized string							m_strOnlinePlayPermissionFailedDialog_PS3_Text;
var localized string							m_strOnlinePlayPermissionFailedDialog_ButtonText;
var localized string							m_strOnlineConnectionFailedDialog_Default_Title;
var localized string							m_strOnlineConnectionFailedDialog_Default_Text;
var localized string							m_strOnlineConnectionFailedDialog_XBOX_Title;
var localized string							m_strOnlineConnectionFailedDialog_XBOX_Text;
var localized string							m_strOnlineConnectionFailedDialog_ButtonText;
var localized string							m_strOnlineNoNetworkConnectionDialog_Default_Title;
var localized string							m_strOnlineNoNetworkConnectionDialog_Default_Text;
var localized string							m_strOnlineNoNetworkConnectionDialog_XBOX_Title;
var localized string							m_strOnlineNoNetworkConnectionDialog_XBOX_Text;
var localized string							m_strOnlineNoNetworkConnectionDialog_PS3_Title;
var localized string							m_strOnlineNoNetworkConnectionDialog_PS3_Text;
var localized string							m_strOnlineNoNetworkConnectionDialog_ButtonText;
var localized string							m_strOnlineChatPermissionFailedDialog_Default_Title;
var localized string							m_strOnlineChatPermissionFailedDialog_PS3_Title;
var localized string							m_strOnlineChatPermissionFailedDialog_Default_Text;
var localized string							m_strOnlineChatPermissionFailedDialog_XBOX_Text;
var localized string							m_strOnlineChatPermissionFailedDialog_PS3_Text;
var localized string							m_strOnlineChatPermissionFailedDialog_ButtonText;

var localized string                            m_strPoints;

var localized string                            m_arrGameTypeNames[EMPGameType.EnumCount];
var localized string                            m_arrNetworkTypeNames[EMPNetworkType.EnumCount];
var localized string							m_strOnlineRankedAutomatchFailed_Title;
var localized string							m_strOnlineRankedAutomatchFailed_Text;
var localized string							m_strOnlineRankedAutomatchFailed_ButtonText;
var localized string							m_strOnlineUnrankedAutomatchFailed_Title;
var localized string							m_strOnlineUnrankedAutomatchFailed_Text;
var localized string							m_strOnlineUnrankedAutomatchFailed_ButtonText;
var localized string							m_strOnlineReadRankedStatsFailed_Title;
var localized string							m_strOnlineReadRankedStatsFailed_Text;
var localized string							m_strOnlineReadRankedStatsFailed_ButtonText;
var localized string							m_strOnlineReadRankedStats_Text;
var localized string							m_strOnlineSearchForRankedAutomatch_Title;
var localized string							m_strOnlineSearchForRankedAutomatch_Text;
var localized string							m_strOnlineSearchForUnrankedAutomatch_Title;
var localized string							m_strOnlineSearchForUnrankedAutomatch_Text;
var localized string							m_strOnlineCancelCreateOnlineGame_Title;
var localized string							m_strOnlineCancelCreateLANGame_Title;
var localized string							m_strOnlineCancelCreateSystemLinkGame_Title;
var localized string							m_strOnlineCancelCreateOnlineGame_Text;
var localized string							m_strOnlineCancelCreateOnlineGame_ButtonText;
var localized string							m_strSelectSaveDeviceForEditSquadPrompt;
var localized string                            m_strRankedMatch;
var localized string                            m_strUnrankedMatch;
var localized string                            m_strSaveLoadout;