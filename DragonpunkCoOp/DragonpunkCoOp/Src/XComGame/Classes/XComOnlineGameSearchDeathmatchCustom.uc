//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineGameSearchDeathmatchCustom.uc
//  AUTHOR:  Timothy Talley  --  07/15/2012
//  PURPOSE: Search class for custom deathmatch games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComOnlineGameSearchDeathmatchCustom extends XComOnlineGameSearchDeathmatch
	config(MPGame);

defaultproperties
{
	Query=(ValueIndex=SESSION_MATCH_QUERY_DEATHMATCHCUSTOM)

	// The class to use for any search results. 
	GameSettingsClass=class'XComGame.XComOnlineGameSettingsDeathmatchUnranked'

	bUsesArbitration=false

	FilterQuery={( // All of the OrClauses must be satisfied
		OrClauses[0]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_DATA_INI_VERSION,ObjectPropertyName="MP Data INI version",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		OrClauses[1]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_ISRANKED,ObjectPropertyName="MP Is Ranked",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		// POINTS
		OrClauses[2]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAXSQUADCOST,ObjectPropertyName="MP Squad Cost Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[3]={( // Any of the OrParams may be satisfied
			// Maps the Rating Max value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAXSQUADCOST,ObjectPropertyName="MP Squad Cost Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// TURN TIME
		OrClauses[4]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_TURNTIMESECONDS,ObjectPropertyName="MP Turn Time Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[5]={( // Any of the OrParams may be satisfied
			// Maps the Rating Max value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_TURNTIMESECONDS,ObjectPropertyName="MP Turn Time Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// MAP PLOT
		OrClauses[6]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAP_PLOT_INT,ObjectPropertyName="MP Map Plot Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[7]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAP_PLOT_INT,ObjectPropertyName="MP Map Plot Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// MAP Biome
		OrClauses[8]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAP_BIOME_INT,ObjectPropertyName="MP Map Biome Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[9]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAP_BIOME_INT,ObjectPropertyName="MP Map Biome Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// NETWORK TYPE
		OrClauses[10]={( // Any of these will satisfy the search
			OrParams[0]=(EntryId=PROPERTY_MP_NETWORKTYPE,ObjectPropertyName="MP Network Type",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		// SERVER READY
		OrClauses[11]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_SERVER_READY,ObjectPropertyName="MP Server Ready",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		// INSTALLED DLC HASH
		OrClauses[12]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_INSTALLED_DLC_HASH,ObjectPropertyName="Installed DLC Hash",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		// INSTALLED MODS HASH
		OrClauses[13]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_INSTALLED_MODS_HASH,ObjectPropertyName="Installed Mods Hash",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		// DEV CONSOLE ENABLED
		OrClauses[14]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_DEV_CONSOLE_ENABLED,ObjectPropertyName="Dev Console Enabled",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		// INI HASH
		OrClauses[15]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_INI_HASH,ObjectPropertyName="INI Hash",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		// BYTE-CODE HASH
		OrClauses[16]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_BYTECODEHASHINDEX,ObjectPropertyName="Byte Code Hash Index",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},


	)}
}
