//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastMessage_UnitBleedingOut.uc
//  AUTHOR:  Todd Smith  --  5/23/2012
//  PURPOSE: Broadcasts a UI message about a unit bleeding out. Displays using the Messenger.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastMessage_UnitBleedingOut extends XComUIBroadcastMessage;

struct XComUIBroadcastMessageData_UnitBleedingOut extends XComUIBroadcastMessageData
{
	var EExpandedLocalizedStrings   m_eExpandedLocalizedStringIndex;
	var XGUnit                      m_kUnit;
	var int                         m_iCriticalWoundCounter;
};

var private XComUIBroadcastMessageData_UnitBleedingOut m_kMessageData_UnitBleedingOut;
var private bool                                       m_bMessageDisplayed_UnitBleedingOut;

function Init_UnitBleedingOut(
	EExpandedLocalizedStrings eExpandedLocalizedStringIndex, 
	XGUnit kUnit, 
	int iCriticalWoundCounter,
	ETeam eBroadcastToTeams,
	EUIIcon iIcon           = eIcon_GenericCircle, 
	EUIPulse iPulse         = ePulse_None, 
	float fTime             = 2.0, 
	string id               = "default" )
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData_UnitBleedingOut.m_eExpandedLocalizedStringIndex = eExpandedLocalizedStringIndex;
	m_kMessageData_UnitBleedingOut.m_kUnit = kUnit;
	m_kMessageData_UnitBleedingOut.m_iCriticalWoundCounter = iCriticalWoundCounter;
	m_kMessageData_UnitBleedingOut.m_iIcon = iIcon;
	m_kMessageData_UnitBleedingOut.m_iPulse = iPulse;
	m_kMessageData_UnitBleedingOut.m_fTime = fTime;
	m_kMessageData_UnitBleedingOut.m_id = id;
}

defaultproperties
{
	m_bMessageDisplayed_UnitBleedingOut=false;
}