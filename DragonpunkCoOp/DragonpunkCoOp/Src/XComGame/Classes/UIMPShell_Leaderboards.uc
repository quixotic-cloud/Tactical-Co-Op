//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_Leaderboards.uc
//  AUTHOR:  Todd Smith  --  9/16/2015
//  PURPOSE: Screen that shows the leaderboards
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_Leaderboards extends UIMPShell_Base;

enum ELeaderboardSortType
{
	eLeaderboardSortType_Name,
	eLeaderboardSortType_Rank,
	eLeaderboardSortType_Wins,
	eLeaderboardSortType_Losses,
	eLeaderboardSortType_Disconnects,
	eLeaderboardSortType_SIZE

};

// these are set in UIFacilitySummary_HeaderButton
var bool m_bFlipSort;
var ELeaderboardSortType m_eSortType;
var EMPLeaderboardType   m_eLeaderboardType;
var ELeaderboardSortType m_eSortOrder[ELeaderboardSortType.eLeaderboardSortType_SIZE];
var array<UILeaderboard_HeaderButton> m_aHeaderButtons;
var int m_iCurrentlySelectedHeaderButton;

var int m_iTopPlayersRank;

var UIPanel             m_kHeader;
var UIPanel             m_kContainer; // contains all controls bellow
var UIList              m_kList;
var UIBGBox             m_kListBG;
var UIX2ScreenHeader    m_kScreenHeader; 

var UIButton PrevPageButton;

var UIButton TopPlayersButton;
var UIButton FriendsButton;
var UIButton YourRankButton;

var UIButton NextPageButton;

var bool            m_bMyRankTop;

var UINavigationHelp m_NavHelp;
var array<TLeaderboardEntry> m_LeaderboardsData;

var localized string            m_strToggleSortingButtonText;
var localized string            m_strLeaderboardHeaderText;
var localized string            m_strTopPlayersButtonText;
var localized string            m_strYourRankButtonText;
var localized string            m_strFriendRanksButtonText;
var localized string            m_strNameColumnText;
var localized string            m_strNameColumnText_Xbox;
var localized string            m_strRankColumnText;
var localized string            m_strPreviousPageText;
var localized string            m_strNextPageText;
var localized string            m_strWinsColumnText;
var localized string            m_strLossesColumnText;
var localized string            m_strDisconnectsColumnText;

