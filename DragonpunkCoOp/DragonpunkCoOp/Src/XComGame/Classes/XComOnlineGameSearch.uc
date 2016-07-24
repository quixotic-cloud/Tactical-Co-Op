//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineGameSearch.uc
//  AUTHOR:  Todd Smith  --  7/7/2011
//  PURPOSE: Game search class specifice to XCom
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineGameSearch extends OnlineGameSearch
	native
	abstract
	config(MPGame);

`include(XComOnlineConstants.uci)


var config int m_iMaxAutomatchSearchesUntilCreateGame;

/**
 * Search overloading for Ranked / Network Type
 */
enum ERankedOverloadProperty
{
	EROP_Ranked,
	EROP_Unranked_Private,
	EROP_Unranked_Public,
	EROP_Offline
};

/**
 * Easy translation from code to constants
 */
enum EGameSearchProperty
{
	EGSP_NONSTANDARDOPTIONS,
	EGSP_MP_NETWORKTYPE,
	EGSP_MP_GAMETYPE,
	EGSP_MP_TURNTIMESECONDS,
	EGSP_MP_MAXSQUADCOST,
	EGSP_MP_ISRANKED,
	EGSP_MP_MAPINDEX,
	EGSP_MP_DEATHMATCH_RANKED_MATCHES_WON,
	EGSP_MP_DEATHMATCH_RANKED_MATCHES_LOST,
	EGSP_MP_DEATHMATCH_RANKED_DISCONNECTS,
	EGSP_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX,
	EGSP_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN,
	EGSP_TEST_INT,
	EGSP_MP_DEATHMATCH_RANKED_GAME_RATING,
	EGSP_MP_DATA_INI_VERSION,
	EGSP_XCOMGAMERATING,
	EGSP_MP_DEATHMATCH_RANKED_RATING,
	EGSP_TEST_RATING,
	EGSP_MP_DEATHMATCH_RANKED_MATCH_STARTED,
	EGSP_MP_MAP_PLOT_INT,
	EGSP_MP_MAP_PLOT_MIN,
	EGSP_MP_MAP_PLOT_MAX,
	EGSP_MP_MAP_BIOME_INT,
	EGSP_MP_MAP_BIOME_MIN,
	EGSP_MP_MAP_BIOME_MAX,
	EGSP_MP_SERVER_READY
};

/**
 * Useful for external usage of building a new search clause.
 *    i.e. OnlineGameSearch.BuildAndAddNewSearchClause(EGSP_MP_TURNTIMESECONDS)
 */
public function int ConvertToPropertyId(EGameSearchProperty SearchProp)
{
	local int PropertyId;

	switch(SearchProp)
	{
	case EGSP_NONSTANDARDOPTIONS:
		PropertyId = PROPERTY_NONSTANDARDOPTIONS;
		break;
	case EGSP_MP_NETWORKTYPE:
		PropertyId = PROPERTY_MP_NETWORKTYPE;
		break;
	case EGSP_MP_GAMETYPE:
		PropertyId = PROPERTY_MP_GAMETYPE;
		break;
	case EGSP_MP_TURNTIMESECONDS:
		PropertyId = PROPERTY_MP_TURNTIMESECONDS;
		break;
	case EGSP_MP_MAXSQUADCOST:
		PropertyId = PROPERTY_MP_MAXSQUADCOST;
		break;
	case EGSP_MP_ISRANKED:
		PropertyId = PROPERTY_MP_ISRANKED;
		break;;
	case EGSP_MP_DEATHMATCH_RANKED_MATCHES_WON:
		PropertyId = PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_WON;
		break;
	case EGSP_MP_DEATHMATCH_RANKED_MATCHES_LOST:
		PropertyId = PROPERTY_MP_DEATHMATCH_RANKED_MATCHES_LOST;
		break;
	case EGSP_MP_DEATHMATCH_RANKED_DISCONNECTS:
		PropertyId = PROPERTY_MP_DEATHMATCH_RANKED_DISCONNECTS;
		break;
	case EGSP_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX:
		PropertyId = PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX;
		break;
	case EGSP_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN:
		PropertyId = PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN;
		break;
	case EGSP_TEST_INT:
		PropertyId = PROPERTY_TEST_INT;
		break;
	case EGSP_MP_DEATHMATCH_RANKED_GAME_RATING:
		PropertyId = PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING;
		break;
	case EGSP_MP_DATA_INI_VERSION:
		PropertyId = PROPERTY_MP_DATA_INI_VERSION;
		break;
	case EGSP_MP_DEATHMATCH_RANKED_MATCH_STARTED:
		PropertyId = PROPERTY_MP_DEATHMATCH_RANKED_MATCH_STARTED;
		break;
	case EGSP_XCOMGAMERATING:
		PropertyId = PROPERTY_XCOMGAMERATING;
		break;
	case EGSP_MP_DEATHMATCH_RANKED_RATING:
		PropertyId = PROPERTY_MP_DEATHMATCH_RANKED_RATING;
		break;
	case EGSP_TEST_RATING:
		PropertyId = PROPERTY_TEST_RATING;
		break;
	case EGSP_MP_MAP_PLOT_INT:
		PropertyId = PROPERTY_MP_MAP_PLOT_INT;
		break;
	case EGSP_MP_MAP_PLOT_MIN:
		PropertyId = PROPERTY_MP_MAP_PLOT_MIN;
		break;
	case EGSP_MP_MAP_PLOT_MAX:
		PropertyId = PROPERTY_MP_MAP_PLOT_MAX;
		break;
	case EGSP_MP_MAP_BIOME_INT:
		PropertyId = PROPERTY_MP_MAP_BIOME_INT;
		break;
	case EGSP_MP_MAP_BIOME_MIN:
		PropertyId = PROPERTY_MP_MAP_BIOME_MIN;
		break;
	case EGSP_MP_MAP_BIOME_MIN:
		PropertyId = PROPERTY_MP_MAP_BIOME_MAX;
		break;
	default:
		PropertyId = 0;
		break;
	}

	return PropertyId;
}

/************************************************************************/
/**                                                                    **/
/** Property Settings                                                  **/
/**                                                                    **/
/************************************************************************/

/** 
 *  Dynamically adds a new search property name/value pair for use within the query system.  This will usually be for value lookups since the PropertyIds are hardcoded for XBox & PSN.
 */
native function AddPropertyMappingANDValue(int PropertyId, Name MappingName, SettingsData Data, optional int PSNID=-1, optional int LiveID=-1, optional int SteamID=-1);

/** 
 *  Data INI Version - Accessors
 */
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

/**
 * Map PlotType - Accessors
 */
function SetMapPlot(int iMapPlotInt, int iMapPlotMin, int iMapPlotMax)
{
	SetIntProperty(PROPERTY_MP_MAP_PLOT_INT, iMapPlotInt);
	SetIntProperty(PROPERTY_MP_MAP_PLOT_MIN, iMapPlotMin);
	SetIntProperty(PROPERTY_MP_MAP_PLOT_MAX, iMapPlotMax);
}

function SetMapPlotTypeInt(int iMapPlotInt)
{
	SetIntProperty(PROPERTY_MP_MAP_PLOT_INT, iMapPlotInt);
}

function SetMapPlotTypeMinMax(int iMapPlotMin, int iMapPlotMax)
{
	SetIntProperty(PROPERTY_MP_MAP_PLOT_MIN, iMapPlotMin);
	SetIntProperty(PROPERTY_MP_MAP_PLOT_MAX, iMapPlotMax);
}

function int GetMapPlotTypeInt()
{
	local int iMapPlotInt;
	GetIntProperty(PROPERTY_MP_MAP_PLOT_INT, iMapPlotInt);
	return iMapPlotInt;
}

function int GetMapPlotTypeMin()
{
	local int iMapPlotMin;
	GetIntProperty(PROPERTY_MP_MAP_PLOT_MIN, iMapPlotMin);
	return iMapPlotMin;
}

function int GetMapPlotTypeMax()
{
	local int iMapPlotMax;
	GetIntProperty(PROPERTY_MP_MAP_PLOT_MAX, iMapPlotMax);
	return iMapPlotMax;
}

/**
 * Map BiomeType - Accessors
 */
function SetMapBiome(int iMapBiomeInt, int iMapBiomeMin, int iMapBiomeMax)
{
	SetIntProperty(PROPERTY_MP_MAP_BIOME_INT, iMapBiomeInt);
	SetIntProperty(PROPERTY_MP_MAP_BIOME_MIN, iMapBiomeMin);
	SetIntProperty(PROPERTY_MP_MAP_BIOME_MAX, iMapBiomeMax);
}

function SetMapBiomeTypeInt(int iMapBiomeInt)
{
	SetIntProperty(PROPERTY_MP_MAP_BIOME_INT, iMapBiomeInt);
}

function SetMapBiomeTypeMinMax(int iMapBiomeMin, int iMapBiomeMax)
{
	SetIntProperty(PROPERTY_MP_MAP_BIOME_MIN, iMapBiomeMin);
	SetIntProperty(PROPERTY_MP_MAP_BIOME_MAX, iMapBiomeMax);
}

function int GetMapBiomeTypeInt()
{
	local int iMapBiomeInt;
	GetIntProperty(PROPERTY_MP_MAP_BIOME_INT, iMapBiomeInt);
	return iMapBiomeInt;
}

function int GetMapBiomeTypeMin()
{
	local int iMapBiomeMin;
	GetIntProperty(PROPERTY_MP_MAP_BIOME_MIN, iMapBiomeMin);
	return iMapBiomeMin;
}

function int GetMapBiomeTypeMax()
{
	local int iMapBiomeMax;
	GetIntProperty(PROPERTY_MP_MAP_BIOME_MAX, iMapBiomeMax);
	return iMapBiomeMax;
}


// subclasses define how ratings are calculated -tsmith 
function int GetHostRankedRating()
{
	return -1;
}

/** 
 *  Ranked Game Rating - Accessors
 */
function SetRankedGameRating(int iRankedGameRating)
{
	SetIntProperty(PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING, iRankedGameRating);
}

function int GetRankedGameRating()
{
	local int iRankedGameRating;
	GetIntProperty(PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING, iRankedGameRating);
	return iRankedGameRating;
}

/** 
 *  Ranked Rating Min - Accessors
 */
function SetRankedRatingMin(int iRankedGameRating)
{
	// overflow condition -tsmith 
	if(iRankedGameRating < 0)
	{
		iRankedGameRating = 0;
	}
	SetIntProperty(PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN, iRankedGameRating);
}

function int GetRankedRatingMin()
{
	local int iRankedGameRating;
	GetIntProperty(PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN, iRankedGameRating);
	return iRankedGameRating;
}

/** 
 *  Ranked Rating Max - Accessors
 */
function SetRankedRatingMax(int iRankedGameRating)
{
	// overflow condition -tsmith 
	if(iRankedGameRating < 0)
	{
		iRankedGameRating = MaxInt;
	}
	SetIntProperty(PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX, iRankedGameRating);
}

function int GetRankedRatingMax()
{
	local int iRankedGameRating;
	GetIntProperty(PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX, iRankedGameRating);
	return iRankedGameRating;
}

/**
 * Sets the range of player ratings used to search for games.
 * i.e. search will attempt to find matches with player rating of iRating +- iTolerance
 * 
 * @param iRating the base rating
 * @param iDelta +- to iRating to define min, max of range
 */
function SetRatingSearchRange(int iRating, int iDelta)
{
	SetRankedRatingMin(iRating - iDelta);
	SetRankedRatingMax(iRating + iDelta);
	`log(self $ "::" $ GetFuncName() @ `ShowVar(iRating) @ `ShowVar(iDelta) @ "Min=" $ GetRankedRatingMin() @ "Max=" $ GetRankedRatingMax(), true, 'XCom_Online');
}

