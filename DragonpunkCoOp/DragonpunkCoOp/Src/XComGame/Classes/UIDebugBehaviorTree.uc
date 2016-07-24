//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDebugBehaviorTree
//  AUTHOR:  Alex Cheng
//
//  PURPOSE: Provides a debug view of AI BehaviorTrees and the last traversals for each AI.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDebugBehaviorTree extends UIScreen;

struct UINodeListData
{
	var string			strName;
	var int				iTraversalIndex;
};

var private XComGameStateHistory CachedHistory;

var private array<string> m_UIAIUnitListData;
var private array<XGAIBehavior> m_arrAIBehavior;

var UIPanel			m_kBehaviorTreeContainer;
var UIBGBox		m_kBehaviorTreeBG;
var UIText		m_kBehaviorTreeTitle;
var UIList		m_kBehaviorTreeList;
var UIButton	m_kCloseButton;
var UICheckbox  m_kHideInvalid;

var UIPanel			m_kTreeDetailsContainer;
var UIBGBox		m_kTreeDetailBG;
var UIText		m_kTreeDetailTitle;
var UIList		m_kNodeList;

var UIPanel			m_kNodeDetailsContainer;
var UIBGBox		m_kNodeDetailBG;
var UITextContainer m_kNodeDetailText;

var name StoredInputState;

var bool bStoredMouseIsActive;

var int m_iSelectedUnitIndex;
var XGAIBehavior m_kSelectedAI;
var bt_traversal_data m_kSelectedTraversalData;
var int m_iSelectedTraversal;
var array<UINodeListData> m_kNodeListData;

var array<X2AIBTBehavior> m_arrDebugBehaviorTree;
struct CharacterBehaviorTrees
{
	var Name TemplateName;
	var array<int> BTRootIndexList;
};

var array<CharacterBehaviorTrees> CharBTList;

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
	// BehaviorTree Controls
	m_kBehaviorTreeContainer = Spawn(class'UIPanel', self).InitPanel();
	m_kBehaviorTreeContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	m_kBehaviorTreeContainer.SetPosition(-430, 50);

	m_kBehaviorTreeBG = Spawn(class'UIBGBox', m_kBehaviorTreeContainer);
	m_kBehaviorTreeBG.InitBG('', -10, -10, 400, 880);
	
	m_kBehaviorTreeTitle = Spawn(class'UIText', m_kBehaviorTreeContainer);
	m_kBehaviorTreeTitle.InitText('BehaviorTreeTitle', "BehaviorTree Traversal History", true);

	m_kBehaviorTreeList = Spawn(class'UIList', m_kBehaviorTreeContainer).InitList('', 0,30,370,740);
	m_kBehaviorTreeList.OnSelectionChanged = OnBehaviorTreeListItemSelected;
	m_kBehaviorTreeList.OnItemDoubleClicked = OnBehaviorTreeListItemDoubleClicked;

	m_kHideInvalid = Spawn(class'UICheckbox', m_kBehaviorTreeContainer);
	m_kHideInvalid.InitCheckbox('m_kHideInvalid', "Hide Untraversed nodes", true, ToggleHideValidCheckbox);	
	m_kHideInvalid.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(10, 780);

	// Tree Detail Controls
	m_kTreeDetailsContainer = Spawn(class'UIPanel', self).InitPanel();
	m_kTreeDetailsContainer.SetPosition(50, 50);

	m_kTreeDetailBG = Spawn(class'UIBGBox', m_kTreeDetailsContainer).InitBG('', -10, -10, 700, 700);

	m_kTreeDetailTitle = Spawn(class'UIText', m_kTreeDetailsContainer);
	m_kTreeDetailTitle.InitText('TreeDetailTitle', "Unit ID= [], History Frame= []", true);

	m_kNodeList = Spawn(class'UIList', m_kTreeDetailsContainer).InitList('', 0,30, 650, 650);
	m_kNodeList.OnSelectionChanged = OnNodeListItemSelected;
//	m_kNodeList.OnItemDoubleClicked = OnNodeListItemDoubleClicked;

	// Node Detail Controls
	m_kNodeDetailsContainer = Spawn(class'UIPanel', self).InitPanel();
	m_kNodeDetailsContainer.SetPosition(750, 50);

	m_kNodeDetailBG = Spawn(class'UIBGBox', m_kNodeDetailsContainer).InitBG('', -10, -10, 500, 700);

	m_kNodeDetailText = Spawn(class'UITextContainer', m_kNodeDetailsContainer);
	m_kNodeDetailText.InitTextContainer('', "<Empty>", 0, 0, 470, 650 );

	// Close Button
	m_kCloseButton = Spawn(class'UIButton', self);
	m_kCloseButton.InitButton('closeButton', "CLOSE", OnCloseButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	m_kCloseButton.SetPosition(600, 750);

	StoredInputState = XComTacticalController(GetALocalPlayerController()).GetInputState();
	XComTacticalController(GetALocalPlayerController()).SetInputState('InTransition');

	UpdateBehaviorTreeList();
}

