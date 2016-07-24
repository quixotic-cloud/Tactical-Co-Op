//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalTutorialMgr.uc
//  AUTHOR:  Brit Steiner - 11/15/2011
//  PURPOSE: This file is a logic class to control input flow via Kismet.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIInputGate extends Actor;

struct TButtonInputState
{
	var int  cmd; 
	var bool bReportToKismet; 
	var bool bIsLocked; 
	var bool bIsValid; 

	structdefaultproperties
	{
		cmd             = FXS_INPUT_NONE; 
		bReportToKismet = true; 
		bIsLocked       = true;
		bIsValid        = false;
	}
};



// General for Mgr 
var XComPlayerController    controller; 
var UIMovie              manager;

// Members 
var array<TButtonInputState> m_arrButtons; 
var bool m_bIsActive; 

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

simulated function Init()
{
}

simulated function bool OnUnrealCommand( int cmd, int action )
{
	local TButtonInputState tButtonState; 

	if( !m_bIsActive ) return false; 

	tButtonState = GetButtonState( cmd );

	if( tButtonState.bIsLocked ) 
		return true;

	if( !tButtonState.bIsValid ) 
		return true;

	return false; 
}

simulated function Activate( bool bIsActive )
{
	m_bIsActive = bIsActive; 

	if( !m_bIsActive )
		m_arrButtons.Length = 0; 
}

simulated function TButtonInputState GetButtonState( int cmd )
{
	local int index; 
	local TButtonInputState defaultButtonState; 

	index = m_arrButtons.Find( 'cmd', cmd );

	if( index > -1 )
		return m_arrButtons[index];
	else 
		return defaultButtonState; 
}

public simulated function SetGate( int cmd, bool bReportToKismet, bool bLocked )
{
	local int index; 
	local TButtonInputState kButton; 


	kButton.cmd = cmd;
	kButton.bReportToKismet = bReportToKismet; 
	kButton.bIsLocked = bLocked;
	kButton.bIsValid = true; 

	//Search, since we only allow one registration per cmd. 
	index = m_arrButtons.Find( 'cmd', cmd );
	if( index > -1 )
		m_arrButtons[index] = kButton; 
	else
		m_arrButtons.AddItem( kButton );
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	m_bIsActive = false; 
}
