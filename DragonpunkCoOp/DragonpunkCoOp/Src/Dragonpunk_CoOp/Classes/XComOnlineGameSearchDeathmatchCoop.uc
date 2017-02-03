// This is an Unreal Script
                           
class XComOnlineGameSearchDeathmatchCoop extends XComOnlineGameSearchDeathmatch;

defaultproperties
{
	Query=(ValueIndex=SESSION_MATCH_QUERY_DEATHMATCHCUSTOM)

	// The class to use for any search results. 
	GameSettingsClass=class'XComGame.XComOnlineGameSettingsDeathmatchUnranked'

	bUsesArbitration=false

	FilterQuery={( // All of the OrClauses must be satisfied

		OrClauses[0]={( // Any of the OrParams may be satisfied
			OrParams[0]=(EntryId=PROPERTY_MP_ISRANKED,ObjectPropertyName="MP Is Ranked",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

		// POINTS
		OrClauses[1]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAXSQUADCOST,ObjectPropertyName="MP Squad Cost Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[2]={( // Any of the OrParams may be satisfied
			// Maps the Rating Max value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAXSQUADCOST,ObjectPropertyName="MP Squad Cost Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// TURN TIME
		OrClauses[3]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_TURNTIMESECONDS,ObjectPropertyName="MP Turn Time Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[4]={( // Any of the OrParams may be satisfied
			// Maps the Rating Max value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_TURNTIMESECONDS,ObjectPropertyName="MP Turn Time Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// MAP PLOT
		OrClauses[5]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAP_PLOT_INT,ObjectPropertyName="MP Map Plot Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[6]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAP_PLOT_INT,ObjectPropertyName="MP Map Plot Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// MAP Biome
		OrClauses[7]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAP_BIOME_INT,ObjectPropertyName="MP Map Biome Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[8]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAP_BIOME_INT,ObjectPropertyName="MP Map Biome Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// NETWORK TYPE
		OrClauses[9]={( // Any of these will satisfy the search
			OrParams[0]=(EntryId=PROPERTY_MP_NETWORKTYPE,ObjectPropertyName="MP Network Type",EntryType=OGSET_Property,ComparisonType=OGSCT_Equals)
		)},

				// POINTS
		OrClauses[10]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAXSQUADCOST,ObjectPropertyName="MP Squad Cost Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[11]={( // Any of the OrParams may be satisfied
			// Maps the Rating Max value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_MAXSQUADCOST,ObjectPropertyName="MP Squad Cost Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

		// TURN TIME
		OrClauses[12]={( // Any of the OrParams may be satisfied
			// Maps the Rating Min value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_TURNTIMESECONDS,ObjectPropertyName="MP Turn Time Min",EntryType=OGSET_Property,ComparisonType=OGSCT_GreaterThanEquals)
		)},
		OrClauses[13]={( // Any of the OrParams may be satisfied
			// Maps the Rating Max value to the Game Rating parameter name
			OrParams[0]=(EntryId=PROPERTY_MP_TURNTIMESECONDS,ObjectPropertyName="MP Turn Time Max",EntryType=OGSET_Property,ComparisonType=OGSCT_LessThanEquals)
		)},

	)}
}