/** 
 *  Squad Cost Min - Accessors
 */
function SetSquadCostMin(int iSquadCostMin)
{
	SetIntProperty(PROPERTY_MP_MAXSQUADCOST_MIN, iSquadCostMin);
}

function int GetSquadCostMin()
{
	local int iSquadCostMin;
	GetIntProperty(PROPERTY_MP_MAXSQUADCOST_MIN, iSquadCostMin);
	return iSquadCostMin;
}

/** 
 *  Squad Cost Max - Accessors
 */
function SetSquadCostMax(int iSquadCostMax)
{
	SetIntProperty(PROPERTY_MP_MAXSQUADCOST_MAX, iSquadCostMax);
}

function int GetSquadCostMax()
{
	local int iSquadCostMax;
	GetIntProperty(PROPERTY_MP_MAXSQUADCOST_MAX, iSquadCostMax);
	return iSquadCostMax;
}

/** 
 *  Turn Time Min - Accessors
 */
function SetTurnTimeMin(int iTurnTimeMin)
{
	SetIntProperty(PROPERTY_MP_TURNTIMESECONDS_MIN, iTurnTimeMin);
}

function int GetTurnTimeMin()
{
	local int iTurnTimeMin;
	GetIntProperty(PROPERTY_MP_TURNTIMESECONDS_MIN, iTurnTimeMin);
	return iTurnTimeMin;
}

