//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITutorialSaveData.uc
//  AUTHOR:  Brit Steiner - 8/16/2010
//  PURPOSE: This file holds flags describing what tutorial messages have been fired. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITutorialSaveData extends Actor;

//----------------------------------------------------------------------------
// MEMBERS

// ---------------------------------------------------------------------------
// UITacticalHUD_AbilityContainer.uc : 
// Captures once an ability type initial help messages has been shown.
var array<int>    m_arrHelpMessages_AbilityTypes;


// XComTacticalInput.uc
// Captures if the tutorial movement messages have been shown
var bool m_bShownHowToMoveSoldiers;
var bool m_bShownHowToSwitchSoldiers;
var bool m_bShownHowToEndTurn;

var string DEBUG_testString1;
var string DEBUG_testString2;



//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	DEBUG_testString1="default1";
	DEBUG_testString2="default2";
}

