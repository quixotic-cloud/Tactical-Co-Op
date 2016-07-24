class XComCopyProtection extends object
	dependson(XComMCP)
	native;

var bool bProtectionPassed;
var int ControllerId;

private native function bool PerformCopyCheck();

function StartCheck(byte LocalUserNum)
{
	local XComMcp Mcp;

	if (PerformCopyCheck())
	{
		`log("Starting copy protection check");

		ControllerId = LocalUserNum;

		Mcp = `XENGINE.GetMCP();
		Mcp.OnEventCompleted = WhitelistRetrieved;
		Mcp.CheckWhiteList(ControllerId);
	}
}


simulated function WhitelistRetrieved(bool bWasSuccessful, EOnlineEventType EventType)
{
	local XComMcp Mcp;

	if (EventType == EOET_Auth)
	{
		bProtectionPassed = bWasSuccessful;
		
		if (bWasSuccessful)
		{
			`log("Copy protection passed ");
			// XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GRI.GetALocalPlayerController()).Pres.GetAnchoredMessenger().Message("Copy protection passed ", 0.55f, 0.8f, BOTTOM_CENTER, 5.0f,, eIcon_GenericCircle);
		}
		else
		{
			`log("Copy protection failed. Contact the developer and include this information: ");
			XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GRI.GetALocalPlayerController()).Pres.GetAnchoredMessenger().Message("Blast processing issue. Contact the developer and include this information.", 0.55f, 0.8f, BOTTOM_CENTER, 20.0f,, eIcon_ExclamationMark);

			OnCopyProtectionFailed();
		}

		Mcp = `XENGINE.GetMCP();
		Mcp.OnEventCompleted = none;
	}
}

function OnCopyProtectionFailed()
{
/*	
	local PlayerController PC;

	foreach WorldInfo.AllControllers(class'PlayerController', PC)
	{
		PC.Pause();
	}
	local PlayerController PC;

	foreach `WORLD.AllControllers(class'PlayerController', PC)
	{
		PC.ConsoleCommand( "exit" );
	}
*/
}


function bool ProtectionFailed()
{
	return PerformCopyCheck() && !bProtectionPassed;
}


defaultproperties
{
	bProtectionPassed = false;
}
