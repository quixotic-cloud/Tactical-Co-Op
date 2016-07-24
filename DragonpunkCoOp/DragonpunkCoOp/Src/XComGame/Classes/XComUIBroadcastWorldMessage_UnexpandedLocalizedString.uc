//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastWorldMessage_UnexpandedLocalizedString.uc
//  AUTHOR:  Todd Smith  --  5/22/2012
//  PURPOSE: Broadcasts a message that uses an unexpanded (XEXPAND.ExpandString) string
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastWorldMessage_UnexpandedLocalizedString extends XComUIBroadcastWorldMessage;

struct XComUIBroadcastWorldMessageData_UnexpandedLocalizedString extends XComUIBroadcastWorldMessageData
{
	var EUnexpandedLocalizedStrings m_eUnexpandedLocalizedStringIndex;
};

var private XComUIBroadcastWorldMessageData_UnexpandedLocalizedString m_kMessageData_UnexpandedLocalizedString;
var private bool                                                      m_bMessageDisplayed_UnexpandedLocalizedString;

function Init_UnexpandedLocalizedString(EUnexpandedLocalizedStrings eUnexpandedLocalizedStringIndex, Vector vLocation, StateObjectReference TargetActor, EWidgetColor eColor, ETeam eBroadcastToTeams)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData_UnexpandedLocalizedString.m_eUnexpandedLocalizedStringIndex = eUnexpandedLocalizedStringIndex;
	m_kMessageData_UnexpandedLocalizedString.m_vLocation = vLocation;
	m_kMessageData_UnexpandedLocalizedString.m_eColor = eColor;
	m_kMessageData_UnexpandedLocalizedString.m_kFollowObject = TargetActor;
}
