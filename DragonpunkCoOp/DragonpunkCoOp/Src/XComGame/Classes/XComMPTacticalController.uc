//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMPTacticalController.uc
//  AUTHOR:  Todd Smith  --  3/23/2010
//  PURPOSE: Controller for the multiplayer tactical game.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComMPTacticalController extends XComTacticalController;

function NotifyConnectionError(EProgressMessageType MessageType, optional string Message, optional string Title)
{
	local X2TacticalMPGameRuleset Ruleset;
	`log(`location @ `ShowVar(MessageType) @ `ShowVar(Message) @ `ShowVar(Title),,'XCom_Online');
	Ruleset = X2TacticalMPGameRuleset(`TACTICALRULES);
	Ruleset.OnNotifyConnectionClosed(0);
}

/**
 * Triggered when the 'disconnect' console command is called, to allow cleanup before disconnecting (e.g. for the online subsystem)
 * NOTE: If you block disconnect, store the 'Command' parameter, and trigger ConsoleCommand(Command) when done; be careful to avoid recursion
 *
 * @param Command	The command which triggered disconnection, e.g. "disconnect" or "disconnect local" (can parse additional parameters here)
 * @return		Return True to block the disconnect command from going through, if cleanup can't be completed immediately
 */
event bool NotifyDisconnect(string Command)
{
	local X2TacticalMPGameRuleset Ruleset;
	`log(self $ "::" $ GetStateName() $ "::" $ GetFuncName() @ `ShowVar(Command), true, 'XCom_Net');
	Ruleset = X2TacticalMPGameRuleset(`TACTICALRULES);
	Ruleset.OnNotifyConnectionClosed(0);
	return true;
}