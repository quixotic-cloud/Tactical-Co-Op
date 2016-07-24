class X2Condition_BattleState extends X2Condition;

var bool bMissionAborted;
var bool bMissionNotAborted;
var bool bCiviliansTargetedByAliens;
var bool bCiviliansNotTargetedByAliens;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (BattleData == none)
		return 'AA_UnknownError';

	if (bMissionAborted && !BattleData.bMissionAborted)
		return 'AA_AbilityUnavailable';

	if (bMissionNotAborted && BattleData.bMissionAborted)
		return 'AA_AbilityUnavailable';

	if( bCiviliansTargetedByAliens && !BattleData.AreCiviliansAlienTargets() )
		return 'AA_AbilityUnavailable';

	if( bCiviliansNotTargetedByAliens && BattleData.AreCiviliansAlienTargets() )
		return 'AA_AbilityUnavailable';

	return 'AA_Success';
}