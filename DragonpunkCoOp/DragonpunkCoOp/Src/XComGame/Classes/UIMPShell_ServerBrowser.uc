//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_ServerBrowser.uc
//  AUTHOR:  Todd Smith  --  6/25/2015
//  PURPOSE: Shows lists of servers hosting games
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_ServerBrowser extends UIMPShell_Base;

var localized string m_strServerBrowserHeaderText;
var localized string m_strGamertagText;
var localized string m_strMapTypeText;
var localized string m_strPingText;
var localized string m_strArmySizeText;
var localized string m_strTurnTimerText;
var localized string m_strRefreshListButtonText;
var localized string m_strJoinGameButtonText;

var TServerBrowserData m_kServerBrowserData;
var int m_iOnlineGameSearchResultIndex;

enum EServerBrowserSortType
{
	eServerBrowserSortType_Name,
	eServerBrowserSortType_SquadSize,
	eServerBrowserSortType_TurnTimer,
	eServerBrowserSortType_MapType,
	eServerBrowserSortType_Ping,
};

// these are set in UIFacilitySummary_HeaderButton
var bool m_bFlipSort;
var EServerBrowserSortType m_eSortType;

var UIPanel       m_kHeader;
var UIPanel       m_kContainer; // contains all controls bellow
var UIList  m_kList;
var UIBGBox  m_kListBG;
var UIX2PanelHeader  m_kTitle;

var UINavigationHelp m_NavHelp;

var array<UIServerBrowser_HeaderButton> m_arrHeaderTabs;
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	m_kContainer = Spawn(class'UIPanel', self).InitPanel();
	m_kContainer.SetPosition(300, 85);
	
	// add BG
	m_kListBG = Spawn(class'UIBGBox', m_kContainer);
	m_kListBG.InitPanel('', class'UIUtilities_Controls'.const.MC_X2Background).SetSize(1310, 940);

	m_kTitle = Spawn(class'UIX2PanelHeader', self).InitPanelHeader('', m_strServerBrowserHeaderText);
	m_kTitle.SetPosition(20, 20);

	m_kList = Spawn(class'UIList', m_kContainer).InitList('', 15, 60, 1265, 810);
	m_kList.OnItemDoubleClicked = ServerListItemDoubleClicked;
	m_kList.OnItemClicked = ServerListItemClicked;

	// allows list to scroll when mouse is touching the BG
	m_kListBG.ProcessMouseEvents(m_kList.OnChildMouseEvent);

	m_eSortType = eServerBrowserSortType_SquadSize;

	m_kHeader = Spawn(class'UIPanel', self).InitPanel('', 'ServerHeader');


	m_arrHeaderTabs.AddItem(Spawn(class'UIServerBrowser_HeaderButton', m_kHeader).InitHeaderButton("gamertag", eServerBrowserSortType_Name, m_strGamertagText));
	m_arrHeaderTabs.AddItem(Spawn(class'UIServerBrowser_HeaderButton', m_kHeader).InitHeaderButton("squad", eServerBrowserSortType_SquadSize, m_strArmySizeText));
	m_arrHeaderTabs.AddItem(Spawn(class'UIServerBrowser_HeaderButton', m_kHeader).InitHeaderButton("turns", eServerBrowserSortType_TurnTimer, m_strTurnTimerText));
	m_arrHeaderTabs.AddItem(Spawn(class'UIServerBrowser_HeaderButton', m_kHeader).InitHeaderButton("map", eServerBrowserSortType_MapType, m_strMapTypeText));
	m_arrHeaderTabs.AddItem(Spawn(class'UIServerBrowser_HeaderButton', m_kHeader).InitHeaderButton("ping", eServerBrowserSortType_Ping, m_strPingText));
	Navigator.Clear();
	Navigator.AddControl(m_kList);
	
	m_NavHelp = Movie.Pres.GetNavHelp();
	UpdateNavHelp();
	
	SubscribeToOnCleanupWorld();
}

