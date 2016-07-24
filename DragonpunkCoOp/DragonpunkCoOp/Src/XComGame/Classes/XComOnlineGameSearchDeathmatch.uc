//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineGameSearchDeathmatch.uc
//  AUTHOR:  Todd Smith  --  9/20/2011
//  PURPOSE: Search class for unranked deathmatch games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComOnlineGameSearchDeathmatch extends XComOnlineGameSearch
	abstract;

defaultproperties
{
	// We are only searching for deathmatch sessions
	LocalizedSettings(0)=(Id=CONTEXT_GAME_MODE,ValueIndex=CONTEXT_GAME_MODE_DEATHMATCH,AdvertisementType=ODAT_OnlineService)
}

