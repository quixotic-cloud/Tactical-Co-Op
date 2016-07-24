//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUnitFlag.uc
//  AUTHOR:  Tronster
//  PURPOSE: Information displayed next to a unit in the tactical game.
//           Supercedes functionality of UIUnitBillboard & UIUnitPoster
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUnitFlag extends UIPanel
	dependson(XComGameState_Unit);

enum EUnitFlagTargetingState
{
	eUnitFlagTargeting_None,
	eUnitFlagTargeting_Dim, 
	eUnitFlagTargeting_Active
};
enum EUnitFlagAlertState
{
	//These states correspond to the Flash image lookups, so order matters here. 
	eUnitFlagAlert_None,
	eUnitFlagAlert_Green,
	eUnitFlagAlert_Yellow, 
	eUnitFlagAlert_Red
};
enum EUnitFlagMovePipState
{
	//Also corresponds to Flash (RemainingMoves.as)
	eUnitFlagMovePip_Invalid,
	eUnitFlagMovePip_Empty,
	eUnitFlagMovePip_Filled
};

var public float WorldMessageAnchorX;
var public float WorldMessageAnchorY;

var int m_iMovePipsTouched; //Effectively, the unit's "previous" action points remaining - so we know how many pips to turn off once they move.

var int StoredObjectID; //Hook up to the object we're attached to 
var XComGameStateHistory History; 

var vector2D      m_positionV2;
var int           m_scale;
var public    bool          m_bIsFriendly;
var bool          m_bIsDead;
var bool			m_bIsOnScreen; 
var bool          m_bIsSelected;
var int           m_iRank;
var int           m_iScaleOverride;
var int           m_ekgState;
var EUnitFlagTargetingState m_eState; 
var int           m_eAlertState; 
var bool            m_bConcealed; 
var bool            m_bSpotted; 
var bool			m_bShowMissionItem; 
var bool			m_bShowObjectiveItem; 
var public bool				m_bShowDuringTargeting;
var bool			m_bIsSpecial;

var bool m_bLockToReticle; 
var UITargetingReticle m_kReticle; 

var bool m_bShowingBuff;
var bool m_bShowingDebuff;

var float m_LocalYOffset;

var localized string m_strReinforcementsTitle;
var localized string m_strReinforcementsBody;

var int VisualizedHistoryIndex;

// kUnit, the unit this flag is associated with.
simulated function InitFlag(StateObjectReference ObjectRef)
{
	InitPanel();

	History = `XCOMHISTORY;
	
	StoredObjectID = ObjectRef.ObjectID; 

	UpdateFriendlyStatus();

	m_bIsDead = false;
	m_iMovePipsTouched = 0;
}

// CALLBACK when Flash is initialized and ready to receive values.
simulated function OnInit()
{	
	local XComGameState_BaseObject StartingState;
	super.OnInit();

	//Initialize the unit flag UI with the starting unit state
	//`log(self $ "::" $ GetFuncName() @ `ShowVar(StoredObjectID), true, 'WTF');
	//`assert(StoredObjectID > 0);
	VisualizedHistoryIndex = `XCOMVISUALIZATIONMGR.LastStateHistoryVisualized;
	StartingState = History.GetGameStateForObjectID(StoredObjectID, , VisualizedHistoryIndex);
	UpdateFromState(StartingState, true);
}

// TODO: @dkaplan: make unit flag visualization updates event based
simulated function UpdateFriendlyStatus()
{
	local XGUnit UnitVisualizer;
	local XComGameState_Player LocalPlayerObject;
	local XComGameState_Destructible DestructibleObject;
	
	UnitVisualizer = XGUnit(History.GetVisualizer(StoredObjectID));

	if(UnitVisualizer != none)
	{
		m_bIsFriendly = UnitVisualizer != none ? UnitVisualizer.IsFriendly(PC) : false;
	}
	else
	{
		LocalPlayerObject = XComGameState_Player(History.GetGameStateForObjectID(`TACTICALRULES.GetLocalClientPlayerObjectID()));
		DestructibleObject = XComGameState_Destructible(History.GetGameStateForObjectID(StoredObjectID));
		m_bIsFriendly = DestructibleObject != none ? !DestructibleObject.IsTargetable(LocalPlayerObject.GetTeam()) : false;
	}
}
simulated function RespondToNewGameState( XComGameState NewState, bool bForceUpdate=false )
{
	local XComGameState_BaseObject ObjectState;	
	
	//the manager responds to a game state before on init is called on this flag in a replay or a tutorial.
	//do not allow calls too early, because unit flag uses direct invoke which results in bad calls pre-init 
	if( !bIsInited )
	{
		return;
	}

	if( bForceUpdate || bIsVisible )
	{				
		if( NewState != None )
		{
			VisualizedHistoryIndex = NewState.HistoryIndex;
			ObjectState = NewState.GetGameStateForObjectID(StoredObjectID);
		}
		else
		{
			ObjectState = History.GetGameStateForObjectID(StoredObjectID);
		}

		if (ObjectState != None)
			UpdateFromState(ObjectState, , bForceUpdate);
	}
}

