class X2AbilityTarget_Self extends X2AbilityTargetStyle native(Core);

simulated function bool SuppressShotHudTargetIcons()
{
	return true;
}

simulated native function name GetPrimaryTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets);
simulated native function name CheckFilteredPrimaryTargets(const XComGameState_Ability Ability, const out array<AvailableTarget> Targets);
