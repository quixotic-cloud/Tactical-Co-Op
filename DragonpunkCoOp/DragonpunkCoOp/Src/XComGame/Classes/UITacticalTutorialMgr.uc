//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalTutorialMgr.uc
//  AUTHOR:  Brit Steiner, Tronster
//  PURPOSE: Manages pop-ups that give additional information to the player about the
//           action they are about to take.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalTutorialMgr extends Actor;

// General for Mgr 
var UIMovie Movie;
var XComPlayerController PC;

// Members 
var XGUnit      m_kActiveUnit;
var bool        m_bShowingDashHelp;
var bool        m_bShowingFlyHelp;
var bool        m_bShowingHoverHelp;
var bool        m_bShowingPrimedGrenadeHelp;

// Localized text
var localized string    m_strCursorHelpDashActive; 
var localized string    m_strCursorHelpSprintActive;
var localized string    m_strCursorHelpFlyActive;
var localized string    m_strCursorHelpRevive;
var localized string    m_strCursorHelpStabilize;
var localized string    m_strCursorHelpStunned;
var localized string    m_strCursorHelpDead;
var localized string    m_strCursorHelpDestroyed;
var localized string    m_strCursorHelpNoFuel;
 
//Watch variable identifiers 
var int     m_hOnOutOfRangeChange;
var int     m_hOnFlyChange;
var int     m_hOnHoverChange;

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie)
{
	PC = InitController; 
	Movie = InitMovie;
	
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComTacticalController(PC), 'm_kActiveUnit', self, UpdateActiveUnit);
	
	//Force initial update; 
	UpdateActiveUnit();
}

//Called by pres layer's UIUpdate tick 
simulated function Update()
{
	UpdateDashMessage();
	UpdateFlyMessage();
	UpdateHoverMessage();
}

simulated function UpdateActiveUnit()
{
	local XCom3DCursor kCursor;

	kCursor = XComTacticalController(PC).GetCursor();

	//Disable any watches related to the active unit  -----------------------------
	//--Dashing
	if( m_hOnOutOfRangeChange != -1 )
		WorldInfo.MyWatchVariableMgr.EnableDisableWatchVariable( m_hOnOutOfRangeChange, false);

	// Update the active unit reference ------------------------------
	m_kActiveUnit = XComTacticalController(PC).GetActiveUnit();

	//Reenable any watches dependant on the active unit  ------------------------------
	//--Dashing 
	if (m_kActiveUnit != none) // there isn't always an active unit, especially at startup -- jboswell
	{
		//RAM - Jake is testing dashing as an automagical ability instead of something toggled by the player. Disabling its tutorial text for now.
		//m_hOnOutOfRangeChange = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( m_kActiveUnit.GetPathingPawn(), 'bOutOfRange', self, ActivateDashMessage);

		m_hOnFlyChange = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( m_kActiveUnit, 'm_bIsFlying', self, ActivateFlyMessage);
		m_hOnHoverChange = WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( kCursor, 'm_bHoverFailDetectedToggle', self, ActivateHoverMessage);

		//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( m_kActiveUnit, 'm_aCurrentStats', self, ActiveUnitStatsChange);
	}

	//Reset any dependant messages  ------------------------------ 
	//--Dashing 
	ClearDashMessage();
}


simulated function ActiveUnitStatsChange()
{

	// If the unit's path stat changed, we'll update the dashing message 
	ClearDashMessage();
	if( ShouldShowDashMessage() )
	{
		UpdateDashMessage( true );
	}
}

// ----------------- CONTEXT MESSAGE: Hover help -----------------
simulated function ActivateHoverMessage()
{
	ClearTimer( 'ShowHoverMessage' );
	SetTimer( 0.1, false, 'ShowHoverMessage', self);
}

simulated function ShowHoverMessage()
{
	ClearTimer( 'ShowHoverMessage' );
	
	//Activate the message, which will then be shown on the next update tick. 
	m_bShowingHoverHelp = true;
}