/** 
 *  Turn Time Max - Accessors
 */
function SetTurnTimeMax(int iTurnTimeMax)
{
	SetIntProperty(PROPERTY_MP_TURNTIMESECONDS_MAX, iTurnTimeMax);
}

function int GetTurnTimeMax()
{
	local int iTurnTimeMax;
	GetIntProperty(PROPERTY_MP_TURNTIMESECONDS_MAX, iTurnTimeMax);
	return iTurnTimeMax;
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

/************************************************************************/
/**                                                                    **/
/** Filter Query                                                       **/
/**                                                                    **/
/************************************************************************/

/**
 * Creates a new search parameter. Default parameter will match the search key to that key's associated value.
 * 
 * @param SearchKeyId - PROPERTY ID from the PropertyId specifier within the Properties/PropertyMappings objects; searches the ID from the published GameSettings' properties
 * @param LookupKeyId - Uses a defined Property PropertyId to find the value to use for the search. For Example: BuildSearchParameter(PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING, PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN, OGSCT_GreaterThanEquals); // Searches the game rating for anything higher than the min value
 * @param ComparisionType - Tells the query how to treat the property value.
 * @param EntryType - Tells the query where to search for the property's value. (Usually will be OGSET_Property)
 */
function OnlineGameSearchParameter BuildSearchParameter(int SearchKeyId, optional int LookupKeyId=-1, optional EOnlineGameSearchComparisonType ComparisonType=OGSCT_Equals, optional EOnlineGameSearchEntryType EntryType=OGSET_Property)
{
	local OnlineGameSearchParameter kSearchParameter;
	local name ObjectPropertyName;

	if (LookupKeyId >= 0)
	{
		ObjectPropertyName = GetPropertyName(LookupKeyId);
	}
	else
	{
		ObjectPropertyname = GetPropertyName(SearchKeyId);
	}

	kSearchParameter.EntryId = SearchKeyId;
	kSearchParameter.EntryType = EntryType;
	kSearchParameter.ComparisonType = ComparisonType;
	kSearchParameter.ObjectPropertyName = ObjectPropertyName;

	return kSearchParameter;
}

/**
 * Builds search query by adding an AND parameter; however, specifing a previously added index will append the parameter as an OR parameter to the same AND clause.
 *  For Example:
 *      INIVersion= && (MapIndex= || MapIndex= || MapIndex=)
 *  Code:
 *      idx = BuildAndAddNewSearchClause(PROPERTY_MP_DATA_INI_VERSION);
 *      idx = BuildAndAddNewSearchClause(PROPERTY_MP_MAPINDEX, -1, QUERY_MAPINDEX_VAR1); // QUERY_MAPINDEX_VAR1 is a defined Property PropertyId, perhaps set dynamically
 *      idx = BuildAndAddNewSearchClause(PROPERTY_MP_MAPINDEX, idx, QUERY_MAPINDEX_VAR2); // QUERY_MAPINDEX_VAR2 is a defined Property PropertyId, perhaps set dynamically
 *      idx = BuildAndAddNewSearchClause(PROPERTY_MP_MAPINDEX, idx, QUERY_MAPINDEX_VAR3); // QUERY_MAPINDEX_VAR3 is a defined Property PropertyId, perhaps set dynamically
 * 
 * @param SearchKeyId - PROPERTY ID from the PropertyId specifier within the Properties/PropertyMappings objects
 * @param OrClauseIdx - This will append the search parameter to the specified AND clause (i.e. ClauseX = PARAMETER 1 || PARAMETER 2)
 */
function int BuildAndAddNewSearchClause(EGameSearchProperty SearchProp, optional int OrClauseIdx=-1, optional int LookupKeyId=-1, optional EOnlineGameSearchComparisonType ComparisonType=OGSCT_Equals, optional EOnlineGameSearchEntryType EntryType=OGSET_Property)
{
	local int SearchKeyId;
	SearchKeyId = ConvertToPropertyId(SearchProp);
	return BuildAndAddNewSearchClauseInternal(SearchKeyId, OrClauseIdx, LookupKeyId, ComparisonType, EntryType);
}

private function int BuildAndAddNewSearchClauseInternal(int SearchKeyId, optional int OrClauseIdx=-1, optional int LookupKeyId=-1, optional EOnlineGameSearchComparisonType ComparisonType=OGSCT_Equals, optional EOnlineGameSearchEntryType EntryType=OGSET_Property)
{
	local int iNewSearchClauseIdx;
	local OnlineGameSearchParameter kSearchParameter;

	kSearchParameter = BuildSearchParameter(SearchKeyId, LookupKeyId, ComparisonType, EntryType);
	iNewSearchClauseIdx = AddNewSearchClause(kSearchParameter, OrClauseIdx);

	return iNewSearchClauseIdx;
}

function int AddNewSearchClause(OnlineGameSearchParameter kSearchParameter, optional int OrClauseIdx=-1)
{
	local int iNewSearchClauseIdx, iClauseIdx, iParamIdx;
	local OnlineGameSearchORClause kSearchORClause;

	if ((OrClauseIdx >= 0) && (OrClauseIdx < FilterQuery.OrClauses.Length)) // Create an AND scenario with the search parameter
	{
		// Overriding a specific search clause
		iNewSearchClauseIdx = OrClauseIdx;
		kSearchORClause = FilterQuery.OrClauses[OrClauseIdx];
		kSearchORClause.OrParams.AddItem(kSearchParameter);
	}
	else
	{
		// New Search Clause ... Check for duplicity
		`log(`location @ "Searching for: " @ `ShowVar(kSearchParameter.EntryId));
		for (iClauseIdx = 0; iClauseIdx < FilterQuery.OrClauses.Length; ++iClauseIdx)
		{
			for (iParamIdx = 0; iParamIdx < FilterQuery.OrClauses[iClauseIdx].OrParams.Length; ++iParamIdx)
			{
				`log(`location @ "       Testing: " @ `ShowVar(FilterQuery.OrClauses[iClauseIdx].OrParams[iParamIdx].EntryId, EntryId));
				if (FilterQuery.OrClauses[iClauseIdx].OrParams[iParamIdx].EntryId == kSearchParameter.EntryId)
				{
					// Found a duplicate entry, preserving
					`log(`location @ "Found duplicate Game Search Parameter, bailing.",,'XCom_Online');
					return iClauseIdx;
				}
			}
		}
		iNewSearchClauseIdx = FilterQuery.OrClauses.Length;
		kSearchORClause.OrParams.AddItem(kSearchParameter);
		FilterQuery.OrClauses.AddItem(kSearchORClause);
	}

	return iNewSearchClauseIdx;
}

