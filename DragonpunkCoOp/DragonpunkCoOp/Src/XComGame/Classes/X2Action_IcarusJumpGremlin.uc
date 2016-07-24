class X2Action_IcarusJumpGremlin extends X2Action;

var bool bPlayInReverse;
var vector MoveLocation;

var private CustomAnimParams AnimParams;

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
	}
	
Begin:
	AnimParams.AnimName = 'HL_EvacStart';
	AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

	if (bPlayInReverse)
		AnimParams.PlayRate = -AnimParams.PlayRate;

	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	if (bPlayInReverse == false)
		UnitPawn.SetLocation(MoveLocation);

	UnitPawn.UpdatePawnVisibility();
	CompleteAction();
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
	bPlayInReverse=false
}
