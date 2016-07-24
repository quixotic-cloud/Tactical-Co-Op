//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComOnlineGameSettingsDeathmatchUnranked.uc
//  AUTHOR:  Todd Smith  --  9/19/2011
//  PURPOSE: Game settings for the base deathmatch games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComOnlineGameSettingsDeathmatchUnranked extends XComOnlineGameSettingsDeathmatch
	dependson(XComOnlineGameSearch);

defaultproperties
{
	OnlineStatsWriteClass=class'XComGame.XComOnlineStatsWriteDeathmatchUnranked'
	OnlineStatsReadClass=class'XComGame.XComOnlineStatsReadDeathmatchUnranked'

	bUsesArbitration = false

	Properties(5)=(PropertyId=PROPERTY_MP_ISRANKED,Data=(Type=SDT_Int32,Value1=EROP_Unranked_Public),AdvertisementType=ODAT_OnlineService);
}