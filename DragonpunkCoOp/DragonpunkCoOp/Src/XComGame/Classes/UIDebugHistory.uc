//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDebugHistory
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: Provides a navigable view of the history object and its game states
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDebugHistory extends UIScreen;

enum EFilterTypeDropdown
{
	eFilterType_Turns,
	eFilterType_EventChains,
	eFilterType_EventTicks,
	eFilterType_Flat,
	eFilterType_Units,
};

struct UIGameStateListData
{
	var string          strName;
	var int             iValue;
};

struct PlayerTurnInfo
{
	var string PlayerTeam;
	var int HistoryIndex;
};

struct TickBatchInfo
{
	var int ChainIndex;	
	var int StartHistoryIndex;
	var int EndHistoryIndex;
	var string ContextSummaryString;
};

var private XComGameStateHistory CachedHistory;
var private array<TickBatchInfo> TickBatchList;
var private array<PlayerTurnInfo> TurnInfoList;

var private array<UIGameStateListData> GameStatesList;

var UIPanel			m_kHistoryContainer;
var UIBGBox		m_kHistoryBG;
var UIText		m_kHistoryTitle;
var UIList		m_kHistoryList;
var UIButton	m_kCloseButton;

var UIPanel			m_kDetailsContainer;
var UIBGBox		m_kStateDetailBG;
var UITextContainer m_kStateDetailText;
var UICheckbox  m_SendToLogCheckBox;

var int                 m_kDepthSelection[3];   //Selection at each depth
var int                 m_kListDepth;
var UIDropdown	m_kFilterType;

var name StoredInputState;

