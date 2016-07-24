class X2Effect_ModifyReactionFire extends X2Effect_Persistent;

var bool bAllowCrit;
var int ReactionModifier;

function bool AllowReactionFireCrit(XComGameState_Unit UnitState, XComGameState_Unit TargetState) 
{ 
	return bAllowCrit; 
}

function ModifyReactionFireSuccess(XComGameState_Unit UnitState, XComGameState_Unit TargetState, out int Modifier)
{
	Modifier = ReactionModifier;
}