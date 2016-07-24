//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastWorldMessage_BoneMarrowHPRegen.uc
//  AUTHOR:  Todd Smith  --  11/29/2012
//  PURPOSE: Broadcasts a message displaying the HP regen for bonemarrow gene mod
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastWorldMessage_BoneMarrowHPRegen extends XComUIBroadcastWorldMessage;

struct XComUIBroadcastWorldMessageData_BoneMarrowHPRegen extends XComUIBroadcastWorldMessageData
{
	var int                         m_iHPRegen;
	var EExpandedLocalizedStrings   m_eHPRegenString;
};

var private XComUIBroadcastWorldMessageData_BoneMarrowHPRegen m_kMessageData_BoneMarrowHPRegen;
var private bool                                              m_bMessageDisplayed_BoneMarrowHPRegen;

function Init_BoneMarrowHPRegen(EExpandedLocalizedStrings eHPRegenString, int iHPRegen, Vector vLocation, EWidgetColor eColor, ETeam eBroadcastToTeams)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData_BoneMarrowHPRegen.m_eHPRegenString = eHPRegenString;
	m_kMessageData_BoneMarrowHPRegen.m_iHPRegen = iHPRegen;
	m_kMessageData_BoneMarrowHPRegen.m_vLocation = vLocation;
	m_kMessageData_BoneMarrowHPRegen.m_eColor = eColor;
}

static final function string GetHPRegenText(EExpandedLocalizedStrings eHPRegenString, int iHPRegen)
{
	local XGParamTag kTag;
	
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.IntValue0 = iHPRegen;

	return `XEXPAND.ExpandString(`GAMECORE.m_aExpandedLocalizedStrings[eHPRegenString]);
}
