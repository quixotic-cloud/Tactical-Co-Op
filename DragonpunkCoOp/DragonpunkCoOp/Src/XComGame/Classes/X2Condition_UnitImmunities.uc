
class X2Condition_UnitImmunities extends X2Condition native(Core);

var array<name> ExcludeDamageTypes;     //Units immune to these damage types will be excluded.
var bool bOnlyOnCharacterTemplate;

function AddExcludeDamageType(name DamageType)
{
	ExcludeDamageTypes.AddItem(DamageType);
}

native function name MeetsCondition(XComGameState_BaseObject kTarget);
