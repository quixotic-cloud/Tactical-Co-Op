//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_CarryUnitPickUp extends X2Action;

//Cached info for performing the action
//*************************************
var	protected CustomAnimParams				Params;

var protected XComGameStateHistory			History;
var protected XComGameStateContext_Ability	AbilityContext;
var protected XComGameState_Unit			UnitState;
var protected XComUnitPawn					TargetPawn;
var protected String						AnimName;
var protected bool							bAbilityEffectReceived;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	if( AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 )
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		TargetPawn = XGUnit(UnitState.GetVisualizer()).GetPawn();
	}
}

function HandleTrackMessage()
{
	bAbilityEffectReceived = true;
}

function bool CheckInterrupted()
{
	return false;
}

function Name AppendMaleFemaleToAnim(String InputName)
{
	if( UnitPawn.bIsFemale )
	{
		InputName = InputName $ "F";
	}
	else
	{
		InputName = InputName $ "M";
	}

	if( TargetPawn.bIsFemale )
	{
		InputName = InputName $ "F";
	}
	else
	{
		InputName = InputName $ "M";
	}

	return Name(InputName);
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	if( AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 )
	{
		UnitPawn.CarryingUnit = TargetPawn;
		VisualizationMgr.SendInterTrackMessage(AbilityContext.InputContext.PrimaryTarget);
	}

	// Wait until the target is attached
	while( !bAbilityEffectReceived && !IsTimedOut() )
	{
		sleep(0.0f);
	}

	UnitPawn.UpdateAnimations();
	UnitPawn.HideAllAttachments();

	AnimName = "HL_CarryBodyStart";
	Params.AnimName = AppendMaleFemaleToAnim(AnimName);
	Params.BlendTime = 0.0f;
	Params.PlayRate = GetNonCriticalAnimationSpeed();
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	AnimName = "ADD_NO_CarryBody";
	Params.AnimName = AppendMaleFemaleToAnim(AnimName);
	Params.BlendTime = 0.0f;
	Params.Looping = true;
	Params.PlayRate = GetNonCriticalAnimationSpeed();
	UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(Params);

	CompleteAction();
}

DefaultProperties
{
	bAbilityEffectReceived = false;
}
