//---------------------------------------------------------------------------
// Provides the correct ruleset to use for Challenge Mode verification
//---------------------------------------------------------------------------
class XComTacticalGameValidation extends XComTacticalGame;


auto state Validating
{
Begin:
	`log(`location @ "Starting Validation ...");
}

simulated function class<X2GameRuleset> GetGameRulesetClass()
{
	return class'X2TacticalGameValidationRuleset';
}


//-----------------------------------------------------------
//-----------------------------------------------------------
defaultproperties
{

}