simulated function UpdateFromState(XComGameState_BaseObject NewState, bool bInitialUpdate = false, bool bForceUpdate = false)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Destructible DestructibleState;

	UnitState = XComGameState_Unit(NewState);
	if(UnitState != none)
	{
		UpdateFromUnitState(UnitState, bInitialUpdate, bForceUpdate);
	}
	else
	{
		DestructibleState = XComGameState_Destructible(NewState);
		if(DestructibleState != none)
		{
			UpdateFromDestructibleState(DestructibleState, bInitialUpdate, bForceUpdate);
		}
	}
}

//----------------------------------------------------------------------------
//  Called in response to new game states
simulated function UpdateFromDestructibleState(XComGameState_Destructible NewDestructibleState, bool bInitialUpdate = false, bool bForceUpdate = false)
{
	local XComDestructibleActor DestructibleActor;

	// Destructible hit points are stored on the actor and updated by environment damage effects
	DestructibleActor = XComDestructibleActor(History.GetVisualizer(StoredObjectID));
	if(DestructibleActor != none)
	{
		SetHitPoints(NewDestructibleState.Health, DestructibleActor.TotalHealth);
	}

	 RealizeAlphaSelection();

	 if( bForceUpdate )
	 {
		 SetConcealmentState(false);
	 }
}

//----------------------------------------------------------------------------
//  Called in response to new game states
simulated function UpdateFromUnitState(XComGameState_Unit NewUnitState, bool bInitialUpdate = false, bool bForceUpdate = false)
{
	// Initial update
	if( bForceUpdate || bInitialUpdate )
	{
		RealizeFaction(NewUnitState);
		RealizeSpecialFaction(NewUnitState);
	}
	
	SetAim( NewUnitState.GetCurrentStat(eStat_Offense) );
	
	RealizeHitPoints(NewUnitState);

	if( bInitialUpdate )
	{
		if( NewUnitState.IsSoldier() )
		{
			SetNames( class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(NewUnitState.GetName(eNameType_Full)), class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(NewUnitState.GetNickName(true)) );
			SetRank( NewUnitState.GetRank() );
		}
		else if ( NewUnitState.IsCivilian() )
		{
			SetNames( class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(NewUnitState.GetName(eNameType_Full)), class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(NewUnitState.GetNickName(true)) );
		}
		else // alien
		{
			SetNames( class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(NewUnitState.GetName(eNameType_Full)), "");
		}
	}	

	RealizeMoves(NewUnitState);
	RealizeCover(NewUnitState);
	RealizeCriticallyWounded(NewUnitState);     //  if loading a save game, this could need to be set immediately
	RealizeStatus(NewUnitState);
	RealizeRupture(NewUnitState);
	RealizeOverwatch(NewUnitState);
	RealizeViperBind(NewUnitState);

	//DEBUG
	//SetDebugText( string(StoredUnitVisualizer.name) );
	
	if( PC != None && History.GetVisualizer(StoredObjectID) == XComTacticalController(PC).GetActiveUnit() ) 
	{
		SetSelected( true );
	}
	else	
	{
		RealizeAlphaSelection();
	}
	
	// concealment & buffs now realized dynamically; only force an update during a resync
	if( bForceUpdate || bInitialUpdate )
	{
		RealizeConcealmentState(NewUnitState);
		RealizeBuffs(NewUnitState);
		RealizeDebuffs(NewUnitState);
		RealizeEKG(NewUnitState);
	}
	// dkaplan - 2/3/15: Disabling all alert and spotted markup on unit flags; can be re-enabled by uncommenting the following two lines
	//RealizeAlertState(NewUnitState);
	//RealizeSpottedState(NewUnitState);
	//RealizeMissionItemState(NewUnitState);
	RealizeObjectiveItemState(NewUnitState);
	
	//Used to indicate which units are visible from the path cursor. 
	//It should always be FALSE here ( moving the path cursor should never submit new game states )
	RealizeLOSPreview(false); 
}

//----------------------------------------------------------------------------
//  Called from the UIUnitFlagManager's OnTick
simulated function Update( XGUnit kNewActiveUnit )
{
	local vector2d UnitPosition; //Unit position as a percentage of total screen space
	local vector2D unitScreenPos; //Unit position in pixels within the current resolution
	local vector vUnitLoc;
	local float flagScale;
	//local XComGameState_Unit UnitState;
	local Actor VisualizedActor;
	local X2VisualizerInterface VisualizedInterface;
	local XComGameState_Unit UnitState;

	const WORLD_Y_OFFSET = 40;

	// If not shown or ready, leave.
	if( !bIsInited )
		return;
	
	if( m_bIsDead)
	{
		return;
	}

	// Do nothing if unit isn't visible.  (And hide if not already hidden).
	VisualizedActor = History.GetVisualizer(StoredObjectID);
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	if( VisualizedActor == none || !VisualizedActor.IsVisible() || (UnitState != None && UnitState.IsBeingCarried()) )
	{
		Hide();
		return;
	}
	else 
	{
		if ( m_bIsFriendly )
		{
			if ( UIUnitFlagManager(Owner).m_bHideFriendlies )
			{
				Hide();
				return;
			}
		}
		else
		{
			if ( UIUnitFlagManager(Owner).m_bHideEnemies )
			{
				Hide();
				return;
			}
		}
	}

	// Now get the unit's location data 
	VisualizedInterface = X2VisualizerInterface(VisualizedActor);
	if(VisualizedInterface != none)
	{
		vUnitLoc = VisualizedInterface.GetUnitFlagLocation();
	}
	else
	{
		vUnitLoc = VisualizedActor.Location;
	}
	
	m_bIsOnScreen = class'UIUtilities'.static.IsOnscreen(vUnitLoc, UnitPosition, 0, WORLD_Y_OFFSET);
	
	//Reticle lock is triggered by watch vars, not this update trigger.
	//(Make sure we don't abort before computing m_bIsOnScreen, though!)
	if (m_bLockToReticle)
	{
		return;
	}

	if( !m_bIsOnScreen || !m_bShowDuringTargeting )
	{
		//Hiding off screen 
		Hide();
	}
	else
	{
		Show();

		unitScreenPos =  Movie.ConvertNormalizedScreenCoordsToUICoords(UnitPosition.X, UnitPosition.Y, false);
		unitScreenPos.Y += m_LocalYOffset;

		if( m_iScaleOverride > 0 )
		{
			SetFlagPosition( unitScreenPos.X, unitScreenPos.Y - m_iScaleOverride, m_iScaleOverride );
		}
		else
		{
			// Don't scale the flag if we're attached to a flag (even if our position is not locked to it)
			if(m_kReticle != none || m_bIsSelected)
				flagScale = 100;
			else
				flagScale = (unitScreenPos.Y / 22.5) + 52.0;

			SetFlagPosition( unitScreenPos.X , unitScreenPos.Y, flagScale );
		}
	}

	if ( kNewActiveUnit == VisualizedActor )
	{
		SetSelected( true );
		ShowExtension();
	}
	else if ( kNewActiveUnit != none )
	{
		SetSelected( false );
		HideExtension();
	}
}

