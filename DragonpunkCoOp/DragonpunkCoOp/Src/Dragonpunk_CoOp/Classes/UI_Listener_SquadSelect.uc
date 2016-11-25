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
				
		if (ConnectionSetupActor != none) // If we're at the end of the mission kill the connection actor so it wont crash the game
		{
			ConnectionSetupActor.Destroy();
			ConnectionSetupActor=none;
		}
	}
	else if(PlayingCoop && Screen.IsA('UITacticalHUD')) // Extends timers so the games dosnt end prematurely
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

/*
 * Cleans up buttons and text containers that make the invite buttons
 */
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


/*
 * Where most of the magic happens, creates invite button manager, connection actors and registering delegates.
 */
event OnReceiveFocus(UIScreen Screen)
{
	local UISquadSelect SSS;
	local int i,Count;
	local float listWidth,listX;
	local UISquadSelect UISS;
	if(Screen.isA('UISquadSelect')) // This will catch overrides/child-classes of the UISquadSelect Screen as well as the base class.
	{
		UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		listWidth =( UISS.GetTotalSlots()+(int(UISS.ShowExtraSlot1())*-2) )* (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING); //No longer in use.
		listX =(UISS.Movie.GetUIResolution().X / 2) - (listWidth/2); //No longer in use.
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(0); //fixes the x position of the list on the screen
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation();
		if(ConnectionSetupActor==none)
			Once=false;

		if(!once)
		{
			`XCOMNETMANAGER.AddReceiveHistoryDelegate(ReceiveHistory); // Make sure we know where to go when getting history from server
			`XCOMNETMANAGER.AddReceiveMergeGameStateDelegate(ReceiveMergeGameState); // Make sure we know where to go when getting game states from server
			ConnectionSetupActor=Screen.Spawn(class'XComCo_Op_ConnectionSetup',none); // Spawn the connection actor that deals with everything about the connection to the other players
			ConnectionSetupActor.ChangeInviteAcceptedDelegates(); // Apply the new delegates and change the online event manager delegates to the stuff we want to activate.
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
		/*else 
		{
			//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.AnchorTopCenter();
		}*/
		
	}
	else if(Screen.isA('UIDialogueBox')) // If we are on a dialog make sure to remove it, closes remaining dialog boxes.
	{
		if(UIDialogueBox(Screen).ShowingDialog())
			UIDialogueBox(Screen).RemoveDialog();				
	}
	
}

/*
* Changes the mission timers to be 3x as long so missions last as long as they should be
* Taken mostly from the "Configureable Mission Timers" mod from wasteland_ghost																						
*/
function SetTimersStart()
{
	local SeqVar_Int TimerVariable;
	local WorldInfo wInfo;
	local Sequence mainSequence;
	local array<SequenceObject> SeqObjs;
	local int i,k;
	wInfo = `XWORLDINFO;
	mainSequence = wInfo.GetGameSequence(); // Find the main game sequence where all kismet objects live
	if (mainSequence != None)
	{
		`Log("Game sequence found: " $ mainSequence);
		mainSequence.FindSeqObjectsByClass( class'SequenceVariable', true, SeqObjs); // Get all the SequenceVariables and loop over them for a search
		if(SeqObjs.Length != 0)
		{
			`Log("Kismet variables found");
			for(i = 0; i < SeqObjs.Length; i++)
			{
				if(InStr(string(SequenceVariable(SeqObjs[i]).VarName), "DefaultTurns") != -1) // Find the Object called "DefaultTurns" and change it to be 3x as big.
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


/*
* This event is triggered when a screen is removed
*/
event OnRemoved(UIScreen Screen)
{
	if(Screen.isA('UISquadSelect')) //Kill the IBM actor when the squad select screen is exited
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
 

/*
* When the player clicks the "Invite Friend" button this delegate fires up
* Makes sure all the delegates are correctly set up, destroys all other online games if it exists
* Initializes all the squads for tracking who controls which soldier and notifies the connection actor to create the game                                                                                                                                                                         
*/
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
	SavedSquad=XComHQ.Squad; // Save the squad you currently have to check for control
	ServerSquad=XComHQ.Squad; // Save the squad you currently have to check for control
	ConnectionSetupActor.SavedSquad=XComHQ.Squad; // Save the squad you currently have to check for control
	ConnectionSetupActor.ServerSquad=XComHQ.Squad; // Save the squad you currently have to check for control
	ConnectionSetupActor.CreateOnlineGame();
	PlayingCoop=true;
}

function OnNotifyConnectionClosed(int ConnectionIdx)
{
	`log("On Connection Closed!");
	`XCOMNETMANAGER.ClearNotifyConnectionClosedDelegate(OnNotifyConnectionClosed);
}


/*
* Makes sure the new "Select Soldier" button created by the mods' button manager get's hooked up to the default functionallity.  
*/
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

/*
* When Receiving history this delegate fires, it has multiple uses-
* On the first time the client recieves history it makes sure to init all the important things and update the data to make the new squad appear
* From there onwards it just fills in the spot to make sure we are getting the history correctly when we are getting the history to transfer to tactical                                                                                                                                                                                                                  
*/
function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	local float listWidth,listX;
	local XComGameState_HeadquartersXCom XComHQ;
	local UISquadSelect UISS;
	local XComGameState FullGameState;

	if(!bHistoryLoaded)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom')); // get the new HQ
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
		ServerSquad=XComHQ.Squad; // Save the squads we need to know that for the tactical game
		ConnectionSetupActor.SavedSquad=XComHQ.Squad; //saving squads
		ConnectionSetupActor.ServerSquad=XComHQ.Squad;//saving squads	
		XComGameInfo(`XWORLDINFO.Game).LoadGame(); //Using this will load the visualizers and ensure we dont get weird crashes from visualizer init bugs
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeItems();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OnReceiveFocus();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData(false); // Reloads he soldiers, fixes the ghost soldier bug
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
 
/*
* Copied from UIMPShell_Lobby  
*/
function SendRemoteCommand(string Command) 
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`XCOMNETMANAGER.SendRemoteCommand(Command, Parms);
	`log(`location @ "Sent Remote Command '"$Command$"'",,'Team Dragonpunk Co Op');
}

/*
* Checking if the 2 arrays of the references are the same. Used to check squads
*/
function bool SquadCheck(array<StateObjectReference> arrOne, array<StateObjectReference> arrTwo) 
{
	local int i,j;
	local array<bool> CheckArray;

	if(arrOne.Length!=arrTwo.Length) 
		return False;

	for(i=0;i<arrOne.Length;i++) //Loop galore! n^2 is fine when squads are rarely over 12 people
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
 
/*
* Checks if the units inside the input game state are different to the latest history state in the game.
*/
function bool PerSoldierSquadCheck(XComGameState InGS) 
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

/*
* Used when getting the unit changes in co-op, updates all the units and control lists.
*/
function ReceiveMergeGameState(XComGameState InGameState) 
{
 	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef; 
	local float listWidth,listX;
	local UISquadSelect UISS;
	`log(`location @"Recieved Merge GameState",,'Team Dragonpunk Co Op');
	//SendRemoteCommand("HistoryRegisteredConfirmed");
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom')); //Update the HQ, will ensure the squads are updated.
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
		GetNewSquadChanges(SavedSquad,XComHQ.Squad);
		SavedSquad=XComHQ.Squad; // Save the squad again
		ConnectionSetupActor.ServerSquad=ServerSquad; // damn....code commenting is boring, now i remember why i didnt do it in the first place...
		ConnectionSetupActor.ClientSquad=ClientSquad;
		ConnectionSetupActor.TotalSquad=SavedSquad;
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData(false);
		ConnectionSetupActor.SentRemoteSquadCommand();
		//CalcAllPlayersReady();
	}
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.OnClickedDelegate=ConnectionSetupActor.LoadTacticalMapDelegate;
	
}
 

/*
* syncs up changes in the new squad relative to the old one.
*/
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

