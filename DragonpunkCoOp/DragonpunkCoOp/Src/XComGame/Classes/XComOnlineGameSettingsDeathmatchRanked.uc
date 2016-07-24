//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineGameSettingsDeathmatchRanked.uc
//  AUTHOR:  Todd Smith  --  9/19/2011
//  PURPOSE: Game settings for the ranked deathmatch games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComOnlineGameSettingsDeathmatchRanked extends XComOnlineGameSettingsDeathmatch
	dependson(XComOnlineGameSearch)
	config(MPGame);


var private config bool     DEBUG_bDisableRandomMap;


function SetNetworkType(EMPNetworkType eNetworkType)
{
	// network type is hardcoded to public -tsmith 
}
function SetGameType(EMPGameType eGameType)
{
	// gametype is hardcoded to deathmatch -tsmith 
}
function SetTurnTimeSeconds(int iTurnTimeSeconds)
{
	// turntimer is hardcoded -tsmith 
	`if(`notdefined(FINAL_RELEASE))
		if(DEBUG_bChangeRankedGameOptions)
		{
			super.SetTurnTimeSeconds(iTurnTimeSeconds);
		}
	`endif
}
function SetMaxSquadCost(int iMaxSquadCost)
{
	// max squad cost is hardcoded -tsmith 
	`if(`notdefined(FINAL_RELEASE))
		if(DEBUG_bChangeRankedGameOptions)
		{
			super.SetMaxSquadCost(iMaxSquadCost);
		}
	`endif
}

function SetIsRanked(bool bIsRanked)
{
	// as the name of the class states... -tsmith 
}

function SetMapPlotType(string strMapPlotType)
{
}

function SetMapBiomeType(string strMapBiomeType)
{
}

function SetHostRankedRating(int iRankedRating)
{
	SetIntProperty(PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING, iRankedRating);
}

function int GetHostRankedRating()
{
	local int intFromProperties;
	GetIntProperty(PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING, intFromProperties);
	return intFromProperties;
}

defaultproperties
{
	OnlineStatsWriteClasses(0)=(WriteType="TacticalGameStart",WriteClass=class'XComGame.XComOnlineStatsWriteDeathmatchRankedGameStartedFlag')
	OnlineStatsWriteClasses(1)=(WriteType="TacticalGameEnd",WriteClass=class'XComGame.XComOnlineStatsWriteDeathmatchRanked')
	OnlineStatsWriteClasses(2)=(WriteType="Disconnected",WriteClass=class'XComGame.XComOnlineStatsWriteDeathmatchRanked')

	OnlineStatsWriteClass=class'XComGame.XComOnlineStatsWriteDeathmatchRanked'
	OnlineStatsReadClass=class'XComGame.XComOnlineStatsReadDeathmatchRanked'

	// These are only joinable via matchmaking, no invites or jip
	bAllowInvites=false
	bUsesPresence=false
	bAllowJoinViaPresence=false
	bIsLanMatch=false

	// ranked -tsmith 	
	// our ranked games no longer use arbitration due to the fact we can't flush stats at the beginning of the game
	// which is when we write our match started flag. also xbox live is the online backend that actually uses it. -tsmith 5.30.2012
	//bUsesArbitration=true
	bUsesArbitration=false

	/************************************************************************/
	/* NOTE: VERY IMPORTANT!!! IF THIS ARRAY IS CHANGED YOU MUST MAKE SURE	*/
	/*       DERIVED CLASSES ARE ADJUSTED ACCORDINGLY!!!!	                */	
	/*       INDICES MUST STAY THE SAME AS THE SUPERCLASS AS WELL           */
	/************************************************************************/
	// overrides for ranked matches -tsmith 
	Properties(1)=(PropertyId=PROPERTY_MP_NETWORKTYPE,Data=(Type=SDT_Int32,Value1=eMPNetworkType_Public),AdvertisementType=ODAT_OnlineService);
	Properties(2)=(PropertyId=PROPERTY_MP_GAMETYPE,Data=(Type=SDT_Int32,Value1=eMPGameType_Deathmatch),AdvertisementType=ODAT_OnlineService);
	Properties(3)=(PropertyId=PROPERTY_MP_TURNTIMESECONDS,Data=(Type=SDT_Int32,Value1=90),AdvertisementType=ODAT_OnlineService);
	Properties(4)=(PropertyId=PROPERTY_MP_MAXSQUADCOST,Data=(Type=SDT_Int32,Value1=10000),AdvertisementType=ODAT_OnlineService);
	Properties(5)=(PropertyId=PROPERTY_MP_ISRANKED,Data=(Type=SDT_Int32,Value1=EROP_Ranked),AdvertisementType=ODAT_OnlineService);
	Properties(6)=(PropertyId=PROPERTY_MP_MAP_PLOT_INT,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	Properties(7)=(PropertyId=PROPERTY_MP_MAP_BIOME_INT,Data=(Type=SDT_Int32,Value1=-1),AdvertisementType=ODAT_OnlineService);
	Properties(8)=(PropertyId=PROPERTY_MP_DEATHMATCH_RANKED_GAME_RATING,Data=(Type=SDT_Int32,Value1=0),AdvertisementType=ODAT_OnlineService);
	Properties(9)=(PropertyId=PROPERTY_MP_BYTECODEHASHINDEX,Data=(Type=SDT_String),AdvertisementType=ODAT_OnlineService)
	Properties(10)=(PropertyId=PROPERTY_MP_ISAUTOMATCH,Data=(Type=SDT_Int32,Value1=1),AdvertisementType=ODAT_OnlineService);
}