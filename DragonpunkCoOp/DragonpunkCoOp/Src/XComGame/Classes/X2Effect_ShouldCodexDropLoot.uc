class X2Effect_ShouldCodexDropLoot extends X2Effect_Persistent;

function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	return UnitState.AreAllCodexInLineageDead(NewGameState);
}