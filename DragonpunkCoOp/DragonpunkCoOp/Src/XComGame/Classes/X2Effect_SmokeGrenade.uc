class X2Effect_SmokeGrenade extends X2Effect_Persistent;

var int HitMod;

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	if (Target.IsInWorldEffectTile(class'X2Effect_ApplySmokeGrenadeToWorld'.default.Class.Name))
	{
		ShotMod.ModType = eHit_Success;
		ShotMod.Value = HitMod;
		ShotMod.Reason = FriendlyName;
		ShotModifiers.AddItem(ShotMod);
	}
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	return TargetUnit.IsInWorldEffectTile(class'X2Effect_ApplySmokeGrenadeToWorld'.default.Class.Name);
}

static function SmokeGrenadeVisualizationTickedOrRemoved(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local X2Action_UpdateUI UpdateUIAction;

	UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	UpdateUIAction.SpecificID = BuildTrack.StateObject_NewState.ObjectID;
	UpdateUIAction.UpdateType = EUIUT_UnitFlag_Buffs;
}


DefaultProperties
{
	EffectName = "SmokeGrenade"
	DuplicateResponse = eDupe_Refresh
	EffectTickedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
	EffectRemovedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
}