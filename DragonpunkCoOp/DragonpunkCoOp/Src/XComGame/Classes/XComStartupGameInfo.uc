class XComStartupGameInfo extends XComGameInfo;

auto State PendingMatch
{
Begin:
	StartMatch();
}

event InitGame( string Options, out string ErrorMessage )
{
	super.InitGame(Options, ErrorMessage);
}

defaultproperties
{
	
}