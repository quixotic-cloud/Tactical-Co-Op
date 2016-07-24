class X2Condition_HasGrappleLocation extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.ObjectID));

	if(UnitState == none || !class'X2GrapplePuck'.static.HasGrappleLocations(UnitState))
		return 'AA_NoTargets';

	return 'AA_Success';
}