simulated function string GetUsernameText()
{
	return m_strNameColumnText;
}
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UILeaderboard_HeaderButton headerButton;
	super.InitScreen(InitController, InitMovie, InitName);
	
	m_kContainer = Spawn(class'UIPanel', self).InitPanel();
	m_kContainer.SetPosition(300, 85);
	m_kContainer.bIsNavigable = false;
	
	//add a screen title
	m_kScreenHeader = Spawn(class'UIX2ScreenHeader', self);
	m_kScreenHeader.InitScreenHeader('LeaderboardHeader');
	m_kScreenHeader.AnchorTopLeft();
	m_kScreenHeader.bIsNavigable = false;

	// add BG
	m_kListBG = Spawn(class'UIBGBox', m_kContainer);
	m_kListBG.InitPanel('', class'UIUtilities_Controls'.const.MC_X2Background).SetSize(1310, 940);
	m_kListBG.bIsNavigable = false;

	m_kList = Spawn(class'UIList', m_kContainer).InitList('', 15, 60, 1265, 860);
	m_kList.bIsNavigable = false;

	// allows list to scroll when mouse is touching the BG
	m_kListBG.ProcessMouseEvents(m_kList.OnChildMouseEvent);

	m_eSortType = eLeaderboardSortType_Rank;

	m_kHeader = Spawn(class'UIPanel', self).InitPanel('', 'LeaderboardHeader');
	m_kHeader.bIsNavigable = false;

	headerButton = Spawn(class'UILeaderboard_HeaderButton', m_kHeader);
	headerButton.InitHeaderButton("rank", eLeaderboardSortType_Rank, m_strRankColumnText);
	m_aHeaderButtons.AddItem( headerButton );
	
	headerButton = Spawn(class'UILeaderboard_HeaderButton', m_kHeader);
	headerButton.InitHeaderButton("gamertag", eLeaderboardSortType_Name, GetUsernameText());
	m_aHeaderButtons.AddItem( headerButton );
	
	//Spawn(class'UILeaderboard_HeaderButton', m_kHeader).InitHeaderButton("wins", eLeaderboardSortType_Wins, m_strWinsColumnText);
	//Spawn(class'UILeaderboard_HeaderButton', m_kHeader).InitHeaderButton("losses", eLeaderboardSortType_Losses, m_strLossesColumnText);
	//Spawn(class'UILeaderboard_HeaderButton', m_kHeader).InitHeaderButton("disconnects", eLeaderboardSortType_Disconnects, m_strDisconnectsColumnText);

	headerButton = Spawn(class'UILeaderboard_HeaderButton', m_kHeader);
	headerButton.InitHeaderButton("wins", eLeaderboardSortType_Wins, m_strWinsColumnText);
	m_aHeaderButtons.AddItem( headerButton );

	headerButton = Spawn(class'UILeaderboard_HeaderButton', m_kHeader);
	headerButton.InitHeaderButton("losses", eLeaderboardSortType_Losses, m_strLossesColumnText);
	m_aHeaderButtons.AddItem( headerButton );

	headerButton = Spawn(class'UILeaderboard_HeaderButton', m_kHeader);
	headerButton.InitHeaderButton("disconnects", eLeaderboardSortType_Disconnects, m_strDisconnectsColumnText);
	m_aHeaderButtons.AddItem( headerButton );
	
	SubscribeToOnCleanupWorld();

	Navigator.Clear();

	
	PrevPageButton = Spawn(class'UIButton', self).InitButton('prevpage', m_strPreviousPageText, PreviousPageCallback);
	PrevPageButton.AnchorBottomCenter();
	PrevPageButton.SetPosition(-450, -40);

	TopPlayersButton = Spawn(class'UIButton', self).InitButton('topPlayers', m_strTopPlayersButtonText, TopPlayersButtonCallback);
	TopPlayersButton.AnchorBottomCenter();
	TopPlayersButton.SetPosition(-250, -40);

	YourRankButton = Spawn(class'UIButton', self).InitButton('yourRank', m_strYourRankButtonText, YourRankButtonCallback);
	YourRankButton.AnchorBottomCenter();
	YourRankButton.SetPosition(-50, -40);

	FriendsButton = Spawn(class'UIButton', self).InitButton('friendsButton', m_strFriendRanksButtonText, FriendRanksButtonCallback);
	FriendsButton.AnchorBottomCenter();
	FriendsButton.SetPosition(150, -40);
	
	NextPageButton  = Spawn(class'UIButton', self).InitButton('nextPage', m_strNextPageText, NextPageCallback);
	NextPageButton.AnchorBottomCenter();
	NextPageButton.SetPosition(350, -40);

	PrevPageButton.SetVisible(`ISCONTROLLERACTIVE == false);
	TopPlayersButton.SetVisible(`ISCONTROLLERACTIVE == false);
	YourRankButton.SetVisible(`ISCONTROLLERACTIVE == false);
	FriendsButton.SetVisible(`ISCONTROLLERACTIVE == false);
	NextPageButton.SetVisible(`ISCONTROLLERACTIVE == false);

	
	
	m_eSortOrder[0] = eLeaderboardSortType_Rank;
	m_eSortOrder[1] = eLeaderboardSortType_Name;
	m_eSortOrder[2] = eLeaderboardSortType_Wins;
	m_eSortOrder[3] = eLeaderboardSortType_Losses;
	m_eSortOrder[4] = eLeaderboardSortType_Disconnects;

	m_iCurrentlySelectedHeaderButton = 0;
}

simulated function UpdateNavHelp()
{	
	m_NavHelp.ClearButtonHelp();
	m_NavHelp.AddBackButton(BackButtonCallback);

	UpdateNavButtons();
}

simulated function UpdateNavButtons()
{
	if( `ISCONTROLLERACTIVE )
	{
		//MODIFIED FOR XBOX USE OF 'GAMERCARD' - JTA 2016/4/8
		//INS:
		m_NavHelp.AddCenterHelp(m_strToggleSortingButtonText, class'UIUtilities_Input'.const.ICON_X_SQUARE);

		//Only display the "Top Players" button if we're not displaying that leaderboard.
		if(m_eLeaderboardType != eMPLeaderboard_TopPlayers)
			m_NavHelp.AddCenterHelp(m_strTopPlayersButtonText, class'UIUtilities_Input'.const.ICON_LT_L2);

		//Only display the "Your Rank" button if we're not displaying that leaderboard.
		if(m_eLeaderboardType != eMPLeaderboard_YourRank)
			m_NavHelp.AddCenterHelp(m_strYourRankButtonText, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);

		//Only display the "Friend Ranks" button if we're not displaying that leaderboard.
		if(m_eLeaderboardType != eMPLeaderboard_Friends)
			m_NavHelp.AddCenterHelp(m_strFriendRanksButtonText, class'UIUtilities_Input'.const.ICON_RT_R2);

		//CONSOLE_INPUT RJM 2016/03/04; JTA 2016/6/6
		if(m_eLeaderboardType == eMPLeaderboard_TopPlayers)
		{
			if(m_iTopPlayersRank > 1)
			{
				m_NavHelp.AddCenterHelp(m_strPreviousPageText, class'UIUtilities_Input'.const.ICON_LB_L1);
			}
			m_NavHelp.AddCenterHelp(m_strNextPageText, class'UIUtilities_Input'.const.ICON_RB_R1);
		}
	}
	else
	{
		PrevPageButton.SetDisabled(m_eLeaderboardType != eMPLeaderboard_TopPlayers);
		NextPageButton.SetDisabled(m_eLeaderboardType != eMPLeaderboard_TopPlayers);

		if(m_eLeaderboardType == eMPLeaderboard_TopPlayers)
		{
			PrevPageButton.Show();
		}

		TopPlayersButton.Show();
		YourRankButton.Show();
		FriendsButton.Show();

		if(m_eLeaderboardType == eMPLeaderboard_TopPlayers)
		{
			NextPageButton.Show();
		}
	}
}

