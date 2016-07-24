//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ExplodingUnitDeathAction extends X2Action_Death;

var private XComGameStateContext_Ability FutureAbilityContext;
var private XComGameState FutureVisualizeGameState;

static function bool AllowOverrideActionDeath(const out VisualizationTrack BuildTrack, XComGameStateContext Context)
{
	return true;
}

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateContext ChainContext;
	local XComGameStateContext_Ability TestContext;

	super.Init(InTrack);

	ChainContext = StateChangeContext;

	for( ChainContext = StateChangeContext.GetNextStateInEventChain().GetContext(); ChainContext != none && !ChainContext.bLastEventInChain; ChainContext = ChainContext.GetNextStateInEventChain().GetContext() )
	{
		TestContext = XComGameStateContext_Ability(ChainContext);

		if( TestContext != None &&
			TestContext.InputContext.AbilityTemplateName == GetAssociatedAbilityName() &&
			TestContext.InputContext.PrimaryTarget.ObjectID == Unit.ObjectID)
		{
			// We are looking for an associated (Gatekeeper, Sectopod, etc.) Unit's DeathExplosion ability that is being brought forward
			FutureAbilityContext = TestContext;
			FutureVisualizeGameState = TestContext.AssociatedState;
			break;
		}
	}
}

simulated function name GetAssociatedAbilityName()
{
	return 'DeathExplosion';
}

simulated function Name ComputeAnimationToPlay()
{
	// Always allow new animations to play.  (fixes sectopod never breaking out of its wrath cannon idle)
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

	return 'HL_Death';
}

event OnAnimNotify(AnimNotify ReceiveNotify)
{	
	super.OnAnimNotify(ReceiveNotify);

	if( (XComAnimNotify_NotifyTarget(ReceiveNotify) != none) && (AbilityContext != none) )
	{
		// Notify the targets of the future explosion abiilty
		// A history index is required but -1 means the notify doesn't need to be associated
		// with a specific history
		DoNotifyTargetsAbilityApplied(FutureVisualizeGameState, FutureAbilityContext, -1);
		bWaitUntilNotified = false;
	}
}

defaultproperties
{
	bWaitUntilNotified=true
}