simulated function OnCloseButtonClicked(UIButton button)
{	
	if( !bStoredMouseIsActive )
	{
		Movie.DeactivateMouse();
	}

	XComTacticalController(GetALocalPlayerController()).SetInputState(StoredInputState);
	Movie.Stack.Pop(self);
	`CHEATMGR.RemoveLookAt();
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
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			PrevTraversal();
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			NextTraversal();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

simulated function UpdateBehaviorTreeList()
{
	local string AIListData;
	local XComGameState_Unit kUnit;
	local XGAIBehavior kBehavior;

	m_kBehaviorTreeList.ClearItems();
	m_UIAIUnitListData.Length = 0;
	m_arrAIBehavior.Length = 0;

	foreach CachedHistory.IterateByClassType(class'XComGameState_Unit', kUnit)
	{
		kBehavior = XGUnit(kUnit.GetVisualizer()).m_kBehavior;
		if (kBehavior != None && kBehavior.m_arrTraversals.Length > 0)
		{
			m_arrAIBehavior.AddItem(kBehavior);
			AIListData = kUnit.GetMyTemplateName() @ "(" @ kUnit.ObjectID @ ")" @ kBehavior.m_arrTraversals.Length @ "BT Traversals Saved.";
			m_UIAIUnitListData.AddItem( AIListData );			
		}
	}

	PopulateBehaviorTreeList();

	m_kBehaviorTreeList.SetSelectedIndex(0);		
	OnBehaviorTreeListItemSelected(m_kBehaviorTreeList, 0);
}

function X2AIBTBehavior GetBehaviorTree(int RootIndex)
{
	local int iBTIndex, CharIndex;
	local X2AIBTBehavior kBT;
	local Name CharName;
	local CharacterBehaviorTrees CharBT;

	iBTIndex = INDEX_NONE;
	CharName = m_kSelectedAI.UnitState.GetMyTemplate().CharacterGroupName;
	CharIndex = CharBTList.Find('TemplateName', CharName);
	if( CharIndex == INDEX_NONE )
	{
		CharIndex = CharBTList.Length;
		CharBTList.AddItem(CharBT);
		CharBT.TemplateName = CharName;
	}
	iBTIndex = CharBTList[CharIndex].BTRootIndexList.Find(RootIndex);
	// We don't have this one saved out.  Save it out now.
	if( iBTIndex == INDEX_NONE )
	{
		kBT = `BEHAVIORTREEMGR.GenerateBehaviorTreeFromIndex(RootIndex, CharName);
		if (kBT != None)
		{
			iBTIndex = m_arrDebugBehaviorTree.Length;
			m_arrDebugBehaviorTree.AddItem(kBT);
			CharBTList[CharIndex].BTRootIndexList.AddItem(RootIndex);
		}
	}

	if (iBTIndex != INDEX_NONE)
	{
		return m_arrDebugBehaviorTree[iBTIndex];
	}
	return None;
}

simulated function UpdateNodeList()
{
	local int iNodeIndex, nNodes;
	local UINodeListData kUIData;
	local X2AIBTBehavior kBehaviorTree;
	local int RootIndex;
	m_kNodeList.ClearItems();
	m_kNodeListData.Length = 0;

	// Compile node list 
	nNodes = m_kSelectedTraversalData.TraversalData.Length;
	RootIndex = m_kSelectedTraversalData.BehaviorTreeRootIndex;
	if( RootIndex == INDEX_NONE )
	{
		RootIndex = `BEHAVIORTREEMGR.GetNodeIndex(Name(m_kSelectedAI.GetParentUnitState().GetMyTemplate().strBehaviorTree));
	}
	kBehaviorTree = GetBehaviorTree(RootIndex);
	for (iNodeIndex=0; iNodeIndex<nNodes; ++iNodeIndex)
	{
		kUIData.iTraversalIndex = iNodeIndex;
		kUIData.strName = m_kSelectedAI.CompileBTString(m_kSelectedTraversalData.TraversalData[kUIData.iTraversalIndex], kUIData.iTraversalIndex, kBehaviorTree);
		m_kNodeListData.AddItem( kUIData );			
	}

	PopulateNodeList();

	m_kNodeList.SetSelectedIndex(0);		
	OnNodeListItemSelected(m_kNodeList, 0);
}

function OnNodeListItemSelected(UIList listControl, int itemIndex)
{		
	RefreshNodeDetailText(itemIndex);
}

function RefreshNodeDetailText( int iListIndex )
{
	local int iNodeIndex;
	local X2AIBTBehavior BT;
	local X2AIBTBehavior Node;
	local string Details;
	local int RootIndex;
	RootIndex = m_kSelectedTraversalData.BehaviorTreeRootIndex;
	if( RootIndex == INDEX_NONE )
	{
		RootIndex = `BEHAVIORTREEMGR.GetNodeIndex(Name(m_kSelectedAI.GetParentUnitState().GetMyTemplate().strBehaviorTree));
	}

	BT = GetBehaviorTree(RootIndex);
	iNodeIndex = GetNodeIndexFromListIndex(iListIndex);

	BT.SetTraversalIndex(0);
	Node = BT.GetNodeIndex(iNodeIndex);
	Details = Node.GetNodeDetails(m_kSelectedTraversalData.TraversalData);
	Details = Details @ m_kSelectedTraversalData.TraversalData[iNodeIndex].DetailedText;
	m_kNodeDetailText.SetText(Details);
}

