//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_UnitEffects.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitEffects extends X2Condition native(Core);

struct native EffectReason
{
	var name EffectName;
	var name Reason;
};

var array<EffectReason> ExcludeEffects;     //Units affected by any effect will be rejected with the given reason
var array<EffectReason> RequireEffects;     //Condition will fail unless every effect in this list is on the unit

function AddExcludeEffect(name EffectName, name Reason)
{
	local EffectReason Exclude;
	Exclude.EffectName = EffectName;
	Exclude.Reason = Reason;
	ExcludeEffects.AddItem(Exclude);
}

function AddRequireEffect(name EffectName, name Reason)
{
	local EffectReason Require;
	Require.EffectName = EffectName;
	Require.Reason = Reason;
	RequireEffects.AddItem(Require);
}

// allows derived templates to allow effects the parent does not
function RemoveExcludeEffect(name EffectName)
{
	local int Index;
	
	for(Index = ExcludeEffects.Length - 1; Index >= 0; Index--)
	{
		if(ExcludeEffects[Index].EffectName == EffectName)
		{
			ExcludeEffects.Remove(Index, 1);
		}
	}
}

// allows derived templates to not require effects the parent does
function RemoveRequireEffect(name EffectName)
{
	local int Index;
	
	for(Index = RequireEffects.Length - 1; Index >= 0; Index--)
	{
		if(RequireEffects[Index].EffectName == EffectName)
		{
			RequireEffects.Remove(Index, 1);
		}
	}
}

native function name MeetsCondition(XComGameState_BaseObject kTarget);
