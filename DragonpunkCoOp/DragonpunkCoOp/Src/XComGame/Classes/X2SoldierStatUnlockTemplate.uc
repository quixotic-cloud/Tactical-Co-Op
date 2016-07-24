class X2SoldierStatUnlockTemplate extends X2SoldierUnlockTemplate;

var ECharStatType   BoostStat;
var int				BoostMaxValue;

function OnSoldierUnlockPurchased(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local StateObjectReference CrewRef;
	local XComGameState_Unit UnitState, NewUnitState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	foreach XComHQ.Crew(CrewRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(CrewRef.ObjectID));
	    if (UnitState != none && UnlockAppliesToUnit(UnitState))
		{
			NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
			StatBoostUnit(NewUnitState);
			NewGameState.AddStateObject(NewUnitState);
		}
	}
}

function OnSoldierAddedToCrew(XComGameState_Unit NewUnitState)
{
	if (UnlockAppliesToUnit(NewUnitState))
		StatBoostUnit(NewUnitState);
}

function StatBoostUnit(XComGameState_Unit UnitState)
{
	local int MaxStat;

	MaxStat = UnitState.GetMaxStat(BoostStat) + BoostMaxValue;
	UnitState.SetBaseMaxStat(BoostStat, MaxStat);
	UnitState.SetCurrentStat(BoostStat, MaxStat);
}

function bool ValidateTemplate(out string strError)
{
	if (BoostStat == eStat_Invalid)
	{
		strError = "no stat specified";
		return false;
	}
	return super.ValidateTemplate(strError);
}