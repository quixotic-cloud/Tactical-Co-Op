// This is an Unreal Script
                           
class X2_Actor_InviteButtonManager extends Actor;

var array<UIButton> AllInviteButtons;
var array<UITextContainer>	AllInviteText;
var float			TimeCounter;


function SetAllElements(array<UIButton> Buttons,array<UITextContainer> AllText)
{
	AllInviteButtons=Buttons;
	AllInviteText=AllText;
}
simulated event Destroyed()
{
	local UIButton BT;
	`log("Destroyed InviteButtonManager");
	//MPClearLobbyDelegates();
	foreach AllInviteButtons(BT)
	{
		BT.Hide();
		BT.Remove();
	}
	AllInviteButtons.Length=0;	
	AllInviteText.Length=0;	
}
event Tick(float deltaTime)
{
	local UISquadSelect MySSS;
	local int i,Count;
	local UIButton MyInvite,MySelect;
	MySSS=UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect'));
	if(MySSS!=none)
	{
		Count=MySSS.m_kSlotList.ItemCount;
		TimeCounter+=1;
		//`log("Tried Changing Size");
		if(TimeCounter%5==4)
		{
			for(i=0;i<Count;i++)
			{
				MyInvite=none;
				MySelect=none;
				if(UISquadSelect_ListItem(MySSS.m_kSlotList.GetItem(i)).GetUnitRef().ObjectId>0 || UISquadSelect_ListItem(MySSS.m_kSlotList.GetItem(i)).bDisabled)
				{	
					//MySSS.m_kSlotList.GetItem(i).SetAlpha(0.75);
					UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('SelectPlayer')).Hide();
					UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('InvitePlayer')).Hide();
					MySelect=UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('SelectPlayer'));
					MyInvite=UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('InvitePlayer'));
					UITextContainer(MySelect.GetChildAt(0)).Hide();
					UITextContainer(MyInvite.GetChildAt(0)).Hide();
				}
				else
				{
					//MySSS.m_kSlotList.GetItem(i).SetAlpha(0);
					UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('SelectPlayer')).Show();
					UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('InvitePlayer')).Show();
					MySelect=UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('SelectPlayer'));
					MyInvite=UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('InvitePlayer'));
					UITextContainer(MySelect.GetChildAt(0)).Show();
					UITextContainer(MyInvite.GetChildAt(0)).Show();
				}
			}
			TimeCounter=0;
		}
	}
}
