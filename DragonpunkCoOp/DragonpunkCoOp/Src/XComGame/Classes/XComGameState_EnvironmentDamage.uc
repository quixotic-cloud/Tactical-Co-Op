//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_EnvironmentDamage.uc
//  AUTHOR:  Ryan McFall  --  3/27/2014
//  PURPOSE: This state object keeps track of damage events that have affected the environment
//           in some way. This includes: missed shots, AOE damage effects such as explosions,
//           smashed windows, etc.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_EnvironmentDamage extends XComGameState_BaseObject native(Core);

var string DEBUG_SourceCodeLocation;        // Location of where this object is generated.

//Projectile / damage information
var() int DamageAmount;                     //Damage amount to apply to targets
var() name DamageTypeTemplateName;
var() Vector Momentum;                      //Imparts a direction / magnitude to the damage for physics / visualization
var() int PhysImpulse;                      //Magnitude of the physics impulse
var() name ProjectileArchetypeName;         //The projectile archetype used to cause this damage
var() bool bAffectFragileOnly;              //Used by projectile logic - ie. projectiles traveling to a target can only destroy non-fragile objects

//Position / target data
var() Vector HitLocation;                   //Location to use as the center of damage. Is quantized to the tiles before it is used.
var() TTile HitLocationTile;				//Tile the hit location happens to be in
var() float DamageRadius;                   //The radius in which the DamageAmount should be applied
var() EShapeType CosmeticDamageShape;
var() Vector CosmeticConeLocation;			//Other end of cone
var() float CosmeticConeEndDiameter;
var() float CosmeticConeLength;
var() StateObjectReference DamageTarget;   //If a target was specified for this damage event, store it here
var() box FilterBox;
var() array<TTile> DamageTiles;				//If the damage is specific to a known set of tiles use this (instead of the location/radius quantization)
var() Vector DamageDirection;				// The direction of damage to be applied it
var() array<ActorIdentifier> DestroyedActors; //If the damage is specific to a known set of destructibleActors use this;
var() array<ActorIdentifier> DamageActors;

//Assignment of responsibility for the damage event
var() StateObjectReference DamageCause;     //A state object that caused the damage to occur. Ex. for a car explosion this would store a reference to the unit that damaged the car
var() StateObjectReference DamageSource;    //The immediate source of damage. Ex. for a car explosion, this would store a reference to the car

//Debug support
var() TraceHitInfo HitInfo;                 //Stores the trace that generated this damage event

//Flags
var() bool bCausesSurroundingAreaDamage;
var() bool bDamagesUnits;
var() bool bIsHit;
var() bool bRadialDamage;
var() bool bSpawnExplosionVisuals;
var() bool bTargetableDamage; // Is this damage directed at a specific target?

var() array<TTile> AdjacentFractureTiles;	//Filled out with tiles that are adjacent to destroyed tiles. Used as candidate locations for secondary fire

// These are caches for the visualization and shouldn't be used for other purposes.
var() transient native array<TTile> FractureTiles;
var() transient native array<XComTileFracLevelActor> AdjacentFracActors;
var() transient native Array_Mirror DestructibleActors{TArray<IDestructible*>};
var() transient native Set_Mirror UniqueRemovedChunks{TSet<UINT>};
var() transient native array<XComLadder> DestroyedLadders;

var bool bAllowDestructionOfDamageCauseCover;

//Returns true if this damage event resulted in actors being damaged or destroyed
native function bool CausedDestruction();

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

simulated event OnStateSubmitted( )
{
	`XEVENTMGR.TriggerEvent( 'OnEnvironmentalDamage', self, self, XComGameState(Outer) );
}

static function VisualizeSecondaryFires(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local X2Effect ApplyEffect;
	local VisualizationTrack BuildTrack;
	local VisualizationTrack EmptyTrack;
	local XComGameState_WorldEffectTileData TileDataStateObject;

	foreach GameState.IterateByClassType(class'XComGameState_WorldEffectTileData', TileDataStateObject)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = TileDataStateObject;
		BuildTrack.StateObject_NewState = TileDataStateObject;

		if (TileDataStateObject.StoredTileData.Length > 0)
		{
			//Assume that effect names are the same for each tile
			ApplyEffect = X2Effect(class'Engine'.static.FindClassDefaultObject(string(TileDataStateObject.StoredTileData[0].Data.EffectName)));
			if (ApplyEffect != none)
			{
				class'X2Action_WaitForWorldDamage'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext());
				ApplyEffect.AddX2ActionsForVisualization(GameState, BuildTrack, 'AA_Success');
			}
			else
			{
				`redscreen("UpdateWorldEffects context failed to build visualization, could not resolve class from name:"@TileDataStateObject.StoredTileData[0].Data.EffectName@"!");
			}

			VisualizationTracks.AddItem(BuildTrack);
		}
	}
}

DefaultProperties
{	
	DamageTypeTemplateName = "DefaultProjectile"
	CosmeticDamageShape = SHAPE_SPHERE
}
