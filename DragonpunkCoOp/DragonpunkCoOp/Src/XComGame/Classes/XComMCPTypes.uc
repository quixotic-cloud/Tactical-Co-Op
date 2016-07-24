//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMCPTypes.uc
//  AUTHOR:  Todd Smith  --  2/20/2012
//  PURPOSE: defines types used by the MCP system to avoid circular script file dependencies
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComMCPTypes extends Object
	native;


enum EMCPInitStatus
{
	EMCPIS_NotInitialized,
	EMCPIS_Success,
	EMCPIS_DisabledByCommandLine,
	EMCPIS_DisabledByConfig,
	EMCPIS_DisabledByProfileStatus,
	EMCPIS_NoOnlineSubsystem,
};

enum EOnlineEventType
{
	EOET_Auth, // renamed from Whitelist because that's racist!
	EOET_Recap,
	EOET_GetRecap,
	EOET_GetDict,
	EOET_PingMCP,
	EOET_PlayerInfo,
	EOET_MissionInfo,
	EOET_ChallengeMode,
};

struct native MCPEventRequest
{
	// The URL to the event page that we're reading
	var const string EventUrl;

	// The current async read state for the operation
	var EOnlineEnumerationReadState AsyncState;

	// The type of event that we are reading
	var const EOnlineEventType EventType;

	// The amount of time before giving up on the read
	var const float TimeOut;
	
	// Pointer to the native helper object that performs the download
	var const native pointer HttpDownloader{class FHttpDownloadBinary};

	// True if once this request has been run once, we save the result elsewhere so it doesn't need to run again
	var const bool bResultIsCached;
};

struct native KeyCountsEntry
{
	var string Key;
	var int Value;
	var int Type;
};

struct native TileCoord
{
	var int X;
	var int Y;
	var int Z;
};
