class X2AbilityToHitCalc_RollStat extends X2AbilityToHitCalc;

var ECharStatType StatToRoll;
var int BaseChance;

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	local XComGameState_Unit UnitState;
	local ShotBreakdown EmptyShotBreakdown;

	//reset shot breakdown
	m_ShotBreakdown = EmptyShotBreakdown;
	
	AddModifier(BaseChance, class'XLocalizedData'.default.BaseChance);

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	if (UnitState != None)
	{
		AddModifier(UnitState.GetCurrentStat(StatToRoll), class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[StatToRoll]);
	}
	return m_ShotBreakdown.FinalHitChance;
}

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int HitChance, RandRoll;

	HitChance = GetHitChance(kAbility, kTarget);
	RandRoll = `SYNC_RAND(100);

	if (RandRoll < HitChance)
	{
		`log("RollStat for stat" @ StatToRoll @ "@" @ HitChance @ "rolled" @ RandRoll @ "== Success!",true,'XCom_HitRolls');
		ResultContext.HitResult = eHit_Success;
	}
	else
	{
		`log("RollStat for stat" @ StatToRoll @ "@" @ HitChance @ "rolled" @ RandRoll @ "== Miss!",true,'XCom_HitRolls');
		ResultContext.HitResult = eHit_Miss;
	}
}

DefaultProperties
{
	BaseChance = 0
	StatToRoll = eStat_Offense
}