/**
 * Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
 */

/** spawns a ghost to magically fire a weapon for cinematics
 * @note: no replication, expected to execute completely clientside
 */
class SeqAct_XComDummyWeaponFire extends SeqAct_Latent;

/** dummy pawn used to fire the weapon */
var XComUnitPawn DummyPawn;

/** defines the projectile being shot */
var() X2UnifiedProjectile FireProjectileTemplate;
/** number of shots to fire, <= 0 for shoot forever */
var() int ShotsToFire;
/** time between shots fired */
var() float DelayBetweenShots;

/** actor where the weapon fire is coming from */
var() Actor Origin;
/** target actor for the weapon fire */
var() Actor Target;

/** Use the structures and classes that X2projectile is used to working with */
var private AnimNotify_FireWeaponVolley FireVolleyNotify;
var private X2UnifiedProjectile NewProjectile;

event Activated()
{
	if (InputLinks[0].bHasImpulse)
	{
		if(FireProjectileTemplate == None)
		{
			ScriptLog("Error: DummyWeaponFire with no Projectile Template");
		}
		else if (Origin == None)
		{
			ScriptLog("Error: DummyWeaponFire with no Origin");
		}
		else if (Target == None)
		{
			ScriptLog("Error: DummyWeaponFire with no Target");
		}
		else
		{
			FireVolleyNotify = new(self) class'AnimNotify_FireWeaponVolley';			
			FireVolleyNotify.NumShots = ShotsToFire;
			FireVolleyNotify.ShotInterval = DelayBetweenShots;
			FireVolleyNotify.bCosmeticVolley = true;

			NewProjectile = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2UnifiedProjectile', , , , , FireProjectileTemplate);
			NewProjectile.ConfigureNewProjectileCosmetic(FireVolleyNotify, none, Origin, Target);
			NewProjectile.GotoState('Executing');
		}
	}
	else
	{
		OutputLinks[2].bHasImpulse = true;
	}

	OutputLinks[0].bHasImpulse = true;
}

event bool Update(float DeltaTime)
{	
	return FALSE;
}

defaultproperties
{
	ObjName="Dummy Weapon Fire (Pre-Rendered Cinematics Only)"
	ObjCategory="Cinematic"
	bCallHandler=false
	bAutoActivateOutputLinks=false

	ShotsToFire=1

	InputLinks(0)=(LinkDesc="Start Firing")	

	OutputLinks(0)=(LinkDesc="Out")
	OutputLinks(1)=(LinkDesc="Finished")	

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Origin",PropertyName=Origin,MaxVars=1)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target",PropertyName=Target,MaxVars=1)
}
