class XComLayerActor extends Actor
	  placeable
	  native(Core);

var() string strLayer;
var() bool bAlwaysAppearIfLayerActive;

var() array<XComDestructionSphere> arrDestructionSpheres;
var() array<Emitter> arrEmitters;
var() array<Light> arrLightsToAppear;
var() array<Light> arrLightsToDisappear;
var() array<DecalActorBase> arrDecals;
var() array<XComDamageVolume> arrDamageVolumes;
var() array<Actor> arrActorsToAppear;
var() array<Actor> arrActorsToDisappear;

var SpriteComponent ChaosSprite;
var SpriteComponent XComSprite;
var SpriteComponent AdventSprite;
var SpriteComponent ResistanceSprite;

var array<Actor> arrPhysicsActors;

native function UpdateSubActors();

native function UpdateIcon();

native function CleanupLevelReferences();

function SetActive(bool bActive)
{
	local int idx;
	local actor kActor;
	local XComDamageVolume kDamageVolume;

	for (idx = 0; idx < arrActorsToAppear.Length; idx++)
	{
		if(arrActorsToAppear[idx].Physics == PHYS_RigidBody)
		{
			arrPhysicsActors.AddItem(arrActorsToAppear[idx]);
		}
	}

	
	if(bActive)
	{
		for (idx = 0; idx < arrDestructionSpheres.Length; idx++)
		{
			arrDestructionSpheres[idx].Explode();
		}

		for (idx = 0; idx < arrEmitters.Length; idx++)
		{
			arrEmitters[idx].SetHidden(!bActive);
			arrEmitters[idx].ParticleSystemComponent.SetHidden(!bActive);
			arrEmitters[idx].bActorDisabled = false;
			arrEmitters[idx].ParticleSystemComponent.SetActive(bActive);
		}

		for (idx = 0; idx < arrDamageVolumes.Length; idx++)
		{
			kDamageVolume = arrDamageVolumes[idx];
			kDamageVolume.SetCollisionType(COLLIDE_TouchAllButWeapons);
			kDamageVolume.UpdateWorldData(true);

			class'XComWorldData'.static.GetWorldData().RefreshActorTileData( kDamageVolume );
		}
		
		for (idx = 0; idx < arrActorsToAppear.Length; idx++)
		{
			kActor = arrActorsToAppear[idx];
			kActor.SetHidden(!bActive);
			kActor.SetCollisionType(COLLIDE_BlockAll);
			kActor.bActorDisabled = false;
			if(kActor.IsA(Name("XComInteractiveLevelActor")))
			{
				kActor.GotoState('_Pristine');				
			}

			class'XComWorldData'.static.GetWorldData().AddActorTileData(kActor);

		}

		for (idx = 0; idx < arrActorsToDisappear.Length; idx++)
		{
			kActor = arrActorsToDisappear[idx];

			if(kActor.IsA(Name("XComInteractiveLevelActor")))
			{
				kActor.GotoState('_Inactive');	
			}

			class'XComWorldData'.static.GetWorldData().RemoveActorTileData(kActor, true);
			kActor.SetCollisionType(COLLIDE_NoCollision);
			kActor.bActorDisabled = true;
			kActor.SetHidden(bActive);
		}

		for (idx = 0; idx < arrPhysicsActors.Length; idx++)
		{
			arrPhysicsActors[idx].SetPhysics(PHYS_RigidBody);
		}

	}
	else
	{
		for (idx = 0; idx < arrEmitters.Length; idx++)
		{
			arrEmitters[idx].ParticleSystemComponent.SetActive(bActive);
			arrEmitters[idx].bActorDisabled = true;
			arrEmitters[idx].ParticleSystemComponent.SetHidden(!bActive);
			arrEmitters[idx].SetHidden(!bActive);
		}

		for (idx = 0; idx < arrDamageVolumes.Length; idx++)
		{
			kDamageVolume = arrDamageVolumes[idx];
			kDamageVolume.SetCollisionType(COLLIDE_NoCollision);
			kDamageVolume.UpdateWorldData(false);

			class'XComWorldData'.static.GetWorldData().RefreshActorTileData( kDamageVolume );
		}

		for (idx = 0; idx < arrActorsToDisappear.Length; idx++)
		{
			kActor = arrActorsToDisappear[idx];
			kActor.SetHidden(bActive);
			kActor.SetCollisionType(COLLIDE_BlockAll);
			kActor.bActorDisabled = false;

			if(kActor.IsA(Name("XComInteractiveLevelActor")))
			{
				kActor.GotoState('_Pristine');				
			}

			class'XComWorldData'.static.GetWorldData().AddActorTileData(kActor);

		}

		for (idx = 0; idx < arrActorsToAppear.Length; idx++)
		{
			kActor = arrActorsToAppear[idx];

			if(kActor.IsA(Name("XComInteractiveLevelActor")))
			{
				kActor.GotoState('_Inactive');
			}

			class'XComWorldData'.static.GetWorldData().RemoveActorTileData(kActor, true);	
			kActor.SetCollisionType(COLLIDE_NoCollision);
			kActor.bActorDisabled = true;
			kActor.SetHidden(!bActive);
		}

		for (idx = 0; idx < arrPhysicsActors.Length; idx++)
		{
			arrPhysicsActors[idx].SetPhysics(PHYS_None);
		}
	}

	for (idx = 0; idx < arrDecals.Length; idx++)
	{
		arrDecals[idx].Decal.SetHidden(!bActive);
	}

	for (idx = 0; idx < arrLightsToAppear.Length; idx++)
	{
		arrLightsToAppear[idx].LightComponent.SetEnabled(bActive);
	}

	for (idx = 0; idx < arrLightsToDisappear.Length; idx++)
	{
		arrLightsToDisappear[idx].LightComponent.SetEnabled(!bActive);
	}

}



cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
}

defaultproperties
{
	Begin Object Class=SpriteComponent Name=ChaosSpriteComponent
		Sprite=Texture2D'LayerIcons.Layers.chaos_layer'
		HiddenGame=True
		Scale=0.3f
	End Object
	
	Begin Object Class=SpriteComponent Name=XComSpriteComponent
		Sprite=Texture2D'LayerIcons.Layers.xcom_layer'
		HiddenGame=True
		HiddenEditor=True
		Scale=0.3f
	End Object

	Begin Object Class=SpriteComponent Name=AdventSpriteComponent
		Sprite=Texture2D'LayerIcons.Layers.advent_layer'
		HiddenGame=True
		HiddenEditor=True
		Scale=0.3f
	End Object

	Begin Object Class=SpriteComponent Name=ResistanceSpriteComponent
		Sprite=Texture2D'LayerIcons.Layers.resistance_layer'
		HiddenGame=True
		HiddenEditor=True
		Scale=0.3f
	End Object

	ChaosSprite=ChaosSpriteComponent
	XComSprite=XComSpriteComponent
	AdventSprite=AdventSpriteComponent
	ResistanceSprite=ResistanceSpriteComponent
	Components.Add(ChaosSpriteComponent)
	Components.Add(XComSpriteComponent)
	Components.Add(AdventSpriteComponent)
	Components.Add(ResistanceSpriteComponent)

	strLayer="Chaos"
	Layer=Chaos
}