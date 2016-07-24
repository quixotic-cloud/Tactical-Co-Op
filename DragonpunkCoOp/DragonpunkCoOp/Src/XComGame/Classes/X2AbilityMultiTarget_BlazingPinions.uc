class X2AbilityMultiTarget_BlazingPinions extends X2AbilityMultiTarget_Radius
	native(Core);

simulated native function bool CalculateValidLocationsForLocation(const XComGameState_Ability Ability, const vector Location, AvailableTarget AvailableTargets, out array<vector> ValidLocations);