// Set the location and scale of the unit flag.
// ( Formally was SetLoc )
// x, horizontal position
// y, vertical position
// scale, a value 1-100 (technically can be > 100) for poster size.
simulated function SetFlagPosition(int flagX, int flagY, int scale)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	// Only update if a new value has been passed in.
	if ((m_positionV2.X != flagX) || (m_positionV2.Y != flagY) || (m_scale != scale))
	{
		m_scale = scale;
		m_positionV2.X = flagX;
		m_positionV2.Y = flagY;

		myValue.Type = AS_Number;

		myValue.n = m_positionV2.X;
		myArray.AddItem( myValue );
		myValue.n = m_positionV2.Y;
		myArray.AddItem( myValue );
		myValue.n = m_scale;
		myArray.AddItem( myValue );

		Invoke("SetPosition", myArray);
	}
}

simulated function SetScaleOverride( int iOverride )
{
	m_iScaleOverride = iOverride;
}

simulated function PreviewMoves( int iMoves )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;

	myValue.n = iMoves;
	myArray.AddItem( myValue );

	Invoke("PreviewMoves", myArray);
}

simulated function RealizeLOSPreview(bool bSeen)
{
	//RAM - TEMP - Use the spotted marker to indicate that the enemy is seen / not seen
	SetSpottedState(bSeen);
}

simulated function SetNames( string unitName, string unitNickName )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;

	myValue.s = unitName;
	myArray.AddItem( myValue );
	myValue.s = unitNickName;
	myArray.AddItem( myValue );

	Invoke("SetNames", myArray);
}

simulated function SetDebugText( string strDisplayText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;

	myValue.s = strDisplayText ;
	myArray.AddItem(myValue);

	Invoke("SetDebugText", myArray);
}

simulated function RealizeSpecialFaction(XComGameState_BaseObject NewState)
{
	local XComGameState_Unit UnitState;
	local array<ASValue> myArray;

	UnitState = XComGameState_Unit(NewState);
	if( UnitState != none 
	   && UnitState.bIsSpecial
	   && !m_bIsSpecial )
	{
		m_bIsSpecial = true;
		myArray.length = 0;
		Invoke("SetFactionSpecial", myArray);
	}	
}

simulated function RealizeFaction(XComGameState_BaseObject NewState)
{
	local array<ASValue> myArray;
	local ASValue myValue;
	
	UpdateFriendlyStatus();

	myArray.length = 0;
	myValue.Type = AS_Boolean;

	myValue.b = m_bIsFriendly;
	myArray.AddItem( myValue );

	Invoke("SetFaction", myArray);	
}


simulated function RealizeAim() 
{
	// TODO: bsteiner: how do we get this data? 
	/*	SetAim( StoredUnitVisualizer.GetOffense() );*/
}
simulated function SetAim( int aimPercent )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;

	myValue.n = aimPercent;
	myArray.AddItem( myValue );

	Invoke("SetAim", myArray);
}


simulated function RealizeHitPoints(optional XComGameState_Unit NewUnitState = none) 
{		
	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	SetHitPoints( NewUnitState.GetCurrentStat(eStat_HP), NewUnitState.GetMaxStat(eStat_HP) );
	SetShieldPoints( NewUnitState.GetCurrentStat(eStat_ShieldHP), NewUnitState.GetMaxStat(eStat_ShieldHP) );
	SetArmorPoints( NewUnitState.GetArmorMitigationForUnitFlag() );
}

simulated function RealizeCriticallyWounded(optional XComGameState_Unit NewUnitState = none) 
{	
	local ASValue myValue;
	local Array<ASValue> myArray;
	local bool bIsCriticallyWounded; 

	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	if (NewUnitState != none)
	{
		bIsCriticallyWounded = NewUnitState.IsBleedingOut();

		myValue.Type = AS_Boolean;
		myValue.b = bIsCriticallyWounded;
		myArray.AddItem(myValue);

		if (bIsCriticallyWounded)
		{
			myValue.Type = AS_Number;
			myValue.n = NewUnitState.GetBleedingOutTurnsRemaining();
			myArray.AddItem(myValue);
		}

		Invoke("SetCriticallyWounded", myArray);
	}
}

