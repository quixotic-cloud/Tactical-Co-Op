//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDebugMultiplayer
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: Visualization and debugging simulated functionality for helping to solve multi-player 
//           issues in X-Com 2
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDebugMultiplayer extends UIScreen dependson(XComParcelManager, XComPlotCoverParcelManager, X2EventManager);

enum EMultiplayerDebugMode
{
	EMPDebugMode_ConnectionInfo,
	EMPDebugMode_EventManager,
	EMPDebugMode_HistoryObjects,
	EMPDebugMode_HistoryObjectDetail
};
var EMultiplayerDebugMode   DebugMode;
var int                     SelectedConnectionIdx;

var XComPresentationLayer   Pres;
var XComTacticalController  TacticalController;
var XComTacticalInput       TacticalInput;

//Game state objects
var XComGameStateHistory        History;
var X2EventManager              EventManager;
var XComGameStateNetworkManager NetworkManager;

//Stored state for restoring game play when the screen is exited
var name StoredInputState;
var bool bStoredMouseIsActive;

//UI Controls
var array<UIPanel>		AllDebugModeControls; //Used to hide all controls
var UIPanel				m_kAllContainer;
var UIButton		m_kStopButton;
var UIPanel				m_kConnectionInfoContainer;
var UIBGBox			m_kCurrentConnectionInfoBG;
var UIList			m_kConnectionInfoList;
var UIPanel				m_kConnectionInfoDetailContainer;
var UITextContainer m_kConnectionInfoDetailText;
var UIButton		m_kDebugEventManagerButton;
var UIButton		m_kDebugHistoryButton;
var UIPanel				m_kEventManagerContainer;
var UIBGBox			m_kEventListBG;
var UIList			m_kLocalEventList;
var UIList			m_kRemoteEventList;
var UIPanel				m_kHistoryListContainer;
var UIBGBox			m_kHistoryListBG;
var UIList			m_kLocalHistoryList;
var UIList			m_kRemoteHistoryList;
var UIPanel				m_kHistoryDetailContainer;
var UIBGBox			m_kHistoryDetailBG;
var UITextContainer m_kLocalDetailText;
var UITextContainer m_kRemoteDetailText;
var UIButton		m_kHistoryListDepthReturnButton;
var UIButton		m_kRefreshRemoteMirrorButton;

struct CachedListItemData
{
	var string ItemSummary;
	var int ItemIdx;
	var UIList OwningList;
};

var array<CachedListItemData> EventManagerListCache;
var int EventManagerListCacheIdx;

var array<CachedListItemData> HistoryListCache;		// When the History List is Updated, this gets filled out with the current snapshot.
var int HistoryListCacheIdx;						// Allows for a delayed load for too many History Objects.

enum eHistoryDepthSelectionType
{
	eHDST_HistoryFrame,
	eHDST_GameState,
};
var int HistoryDepthSelection[eHistoryDepthSelectionType.eHDST_MAX];	// Selection at each depth
var int HistoryListDepth;   // Follows eHistoryDepthSelectionType

