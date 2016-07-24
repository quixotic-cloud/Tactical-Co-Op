class X2Effect_SharpshooterAim extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMan;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMan = `XEVENTMGR;
	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	EventMan.RegisterForEvent(EffectObj, 'AbilityActivated', class'XComGameState_Effect'.static.SharpshooterAimListener, ELD_OnStateSubmitted, , UnitState);
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotInfo;

	if (!bMelee)
	{
		ShotInfo.ModType = eHit_Success;
		ShotInfo.Reason = FriendlyName;
		ShotInfo.Value = class'X2Ability_SharpshooterAbilitySet'.default.SHARPSHOOTERAIM_BONUS;
		ShotModifiers.AddItem(ShotInfo);
	}
}

DefaultProperties
{
	DuplicateResponse = eDupe_Refresh           //  if you keep using hunker down, just extend the lifetime of the effect
	EffectName = "SharpshooterAimBonus"
}