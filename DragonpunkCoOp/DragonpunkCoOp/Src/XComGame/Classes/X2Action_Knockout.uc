//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Knockout extends X2Action;

//Cached info for performing the action
//*************************************
var XComUnitPawn                TargetPawn;
var CustomAnimParams            Params;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;
	local XComGameState_BaseObject ObjectState;
	local XGUnit Target;

	super.Init(InTrack);
	
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	`assert(UnitState != none);

	ObjectState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);
	Target = XGUnit(ObjectState.GetVisualizer());
	TargetPawn = Target.GetPawn();
}

function bool IsTimedOut()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	if (UnitPawn == TargetPawn) // we are knocking ourself out (in the tutorial, or when syncing visualizers)
	{
		// just immediately warp the guy to the death pose
		if (TargetPawn.GetAnimTreeController().CanPlayAnimation('HL_CarryBodyLoop'))
		{
			Params.AnimName = 'HL_CarryBodyLoop';
			Params.BlendTime = 0.0f;
		}
		else //If we can't, for some reason, then warp to the end of the death animation
		{
			Params.AnimName = 'HL_Death';
			Params.StartOffsetTime = 10.0f;
		}

		TargetPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
		TargetPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	}
	else
	{
		// play a temp knockout anim until we get a real one
		Params.AnimName = 'HL_GetKnockedOut';
		TargetPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
		TargetPawn.GetAnimTreeController().SetAllowNewAnimations(false);

		Params.AnimName = 'FF_Melee';
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));
	}

	CompleteAction();
}

defaultproperties
{
}