simulated function OnInit()
{
	super.OnInit();
	
	m_NavHelp = m_kMPShellManager.NavHelp;
	if( `ISCONTROLLERACTIVE ) UpdateNavHelp();

	m_kMPShellManager.CancelLeaderboardsFetch();
	m_kMPShellManager.AddLeaderboardFetchCompleteDelegate(OnLeaderBoardFetchComplete);
	TopPlayersButtonCallback(TopPlayersButton);
	if( `ISCONTROLLERACTIVE ) 
		m_NavHelp.SetCenterHelpPaddingValue(m_NavHelp.CENTER_HELP_CONTAINER_PADDING - 10);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int previousSelectedIndex;
	local bool bHandled;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:

		//here we change the sort type.
		//we also change our index
		previousSelectedIndex = m_iCurrentlySelectedHeaderButton;
		if(m_bFlipSort)
		{	
			m_iCurrentlySelectedHeaderButton++;
			m_eSortType = m_eSortOrder[m_iCurrentlySelectedHeaderButton];
			if(m_iCurrentlySelectedHeaderButton >= eLeaderboardSortType_SIZE)
			{
				m_iCurrentlySelectedHeaderButton = 0;
				m_eSortType = m_eSortOrder[m_iCurrentlySelectedHeaderButton];
			}
		}
		if(previousSelectedIndex != m_iCurrentlySelectedHeaderButton)
		{
			//we've changed to a different index that means
			//that we need to deselect and reselect our new button.
			m_aHeaderButtons[previousSelectedIndex].Deselect();
			m_aHeaderButtons[m_iCurrentlySelectedHeaderButton].Select();
		}
		else
		{
			m_bFlipSort = !m_bFlipSort;
			m_aHeaderButtons[m_iCurrentlySelectedHeaderButton].SetArrow( m_bFlipSort );
		}
		UpdateData();
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
		PreviousPageCallback(none);
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:
		TopPlayersButtonCallback(none);
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
		YourRankButtonCallback(none);
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		ViewProfile();
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:
		FriendRanksButtonCallback(none);
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
		NextPageCallback(none);
		break;

	default:
		bHandled = false;
		break;
	}

	if (!bHandled && m_kList.Navigator.OnUnrealCommand(cmd, arg))
		return true;

	return bHandled || super.OnUnrealCommand(cmd, arg);
}
public function ViewProfile()
{
	//TODO 
}
public function PreviousPageCallback(UIButton button)
{
	if(m_eLeaderboardType == eMPLeaderboard_TopPlayers)
	{
		if(m_iTopPlayersRank > 1)
		{
			m_iTopPlayersRank -= 20;

			if(m_iTopPlayersRank < 1)
			{
				m_iTopPlayersRank = 1;
			}

			if(!FetchTopPlayersListData()) // failed to fetch go back to previous rank
			{
				m_iTopPlayersRank += 20;
			}
		}
	}
}

public function NextPageCallback(UIButton button)
{
	if(m_eLeaderboardType == eMPLeaderboard_TopPlayers)
	{
		m_iTopPlayersRank += 20;

		if(!FetchTopPlayersListData()) // failed to fetch go back to previous rank
		{
			m_iTopPlayersRank -= 20;
		}
	}
}

