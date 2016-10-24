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
var array<StateObjectReference> SavedSquad;
var array<StateObjectReference> ServerSquad,ClientSquad;
var bool Launched;
event OnInit(UIScreen Screen)
{
	if(Screen.isA('UISquadSelect'))
		OnReceiveFocus(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	local UISquadSelect SSS;
	local int i,Count;
	local float listWidth,listX;
	local UISquadSelect UISS;
	
	if(Screen.isA('UISquadSelect'))
	{
		
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
		UISquadSelect(Screen).LaunchButton.AnchorTopCenter();
		XComCheatManager(UISquadSelect(Screen).GetALocalPlayerController().CheatManager).UnsuppressMP(); //Unsuppress log types
		SSS=UISquadSelect(Screen);
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
		listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);	
		listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
		UISquadSelect(Screen).m_kSlotList.SetX(listX); //change the list X-position to the right place.
		if(UIDialogueBox(UISquadSelect(Screen).Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).ShowingDialog())
			UIDialogueBox(UISquadSelect(Screen).Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).RemoveDialog();
		if(`XCOMNETMANAGER.HasClientConnection())
			UISquadSelect(Screen).LaunchButton.Hide();

	}
	else if(Screen.isA('UIDialogueBox'))
	{
		if(UIDialogueBox(Screen).ShowingDialog())
			UIDialogueBox(Screen).RemoveDialog();				
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
//	`XCOMNETMANAGER.Disconnect();
//	`XCOMNETMANAGER.ResetConnectionData();
  	ClientSquad.Length=0;
	ServerSquad.Length=0;
	SavedSquad=XComHQ.Squad;
	ServerSquad=XComHQ.Squad;
	ConnectionSetupActor.SavedSquad=XComHQ.Squad;
	ConnectionSetupActor.ServerSquad=XComHQ.Squad;
	ConnectionSetupActor.CreateOnlineGame();
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


	if(!bHistoryLoaded)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		`log(`location,,'XCom_Online');
		`log(`location @"Dragonpunk Recieved History",,'Team Dragonpunk Co Op');
		bHistoryLoaded = true;
		SendRemoteCommand("RecievedHistory");
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateMissionInfo();
		UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
		listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(listX); //fixes the x position of the list on the screen
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).RefreshDisplay(); //That's what getting everything updated for the player		SavedSquad=XComHQ.Squad;
		ServerSquad=XComHQ.Squad;
		ConnectionSetupActor.SavedSquad=XComHQ.Squad;
		ConnectionSetupActor.ServerSquad=XComHQ.Squad;		
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
		listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
		listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(listX); //fixes the x position of the list on the screen
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).RefreshDisplay(); //That's what getting everything updated for the player
		GetNewSquadChanges(SavedSquad,XComHQ.Squad);
		SavedSquad=XComHQ.Squad;
		ConnectionSetupActor.ServerSquad=ServerSquad;
		ConnectionSetupActor.ClientSquad=ClientSquad;
		ConnectionSetupActor.TotalSquad=SavedSquad;
		ConnectionSetupActor.SentRemoteSquadCommand();
		//CalcAllPlayersReady();
	}
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.OnClickedDelegate=ConnectionSetupActor.LoadTacticalMapDelegate;
	
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

