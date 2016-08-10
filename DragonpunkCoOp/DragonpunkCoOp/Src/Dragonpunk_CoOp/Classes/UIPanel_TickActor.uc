// This is an Unreal Script

class UIPanel_TickActor extends Actor;


function SetupTick(float TickTime)
{
	`log(`location @"Trying to connect to server IN FUNCTION TickTime:" @TickTime,,'Team Dragonpunk Co Op');
	SetTimer(TickTime,true,'Connect');
}
function SetupCoOpTimer(float TickTime)
{
	`log(`location @"Trying to Create server IN FUNCTION TickTime:" @TickTime,,'Team Dragonpunk Co Op');
	SetTimer(TickTime,true,'OnCreateCoOpGameTimerComplete');
}
function Connect()
{
	local bool ForceSuccess;
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`log(`location @"Trying to connect to server",,'Team Dragonpunk Co Op');
	ForceSuccess=`XCOMNETMANAGER.ForceConnectionAttempt();
	if(ForceSuccess) `XCOMNETMANAGER.SendRemoteCommand("HostJoined",Parms);
	`log(`location @"ForceSuccess"@ForceSuccess,,'Team Dragonpunk Co Op');
	ClearTimer('Connect');
}

function OnCreateCoOpGameTimerComplete()
{
	//clear any repeat timers to prevent the multiplayer match from exiting prematurely during load
	`PRESBASE.ClearInput();
	`log("Starting Network Game Ended", true, 'Team Dragonpunk Co Op');
	//set the input state back to normal
	XComShellInput(XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).PlayerInput).PopState();
	ClearTimer('OnCreateCoOpGameTimerComplete');
}