class X2AbilityMultiTarget_Loot extends X2AbilityMultiTarget_Radius
	native(Core);

simulated native function GetMultiTargetsForLocation(const XComGameState_Ability Ability, const vector Location, out AvailableTarget Target);