simulated function UpdateNavHelp()
{
	m_NavHelp.ClearButtonHelp();
	m_NavHelp.AddBackButton(BackButtonCallback);

	//m_NavHelp.AddRightHelp(m_strRefreshListButtonText, "", RefreshListButtonCallback);
	m_NavHelp.AddCenterHelp(m_strRefreshListButtonText, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, RefreshListButtonCallback);
	if(m_kList.GetItemCount() > 0)
	{
		if( `ISCONTROLLERACTIVE )
			m_NavHelp.AddCenterHelp(m_strJoinGameButtonText, class'UIUtilities_Input'.const.ICON_A_X, JoinGameButtonCallback);
		else
			m_NavHelp.AddRightHelp(m_strJoinGameButtonText, "", JoinGameButtonCallback);

	}
}
simulated function UpdateGamepadFocus()
{		
	if(m_kList != None && m_kList.ItemCount > 0)
	{		
		Navigator.SetSelected(m_kList);
		m_kList.SetSelectedIndex(m_kList.SelectedIndex > -1 ? m_kList.SelectedIndex : 0);
		UpdateNavHelp();
	}
}

//called from a delegate event when the list items are ready to take focus
simulated function OnFirstPanelInitialized(UIPanel Panel)
{
	UpdateGamepadFocus();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			RefreshListButtonCallback();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			ServerListItemDoubleClicked(m_kList,m_kList.SelectedIndex);
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

function BackButtonCallback()
{
	CloseScreen();
}

simulated function UpdateData()
{
	SortLeaderboards();

	UpdateServerBrowserList(m_kServerBrowserData);
}

function SortLeaderboards()
{
	switch(m_eSortType)
	{
	case eServerBrowserSortType_Name:       m_kServerBrowserData.arrServers.Sort(SortByName);           break;
	case eServerBrowserSortType_SquadSize:  m_kServerBrowserData.arrServers.Sort(SortBySquadSize);      break;
	case eServerBrowserSortType_TurnTimer:  m_kServerBrowserData.arrServers.Sort(SortByTurnTime);       break;
	case eServerBrowserSortType_MapType:    m_kServerBrowserData.arrServers.Sort(SortByMapType);        break;
	case eServerBrowserSortType_Ping:       m_kServerBrowserData.arrServers.Sort(SortByPing);          break;
	}
}

simulated function int SortByName(TServerInfo A, TServerInfo B)
{
	local string NameA, NameB;

	NameA = A.strHost;
	NameB = B.strHost;

	if(NameA < NameB) return m_bFlipSort ? -1 : 1;
	else if(NameA > NameB) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortBySquadSize(TServerInfo A, TServerInfo B)
{
	if(A.strPoints < B.strPoints) return m_bFlipSort ? -1 : 1;
	else if(A.strPoints > B.strPoints) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByTurnTime(TServerInfo A, TServerInfo B)
{
	if(A.strTurnTime < B.strTurnTime) return m_bFlipSort ? -1 : 1;
	else if(A.strTurnTime > B.strTurnTime) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByMapType(TServerInfo A, TServerInfo B)
{
	if(A.strMapPlotType < B.strMapPlotType) return m_bFlipSort ? -1 : 1;
	else if(A.strMapPlotType > B.strMapPlotType) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByPing(TServerInfo A, TServerInfo B)
{
	if(A.iPing < B.iPing) return m_bFlipSort ? -1 : 1;
	else if(A.iPing > B.iPing) return m_bFlipSort ? 1 : -1;
	else return 0;
}

function InitServerBrowser(TServerBrowserData kServerBrowserData)
{
	m_kServerBrowserData = kServerBrowserData;
	UpdateServerBrowserList(m_kServerBrowserData);
}

function ServerListItemDoubleClicked(UIList listControl, int itemIndex)
{
	`log(self $ "::" $ GetFuncName() @ "itemIndex=" $ itemIndex,, 'uixcom_mp');
	m_iOnlineGameSearchResultIndex = UIServerBrowser_ListItem(listControl.GetItem(itemIndex)).metadataInt;
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	JoinGame();
}

function ServerListItemClicked(UIList listControl, int itemIndex)
{
	m_iOnlineGameSearchResultIndex = UIServerBrowser_ListItem(listControl.GetItem(itemIndex)).metadataInt;
}

function JoinGame()
{
	local int iPoints;
	if(m_iOnlineGameSearchResultIndex >= 0)
	{
		if(m_kServerBrowserData.arrServers[m_iOnlineGameSearchResultIndex].strPoints == class'X2MPData_Shell'.default.m_strMPCustomMatchInfinitePointsString)
			iPoints = -1;
		else
			iPoints = int(m_kServerBrowserData.arrServers[m_iOnlineGameSearchResultIndex].strPoints);
	
		m_kMPShellManager.OnlineGame_SetMaxSquadCost(iPoints);
		`SCREENSTACK.Push(Spawn(class'UIMPShell_SquadLoadoutList_CustomGameSearch', Movie.Pres));
		m_kMPShellManager.m_iServerBrowserJoinGameSearchResultsIndex = m_iOnlineGameSearchResultIndex;//OSSJoin(m_iOnlineGameSearchResultIndex);
	}
}

function RefreshListButtonCallback()
{
	m_kMPShellManager.AddSearchGamesCompleteDelegate(OnSearchGamesCompleteCallback);
	m_kMPShellManager.OnlineGame_SearchGame();
}

function JoinGameButtonCallback()
{
	JoinGame();
}

function OnSearchGamesCompleteCallback(const out TServerBrowserData kServerData, bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_kMPShellManager.ClearSearchGamesCompleteDelegate(OnSearchGamesCompleteCallback);
	if(bSuccess)
	{
		UpdateServerBrowserList(kServerData);
	}
}

function UpdateServerBrowserList(const out TServerBrowserData kServerData)
{
	local UIServerBrowser_ListItem kServerListItem;
	local TServerInfo kServerInfo;
	local int i;

	m_kServerBrowserData = kServerData;
	m_iOnlineGameSearchResultIndex = -1;
	m_kList.ClearItems();
	for(i = 0; i < m_kServerBrowserData.arrServers.Length; i++)
	{
		kServerInfo = m_kServerBrowserData.arrServers[i];
		if(i == 0)
		{
			m_iOnlineGameSearchResultIndex = kServerInfo.iOnlineGameSearchResultIndex;
		}
		kServerListItem = UIServerBrowser_ListItem(m_kList.CreateItem(class'UIServerBrowser_ListItem')).InitListItem();
		kServerListItem.metadataInt = kServerInfo.iOnlineGameSearchResultIndex;
		kServerListItem.UpdateData(kServerInfo);
		
		if( i == 0 )
		{
			//Will callback when the item is ready to take visual focus
			//TODO - should actually be set to the 'bg' variable if possible (which is the asset that has the visual highlight)
			kServerListItem.AddOnInitDelegate(OnFirstPanelInitialized);
		}
	}
}

defaultproperties
{
	m_iOnlineGameSearchResultIndex=-1
	Package   = "/ package/gfxFacilitySummary/FacilitySummary";
	InputState = eInputState_Consume;
}