simulated function SetHitPoints( int _currentHP, int _maxHP )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentHP, maxHP, iMultiplier;

	iMultiplier = `GAMECORE.HP_PER_TICK;

	if ( _currentHP < 1 )
	{
		m_bIsDead = true;
		Remove();
	}
	else
	{
		if( !m_bIsFriendly && !`XPROFILESETTINGS.Data.m_bShowEnemyHealth ) // Profile is set to hide enemy health 
		{			
			myValue.Type = AS_Number;
			myValue.n = 0;
			myArray.AddItem( myValue );
			myValue.n = 0;
			myArray.AddItem( myValue );
		}
		else
		{

			//Always round up for display when using the gamecore multiplier, per Jake's request. 
			if( iMultiplier > 0 )
			{
				currentHP = FCeil(float(_currentHP) / float(iMultiplier)); 
				maxHP = FCeil(float(_maxHP) / float(iMultiplier)); 
			}
		
			myValue.Type = AS_Number;
			myValue.n = currentHP;
			myArray.AddItem( myValue );
			myValue.n = maxHP;
			myArray.AddItem( myValue );
		}
		Invoke("SetHitPoints", myArray);
	}
}
simulated function SetShieldPoints( int _currentShields, int _maxShields )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentShields, maxShields, iMultiplier;

	iMultiplier = `GAMECORE.HP_PER_TICK;

	if( !m_bIsFriendly && !`XPROFILESETTINGS.Data.m_bShowEnemyHealth ) // Profile is set to hide enemy health 
	{			
		myValue.Type = AS_Number;
		myValue.n = 0;
		myArray.AddItem( myValue );
		myValue.n = 0;
		myArray.AddItem( myValue );
	}
	else
	{
		//Always round up for display when using the gamecore multiplier, per Jake's request. 
		if( iMultiplier > 0 )
		{
			currentShields = FCeil(float(_currentShields) / float(iMultiplier));
			maxShields = FCeil(float(_maxShields) / float(iMultiplier));
		}
	
		myValue.Type = AS_Number;
		myValue.n = currentShields;
		myArray.AddItem( myValue );
		myValue.n = maxShields;
		myArray.AddItem( myValue );
	}
	Invoke("SetShieldPoints", myArray);

	// Disable hitpoints preview visualization - sbatista 6/24/2013
	SetShieldPointsPreview();
}

simulated function SetArmorPoints(optional int _iArmor = 0)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int currentArmor, iMultiplier;

	iMultiplier = `GAMECORE.HP_PER_TICK;

	if( m_bIsFriendly ||`XPROFILESETTINGS.Data.m_bShowEnemyHealth ) 
	{			
		//Always round up for display when using the gamecore multiplier, per Jake's request. 
		if( iMultiplier > 0 )
		{
			currentArmor = FCeil(float(_iArmor) / float(iMultiplier));
		}
	
		myValue.Type = AS_Number;
		myValue.n = currentArmor;
		myArray.AddItem( myValue );	
		
		Invoke("ClearAllArmor");
		Invoke("SetArmor", myArray);
	}
	else
	{
		Invoke("ClearAllArmor"); // we dont want to show enemy healthbars so clear armor pips
	}
}


simulated function SetHitPointsPreview( optional int _iPossibleDamage = 0 )
{	
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int iPossibleDamage, iMultiplier;

	if(!`XPROFILESETTINGS.Data.m_bShowEnemyHealth)
		return;
	
	iMultiplier = `GAMECORE.HP_PER_TICK;
	
	//Always round up for display when using the gamecore multiplier, per Jake's request. 
	if( iMultiplier > 0 && _iPossibleDamage != 0)
	{
		iPossibleDamage = FCeil(float(_iPossibleDamage) / float(iMultiplier)); 
	}

	myValue.Type = AS_Number;
	
	myValue.n = iPossibleDamage;
	myArray.AddItem( myValue );

	Invoke("SetHitPointsPreview", myArray);
}

simulated function SetShieldPointsPreview( optional int _iPossibleDamage = 0 )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int iPossibleDamage, iMultiplier;
	
	iMultiplier = `GAMECORE.HP_PER_TICK;
	
	//Always round up for display when using the gamecore multiplier, per Jake's request. 
	if( iMultiplier > 0 && _iPossibleDamage != 0)
	{
		iPossibleDamage = FCeil(float(_iPossibleDamage) / float(iMultiplier)); 
	}

	myValue.Type = AS_Number;

	myValue.n = iPossibleDamage;
	myArray.AddItem( myValue );

	Invoke("SetShieldPointsPreview", myArray);
}

simulated function SetArmorPointsPreview( optional int _iPossibleShred = 0, optional int _iPossiblePierce )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int iPossibleShred, iPossiblePierce, iMultiplier;
	
	iMultiplier = `GAMECORE.HP_PER_TICK;
	
	//Always round up for display when using the gamecore multiplier, per Jake's request. 
	if( iMultiplier > 0 && _iPossibleShred != 0)
	{
		iPossibleShred = FCeil(float(_iPossibleShred) / float(iMultiplier)); 
	}

	//Always round up for display when using the gamecore multiplier, per Jake's request. 
	if( iMultiplier > 0 && _iPossiblePierce != 0)
	{
		iPossiblePierce = FCeil(float(_iPossiblePierce) / float(iMultiplier)); 
	}

	myValue.Type = AS_Number;
	myValue.n = iPossibleShred;
	myArray.AddItem( myValue );

	if(iPossibleShred > 0)
	{
		Invoke("SetArmorShred", myArray);
	}
	else
	{
		myArray[0].n = iPossiblePierce;

		Invoke("SetArmorPierce", myArray);
	}
}

