class X2SoldierIntegratedWarfareUnlockTemplate extends X2SoldierUnlockTemplate config(GameData_SoldierSkills);

var config float StatBoostValue;
var config int StatBoostIncrement;

function OnSoldierUnlockPurchased(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local StateObjectReference CrewRef;
	local XComGameState_Unit UnitState, NewUnitState;
	local XComGameState_Item CombatSim;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	foreach XComHQ.Crew(CrewRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(CrewRef.ObjectID));
	    if (UnitState != none && UnlockAppliesToUnit(UnitState))
		{
			CombatSim = UnitState.GetItemInSlot(eInvSlot_CombatSim);
			if (CombatSim != none)
			{
				NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
				NewUnitState.UnapplyCombatSimStats(CombatSim, false);
				NewUnitState.ApplyCombatSimStats(CombatSim, false, true);
				NewGameState.AddStateObject(NewUnitState);
			}
		}
	}
}

DefaultProperties
{
	bAllClasses = true
}