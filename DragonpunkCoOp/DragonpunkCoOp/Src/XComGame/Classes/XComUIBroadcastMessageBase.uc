//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastMessageBase.uc
//  AUTHOR:  Todd Smith  --  4/9/2010
//  PURPOSE: Base class used to broadcast UI messages to network players.
//           Broadcasts to all teams by default but has the ability to only replicate to specific teams.           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastMessageBase extends Actor
	abstract;

/**
 * Initialize the message object
 * 
 * @param eVisibleToTeams   a bitwise OR of all the teams this message should be sent to.
 */
function BaseInit(optional ETeam eBroadcastToTeams=eTeam_All)
{
	SetTeamType(eBroadcastToTeams);
}

defaultproperties
{
	//RemoteRole=ROLE_SimulatedProxy;
	RemoteRole=ROLE_None
	bOnlyRelevantToFriendlies=true;
	bNetTemporary=true;
	LifeSpan=5.00;
	m_eTeam=eTeam_All;
}