public function TopPlayersButtonCallback(UIButton button)
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	
	if(m_kMPShellManager.m_bLeaderboardsTopPlayersDataLoaded)
	{
		m_eLeaderboardType = eMPLeaderboard_TopPlayers;
		m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strTopPlayersButtonText);
		OnLeaderBoardFetchComplete(m_kMpShellManager.m_tLeaderboardsTopPlayersData);
	}
	else if(m_eLeaderboardType != eMPLeaderboard_TopPlayers && FetchTopPlayersListData())
	{
		m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strTopPlayersButtonText);
		m_kScreenHeader.Show();
	}
	if( `ISCONTROLLERACTIVE == false)	UpdateNavButtons();
	m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strTopPlayersButtonText);
}

public function YourRankButtonCallback(UIButton button)
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	
	if(m_kMPShellManager.m_bLeaderboardsYourRankDataLoaded)
	{
		m_eLeaderboardType = eMPLeaderboard_YourRank;
		m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strYourRankButtonText);
		OnLeaderBoardFetchComplete(m_kMpShellManager.m_tLeaderboardsYourRankData);
	}
	else if(m_eLeaderboardType != eMPLeaderboard_YourRank && FetchYourRankListData())
	{
		m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strYourRankButtonText);
		m_kScreenHeader.Show();
	}
	if( `ISCONTROLLERACTIVE == false) UpdateNavButtons();
	m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strYourRankButtonText);
}

