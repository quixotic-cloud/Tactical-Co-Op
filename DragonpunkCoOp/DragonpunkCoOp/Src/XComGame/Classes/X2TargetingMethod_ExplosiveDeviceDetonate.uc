//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_ExplosiveDeviceDetonate extends X2TargetingMethod;

var array<XComGameState_DestructionSphere> VisibleSpheres;

function Init(AvailableAction InAction)
{
	local XComDestructionSphere SphereActor;
	local XGBattle Battle;
	local XComGameState_DestructionSphere DestructionSphereUnit;
	local XComWorldData WorldData;
	local XComInteractiveLevelActor InteractiveActor;
	local XComGameState_InteractiveObject InteractiveUnit;
	local float DistanceSquared;

	super.Init(InAction);

	Battle = `BATTLE;
	WorldData = `XWORLD;

	// Loop over all destruction spheres and check if there is an
	// interactive actor that has been interacted with.
	// This will be the list of destruction spheres that need to be displayed.

	foreach Battle.AllActors(class'XComDestructionSphere', SphereActor)
	{
		DestructionSphereUnit = class'XComGameState_DestructionSphere'.static.GetStateObject(SphereActor);

		foreach Battle.AllActors(class'XComInteractiveLevelActor', InteractiveActor)
		{
			InteractiveUnit = InteractiveActor.GetInteractiveState();
			
			if (InteractiveUnit.InteractionCount > 0)
			{
				DistanceSquared = VSizeSq(SphereActor.Location - InteractiveActor.Location);
				if (DistanceSquared <= WorldData.WORLD_StepSizeSquared)
				{
					DestructionSphereUnit.SetDamageSphereVisible(true);
					VisibleSpheres.AddItem(DestructionSphereUnit);
				}
			}
		}
	}
}

function Update(float DeltaTime);

function Canceled()
{
	local int i;

	for (i = 0; i < VisibleSpheres.Length; ++i)
	{
		VisibleSpheres[i].SetDamageSphereVisible(false);
	}

	VisibleSpheres.Length = 0;
}

function Committed()
{
	Canceled();
}