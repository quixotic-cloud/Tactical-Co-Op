class XGAIBehavior_AdventTroopTransport extends XGAIBehavior;

state ExecutingAI
{
Begin:	
	SkipTurn();
	GotoState('EndOfTurn');
}