public function FriendRanksButtonCallback(UIButton button)
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(m_kMPShellManager.m_bLeaderboardsFriendsDataLoaded)
	{
		m_eLeaderboardType = eMPLeaderboard_Friends;
		m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strFriendRanksButtonText);
		OnLeaderBoardFetchComplete(m_kMpShellManager.m_tLeaderboardsFriendsData);
	}
	else if(m_eLeaderboardType != eMPLeaderboard_Friends && FetchFriendRanksListData())
	{
		m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strFriendRanksButtonText);
		m_kScreenHeader.Show();
	}
	if( `ISCONTROLLERACTIVE == false ) UpdateNavButtons();
	m_kScreenHeader.SetText(m_strLeaderboardHeaderText, m_strFriendRanksButtonText);
}

function BackButtonCallback()
{
	m_kMPShellManager.CancelLeaderboardsFetch();
	CloseScreen();
}

simulated function UpdateData()
{
	local TLeaderboardEntry kLeaderbardEntry;
	local int i;
	local UILeaderboard_ListItem kListItem;

	SortLeaderboards();
	
	if(m_eLeaderboardType == eMPLeaderboard_TopPlayers && GetLowestRank() > 0)
	{
		m_iTopPlayersRank = GetLowestRank();
	}

	// Clear old data
	m_kList.ClearItems();
	
	for(i = 0; i < m_LeaderboardsData.Length; i++)
	{
		kLeaderbardEntry = m_LeaderboardsData[i];
		kListItem = UILeaderboard_ListItem(m_kList.CreateItem(class'UILeaderboard_ListItem')).InitListItem();
		kListItem.UpdateData(kLeaderbardEntry);
	}
	m_kList.SetSelectedIndex(0);
}

simulated function int GetLowestRank()
{
	local int rank, i;
	rank = m_LeaderboardsData[0].iRank;

	for(i = 1; i < m_LeaderboardsData.Length; i++)
	{
		if(m_LeaderboardsData[i].iRank < rank)
		{
			rank = m_LeaderboardsData[i].iRank;
		}
	}

	return rank;
}

function OnLeaderBoardFetchComplete(const out TLeaderboardsData kLeaderboardsData)
{
	m_LeaderboardsData = kLeaderboardsData.arrResults;

	UpdateData();

	Movie.Pres.UICloseProgressDialog();
	UpdateNavHelp();
}

function SortLeaderboards()
{
	switch(m_eSortType)
	{
	case eLeaderboardSortType_Name: m_LeaderboardsData.Sort(SortByName); break;
	case eLeaderboardSortType_Rank: m_LeaderboardsData.Sort(SortByRank); break;
	case eLeaderboardSortType_Wins: m_LeaderboardsData.Sort(SortByWins); break;
	case eLeaderboardSortType_Losses: m_LeaderboardsData.Sort(SortByLosses); break;
	case eLeaderboardSortType_Disconnects: m_LeaderboardsData.Sort(SortByDisconnects); break;
	}
}

simulated function int SortByName(TLeaderboardEntry A, TLeaderboardEntry B)
{
	local string NameA, NameB;

	NameA = A.strPlayerName;
	NameB = B.strPlayerName;

	if(m_bMyRankTop)
	{
		if(A.playerID == PC.PlayerReplicationInfo.UniqueID)
			return 1;
		else if(B.playerID == PC.PlayerReplicationInfo.UniqueID)
			return -1;
	}

	if(NameA < NameB) return m_bFlipSort ? -1 : 1;
	else if(NameA > NameB) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByRank(TLeaderboardEntry A, TLeaderboardEntry B)
{
	if(m_bMyRankTop)
	{
		if(A.playerID == PC.PlayerReplicationInfo.UniqueID)
			return 1;
		else if(B.playerID == PC.PlayerReplicationInfo.UniqueID)
			return -1;
	}

	if(A.iRank < B.iRank) return m_bFlipSort ? -1 : 1;
	else if(A.iRank > B.iRank) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByWins(TLeaderboardEntry A, TLeaderboardEntry B)
{
	if(m_bMyRankTop)
	{
		if(A.playerID == PC.PlayerReplicationInfo.UniqueID)
			return 1;
		else if(B.playerID == PC.PlayerReplicationInfo.UniqueID)
			return -1;
	}

	if(A.iWins < B.iWins) return m_bFlipSort ? -1 : 1;
	else if(A.iWins > B.iWins) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByLosses(TLeaderboardEntry A, TLeaderboardEntry B)
{
	if(m_bMyRankTop)
	{
		if(A.playerID == PC.PlayerReplicationInfo.UniqueID)
			return 1;
		else if(B.playerID == PC.PlayerReplicationInfo.UniqueID)
			return -1;
	}

	if(A.iLosses < B.iLosses) return m_bFlipSort ? -1 : 1;
	else if(A.iLosses > B.iLosses) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByDisconnects(TLeaderboardEntry A, TLeaderboardEntry B)
{
	if(m_bMyRankTop)
	{
		if(A.playerID == PC.PlayerReplicationInfo.UniqueID)
			return 1;
		else if(B.playerID == PC.PlayerReplicationInfo.UniqueID)
			return -1;
	}

	if(A.iDisconnects < B.iDisconnects) return m_bFlipSort ? -1 : 1;
	else if(A.iDisconnects > B.iDisconnects) return m_bFlipSort ? 1 : -1;
	else return 0;
}

function bool FetchTopPlayersListData()
{
	m_bMyRankTop=false;
	return FetchLeaderboardData(eMPLeaderboard_TopPlayers);
}

function bool FetchYourRankListData()
{
	m_bMyRankTop=true;
	return FetchLeaderboardData(eMPLeaderboard_YourRank);
}

function bool FetchFriendRanksListData()
{
	m_bMyRankTop=false;
	return FetchLeaderboardData(eMPLeaderboard_Friends);
}

function bool FetchLeaderboardData(EMPLeaderboardType kLeaderboardType)
{
	local bool bSuccess;
	local TProgressDialogData kDialogBoxData;
	
	m_eLeaderboardType = kLeaderboardType;
	bSuccess = m_kMPShellManager.OSSBeginLeaderboardsFetch(kLeaderboardType, m_iTopPlayersRank, 20);
	if(bSuccess)
	{
		// If we're going to spawn a dialog box that says we're fetching data, that means we don't want navhelp to display anything, since we aren't able to do anything(kmartinez)
		m_NavHelp.ClearButtonHelp();
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strMPFetchingLeaderboardsProgressDialogTitle;
		kDialogBoxData.strDescription = class'X2MPData_Shell'.default.m_strMPFetchingLeaderboardsProgressDialogText;
		kDialogBoxData.fnCallback = CloseScreen;

		Movie.Pres.UIProgressDialog(kDialogBoxData);
	}
	return bSuccess;
}

simulated function CloseScreen()
{
	if(m_kMPShellManager.m_tLeaderboardsData.bFetching)
	{
		m_kMPShellManager.CancelLeaderboardsFetch();
	}
	Cleanup();
	super.CloseScreen();
}

/**
* Called when the world is being cleaned up. Allows the actor to free any dynamic content it has created.
*/
simulated event OnCleanupWorld()
{
	Cleanup();
}

function Cleanup()
{
	m_kMPShellManager.ClearLeaderboardFetchCompleteDelegate(OnLeaderBoardFetchComplete);
	m_kMPShellManager.CancelLeaderboardsFetch();
	if( `ISCONTROLLERACTIVE ) m_NavHelp.SetCenterHelpPaddingValue(m_NavHelp.CENTER_HELP_CONTAINER_PADDING);
}

defaultproperties
{
	m_iTopPlayersRank=1;
	m_eLeaderboardType = eMPLeaderboard_Friends;
	m_bMyRankTop=false;
	Package   = "/ package/gfxFacilitySummary/FacilitySummary";
	InputState = eInputState_Consume;
}