simulated function RealizeModifiers()
{
	// TODO: bsteiner: how do we get this data? 
	/*
	local int iOffenseBuff, iDefenseBuff, iOffenseDebuff, iDefenseDebuff; 
	local bool bOffenseBuff, bDefenseBuff, bOffenseDebuff, bDefenseDebuff; 

	bOffenseBuff    = StoredUnitVisualizer.IsStatBuffed( eStat_Offense, iOffenseBuff );
	bOffenseDebuff  = StoredUnitVisualizer.IsStatDebuffed( eStat_Offense, iOffenseDebuff );

	bDefenseBuff    = StoredUnitVisualizer.IsStatBuffed( eStat_Defense, iDefenseBuff );
	bDefenseDebuff  = StoredUnitVisualizer.IsStatDebuffed( eStat_Defense, iDefenseDebuff );

	SetModifiers( bOffenseBuff,     iOffenseBuff, 
				  bOffenseDebuff,   iOffenseDebuff,
				  bDefenseBuff,     iDefenseBuff,
				  bDefenseDebuff,   iDefenseDebuff ); 
	*/
}

simulated function SetModifiers( bool bOffenseBuff,     int iOffenseBuffArrows,
								 bool bOffenseDebuff,   int iOffenseDebuffArrows,
								 bool bDefenseBuff,     int iDefenseBuffArrows,
								 bool bDefenseDebuff,   int iDefenseDebuffArrows)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	// ---------------------------

	myValue.Type = AS_Boolean;
	myValue.b = bOffenseBuff;
	myArray.AddItem( myValue );

	myValue.Type = AS_Number;
	myValue.n = iOffenseBuffArrows;
	myArray.AddItem( myValue );
	
	myValue.Type = AS_Boolean;
	myValue.b = bOffenseDebuff;
	myArray.AddItem( myValue );
	
	myValue.Type = AS_Number;
	myValue.n = iOffenseDebuffArrows;
	myArray.AddItem( myValue );

	// ---------------------------

	myValue.Type = AS_Boolean;
	myValue.b = bDefenseBuff;
	myArray.AddItem( myValue );

	myValue.Type = AS_Number;
	myValue.n = iDefenseBuffArrows;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
	myValue.b = bDefenseDebuff;
	myArray.AddItem( myValue );

	myValue.Type = AS_Number;
	myValue.n = iDefenseDebuffArrows;
	myArray.AddItem( myValue );
	
	// ---------------------------

	Invoke("SetModifiers", myArray);

}

simulated function SetRank(int rank)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( m_iRank != rank )
	{
		m_iRank = rank;

		myValue.Type = AS_Number;
		myValue.n = rank;
		myArray.AddItem( myValue );
		Invoke("SetRank", myArray);
	}
}

// Values already set internally, realize it across the wire...
simulated function RealizeMoves(optional XComGameState_Unit NewUnitState = none)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local EUnitFlagMovePipState PipState;
	local int i;
	
	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	//Clear old move pips
	myValue.Type = AS_Number;
	myValue.n = 0;
	myArray.AddItem(myValue);
	Invoke("SetMoves", myArray);
	myArray.Length = 0;
	
	PipState = eUnitFlagMovePip_Invalid;
	myValue.n = int(PipState);
	for (i = 0; i < m_iMovePipsTouched; i++)
		myArray.AddItem(myValue);

	Invoke("SetMovePips", myArray);
	myArray.Length = 0;

	m_iMovePipsTouched = 0;


	if ( m_bIsFriendly )// Only show moves for friendly units
	{
		//For now, it seems necessary to always use SetMoves before SetMovePips - something is perhaps getting clobbered by Flash.
		myValue.n = NewUnitState.NumAllActionPoints();
		myArray.AddItem(myValue);
		Invoke("SetMoves", myArray);
		myArray.Length = 0;

		//Show all of the action points the unit has, or pad to 2 pips (with empties) if they have less.
		//Iterate backwards to right-justify the filled pips, adding the empties first.
		for (i = max(2, NewUnitState.NumAllActionPoints()) - 1; i >= 0; i--)
		{
			if (i < NewUnitState.NumAllActionPoints())
				PipState = eUnitFlagMovePip_Filled;
			else
				PipState = eUnitFlagMovePip_Empty;

			myValue.n = int(PipState);
			myArray.AddItem(myValue);
		}

		Invoke("SetMovePips", myArray);
		myArray.Length = 0;

		//Store the number of pips we touched, so we can properly clear them out on the next update (avoiding a hard-coded limit).
		m_iMovePipsTouched = max(2, NewUnitState.NumAllActionPoints());
	}

	RealizeActive();
}

