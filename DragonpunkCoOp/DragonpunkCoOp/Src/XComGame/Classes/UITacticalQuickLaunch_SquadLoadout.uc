//-------------------------------------
//--------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalQuickLaunch_SquadLoadout
//  AUTHOR:  Sam Batista --  02/26/14
//  PURPOSE: Provides functionality to outfit and loadout units.
//  NOTE:    Contains most GAME logic 
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalQuickLaunch_SquadLoadout extends UIScreen;

// GAME Vars
var private XComGameState GameState;
				 
// UI Vars		 
var private int      m_iXPositionHelper;
var private int      m_iSlotsStartY;
var private UIPanel	 m_kContainer;
var private UIList	 m_kSoldierList;
var private UIButton m_kAddUnitButton;
var private UIButton m_kRemoveUnitButton;
var private UIButton m_kNewSquadButton;
var private UIButton m_kLaunchButton;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIPanel kBG, kLine;
	local UIText kTitle;

	super.InitScreen(InitController, InitMovie, InitName);

	// Create Container
	m_kContainer = Spawn(class'UIPanel', self);
	m_kContainer.InitPanel();

	// Create BG
	kBG = Spawn(class'UIBGBox', m_kContainer).InitBG('BG', 0, 0, 1840, 1020);

	// Center Container using BG
	m_kContainer.CenterWithin(kBG);

	// MOUSE GUARD - PREVENT USERS FROM CHANGING DROPDOWN OPTIONS
	// Spawn(class'UIBGBox', self).InitBG('',40,120,kBG.width,kBG.height-90).ProcessMouseEvents(none).SetAlpha(75);

	// Create Title text
	kTitle = Spawn(class'UIText', m_kContainer);
	kTitle.InitText('', "TACTICAL LOADOUT", true);
	kTitle.SetPosition(10, 5).SetWidth(kBG.width);

	// Create Add / Remove Slot + Launch Tactical Map buttons
	m_kAddUnitButton = Spawn(class'UIButton', m_kContainer);
	m_kAddUnitButton.InitButton('', "ADD UNIT", AddSlot, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	m_kAddUnitButton.SetPosition(320, 10);

	m_kRemoveUnitButton = Spawn(class'UIButton', m_kContainer);
	m_kRemoveUnitButton.InitButton('', "REMOVE UNIT", RemoveSlot, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	m_kRemoveUnitButton.SetPosition(480, 10);

	m_kNewSquadButton = Spawn(class'UIButton', m_kContainer);
	m_kNewSquadButton.InitButton('', "NEW SQUAD", NewSquad, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	m_kNewSquadButton.SetPosition(680, 10);

	m_kLaunchButton = Spawn(class'UIButton', m_kContainer);
	if(!Movie.Stack.IsInStack(class'UITacticalQuickLaunch'))
		m_kLaunchButton.InitButton('', "LAUNCH", LaunchTacticalMap, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	else
		m_kLaunchButton.InitButton('', "SAVE & EXIT", LaunchTacticalMap, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	m_kLaunchButton.SetPosition(kBG.width - 160, 10);
	
	// Add divider line
	kLine = Spawn(class'UIPanel', m_kContainer);
	kLine.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
	kLine.SetSize(kBG.width - 10, 2).SetPosition(5, 50).SetAlpha(50);

	// Add column headers (order matters)
	CreateColumnHeader("CHARACTER TYPE");
	CreateColumnHeader("SOLDIER CLASS");
	CreateColumnHeader("WEAPONS");
	//CreateColumnHeader("HEAVY WEAPON"); TODO (NOT YET IMPLEMENTED BY GAMEPLAY)
	CreateColumnHeader("ARMOR / MISSION ITEM");
	CreateColumnHeader("UTILITY ITEMS");

	// Add divider line
	kLine = Spawn(class'UIPanel', m_kContainer);
	kLine.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
	kLine.SetPosition(5, 90).SetSize(kBG.width - 10, 2).SetAlpha(50);
	
	// Get initial GameState
	GameState = Movie.Pres.TacticalStartState;

	m_kSoldierList = Spawn(class'UIList', m_kContainer);
	m_kSoldierList.InitList(,0, m_iSlotsStartY, kBG.Width - 20 /* space for scrollbar */, class'UITacticalQuickLaunch_UnitSlot'.default.Height * 4);

	// Load units from GameState
	LoadUnits();
}

simulated private function CreateColumnHeader(string label)
{
	local UIText kText;
	kText = Spawn(class'UIText', m_kContainer).InitText();
	kText.SetText(label).SetPosition(m_iXPositionHelper + 35, 60);
	m_iXPositionHelper += class'UITacticalQuickLaunch_UnitSlot'.default.m_iDropdownWidth;
}

simulated private function AddSlot(UIButton kButton)
{
	local UITacticalQuickLaunch_UnitSlot UnitSlot;
	//if (m_kSoldierList.ItemCount < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
	//{
		UnitSlot = UITacticalQuickLaunch_UnitSlot(m_kSoldierList.CreateItem(class'UITacticalQuickLaunch_UnitSlot')).InitSlot();
		m_kSoldierList.MoveItemToTop(UnitSlot);
		RealizeSlots();
	//}
}

simulated private function RemoveSlot(UIButton kButton)
{
	if(m_kSoldierList.ItemCount > 0)
	{
		m_kSoldierList.GetItem(m_kSoldierList.ItemCount - 1).Remove();
		RealizeSlots();
	}
}

simulated private function NewSquad(UIButton kButton)
{
	m_kSoldierList.ClearItems();
	PurgeGameState();
	LoadUnits();
}

// Called when slots are modified
simulated private function RealizeSlots()
{
	// update button availability
	m_kLaunchButton.SetDisabled(m_kSoldierList.ItemCount == 0);
	m_kRemoveUnitButton.SetDisabled(m_kSoldierList.ItemCount == 0);
	//m_kAddUnitButton.SetDisabled(m_kSoldierList.ItemCount == class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission());
}

simulated private function LaunchTacticalMap(UIButton kButton)
{
	WriteLoadoutToProfile();

	if(!Movie.Stack.IsInStack(class'UITacticalQuickLaunch'))
		ConsoleCommand( GetBattleData().m_strMapCommand );
	else
		Movie.Stack.Pop(self);
}

simulated function WriteLoadoutToProfile()
{
	local int i;
	local UITacticalQuickLaunch_UnitSlot UnitSlot;
	local XComGameState StartState;
	local XComGameState_Player TeamXComPlayer;

	//Find the player associated with the player's team
	foreach GameState.IterateByClassType(class'XComGameState_Player', TeamXComPlayer, eReturnType_Reference)
	{
		if( TeamXComPlayer != None && TeamXComPlayer.TeamFlag == eTeam_XCom )
		{
			break;
		}
	}

	//Obliterate any previously added Units / Items
	PurgeGameState();

	for(i = m_kSoldierList.ItemCount - 1; i >= 0; --i)
	{
		UnitSlot = UITacticalQuickLaunch_UnitSlot(m_kSoldierList.GetItem(i));
		UnitSlot.AddUnitToGameState(GameState, TeamXComPlayer);
	}

	// create a new game state
	StartState = `XCOMHISTORY.CreateNewGameState(false, GameState.GetContext());
	GameState.CopyGameState(StartState);

	//Add the start state to the history
	`XCOMHISTORY.AddGameStateToHistory(StartState);

	Movie.Pres.TacticalStartState = StartState;

	//Write GameState to profile
	`XPROFILESETTINGS.WriteTacticalGameStartState(GameState);

	`ONLINEEVENTMGR.SaveProfileSettings();
}

simulated function LoadUnits()
{
	local bool createdUnits;
	local XComGameState_Unit Unit;
	local UITacticalQuickLaunch_UnitSlot UnitSlot;

	foreach GameState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		UnitSlot = UITacticalQuickLaunch_UnitSlot(m_kSoldierList.CreateItem(class'UITacticalQuickLaunch_UnitSlot'));
		UnitSlot.LoadTemplatesFromCharacter(Unit, GameState); // load template data first, then init
		UnitSlot.InitSlot();
		m_kSoldierList.MoveItemToTop(UnitSlot);
		createdUnits = true;
	}

	// If we don't have stored units, create defaults and reload
	if(!createdUnits)
	{
		class'XComOnlineProfileSettings'.static.AddDefaultSoldiersToStartState(GameState);

		// Make sure that actually loaded some units - if not we'll end up in an infinite loop
		foreach GameState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			createdUnits = true;
			break;
		}
		`assert(createdUnits);

		LoadUnits();
	}
	else
	{
		RealizeSlots();
	}
}

function XComGameState_BattleData GetBattleData()
{
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	return BattleData;
}

// Purge the GameState of any XComGameState_Unit or XComGameState_Item objects
function PurgeGameState()
{
	local int i;
	local array<int> arrObjectIDs;
	local XComGameState_Unit Unit;
	local XComGameState_Item Item;

	// Enumerate objects
	foreach GameState.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		arrObjectIDs.AddItem(Unit.ObjectID);
	}
	foreach GameState.IterateByClassType(class'XComGameState_Item', Item)
	{
		arrObjectIDs.AddItem(Item.ObjectID);
	}
	
	// Purge objects
	for(i = 0 ; i < arrObjectIDs.Length; ++i)
	{
		GameState.PurgeGameStateForObjectID(arrObjectIDs[i]);
	}
}

//-----------------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		if(m_kSoldierList.ItemCount > 0)
			LaunchTacticalMap(none);
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		Movie.Stack.Pop(self);
		break; 
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//-----------------------------------------------------------------------------

simulated function OnRemoved()
{
	super.OnRemoved();
}

//==============================================================================

defaultproperties
{
	InputState    = eInputState_Consume;
	m_iSlotsStartY  = 120;
}
