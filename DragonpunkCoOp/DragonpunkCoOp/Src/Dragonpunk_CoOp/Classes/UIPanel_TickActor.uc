// This is an Unreal Script

class UIPanel_TickActor extends Actor;

function SetupTick(float TickTime)
{
	`log(`location @"Trying to connect to server IN FUNCTION TickTime:" @TickTime,,'Team Dragonpunk Co Op');
	SetTimer(TickTime,true,'Connect');
}

function Connect()
{
	local bool ForceSuccess;
	`log(`location @"Trying to connect to server",,'Team Dragonpunk Co Op');
	ForceSuccess=`XCOMNETMANAGER.ForceConnectionAttempt();
	`log(`location @"ForceSuccess"@ForceSuccess,,'Team Dragonpunk Co Op');
	ClearTimer('Connect');
}