//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastWorldMessage_PsiDrain.uc
//  AUTHOR:  Todd Smith  --  5/22/2012
//  PURPOSE: Broadcasts a message displaying how much hover fuel remains
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastWorldMessage_PsiDrain extends XComUIBroadcastWorldMessage;

struct XComUIBroadcastWorldMessageData_PsiDrain extends XComUIBroadcastWorldMessageData
{
	var int                         m_iHealthDrained;
	var EExpandedLocalizedStrings   m_ePsiDrainString;
};

var private XComUIBroadcastWorldMessageData_PsiDrain    m_kMessageData_PsiDrain;
var private bool                                        m_bMessageDisplayed_PsiDrain;

function Init_PsiDrain(EExpandedLocalizedStrings ePsiDrainString, int iHealthDrained, Vector vLocation, EWidgetColor eColor, ETeam eBroadcastToTeams)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData_PsiDrain.m_ePsiDrainString = ePsiDrainString;
	m_kMessageData_PsiDrain.m_iHealthDrained = iHealthDrained;
	m_kMessageData_PsiDrain.m_vLocation = vLocation;
	m_kMessageData_PsiDrain.m_eColor = eColor;
}

static final function string GetPsiDrainText(EExpandedLocalizedStrings ePsiDrainString, int iHealthDrained)
{
	local XGParamTag kTag;
	
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.IntValue0 = iHealthDrained;

	return `XEXPAND.ExpandString(`GAMECORE.m_aExpandedLocalizedStrings[ePsiDrainString]);
}