function string ToString()
{
	local string strRep;

	strRep = self $ "\n";
	strRep $= "NetworkType=" $ GetNetworkType() $ "\n";
	strRep $= "GameType=" $ GetGameType() $ "\n";
	strRep $= "IsRanked=" $ GetIsRanked() $ "\n";
	strRep $= "RankedGameRating=" $ GetRankedGameRating() $ "\n";
	strRep $= "RankedRatingMin=" $ GetRankedRatingMin() $ "\n";
	strRep $= "RankedRatingMax=" $ GetRankedRatingMax() $ "\n";
	strRep $= "HostRankedRating=" $ GetHostRankedRating() $ "\n";
	strRep $= "TurnTimeSeconds=" $ GetTurnTimeSeconds() $ "\n";
	strRep $= "TurnTimeMin=" $ GetTurnTimeMin() $ "\n";
	strRep $= "TurnTimeMax=" $ GetTurnTimeMax() $ "\n";
	strRep $= "MaxSquadCost=" $ GetMaxSquadCost() $ "\n";
	strRep $= "SquadCostMin=" $ GetSquadCostMin() $ "\n";
	strRep $= "SquadCostMax=" $ GetSquadCostMax() $ "\n";
	strRep $= "MapPlotTypeInt=" $ GetMapPlotTypeInt() $ "\n";
	strRep $= "MapPlotTypeMin=" $ GetMapPlotTypeMin() $ "\n";
	strRep $= "MapPlotTypeMax=" $ GetMapPlotTypeMax() $ "\n";
	strRep $= "MapBiomeTypeInt=" $ GetMapBiomeTypeInt() $ "\n";
	strRep $= "MapBiomeTypeMin=" $ GetMapBiomeTypeMin() $ "\n";
	strRep $= "MapBiomeTypeMax=" $ GetMapBiomeTypeMax() $ "\n";
	strRep $= "ByteCodeHash=" $ GetByteCodeHash() $ "\n";
	strRep $= "InstalledDLCHash=" $ GetInstalledDLCHash() $ "\n";
	strRep $= "InstalledModsHash=" $ GetInstalledModsHash() $ "\n";
	strRep $= "INIHash=" $ GetINIHash() $ "\n";
	strRep $= "IsDevConsoleEnabled=" $ GetIsDevConsoleEnabled() $ "\n";
	strRep $= "ServerReady=" $ GetServerReady() $ "\n";
	
	return strRep;
}

