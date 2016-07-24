//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastAnchoredMessage.uc
//  AUTHOR:  Todd Smith  --  4/14/2010
//			 Brit Steiner - 9/16/2014 - removing deprecated network replication. 
//  PURPOSE: Broadcasts UI messages to players. Displays using the AnchoredMessenger.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastAnchoredMessage extends XComUIBroadcastMessageBase;

struct XComUIBroadcastAnchoredMessageData
{
	// @UI: can we make all the string messages FNames that way we only replicate an index.-tsmith 
	// alternatively, if we run into hitting the max packet size we can replicate the string seperately
	// it will make the replication code a bit more complicated as we would need to wait for both the struct
	// and the string to replicate before showing the message and closing network channels-tsmith 
	var string     											m_sMsg; 
	var float      											m_xLoc; 
	var float      											m_yLoc;
	var EUIAnchor  											m_eAnchor;
	var float      											m_fDisplayTime;
	var string     											m_sId;
	var EUIIcon                                         	m_eIcon;
};

var private XComUIBroadcastAnchoredMessageData    m_kMessageData;
var private bool                                  m_bMessageDisplayed;

function Init(string sMsg, float xLoc, float yLoc, EUIAnchor eAnchor, float fDisplayTime, string sId, EUIIcon eIcon, ETeam eBroadcastToTeams)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData.m_sMsg = sMsg;
	m_kMessageData.m_xLoc = xLoc;
	m_kMessageData.m_yLoc = yLoc;
	m_kMessageData.m_eAnchor = eAnchor;
	m_kMessageData.m_fDisplayTime = fDisplayTime;
	m_kMessageData.m_sId = sId;
	m_kMessageData.m_eIcon = eIcon;
}
