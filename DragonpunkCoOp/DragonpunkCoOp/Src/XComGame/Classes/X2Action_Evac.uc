class X2Action_Evac extends X2Action;

var private CustomAnimParams AnimParams;
var private XComWeapon Rope;
var private Actor RopeTemplate;

var bool bIsVisualizingGremlin;

//------------------------------------------------------------------------------------------------

event bool BlocksAbilityActivation()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event EndState(name NextStateName)
	{
		super.EndState(NextStateName);

		if( Rope != None )
		{
			Rope.Destroy();
		}
	}

	function RopeLoaded(Object LoadedArchetype)
	{
		RopeTemplate = Actor(LoadedArchetype);
	}

	function RequestRopeArchetype()
	{
		`CONTENT.RequestGameArchetype("WP_EvacRope.WP_EvacRope", self, RopeLoaded, true);
	}

	function SpawnAndPlayRopeAnim()
	{
		local CustomAnimParams Params;
		local Vector RopeLocation;
		
		RopeLocation = UnitPawn.Location;
		RopeLocation.Z += UnitPawn.Mesh.Translation.Z;
		Rope = Spawn(class'XComWeapon', self, 'EvacRope', RopeLocation, UnitPawn.Rotation, RopeTemplate);
		Rope.SetHidden(false);

		if( UnitPawn.CarryingUnit != None )
		{
			Params.AnimName = 'HL_CarryEvacStartA';
		}
		else
		{
			Params.AnimName = 'HL_EvacStartA';
		}

		Params.BlendTime = 0.0f;
		Params.PlayRate = GetNonCriticalAnimationSpeed();

		Rope.DynamicNode.PlayDynamicAnim(Params);
	}
	
Begin:
	if (bIsVisualizingGremlin)
	{
		AnimParams.AnimName = 'HL_EvacStart';
		AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		UnitPawn.UpdatePawnVisibility();
		CompleteAction();
	}
	else
	{
		if( UnitPawn.EvacWithRope )
		{
		RequestRopeArchetype();

		while( RopeTemplate == None )
		{
			Sleep(0.0f);
		}

		SpawnAndPlayRopeAnim();
		}

		AnimParams.AnimName = 'HL_EvacStart';
		AnimParams.PlayRate = GetNonCriticalAnimationSpeed();
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

		CompleteAction();
	}
}

event HandleNewUnitSelection()
{
	// we don't currently have a good way to continue execution of this action without blocking 
	// and also wait for this action to finish to kick off the remove unit action that follows
	// so instead we just remove both the evacing unit and the rope right now
	ForceImmediateTimeout();
}

defaultproperties
{
}
