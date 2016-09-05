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
var array<XComGameState_Unit> SavedSquad_Units;


event OnInit(UIScreen Screen)
{
	OnReceiveFocus(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	local UISquadSelect SSS;
	local int i,Count;
	local float listWidth,listX;
	local UISquadSelect UISS;

	if(!once)
	{
		`XCOMNETMANAGER.AddReceiveHistoryDelegate(ReceiveHistory);
		`XCOMNETMANAGER.AddReceiveMergeGameStateDelegate(ReceiveMergeGameState);
		ConnectionSetupActor=Screen.Spawn(class'XComCo_Op_ConnectionSetup',Screen);
		ConnectionSetupActor.ChangeInviteAcceptedDelegates();
		Once=true;
	}
	if(ConnectionSetupActor==none)
		Once=false;

	if(ConnectionSetupActor!=none)
	{
		ConnectionSetupActor.RevertInviteAcceptedDelegates();// Cleanup delegates before doing anything
		ConnectionSetupActor.ChangeInviteAcceptedDelegates();// Re-register for all delegates
	}
	IBM=Screen.Spawn(class'X2_Actor_InviteButtonManager');
	AllButtons.Length=0;
	AllText.Length=0;

	if(Screen.isA('UISquadSelect'))
	{
		//`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
		//`ONLINEEVENTMGR.AddGameInviteCompleteDelegate(OnGameInviteComplete);
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
			UISS=UISquadSelect(Screen);
			listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);	
			listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
			UISquadSelect(Screen).m_kSlotList.SetX(listX); //change the list X-position to the right place.
		}
	}
}

event OnLoseFocus(UIScreen Screen)
{
	IBM.Destroy();
	AllText.Length=0;
	AllButtons.Length=0;		
}
// This event is triggered when a screen is removed
event OnRemoved(UIScreen Screen)
{
	OnLoseFocus(Screen);
}

simulated function OnInviteFriend(UIButton button)
{
	`log("Invited Friend!",true,'Team Dragonpunk Soldiers of Fortune');
	Class'Engine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('Game');	//Destroy any lingering Online games
//	`XCOMNETMANAGER.Disconnect();
//	`XCOMNETMANAGER.ResetConnectionData();
	ConnectionSetupActor.CreateOnlineGame();
}
simulated function OnSelectSoldier(UIButton button)
{
	UISquadSelect_ListItem(button.ParentPanel).OnClickedSelectUnitButton(); //Turn to the stock soldier selection menu
	`log("Selected Soldier!",true,'Team Dragonpunk');
}


function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	local float listWidth,listX;
	local XComGameState_HeadquartersXCom XComHQ;
	local UISquadSelect UISS;
	local XComGameStateNetworkManager NetworkMgr;
	local StateObjectReference temp;
	if(!bHistoryLoaded)
	{
		NetworkMgr = `XCOMNETMANAGER;
		NetworkMgr.ClearReceiveHistoryDelegate(ReceiveHistory);
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		`log(`location,,'XCom_Online');
		`log(`location @"Dragonpunk Recieved History",,'Team Dragonpunk Co Op');
		bHistoryLoaded = true;
		Global.ReceiveHistory(InHistory, EventManager);
		SendRemoteCommand("RecievedHistory");
		UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
		listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(listX); //Fix the position of the list when getting history.
		SavedSquad_Units.Length=0;
		foreach XComHQ.Squad(temp)
		{
			SavedSquad_Units.AddItem(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(temp.ObjectID)));
		}
		//SendRemoteCommand("ClientJoined");
	}
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
	local StateObjectReference temp;
	local array<XComGameState_Unit> NewUnits;
	`log(`location @"Recieved Merge GameState",,'Team Dragonpunk Co Op');
	//SendRemoteCommand("HistoryRegisteredConfirmed");
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	foreach XComHQ.Squad(UnitRef)
	{
		`log("Unit in squad ReceiveMergeGameState:"@XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).GetFullName(),,'Team Dragonpunk Co Op');
	}
	//`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_SquadWatcher);
	foreach XComHQ.Squad(temp)
	{
		NewUnits.AddItem(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(temp.ObjectID)));
	}
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
		SavedSquad=XComHQ.Squad;
		SavedSquad_Units=NewUnits;
		//CalcAllPlayersReady();
		//UpdateButtons();
	}
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.OnClickedDelegate=ConnectionSetupActor.LoadTacticalMapDelegate;
	if(`XCOMNETMANAGER.HasClientConnection())
	{
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.Hide();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.SetDisabled(True);
	}
	else if(`XCOMNETMANAGER.HasServerConnection() || !`XCOMNETMANAGER.HasConnections())
{
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.Show();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.SetDisabled(False);
	}
}


defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}

