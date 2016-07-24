//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineGameSettingsDeathmatch.uc
//  AUTHOR:  Todd Smith  --  9/19/2011
//  PURPOSE: Game settings for the base deathmatch games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComOnlineGameSettingsDeathmatch extends XComOnlineGameSettings
	abstract;

defaultproperties
{
	OnlineStatsWriteClass=class'XComGame.XComOnlineStatsWriteDeathmatch'
	OnlineStatsReadClass=class'XComGame.XComOnlineStatsReadDeathmatch'

	// 1 v 1 -tsmith 
	NumPublicConnections=2
	NumPrivateConnections=0

	/************************************************************************/
	/* NOTE: VERY IMPORTANT!!! IF THIS ARRAY IS CHANGED YOU MUST MAKE SURE	*/
	/*       DERIVED CLASSES ARE ADJUSTED ACCORDINGLY!!!!					*/
	/************************************************************************/

	LocalizedSettings(0)=(Id=CONTEXT_GAME_MODE,ValueIndex=CONTEXT_GAME_MODE_DEATHMATCH,AdvertisementType=ODAT_OnlineService)
	LocalizedSettingsMappings(0)=(Id=CONTEXT_GAME_MODE)
}