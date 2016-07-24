class X2Effect_StayConcealed extends X2Effect_Persistent;

function bool RetainIndividualConcealment(XComGameState_Effect EffectState, XComGameState_Unit UnitState)
{
	return true;
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "StayConcealed"
}