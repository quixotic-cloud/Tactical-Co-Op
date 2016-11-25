// This is an Unreal Script
//                           
// NOT USING THIS CLASS. Will delete when making sure it dosnt do anything bad to the game

               
class XCom_Co_Op_TacticalGameManager extends Actor;

var array<XComGameState_Unit> RemoteUnits;
var array<XComGameState_Unit> LocalUnits;

var XComGameState_Player ServerPlayer,ClientPlayer;

var XComReplayMgr ReplayMgr;

function InitManager(Optional array<XComGameState_Unit> LocalUnitsA ,Optional array<XComGameState_Unit> RemoteUnitsA)
{
	/*local XComGameState_BattleData BattleData;
	local object myself;
	local int i;
	local XComGameStateHistory History;
	myself=self;
	History=`XCOMHISTORY;
	RemoteUnits=RemoteUnitsA;
	LocalUnits=LocalUnitsA;
	ReplayMgr = Spawn(class'XComReplayMgr', self);
	if(`XCOMNETMANAGER.HasServerConnection())
		`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_XComPlayerWatcher);

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	for(i=1;i<BattleData.PlayerTurnOrder.Length;i++)
	{
		if(XComGameState_Player(History.GetGameStateForObjectID(BattleData.PlayerTurnOrder[i].ObjectID)).GetTeam()==eTeam_XCom&&XComGameState_Player(History.GetGameStateForObjectID(StateObjectReference(BattleData.PlayerTurnOrder[i-1]).ObjectID)).GetTeam()==eTeam_XCom)
		{
			ServerPlayer=XComGameState_Player(History.GetGameStateForObjectID(StateObjectReference(BattleData.PlayerTurnOrder[i-1]).ObjectID));
			ClientPlayer=XComGameState_Player(History.GetGameStateForObjectID(StateObjectReference(BattleData.PlayerTurnOrder[i]).ObjectID));
			break;
		}
	}*/
	SendRemoteCommand("EnterStates");
}

static function OnNewGameState_XComPlayerWatcher(XComGameState GameState) //Thank you Amineri and LWS! 
{
/*	local int StateObjectIndex;
	local XComGameState_BaseObject StateObjectCurrent;
	local array<bool> Send;
	local XComGameState_BaseObject StateObjectPrevious;
	local XComGameState_Player OldLocalPlayer;
	local XComGameState_Unit UpdatedUnit,OldUnit;
	local XComGameState_BattleData NewBattleData,OldBattleData;

	if(!`XCOMNETMANAGER.HasConnections())return;
    for( StateObjectIndex = 0; StateObjectIndex < GameState.GetNumGameStateObjects(); ++StateObjectIndex )
	{	
		if(XComGameState_BattleData(GameState.GetGameStateForObjectIndex(StateObjectIndex))!=none)
		{
			OldBattleData=XComGameState_BattleData(GameState.GetGameStateForObjectIndex(StateObjectIndex));
			Send.AddItem(True);
		}
		else if(XComGameState_Player(GameState.GetGameStateForObjectIndex(StateObjectIndex))!=none)
		{
			if(XComGameState_Player(GameState.GetGameStateForObjectIndex(StateObjectIndex)).GetTeam()==eTeam_XCom)
				OldLocalPlayer=XComGameState_Player(GameState.GetGameStateForObjectIndex(StateObjectIndex));

			Send.AddItem(True);
		}
	}
	if(Send.Length==4)
	{
		GameState.AddStateObject(NewBattleData);
		//GameState.AddStateObject(ServerPlayer);
		//GameState.AddStateObject(RemotePlayer);
		//RemotePlayer.PlayerName$="Client";
		//ServerPlayer.PlayerName$="Server";
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', OldUnit )
		{
			UpdatedUnit=XComGameState_Unit(GameState.CreateStateObject(class'XComGameState_Unit',OldUnit.ObjectID));
			GameState.AddStateObject(UpdatedUnit);
			//UpdatedUnit.SetControllingPlayer(RemoteUnits.Find(UpdatedUnit)!=-1 ? RemotePlayer.GetReference() : LocalPlayer.GetReference());
		}
		`log("Send.Length==4",,'Dragonpunk Co Op');
		`XCOMHISTORY.AddGameStateToHistory(GameState);
	}
	else if(Send.Length==5)
	{
		`XCOMNETMANAGER.SendHistory(`XCOMHISTORY, `XEVENTMGR);
		`XCOMNETMANAGER.SendMergeGameState(GameState);
		`XCOMHISTORY.UnRegisterOnNewGameStateDelegate(OnNewGameState_XComPlayerWatcher);
		`log("Send.Length==5",,'Dragonpunk Co Op');
	}
*/
}



