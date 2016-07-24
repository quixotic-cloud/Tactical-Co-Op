//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_GetPickedUp extends X2Action;

//Cached info for performing the action
//*************************************
var private XComGameState_Unit	UnitState;
var	private	CustomAnimParams	Params;

var private XComGameStateHistory			History;
var private XComGameStateContext_Ability	AbilityContext;
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

	UnitPawn.EndRagDoll();
	UnitPawn.bRunPhysicsWithNoController = false;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	UnitPawn.UpdateLootSparklesEnabled(false, UnitState);

	// Line up to the source since the camera cut will hide it.
	UnitPawn.UnitCarryingMe = SourcePawn;
	UnitPawn.bSkipIK = true;
	UnitPawn.UpdateAnimations();
	UnitPawn.HideAllAttachments();

	SourcePawn.GetAnimTreeController().AttachChildController(UnitPawn.GetAnimTreeController());
	if( AbilityContext.InputContext.SourceObject.ObjectID > 0 )
	{
		VisualizationMgr.SendInterTrackMessage(AbilityContext.InputContext.SourceObject);
	}
	
	UnitPawn.m_kGameUnit.IdleStateMachine.GoDormant(SourcePawn, true, true);

	CompleteAction();
}

DefaultProperties
{
	bAbilityEffectReceived = false;
}
