//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_AndromedonDeathAction extends X2Action_PlayAnimation;

var private StateObjectReference SpawnedRobotUnitReference;
var private TTile CurrentTile;
var private bool bReceivedMeshSwapNotify;

static function bool AllowOverrideActionDeath(const out VisualizationTrack BuildTrack, XComGameStateContext Context)
{
	// The Andromedon should always be switching to the robot on death
	return true;
}

function Init(const out VisualizationTrack InTrack)
{
	local XComGameState_Unit AndromedonUnit, SpawnedRobotUnit;
	local UnitValue SpawnedUnitValue;
	local XComGameStateHistory History;
	local int i;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability TestAbilityContext;

	super.Init(InTrack);

	Params.AnimName = 'HL_RobotBattleSuitStart';
	History = `XCOMHISTORY;

	// Search through the chain to find when the Andromedon's SwitchToRobot ability occurs
	i = StateChangeContext.EventChainStartIndex;
	Context = StateChangeContext;
	While( (AndromedonUnit == none) && (!Context.bLastEventInChain))
	{
		Context = History.GetGameStateFromHistory(i).GetContext();

		TestAbilityContext = XComGameStateContext_Ability(Context);

		if( TestAbilityContext!= none &&
			TestAbilityContext.InputContext.AbilityTemplateName == 'SwitchToRobot' &&
			TestAbilityContext.InputContext.SourceObject.ObjectID == UnitPawn.ObjectID )
		{
			// Get the up to date version of this unit so we can find the associated spawned robot
			AndromedonUnit = XComGameState_Unit(TestAbilityContext.AssociatedState.GetGameStateForObjectID(UnitPawn.ObjectID));
			AndromedonUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);
		}

		++i;
	}

	if( AndromedonUnit == none )
	{
		`RedScreenOnce("X2Action_AndromedonDeathAction: Andromedon not found, should have come from SwitchToRobot GameState -dslonneger @gameplay");
	}

	SpawnedRobotUnit = XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnitValue.fValue));
	if( SpawnedRobotUnit == none )
	{
		`RedScreenOnce("X2Action_AndromedonDeathAction: AndromedonRobot not found, Andromedon needs to have the reference -dslonneger @gameplay");
	}

	SpawnedRobotUnitReference = SpawnedRobotUnit.GetReference();
}

event OnAnimNotify(AnimNotify ReceiveNotify)
{
	local XComAnimNotify_NotifyTarget NotifyTarget;

	NotifyTarget = XComAnimNotify_NotifyTarget(ReceiveNotify);
	if(NotifyTarget != none)
	{
		bReceivedMeshSwapNotify = true;
	}
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bSkipIK = true;

	// Let the associated robot know it should start the animation
	VisualizationMgr.SendInterTrackMessage(SpawnedRobotUnitReference);

	// If it can't play the animation, just do the swap
	if( UnitPawn.GetAnimTreeController().CanPlayAnimation(Params.AnimName) )
	{
		UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

		while (!bReceivedMeshSwapNotify)
		{
			// There are two anim notifies that occur on this animation
			sleep(0.0);
		}
	}

	// Let the associated robot know it should swap the visibility
	// of the Andromedon and Robot meshes
	VisualizationMgr.SendInterTrackMessage(SpawnedRobotUnitReference);

	CompleteAction();
}

defaultproperties
{
	bReceivedMeshSwapNotify=false
}