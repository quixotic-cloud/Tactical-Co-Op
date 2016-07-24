//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ApplyDirectionalWorldDamage extends X2Effect;

var int EnvironmentalDamageAmount;
var name DamageTypeTemplateName;
var int PlusNumZTiles;
var bool bUseWeaponEnvironmentalDamage;
var bool bUseWeaponDamageType;
var bool bHitSourceTile;
var bool bHitTargetTile;
var bool bHitAdjacentDestructibles;
var bool bAllowDestructionOfDamageCauseCover; // if the cause of the damage is a unit, allow this damage event to destroy that unit's cover (because this is normally protected against).

simulated function ApplyDirectionalDamageToTarget(XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, XComGameState NewGameState)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_Item ItemState;
	local X2WeaponTemplate WeaponTemplate;
	local XComWorldData WorldData;
	local Vector DamageDirection;
	local Vector SourceLocation, TargetLocation;
	local TTile  SourceTile, TargetTile;
	local DestructibleTileData DestructData;
	local Actor DestructActor;
	local int i;

	if (SourceUnit == None || TargetUnit == None)
		return;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if( AbilityContext != none )
	{
		WorldData = `XWORLD;

		SourceUnit.GetKeystoneVisibilityLocation(SourceTile);
		SourceLocation = WorldData.GetPositionFromTileCoordinates(SourceTile);

		TargetUnit.GetKeystoneVisibilityLocation(TargetTile);
		TargetLocation = WorldData.GetPositionFromTileCoordinates(TargetTile);

		if (bHitSourceTile)
		{
			DamageDirection = TargetLocation - SourceLocation;
			DamageDirection.Z = 0.0f;
			DamageDirection = Normal(DamageDirection);
		}
		else if (bHitTargetTile)
		{
			DamageDirection = SourceLocation - TargetLocation;
			DamageDirection.Z = 0.0f;
			DamageDirection = Normal(DamageDirection);
		}

		DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateStateObject(class'XComGameState_EnvironmentDamage'));
		DamageEvent.DEBUG_SourceCodeLocation = "UC: X2Effect_ApplyDirectionalWorldDamage:ApplyEffectToWorld";
		DamageEvent.DamageAmount = EnvironmentalDamageAmount;
		DamageEvent.DamageTypeTemplateName = DamageTypeTemplateName;

		if (bHitAdjacentDestructibles)
		{
			WorldData.GetAdjacentDestructibles(bHitSourceTile ? SourceUnit : TargetUnit, DestructData, DamageDirection, bHitSourceTile ? TargetUnit : SourceUnit);
			for (i = 0; i < DestructData.DestructibleActors.Length; ++i)
			{
				DestructActor = Actor(DestructData.DestructibleActors[i]);
				if (DestructActor != none)
					DamageEvent.DestroyedActors.AddItem(DestructActor.GetActorId());
			}
		}

		if (bUseWeaponDamageType || bUseWeaponEnvironmentalDamage)
		{
			ItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
			if (ItemState != none)
			{
				WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
				if (WeaponTemplate != none)
				{
					if (bUseWeaponDamageType)
						DamageEvent.DamageTypeTemplateName = WeaponTemplate.DamageTypeTemplateName;
					if (bUseWeaponEnvironmentalDamage)
						DamageEvent.DamageAmount = WeaponTemplate.iEnvironmentDamage;
				}
			}
		}

		if (bHitSourceTile)
			DamageEvent.HitLocation = SourceLocation;
		else
			DamageEvent.HitLocation = TargetLocation;
		DamageEvent.Momentum = DamageDirection;
		DamageEvent.DamageDirection = DamageDirection; //Limit environmental damage to the attack direction( ie. spare floors )
		DamageEvent.PhysImpulse = 100;
		DamageEvent.DamageRadius = 64;			
		DamageEvent.DamageCause = SourceUnit.GetReference();
		DamageEvent.DamageSource = DamageEvent.DamageCause;
		DamageEvent.bRadialDamage = false;
		DamageEvent.bAllowDestructionOfDamageCauseCover = bAllowDestructionOfDamageCauseCover;

		if (bHitSourceTile)
		{
			DamageEvent.DamageTiles.AddItem(SourceTile);

			for( i = 0; i < PlusNumZTiles; ++i)
			{
				SourceTile.Z++;
				DamageEvent.DamageTiles.AddItem(SourceTile);
			}
		}
		if (bHitTargetTile)
		{
			DamageEvent.DamageTiles.AddItem(TargetTile);
			
			for (i = 0; i < PlusNumZTiles; ++i)
			{
				TargetTile.Z++;
				DamageEvent.DamageTiles.AddItem(TargetTile);
			}
		}

		NewGameState.AddStateObject(DamageEvent);
	}
}

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit SourceUnit, TargetUnit;
	local int i;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if( AbilityContext != none )
	{
		SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

		ApplyDirectionalDamageToTarget(SourceUnit, TargetUnit, NewGameState);

		for (i = 0; i < AbilityContext.InputContext.MultiTargets.Length; ++i)
		{
			TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.MultiTargets[i].ObjectID));
			ApplyDirectionalDamageToTarget(SourceUnit, TargetUnit, NewGameState);
		}
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	if( BuildTrack.StateObject_NewState.IsA('XComGameState_EnvironmentDamage') )
	{
		if( EffectApplyResult == 'AA_Success' )
		{
			//All non-unit damage is routed through XComGameState_EnvironmentDamage state objects, which represent an environmental damage event
			class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
		}
	}
}

defaultproperties
{
	PlusNumZTiles=0
	bAppliesDamage=true
}