class XComGameState_GameTime extends XComGameState_BaseObject;

var() TDateTime     CurrentTime;

static function CreateGameStartTime(XComGameState StartState)
{
	local XComGameState_GameTime TimeState;

	TimeState = XComGameState_GameTime(StartState.CreateStateObject(class'XComGameState_GameTime'));
	class'X2StrategyGameRulesetDataStructures'.static.SetTime(TimeState.CurrentTime, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH, class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );	
	StartState.AddStateObject(TimeState);

	if (`STRATEGYRULES != none)
		`STRATEGYRULES.GameTime = TimeState.CurrentTime;
}