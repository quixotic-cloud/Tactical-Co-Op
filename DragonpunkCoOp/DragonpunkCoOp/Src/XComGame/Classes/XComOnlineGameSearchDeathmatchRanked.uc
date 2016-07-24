//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineGameSearchDeathmatchRanked.uc
//  AUTHOR:  Todd Smith  --  9/20/2011
//  PURPOSE: Search class for ranked deathmatch games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineGameSearchDeathmatchRanked extends XComOnlineGameSearchDeathmatch
	config(MPGame);

var config int  m_iRankedSearchRatingDelta;
var const int   m_iFinalRankedSearchRatingDelta;

defaultproperties
{
	m_iFinalRankedSearchRatingDelta=MaxInt

	Query=(ValueIndex=SESSION_MATCH_QUERY_DEATHMATCHRANKED)

	// The class to use for any search results. 
	GameSettingsClass=class'XComGame.XComOnlineGameSettingsDeathmatchRanked'

	// ranked -tsmith 
	// our ranked games no longer use arbitration due to the fact we can't flush stats at the beginning of the game
	// which is when we write our match started flag. also xbox live is the online backend that actually uses it. -tsmith 5.30.2012
	//bUsesArbitration=true
	bUsesArbitration=false

	// Parent property overrides -ttalley
	Properties(5)=(PropertyId=PROPERTY_MP_ISRANKED,Data=(Type=SDT_Int32,Value1=EROP_Ranked),AdvertisementType=ODAT_OnlineService)

	FilterQuery={( // All of the OrClauses must be satisfied
		OrClauses[0]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_DATA_INI_VERSION,ObjectPropertyName="MP Data INI version",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[1]={( // Any of these will satisfy the search
			OrParams[0]=(EntryId=PROPERTY_MP_NETWORKTYPE,ObjectPropertyName="MP Network Type",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[2]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,ObjectPropertyName="Deathmatch Ranked Rating Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[3]={( // Any of the OrParams may be satisfied
			// Maps the Rating Max value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,ObjectPropertyName="Deathmatch Ranked Rating Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},
		OrClauses[4]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_ISRANKED,ObjectPropertyName="MP Is Ranked",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[5]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_SERVER_READY,ObjectPropertyName="MP Server Ready",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[6]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_INSTALLED_DLC_HASH,ObjectPropertyName="Installed DLC Hash",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[7]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_INSTALLED_MODS_HASH,ObjectPropertyName="Installed Mods Hash",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[8]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_DEV_CONSOLE_ENABLED,ObjectPropertyName="Dev Console Enabled",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[9]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_INI_HASH,ObjectPropertyName="INI Hash",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
		OrClauses[10]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_BYTECODEHASHINDEX,ObjectPropertyName="Byte Code Hash Index",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},
	)}
}