//----------------------------------------------------------------------------
// MEMBERS
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	History = `XCOMHISTORY;
	EventManager = `XEVENTMGR;
	NetworkManager = `XCOMNETMANAGER;
	Pres = XComPresentationLayer(PC.Pres);
	TacticalController = XComTacticalController(PC);
	TacticalInput = XComTacticalInput(TacticalController.PlayerInput);
	StoredInputState = XComTacticalController(GetALocalPlayerController()).GetInputState();
	XComTacticalController(GetALocalPlayerController()).SetInputState('InTransition');

	super.InitScreen(InitController, InitMovie, InitName);

	DebugMode = EMPDebugMode_ConnectionInfo; // Starts here, but when the Event / History buttons are clicked then it will change


	m_kAllContainer = Spawn(class'UIPanel', self).InitPanel('allContainer').SetPosition(50, 50);
	m_kAllContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);


	//
	// Connection Info List
	m_kConnectionInfoContainer = Spawn(class'UIPanel', m_kAllContainer).InitPanel();
	m_kCurrentConnectionInfoBG = Spawn(class'UIBGBox', m_kConnectionInfoContainer).InitBG('', -10, -10, 650, 880);
	m_kConnectionInfoList = Spawn(class'UIList', m_kConnectionInfoContainer).InitList('', 0, 30, 600, 300);
	m_kConnectionInfoList.OnSelectionChanged = OnConnectionInfoListItemSelected;
	m_kConnectionInfoList.OnItemDoubleClicked = OnConnectionInfoListItemDoubleClicked;

	m_kConnectionInfoDetailContainer = Spawn(class'UIPanel', m_kConnectionInfoContainer).InitPanel();
	m_kConnectionInfoDetailText = Spawn(class'UITextContainer', m_kConnectionInfoDetailContainer).InitTextContainer('', "<Empty>", 0, 0, 600, 440);
	m_kDebugEventManagerButton = Spawn(class'UIButton', m_kConnectionInfoDetailContainer);
	m_kDebugEventManagerButton.InitButton('DebugEventManager', "Debug Event Manager", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON).SetPosition(25, 855);
	m_kDebugHistoryButton = Spawn(class'UIButton', m_kConnectionInfoDetailContainer);
	m_kDebugHistoryButton.InitButton('DebugHistoryList', "Debug History List", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON).SetPosition(225, 855);


	//
	// Event Manager
	m_kEventManagerContainer = Spawn(class'UIPanel', m_kAllContainer).InitPanel();
	m_kEventListBG = Spawn(class'UIBGBox', m_kEventManagerContainer).InitBG('', 700, -10, 1100, 880);

	m_kLocalEventList = Spawn(class'UIList', m_kEventManagerContainer).InitList('', 725, 30, 1050, 375);
	m_kLocalEventList.OnSelectionChanged = OnLocalEventListItemSelected;
	m_kLocalEventList.OnItemDoubleClicked = OnLocalEventListItemDoubleClicked;

	m_kRemoteEventList = Spawn(class'UIList', m_kEventManagerContainer).InitList('', 725, 455, 1050, 375);
	m_kRemoteEventList.OnSelectionChanged = OnRemoteEventListItemSelected;
	m_kRemoteEventList.OnItemDoubleClicked = OnRemoteEventListItemDoubleClicked;

	m_kEventManagerContainer.Hide();


	//
	// History Objects List
	m_kHistoryListContainer = Spawn(class'UIPanel', m_kAllContainer).InitPanel();
	m_kHistoryListBG = Spawn(class'UIBGBox', m_kHistoryListContainer).InitBG('', 700, -10, 1100, 220);

	// History List Windows
	m_kLocalHistoryList = Spawn(class'UIList', m_kHistoryListContainer).InitList('', 725, 0, 500, 200);
	m_kLocalHistoryList.OnSelectionChanged = OnLocalHistoryListItemSelected;
	m_kLocalHistoryList.OnItemDoubleClicked = OnLocalHistoryListItemDoubleClicked;

	m_kRemoteHistoryList = Spawn(class'UIList', m_kHistoryListContainer).InitList('', 1275, 0, 500, 200);
	m_kRemoteHistoryList.OnSelectionChanged = OnRemoteHistoryListItemSelected;
	m_kRemoteHistoryList.OnItemDoubleClicked = OnRemoteHistoryListItemDoubleClicked;

	// History Detail Windows
	m_kHistoryDetailContainer = Spawn(class'UIPanel', m_kHistoryListContainer).InitPanel();
	m_kHistoryDetailBG = Spawn(class'UIBGBox', m_kHistoryDetailContainer).InitBG('', 700, 240, 1100, 640);

	m_kLocalDetailText = Spawn(class'UITextContainer', m_kHistoryDetailContainer);	
	m_kLocalDetailText.InitTextContainer('', "<Empty>", 725, 280, 1050, 280 );

	m_kRemoteDetailText = Spawn(class'UITextContainer', m_kHistoryDetailContainer);	
	m_kRemoteDetailText.InitTextContainer('', "<Empty>", 725, 590, 1050, 280 );

	m_kHistoryListDepthReturnButton = Spawn(class'UIButton', m_kHistoryDetailContainer);
	m_kHistoryListDepthReturnButton.InitButton('HistoryListDepth', "Up History Level", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON).SetPosition(795, 865);

	m_kRefreshRemoteMirrorButton = Spawn(class'UIButton', m_kHistoryDetailContainer);
	m_kRefreshRemoteMirrorButton.InitButton('RefreshRemoteMirror', "Refresh Remote History", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON).SetPosition(1600, 865);

	m_kHistoryListContainer.Hide();


	//
	// Stop Debugging Button - Keep at bottom to always be on top
	m_kStopButton = Spawn(class'UIButton', m_kAllContainer);
	m_kStopButton.InitButton('stopButton', "Stop Debugging", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	m_kStopButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kStopButton.SetX(25);
	m_kStopButton.SetY(-25);


	//
	// Refresh any data
	UpdateConnectionInfoList();


	//
	// Cleanup the init process
	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();
}

simulated function ShowEventManagerList()
{
	UpdateEventManagerList();

	m_kHistoryListContainer.Hide();
	m_kEventManagerContainer.Show();
}

simulated function ShowHistoryList()
{
	UpdateHistoryList();
	UpdateHistoryListDetails();

	m_kEventManagerContainer.Hide();
	m_kHistoryListContainer.Show();
}

simulated function UpdateConnectionInfoList()
{
	local UIListItemString ListItem;
	local int Idx;
	m_kConnectionInfoList.ClearItems();

	if ( NetworkManager.Connections.Length > 0 )
	{
		for( Idx = 0; Idx < NetworkManager.Connections.Length; ++Idx )
		{
			ListItem = Spawn(class'UIListItemString', m_kConnectionInfoList.itemContainer);
			ListItem.InitListItem(NetworkManager.GetConnectionInfoDebugString(Idx));
		}
	}
	else
	{
		ListItem = Spawn(class'UIListItemString', m_kConnectionInfoList.itemContainer);
		ListItem.InitListItem(" ... No Connections Available ...");
		ListItem.DisableListItem();
	}
}

simulated function Helper_UpdateEventManagerList(UIList ControlList, X2EventManager InEventManager)
{
	local UIListItemString ListItem;
	local int Idx;
	local name EventName;
	local EventListener Listener;

	ControlList.ClearItems();

	foreach InEventManager.IterateEventByName(EventName, Listener)
	{
		++Idx;
		ListItem = Spawn(class'UIListItemString', ControlList.itemContainer);
		ListItem.InitListItem("" $ Idx $ ":" @ InEventManager.EventListenerToString(Listener, true));
	}

	if (ControlList.itemCount <= 0)
	{
		ListItem = Spawn(class'UIListItemString', ControlList.itemContainer);
		ListItem.InitListItem(" ... No Event Manager Listeners Available ...");
		ListItem.DisableListItem();
	}
}

simulated function UpdateEventManagerList()
{
	local X2EventManager RemoteEventManager;

	EventManagerListCache.Length = 0; // Clear all entries

	if ( SelectedConnectionIdx >= 0 && SelectedConnectionIdx < NetworkManager.Connections.Length)
	{
		RemoteEventManager = NetworkManager.Connections[SelectedConnectionIdx].EventManagerMirror;
	}

	Helper_UpdateEventManagerList(m_kLocalEventList, EventManager);
	Helper_UpdateEventManagerList(m_kRemoteEventList, RemoteEventManager);
}

simulated function UIListItemString AddHistoryItemToList(UIList ControlList, string StateSummary, optional delegate<OnPanelInited> AddDelegate = none)
{
	local UIListItemString ListItem;

	ListItem = Spawn(class'UIListItemString', ControlList.itemContainer);
	if (AddDelegate != none)
	{
		ListItem.AddOnInitDelegate(AddDelegate);
	}
	ListItem.InitListItem(StateSummary);

	return ListItem;
}

simulated function DelayedHistoryItemLoad( UIPanel Control )
{
	if ( HistoryListCacheIdx < HistoryListCache.Length )
	{
		AddHistoryItemToList(HistoryListCache[HistoryListCacheIdx].OwningList, HistoryListCache[HistoryListCacheIdx].ItemSummary, DelayedHistoryItemLoad);

		++HistoryListCacheIdx;
	}
}

// Default CacheEntriesStartingIdx will NOT add any entries to the cache, choose 0 to add ALL entries.
simulated function Helper_UpdateHistoryList(UIList ControlList, XComGameStateHistory InHistory, optional int CacheEntriesStartingIdx=-1)
{
	local int HistoryIndex, NumGameStates, CacheHistoryIndex;
	local string StateSummary;
	local XComGameState AssociatedGameStateFrame;	
	local UIListItemString ListItem;

	ControlList.ClearItems();

	switch(eHistoryDepthSelectionType(HistoryListDepth))
	{
	case eHDST_HistoryFrame:
		NumGameStates = InHistory.GetNumGameStates();
		break;
	case eHDST_GameState:
		AssociatedGameStateFrame = InHistory.GetGameStateFromHistory(HistoryDepthSelection[HistoryListDepth-1], eReturnType_Reference);
		NumGameStates = AssociatedGameStateFrame.GetNumGameStateObjects();
		break;
	}

	if ( InHistory != none && NumGameStates > 0 )
	{
		if ( CacheEntriesStartingIdx < 0 )
		{
			CacheEntriesStartingIdx = NumGameStates;
		}
		else
		{
			CacheHistoryIndex = HistoryListCache.Length;
			if ( NumGameStates > CacheEntriesStartingIdx )
			{
				HistoryListCache.Add(NumGameStates - CacheEntriesStartingIdx);
			}
		}

		for( HistoryIndex = 0; HistoryIndex < NumGameStates; ++HistoryIndex )
		{
			switch(eHistoryDepthSelectionType(HistoryListDepth))
			{
			case eHDST_HistoryFrame:
				AssociatedGameStateFrame = InHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
				StateSummary = "State" @ HistoryIndex @ ":" @ AssociatedGameStateFrame.GetContext().SummaryString() @ "(" @ AssociatedGameStateFrame.GetNumGameStateObjects() @ "OBJ" @ ")";
				break;
			case eHDST_GameState:
				StateSummary = string(AssociatedGameStateFrame.GetGameStateForObjectIndex(HistoryIndex).Name);
				break;
			}


			if ( HistoryIndex < CacheEntriesStartingIdx )
			{
				// Add history item to the list
				AddHistoryItemToList(ControlList, StateSummary);
			}
			else
			{
				// Cache this item for later addition
				HistoryListCache[CacheHistoryIndex].ItemSummary = StateSummary;
				HistoryListCache[CacheHistoryIndex].ItemIdx     = HistoryIndex;
				HistoryListCache[CacheHistoryIndex].OwningList  = ControlList;

				++CacheHistoryIndex;
			}
		}
	}
	else
	{
		ListItem = Spawn(class'UIListItemString', ControlList.itemContainer);
		ListItem.InitListItem(" ... No History Game States Available ...");
		ListItem.DisableListItem();
	}
}

simulated function UpdateHistoryList()
{
	HistoryListCacheIdx = 0;
	HistoryListCache.Length = 0;

	Helper_UpdateHistoryList(m_kLocalHistoryList, History, 50);
	Helper_UpdateHistoryList(m_kRemoteHistoryList, GetRemoteHistory(), 50);

	if ( HistoryListCache.Length > 0 )
	{
		DelayedHistoryItemLoad(none);
	}
}

simulated function OnConnectionInfoListItemSelected(UIList listControl, int itemIndex)
{
	SelectedConnectionIdx = itemIndex;

	switch( DebugMode )
	{
	case EMPDebugMode_EventManager:
		ShowEventManagerList();
		break;
	case EMPDebugMode_HistoryObjects:
		ShowHistoryList();
		break;
	case EMPDebugMode_HistoryObjectDetail:
		break;
	}
}

simulated function OnConnectionInfoListItemDoubleClicked(UIList listControl, int itemIndex)
{
}

simulated function OnLocalEventListItemSelected(UIList listControl, int itemIndex)
{
}

simulated function OnLocalEventListItemDoubleClicked(UIList listControl, int itemIndex)
{
}

simulated function OnRemoteEventListItemSelected(UIList listControl, int itemIndex)
{
}

simulated function OnRemoteEventListItemDoubleClicked(UIList listControl, int itemIndex)
{
}

simulated function Helper_UpdateHistoryListDetail(UITextContainer StateDetailText, XComGameStateHistory InHistory)
{
	local XComGameState AssociatedGameStateFrame;	
	local string TextString;

	switch(eHistoryDepthSelectionType(HistoryListDepth))
	{
	case eHDST_HistoryFrame:
		AssociatedGameStateFrame = InHistory.GetGameStateFromHistory(HistoryDepthSelection[HistoryListDepth], eReturnType_Reference);
		TextString = AssociatedGameStateFrame.GetContext().VerboseDebugString();
		StateDetailText.SetText( TextString );
		break;
	case eHDST_GameState:
		AssociatedGameStateFrame = InHistory.GetGameStateFromHistory(HistoryDepthSelection[HistoryListDepth-1], eReturnType_Reference);
		TextString = AssociatedGameStateFrame.GetGameStateForObjectIndex(HistoryDepthSelection[HistoryListDepth]).ToString();
		StateDetailText.SetText( TextString );
		break;
	}
}

simulated function UpdateHistoryListDetails()
{
	Helper_UpdateHistoryListDetail(m_kLocalDetailText, History);
	Helper_UpdateHistoryListDetail(m_kRemoteDetailText, GetRemoteHistory());
}

simulated function Helper_HistoryListItemSelected(int itemIndex)
{
	HistoryDepthSelection[HistoryListDepth] = itemIndex;
	UpdateHistoryListDetails();
}

simulated function Helper_HistoryListItemDoubleClicked(int itemIndex)
{
	HistoryDepthSelection[HistoryListDepth] = itemIndex;
	HistoryListDepth = Min(eHDST_MAX-1, HistoryListDepth + 1);
	HistoryDepthSelection[HistoryListDepth] = 0;
	UpdateHistoryListDetails();
}

simulated function OnLocalHistoryListItemSelected(UIList listControl, int itemIndex)
{
	Helper_HistoryListItemSelected(itemIndex);
}

simulated function OnLocalHistoryListItemDoubleClicked(UIList listControl, int itemIndex)
{
	Helper_HistoryListItemDoubleClicked(itemIndex);
}

simulated function OnRemoteHistoryListItemSelected(UIList listControl, int itemIndex)
{
	Helper_HistoryListItemSelected(itemIndex);
}

simulated function OnRemoteHistoryListItemDoubleClicked(UIList listControl, int itemIndex)
{
	Helper_HistoryListItemDoubleClicked(itemIndex);
}

simulated function SelectMPDebugMode(UIDropdown dropdown)
{	
	local int Index;

	for( Index = 0; Index < AllDebugModeControls.Length; ++Index )
	{
		AllDebugModeControls[Index].Hide();
	}

	DebugMode = EMultiplayerDebugMode(dropdown.selectedItem);	
	switch(DebugMode)
	{
	case EMPDebugMode_ConnectionInfo:
		break;
	case EMPDebugMode_EventManager:
		break;
	case EMPDebugMode_HistoryObjects:
		break;
	case EMPDebugMode_HistoryObjectDetail:
		break;
	default:
		break;
	}
}

simulated function XComGameStateHistory GetRemoteHistory()
{
	local XComGameStateHistory RemoteHistory;

	if ( SelectedConnectionIdx >= 0 && SelectedConnectionIdx < NetworkManager.Connections.Length)
	{
		RemoteHistory = NetworkManager.Connections[SelectedConnectionIdx].HistoryMirror;
	}

	return RemoteHistory;
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		case class'UIUtilities_input'.const.FXS_BUTTON_L3:
			return true;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			OnLMouseDown();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

public simulated function OnUCancel()
{
	
}

public simulated function OnLMouseDown()
{
	
}

simulated function OnButtonClicked(UIButton button)
{
	if ( button == m_kStopButton )
	{		
		Movie.Stack.Pop(self);
	}
	else if ( button == m_kDebugEventManagerButton )
	{
		ShowEventManagerList();
	}
	else if ( button == m_kDebugHistoryButton )
	{
		// Reset
		HistoryListDepth = 0;
		HistoryDepthSelection[HistoryListDepth] = 0;
		ShowHistoryList();
	}
	else if ( button == m_kHistoryListDepthReturnButton )
	{
		HistoryListDepth = Max(0, HistoryListDepth - 1);
		HistoryDepthSelection[HistoryListDepth] = 0;
		ShowHistoryList();
	}
	else if ( button == m_kRefreshRemoteMirrorButton )
	{

	}
}

simulated function OnRemoved()
{
	super.OnRemoved();
	
	if( !bStoredMouseIsActive )
	{
		Movie.DeactivateMouse();
	}

	TacticalController.SetInputState(StoredInputState);	
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	bHideOnLoseFocus = true;
}