//Sets to gray if unit has used up his turn 
simulated function RealizeActive()
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Boolean;	
	if ( m_bIsFriendly )
	{
		// TODO: bsteiner: how do we get this data? 
		/*
		if ( StoredUnitVisualizer.HasRemainingUnitActionPoints() )
			myValue.b = false;
		else*/
			myValue.b = true;
	}
	else
		myValue.b = false;

	myArray.AddItem( myValue );

	Invoke("SetDisabled", myArray);	
}

simulated function EndTurn()
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	myArray.AddItem( myValue );

	myArray[0].Type = AS_Boolean;	
	myArray[0].b = m_bIsFriendly;
	Invoke("SetDisabled", myArray);	

	myArray[0].Type = AS_Number;
	myArray[0].n = 0;
	Invoke("SetMoves", myArray);
}

simulated function RealizeCover(optional XComGameState_Unit UnitState = none, optional int HistoryIndex=INDEX_NONE)
{
	local ASValue myValue;
	local Array<ASValue> myArray;	
	local ECoverType CoverType;

	if( HistoryIndex != INDEX_NONE )
	{
		VisualizedHistoryIndex = HistoryIndex;
	}

	if( UnitState == none )
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	myValue.Type = AS_String;
	myValue.s = "_none";

	if(UnitState != none)
	{
		CoverType = UnitState.GetCoverTypeFromLocation();
		if (CoverType != CT_None)
		{	
			if (CoverType == CT_Standing)
			{
				myValue.s = "_highCover";
			}
			else
			{
				myValue.s = "_lowCover";
			}
		}
	}

	myArray.AddItem( myValue );

	//----------------------

	myValue.Type = AS_Boolean;
	myValue.b = UnitState != none ? (UnitState.IsFlanked(,, VisualizedHistoryIndex) && !(UnitState.ControllingPlayerIsAI() && UnitState.GetCurrentStat(eStat_AlertLevel) == 0)) : false; // don't show as flanked when un-alerted

	myArray.AddItem( myValue );

	Invoke("SetCover", myArray);
}

simulated function ShowExtension()
{
	Invoke("ShowExtension");
}

simulated function HideExtension()
{
	Invoke("HideExtension");
}

simulated function SetSelected( bool isSelected )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	m_bIsSelected = isSelected;

	// This function might get called before object is ready to rock and roll.
	if(!bIsInited)
		return;

	myValue.Type = AS_Boolean;
	myValue.b = m_bIsSelected;
	myArray.AddItem( myValue );

	Invoke("SetSelected", myArray);

	RealizeTargetedState();
}

//HACK: shifting the alpha as a visual test for Greg 
simulated function RealizeAlphaSelection()
{
	if( m_bIsSelected || !m_bIsFriendly || m_kReticle != none )
		SetAlpha(100);
	else
		SetAlpha(40);
}

simulated function RealizeTargetedState()
{
	if( m_bIsSelected || m_kReticle != none  ||
	  ( !XComPresentationLayer(screen.Owner).GetTacticalHUD().IsMenuRaised() && !m_bIsFriendly ))
		SetAlphaState( eUnitFlagTargeting_Active );
	else
		SetAlphaState( eUnitFlagTargeting_Dim );
}

simulated function RealizeAlertState(optional XComGameState_Unit NewUnitState = none)
{
	local EAlertLevel AlertLevel;
	// Update to use visualizer alert levels.  GameState may change alert level too early (i.e. before actually moving to the alert location).
	local XGUnit UnitVisualizer;  
	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	//For now, only AI players can have alert levels
	if( NewUnitState.ControllingPlayerIsAI() && !NewUnitState.m_bSubsystem )
	{
		UnitVisualizer = XGUnit(NewUnitState.GetVisualizer());
		AlertLevel = UnitVisualizer.GetAlertLevel();
		if(AlertLevel == eAL_Red)
		{
			SetAlertState( eUnitFlagAlert_Red );
		}
		else if(AlertLevel == eAL_Yellow)
		{
			SetAlertState( eUnitFlagAlert_Yellow );
		}
		else if(AlertLevel == eAL_Green)
		{
			SetAlertState( eUnitFlagAlert_Green );
		}
	}
	else
	{
		SetAlertState( eUnitFlagAlert_None);
	}
}

simulated function SetAlertState( EUnitFlagAlertState eState )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( eState == m_eAlertState ) return;

	m_eAlertState = eState;

	myValue.Type = AS_Number; 
	myValue.n = int(eState);
	myArray.AddItem( myValue );

	Invoke("SetAlertState", myArray);	
}

simulated function RealizeSpottedState(optional XComGameState_Unit NewUnitState = none)
{
	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	//For now, only AI players can have alert levels
	if( NewUnitState.IsSpotted() )
	{
		SetSpottedState( true );
	}
	else
	{
		SetSpottedState( false );
	}
}

simulated function SetSpottedState( bool bShow)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	if( bShow == m_bSpotted ) return;

	m_bSpotted = bShow;

	myValue.Type = AS_Boolean; 
	myValue.b = m_bSpotted;
	myArray.AddItem( myValue );

	Invoke("SetSpottedState", myArray);	
}

simulated function RealizeMissionItemState(optional XComGameState_Unit NewUnitState = none)
{
	local XComGameState_Item Item; 

	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}
	Item = NewUnitState.GetItemInSlot(eInvSlot_Mission); 

	if( Item != none )
	{
		SetMissionItem( true );
	}
	else
	{
		SetMissionItem( false );
	}
}

