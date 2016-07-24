//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITargetingReticle.uc
//  AUTHOR:  Katie Hirsch, Brit Steiner, Tronster
//  PURPOSE: Targeting reticuls that appears to track enemy in the tactical game.
//----------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITargetingReticle extends UIPanel
	dependson( UITacticalHUD );

//----------------------------------------------------------------------------
// MEMBERS
//

var vector2D    Loc;

var bool					m_bIsDisabled;
var bool					m_bIsLockedOn;
var bool					m_bLockTheCursor; //Will stop the location update incokes. 
var float					m_fAimPercentage;
var X2VisualizerInterface   m_kTarget; 
var bool					m_bUpdateShotWithLoc;
var string                  m_kCursorMessage;

// For blocked shots text
var bool        m_bShotIsBlocked;
var localized string    m_strShotIsBlocked;

//----------------------------------------------------------------------------
// METHODS
//

simulated function UITargetingReticle InitTargetingReticle()
{
	InitPanel();

	Loc.X = -1;
	Loc.Y = -1;

	Hide();
	
	return self;
}

simulated function OnInit()
{
	super.OnInit();

	//Set display data 
	UpdateShotData();

	Movie.Pres.SubscribeToUIUpdate(UpdateLocation);
}

simulated function UpdateShotData()
{
	local float fHitChance;
	local int i, iHitChance;
	local bool bShotBlocked;
	local ShotBreakdown kBreakdown;
	local AvailableAction SelectedAction;
	local XComGameState_Ability AbilityState;

	m_bUpdateShotWithLoc = false;

	if(!UITacticalHUD(screen).IsMenuRaised())
	{
		SetAimPercentages( -1.0f, -1.0f );
		SetDisabled( false );
		SetLockedOn( false );
		SetAimPercentages( -1.0f, -1.0f );
		if( Movie == none )
			`log("Targeting reticle ref to 'Movie' is bad!",, 'uixcom');
		else
			SetLoc( Movie.UI_RES_X / 2 , Movie.UI_RES_Y / 2 );

		return;
	}
			
	SelectedAction = UITacticalHUD(screen).GetSelectedAction();
	kBreakdown.HideShotBreakdown = true;
	for (i = 0; i < SelectedAction.AvailableTargets.Length; ++i)
	{
		if (SelectedAction.AvailableTargets[i].PrimaryTarget.ObjectID == m_kTarget.GetVisualizedStateReference().ObjectID)
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectedAction.AbilityObjectRef.ObjectID));
			AbilityState.LookupShotBreakdown(AbilityState.OwnerStateObject, SelectedAction.AvailableTargets[i].PrimaryTarget, AbilityState.GetReference(), kBreakdown);
			iHitChance = min(((kBreakdown.bIsMultishot ) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance ), 100);
			break;
		}
	}
	if (!kBreakdown.HideShotBreakdown)
	{
		fHitChance = iHitChance;
		fHitChance /= 100.0f;
		if (fHitChance > 1)
		{
			fHitChance = 1;
		}
		SetAimPercentages(fHitChance, -1.0f);
	}
	else
	{
		SetAimPercentages( -1.0f, -1.0f );

		bShotBlocked = false; //kTargetingAction.IsShotBlocked();
		if (bShotBlocked != m_bShotIsBlocked)
		{
			m_bShotIsBlocked = bShotBlocked;
			SetCursorMessage( m_bShotIsBlocked ? m_strShotIsBlocked : "" );
		}
	}
	
	SetLockedOn( true ); // TODO:TARGETING Only if there is a target!
}

simulated public function UpdateLocation()
{
	local vector2D  vScreenLocation; 
		
	if( m_kTarget != none )
	{
		//Get the current screen coords
		if(class'UIUtilities'.static.IsOnscreen( m_kTarget.GetTargetingFocusLocation(), vScreenLocation))
		{
			Show();
			SetLoc( vScreenLocation.X, vScreenLocation.Y );
		}
		else
			Hide();
	}
	
	if (m_bUpdateShotWithLoc)
		UpdateShotData();
}

simulated function SetTarget(optional X2VisualizerInterface _target)
{
	local XGUnit UnitTarget;

	// unlock previous target's flag
	if(_target != m_kTarget && m_kTarget != none)
		XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.LockFlagToReticle(false, none, m_kTarget.GetVisualizedStateReference());

	m_kTarget = _target;

	if(m_kTarget != None)
	{
		Show();
		UpdateLocation();

		// if we are targeting ourselves don't move our health flag info
		if( m_kTarget != XComTacticalController(PC).GetActiveUnit() )
		{
			// Lock flag to cursor when targeting enemy
			UnitTarget = XGUnit(m_kTarget);
			if(UnitTarget != none)
				XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.LockFlagToReticle(!UnitTarget.IsFriendly(PC), self, m_kTarget.GetVisualizedStateReference());
			else
				XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.LockFlagToReticle(true, self, m_kTarget.GetVisualizedStateReference());
		}
	}
	else if(bIsVisible)
		Hide();
}

simulated function SetMode(int reticleEnum)
{
	local int reticleIndex;
	reticleIndex = reticleEnum - 1;
	MC.FunctionNum("setMode", reticleIndex);
}

// Set the location of the target reticule on the screen.
//  x, y,   Screen pixel coordiantes
//
simulated function SetLoc(float NewX, float NewY)
{
	local Vector2D v2ScreenLoc;
	
	//If the cursor lock is on, set the cursor to be the center of the screen. 
	if( m_bLockTheCursor )
	{ 
		NewX = 0.5; 
		NewY = 0.5;
	}

	if( Loc.X != NewX || Loc.Y != NewY )
	{
		Loc.X = NewX;
		Loc.Y = NewY;
		
		v2ScreenLoc = Movie.ConvertNormalizedScreenCoordsToUICoords(Loc.X, Loc.Y);

		if(bIsInited)
		{
			AS_SetLoc(v2ScreenLoc.x, v2ScreenLoc.y);
		}
		else
		{
			MC.BeginFunctionOp("setLoc");
			MC.QueueNumber(v2ScreenLoc.x);
			MC.QueueNumber(v2ScreenLoc.y);
			MC.EndOp();
		}
	}
}

simulated function AS_SetLoc(float NewX, float NewY)
{
	Movie.ActionScriptVoid(MCPath$".setLoc");
}

// This is updated by the abilityHUD, and will stop the cursor location update while 
// there are no enemies in rage, but the player hasn't yet activated free-aiming. 
simulated function LockTheCursor( bool bShouldLock )
{
	m_bLockTheCursor = bShouldLock;	
}

//  fPercent, likelihood of hit (0.0f - 1.0f), less than 0 nothing will show.
simulated function SetAimPercentages( float fPercent, float fCritical )
{
	// Prevent calling to Flash if aim percent is the same.
	if( m_fAimPercentage != fPercent )
	{
		m_fAimPercentage = fPercent;
		MC.FunctionNum("SetAimPercentage", m_fAimPercentage);
	}	
}

//----------------------------------------------------------------------------
//  Simple text area for help near the reticule 
simulated function SetCursorMessage( string messageText )
{
	if( m_kCursorMessage != messageText )
	{
		m_kCursorMessage = messageText;
		MC.FunctionString("SetCursorMessage", m_kCursorMessage);
	}
}

//----------------------------------------------------------------------------
// 	
simulated function SetLockedOn(bool isLockedOn)
{
	if(m_bIsLockedOn != isLockedOn)
	{
		m_bIsLockedOn = isLockedOn;
		MC.FunctionBool("SetLockedOn", m_bIsLockedOn);
	}
}

//----------------------------------------------------------------------------
// 	
simulated function SetDisabled(bool isDisabled)
{
	if( m_bIsDisabled != isDisabled)
	{
		m_bIsDisabled = isDisabled;
		MC.FunctionBool("SetDisabled", m_bIsDisabled);
	}
}

simulated function Remove()
{
	SetTarget(); // set target to none to unlock any potentially locked unit flags

	Movie.Pres.UnsubscribeToUIUpdate(UpdateLocation);

	super.Remove();
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	MCName = "targetingReticle";
	bAnimateOnInit = false;
}
