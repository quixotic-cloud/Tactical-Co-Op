//---------------------------------------------------------------------------
// This is currently acting as the multiplayer lobby
// Having the server wait for the required number of players to show up
//---------------------------------------------------------------------------
class XComMPTacticalGame extends XComTacticalGame
	config(MPGame);


simulated function class<X2GameRuleset> GetGameRulesetClass()
{
	return class'X2TacticalMPGameRuleset';
}


//-----------------------------------------------------------
//-----------------------------------------------------------
defaultproperties
{
	PlayerControllerClass=class'XComMPTacticalController'
	GameReplicationInfoClass = class'XComMPTacticalGRI'
	PlayerReplicationInfoClass = class'XComMPTacticalPRI'
	m_iRequiredPlayers = 2;
	m_bMatchStarting=false
}