simulated function SetMissionItem( bool bShow)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( bShow == m_bShowMissionItem ) return;

	m_bShowMissionItem = bShow;

	myValue.Type = AS_Boolean; 
	myValue.b = m_bShowMissionItem;
	myArray.AddItem( myValue );

	Invoke("SetMissionItem", myArray);	
}

simulated function RealizeObjectiveItemState(optional XComGameState_Unit NewUnitState = none)
{
	local bool bHasObjectiveItem; 

	bHasObjectiveItem = false; 
	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}
	bHasObjectiveItem = NewUnitState.HasItemOfTemplateClass(class'X2QuestItemTemplate'); 

	if( bHasObjectiveItem )
	{
		SeObjectiveItem( true );
	}
	else
	{
		SeObjectiveItem( false );
	}
}

simulated function SeObjectiveItem( bool bShow)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( bShow == m_bShowObjectiveItem ) return;

	m_bShowObjectiveItem = bShow;

	myValue.Type = AS_Boolean; 
	myValue.b = m_bShowObjectiveItem;
	myArray.AddItem( myValue );

	Invoke("SetObjectiveItem", myArray);	
}
simulated function RealizeConcealmentState(optional XComGameState_Unit NewUnitState = none)
{
	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}
	
	if( NewUnitState != none && NewUnitState.IsConcealed() )
	{
		SetConcealmentState( true );
	}
	else
	{
		SetConcealmentState( false );
	}
}

simulated function SetConcealmentState( bool bShow)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	m_bConcealed = bShow;

	myValue.Type = AS_Boolean; 
	myValue.b = m_bConcealed;
	myArray.AddItem( myValue );

	Invoke("SetConcealmentState", myArray);	
}

simulated function RealizeEKG(optional XComGameState_Unit NewUnitState = none)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int ekgState; 

	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	if( NewUnitState.IsPanicked() )
		ekgState = 1;
	else
		ekgState = 0;

	if( m_ekgState != ekgState )
	{
		m_ekgState = ekgState; 

		myValue.Type = AS_Number; 
		myValue.n = ekgState;
		myArray.AddItem( myValue );

		Invoke("SetEKGState", myArray);	
	}
}

simulated function SetAlphaState( EUnitFlagTargetingState eState )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( m_eState == eState ) return;

	m_eState = eState;

	myValue.Type = AS_Number; 
	myValue.n = int(eState);
	myArray.AddItem( myValue );

	Invoke("SetState", myArray);	
	
}

simulated function Show()
{
	if ( XComTacticalCheatManager(`XCOMGRI.GetALocalPlayerController().CheatManager) != none && 
		!XComTacticalCheatManager(`XCOMGRI.GetALocalPlayerController().CheatManager).bShowUnitFlags )
		return;

	if( m_bIsDead )
		return;

	if( !m_bIsOnScreen )
		return;

	// don't show flags on destructible actors that are not mission objectives unless we are actively targeting them 
	if(!m_bLockToReticle 
		&& XComGameState_Destructible(History.GetGameStateForObjectID(StoredObjectID)) != none
		&& History.GetGameStateComponentForObjectID(StoredObjectID, class'XComGameState_ObjectiveInfo') == none)
	{
		return;
	}

	super.Show();
}
simulated function Hide()
{
	super.Hide();
}

simulated function ActivateExtensionForTargeting( bool bShouldShow )
{
	m_bShowDuringTargeting = bShouldShow; 
	
	if( m_bShowDuringTargeting )
	{
		//Set appropriate info on the targeted flag 
		ShowExtension();
		SetSelected(true);
		Show();
	}
	else
	{
		Hide();
	}
}

simulated function DeactivateExtensionForTargeting()
{
	m_bShowDuringTargeting = true; 
	Show();
}


simulated function bool IsAttachedToUnit( XGUnit possibleUnit )
{
	return( StoredObjectID == possibleUnit.ObjectID );
}

simulated function LockToReticle( bool bShouldLock, UITargetingReticle kReticle )
{
	m_kReticle = kReticle; 
	
	if( m_kReticle != none )
	{
		m_bLockToReticle = bShouldLock;

		if(m_bLockToReticle)
			Movie.Pres.SubscribeToUIUpdate(UpdateLocationFromReticle);
		else
			Movie.Pres.UnsubscribeToUIUpdate(UpdateLocationFromReticle);
	}
	else if(m_bLockToReticle)
	{
		m_bLockToReticle = false;
		Movie.Pres.UnsubscribeToUIUpdate(UpdateLocationFromReticle);
		if(XComDestructibleActor(History.GetVisualizer(StoredObjectID)) != none)
			Hide();
	}
}

simulated function UpdateLocationFromReticle()
{
	local Vector2D vLocation;

	if(m_kReticle != none)
	{
		if(m_kReticle.bIsVisible)
		{
			Show();
			if(bIsVisible)
			{
				vLocation = Movie.ConvertNormalizedScreenCoordsToUICoords(m_kReticle.Loc.X, m_kReticle.Loc.Y);

				//Prevent the unit flag from being off the top of the screen, if the reticle is very near to it
				if (vLocation.Y < 200)
					SetFlagPosition(vLocation.X + 40, 160, 100);
				else
					SetFlagPosition( vLocation.X + 40, vLocation.Y - 40, 100 );
					
			}
		}
		else
			Hide();
	}
	else
		LockToReticle(false, none);
}

