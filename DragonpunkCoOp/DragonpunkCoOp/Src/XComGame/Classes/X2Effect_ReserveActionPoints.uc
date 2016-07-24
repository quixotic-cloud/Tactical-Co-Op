class X2Effect_ReserveActionPoints extends X2Effect;

var name ReserveType;       //  type of action point to reserve
var int NumPoints;          //  number of points to reserve

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;
	local int i, Points;

	TargetUnitState = XComGameState_Unit(kNewTargetState);
	if( TargetUnitState != none )
	{
		Points = GetNumPoints(TargetUnitState);

		for (i = 0; i < Points; ++i)
		{
			TargetUnitState.ReserveActionPoints.AddItem(GetReserveType(ApplyEffectParameters, NewGameState));
		}
		TargetUnitState.ActionPoints.Length = 0;
	}
}

simulated function name GetReserveType(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	return ReserveType;
}

simulated protected function int GetNumPoints(XComGameState_Unit UnitState)
{
	return NumPoints;
}

DefaultProperties
{
	NumPoints = 1
}