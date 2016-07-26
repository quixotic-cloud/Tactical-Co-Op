// This is an Unreal Script
                           
class UI_Listener_SquadSelect extends UIScreenListener;
var array<UIButton> AllButtons;
var array<UITextContainer> AllText;
var X2_Actor_InviteButtonManager IBM;
var bool Once;
var XComCo_Op_ConnectionSetup ConnectionSetupActor;
event OnInit(UIScreen Screen)
{
	OnReceiveFocus(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	local UISquadSelect SSS;
	local int i,Count;

	if(!once)
	{
		ConnectionSetupActor=Screen.Spawn(class'XComCo_Op_ConnectionSetup').InitConnectionSetup("",'XComOnlineCoOpGame_TeamDragonpunk');
		Once=true;
	}
	if(ConnectionSetupActor==none)
		Once=false;

	IBM=Screen.Spawn(class'X2_Actor_InviteButtonManager');
	AllButtons.Length=0;
	AllText.Length=0;
	if(Screen.isA('UISquadSelect'))
	{
		//`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
		//`ONLINEEVENTMGR.AddGameInviteCompleteDelegate(OnGameInviteComplete);
		XComCheatManager(UISquadSelect(Screen).GetALocalPlayerController().CheatManager).UnsuppressMP();
		SSS=UISquadSelect(Screen);
		Count=SSS.m_kSlotList.ItemCount;
		//`log("Tried Changing Size");
		for(i=0;i<Count*2;i++)
		{
			if(i%2==0)
				AllButtons[i] = SSS.Spawn(class'UIButton', SSS.m_kSlotList.GetItem(i/2));
			else
				AllButtons[i] = SSS.Spawn(class'UIButton', SSS.m_kSlotList.GetItem((i-1)/2));

			AllButtons[i].SetResizeToText(false);
			if(i%2==0)	
				AllButtons[i].InitButton('SelectPlayer',/*"<p> </p><p>INVITE FRIEND</p>"*/,OnSelectSoldier,eUIButtonStyle_BUTTON_WHEN_MOUSE);
			else		
				AllButtons[i].InitButton('InvitePlayer',/*"<p> </p><p>INVITE FRIEND</p>"*/,OnInviteFriend,eUIButtonStyle_BUTTON_WHEN_MOUSE);
			AllButtons[i].SetTextAlign("center");
			AllButtons[i].SetFontSize(24);
			AllButtons[i].SetHeight(79+35);
			AllButtons[i].SetWidth(282);
			//AllButtons[i].AnchorTopLeft();	
			if(i%2==0)	
				AllButtons[i].SetY((79+35)*0.75);	
			else		
				AllButtons[i].SetY((79+35)*1.75);	
			//AllButtons[i].AS_SetEmpty("INVITE FRIEND");
			if(i%2==0)	
				AllText[i]= SSS.Spawn(class'UITextContainer',AllButtons[i]).InitTextContainer('InvitePlayerText',class'UIUtilities_Text'.static.GetSizedText("SELECT SOLDIER",24),AllButtons[i].Width/6,AllButtons[i].Height*1/3,AllButtons[i].Width,AllButtons[i].Height); //play with the third and forth parameters for adjusting X,Y accordingly!
			else		
				AllText[i]= SSS.Spawn(class'UITextContainer',AllButtons[i]).InitTextContainer('InvitePlayerText',class'UIUtilities_Text'.static.GetSizedText("INVITE FRIEND",24),AllButtons[i].Width/5,AllButtons[i].Height*1/3,AllButtons[i].Width,AllButtons[i].Height);  //play with the third and forth parameters for adjusting X,Y accordingly!
			AllText[i].RealizeTextSize();
			//AllText[i].SetText("INVITE FRIEND");
			//AllText[i].SetHeight(AllButtons[i].Height);
			//AllText[i].SetWidth(AllButtons[i].Width);
			AllText[i].Show();
			AllButtons[i].Show();
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
	Class'Engine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('XComOnlineCoOpGame_TeamDragonpunk');
	OnInviteButtonClicked();
}
simulated function OnSelectSoldier(UIButton button)
{
	UISquadSelect_ListItem(button.ParentPanel).OnClickedSelectUnitButton();
	`log("Selected Soldier!",true,'Team Dragonpunk');
}

function OnInviteButtonClicked()
{
	local OnlineSubsystem onlineSub;
	local int LocalUserNum;

	onlineSub = `ONLINEEVENTMGR.OnlineSub;
	`assert(onlineSub != none);

	LocalUserNum = `ONLINEEVENTMGR.LocalUserIndex;
	onlineSub.PlayerInterfaceEx.ShowInviteUI(LocalUserNum);
	ConnectionSetupActor.OSSCreateCoOpOnlineGame();
}

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}