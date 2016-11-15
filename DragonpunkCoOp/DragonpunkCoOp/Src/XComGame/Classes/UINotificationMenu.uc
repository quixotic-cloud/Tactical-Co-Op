//---------------------------------------------------------------------------------------
//  FILE:    UINotificationMenu.uc
//  AUTHOR:  Jake Akemann - 10/27/15
//  PURPOSE: Menu to display the notifications that is navigable by a console controller
//---------------------------------------------------------------------------------------

class UINotificationMenu extends UIScreen;

//----------------------------------------------------------------------------
// MEMBERS

//using the UIToDoWidget to grab all of the data (instead of re-creating all of that logic here)
var privatewrite UIToDoWidget Notices;

//class-specific members
var privatewrite array<int>		m_aCategoryRefIndex; //array of indices of the Categories array, found in UIToDoWidget
var privatewrite UINavigationHelp NavHelp;

var localized string		m_sNotificationHeader;
var localized string		m_sNotificationLabel;
var localized string		m_sNotificationEmpty;
var localized string		m_sGoTo;

//Instances on the .fla stage
var privatewrite UIList		List;
var privatewrite UIList		TabList;
var privatewrite UIX2PanelHeader	Header;

//const values compiled from values on the .FLA stage (see default properties)
var const int xOffsetTooltips;
var const int yOffsetTooltips;

delegate MsgCallback(optional StateObjectReference Facility);

//----------------------------------------------------------------------------
// FUNCTIONS


simulated function UINotificationMenu InitNotificationMenu(UIToDoWidget ToDoWidget, XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	Notices = ToDoWidget;
	InitScreen(InitController, InitMovie, InitName);
	return self;
}

