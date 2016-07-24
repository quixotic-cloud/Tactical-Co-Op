//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ViperBind extends X2Action;

//Cached info for the unit performing the action
//*************************************
var private CustomAnimParams	Params, ResetParams;
var private Actor				PartnerVisualizer;
var private XComUnitPawn		PartnerUnitPawn;
var private XComGameStateContext_Ability AbilityContext;

var private Vector				DesiredAnimLocation;
var private AnimNodeSequence	ShooterAnim;
var private AnimNodeSequence	TargetAnim;
var private XComGameState       VisualizeGameState;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	local XComGameState_Effect BindEffectState;
	local XComGameState_Unit BindSourceUnit;

	super.Init(InTrack);
	
	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	

	History = `XCOMHISTORY;

	if( AbilityContext != none )
	{
		PartnerVisualizer = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID).GetVisualizer();
		VisualizeGameState = AbilityContext.GetLastStateInInterruptChain();
	}
	else
	{
		// The StateChangeContext is not a XComGameStateContext_Ability, so we need to get the primary target's ID another way
		BindSourceUnit = XComGameState_Unit(Track.StateObject_NewState);
		BindEffectState = BindSourceUnit.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BoundName);

		PartnerVisualizer = History.GetGameStateForObjectID(BindEffectState.ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID).GetVisualizer();
	}


	PartnerUnitPawn = XGUnit(PartnerVisualizer).GetPawn();

	DesiredAnimLocation = VLerp(UnitPawn.Location, PartnerVisualizer.Location, 0.5f);
	DesiredAnimLocation.Z = Unit.GetDesiredZForLocation(DesiredAnimLocation); // Keep their Z on the floor
}

function ForceImmediateTimeout()
{
	// Do nothing. This is causing the animation to not finish. This animation has a fixup that
	// gets the two units to their desired positions.
}

function NotifyTargetsAbilityApplied()
{
	local StateObjectReference Target;		
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;

	if( VisualizeGameState != none )
	{
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
		{
			Target = EnvironmentDamageEvent.GetReference();
			VisualizationMgr.SendInterTrackMessage(Target);
		}
	}
}

function bool CheckInterrupted()
{
	return VisualizationBlockContext.InterruptionStatus == eInterruptionStatus_Interrupt;
}

simulated state Executing
{
	function AnimNodeSequence PlayBindAnim(XComUnitPawn PlayOnPawn, vector FaceDir)
	{
		local vector UpdatedFaceDir;

		UpdatedFaceDir = FaceDir;
		UpdatedFaceDir.Z = 0;

		Params.AnimName = 'NO_BindStart';
		Params.HasDesiredEndingAtom = true;
		Params.DesiredEndingAtom.Translation = DesiredAnimLocation;		
		Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(UpdatedFaceDir));
		Params.DesiredEndingAtom.Scale = 1.0f;

		return PlayOnPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	}

	function PlayBindLoopAnim(XComUnitPawn PlayOnPawn)
	{
		Params = ResetParams;
		Params.AnimName = 'NO_BindLoop';
		Params.Looping = true;
		PlayOnPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	}

Begin:
	//Wait for the idle state machine to return to idle
	while( UnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance() ||
		   PartnerUnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance() ||
		   bInterrupted)
	{
		Sleep(0.01f);
	}

	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	ShooterAnim = PlayBindAnim(UnitPawn, (PartnerUnitPawn.Location - UnitPawn.Location));

	PartnerUnitPawn.EnableRMA(true, true);
	PartnerUnitPawn.EnableRMAInteractPhysics(true);
	TargetAnim = PlayBindAnim(PartnerUnitPawn, (UnitPawn.Location - PartnerUnitPawn.Location));

	UnitPawn.bSkipIK = true;
	PartnerUnitPawn.bSkipIK = true;

	NotifyTargetsAbilityApplied();

	//Make sure the animations are finished
	FinishAnim(ShooterAnim);
	FinishAnim(TargetAnim);
	
	PlayBindLoopAnim(UnitPawn);
	PlayBindLoopAnim(PartnerUnitPawn);

	//Regardless of whether we skip the animations or not, notify the other track that we're done
	if(AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 && AbilityContext.InputContext.PrimaryTarget.ObjectID != Unit.ObjectID)
	{
		VisualizationMgr.SendInterTrackMessage(AbilityContext.InputContext.PrimaryTarget);
	}

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return true;
}