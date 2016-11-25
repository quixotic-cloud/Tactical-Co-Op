//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    UI_Listener_SquadSelect
//  AUTHOR:  Elad Dvash
//  PURPOSE: Deals with everything that happens in the squad select screen,Including
//	spawning the buttons on the screen in order to be able to show/hide when appropriate
//---------------------------------------------------------------------------------------
                           
class UI_Listener_SquadSelect extends UIScreenListener;

var array<UIButton> AllButtons;
var array<UITextContainer> AllText;
var X2_Actor_InviteButtonManager IBM;
var bool Once,bHistoryLoaded;
var XComCo_Op_ConnectionSetup ConnectionSetupActor;
var bool AlreadyInvitedFriend;
var bool PlayingCoop;
var array<StateObjectReference> SavedSquad;
var array<StateObjectReference> ServerSquad,ClientSquad;
var bool Launched;
var UIPanel_TickActor MyTick;
event OnInit(UIScreen Screen)
{
	
	if(Screen.isA('UISquadSelect'))
	{
		OnReceiveFocus(Screen);
	}
	else if (Screen.isA('UIMissionSummary'))
	{
		`log("UI Mission Summary Initiated Cleanup!");
		Cleanup();
				
		if (ConnectionSetupActor != none)
		{
			ConnectionSetupActor.Destroy();
			ConnectionSetupActor=none;
		}
	}
	else if(PlayingCoop && Screen.IsA('UITacticalHUD'))
	{
		SetTimersStart();
	}

}



function DisconnectGame()
{
	if(`XCOMNETMANAGER.HasClientConnection())
	{
		`XCOMNETMANAGER.Disconnect();
	}
}

function Cleanup()
{
	local UIButton TB;
	local UITextContainer TT;

	if(IBM!=none)
	{
		IBM.KillUpdateButtons();
		IBM.Destroy();
		IBM=none;	

	}
	foreach AllButtons(TB)
	{
		TB.Remove();
	}
	foreach AllText(TT)
	{
		TT.Remove();
	}
	AllText.Length=0;
	AllButtons.Length=0;	
}

function EventListenerReturn EndedTacticalGameplay(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	ConnectionSetupActor.Destroy();
	ConnectionSetupActor=none;
	return ELR_NoInterrupt;
}
event OnReceiveFocus(UIScreen Screen)
{
	local UISquadSelect SSS;
	local int i,Count;
	local float listWidth,listX;
	local UISquadSelect UISS;
	if(Screen.isA('UISquadSelect'))
	{
		UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		listWidth =( UISS.GetTotalSlots()+(int(UISS.ShowExtraSlot1())*-2) )* (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
		listX =(UISS.Movie.GetUIResolution().X / 2) - (listWidth/2);
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(0); //fixes the x position of the list on the screen
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation();
		if(ConnectionSetupActor==none)
			Once=false;

		if(!once)
		{
			`XCOMNETMANAGER.AddReceiveHistoryDelegate(ReceiveHistory);
			`XCOMNETMANAGER.AddReceiveMergeGameStateDelegate(ReceiveMergeGameState);
			ConnectionSetupActor=Screen.Spawn(class'XComCo_Op_ConnectionSetup',none);
			ConnectionSetupActor.ChangeInviteAcceptedDelegates();
			Once=true;
		}

		if(ConnectionSetupActor!=none)
		{
			ConnectionSetupActor.RevertInviteAcceptedDelegates();// Cleanup delegates before doing anything
			ConnectionSetupActor.ChangeInviteAcceptedDelegates();// Re-register for all delegates
		}
		if(IBM==none)
			IBM=Screen.Spawn(class'X2_Actor_InviteButtonManager');
		IBM.StartsUpdateButtons();
		AllButtons.Length=0;
		AllText.Length=0;
		
	
		//`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
		//`ONLINEEVENTMGR.AddGameInviteCompleteDelegate(OnGameInviteComplete);
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.SetPosition((UISS.Movie.GetUIResolution().X / 2),-UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.Height*0.5);
		XComCheatManager(UISquadSelect(Screen).GetALocalPlayerController().CheatManager).UnsuppressMP(); //Unsuppress log types
		SSS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		Count=SSS.m_kSlotList.ItemCount;
		for(i=0;i<Count*2;i++)
		{
			if(i%2==0)
				AllButtons[i] = SSS.Spawn(class'UIButton', SSS.m_kSlotList.GetItem(i/2));//Adds the new "Select Player" button
			else
				AllButtons[i] = SSS.Spawn(class'UIButton', SSS.m_kSlotList.GetItem((i-1)/2));//Adds the new "Invite Friend" button

			AllButtons[i].SetResizeToText(false);
			if(i%2==0)	
				AllButtons[i].InitButton('SelectPlayer',,OnSelectSoldier,eUIButtonStyle_BUTTON_WHEN_MOUSE);
			else		
				AllButtons[i].InitButton('InvitePlayer',,OnInviteFriend,eUIButtonStyle_BUTTON_WHEN_MOUSE);
			AllButtons[i].SetTextAlign("center");
			AllButtons[i].SetFontSize(24);
			AllButtons[i].SetHeight(79+35);
			AllButtons[i].SetWidth(282);
			if(i%2==0)	
				AllButtons[i].SetY((79+35)*0.75);	
			else		
				AllButtons[i].SetY((79+35)*1.75);	
			if(i%2==0)	
				AllText[i]= SSS.Spawn(class'UITextContainer',AllButtons[i]).InitTextContainer('InvitePlayerText',class'UIUtilities_Text'.static.GetSizedText("SELECT SOLDIER",24),AllButtons[i].Width/6,AllButtons[i].Height*1/3,AllButtons[i].Width,AllButtons[i].Height); //play with the third and forth parameters for adjusting X,Y accordingly!
			else		
				AllText[i]= SSS.Spawn(class'UITextContainer',AllButtons[i]).InitTextContainer('InvitePlayerText',class'UIUtilities_Text'.static.GetSizedText("INVITE FRIEND",24),AllButtons[i].Width/5,AllButtons[i].Height*1/3,AllButtons[i].Width,AllButtons[i].Height);  //play with the third and forth parameters for adjusting X,Y accordingly!
			AllText[i].RealizeTextSize();
			AllText[i].Show();
			AllButtons[i].Show();
		}
		UISS=UISquadSelect(Screen);
		listWidth =( UISS.GetTotalSlots()+(int(UISS.ShowExtraSlot1())*-2) )* (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);	
		listX =(UISS.Movie.GetUIResolution().X / 2) - (listWidth/2);
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(UISS.Movie.UI_RES_X / 2); //fixes the x position of the list on the screen
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation(); //fixes the x position of the list on the screen
		if(UIDialogueBox(UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).ShowingDialog())
			UIDialogueBox(UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).RemoveDialog();
		if(`XCOMNETMANAGER.HasClientConnection())
			UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.Hide();
		else 
		{
			//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.AnchorTopCenter();
		}
		
	}
	else if(Screen.isA('UIDialogueBox'))
	{
		if(UIDialogueBox(Screen).ShowingDialog())
			UIDialogueBox(Screen).RemoveDialog();				
	}
	
}

function SetTimersStart()
{
	local SeqVar_Int TimerVariable;
	local WorldInfo wInfo;
	local Sequence mainSequence;
	local array<SequenceObject> SeqObjs;
	local int i,k;
	wInfo = `XWORLDINFO;
	mainSequence = wInfo.GetGameSequence();
	if (mainSequence != None)
	{
		`Log("Game sequence found: " $ mainSequence);
		mainSequence.FindSeqObjectsByClass( class'SequenceVariable', true, SeqObjs);
		if(SeqObjs.Length != 0)
		{
			`Log("Kismet variables found");
			for(i = 0; i < SeqObjs.Length; i++)
			{
				if(InStr(string(SequenceVariable(SeqObjs[i]).VarName), "DefaultTurns") != -1)
				{
					`Log("Variable found: " $ SequenceVariable(SeqObjs[i]).VarName);
					`Log("IntValue = " $ SeqVar_Int(SeqObjs[i]).IntValue);
					TimerVariable = SeqVar_Int(SeqObjs[i]);
					TimerVariable.IntValue = TimerVariable.IntValue*3;
					`Log("Timer set to: " $ TimerVariable.IntValue);
				}	
			}
		}
	}
}



event OnLoseFocus(UIScreen Screen)
{
		
}
// This event is triggered when a screen is removed
event OnRemoved(UIScreen Screen)
{
	if(Screen.isA('UISquadSelect'))
	{
		IBM.KillUpdateButtons();
		IBM.Destroy();
		AllText.Length=0;
		AllButtons.Length=0;	
	}
	if (Screen.isA('UIAfterAction')) 
	{
		DisconnectGame();
	}
}

simulated function OnInviteFriend(UIButton button)
{
	local XComGameState_HeadquartersXCom XComHQ;
	if(ConnectionSetupActor!=none)
	{
		ConnectionSetupActor.RevertInviteAcceptedDelegates();// Cleanup delegates before doing anything
		ConnectionSetupActor.ChangeInviteAcceptedDelegates();// Re-register for all delegates
	}
	`log("Invited Friend!",true,'Team Dragonpunk Soldiers of Fortune');
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Class'Engine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('Game');	//Destroy any lingering Online games
	`XCOMNETMANAGER.AddNotifyConnectionClosedDelegate(OnNotifyConnectionClosed);
//	`XCOMNETMANAGER.Disconnect();
//	`XCOMNETMANAGER.ResetConnectionData();
  	ClientSquad.Length=0;
	ServerSquad.Length=0;
	SavedSquad=XComHQ.Squad;
	ServerSquad=XComHQ.Squad;
	ConnectionSetupActor.SavedSquad=XComHQ.Squad;
	ConnectionSetupActor.ServerSquad=XComHQ.Squad;
	ConnectionSetupActor.CreateOnlineGame();
	PlayingCoop=true;
}

function OnNotifyConnectionClosed(int ConnectionIdx)
{
	`log("On Connection Closed!");
	`XCOMNETMANAGER.ClearNotifyConnectionClosedDelegate(OnNotifyConnectionClosed);
}

simulated function OnSelectSoldier(UIButton button)
{
	UISquadSelect_ListItem(button.ParentPanel).OnClickedSelectUnitButton(); //Turn to the stock soldier selection menu
	`log("Selected Soldier!",true,'Team Dragonpunk');
}

function RevertInviteAcceptedDelegates()
{	
	`XCOMNETMANAGER.ClearReceiveHistoryDelegate(ReceiveHistory);
	`XCOMNETMANAGER.ClearReceiveMergeGameStateDelegate(ReceiveMergeGameState);
}

function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	local float listWidth,listX;
	local XComGameState_HeadquartersXCom XComHQ;
	local UISquadSelect UISS;
	local XComGameState FullGameState;

	if(!bHistoryLoaded)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		`log(`location,,'XCom_Online');
		`log(`location @"Dragonpunk Recieved History",,'Team Dragonpunk Co Op');
		bHistoryLoaded = true;
		PlayingCoop=true;
		SendRemoteCommand("RecievedHistory");
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateMissionInfo();
		UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		listWidth =( UISS.GetTotalSlots()+(int(UISS.ShowExtraSlot1())*-2) )* (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
		listX =(UISS.Movie.GetUIResolution().X / 2) - (listWidth/2);
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(UISS.Movie.UI_RES_X / 2); //fixes the x position of the list on the screen
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation(); //fixes the x position of the list on the screen
		//RefreshDisplay();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).//RefreshDisplay(); //That's what getting everything updated for the player		SavedSquad=XComHQ.Squad;
		ServerSquad=XComHQ.Squad;
		ConnectionSetupActor.SavedSquad=XComHQ.Squad;
		ConnectionSetupActor.ServerSquad=XComHQ.Squad;		
		XComGameInfo(`XWORLDINFO.Game).LoadGame();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeItems();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OnReceiveFocus();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData(false);
		//SendRemoteCommand("ClientJoined");
	}
	else 
	{
		`log(`location @"Dragonpunk Recieved History",,'Team Dragonpunk Co Op');
		SendRemoteCommand("RecievedHistory");
		if(Launched)
			RevertInviteAcceptedDelegates();	
		Launched=true;
	}

	if(`XCOMNETMANAGER.HasClientConnection())
			UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.Hide();
	//NetManager.OnReceiveHistory(InHistory, EventManager);
	//m_kLocalPlayerInfo.InitPlayer(eTeam_Two, m_kSquadLoadout);
	//m_kRemotePlayerInfo.InitPlayer(eTeam_One);
	
}
function SendRemoteCommand(string Command) //Copied from UIMPShell_Lobby
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`XCOMNETMANAGER.SendRemoteCommand(Command, Parms);
	`log(`location @ "Sent Remote Command '"$Command$"'",,'Team Dragonpunk Co Op');
}

function bool SquadCheck(array<StateObjectReference> arrOne, array<StateObjectReference> arrTwo) // Checking if the 2 arrays of the references are the same. Used to check squads
{
	local int i,j;
	local array<bool> CheckArray;

	if(arrOne.Length!=arrTwo.Length) 
		return False;

	for(i=0;i<arrOne.Length;i++)
	{
		for(j=0;j<arrTwo.Length;j++)
		{
			if(arrOne[i]==arrTwo[j])
				CheckArray.AddItem(true);
		}
	}
	if(CheckArray.Length==arrOne.Length)
		return true;

	return false;
}

function bool PerSoldierSquadCheck(XComGameState InGS) // Checks if the units inside the input game state are different to the latest history state in the game.
{
	local int i;
	local XComGameState_Unit Unit,UnitPrev;

	for(i=0;i<InGS.GetNumGameStateObjects();i++)
	{
		Unit=XComGameState_Unit(InGS.GetGameStateForObjectIndex(i));
		if(Unit!=none)
		{
			UnitPrev=XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID,,InGS.HistoryIndex - 1));
			if(UnitPrev !=none)
			{
				if(UnitPrev!=Unit)
					return false;
			}
		}
	}
	return true;
}

function ReceiveMergeGameState(XComGameState InGameState) //Used when getting the unit changes in co-op
{
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef; 
	local float listWidth,listX;
	local UISquadSelect UISS;
	`log(`location @"Recieved Merge GameState",,'Team Dragonpunk Co Op');
	//SendRemoteCommand("HistoryRegisteredConfirmed");
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	foreach XComHQ.Squad(UnitRef)
	{
		`log("Unit in squad ReceiveMergeGameState:"@XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).GetFullName(),,'Team Dragonpunk Co Op');
	}
	//`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_SquadWatcher);
	if(!SquadCheck(XComHQ.Squad,SavedSquad) ||!PerSoldierSquadCheck(InGameState)) //Check if we have any changes. Without checking you'll get a T-pose on the units and the UI becomes unresponsive.
	{
		`log("SquadCheck"@SquadCheck(XComHQ.Squad,SavedSquad) @"PerSoldierSquadCheck:"@PerSoldierSquadCheck(InGameState));
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateMissionInfo();
		UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		listWidth =( UISS.GetTotalSlots()+(int(UISS.ShowExtraSlot1())*-2) )* (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
		listX =(UISS.Movie.GetUIResolution().X / 2) - (listWidth/2);
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(UISS.Movie.UI_RES_X / 2); //fixes the x position of the list on the screen
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation(); //fixes the x position of the list on the screen
		//RefreshDisplay();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).//RefreshDisplay(); //That's what getting everything updated for the player
		GetNewSquadChanges(SavedSquad,XComHQ.Squad);
		SavedSquad=XComHQ.Squad;
		ConnectionSetupActor.ServerSquad=ServerSquad;
		ConnectionSetupActor.ClientSquad=ClientSquad;
		ConnectionSetupActor.TotalSquad=SavedSquad;
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData(false);
		ConnectionSetupActor.SentRemoteSquadCommand();
		//CalcAllPlayersReady();
	}
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.OnClickedDelegate=ConnectionSetupActor.LoadTacticalMapDelegate;
	
}

simulated function RefreshDisplay()
{
	local int SlotIndex, SquadIndex;
	local UISquadSelect_ListItem ListItem; 
	local UISquadSelect SS; 
	
	SS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));

	for( SlotIndex = 0; SlotIndex < `XComHQ.Squad.Length; ++SlotIndex )
	{
		SquadIndex =SS.SlotListOrder[SlotIndex];

		// The slot list may contain more information/slots than available soldiers, so skip if we're reading outside the current soldier availability. 
		if( SquadIndex >= SS.SoldierSlotCount )
			continue;

		//We want the slots to match the visual order of the pawns in the slot list. 
		ListItem = UISquadSelect_ListItem(SS.m_kSlotList.GetItem(SlotIndex));
		ListItem.UpdateData(SquadIndex);
	}
}

function GetNewSquadChanges(array<StateObjectReference> AOldSquad, array<StateObjectReference> ANewSquad)
{
	local int i,j;
	local bool Found;
	local StateObjectReference TempRef;
	local array<StateObjectReference> OldSquad,NewSquad;
	
	OldSquad=AOldSquad;
	NewSquad=ANewSquad;
	foreach OldSquad(TempRef)
	{
		if(TempRef.ObjectID==0)
			OldSquad.RemoveItem(TempRef);
	}
	foreach NewSquad(TempRef)
	{
		if(TempRef.ObjectID==0)
			NewSquad.RemoveItem(TempRef);
	}
	if(OldSquad.length==NewSquad.Length)
		return;
	else if(OldSquad.Length>NewSquad.Length)
	{
		
		for(i=0;i<OldSquad.Length;i++)
		{
			Found=false;
			for(j=0;j<NewSquad.Length;j++)
			{
				if(OldSquad[i]==NewSquad[j])
					Found=true;
			}
			if(!Found)
			{
				if(`XCOMNETMANAGER.HasServerConnection())
					ClientSquad.RemoveItem(OldSquad[i]);
				else if(`XCOMNETMANAGER.HasClientConnection())
					ServerSquad.RemoveItem(OldSquad[i]);
			}
		}
	}
	else
	{
		for(i=0;i<NewSquad.Length;i++)
		{
			Found=false;
			for(j=0;j<OldSquad.Length;j++)
			{
				if(NewSquad[i].ObjectID==OldSquad[j].ObjectID)
					Found=true;
			}
			if(!Found)
			{
				if(`XCOMNETMANAGER.HasServerConnection())
					ClientSquad.AddItem(NewSquad[i]);
				else if(`XCOMNETMANAGER.HasClientConnection())
					ServerSquad.AddItem(NewSquad[i]);
			}
		}	
	}
			
}
// `XCOMNETMANAGER.HasClientConnection()  `XCOMNETMANAGER.HasServerConnection()
defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}

