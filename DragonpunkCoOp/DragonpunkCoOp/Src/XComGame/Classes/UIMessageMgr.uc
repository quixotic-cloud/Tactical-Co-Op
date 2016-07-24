//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInfoBox
//  AUTHOR:  Brit Steiner  --  02/27/09
//  PURPOSE: This file controls the popup message box UI element. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMessageMgr extends UIMessageMgrBase
	native(UI);

var int DefaultMessageID;
var UIMessageMgr_Container m_MessageContainer;

// Valid flash pulse animation states, their ints translate to frame number to display, so the order listed here does matter!
enum EUIPulse
{	
	ePulse_None,
	ePulse_Cyan,
	ePulse_Blue,
	ePulse_Red
};

var UI_FxsMessageBox m_kEndTurnMessage;

//==============================================================================
// 		GENERAL FUNCTIONS:
//==============================================================================

simulated function InitMessageMgr(name InitName)
{
	InitPanel(InitName);
	m_MessageContainer = Spawn(class'UIMessageMgr_Container', self).InitMessageContainer();
}

// Only call Message() for popups that will animate out on their own/ not persistant. 
// If you want the message to be persistent, you will need to as the UI team for access functions. 
simulated function XComUIBroadcastMessage Message(  string    _sMsg, 
													EUIIcon   _iIcon   = eIcon_GenericCircle, 
													EUIPulse  _iPulse  = ePulse_None, 
													float     _fTime   = 2.0,
													string    _id      = "",
													optional ETeam     _eBroadcastToTeams = eTeam_None,
													optional class<XComUIBroadcastMessage> cBroadcastMessageClass = none)
{
	local bool bDisplayMessage, bBroadcastMessage;
	local int ibDisplayMessage, ibBroadcastMessage;
	local XComUIBroadcastMessage kBroadcastMessage;

	ShouldDisplayAndBroadcastMessage(
		ibDisplayMessage, 
		ibBroadcastMessage, 
		_eBroadcastToTeams, 
		`ShowVar(_sMsg) @
		`ShowVar(_iIcon) @
		`ShowVar(_iPulse) @
		`ShowVar(_fTime) @
		`ShowVar(_id) @
		`ShowVar(_eBroadcastToTeams));

	// unrealscript is teh suck and doesnt allow 'out bool' parameters to function hence the int hacks -tsmith 
	bDisplayMessage = ibDisplayMessage > 0;
	bBroadcastMessage = ibBroadcastMessage > 0;
	
	//ID must always be unique
	if( _id == "" )
		_id =  "default" $DefaultMessageID++; 

	//send the message down one level into the container.
	if(bDisplayMessage)
	{
		if (m_MessageContainer != none)
			m_MessageContainer.Message( _sMsg, _iIcon, _iPulse, _fTime, _id);
	}
	if(bBroadcastMessage)
	{
		if(cBroadcastMessageClass != none)
		{
			kBroadcastMessage = Spawn(cBroadcastMessageClass,,,,,,, _eBroadcastToTeams);
		}
		else
		{
			`warn(self $ "::" $ GetFuncName() @ "Message needs to be broadcast but no broadcast message class specified! Message text:" @ _sMsg, true, 'XCom_Net');
		}
	}

	return kBroadcastMessage;
}

simulated function UI_FxsMessageBox GetMessage( name id )
{
	return m_MessageContainer.GetMessage( id );
}

simulated function RemoveMessage( name id )
{
	m_MessageContainer.RemoveMessage( GetMessage(id) );
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxMessageMgr/MessageMgr";
	MCName = "theMessageContainer";
	DefaultMessageID = 0;
}