simulated function UpdateHoverMessage( optional bool bInitializeMessage = false )
{	
	local XCom3DCursor  kCursor;
	local Vector        messageV3;
	local Vector2D      vScreenLocation;

	kCursor = XComTacticalController(PC).GetCursor();

	//Contextual help message
	if( bInitializeMessage || m_bShowingHoverHelp)
	{
		if (m_kActiveUnit.IsAttemptingToHover(kCursor) &&
			!m_kActiveUnit.CanSatisfyHoverRequirements())
		{
			messageV3 = kCursor.Location; 
			class'UIUtilities'.static.IsOnscreen( messageV3, vScreenLocation );

			XComPresentationLayer(Owner).GetWorldMessenger().Message( m_strCursorHelpNoFuel, 
																	  messageV3, 
																	  ,
																	  eColor_Xcom, 
																	  class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_STEADY, 
																	  "cursorHelp_Hover",
																	  , 
																	  true, 
																	  vScreenLocation, 
																	  0); // Passing '0' here allows us to specify when message gets removed.
																	  
			m_bShowingHoverHelp = true;		
		}
		else
		{
			ClearHoverMessage();
		}
	}
}

//Clearing the message and timers
simulated function ClearHoverMessage()
{
	if( m_bShowingHoverHelp )
	{
		m_bShowingHoverHelp = false;
		
		ClearTimer( 'ClearHoverMessage' );
		XComPresentationLayer(Owner).GetWorldMessenger().RemoveMessage( "cursorHelp_Hover" );
	}
}

// ----------------- CONTEXT MESSAGE: Flying -----------------

simulated function ActivateFlyMessage()
{
	if( CanFly() ) 
	{
		ClearTimer( 'ShowFlyMessage' );
		SetTimer( 1.0, false, 'ShowFlyMessage', self);
	}
}

simulated function ShowFlyMessage()
{
	//Forcing the first show of the dash message 
	if( CanFly() ) 
	{
		ClearTimer( 'ShowFlyMessage' );
		
		//Activate the message, which will then be shown on the next update tick. 
		m_bShowingFlyHelp = true;
	}
}

//Location will update to follow the cursor around. 
simulated function UpdateFlyMessage( optional bool bInitializeMessage = false )
{	
	local XCom3DCursor  kCursor;
	local Vector        messageV3;
	local Vector2D      vScreenLocation;

	//Contextual help message
	if( bInitializeMessage || m_bShowingFlyHelp)
	{
		if( CanFly() )
		{
			kCursor = XComTacticalController(PC).GetCursor();
			messageV3 = kCursor.Location; 
			class'UIUtilities'.static.IsOnscreen( messageV3, vScreenLocation );

			XComPresentationLayer(Owner).GetWorldMessenger().Message( m_strCursorHelpFlyActive, 
																	  messageV3, 
																	  ,
																	  eColor_Xcom, 
																	  class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_STEADY, 
																	  "cursorHelp_Flying",
																	  , 
																	  true, 
																	  vScreenLocation, 
																	  0); // Passing '0' here allows us to specify when message gets removed.
			m_bShowingFlyHelp = true;
		}
		else
		{ 
			ClearFlyMessage();
		}
	}
}

//Clearing the message and timers
simulated function ClearFlyMessage()
{
	if( m_bShowingFlyHelp )
	{
		m_bShowingFlyHelp = false;
		
		ClearTimer( 'ClearFlyMessage' );
		XComPresentationLayer(Owner).GetWorldMessenger().RemoveMessage( "cursorHelp_Flying" );
	}
}

simulated function bool CanFly()
{
	return false;
}

// ----------------- CONTEXT MESSAGE: DASHING -----------------

//Dash message is activated, and now setting a delay until the dash message appears.
simulated function ActivateDashMessage()
{
	if( CanDash() ) 
	{
		ClearTimer( 'ShowDashMessage' );
		SetTimer( 1.0, false, 'ShowDashMessage', self);
	}
}