simulated function OnInit()
{
	super.OnInit();

	//initializes the tab list
	SetupTabList();

	//initializes the header (Uses tablist length to determine the labels)
	Header = Spawn(class'UIX2PanelHeader', self, 'mc_title');
	Header.InitPanelHeader('mc_title',m_sNotificationHeader, TabList.GetItemCount() > 0 ? m_sNotificationLabel : m_sNotificationEmpty);
	Header.SetWidth(800); //width must be set manually or text will not be visible
	Header.DisableNavigation();

	//initialize the data list
	List = Spawn(class'UIList', self, 'mc_list');
	List.InitList('mc_list');
	List.OnItemClicked=NoticeListIndexSelected;
	List.OnSelectionChanged=NoticeListIndexChanged;
	List.DisableNavigation(); //Prevent scrolling off the bottom of the TabList and ending up here -bet 2016-03-28

	//populates the data list with currently selected category index
	RefreshNotices();

	Navigator.SetSelected(TabList);

	//initializing navhelp
	NavHelp =`HQPRES.m_kAvengerHUD.NavHelp;
	UpdateNavHelp();
}

simulated function UpdateNavHelp()
{
	local string sNoticeNavHelp;

	NavHelp.ClearButtonHelp();	
	NavHelp.AddBackButton();

	//If empty, there is nothing to do, but back out
	if(TabList != None && TabList.ItemCount == 0)
		return;

	//If on the list of notification categories add a "Select" navhelp
	if(Navigator.GetSelected() == TabList)
		NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericSelect, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());

	//If on the list of notifications themselves, add a "Jump to facility" navhelp
	if(Navigator.GetSelected() == List)
	{
		//Checks to see if there was an assigned NavHelpLabel for the Notification
		sNoticeNavHelp = Notices.Categories[m_aCategoryRefIndex[TabList.SelectedIndex]].Messages[List.SelectedIndex].NavHelpLabel;
		//If there wasn't (returns an empty string), assign the default "Jump To Facility" NavHelp label
		if(sNoticeNavHelp == "")
			sNoticeNavHelp = m_sGoTo;
		NavHelp.AddLeftHelp(sNoticeNavHelp, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	}		
}

//Initial setup and data-populate
simulated function SetupTabList()
{
	local int i;
	local UIListItemString ListItem;
	//local UIIcon Icon;

	//initialize the tabs list
	TabList = Spawn(class'UIList', self, 'mc_tabList');
	TabList.InitList('mc_tabList');

	if(Notices != None)
	{
		for( i=0; i<Notices.Categories.Length; i++)
		{
			if( Notices.Categories[i].Messages.Length > 0 )
			{
				m_aCategoryRefIndex.AddItem(i);
				ListItem = Spawn(class'UIListItemString', TabList.ItemContainer).InitListItem(i < Notices.m_arrCategory_Labels.Length ? Notices.m_arrCategory_Labels[i] : "");
				ListItem.SetWidth(250);
				//puts the "needs attention" icon on the list item if any messages within have a 'high' urgency
				if( Notices.Categories[i].Messages.Find('Urgency', eUIToDoMsgUrgency_High) > -1 )
					ListItem.NeedsAttention(true);
			}
			
			//Icon Handling: Use this as a starting point if we want to get icons in the tab list
			//if(ListItem != None)
			//{
			//	Icon = Spawn(class'UIIcon', ListItem).InitIcon(Name("CatImage_" $ i),,,,ListItem.MC.GetNum("height"));
			//	if( Icon != None)
			//	{
			//		Icon.LoadIcon( class'UIUtilities_Image'.static.GetToDoWidgetImagePath(i) );
			//		Icon.SetForegroundColor( class'UIUtilities_Colors'.const.BLACK_HTML_COLOR );
			//		Icon.SetBGColorState( Notices.GetUrgencyColor(i) );
			//	}
			//}	
		}
	}

	if( TabList.GetItemCount() > 0 )
	{
		TabList.SetSelectedIndex(0);
		TabList.OnItemClicked = TabListIndexSelected;
		TabList.OnSelectionChanged = TabListIndexChanged;
	}
}

simulated function RefreshNotices()
{
	local int i;
	local UIListItemString ListItem;

	if( List != None )
	{
		List.ClearItems();
		for( i = 0; i < Notices.Categories[m_aCategoryRefIndex[TabList.SelectedIndex]].Messages.Length; i++ )
		{
			ListItem = Spawn(class'UIListItemString', List.ItemContainer).InitListItem( Notices.Categories[m_aCategoryRefIndex[TabList.SelectedIndex]].Messages[i].Label );
			ListItem.SetWidth(480);
			//puts the "needs attention" icon on the list item
			if(Notices.Categories[m_aCategoryRefIndex[TabList.SelectedIndex]].Messages[i].Urgency == eUIToDoMsgUrgency_High)
				ListItem.NeedsAttention(true);
			ListItem.SetTooltipText(Notices.Categories[m_aCategoryRefIndex[TabList.SelectedIndex]].Messages[i].Description,,,,false,class'UIUtilities'.const.ANCHOR_TOP_LEFT);
		}
		List.SetSelectedIndex(-1); //makes sure nothing is highlighted until focus is given to the list
	}
}

//----------------------------------------------------------------------------
// EVENT HANDLING

simulated function TabListIndexChanged(UIList ContainerList, int ItemIndex)
{
	RefreshNotices();
}

simulated function TabListIndexSelected(UIList ContainerList, int ItemIndex)
{
	List.EnableNavigation();
	List.SetSelectedIndex(0);
	Navigator.SetSelected(List);
	TabList.DisableNavigation();

	UpdateNavHelp();
}

simulated function NoticeListIndexChanged(UIList ContainerList, int ItemIndex)
{
	UpdateNavHelp();	
	SimulateMouseHover(true);
}

simulated function NoticeListIndexSelected(UIList ContainerList, int ItemIndex)
{
	local delegate<MsgCallback> MsgCallback; 

	MsgCallback = Notices.Categories[m_aCategoryRefIndex[TabList.SelectedIndex]].Messages[ItemIndex].OnItemClicked;
	if( MsgCallback != none )
	{
		MsgCallback(Notices.Categories[m_aCategoryRefIndex[TabList.SelectedIndex]].Messages[ItemIndex].HotLinkRef);
		CloseScreen();
	}		
}

simulated function bool SimulateMouseHover(bool bIsHovering)
{
	local UITooltipMgr Mgr;
	local UIListItemString ListItem;
	local UITextTooltip ListItemTooltip;

	Mgr = Movie.Pres.m_kTooltipMgr;

	ListItem = UIListItemString(List.GetSelectedItem());
	if(ListItem != None && Mgr != None)
	{		
		ListItemTooltip = UITextTooltip(Mgr.GetTooltipByID(ListItem.ButtonBG.CachedTooltipId));
		if(ListItemTooltip != None)
		{
			//sets tooltip position
			ListItemTooltip.SetFollowMouse(false);
			ListItemTooltip.SetTooltipPosition(xOffsetTooltips + ListItem.Width + 20, yOffsetTooltips + ListItem.Y); //20 is for padding

			//manually shows/hides the tooltip
			if(bIsHovering)
			{
				ListItemTooltip.HideTooltip(); //refreshes the tooltip (it uses the same asset)
				ListItemTooltip.Activate();
			}
			else
				ListItemTooltip.HideTooltip();
		}
	}
	return true;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
	// <workshop> ORBIS_DEFAULT_BUTTON adsmith 2016-03-28
	// WAS:
	//case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	// </workshop>
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		if(Navigator.GetSelected() == List)
		{
			TabList.EnableNavigation();
			Navigator.SetSelected(TabList);
			List.SetSelectedIndex(-1);
			UpdateNavHelp();
			List.DisableNavigation();
		}
		else
			CloseScreen();
		break;

	//Re-enabled the left/right directional navigation at the request of 2K -bet 2016-03-28
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		if(Navigator.GetSelected() == TabList)
			TabListIndexSelected(TabList,TabList.SelectedIndex);
		break;
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		if(Navigator.GetSelected() == List)
		{
			TabList.EnableNavigation();
			Navigator.SetSelected(TabList);
			SimulateMouseHover(false); //Must be called before the list's SelectedIndex is changed
			List.SetSelectedIndex(-1);
			UpdateNavHelp();			
			List.DisableNavigation();
		}			
		break;

	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	Package = "/ package/gfxnotifications/notifications"; //Unreal stomps the capitalization. Not awesome, but just make it work. -bsteiner 
	MCName = "mc_notifications";
	InputState = eInputState_Consume;
	bIsNavigable = true;
	xOffsetTooltips = 831;//(541 + 290) widget.X + list.X - found on the .FLA stage
	yOffsetTooltips = 281;//(197 + 84)  widget.Y + list.Y - found on the .FLA stage
}
