// This is an Unreal Script
                           
class XComPresentationLayerBase_CoOp_Override extends XComPresentationLayerBase;

simulated function StartMPShellState() 
{
	local UISquadSelect SquadSelectScreen;

	`ONLINEEVENTMGR.ClearGameInviteAcceptedDelegate(CoopGameInviteAccepted);
	`ONLINEEVENTMGR.ClearGameInviteCompleteDelegate(CoopGameInviteComplete);
	if(class'XComOnlineEventMgr_Co_Op_Override'.static.IsInvitedToCoOp())
	{
		if(!`SCREENSTACK.IsCurrentScreen('UISquadSelect'))
		{
			`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(CoopGameInviteAccepted);
			`ONLINEEVENTMGR.AddGameInviteCompleteDelegate(CoopGameInviteComplete);
			SquadSelectScreen=(`SCREENSTACK.Screens[0].Spawn(Class'UISquadSelect',none));
			`SCREENSTACK.Push(SquadSelectScreen);
			`log("Pushing SquadSelectUI to screen stack",true,'Team Dragonpunk');
		}
		else
		{
			`log("Already in Squad Select UI",true,'Team Dragonpunk');
		}
	}
    else if( !WorldInfo.Game.IsA('XComMPShell') )
	{
		ConsoleCommand("open XComShell_Multiplayer.umap?Game=XComGame.XComMPShell");
	}
}
function CoopGameInviteAccepted(bool bWasSuccessful)
{
	//local UISquadSelect SquadSelectScreen;
	
	`log(bWasSuccessful @"OnGameInviteAccepted", true, 'Team Dragonpunk');
	if(`XENGINE.IsAnyMoviePlaying())
		`XENGINE.StopCurrentMovie();
	if(bWasSuccessful)
	{		
		//`SCREENSTACK.Screens[0].ConsoleCommand("open"@`Maps.SelectShellMap()$"?Game=XComGame.XComShell");
		//SquadSelectScreen=(`SCREENSTACK.Screens[0].Spawn(Class'UISquadSelect',none));
		//if(`XENGINE.IsAnyMoviePlaying())
		//`XENGINE.StopCurrentMovie();
		//`SCREENSTACK.Push(SquadSelectScreen);
	}	
//`ONLINEEVENTMGR.TriggerAcceptedInvite();
}

function CoopGameInviteComplete(ESystemMessageType MessageType, bool bWasSuccessful)
{
	`log(bWasSuccessful @"OnGameInviteComplete", true, 'Team Dragonpunk');
}