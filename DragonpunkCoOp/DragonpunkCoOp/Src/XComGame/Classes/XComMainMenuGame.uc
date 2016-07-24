//-----------------------------------------------------------
// FIRAXIS SOURCE CODE
// Copyright 2009 Firaxis Games
//-----------------------------------------------------------

class XComMainMenuGame extends XComMainMenuGameInfoNativeBase;

auto State PendingMatch
{
Begin:
	StartMatch();
}

event InitGame( string Options, out string ErrorMessage )
{
	super.InitGame(Options, ErrorMessage);
}


// Here you define the properties and classes your game type will use
// Such as the HUD, scoreboard, player controller, replication (networking) controller
defaultproperties
{
	PlayerControllerClass=class'XComGame.XComMainMenuController'
}




