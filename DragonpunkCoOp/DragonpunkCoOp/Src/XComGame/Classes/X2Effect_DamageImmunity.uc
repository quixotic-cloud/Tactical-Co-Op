class X2Effect_DamageImmunity extends X2Effect_Persistent;

var array<name> ImmuneTypes;
var bool ImmueTypesAreInclusive;
var int RemoveAfterAttackCount;

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	return (ImmuneTypes.Find(DamageType) != INDEX_NONE) == ImmueTypesAreInclusive;
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit EffectTargetUnit;
	local XComGameStateHistory History;
	local Object GameStateObj;

	super.RegisterForEvents(EffectGameState);

	if( RemoveAfterAttackCount > 0 )
	{
		History = `XCOMHISTORY;
		EventMgr = `XEVENTMGR;

		GameStateObj = EffectGameState;
		EffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

		// Register for the required events
		EventMgr.RegisterForEvent(GameStateObj, 'UnitAttacked', EffectGameState.OnUnitAttacked, ELD_OnStateSubmitted, , EffectTargetUnit);
	}
}

defaultproperties
{
	ImmueTypesAreInclusive=true
}