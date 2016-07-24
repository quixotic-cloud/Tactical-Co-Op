//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineGameSettings.uc
//  AUTHOR:  Todd Smith  --  3/15/2011
//  PURPOSE: Base class for our custom online game settings
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineGameSettings extends OnlineGameSettings
	dependson(XComOnlineGameSearch)
	abstract
	config(MPGame);

`include(XComOnlineConstants.uci)

var protectedwrite config bool      DEBUG_bChangeRankedGameOptions;
var privatewrite config int         QuickmatchTurnTimer;

/**
 *  Data INI Version - Accessors
 */
// @TODO tsmith: deprecate, X2 does not use the MP INI anymore.
function SetMPDataINIVersion(int iINIVersion)
{
	local int iBuildVersion;
	// Convert to string INIVersion + GameVersion, then convert to int
	iBuildVersion = int(iINIVersion $ class'XComGameInfo'.static.GetGameVersion());
	SetIntProperty(PROPERTY_MP_DATA_INI_VERSION, iBuildVersion);
	`log(`location @ "Version#" @ iBuildVersion,,'XComOnline');
}

function int GetMPDataINIVersion()
{
	local int iValue;
	GetIntProperty(PROPERTY_MP_DATA_INI_VERSION, iValue);
	return iValue;
}

/** 
 *  Network Type - Accessors
 */
function SetNetworkType(EMPNetworkType eNetworkType)
{
	SetIntProperty(PROPERTY_MP_NETWORKTYPE, eNetworkType);
	SetRankedNetworkType(eNetworkType, GetIsRanked());
}

function EMPNetworkType GetNetworkType()
{
	local int iNetworkType;
	GetIntProperty(PROPERTY_MP_NETWORKTYPE, iNetworkType);
	return EMPNetworkType(iNetworkType);
}

/** 
 *  Game Type - Accessors
 */
function SetGameType(EMPGameType eGameType)
{
	SetIntProperty(PROPERTY_MP_GAMETYPE, eGameType); 
}

function EMPGameType GetGameType()
{
	local int iGameType;
	GetIntProperty(PROPERTY_MP_GAMETYPE, iGameType);
	return EMPGameType(iGameType);
}

/** 
 *  Turn Time In Seconds - Accessors
 */
function SetTurnTimeSeconds(int iTurnTime)
{
	SetIntProperty(PROPERTY_MP_TURNTIMESECONDS, iTurnTime);
}

function int GetTurnTimeSeconds()
{
	local int iTurnTime;
	GetIntProperty(PROPERTY_MP_TURNTIMESECONDS, iTurnTime);
	return iTurnTime;
}

/** 
 *  Max Squad Cost - Accessors
 */
function SetMaxSquadCost(int iSquadCost)
{
	SetIntProperty(PROPERTY_MP_MAXSQUADCOST, iSquadCost);
}

function int GetMaxSquadCost()
{
	local int iSquadCost;
	GetIntProperty(PROPERTY_MP_MAXSQUADCOST, iSquadCost);
	return iSquadCost;
}

/** 
 *  Is Ranked - Accessors
 */
function SetIsRanked(bool bIsRanked)
{
	SetRankedNetworkType(GetNetworkType(), bIsRanked);
}

function bool GetIsRanked()
{
	local int iIsRanked;
	GetIntProperty(PROPERTY_MP_ISRANKED, iIsRanked);
	return (iIsRanked == EROP_Ranked);
}

/**
 * Small hack to combine the Ranked and Network types to get around the 8 search terms for the PS3 -ttalley
 */
function SetRankedNetworkType(EMPNetworkType eNetworkType, bool bIsRanked)
{
	local ERankedOverloadProperty eRankedNetworkType;
	switch(eNetworkType)
	{
	case eMPNetworkType_Public:
		eRankedNetworkType = (bIsRanked ? EROP_Ranked : EROP_Unranked_Public);
		break;
	case eMPNetworkType_Private:
		eRankedNetworkType = EROP_Unranked_Private;
		break;
	case eMPNetworkType_LAN:
	default:
		eRankedNetworkType = EROP_Offline;
		break;
	}
	SetIntProperty(PROPERTY_MP_ISRANKED, eRankedNetworkType);
}

// subclasses define how ratings are calculated -tsmith 
function int GetHostRankedRating()
{
	return -1;
}

/**
 * Byte-code Identifier Hash - Accessors
 */
function SetByteCodeHash(string sByteCodeHash)
{
	SetStringProperty(PROPERTY_MP_BYTECODEHASHINDEX, sByteCodeHash);
}

function string GetByteCodeHash()
{
	local string sByteCodeHash;
	GetStringProperty(PROPERTY_MP_BYTECODEHASHINDEX, sByteCodeHash);
	return sByteCodeHash;
}

/** 
 *  Automatch - Accessors
 */
function SetIsAutomatch(bool bAutomatch)
{
	SetIntProperty(PROPERTY_MP_ISAUTOMATCH, (bAutomatch ? 1 : 0));
}

function bool GetIsAutomatch()
{
	local int iIsAutomatch;
	GetIntProperty(PROPERTY_MP_ISAUTOMATCH, iIsAutomatch);
	return iIsAutomatch > 0;
}

/** 
 *  Map Plot Type - Accessors
 */
function SetMapPlotTypeInt(int iMapPlotType)
{
	SetIntProperty(PROPERTY_MP_MAP_PLOT_INT, iMapPlotType);
}

function int GetMapPlotTypeInt()
{
	local int iMapPlotType;
	GetIntProperty(PROPERTY_MP_MAP_PLOT_INT, iMapPlotType);
	return iMapPlotType;
}

/** 
 *  Map Biome Type - Accessors
 */
function SetMapBiomeTypeInt(int iMapBiomeType)
{
	SetIntProperty(PROPERTY_MP_MAP_BIOME_INT, iMapBiomeType);
}

function int GetMapBiomeTypeInt()
{
	local int iMapBiomeType;
	GetIntProperty(PROPERTY_MP_MAP_BIOME_INT, iMapBiomeType);
	return iMapBiomeType;
}

/**
 * Server Ready - Accessors
 */
function SetServerReady(bool bIsReady)
{
	SetIntProperty(PROPERTY_MP_SERVER_READY, int(bIsReady));
}

function bool GetServerReady()
{
	local int iIsReady;
	GetIntProperty(PROPERTY_MP_SERVER_READY, iIsReady);
	return iIsReady > 0;
}

/**
 * Installed DLC - Accessors
 */
function SetInstalledDLCHash(int iInstalledDLCHash)
{
	SetIntProperty(PROPERTY_MP_INSTALLED_DLC_HASH, iInstalledDLCHash);
}

function int GetInstalledDLCHash()
{
	local int iInstalledDLCHash;
	GetIntProperty(PROPERTY_MP_INSTALLED_DLC_HASH, iInstalledDLCHash);
	return iInstalledDLCHash;
}

/**
 * Installed Mods - Accessors
 */
function SetInstalledModsHash(int iInstalledModsHash)
{
	SetIntProperty(PROPERTY_MP_INSTALLED_MODS_HASH, iInstalledModsHash);
}

function int GetInstalledModsHash()
{
	local int iInstalledModsHash;
	GetIntProperty(PROPERTY_MP_INSTALLED_MODS_HASH, iInstalledModsHash);
	return iInstalledModsHash;
}

/**
 * Dev console enabled - Accessors
 */
function SetIsDevConsoleEnabled(bool bIsDevConsoleEnabled)
{
	SetIntProperty(PROPERTY_MP_DEV_CONSOLE_ENABLED, int(bIsDevConsoleEnabled));
}

function bool GetIsDevConsoleEnabled()
{
	local int iIsDevConsoleEnabled;
	GetIntProperty(PROPERTY_MP_DEV_CONSOLE_ENABLED, iIsDevConsoleEnabled);
	return iIsDevConsoleEnabled > 0;
}

/**
 * INI Hash - Accessors
 */
function SetINIHash(string sINIHash)
{
	SetStringProperty(PROPERTY_MP_INI_HASH, sINIHash);
}

function string GetINIHash()
{
	local string sINIHash;
	GetStringProperty(PROPERTY_MP_INI_HASH, sINIHash);
	return sINIHash;
}

function string ToString()
{
	local string strRep;

	strRep = self $ "\n";
	strRep $= "      OwningPlayerName=" $ OwningPlayerName $ "\n";
	strRep $= "      OwningPlayerId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(OwningPlayerId) $ "\n";
	strRep $= "      PingInMs=" $ PingInMs $ "\n";
	strRep $= "      NumPublicConnections=" $ NumPublicConnections $ "\n";
	strRep $= "      NumOpenPublicConnections=" $ NumOpenPublicConnections $ "\n";
	strRep $= "      NumPrivateConnections=" $ NumPrivateConnections $ "\n";
	strRep $= "      NumOpenPrivateConnections=" $ NumOpenPrivateConnections $ "\n";
	strRep $= "      bIsLanMatch=" $ bIsLanMatch $ "\n";
	strRep $= "      bIsDedicated=" $ bIsDedicated $ "\n";
	strRep $= "      bUsesStats=" $ bUsesStats $ "\n";
	strRep $= "      bUsesArbitration=" $ bUsesArbitration $ "\n";
	strRep $= "      bAntiCheatProtected=" $ bAntiCheatProtected $ "\n";
	strRep $= "      bShouldAdvertise=" $ bShouldAdvertise $ "\n";
	strRep $= "      bAllowJoinInProgress=" $ bAllowJoinInProgress $ "\n";
	strRep $= "      bAllowInvites=" $ bAllowInvites $ "\n";
	strRep $= "      bUsesPresence=" $ bUsesPresence $ "\n";
	strRep $= "      bWasFromInvite=" $ bWasFromInvite $ "\n";
	strRep $= "      bAllowJoinViaPresence=" $ bAllowJoinViaPresence $ "\n";
	strRep $= "      bAllowJoinViaPresenceFriendsOnly=" $ bAllowJoinViaPresenceFriendsOnly $ "\n";
	strRep $= "      BuildUniqueId=" $ BuildUniqueId $ "\n";
	strRep $= "      GameState=" $ GameState $ "\n";
	strRep $= "      NetworkType=" $ class'XComMPData'.static.GetNetworkTypeName(GetNetworkType()) $ "\n";
	strRep $= "      GameType=" $ class'X2MPData_Shell'.default.m_arrGameTypeNames[GetGameType()] $ "\n";
	strRep $= "      TurnTimeSeconds=" $ GetTurnTimeSeconds() $ "\n";
	strRep $= "      MaxSquadCost=" $ GetMaxSquadCost() $ "\n";
	strRep $= "      IsRanked=" $ GetIsRanked() $ "\n";
	strRep $= "      IsAutomatch=" $ GetIsAutomatch() $ "\n";
	strRep $= "      MapPlotTypeInt=" $ GetMapPlotTypeInt() $ "\n";
	strRep $= "      MapBiomeTypeInt=" $ GetMapBiomeTypeInt() $ "\n";
	strRep $= "      HostRankedRating=" $ GetHostRankedRating() $ "\n";
	strRep $= "      MP Data INI Version=" $ GetMPDataINIVersion() $ "\n";
	strRep $= "      Byte Code Hash=" $ GetByteCodeHash() $ "\n";
	strRep $= "      InstalledDLCHash=" $ GetInstalledDLCHash() $ "\n";
	strRep $= "      InstalledModsHash=" $ GetInstalledModsHash() $ "\n";
	strRep $= "      INIHash=" $ GetINIHash() $ "\n";
	strRep $= "      IsDevConsoleEnabled=" $ GetIsDevConsoleEnabled() $ "\n";
	strRep $= "      MP Server Ready=" $ GetServerReady() $ "\n";

	return strRep;
}


defaultproperties
{
	OnlineStatsWriteClass=class'XComGame.XComOnlineStatsWrite'
	OnlineStatsReadClass=class'XComGame.XComOnlineStatsRead'

	// none of our games are allowed to be joined in progress  -tsmith 
	bAllowJoinInProgress=false

	// NOTE: this just advertise the match to the online service. it does not make the match private/public.
	// see https://udn.epicgames.com/lists/showpost.php?list=unprog3&id=33321&lessthan=&show=20 -tsmith 
	bShouldAdvertise = true;

	/************************************************************************/
	/* NOTE: VERY IMPORTANT!!! IF THIS ARRAY IS CHANGED YOU MUST MAKE SURE	*/
	/*       DERIVED CLASSES ARE ADJUSTED ACCORDINGLY!!!!	                */
	/*       INDICES MUST STAY THE SAME AS THE SUPERCLASS AS WELL           */
	/************************************************************************/

	// INI version we are searching for -tsmith 
	Properties(0)=(PropertyId=PROPERTY_MP_DATA_INI_VERSION,Data=(Type=SDT_Int32,Value1=1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(0)={(
		Id=PROPERTY_MP_DATA_INI_VERSION,
		Name="MP Data INI version",
		NamedIds[0]=(Id=PROPERTY_MP_DATA_INI_VERSION,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_DATA_INI_VERSION,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_DATA_INI_VERSION,Name="PSN")
	)}

	Properties(1)=(PropertyId=PROPERTY_MP_NETWORKTYPE,Data=(Type=SDT_Int32,Value1=eMPNetworkType_Public),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(1)={(
		Id=PROPERTY_MP_NETWORKTYPE,
		Name="MP Network Type",
		NamedIds[0]=(Id=PROPERTY_MP_NETWORKTYPE,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_NETWORKTYPE,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_NETWORKTYPE,Name="PSN")
	)}

	Properties(2)=(PropertyId=PROPERTY_MP_GAMETYPE,Data=(Type=SDT_Int32,Value1=eMPGameType_Deathmatch),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(2)={(
		Id=PROPERTY_MP_GAMETYPE,
		Name="MP Game Type",
		NamedIds[0]=(Id=PROPERTY_MP_GAMETYPE,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_GAMETYPE,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_GAMETYPE,Name="PSN")
	)}

	Properties(3)=(PropertyId=PROPERTY_MP_TURNTIMESECONDS,Data=(Type=SDT_Int32,Value1=90),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(3)={(
		Id=PROPERTY_MP_TURNTIMESECONDS,
		Name="MP Turn Time In Seconds",
		NamedIds[0]=(Id=PROPERTY_MP_TURNTIMESECONDS,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_TURNTIMESECONDS,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_TURNTIMESECONDS,Name="PSN")
	)}

	Properties(4)=(PropertyId=PROPERTY_MP_MAXSQUADCOST,Data=(Type=SDT_Int32,Value1=10000),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(4)={(
		Id=PROPERTY_MP_MAXSQUADCOST,
		Name="MP Max Squad Cost",
		NamedIds[0]=(Id=PROPERTY_MP_MAXSQUADCOST,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_MAXSQUADCOST,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_MAXSQUADCOST,Name="PSN")
	)}

	Properties(5)=(PropertyId=PROPERTY_MP_ISRANKED,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(5)={(
		Id=PROPERTY_MP_ISRANKED,
		Name="MP Is Ranked",
		NamedIds[0]=(Id=PROPERTY_MP_ISRANKED,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_ISRANKED,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_ISRANKED,Name="PSN")
	)}

	Properties(6)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(6)={(
		Id=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,
		Name="MP Ranked Rating",
		NamedIds[0]=(Id=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Name="PSN")
	)}

	// Workshop: This is a steam only property and does not need to be ported, but can be if its easier that way. -ttalley
	Properties(7)=(PropertyId=PROPERTY_MP_BYTECODEHASHINDEX,Data=(Type=SDT_String),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(7)={(
		Id=PROPERTY_MP_BYTECODEHASHINDEX,
		Name="Byte Code Hash Index",
		NamedIds[0]=(Id=PROPERTY_MP_BYTECODEHASHINDEX,Name="STEAM"),
	)}

	// @TODO Workshop: add the console mappings if we end up porting X2 to consoles.
	Properties(8)=(PropertyId=PROPERTY_MP_ISAUTOMATCH,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(8)={(
		Id=PROPERTY_MP_ISAUTOMATCH,
		Name="MP Is Automatch",
		NamedIds[0]=(Id=PROPERTY_MP_ISAUTOMATCH,Name="STEAM"),
	)}

	// @TODO Workshop: add the console mappings if we end up porting X2 to consoles.
	Properties(9)=(PropertyId=PROPERTY_MP_MAP_PLOT_INT,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(9)={(
		Id=PROPERTY_MP_MAP_PLOT_INT,
		Name="MP Map Plot Int",
		NamedIds[0]=(Id=PROPERTY_MP_MAP_PLOT_INT,Name="STEAM"),
	)}

	// @TODO Workshop: add the console mappings if we end up porting X2 to consoles.
	Properties(10)=(PropertyId=PROPERTY_MP_MAP_BIOME_INT,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(10)={(
		Id=PROPERTY_MP_MAP_BIOME_INT,
		Name="MP Map Biome Int",
		NamedIds[0]=(Id=PROPERTY_MP_MAP_BIOME_INT,Name="STEAM"),
	)}

	// @TODO Workshop: add the console mappings if we end up porting X2 to consoles.
	Properties(11)=(PropertyId=PROPERTY_MP_SERVER_READY,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(11)={(
		Id=PROPERTY_MP_SERVER_READY,
		Name="MP Server Ready",
		NamedIds[0]=(Id=PROPERTY_MP_SERVER_READY,Name="STEAM"),
	)}

	Properties(12)=(PropertyId=PROPERTY_MP_INSTALLED_DLC_HASH,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(12)={(
		Id=PROPERTY_MP_INSTALLED_DLC_HASH,
		Name="Installed DLC Hash",
		NamedIds[0]=(Id=PROPERTY_MP_INSTALLED_DLC_HASH,Name="STEAM"),
	)}

	// Workshop: This is a steam only property and does not need to be ported, but can be if its easier that way.
	Properties(13)=(PropertyId=PROPERTY_MP_INSTALLED_MODS_HASH,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(13)={(
		Id=PROPERTY_MP_INSTALLED_MODS_HASH,
		Name="Installed Mods Hash",
		NamedIds[0]=(Id=PROPERTY_MP_INSTALLED_MODS_HASH,Name="STEAM"),
	)}

	// Workshop: This is a steam only property and does not need to be ported, but can be if its easier that way.
	Properties(14)=(PropertyId=PROPERTY_MP_DEV_CONSOLE_ENABLED,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(14)={(
		Id=PROPERTY_MP_DEV_CONSOLE_ENABLED,
		Name="Dev Console Enabled",
		NamedIds[0]=(Id=PROPERTY_MP_DEV_CONSOLE_ENABLED,Name="STEAM"),
	)}

	// Workshop: This is a steam only property and does not need to be ported, but can be if its easier that way. -ttalley
	Properties(15)=(PropertyId=PROPERTY_MP_INI_HASH,Data=(Type=SDT_String),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(15)={(
		Id=PROPERTY_MP_INI_HASH,
		Name="INI Hash",
		NamedIds[0]=(Id=PROPERTY_MP_INI_HASH,Name="STEAM"),
	)}
}
