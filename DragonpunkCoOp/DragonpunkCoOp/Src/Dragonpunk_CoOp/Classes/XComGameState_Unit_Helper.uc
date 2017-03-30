// This is an Unreal Script

class XComGameState_Unit_Helper extends XComGameState_Unit;

static function ChangeUnitRank(XComGameState_Unit Unit , int Rank)
{
	Unit.m_SoldierRank=Rank;
}