//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Destructible.uc
//  AUTHOR:  David Burchanowski  --  11/11/2014
//  PURPOSE: This object represents the instance data for an XComDestructibleActor on the
//           battlefield
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Destructible extends XComGameState_BaseObject
	implements(X2GameRulesetVisibilityInterface, Damageable, X2VisualizedInterface)
	config(GameCore)
	native(Core);

var const config bool OnlyTargetDestructiblesWithEnemiesInTheBlastRadius;

//Instance-only variables
var ActorIdentifier ActorId;
var TTile TileLocation;
var int Health; // keep track of applied health so we can fire events when this object is destroyed

cpptext
{
	// True if this object can be included in another viewer's visibility updates (ie. this object can be seen by other objects)
	virtual UBOOL CanEverBeSeen() const
	{
		return TRUE;
	}
};

native function bool IsTargetable(optional ETeam TargetingTeam = eTeam_None);

function SetInitialState(XComDestructibleActor InVisualizer)
{
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	`XCOMHISTORY.SetVisualizer(ObjectID, InVisualizer);
	InVisualizer.SetObjectIDFromState(self);

	ActorId = InVisualizer.GetActorId( );
	TileLocation = WorldData.GetTileCoordinatesFromPosition( InVisualizer.Location );

	if(InVisualizer.Toughness != none && !InVisualizer.Toughness.bInvincible)
	{
		Health = InVisualizer.Toughness.Health;
	}

	bRequiresVisibilityUpdate = true;
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	local XComGameStateHistory History;
	local XComDestructibleActor Visualizer;
	local XComWorldData World;
	
	Visualizer = XComDestructibleActor(GetVisualizer());
	if(Visualizer == none)
	{
		World = `XWORLD;

		Visualizer = World.FindDestructibleActor( ActorId );
		if (Visualizer != none)
		{
			History = `XCOMHISTORY;

			History.SetVisualizer( ObjectID, Visualizer );
			Visualizer.SetObjectIDFromState( self );
		}
		else
		{
			`redscreen("XComGameState_Destructible::SyncVisualizer was unable to find a visualizer for "@ActorId.OuterName@"."@ActorId.ActorName@" we thought was at {"@TileLocation.X@","@TileLocation.Y@","@TileLocation.Z@"}. Maybe it moved, maybe the asset is bad. Either way this session could be unstable.  ~RussellA");
		}
	}

	return Visualizer;
}

function SyncVisualizer(optional XComGameState GameState = none)
{
}

function AppendAdditionalSyncActions( out VisualizationTrack BuildTrack )
{
}

// X2GameRulesetVisibilityInterface Interface
event float GetVisibilityRadius();
event int GetAssociatedPlayerID() { return -1; }
event SetVisibilityLocation(const out TTile VisibilityLocation);

event bool TargetIsEnemy(int TargetObjectID, int HistoryIndex = -1)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComDestructibleActor DestructibleActor;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TargetObjectID, , HistoryIndex));
	if(UnitState == none) return false;

	DestructibleActor = XComDestructibleActor(GetVisualizer());
	if(DestructibleActor == none || DestructibleActor.Toughness == none) return false;

	switch(DestructibleActor.Toughness.TargetableBy)
	{
	case TargetableByNone:
		return false;
	case TargetableByXCom:
		return UnitState.GetTeam() == eTeam_XCom;
	case TargetableByAliens:
		return UnitState.GetTeam() == eTeam_Alien;
	case TargetableByAll:
		return true;
	}

	return false;
}

event bool TargetIsAlly(int TargetObjectID, int HistoryIndex = -1)
{
	return false;
}

event bool ShouldTreatLowCoverAsHighCover( )
{
	return false;
}

event UpdateGameplayVisibility(out GameRulesCache_VisibilityInfo InOutVisibilityInfo)
{
	InOutVisibilityInfo.bVisibleGameplay = InOutVisibilityInfo.bVisibleBasic;
}

native function NativeGetVisibilityLocation(out array<TTile> VisibilityTiles) const;
native function NativeGetKeystoneVisibilityLocation(out TTile VisibilityTile) const;

function GetVisibilityLocation(out array<TTile> VisibilityTiles)
{
	NativeGetVisibilityLocation(VisibilityTiles);
}

function GetKeystoneVisibilityLocation(out TTile VisibilityTile)
{
	NativeGetKeystoneVisibilityLocation(VisibilityTile);
}

