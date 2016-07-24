class X2Effect_Frenzy extends X2Effect_PersistentStatChange
	config(GameCore);

var config int FRENZY_NUM_ACTION_POINTS_ADDED;

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	local int i;

	for (i = 0; i < default.FRENZY_NUM_ACTION_POINTS_ADDED; ++i)
	{
		ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	}
}

defaultproperties
{
	EffectName="FrenzyEffect"
}