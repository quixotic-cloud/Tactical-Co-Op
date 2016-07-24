//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UI_FxsMessageBox
//  AUTHOR:  Brit Steiner  --  02/27/09
//  PURPOSE: This file contains the data elements for a custom pop up message in the 
//           UIMessageMgr system.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UI_FxsMessageBox extends UIPanel
	dependson(UIMessageMgr);


var protected string	m_strTitle;
var protected EUIPulse  m_ePulse;
var protected EUIIcon   m_eIcon;
var protected float     m_fTime;


//==============================================================================
// 		GENERAL FUNCTIONS:
//==============================================================================

simulated function Init( coerce name InitName )
{
	InitPanel(InitName);
}

simulated function OnInit()
{
	super.OnInit();
	
	SetDisplay();
	//SetMessageLocationY();
	if( m_fTime > 0 )
		SetTimer( m_fTime,,'AnimateOut');
}

/**
 * Processes the display data for flash, and then will animate in
 * */
simulated function SetDisplay()
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	myValue.Type = AS_String;
	myValue.s = GetTitle();
	myArray.AddItem( myValue );

	myValue.Type = AS_Number;
	myValue.n = GetIcon();
	myArray.AddItem( myValue );
	myValue.n = GetPulse();
	myArray.AddItem( myValue );

	Invoke("SetDisplay", myArray);
}

simulated function AnimateOut(optional float Delay = -1.0)
{
	Remove();
}

//==============================================================================
// 		HELPER FUNCTIONS:
//==============================================================================

simulated function SetTitle( string _sMessage )     {	m_strTitle = _sMessage;}
simulated function string GetTitle()		        {	return m_strTitle;}

simulated function SetPulse( EUIPulse _ePulse )     {	m_ePulse = _ePulse;}
simulated function EUIPulse GetPulse()              {	return m_ePulse;}

simulated function SetTime( float _fTime )          {	m_fTime = _fTime;}
simulated function float GetTime()                  {	return m_fTime;}

simulated function LoadIcon( EUIIcon _eIcon )        {	m_eIcon = _eIcon;}
simulated function EUIIcon GetIcon()                {   return m_eIcon ;}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	m_strTitle  = "Generic Title";
	m_ePulse    = ePulse_None; 
	m_eIcon     = eIcon_GenericCircle;
	m_fTime     = 5.0;
}

//---------------------------------------------------------------------
//---------------------------------------------------------------------

