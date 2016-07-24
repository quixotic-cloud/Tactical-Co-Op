//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastWorldMessage_HoverFuel.uc
//  AUTHOR:  Todd Smith  --  5/22/2012
//  PURPOSE: Broadcasts a message displaying how much hover fuel remains
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastWorldMessage_HoverFuel extends XComUIBroadcastWorldMessage;

struct XComUIBroadcastWorldMessageData_HoverFuel extends XComUIBroadcastWorldMessageData
{
	var int                         m_iCurrentFuel;
	var int                         m_iMaxFuel;
	var EExpandedLocalizedStrings   m_eHoverFuelString;
};

var private XComUIBroadcastWorldMessageData_HoverFuel m_kMessageData_HoverFuel;
var private bool                                      m_bMessageDisplayed_HoverFuel;

function Init_HoverFuel(EExpandedLocalizedStrings eHoverFuelString, int iCurrentFuel, int iMaxFuel, Vector vLocation, EWidgetColor eColor, ETeam eBroadcastToTeams)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData_HoverFuel.m_eHoverFuelString = eHoverFuelString;
	m_kMessageData_HoverFuel.m_iCurrentFuel = iCurrentFuel;
	m_kMessageData_HoverFuel.m_iMaxFuel = iMaxFuel;
	m_kMessageData_HoverFuel.m_vLocation = vLocation;
	m_kMessageData_HoverFuel.m_eColor = eColor;
}

static final function string GetHoverFuelText(EExpandedLocalizedStrings eHoverFuelString, int iCurrentFuel, int iMaxFuel)
{
	local XGParamTag kTag;
	
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.IntValue0 = iCurrentFuel;
	kTag.IntValue1 = iMaxFuel;

	return `XEXPAND.ExpandString(`GAMECORE.m_aExpandedLocalizedStrings[eHoverFuelString]);
}