//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_CoveringFire.uc
//  AUTHOR:  Joshua Bouscher  --  2/11/2015
//  PURPOSE: Put this effect on a unit to allow overwatch shots against enemy attacks.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_CoveringFire extends X2Effect_Persistent;

var name AbilityToActivate;         //  ability to activate when the covering fire check is matched
var name GrantActionPoint;          //  action point to give the shooter when covering fire check is matched
var int MaxPointsPerTurn;           //  max times per turn the action point can be granted
var bool bDirectAttackOnly;         //  covering fire check can only match when the target of this effect is directly attacked
var bool bPreEmptiveFire;           //  if true, the reaction fire will happen prior to the attacker's shot; otherwise it will happen after
var bool bOnlyDuringEnemyTurn;      //  only activate the ability during the enemy turn (e.g. prevent return fire during the sharpshooter's own turn)
var bool bUseMultiTargets;          //  initiate AbilityToActivate against yourself and look for multi targets to hit, instead of direct retaliation

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', EffectGameState.CoveringFireCheck, ELD_OnStateSubmitted);
}

DefaultProperties
{
	bPreEmptiveFire = true
}