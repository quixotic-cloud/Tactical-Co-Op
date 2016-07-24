class X2Effect_Implacable extends X2Effect_Persistent;

var name ImplacableThisTurnValue;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;

	EventMgr.RegisterForEvent(EffectObj, 'UnitDied', EffectGameState.ImplacableCheck, ELD_OnStateSubmitted);
}

DefaultProperties
{
	ImplacableThisTurnValue="ImplacableThisTurn"
}