event GetVisibilityExtents(out Box VisibilityExtents)
{
	local Vector HalfTileExtents;
	
	HalfTileExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;

	VisibilityExtents.Min = `XWORLD.GetPositionFromTileCoordinates( TileLocation ) - HalfTileExtents;
	VisibilityExtents.Max = `XWORLD.GetPositionFromTileCoordinates( TileLocation ) + HalfTileExtents;
	VisibilityExtents.IsValid = 1;
}

event EForceVisibilitySetting ForceModelVisible()
{
	return eForceVisible;
}

// Damageable Interface
function float GetArmorMitigation(const out ArmorMitigationResults Armor);
function bool IsImmuneToDamage(name DamageType);

event ForceDestroyed( XComGameState NewGameState, XComGameState_EnvironmentDamage AssociatedDamage )
{
	local XComGameState_Unit KillerUnitState;

	Health = 0;

	KillerUnitState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( AssociatedDamage.DamageCause.ObjectID ) );
	`XEVENTMGR.TriggerEvent( 'ObjectDestroyed', KillerUnitState, self, NewGameState );
	bRequiresVisibilityUpdate = true;
}

function TakeDamage( XComGameState NewGameState, const int DamageAmount, const int MitigationAmount, const int ShredAmount, optional EffectAppliedData EffectData,
		optional Object CauseOfDeath, optional StateObjectReference DamageSource, optional bool bExplosiveDamage = false, optional array<name> DamageTypes,
		optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false )
{
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComDestructibleActor Visualizer;
	local XComWorldData WorldData;
	local XComGameState_Unit KillerUnitState;
	local int OldHealth;

	WorldData = `XWORLD;
	Visualizer = XComDestructibleActor( GetVisualizer( ) );

	// track overall health. This is tracked in the actor from environment damage, but we need it
	// for game state queries too, and it updates latently on the actor
	if (Health < 0) // either indestructible or we haven't initialized our health value yet, check
	{
		if (Visualizer != none && Visualizer.Toughness != none && !Visualizer.Toughness.bInvincible)
		{
			Health = Visualizer.Toughness.Health;
		}
	}

	// update health and fire death messages, if needed
	if (Health >= 0) // < 0 indicates indestructible
	{
		OldHealth = Health;
		Health = Max( 0, class'XComDestructibleActor'.static.GetNewHealth( Visualizer, Health, DamageAmount ) );

		if (OldHealth != Health)
		{
			if (OldHealth > 0 && Health == 0)
			{
				// fire an event to notify that this object was destroyed
				KillerUnitState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( DamageSource.ObjectID ) );
				`XEVENTMGR.TriggerEvent( 'ObjectDestroyed', KillerUnitState, self, NewGameState );
				bRequiresVisibilityUpdate = true;
			}

			if (Visualizer.IsTargetable( ))
			{
				// Add an environment damage state at our location. This will cause the actual damage to the 
				// destructible actor in the world.
				DamageEvent = XComGameState_EnvironmentDamage( NewGameState.CreateStateObject( class'XComGameState_EnvironmentDamage' ) );
				DamageEvent.DEBUG_SourceCodeLocation = "UC: XComGameState_Destructible:TakeEffectDamage";
				DamageEvent.DamageAmount = DamageAmount;
				DamageEvent.DamageTypeTemplateName = 'Explosion';
				DamageEvent.HitLocation = WorldData.GetPositionFromTileCoordinates( TileLocation );
				DamageEvent.DamageTiles.AddItem( TileLocation );
				DamageEvent.DamageCause = DamageSource;
				DamageEvent.DamageSource = DamageEvent.DamageCause;
				DamageEvent.bTargetableDamage = true;
				DamageEvent.DamageTarget = GetReference( );
				NewGameState.AddStateObject( DamageEvent );
			}
		}
	}
}

function TakeEffectDamage(const X2Effect DmgEffect, const int DamageAmount, const int MitigationAmount, const int ShredAmount, const out EffectAppliedData EffectData, XComGameState NewGameState,
						  optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false, optional array<Name> DamageTypes)
{
	if( DamageTypes.Length == 0 )
	{
		DamageTypes = DmgEffect.DamageTypes;
	}
	TakeDamage( NewGameState, DamageAmount, MitigationAmount, ShredAmount, EffectData, DmgEffect, EffectData.SourceStateObjectRef, DmgEffect.IsExplosiveDamage( ),
					DamageTypes, bForceBleedOut, bAllowBleedout, bIgnoreShields );
}

function int GetRupturedValue()
{
	return 0;
}

function AddRupturedValue(const int Rupture)
{
	//  nothin'
}

function AddShreddedValue(const int Shred)
{
	//  nothin'
}

DefaultProperties
{	
	Health = -1
}
