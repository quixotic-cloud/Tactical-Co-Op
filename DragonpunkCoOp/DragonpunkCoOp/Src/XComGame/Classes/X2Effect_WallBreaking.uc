class X2Effect_WallBreaking extends X2Effect_PersistentTraversalChange;

var name WallBreakingEffectName;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local XComGameState_Unit EffectTargetUnit;
	local X2EventManager EventMgr;
	local XComGameStateHistory History;
	local Object ListenerObj;
	
	History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;
	
	//This object should handle the callback
	ListenerObj = self;

	EffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	// Register for the required events
	EventMgr.RegisterForEvent(ListenerObj, 'UnitMoveFinished', WallBreakingAbilityActivated, ELD_OnStateSubmitted,, EffectTargetUnit);
}

function EventListenerReturn WallBreakingAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateContext_EffectRemoved EffectRemovedContext;
	local XComGameState_Effect WallBreakingEffectStateObject;
	local XComGameState NewGameState;
	local XComGameState_Unit AbilityUnit;
	
	AbilityUnit = XComGameState_Unit(EventSource);
	WallBreakingEffectStateObject = AbilityUnit.GetUnitAffectedByEffectState(WallBreakingEffectName);

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (WallBreakingEffectStateObject != none && 
		AbilityContext != none && AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length > 0)
	{
		EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(WallBreakingEffectStateObject);
			
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, EffectRemovedContext);
		WallBreakingEffectStateObject.RemoveEffect(NewGameState, NewGameState);			
		`TACTICALRULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore;
	WallBreakingEffectName = WallBreaking;
}