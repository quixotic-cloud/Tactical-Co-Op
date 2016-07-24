//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_PanicOnPod extends X2Condition;

var int MaxPanicUnitsPerPod;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState, OtherUnit;
	local XComGameState_Effect EffectState;
	local X2Effect_Solace SolaceEffect;
	local XComGameStateHistory History;
	local int PanicCount, ActiveCount;
	local XComGameState_AIGroup AIGroup;
	local array<int> LivingGroupMembers;
	local int GroupIndex;

	UnitState = XComGameState_Unit(kTarget);
	if (UnitState == none)
		return 'AA_NotAUnit';
	if (UnitState.IsDead() || UnitState.IsUnconscious() || UnitState.IsBleedingOut())
		return 'AA_UnitIsDead';

	if (UnitState.IsPanicked())
		return 'AA_UnitIsPanicked';

	EffectState = UnitState.GetUnitAffectedByEffectState(class'X2Effect_Solace'.default.EffectName);
	if (EffectState != none)
	{
		SolaceEffect = X2Effect_Solace(EffectState.GetX2Effect());
		if (SolaceEffect != none)
		{
			if (SolaceEffect.IsEffectCurrentlyRelevant(EffectState, UnitState))
				return 'AA_UnitIsImmune';
		}
	}

	//  Check to see if we are at the panic limit
	if (UnitState.ControllingPlayerIsAI() && (MaxPanicUnitsPerPod > 0))
	{
		History = `XCOMHISTORY;

		PanicCount = 0;
		ActiveCount = 0;
		AIGroup = UnitState.GetGroupMembership();
		if( AIGroup.GetLivingMembers(LivingGroupMembers) )
		{
			for( GroupIndex = 0; GroupIndex < LivingGroupMembers.Length; ++GroupIndex )
			{
				OtherUnit = XComGameState_Unit(History.GetGameStateForObjectID(LivingGroupMembers[GroupIndex]));
				if( OtherUnit != None )
				{
					if (OtherUnit.IsPanicked())
						++PanicCount;
					else if (OtherUnit.IsAbleToAct())
						++ActiveCount;
				}
			}

			if (PanicCount >= MaxPanicUnitsPerPod || ActiveCount == 0)
			{
				return 'AA_UnitIsImmune';
			}
		}
	}

	return 'AA_Success';
}

defaultproperties
{
	MaxPanicUnitsPerPod=0
}