class X2AbilityMultiTarget_BurstFire extends X2AbilityMultiTargetStyle native(Core);

var int NumExtraShots;

simulated native function GetMultiTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets);

DefaultProperties
{
	bAllowSameTarget=true
}