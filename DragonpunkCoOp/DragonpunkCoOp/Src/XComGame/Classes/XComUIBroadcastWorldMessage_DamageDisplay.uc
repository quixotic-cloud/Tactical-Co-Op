//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastWorldMessage_DamageDisplay.uc
//  AUTHOR:  Todd Smith  --  5/15/2012
//  PURPOSE: Broadcasts a message that calls DamageDisplay, ensures everything is localized correctly.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastWorldMessage_DamageDisplay extends XComUIBroadcastWorldMessage;

enum EUIBWMDamageDisplayType
{
	eUIBWMDamageDisplayType_Miss,
	eUIBWMDamageDisplayType_Hit,
	eUIBWMDamageDisplayType_CriticalHit,
	eUIBWMDamageDisplayType_GrazeHit,
};

struct XComUIBroadcastWorldMessageData_DamageDisplay extends XComUIBroadcastWorldMessageData
{
	var EUIBWMDamageDisplayType m_eDamageType;
	var int                     m_iActualDamage;
};

var private XComUIBroadcastWorldMessageData_DamageDisplay m_kMessageData_DamageDisplay;
var private bool                                          m_bMessageDisplayed_DamageDisplay;

function Init_DisplayDamage(EUIBWMDamageDisplayType eDamageType , Vector vLocation, StateObjectReference kTarget, int iActualDamage, ETeam eBroadcastToTeams)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData_DamageDisplay.m_eDamageType = eDamageType;
	m_kMessageData_DamageDisplay.m_vLocation = vLocation;
	m_kMessageData_DamageDisplay.m_iActualDamage = iActualDamage;
	m_kMessageData_DamageDisplay.m_kFollowObject = kTarget;
}