simulated function ShowDashMessage()
{
	//Forcing the first show of the dash message 
	if( CanDash() ) 
	{
		ClearTimer( 'ShowDashMessage' );
		
		//Activate the message, which will then be shown on the next update tick. 
		m_bShowingDashHelp = true;
	}
}

//Location will update to follow the cursor around. 
simulated function UpdateDashMessage( optional bool bInitializeMessage = false )
{	
	local XCom3DCursor  kCursor;
	local Vector        messageV3;
	local Vector2D      vScreenLocation;
	local string        dashMessage;

	//Contextual help message
	if( bInitializeMessage || m_bShowingDashHelp)
	{
		if( ShouldShowDashMessage() )
		{
			kCursor = XComTacticalController(PC).GetCursor();
			messageV3 = kCursor.Location; 
			class'UIUtilities'.static.IsOnscreen( messageV3, vScreenLocation );

			dashMessage = m_strCursorHelpDashActive;

			XComPresentationLayer(Owner).GetWorldMessenger().Message( dashMessage, 
																	  messageV3,
																	  ,
																	  eColor_Xcom, 
																	  class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_STEADY, 
																	  "cursorHelp_Dashing",
																	  , 
																	  true, 
																	  vScreenLocation,
																	  0); // Passing '0' here allows us to specify when message gets removed.
			m_bShowingDashHelp = true;
		}
		else 
		{ 
			ClearDashMessage();
		}
	}
	else if(!m_bShowingDashHelp && (ShouldShowDashMessage() || CanDash()) )
	{
		UpdateDashMessage(true);
	}
}

//Clearing the message and timers
simulated function ClearDashMessage()
{
	if( m_bShowingDashHelp )
	{
		m_bShowingDashHelp = false;
		
		ClearTimer( 'ClearDashMessage' );
		if (XComPresentationLayer(Owner).GetWorldMessenger() != none)
			XComPresentationLayer(Owner).GetWorldMessenger().RemoveMessage( "cursorHelp_Dashing" );
	}
}
simulated function bool ShouldShowDashMessage()
{
	local XCom3DCursor kCursor;

	if(m_kActiveUnit == none || !m_kActiveUnit.IsAliveAndWell()) 
	{
		return false;
	}

	if(m_kActiveUnit.IsPerformingAction() || m_kActiveUnit.InAscent())
	{
		return false;
	}

	kCursor = XComTacticalController(PC).GetCursor();
	if(kCursor == none)
	{
		return false;
	}

	//Allow the cheat Movie to turn this off. 
	if(GetALocalPlayerController().CheatManager != none && XComCheatManager(GetALocalPlayerController().CheatManager) != none)
	{
		if( !XComCheatManager(GetALocalPlayerController().CheatManager).m_bAllowTether )
		{
			return false;
		}
	}

	return (m_kActiveUnit.GetMaxPathLengthMeters() > m_kActiveUnit.GetMobility());
}

simulated function bool CanDash()
{
	if(  m_kActiveUnit != none 
		 && m_kActiveUnit.IsAliveAndWell()
		 && !m_kActiveUnit.IsPerformingAction()
		 && m_kActiveUnit.HasRemainingUnitActionPoints(2)
		 && !m_kActiveUnit.InAscent()
		 && !XComPresentationLayer(Movie.Pres).m_bPathMessageActive )
	{
		return true;
	}
	else
	{
		return false;
	}
}

// ----------------- CONTEXT MESSAGE: CURSOR TOUCH -----------------

