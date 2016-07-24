//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastWorldMessage.uc
//  AUTHOR:  Todd Smith  --  4/7/2010
//  PURPOSE: Broadcasts UI messages to network players. Displays using the WorldMessenger.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastWorldMessage extends XComUIBroadcastMessageBase;

struct XComUIBroadcastWorldMessageData
{
	var Vector         m_vLocation;
	var string         m_strMessage;
	var int            m_eColor;
	var int            m_eBehavior;
	var bool           m_bUseScreenLocationParam;
	var Vector2D       m_vScreenLocationParam;
	var float          m_fDisplayTime;
	var StateObjectReference m_kFollowObject;
	var bool                 m_bIsArmor;

	var string				m_sIconPath;		// Dynamically loading path 
	var int					m_iDamagePrimary;	// Will trigger using a damage-style message 
	var int					m_iDamageModified;	// Optional, will trigger modifier animation and display value updates
	var int                 m_iDamageType;
	var string              m_sCritlabel;       // Optional, if not empty, the message will style crit yellow 

	structdefaultproperties
	{
		m_sIconPath = ""; 
		m_iDamagePrimary = 0;
		m_iDamageModified = 0;
		m_sCritlabel = "";
	}
};

var private XComUIBroadcastWorldMessageData   m_kMessageData;
var private bool                              m_bMessageDisplayed;

function Init(Vector vLocation, 
			  StateObjectReference _kFollowObject,
			  string strMessage, 
			  int eColor, 
			  int eBehavior, 
			  bool bUseScreenLocationParam, 
			  Vector2D vScreenLocationParam,
			  float fDisplayTime, 
			  ETeam eBroadcastToTeams,
			  string _sIcon, 
			  int _iDamagePrimary,
			  int _iDamageModifier, 
			  string _sCritlabel,
			  int _damageType)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData.m_vLocation = vLocation;
	m_kMessageData.m_strMessage = strMessage;
	m_kMessageData.m_eColor = eColor;
	m_kMessageData.m_eBehavior = eBehavior;
	m_kMessageData.m_bUseScreenLocationParam = bUseScreenLocationParam;
	m_kMessageData.m_vScreenLocationParam = vScreenLocationParam;
	m_kMessageData.m_fDisplayTime = fDisplayTime;
	m_kMessageData.m_kFollowObject = _kFollowObject;
	m_kMessageData.m_sIconPath = _sIcon;
	m_kMessageData.m_iDamagePrimary = _iDamagePrimary;
	m_kMessageData.m_iDamageModified = _iDamageModifier;
	m_kMessageData.m_sCritlabel = _sCritlabel;
	m_kMessageData.m_iDamageType = _damageType;
}


defaultproperties
{
	m_bMessageDisplayed=false;
}