simulated function Remove()
{
	UIUnitFlagManager(Owner).RemoveFlag(self);
	super.Remove();
}

//This function will be spammed, so please only send changes to flash.
simulated function RealizeOverwatch(optional XComGameState_Unit NewUnitState = none)
{
	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	if(NewUnitState != none)
	{
		
		AS_SetOverwatchIcon(NewUnitState.ReserveActionPoints.Find('Overwatch') > -1);
	}
}

//This function will be spammed, so please only send changes to flash.
simulated function RealizeBuffs(optional XComGameState_Unit NewUnitState = none)
{
	local array<UISummary_UnitEffect> Bonuses; 

	//Exit early if we have not yet been associated with a unit
	if (StoredObjectID < 1)
	{
		return;
	}

	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	//Although this is a 'unit' flag, non units may use it - such as destructible objects. Buffs et. al don't apply to those types of object
	if (NewUnitState != none)
	{
		Bonuses = NewUnitState.GetUISummary_UnitEffectsByCategory(ePerkBuff_Bonus);

		if (!m_bShowingBuff && Bonuses.Length > 0)
		{
			ShowBuff(true);
			m_bShowingBuff = true;
		}

		if (m_bShowingBuff && Bonuses.Length == 0)
		{
			ShowBuff(false);
			m_bShowingBuff = false;
		}
	}
}
//This function will be spammed, so please only send changes to flash.
simulated function RealizeDebuffs(optional XComGameState_Unit NewUnitState = none)
{
	local array<UISummary_UnitEffect> Penalties;

	//Exit early if we have not yet been associated with a unit
	if (StoredObjectID < 1)
	{
		return;
	}

	NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));

	//Although this is a 'unit' flag, non units may use it - such as destructible objects. Buffs et. al don't apply to those types of object
	if (NewUnitState != none)
	{
		Penalties = NewUnitState.GetUISummary_UnitEffectsByCategory(ePerkBuff_Penalty);

		if (!m_bShowingDebuff && Penalties.Length > 0)
		{
			ShowDebuff(true);
			m_bShowingDebuff = true;
		}

		if (m_bShowingDebuff && Penalties.Length == 0)
		{
			ShowDebuff(false);
			m_bShowingDebuff = false;
		}
	}
}
simulated function ShowBuff( bool bShow )
{
	Movie.ActionScriptVoid(MCPath$".ShowBuff");
}
simulated function ShowDebuff( bool bShow )
{
	Movie.ActionScriptVoid(MCPath$".ShowDebuff");
}

simulated function CallForReinforcements()
{
	AS_SetMessage(m_strReinforcementsTitle, m_strReinforcementsBody);
}

simulated function AS_SetMessage( string str0, string str1 )
{
	Movie.ActionScriptVoid(MCPath$".SetMessage");
}

simulated function AS_SetOverwatchIcon(bool overwatch)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Boolean;
	myValue.b = overwatch;
	myArray.AddItem(myValue);

	Invoke("SetOverwatch", myArray);
}

simulated function RealizeStatus(optional XComGameState_Unit NewUnitState = none)
{
	local array<string> Icons; 

	if( NewUnitState == none )
	{
		NewUnitState = XComGameState_Unit(History.GetGameStateForObjectID(StoredObjectID));
	}

	Icons = NewUnitState.GetUISummary_UnitStatusIcons();

	//NOTE: The UI currently only supports one status icon, and this is intentional from design. 
	// I suspect we may need to stack them or show more in the future, so I'm handling everything 
	// in an array. Will update the flag to handle multiple icons if we need to. -bsteiner 2.26.2015

	if( Icons.length == 0 )
		AS_SetStatusIcon("");
	else
		AS_SetStatusIcon(Icons[0]);
}

simulated function AS_SetStatusIcon(string StatusIcon)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;
	myValue.s = StatusIcon;
	myArray.AddItem(myValue);

	Invoke("SetStatus", myArray);

}

simulated function RealizeRupture(XComGameState_Unit NewUnitState)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Boolean;
	myValue.b = NewUnitState.GetRupturedValue() > 0;
	myArray.AddItem(myValue);

	Invoke("SetShred", myArray);        //  @TODO - UI - rename this ?
}

simulated function RealizeViperBind(XComGameState_Unit NewUnitState)
{
	const VIPER_BIND_OFFSET = 30;
	//The unit flag for the unit being bound will overlap with the Viper's unit flag without an offset.
	m_LocalYOffset = NewUnitState.IsUnitAffectedByEffectName(class'X2Ability_Viper'.default.BindSustainedEffectName) ? VIPER_BIND_OFFSET : 0;
}

event Destroyed()
{
	Movie.Pres.UnsubscribeToUIUpdate(UpdateLocationFromReticle);
	super.Destroyed();
}

defaultproperties
{
	m_bIsFriendly   = true;
	m_bIsSelected   = false; 
	m_ekgState = -1;
	m_kReticle = none; 
	m_iScaleOverride = 0;
	m_bShowingBuff = false;
	m_bShowingDebuff = false; 
	m_bShowDuringTargeting = true; 
	
	m_eAlertState = 0; 
	m_bConcealed = true;  // Initializing to default state of icon
	
	WorldMessageAnchorX = 65.0;
	WorldMessageAnchorY = -170.0;
}
