//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_GetPutDown extends X2Action;

//Cached info for performing the action
//*************************************
var	private	CustomAnimParams	Params;

var private XComGameStateHistory			History;
var private XComGameStateContext_Ability	AbilityContext;
var private XComGameState_Unit				UnitState;
var private XComUnitPawn					SourcePawn;

var private bool bAbilityEffectReceived;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	UnitState = XComGameState_Unit(Track.StateObject_NewState);

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	SourcePawn = XGUnit(History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID)).GetPawn();
}

function HandleTrackMessage()
{
	bAbilityEffectReceived = true;
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:
	while( !bAbilityEffectReceived && !IsTimedOut() )
	{
		sleep(0.0f);
	}

	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bRunPhysicsWithNoController = true;

	// Stop lining Up with the guy carrying you
	UnitPawn.UnitCarryingMe = None;

	SourcePawn.GetAnimTreeController().DetachChildController(UnitPawn.GetAnimTreeController());

	// Ensure we hold our dead pose
	Params.AnimName = 'Pose';
	Params.HasPoseOverride = true;
	Params.Pose = UnitPawn.Mesh.LocalAtoms;
	Params.BlendTime = 0.0f;
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	
	UnitPawn.UpdateAnimations();

	UnitPawn.m_kGameUnit.IdleStateMachine.Resume(SourcePawn);
	UnitPawn.bSkipIK = false;

	UnitPawn.UpdateLootSparklesEnabled(false, UnitState);

	CompleteAction();
}

DefaultProperties
{
	bAbilityEffectReceived = false;
}
