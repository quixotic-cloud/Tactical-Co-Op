//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCooldown.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCooldown extends Object;

struct AdditionalCooldownInfo
{
	var name AbilityName;
	var int NumTurns;
	var bool bUseAbilityCooldownNumTurns;
	var name ApplyCooldownType;

	structdefaultproperties
	{
		AbilityName = ""
		NumTurns = 0
		bUseAbilityCooldownNumTurns = false
		ApplyCooldownType = "AdditionalCooldown_ApplyLarger"
	}
};

var int     iNumTurns;
var bool    bDoNotApplyOnHit;
var array<AdditionalCooldownInfo> AditionalAbilityCooldowns;

var privatewrite name AdditionalCooldown_ApplyLarger, AdditionalCooldown_ApplySmaller;

simulated function ApplyCooldown(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameStateContext_Ability AbilityContext;

	// For debug only
	if(`CHEATMGR != None && `CHEATMGR.strAIForcedAbility ~= string(kAbility.GetMyTemplateName()))
		iNumTurns = 0;

	if(bDoNotApplyOnHit)
	{
		AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
		if(AbilityContext != None && AbilityContext.IsResultContextHit())
			return;
	}
	kAbility.iCooldown = GetNumTurns(kAbility, AffectState, AffectWeapon, NewGameState);

	ApplyAdditionalCooldown(kAbility, AffectState, AffectWeapon, NewGameState);
}

simulated function int GetNumTurns(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	return iNumTurns;
}

simulated function ApplyAdditionalCooldown(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local int i;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit UnitState;
	local StateObjectReference AbilityRef;
	local bool bNeedToAddAbility;
	local int CooldownTurns;

	UnitState = XComGameState_Unit(AffectState);
	if(UnitState != none)
	{
		for(i = 0; i < AditionalAbilityCooldowns.Length; ++i)
		{
			bNeedToAddAbility = false;

			AbilityRef = UnitState.FindAbility(AditionalAbilityCooldowns[i].AbilityName);
			if(AbilityRef.ObjectID != 0)
			{
				AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(AbilityRef.ObjectID));
				if(AbilityState == none)
				{
					// This AbilityState needs to be added to the NewGameState
					AbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', AbilityRef.ObjectID));
					bNeedToAddAbility = true;
				}

				CooldownTurns = AditionalAbilityCooldowns[i].NumTurns;
				if(AditionalAbilityCooldowns[i].bUseAbilityCooldownNumTurns)
				{
					// Calculate the number of turns based upon this ability's cooldown
					CooldownTurns = AbilityState.GetMyTemplate().AbilityCooldown.GetNumTurns(AbilityState, AffectState, AffectWeapon, NewGameState);
				}

				switch(AditionalAbilityCooldowns[i].ApplyCooldownType)
				{
				case AdditionalCooldown_ApplyLarger:
					if(AbilityState.iCooldown < CooldownTurns)
					{
						AbilityState.iCooldown = CooldownTurns;
					}
					break;

				case AdditionalCooldown_ApplySmaller:
					if((AbilityState.iCooldown == 0) || (AbilityState.iCooldown > CooldownTurns))
					{
						AbilityState.iCooldown = CooldownTurns;
					}
					break;

				default:
					// The CooldownType needs to be a value in the case statements
					`Redscreen(AditionalAbilityCooldowns[i].ApplyCooldownType @ " is not a valid ApplyCooldownType for AdditionalCooldownInfo.");
					break;
				}

				if(bNeedToAddAbility)
				{
					NewGameState.AddStateObject(AbilityState);
				}
			}
		}
	}
}

defaultproperties
{
	AdditionalCooldown_ApplyLarger = "AdditionalCooldown_ApplyLarger"
	AdditionalCooldown_ApplySmaller = "AdditionalCooldown_ApplySmaller"
}