var bool bStoredMouseIsActive;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	super.InitScreen(InitController, InitMovie, InitName);

	CachedHistory = `XCOMHISTORY;
	
	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();

	//=======================================================================================
	//X-Com 2 UI - new dynamic UI system
	//
	// History Controls
	m_kHistoryContainer = Spawn(class'UIPanel', self).InitPanel();
	m_kHistoryContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	m_kHistoryContainer.SetPosition(-880, 50);

	m_kHistoryBG = Spawn(class'UIBGBox', m_kHistoryContainer);
	m_kHistoryBG.InitBG('', -10, -10, 850, 880);
	
	m_kHistoryTitle = Spawn(class'UIText', m_kHistoryContainer);
	m_kHistoryTitle.InitText('historyTitle', "History States", true);

	m_kHistoryList = Spawn(class'UIList', m_kHistoryContainer).InitList('', 0,30,800,740);
	m_kHistoryList.OnSelectionChanged = OnHistoryListItemSelected;
	m_kHistoryList.OnItemDoubleClicked = OnHistoryListItemDoubleClicked;
	
	m_kFilterType = Spawn(class'UIDropdown', m_kHistoryContainer);
	m_kFilterType.InitDropdown('', "Filter List Type", SelectFilterType);
	m_kFilterType.AddItem("Turns").AddItem("Event Chains").AddItem("Ticks").AddItem("Flat").AddItem("Units");
	m_kFilterType.SetPosition(15, 830);

	// State Detail Controls
	m_kDetailsContainer = Spawn(class'UIPanel', self).InitPanel();
	m_kDetailsContainer.SetPosition(50, 50);

	m_kStateDetailBG = Spawn(class'UIBGBox', m_kDetailsContainer).InitBG('', -10, -10, 750, 700);

	m_kStateDetailText = Spawn(class'UITextContainer', m_kDetailsContainer);	
	m_kStateDetailText.InitTextContainer('', "<Empty>", 0, 0, 750, 700 );

	// Send to Log Check Box
	//InitCheckbox(name InitName, optional string initText, optional bool bInitChecked, optional delegate<OnChangedCallback> statusChangedDelegate, optional bool bInitReadOnly)
	m_SendToLogCheckBox = Spawn(class'UICheckBox', self).InitCheckbox('', "Send to Log", false, OnCheckboxChange);
	m_SendToLogCheckBox.SetPosition(250, 750);

	// Close Button
	m_kCloseButton = Spawn(class'UIButton', self);
	m_kCloseButton.InitButton('closeButton', "CLOSE", OnCloseButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	m_kCloseButton.SetPosition(600, 750);

	// Show flat view by default in strategy game
	if(Movie.Pres.Class.Name == 'XComHQPresentationLayer')
	{
		m_kFilterType.SetSelected(eFilterType_Flat);
	}
	else
	{
		m_kFilterType.SetSelected(eFilterType_EventTicks);
	}
		

	StoredInputState = XComTacticalController(GetALocalPlayerController()).GetInputState();
	XComTacticalController(GetALocalPlayerController()).SetInputState('InTransition');

	UpdateHistoryList();
}

simulated function OnCheckboxChange(UICheckbox checkboxControl)
{
	UpdateListItem();
}

simulated function OnCloseButtonClicked(UIButton button)
{	
	if( m_kListDepth > 0 )
	{			
		m_kListDepth = Max(m_kListDepth - 1, 0);
		UpdateHistoryList();
	}
	else
	{
		if( !bStoredMouseIsActive )
		{
			Movie.DeactivateMouse();
		}

		XComTacticalController(GetALocalPlayerController()).SetInputState(StoredInputState);
		Movie.Stack.Pop(self);
	}
}

simulated function SelectFilterType(UIDropdown dropdown)
{	
	local int Index;

	m_kListDepth = 0;	
	for( Index = 0; Index < 3; Index++ )
	{
		m_kDepthSelection[Index] = 0;
	}

	UpdateHistoryList();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCloseButtonClicked(m_kCloseButton);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:		
			OnUAccept();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

simulated function UpdateHistoryList()
{
	m_kHistoryList.ClearItems();

	switch(EFilterTypeDropdown(m_kFilterType.selectedItem))
	{
	case eFilterType_Turns:
		UpdateHistoryListTurns();
		break;
	case eFilterType_EventChains:
	case eFilterType_EventTicks:
		UpdateHistoryListTicks();
		break;
	case eFilterType_Flat:
		UpdateHistoryListFlat();
		break;
	case eFilterType_Units:
		UpdateHistoryListUnits();
	}
}

simulated function UpdateHistoryListTurns()
{
	local UIGameStateListData XComGameStateData;
	local int HistoryIndex;	
	local XComGameStateContext_TacticalGameRule GameRuleState;
	local XComGameState AssociatedGameStateFrame;
	local XComGameState_BattleData BattleData;
	local array<XComGameState_Player> PlayerStateObjects;
	local int PlayerIndex;
	local PlayerTurnInfo EmptyInfo;
	local PlayerTurnInfo NewTurnInfo;	
	local int TurnIndex;
	local int TurnNumber;
	local int NumGameStates;
	local bool bContinue;

	GameStatesList.Length = 0;
	TurnInfoList.Length = 0;

	//Retrieve the BattleData object
	BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	//Get the list of players from the BattleData object
	for( PlayerIndex = 0; PlayerIndex < BattleData.PlayerTurnOrder.Length; PlayerIndex++ )
	{
		PlayerStateObjects.AddItem(XComGameState_Player(CachedHistory.GetGameStateForObjectID(BattleData.PlayerTurnOrder[PlayerIndex].ObjectID)));
	}
	
	NumGameStates = CachedHistory.GetNumGameStates();

	//Build a list of turns
	PlayerIndex = 0;
	for( HistoryIndex = 0; HistoryIndex < NumGameStates; HistoryIndex++ )
	{		
		AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
		GameRuleState = XComGameStateContext_TacticalGameRule(AssociatedGameStateFrame.GetContext());
		if( GameRuleState.GameRuleType == eGameRule_PlayerTurnBegin )
		{
			NewTurnInfo = EmptyInfo;
			NewTurnInfo.PlayerTeam = string(PlayerStateObjects[PlayerIndex].TeamFlag);
			NewTurnInfo.HistoryIndex = HistoryIndex;
			TurnInfoList.AddItem(NewTurnInfo);

			PlayerIndex = (PlayerIndex + 1) % BattleData.PlayerTurnOrder.Length;
		}
	}

	switch(m_kListDepth)
	{
	case 0:				
		for( TurnIndex = 0; TurnIndex < TurnInfoList.Length; TurnIndex++ )
		{
			TurnNumber = TurnIndex / BattleData.PlayerTurnOrder.Length;
			XComGameStateData.strName = "Turn"@TurnNumber@" : "@TurnInfoList[TurnIndex].PlayerTeam;
			XComGameStateData.iValue = TurnIndex;
			GameStatesList.AddItem( XComGameStateData );			
		}
		break;
	case 1:		
		NewTurnInfo = TurnInfoList[m_kDepthSelection[m_kListDepth-1]]; //depth 0 picks player turn info
		bContinue = true;
		for( HistoryIndex = NewTurnInfo.HistoryIndex; HistoryIndex < NumGameStates && bContinue; HistoryIndex++ )
		{		
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);

			GameRuleState = XComGameStateContext_TacticalGameRule(AssociatedGameStateFrame.GetContext());
			if(GameRuleState.GameRuleType == eGameRule_PlayerTurnBegin && HistoryIndex > NewTurnInfo.HistoryIndex)
			{
				bContinue = false;
			}

			XComGameStateData.strName = "State" @ HistoryIndex @ ":" @ AssociatedGameStateFrame.GetContext().SummaryString() @ "(" @ AssociatedGameStateFrame.GetNumGameStateObjects() @ "OBJ" @ ")";
			XComGameStateData.iValue = HistoryIndex;
			GameStatesList.AddItem( XComGameStateData );
		}
		break;
	case 2:
		NewTurnInfo = TurnInfoList[m_kDepthSelection[m_kListDepth-2]];
		HistoryIndex = NewTurnInfo.HistoryIndex + m_kDepthSelection[m_kListDepth-1];
		AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
		NumGameStates = AssociatedGameStateFrame.GetNumGameStateObjects();
		for( HistoryIndex = 0; HistoryIndex < NumGameStates; HistoryIndex++ )
		{
			XComGameStateData.strName = string(AssociatedGameStateFrame.GetGameStateForObjectIndex(HistoryIndex).Name);
			XComGameStateData.iValue = HistoryIndex;
			GameStatesList.AddItem( XComGameStateData );
		}
		break;
	}
	
	PopulateHistoryList(none);

	
	switch(m_kListDepth)
	{
	case 0:
		break;
	case 1:		
		m_kHistoryList.SetSelectedIndex(m_kDepthSelection[m_kListDepth]);
		OnHistoryListItemSelected(m_kHistoryList, m_kDepthSelection[m_kListDepth]);
		break;
	case 2:
		m_kHistoryList.SetSelectedIndex(m_kDepthSelection[m_kListDepth-1]);
		OnHistoryListItemSelected(m_kHistoryList, m_kDepthSelection[m_kListDepth]);
		break;
	}
	
}

simulated function UpdateHistoryListTicks()
{
	local UIGameStateListData XComGameStateData;
	local int HistoryIndex;		
	local XComGameState AssociatedGameStateFrame;	
	local TickBatchInfo EmptyBatchInfo;
	local TickBatchInfo NewBatchInfo;		
	local EFilterTypeDropdown DropdownSetting;
	local int TestIndex;
	local int NumGameStates;
	local int BatchInfoIndex;
	local XComGameStateContext Context;

	GameStatesList.Length = 0;

	NumGameStates = CachedHistory.GetNumGameStates();

	DropdownSetting = EFilterTypeDropdown(m_kFilterType.selectedItem);

	//Build the combined list of game states, starting with the 0th state
	AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(NumGameStates - 1, eReturnType_Reference);

	TickBatchList.Length = 0;
	NewBatchInfo = EmptyBatchInfo;
	NewBatchInfo.StartHistoryIndex = -1;
	NewBatchInfo.EndHistoryIndex = NumGameStates - 1;	
	NewBatchInfo.ChainIndex = DropdownSetting == eFilterType_EventChains ? AssociatedGameStateFrame.GetContext().EventChainStartIndex : AssociatedGameStateFrame.TickAddedToHistory;

	for(HistoryIndex = NumGameStates - 2; HistoryIndex > 0; HistoryIndex--)
	{		
		AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
		if(AssociatedGameStateFrame == none)
		{
			break;
		}

		TestIndex = DropdownSetting == eFilterType_EventChains ? AssociatedGameStateFrame.GetContext().EventChainStartIndex : AssociatedGameStateFrame.TickAddedToHistory;

		if(NewBatchInfo.ChainIndex != TestIndex)
		{
			NewBatchInfo.StartHistoryIndex = HistoryIndex+1;
			Context = CachedHistory.GetGameStateFromHistory(NewBatchInfo.StartHistoryIndex, eReturnType_Reference).GetContext();
			NewBatchInfo.ContextSummaryString = Context.SummaryString();

			if( `CHEATMGR.X2DebugHistoryHighlight > 0 && Context.HasAssociatedObjectID(`CHEATMGR.X2DebugHistoryHighlight) )
			{
				NewBatchInfo.ContextSummaryString = class'UIUtilities_Text'.static.GetColoredText(NewBatchInfo.ContextSummaryString, eUIState_Good);
			}


			//Add the current batch info and create another
			TickBatchList.AddItem(NewBatchInfo);

			NewBatchInfo = EmptyBatchInfo;
			NewBatchInfo.StartHistoryIndex = -1;
			NewBatchInfo.EndHistoryIndex = HistoryIndex;
			Context = AssociatedGameStateFrame.GetContext();
			NewBatchInfo.ContextSummaryString = Context.SummaryString();
			if( `CHEATMGR.X2DebugHistoryHighlight > 0 && Context.HasAssociatedObjectID(`CHEATMGR.X2DebugHistoryHighlight) )
			{
				NewBatchInfo.ContextSummaryString = class'UIUtilities_Text'.static.GetColoredText(NewBatchInfo.ContextSummaryString, eUIState_Good);
			}

			NewBatchInfo.ChainIndex = TestIndex;
		}
	}

	if(NewBatchInfo.StartHistoryIndex == -1)
	{
		NewBatchInfo.StartHistoryIndex = 0;
		//Add the current batch info and create another
		TickBatchList.AddItem(NewBatchInfo);
	}

	switch(m_kListDepth)
	{
	case 0:				
		for( BatchInfoIndex = 0; BatchInfoIndex < TickBatchList.Length; BatchInfoIndex++ )
		{
			NewBatchInfo = TickBatchList[BatchInfoIndex];

			XComGameStateData.strName = NewBatchInfo.StartHistoryIndex @ " " @ NewBatchInfo.ContextSummaryString @ " (" @ (NewBatchInfo.EndHistoryIndex - NewBatchInfo.StartHistoryIndex) @ " Frames) ";
			XComGameStateData.iValue = BatchInfoIndex;
			GameStatesList.AddItem( XComGameStateData );			
		}
		break;
	case 1:		
		NewBatchInfo = TickBatchList[m_kDepthSelection[m_kListDepth-1]]; //depth 0 picks a batch info		
		for( HistoryIndex = NewBatchInfo.StartHistoryIndex; HistoryIndex < NewBatchInfo.EndHistoryIndex; HistoryIndex++ )
		{		
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
			XComGameStateData.strName = "State" @ HistoryIndex @ ":" @ AssociatedGameStateFrame.GetContext().SummaryString() @ "(" @ AssociatedGameStateFrame.GetNumGameStateObjects() @ "OBJ" @ ")";
			if( `CHEATMGR.X2DebugHistoryHighlight > 0 && AssociatedGameStateFrame.GetContext().HasAssociatedObjectID(`CHEATMGR.X2DebugHistoryHighlight) )
			{
				XComGameStateData.strName = class'UIUtilities_Text'.static.GetColoredText(XComGameStateData.strName, eUIState_Good);
			}
			XComGameStateData.iValue = HistoryIndex;
			GameStatesList.AddItem( XComGameStateData );
		}
		break;
	case 2:
		NewBatchInfo = TickBatchList[m_kDepthSelection[m_kListDepth-2]]; //depth 0 picks a batch info		
		HistoryIndex = NewBatchInfo.StartHistoryIndex + m_kDepthSelection[m_kListDepth-1];
		AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
		NumGameStates = AssociatedGameStateFrame.GetNumGameStateObjects();
		for( HistoryIndex = 0; HistoryIndex < NumGameStates; HistoryIndex++ )
		{
			XComGameStateData.strName = string(AssociatedGameStateFrame.GetGameStateForObjectIndex(HistoryIndex).Name);
			XComGameStateData.iValue = HistoryIndex;
			GameStatesList.AddItem( XComGameStateData );
		}
		break;
	}
	
	PopulateHistoryList(none);

	
	switch(m_kListDepth)
	{
	case 0:
		break;
	case 1:		
		m_kHistoryList.SetSelectedIndex(m_kDepthSelection[m_kListDepth]);
		OnHistoryListItemSelected(m_kHistoryList, m_kDepthSelection[m_kListDepth]);
		break;
	case 2:
		m_kHistoryList.SetSelectedIndex(m_kDepthSelection[m_kListDepth-1]);
		OnHistoryListItemSelected(m_kHistoryList, m_kDepthSelection[m_kListDepth]);
		break;
	}
	
}

simulated function UpdateHistoryListFlat()
{
	local int HistoryIndex, NumHistoryPrinted;
	local UIGameStateListData XComGameStateData;
	local XComGameState AssociatedGameStateFrame;	
	local XComGameStateContext AssociatedContext;
	local XComCheatManager CheatMgr;

	GameStatesList.Length = 0;
	CheatMgr = XComCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);

	switch(m_kListDepth)
	{
	case 0:
		NumHistoryPrinted = CachedHistory.GetNumGameStates();
		for( HistoryIndex = NumHistoryPrinted - 1; HistoryIndex > -1; HistoryIndex-- )
		{		
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
			if(AssociatedGameStateFrame == none)
			{
				continue;
			}
			AssociatedContext = AssociatedGameStateFrame.GetContext();
			XComGameStateData.strName = "State" @ HistoryIndex @ ":" @ AssociatedContext.SummaryString() @ "(" @ AssociatedGameStateFrame.GetNumGameStateObjects() @ "OBJ" @ ") [" @ (AssociatedContext.VisualizationStartIndex > 0 ? AssociatedContext.VisualizationStartIndex : HistoryIndex - 1) @ "]";
			if( CheatMgr.X2DebugHistoryHighlight > 0 && AssociatedContext.HasAssociatedObjectID(CheatMgr.X2DebugHistoryHighlight) )
			{
				XComGameStateData.strName = class'UIUtilities_Text'.static.GetColoredText(XComGameStateData.strName, eUIState_Good);
			}
			XComGameStateData.iValue = HistoryIndex;
			GameStatesList.AddItem( XComGameStateData );			
		}
		break;
	case 1:
		HistoryIndex = CachedHistory.GetNumGameStates() - 1 - m_kDepthSelection[m_kListDepth-1];
		AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
		NumHistoryPrinted = AssociatedGameStateFrame.GetNumGameStateObjects();
		for( HistoryIndex = 0; HistoryIndex < NumHistoryPrinted; HistoryIndex++ )
		{
			XComGameStateData.strName = string(AssociatedGameStateFrame.GetGameStateForObjectIndex(HistoryIndex).Name);
			XComGameStateData.iValue = HistoryIndex;
			GameStatesList.AddItem( XComGameStateData );
		}
		break;
	}

	PopulateHistoryList(None);

	switch(m_kListDepth)
	{
	case 0:
		m_kHistoryList.SetSelectedIndex(m_kDepthSelection[m_kListDepth]);		
		OnHistoryListItemSelected(m_kHistoryList, m_kDepthSelection[m_kListDepth]);
		break;
	case 1:
		m_kHistoryList.SetSelectedIndex(m_kDepthSelection[m_kListDepth]);
		OnHistoryListItemSelected(m_kHistoryList, m_kDepthSelection[m_kListDepth-1]);
		break;
	}
}

simulated function UpdateHistoryListUnits()
{
	local int HistoryIndex;
	local UIGameStateListData XComGameStateData;
	local XComGameState_Unit UnitState;	

	GameStatesList.Length = 0;
	HistoryIndex = 0;

	switch(m_kListDepth)
	{
	case 0:
		foreach CachedHistory.IterateByClassType(class'XComGameState_Unit', UnitState)
		{		
			XComGameStateData.strName = "Unit" @ HistoryIndex @ ":" @ UnitState.name @ "(" @ UnitState.GetReference().ObjectID @ ")";
			XComGameStateData.iValue = HistoryIndex;
			GameStatesList.AddItem( XComGameStateData );
			++HistoryIndex;
		}
		break;
	}

	PopulateHistoryList(none);

	switch(m_kListDepth)
	{
	case 0:
		m_kHistoryList.SetSelectedIndex(m_kDepthSelection[m_kListDepth]);		
		OnHistoryListItemSelected(m_kHistoryList, m_kDepthSelection[m_kListDepth]);
		break;
	}
}

simulated function PopulateHistoryList( UIPanel Control )
{
	// Populate list instantly if there are few elements, otherwise populate one by one
	if(GameStatesList.Length < 100)
	{
		while(m_kHistoryList.itemCount < GameStatesList.Length)
		{
			Spawn(class'UIListItemString', m_kHistoryList.itemContainer)
			.InitListItem(GameStatesList[m_kHistoryList.itemCount].strName);
		}
	}
	else if(m_kHistoryList.itemCount < GameStatesList.Length)
	{
		Spawn(class'UIListItemString', m_kHistoryList.itemContainer)
		.InitListItem(GameStatesList[m_kHistoryList.itemCount].strName)
		.AddOnInitDelegate(PopulateHistoryList);
	}
}

function OnHistoryListItemSelected(UIList listControl, int itemIndex)
{
	m_kDepthSelection[m_kListDepth] = itemIndex;
	UpdateListItem();
}

function UpdateListItem()
{
	local XComGameState AssociatedGameStateFrame;	
	local string TextString;
	local int HistoryIndex;
	local XComGameState_Unit UnitState;

	switch(EFilterTypeDropdown(m_kFilterType.selectedItem))
	{
	case eFilterType_Turns:		
		// depth 0 selection: turn
		// depth 1 selection: history frame
		// depth 2 selection: game state
		switch(m_kListDepth)
		{
		case 1:
			HistoryIndex = TurnInfoList[m_kDepthSelection[m_kListDepth-1]].HistoryIndex + m_kDepthSelection[m_kListDepth];
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
			TextString = AssociatedGameStateFrame.GetContext().VerboseDebugString();
			m_kStateDetailText.SetText( TextString );
			break;
		case 2:
			HistoryIndex = TurnInfoList[m_kDepthSelection[m_kListDepth-2]].HistoryIndex + m_kDepthSelection[m_kListDepth-1];
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
			TextString = AssociatedGameStateFrame.GetGameStateForObjectIndex(m_kDepthSelection[m_kListDepth]).ToString();
			m_kStateDetailText.SetText( TextString );
			break;
		}
		break;
	case eFilterType_EventChains:
	case eFilterType_EventTicks:
		// depth 0 selection: ticks
		// depth 1 selection: history frame
		// depth 2 selection: game state
		switch(m_kListDepth)
		{
		case 1:
			HistoryIndex = TickBatchList[m_kDepthSelection[m_kListDepth-1]].StartHistoryIndex + m_kDepthSelection[m_kListDepth];
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
			TextString = AssociatedGameStateFrame.GetContext().VerboseDebugString();
			m_kStateDetailText.SetText( TextString );
			break;
		case 2:
			HistoryIndex = TickBatchList[m_kDepthSelection[m_kListDepth-2]].StartHistoryIndex + m_kDepthSelection[m_kListDepth-1];
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
			TextString = AssociatedGameStateFrame.GetGameStateForObjectIndex(m_kDepthSelection[m_kListDepth]).ToString();
			m_kStateDetailText.SetText( TextString );
			break;
		}
		break;
	case eFilterType_Flat:
		switch(m_kListDepth)
		{
		case 0:
			HistoryIndex = CachedHistory.GetNumGameStates() - 1 - m_kDepthSelection[m_kListDepth];
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
			TextString = AssociatedGameStateFrame.GetContext().VerboseDebugString();
			m_kStateDetailText.SetText( TextString );
			break;
		case 1:
			HistoryIndex = CachedHistory.GetNumGameStates() - 1 - m_kDepthSelection[m_kListDepth - 1];
			AssociatedGameStateFrame = CachedHistory.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
			TextString = AssociatedGameStateFrame.GetGameStateForObjectIndex(m_kDepthSelection[m_kListDepth]).ToString();
			m_kStateDetailText.SetText( TextString );
			break;
		}		
		break;
	case eFilterType_Units:
		switch(m_kListDepth)
		{
		case 0:
			HistoryIndex = 0;
			foreach CachedHistory.IterateByClassType(class'XComGameState_Unit', UnitState)
			{		
				if( HistoryIndex == m_kDepthSelection[m_kListDepth] )
				{
					TextString = UnitState.GetStatusString();
					m_kStateDetailText.SetText( TextString );
					break;
				}
				++HistoryIndex;
			}
			break;
		}		
		break;
	}

	if( m_SendToLogCheckBox.bChecked )
	{
		`log(`location @ TextString);
	}
}

function OnHistoryListItemDoubleClicked(UIList listControl, int itemIndex)
{
	OnUAccept();
}

simulated public function OnUAccept()
{
	m_kListDepth = Min(m_kListDepth + 1, GetMaxSelectionDepth());
	UpdateHistoryList();
}

simulated function int GetMaxSelectionDepth()
{	
	switch(EFilterTypeDropdown(m_kFilterType.selectedItem))
	{
	case eFilterType_Turns:
		return 2;
		break;
	case eFilterType_EventChains:
	case eFilterType_EventTicks:
		return 2;
		break;
	case eFilterType_Flat:		
		return 1;
		break;
	case eFilterType_Units:
		return 0;
		break;
	}
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

simulated function OnReceiveFocus()
{
	Show();
}

simulated function OnLoseFocus()
{
	Hide();
}

defaultproperties
{
	InputState    = eInputState_Consume;	
}