defaultproperties
{
	/************************************************************************/
	/* NOTE: VERY IMPORTANT!!! IF THIS ARRAY IS CHANGED YOU MUST MAKE SURE	*/
	/*       DERIVED CLASSES ARE ADJUSTED ACCORDINGLY!!!!	                */
	/*       INDICES MUST STAY THE SAME AS THE SUPERCLASS AS WELL           */
	/************************************************************************/

	// INI version we are searching for -tsmith 
	Properties(0)=(PropertyId=PROPERTY_MP_DATA_INI_VERSION,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(0)={(
		Id=PROPERTY_MP_DATA_INI_VERSION,
		Name="MP Data INI version",
		NamedIds[0]=(Id=PROPERTY_MP_DATA_INI_VERSION,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_DATA_INI_VERSION,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_DATA_INI_VERSION,Name="PSN")
	)}

	Properties(1)=(PropertyId=PROPERTY_MP_NETWORKTYPE,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(1)={(
		Id=PROPERTY_MP_NETWORKTYPE,
		Name="MP Network Type",
		NamedIds[0]=(Id=PROPERTY_MP_NETWORKTYPE,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_NETWORKTYPE,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_NETWORKTYPE,Name="PSN")
	)}

	Properties(2)=(PropertyId=PROPERTY_MP_GAMETYPE,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(2)={(
		Id=PROPERTY_MP_GAMETYPE,
		Name="MP Game Type",
		NamedIds[0]=(Id=PROPERTY_MP_GAMETYPE,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_GAMETYPE,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_GAMETYPE,Name="PSN")
	)}

	Properties(3)=(PropertyId=PROPERTY_MP_TURNTIMESECONDS,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(3)={(
		Id=PROPERTY_MP_TURNTIMESECONDS,
		Name="MP Turn Time In Seconds",
		NamedIds[0]=(Id=PROPERTY_MP_TURNTIMESECONDS,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_TURNTIMESECONDS,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_TURNTIMESECONDS,Name="PSN")
	)}

	Properties(4)=(PropertyId=PROPERTY_MP_MAXSQUADCOST,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(4)={(
		Id=PROPERTY_MP_MAXSQUADCOST,
		Name="MP Max Squad Cost",
		NamedIds[0]=(Id=PROPERTY_MP_MAXSQUADCOST,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_MAXSQUADCOST,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_MAXSQUADCOST,Name="PSN")
	)}

	Properties(5)=(PropertyId=PROPERTY_MP_ISRANKED,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(5)={(
		Id=PROPERTY_MP_ISRANKED,
		Name="MP Is Ranked",
		NamedIds[0]=(Id=PROPERTY_MP_ISRANKED,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_ISRANKED,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_ISRANKED,Name="PSN")
	)}

	Properties(6)=(PropertyId=PROPERTY_MP_MAP_PLOT_INT,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(6)={(
		Id=PROPERTY_MP_MAP_PLOT_INT,
		Name="MP Map Plot Int",
		NamedIds[0]=(Id=PROPERTY_MP_MAP_PLOT_INT,Name="STEAM"),
	)}

	Properties(7)=(PropertyId=PROPERTY_MP_MAP_BIOME_INT,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(7)={(
		Id=PROPERTY_MP_MAP_BIOME_INT,
		Name="MP Map Biome Int",
		NamedIds[0]=(Id=PROPERTY_MP_MAP_BIOME_INT,Name="STEAM"),
	)}

	Properties(8)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(8)={(
		Id=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,
		Name="MP Ranked Rating",
		NamedIds[0]=(Id=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Name="PSN")
	)}

	Properties(9)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(9)={(
		Id=PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN,
		Name="Deathmatch Ranked Rating Min",
		NamedIds[0]=(Id=PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MIN,Name="PSN")
	)}

	Properties(10)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(10)={(
		Id=PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX,
		Name="Deathmatch Ranked Rating Max",
		NamedIds[0]=(Id=PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_DEATHMATCH_RANKED_QUERY_RATING_MAX,Name="PSN")
	)}

	Properties(11)=(PropertyId=PROPERTY_MP_MAXSQUADCOST_MIN,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(11)={(
		Id=PROPERTY_MP_MAXSQUADCOST_MIN,
		Name="MP Squad Cost Min",
		NamedIds[0]=(Id=PROPERTY_MP_MAXSQUADCOST_MIN,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_MAXSQUADCOST_MIN,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_MAXSQUADCOST_MIN,Name="PSN")
	)}

	Properties(12)=(PropertyId=PROPERTY_MP_MAXSQUADCOST_MAX,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(12)={(
		Id=PROPERTY_MP_MAXSQUADCOST_MAX,
		Name="MP Squad Cost Max",
		NamedIds[0]=(Id=PROPERTY_MP_MAXSQUADCOST_MAX,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_MAXSQUADCOST_MAX,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_MAXSQUADCOST_MAX,Name="PSN")
	)}

	Properties(13)=(PropertyId=PROPERTY_MP_TURNTIMESECONDS_MIN,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(13)={(
		Id=PROPERTY_MP_TURNTIMESECONDS_MIN,
		Name="MP Turn Time Min",
		NamedIds[0]=(Id=PROPERTY_MP_TURNTIMESECONDS_MIN,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_TURNTIMESECONDS_MIN,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_TURNTIMESECONDS_MIN,Name="PSN")
	)}

	Properties(14)=(PropertyId=PROPERTY_MP_TURNTIMESECONDS_MAX,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(14)={(
		Id=PROPERTY_MP_TURNTIMESECONDS_MAX,
		Name="MP Turn Time Max",
		NamedIds[0]=(Id=PROPERTY_MP_TURNTIMESECONDS_MAX,Name="LIVE"),
		NamedIds[1]=(Id=PROPERTY_MP_TURNTIMESECONDS_MAX,Name="STEAM"),
		NamedIds[2]=(Id=PSN_PROPERTY_MP_TURNTIMESECONDS_MAX,Name="PSN")
	)}

	Properties(15)=(PropertyId=PROPERTY_MP_BYTECODEHASHINDEX,Data=(Type=SDT_String),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(15)={(
		Id=PROPERTY_MP_BYTECODEHASHINDEX,
		Name="Byte Code Hash Index",
		NamedIds[0]=(Id=PROPERTY_MP_BYTECODEHASHINDEX,Name="STEAM"),
	)}


	Properties(16)=(PropertyId=PROPERTY_MP_MAP_PLOT_MIN,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(16)={(
		Id=PROPERTY_MP_MAP_PLOT_MIN,
		Name="MP Map Plot Min",
		NamedIds[0]=(Id=PROPERTY_MP_MAP_PLOT_MIN,Name="STEAM"),
	)}

	Properties(17)=(PropertyId=PROPERTY_MP_MAP_PLOT_MAX,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(17)={(
		Id=PROPERTY_MP_MAP_PLOT_MAX,
		Name="MP Map Plot Max",
		NamedIds[0]=(Id=PROPERTY_MP_MAP_PLOT_MAX,Name="STEAM"),
	)}

	Properties(18)=(PropertyId=PROPERTY_MP_MAP_BIOME_MIN,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(18)={(
		Id=PROPERTY_MP_MAP_BIOME_MIN,
		Name="MP Map Biome Min",
		NamedIds[0]=(Id=PROPERTY_MP_MAP_BIOME_MIN,Name="STEAM"),
	)}

	Properties(19)=(PropertyId=PROPERTY_MP_MAP_BIOME_MAX,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	PropertyMappings(19)={(
		Id=PROPERTY_MP_MAP_BIOME_MAX,
		Name="MP Map Biome Max",
		NamedIds[0]=(Id=PROPERTY_MP_MAP_BIOME_MAX,Name="STEAM"),
	)}

	// NOTE: Setting Value1 to (1) to make sure that we only search for servers that are ready, confirm that the property default is (0) to start in a "hidden" state.
	Properties(20)=(PropertyId=PROPERTY_MP_SERVER_READY,Data=(Type=SDT_Int32,Value1=1),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(20)={(
		Id=PROPERTY_MP_SERVER_READY,
		Name="MP Server Ready",
		NamedIds[0]=(Id=PROPERTY_MP_SERVER_READY,Name="STEAM"),
	)}

	Properties(21)=(PropertyId=PROPERTY_MP_INSTALLED_DLC_HASH,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(21)={(
		Id=PROPERTY_MP_INSTALLED_DLC_HASH,
		Name="Installed DLC Hash",
		NamedIds[0]=(Id=PROPERTY_MP_INSTALLED_DLC_HASH,Name="STEAM"),
	)}

	Properties(22)=(PropertyId=PROPERTY_MP_INSTALLED_MODS_HASH,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(22)={(
		Id=PROPERTY_MP_INSTALLED_MODS_HASH,
		Name="Installed Mods Hash",
		NamedIds[0]=(Id=PROPERTY_MP_INSTALLED_MODS_HASH,Name="STEAM"),
	)}

	Properties(23)=(PropertyId=PROPERTY_MP_DEV_CONSOLE_ENABLED,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(23)={(
		Id=PROPERTY_MP_DEV_CONSOLE_ENABLED,
		Name="Dev Console Enabled",
		NamedIds[0]=(Id=PROPERTY_MP_DEV_CONSOLE_ENABLED,Name="STEAM"),
	)}

	Properties(24)=(PropertyId=PROPERTY_MP_INI_HASH,Data=(Type=SDT_String),AdvertisementType=ODAT_OnlineService)
	PropertyMappings(24)={(
		Id=PROPERTY_MP_INI_HASH,
		Name="INI Hash",
		NamedIds[0]=(Id=PROPERTY_MP_INI_HASH,Name="STEAM"),
	)}


	// Default search criteria: INI Version AND Network Type
	FilterQuery={( // All of these must be satisfied
		OrClauses[0]={( // Any of these will satisfy the search
			OrParams[0]=(EntryId=PROPERTY_MP_DATA_INI_VERSION,ObjectPropertyName="MP Data INI version",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[1]={( // Any of these will satisfy the search
			OrParams[0]=(EntryId=PROPERTY_MP_NETWORKTYPE,ObjectPropertyName="MP Network Type",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)}
	)}
}
