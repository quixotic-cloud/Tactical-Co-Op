//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastMessage_ExpandUnitNameString.uc
//  AUTHOR:  Todd Smith  --  5/23/2012
//  PURPOSE: Broadcasts a UI message that expands a localized string based on unit info. 
//           Displays using the Messenger.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastMessage_ExpandUnitNameString extends XComUIBroadcastMessage;

struct XComUIBroadcastMessageData_ExpandUnitNameString extends XComUIBroadcastMessageData
{
	var EExpandedLocalizedStrings   m_eExpandedLocalizedStringIndex;
	var XGUnit                      m_kUnit;
};

var private XComUIBroadcastMessageData_ExpandUnitNameString  m_kMessageData_ExpandUnitNameString;
var private bool                                             m_bMessageDisplayed_ExpandUnitNameString;

function Init_ExpandUnitNameString(
	EExpandedLocalizedStrings eExpandedLocalizedStringIndex, 
	XGUnit kUnit, 
	ETeam eBroadcastToTeams,
	EUIIcon iIcon           = eIcon_GenericCircle, 
	EUIPulse iPulse         = ePulse_None, 
	float fTime             = 2.0, 
	string id               = "default" )
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData_ExpandUnitNameString.m_eExpandedLocalizedStringIndex = eExpandedLocalizedStringIndex;
	m_kMessageData_ExpandUnitNameString.m_kUnit = kUnit;
	m_kMessageData_ExpandUnitNameString.m_iIcon = iIcon;
	m_kMessageData_ExpandUnitNameString.m_iPulse = iPulse;
	m_kMessageData_ExpandUnitNameString.m_fTime = fTime;
	m_kMessageData_ExpandUnitNameString.m_id = id;
}

defaultproperties
{
	m_bMessageDisplayed_ExpandUnitNameString=false;
}