static function SendRemoteCommand(string Command) //Copied from UIMPShell_Lobby
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`XCOMNETMANAGER.SendRemoteCommand(Command, Parms);
	`log("Sent Remote Command '"$Command$"'",,'Team Dragonpunk Co Op');
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	if(Command~="GoToReplayMode")	
	{
		if(!`XCOMNETMANAGER.HasServerConnection())
			ReplayMgr.StartReplay(0);
	}
	else if(Command~="GoToReplayMode_Server")	
	{
		if(`XCOMNETMANAGER.HasServerConnection())
			ReplayMgr.StartReplay(0);
	}
	else if(Command~="EnterStates")
	{
		if(`XCOMNETMANAGER.HasServerConnection())
			GoToState('ServerPlayerTurn');
		else if(`XCOMNETMANAGER.HasClientConnection())
			GoToState('ClientPlayerTurn');
	}
	global.OnRemoteCommand(Command, RawParams);
}
static function OnNewGameState_GeneralGameStateWatcher(XComGameState GameState) //Thank you Amineri and LWS! 
{
	
	`XCOMNETMANAGER.SendGameState(GameState,0);

	if(`XCOMNETMANAGER.HasServerConnection())
		SendRemoteCommand("GoToReplayMode");

	else if(`XCOMNETMANAGER.HasClientConnection())
		SendRemoteCommand("GoToReplayMode_Server");
}

State ServerPlayerTurn
{
	
	function StartServerTurnEndWait()
	{
		local Object ThisObj;
		ThisObj=self;
		`XEVENTMGR.RegisterForEvent( ThisObj, 'PlayerTurnEnded', OnServerTurnEnded, ELD_OnStateSubmitted);		
	}
	function StartServerTurnStartWait()
	{
		local Object ThisObj;
		ThisObj=self;
		`XEVENTMGR.RegisterForEvent( ThisObj, 'PlayerTurnBegun', OnServerTurnBegun, ELD_OnStateSubmitted);	
	}
	function EventListenerReturn OnServerTurnEnded(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
	{
		if(InStr(XComGameState_Player(EventData).PlayerName,"Server")!=-1)
			`XCOMHISTORY.UnRegisterOnNewGameStateDelegate(OnNewGameState_GeneralGameStateWatcher);	
		return ELR_NoInterrupt;
	}
	function EventListenerReturn OnServerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
	{
		if(InStr(XComGameState_Player(EventData).PlayerName,"Server")!=-1)
		{
			`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_GeneralGameStateWatcher);	
			ReplayMgr.StopReplay();	
		}	
		return ELR_NoInterrupt;
	}
	Begin:
		SendRemoteCommand("EnterStates");
		ReplayMgr.StopReplay();
		StartServerTurnEndWait();
		StartServerTurnStartWait();		
}

State ClientPlayerTurn
{
	function StartClientTurnEndWait()
	{
		local Object ThisObj;
		ThisObj=self;
		`XEVENTMGR.RegisterForEvent( ThisObj, 'PlayerTurnEnded', OnClientTurnEnded, ELD_OnStateSubmitted);		
	}
	function StartClientTurnStartWait()
	{
		local Object ThisObj;
		ThisObj=self;
		`XEVENTMGR.RegisterForEvent( ThisObj, 'PlayerTurnBegun', OnClientTurnBegun, ELD_OnStateSubmitted);	
	}
	function EventListenerReturn OnClientTurnEnded(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
	{
		if(InStr(XComGameState_Player(EventData).PlayerName,"Client")!=-1)
			`XCOMHISTORY.UnRegisterOnNewGameStateDelegate(OnNewGameState_GeneralGameStateWatcher);	
		return ELR_NoInterrupt;
	}
	function EventListenerReturn OnClientTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
	{
		if(InStr(XComGameState_Player(EventData).PlayerName,"Client")!=-1)
		{
			`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_GeneralGameStateWatcher);	
			ReplayMgr.StopReplay();	
		}	
		return ELR_NoInterrupt;
	}
	Begin:
		SendRemoteCommand("EnterStates");
		ReplayMgr.StopReplay();
		StartClientTurnEndWait();
		StartClientTurnStartWait();
		
}
