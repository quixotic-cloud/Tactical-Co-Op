//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComUIBroadcastWorldMessage_UnitReflectedAttack.uc
//  AUTHOR:  Todd Smith  --  5/22/2012
//  PURPOSE: Broadcasts a message when a unit reflects an attack.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComUIBroadcastWorldMessage_UnitReflectedAttack extends XComUIBroadcastWorldMessage;

struct XComUIBroadcastWorldMessageData_UnitReflectedAttack extends XComUIBroadcastWorldMessageData
{
	var XGUnit m_kUnit;
};

var private XComUIBroadcastWorldMessageData_UnitReflectedAttack  m_kMessageData_UnitReflectedAttack;
var private bool                                                 m_bMessageDisplayed_UnitReflectedAttack;

function Init_UnitReflectedAttack(XGUnit kUnit, Vector vLocation, EWidgetColor eColor, ETeam eBroadcastToTeams)
{
	BaseInit(eBroadcastToTeams);

	m_kMessageData_UnitReflectedAttack.m_kUnit = kUnit;
	m_kMessageData_UnitReflectedAttack.m_vLocation = vLocation;
	m_kMessageData_UnitReflectedAttack.m_eColor = eColor;
}