simulated function UpdateCursorTouchInfo()
{
	local XCom3DCursor  kCursor;
	local Vector        messageV3;
	local Vector2D      vScreenLocation;
	local actor         kTouchingActor;
	local XGUnit        kUnit; 
	local string        sDeadString, sStabilize;
	
	kCursor = XComTacticalController(PC).GetCursor();
	kTouchingActor = kCursor.m_kTouchingActor;

	//If we're touching a unit pawn 
	if( XComUnitPawn(kTouchingActor) != none )
	{
		kUnit = XGUnit( XComUnitPawn(kTouchingActor).GetGameUnit() );

		if( kUnit != none )
		{
			//Show stunned message
			if( kUnit.IsAlive() && kUnit.IsCriticallyWounded() && kUnit.m_bStunned)
			{
				ClearStunnedMessage();

				messageV3 = kUnit.Location; 
				class'UIUtilities'.static.IsOnscreen( messageV3, vScreenLocation );

				XComPresentationLayer(Owner).GetWorldMessenger().Message( m_strCursorHelpStunned, 
																		  messageV3,
																		  ,
																		  eColor_Xcom, 
																		  class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_STEADY, 
																		  "cursorHelp_stunnedMsg",
																		  , 
																		  true, 
																		  vScreenLocation,
																		  0); // Passing '0' here allows us to specify when message gets removed.
				SetTimer(2.0, false, 'ClearStunnedMessage');
			}
			//Show critically wounded / revive message 
			else if( kUnit.IsAlive() && kUnit.IsCriticallyWounded() )
			{
				ClearReviveMessage();

				messageV3 = kUnit.Location; 
				class'UIUtilities'.static.IsOnscreen( messageV3, vScreenLocation );

				if (kUnit.m_bStabilized)
					sStabilize = m_strCursorHelpRevive;     //  indicate the unit can be revived (but is already stabilized)
				else
					sStabilize = m_strCursorHelpStabilize;  //  indicate the unit can be revived or stabilized

				XComPresentationLayer(Owner).GetWorldMessenger().Message( sStabilize, 
																		  messageV3, 
																		  ,
																		  eColor_Xcom, 
																		  class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_STEADY, 
																		  "cursorHelp_reviveMsg",
																		  , 
																		  true, 
																		  vScreenLocation,
																		  0); // Passing '0' here allows us to specify when message gets removed.
				SetTimer(2.0, false, 'ClearReviveMessage');
			}
			//Show deceased message 
			else if( kUnit.IsDead() && !kUnit.m_bForceHidden )
			{
				ClearDeadMessage();

				messageV3 = kUnit.Location; 
				class'UIUtilities'.static.IsOnscreen( messageV3, vScreenLocation );

				if( false ) //kUnit.GetCharacter().IsRobotic() )        jbouscher - REFACTORING CHARACTERS 
					sDeadString = m_strCursorHelpDestroyed;
				else
					sDeadString = m_strCursorHelpDead;

				XComPresentationLayer(Owner).GetWorldMessenger().Message( kUnit.SafeGetCharacterName() @ sDeadString,
																		  messageV3,
																		  ,
																		  eColor_Xcom, 
																		  class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_STEADY, 
																		  "cursorHelp_deadMsg",
																		  , 
																		  true, 
																		  vScreenLocation,
																		  0); // Passing '0' here allows us to specify when message gets removed.
				SetTimer(2.0, false, 'ClearDeadMessage');
			}
		}
	}
}
/*
simulated function ClearCursorMessages()
{
	ClearReviveMessage();
	ClearDeadMessage();
	ClearGrenadeMessage();
}*/

simulated function ClearStunnedmessage()
{
	ClearTimer('ClearStunnedMessage');
	XComPresentationLayer(Owner).GetWorldMessenger().RemoveMessage("cursorHelp_stunnedMsg");
}
simulated function ClearReviveMessage()
{
	ClearTimer('ClearReviveMessage');
	XComPresentationLayer(Owner).GetWorldMessenger().RemoveMessage("cursorHelp_reviveMsg");
}
simulated function ClearDeadMessage()
{
	ClearTimer('ClearDeadMessage');
	XComPresentationLayer(Owner).GetWorldMessenger().RemoveMessage("cursorHelp_deadMsg");
}
simulated function ClearGrenadeMessage()
{
	ClearTimer('ClearGrenadeMessage');
	XComPresentationLayer(Owner).GetWorldMessenger().RemoveMessage("cursorHelp_grenadeMsg");
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	m_kActiveUnit = none; 
	m_bShowingDashHelp = false;

	m_hOnOutOfRangeChange = -1;
}