function int GetNodeIndexFromListIndex( int iListIndex )
{
	local int iNode, iRunningIndex;
	if (!m_kHideInvalid.bChecked || iListIndex == 0)
		return iListIndex;

	iRunningIndex = -1;
	for (iNode=0; iNode<m_kNodeListData.Length; iNode++)
	{
		if (m_kSelectedTraversalData.TraversalData[iNode].Result != BTS_INVALID)
		{
			iRunningIndex++;
		}
		if (iRunningIndex == iListIndex)
			return iNode;
	}
	`Warn("Error.  GetNodeIndexFromListIndex- Invalid index!");
	return 0;
}


simulated function PopulateNodeList()
{
	local int iNode;
	local UINodeListData kData;
	m_kNodeList.ClearItems();

	for (iNode=0; iNode<m_kNodeListData.Length; iNode++)
	{
		kData = m_kNodeListData[iNode];
		if (m_kSelectedTraversalData.TraversalData[kData.iTraversalIndex].Result == BTS_INVALID && m_kHideInvalid.bChecked)
			continue;

		Spawn(class'UIListItemString', m_kNodeList.itemContainer).InitListItem(kData.strName);
	}
}


simulated function ToggleHideValidCheckbox(UICheckbox checkboxControl)
{
	if( checkboxControl == m_kHideInvalid )
	{
		PopulateNodeList();
	}
}

function OnBehaviorTreeListItemSelected(UIList listControl, int itemIndex)
{		
	local int nTraversals;
	local vector vLoc;
	if (itemIndex < m_arrAIBehavior.Length)
	{
		m_iSelectedUnitIndex = itemIndex;
		m_kSelectedAI = m_arrAIBehavior[itemIndex];
		`BEHAVIORTREEMGR.ActiveCharacterName = String(m_kSelectedAI.UnitState.GetMyTemplate().CharacterGroupName);

		nTraversals = m_kSelectedAI.m_arrTraversals.Length;
		if (nTraversals > 0)
		{
			m_iSelectedTraversal = nTraversals-1;
			RefreshNodesList();
		}
		vLoc = m_kSelectedAI.m_kUnit.GetLocation();
		`CHEATMGR.ViewLocation(vLoc.X, vLoc.Y, vLoc.Z, true);
	}
	else
	{
		`Warn("Error.  Invalid item Index!");
	}
}

function RefreshNodesList()
{
	local string strTitle;
	m_kSelectedTraversalData = m_kSelectedAI.m_arrTraversals[m_iSelectedTraversal];
	strTitle = "Unit ID="@m_kSelectedAI.UnitState.ObjectID@"          History Frame="@m_kSelectedTraversalData.iHistoryIndex@"  ("$m_iSelectedTraversal+1@"of"@m_kSelectedAI.m_arrTraversals.Length$") Left/Right to change";
	m_kTreeDetailTitle.SetText(strTitle);
	UpdateNodeList();
}

simulated function PopulateBehaviorTreeList()
{
	while(m_kBehaviorTreeList.itemCount < m_UIAIUnitListData.Length)
	{
		Spawn(class'UIListItemString', m_kBehaviorTreeList.itemContainer).InitListItem(m_UIAIUnitListData[m_kBehaviorTreeList.itemCount]);
	}
}

function OnBehaviorTreeListItemDoubleClicked(UIList listControl, int itemIndex)
{
	PrevTraversal();
}

simulated public function PrevTraversal()
{
	if (m_iSelectedTraversal > 0)
	{
		m_iSelectedTraversal--;
	}
	else if (m_kSelectedAI.m_arrTraversals.Length > 1)
	{
		m_iSelectedTraversal = m_kSelectedAI.m_arrTraversals.Length - 1;
	}
	RefreshNodesList();
}

simulated public function NextTraversal()
{
	if (m_kSelectedAI.m_arrTraversals.Length > 1)
	{
		m_iSelectedTraversal++;
		m_iSelectedTraversal = m_iSelectedTraversal%m_kSelectedAI.m_arrTraversals.Length;
	}
	RefreshNodesList();
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