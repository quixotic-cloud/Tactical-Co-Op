class X2Effect_ModifyStatCheckSuccesses extends X2Effect_Persistent
	config(GameCore);

enum EAbilityRequirement
{
	AbilityRequirement_Source,
};

struct AdditionalSuccessModifier
{
	var name AbilityName;
	var int AddSuccessCheckValue;
	var EAbilityRequirement AdditionAbilityRequirement;
};

var array<AdditionalSuccessModifier> AdditionalSuccessModifiers;

simulated function AddAdditionalSuccessModifier(name AbilityName, int AddSuccessCheckValue, optional EAbilityRequirement AdditionAbilityRequirement = AbilityRequirement_Source)
{
	local AdditionalSuccessModifier Modifier;

	Modifier.AbilityName = AbilityName;
	Modifier.AddSuccessCheckValue = AddSuccessCheckValue;
	Modifier.AdditionAbilityRequirement = AdditionAbilityRequirement;

	AdditionalSuccessModifiers.AddItem(Modifier);
}

function GetStatCheckModToSuccessCheck(XComGameState_Effect EffectState, XComGameState_Unit UnitState, XComGameState_Ability AbilityState, out int Successes)
{
	local AdditionalSuccessModifier Modifier;

	foreach AdditionalSuccessModifiers(Modifier)
	{
		if( AbilityState.GetMyTemplateName() == Modifier.AbilityName )
		{
			// Currently this is only added if the UnitState is also the source 
			// unit of the ability. Additional (either, target, etc) checks
			// should be added as required.
			if( (Modifier.AdditionAbilityRequirement == AbilityRequirement_Source) && 
				(AbilityState.OwnerStateObject.ObjectID != UnitState.ObjectID) )
			{
				continue;
			}

			Successes += Modifier.AddSuccessCheckValue;
		}
	}
}