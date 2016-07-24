class X2Condition_MapProperty extends X2Condition;

var array<string> AllowedBiomes;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if (AllowedBiomes.Length > 0)
	{
		if (AllowedBiomes.Find(BattleData.MapData.Biome) == INDEX_NONE)
			return 'AA_WrongBiome';
	}

	return 'AA_Success';
}