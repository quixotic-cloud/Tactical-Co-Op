//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastMessage.uc
//  AUTHOR:  Todd Smith  --  4/13/2010
//  PURPOSE: Broadcasts UI messages to network players. Displays using the Messenger.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastMessage extends XComUIBroadcastMessageBase
	abstract;

struct XComUIBroadcastMessageData
{
	var string    m_sMsg;
	var EUIIcon   m_iIcon;
	var EUIPulse  m_iPulse;
	var float     m_fTime;
	var string    m_id;
};

var private XComUIBroadcastMessageData m_kMessageData;
var private bool                       m_bMessageDisplayed;

function Init(string sMsg, EUIIcon iIcon, EUIPulse iPulse, float fTime, string id, ETeam eBroadcastToTeams)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData.m_sMsg = sMsg;
	m_kMessageData.m_iIcon = iIcon;
	m_kMessageData.m_iPulse = iPulse;
	m_kMessageData.m_fTime = fTime;
	m_kMessageData.m_id = id;
}

defaultproperties
{
	m_bMessageDisplayed=false;
}