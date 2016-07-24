//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_StrategyGameRule.uc
//  AUTHOR:  Ryan McFall  --  11/21/2013
//  PURPOSE: Context for game rules such as the game starting, rules engine state changes
//           and replay support.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_StrategyGameRule extends XComGameStateContext;

enum StrategyGameRuleStateChange
{
	eStrategyGameRule_StrategyGameStart,
	eStrategyGameRule_RulesEngineStateChange,   //Called when the strategy rules engine changes to a new phase. See X2StrategyGameRuleset and its states.
	eStrategyGameRule_ReplaySync,               //This informs the system sync all visualizers to an arbitrary state
};

var StrategyGameRuleStateChange GameRuleType;
var name RuleEngineNextState;           //The name of the new state that the rules engine is entering. Can be used for error checking or actually implementing GotoState
var string StrategyMapCommand;

//XComGameStateContext interface
//***************************************************
/// <summary>
/// Should return true if ContextBuildGameState can return a game state, false if not. Used internally and externally to determine whether a given context is
/// valid or not.
/// </summary>
function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

/// <summary>
/// Override in concrete classes to converts the InputContext into an XComGameState
/// </summary>
function XComGameState ContextBuildGameState()
{
	
}

/// <summary>
/// Convert the ResultContext and AssociatedState into a set of visualization tracks
/// </summary>
protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	
}

/// <summary>
/// Override to return TRUE for the XComGameStateContext object to show that the associated state is a start state
/// </summary>
event bool IsStartState()
{
	return GameRuleType == eStrategyGameRule_StrategyGameStart;
}

/// <summary>
/// Returns a short description of this context object
/// </summary>
function string SummaryString()
{
	local string GameRuleString;

	GameRuleString = string(GameRuleType);
	if( RuleEngineNextState != '' )
	{
		GameRuleString = GameRuleString @ "(" @ RuleEngineNextState @ ")";
	}

	return GameRuleString;
}

/// <summary>
/// Returns a string representation of this object.
/// </summary>
function string ToString()
{
	return "";
}
//***************************************************

/// <summary>
/// Returns an XComGameState that is used to launch the X-Com 2 campaign.
/// </summary>
static function XComGameState CreateStrategyGameStart(optional XComGameState StartState, optional bool bSetRandomSeed=true, optional bool bTutorialEnabled=false, 
													  optional int SelectedDifficulty=1, optional bool bSuppressFirstTimeVO=false, optional array<name> EnabledOptionalNarrativeDLC, 
													  optional bool SendCampaignAnalytics=true, optional bool IronManEnabled=false, optional int UseTemplateGameArea=-1, optional bool bSetupDLCContent=true)
{	
	local XComGameStateHistory History;
	local XComGameStateContext_StrategyGameRule StrategyStartContext;
	local Engine LocalGameEngine;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;
	local int Seed;
	local bool NewCampaign;

	NewCampaign = false;
	if( StartState == None )
	{
		History = `XCOMHISTORY;

		StrategyStartContext = XComGameStateContext_StrategyGameRule(class'XComGameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
		StrategyStartContext.GameRuleType = eStrategyGameRule_StrategyGameStart;
		StartState = History.CreateNewGameState(false, StrategyStartContext);
		History.AddGameStateToHistory(StartState);

		NewCampaign = true;
	}

	if (bSetRandomSeed)
	{
		LocalGameEngine = class'Engine'.static.GetEngine();
		Seed = LocalGameEngine.GetARandomSeed();
		LocalGameEngine.SetRandomSeeds(Seed);
	}

	//Create start time
	class'XComGameState_GameTime'.static.CreateGameStartTime(StartState);

	//Create campaign settings
	class'XComGameState_CampaignSettings'.static.CreateCampaignSettings(StartState, bTutorialEnabled, SelectedDifficulty, bSuppressFirstTimeVO, EnabledOptionalNarrativeDLC);

	//Create analytics object
	class'XComGameState_Analytics'.static.CreateAnalytics(StartState, SelectedDifficulty);

	//Create and add regions
	class'XComGameState_WorldRegion'.static.SetUpRegions(StartState);

	//Create and add continents
	class'XComGameState_Continent'.static.SetUpContinents(StartState);

	//Create and add region links
	class'XComGameState_RegionLink'.static.SetUpRegionLinks(StartState);

	//Create and add cities
	class'XComGameState_City'.static.SetUpCities(StartState);

	//Create and add Trading Posts (requires regions)
	class'XComGameState_TradingPost'.static.SetUpTradingPosts(StartState);

	// Create and add Black Market (requires regions)
	class'XComGameState_BlackMarket'.static.SetUpBlackMarket(StartState);

	// Create and add the Resource Cache (requires regions)
	class'XComGameState_ResourceCache'.static.SetUpResourceCache(StartState);

	// Create the POIs
	class'XComGameState_PointOfInterest'.static.SetUpPOIs(StartState, UseTemplateGameArea);
	
	//Create XCom Techs
	class'XComGameState_Tech'.static.SetUpTechs(StartState);

	//Create Resistance HQ
	class'XComGameState_HeadquartersResistance'.static.SetUpHeadquarters(StartState, bTutorialEnabled);

	//Create X-Com HQ (Rooms, Facilities, Initial Staff)
	class'XComGameState_HeadquartersXCom'.static.SetUpHeadquarters(StartState, bTutorialEnabled);

	// Create Dark Events
	class'XComGameState_DarkEvent'.static.SetUpDarkEvents(StartState);

	//Create Alien HQ (Alien Facilities)
	class'XComGameState_HeadquartersAlien'.static.SetUpHeadquarters(StartState);

	// Create Mission Calendar
	class'XComGameState_MissionCalendar'.static.SetupCalendar(StartState);

	// Create Objectives
	class'XComGameState_Objective'.static.SetUpObjectives(StartState);

	// Finish initializing Havens
	class'XComGameState_Haven'.static.SetUpHavens(StartState);

	if (NewCampaign && SendCampaignAnalytics)
	{
		class'AnalyticsManager'.static.SendGameStartTelemetry( History, IronManEnabled );
	}

	if( bSetupDLCContent )
	{
	// Let the DLC / Mods hook the creation of a new campaign
	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].InstallNewCampaign(StartState);
	}
	}

	return StartState;
}

/// <summary>
/// Used to create a strategy game start state from a tactical battle
/// </summary>
static function XComGameState CreateStrategyGameStartFromTactical()
{	
	local XComGameStateHistory History;
	local XComGameState StartState;
	local XComGameStateContext_StrategyGameRule StrategyStartContext;
	local XComGameState PriorStrategyState;
	local int PreStartStateIndex;	
	local int Index, BackpackIndex;
	local int NumStateObjects;
	local XComGameState_BaseObject StateObject, NewStateObject;
	local array<XComGameState_Item> BackpackItems;
	local XComGameState_Item ItemState;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_ObjectivesList ObjectivesList;
	local XComGameState_WorldNarrativeTracker NarrativeTracker;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	//Build a game state that contains the full state of every object that existed in the strategy
	//game session prior to the current tactical match
	PreStartStateIndex = History.FindStartStateIndex() - 1;
	PriorStrategyState = History.GetGameStateFromHistory(PreStartStateIndex, eReturnType_Copy, false);

	//Now create the strategy start state and add it to the history
	StrategyStartContext = XComGameStateContext_StrategyGameRule(class'XComGameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
	StrategyStartContext.GameRuleType = eStrategyGameRule_StrategyGameStart;
	StartState = History.CreateNewGameState(false, StrategyStartContext);
	
			
	//Iterate all the game states in the strategy game state built above and create a new entry in the 
	//start state we are building for each one. If any of the state objects were changed / updated in the
	//tactical battle, their changes are automatically picked up by this process.
	//
	//Caveat: Currently this assumes that the only objects that can return from tactical to strategy are those 
	//which were created in the strategy game. Additional logic will be necessary to transfer NEW objects 
	//created within tactical.
	NumStateObjects = PriorStrategyState.GetNumGameStateObjects();
	for( Index = 0; Index < NumStateObjects; ++Index )
	{
		StateObject = PriorStrategyState.GetGameStateForObjectIndex(Index);

		NewStateObject = StartState.CreateStateObject(StateObject.Class, StateObject.ObjectID);
		StartState.AddStateObject( NewStateObject );

		//  Check units for items in the backpack and move them over as they were created in tactical
		if (StateObject.IsA('XComGameState_Unit'))
		{
			BackpackItems = XComGameState_Unit(StateObject).GetAllItemsInSlot(eInvSlot_Backpack);
			for (BackpackIndex = 0; BackpackIndex < BackpackItems.Length; ++BackpackIndex)
			{
				ItemState = XComGameState_Item(StartState.GetGameStateForObjectID(BackpackItems[BackpackIndex].ObjectID));

				if(ItemState == none)
				{
					XComGameState_Item(StartState.AddStateObject(StartState.CreateStateObject(BackpackItems[BackpackIndex].Class, BackpackItems[BackpackIndex].ObjectID)));
				}				
			}
		}
	}

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	`assert(BattleData.m_iMissionID == XComHQ.MissionRef.ObjectID);
	BattleData = XComGameState_BattleData(StartState.CreateStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	StartState.AddStateObject(BattleData);

	ObjectivesList = XComGameState_ObjectivesList(History.GetSingleGameStateObjectForClass(class'XComGameState_ObjectivesList'));
	ObjectivesList = XComGameState_ObjectivesList(StartState.CreateStateObject(class'XComGameState_ObjectivesList', ObjectivesList.ObjectID));
	StartState.AddStateObject(ObjectivesList);

	// clear completed & failed objectives on transition back to strategy
	ObjectivesList.ClearTacticalObjectives();

	// if we have a narrative tracker, pass it along
	NarrativeTracker = XComGameState_WorldNarrativeTracker(History.GetSingleGameStateObjectForClass(class'XComGameState_WorldNarrativeTracker', true));
	if(NarrativeTracker != none)
	{
		StartState.AddStateObject(StartState.CreateStateObject(class'XComGameState_WorldNarrativeTracker', NarrativeTracker.ObjectID));
	}

	History.AddGameStateToHistory(StartState);

	return StartState;
}

/// <summary>
/// Modify any objects as they come into strategy from tactical
/// e.g. Move backpack items into storage, place injured soldiers in the infirmary, move dead soldiers to the morgue, etc.
/// </summary>
static function CompleteStrategyFromTacticalTransfer()
{
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;
	
	UpdateSkyranger();
	CleanupProxyVips();
	ProcessMissionResults();
	SquadTacticalToStrategyTransfer();
	
	EventManager = `ONLINEEVENTMGR;
	DLCInfos = EventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnPostMission();
	}
}

/// <summary>
/// Return skyranger to the Avenger
/// </summary>
static function UpdateSkyranger()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Skyranger SkyrangerState;

	// Dock Skyranger at HQ
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Dock Skyranger");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SkyrangerState = XComGameState_Skyranger(NewGameState.CreateStateObject(class'XComGameState_Skyranger', XComHQ.SkyrangerRef.ObjectID));
	NewGameState.AddStateObject(SkyrangerState);
	SkyrangerState.Location = XComHQ.Location;
	SkyrangerState.SourceLocation.X = SkyrangerState.Location.X;
	SkyrangerState.SourceLocation.Y = SkyrangerState.Location.Y;
	SkyrangerState.TargetEntity = XComHQ.GetReference();
	SkyrangerState.SquadOnBoard = false;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/// <summary>
/// Removes mission and handles rewards
/// </summary>
static function ProcessMissionResults()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionSite MissionState, FortressMission;
	local X2MissionSourceTemplate MissionSource;
	local bool bMissionSuccess;
	local int idx;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cleanup Mission");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.bReturningFromMission = true;
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', XComHQ.MissionRef.ObjectID));
	NewGameState.AddStateObject(MissionState);
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	FortressMission = AlienHQ.GetFortressMission();

	// Handle tactical objective complete doom removal (should not be any other pending doom at this point)
	for(idx = 0; idx < AlienHQ.PendingDoomData.Length; idx++)
	{
		if(AlienHQ.PendingDoomData[idx].Doom > 0)
		{
			AlienHQ.PendingDoomData[idx].Doom = Clamp(AlienHQ.PendingDoomData[idx].Doom, 0, AlienHQ.GetCurrentDoom(true));
			AlienHQ.AddDoomToFortress(NewGameState, AlienHQ.PendingDoomData[idx].Doom, , false);
			AlienHQ.PendingDoomEntity = FortressMission.GetReference();

			if(AlienHQ.PendingDoomData[idx].DoomMessage != "" && FortressMission.ShouldBeVisible())
			{
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, AlienHQ.PendingDoomData[idx].DoomMessage, true);
			}
			
		}
		else if(AlienHQ.PendingDoomData[idx].Doom < 0)
		{
			AlienHQ.PendingDoomData[idx].Doom = Clamp(AlienHQ.PendingDoomData[idx].Doom, -AlienHQ.GetCurrentDoom(true), 0);
			AlienHQ.RemoveDoomFromFortress(NewGameState, -AlienHQ.PendingDoomData[idx].Doom, , false);
			AlienHQ.PendingDoomEntity = FortressMission.GetReference();

			if(AlienHQ.PendingDoomData[idx].DoomMessage != "" && FortressMission.ShouldBeVisible())
			{
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, AlienHQ.PendingDoomData[idx].DoomMessage, false);
				class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgressReduced', -AlienHQ.PendingDoomData[idx].Doom);
			}
		}
		else
		{
			AlienHQ.PendingDoomData.Remove(idx, 1);
			AlienHQ.PendingDoomEvent = '';
			idx--;
		}
		
	}

	// If accelerating doom, stop
	if(AlienHQ.bAcceleratingDoom)
	{
		AlienHQ.StopAcceleratingDoom();
	}

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleData.m_iMissionID == MissionState.ObjectID);

	MissionSource = MissionState.GetMissionSource();

	// Main objective success/failure hooks
	bMissionSuccess = BattleData.bLocalPlayerWon;

	class'X2StrategyElement_DefaultMissionSources'.static.IncreaseForceLevel(NewGameState, MissionState);

	if( bMissionSuccess )
	{
		if( MissionSource.OnSuccessFn != none )
		{
			MissionSource.OnSuccessFn(NewGameState, MissionState);
		}
	}
	else
	{
		if( MissionSource.OnFailureFn != none )
		{
			MissionSource.OnFailureFn(NewGameState, MissionState);
		}
	}

	// Triad objective success/failure hooks
	if( BattleData.AllTriadObjectivesCompleted() )
	{
		if( MissionSource.OnTriadSuccessFn != none )
		{
			MissionSource.OnTriadSuccessFn(NewGameState, MissionState);
		}
	}
	else
	{
		if( MissionSource.OnTriadFailureFn != none )
		{
			MissionSource.OnTriadFailureFn(NewGameState, MissionState);
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

/// <summary>
/// Modify the squad and related items as they come into strategy from tactical
/// e.g. Move backpack items into storage, place injured soldiers in the infirmary, move dead soldiers to the morgue, etc.
/// </summary>
static function SquadTacticalToStrategyTransfer()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Item> Items;
	local XComGameState_Item ItemState;
	local StateObjectReference DeadUnitRef;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local XComGameState_HeadquartersProjectPsiTraining PsiProjectState;
	local XComGameState_HeadquartersAlien AlienHeadquarters;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot SlotState;
	local array<StateObjectReference> SoldiersToTransfer;
	local int idx, SlotIndex, NewBlocksRemaining, NewProjectPointsRemaining;
	local bool bRemoveItemStatus;
	local StaffUnitInfo UnitInfo;
	local XComGameStateHistory History;
	local X2EventManager EventManager;
	local XComGameState_BattleData BattleData;

	EventManager = `XEVENTMGR;
	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission Squad Cleanup");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	NewGameState.AddStateObject(BattleData);

	// If the unit is in the squad or was spawned from the avenger on the mission, add them to the SoldiersToTransfer array
	SoldiersToTransfer = XComHQ.Squad;
	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		if (XComHQ.Crew[idx].ObjectID != 0)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));
			if (UnitState.bSpawnedFromAvenger)
			{
				SoldiersToTransfer.AddItem(XComHQ.Crew[idx]);
			}
		}
	}

	for( idx = 0; idx < SoldiersToTransfer.Length; idx++ )
	{
		if(SoldiersToTransfer[idx].ObjectID != 0)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', SoldiersToTransfer[idx].ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.iNumMissions++;

			// Bleeding out soldiers die if not rescued, some characters die when captured
			if (UnitState.bBleedingOut || (UnitState.bCaptured && UnitState.GetMyTemplate().bDiesWhenCaptured))
			{
				UnitState.SetCurrentStat(eStat_HP, 0);
			}

			//  Dead soldiers get moved to the DeadCrew list
			if (UnitState.IsDead())
			{
				DeadUnitRef = UnitState.GetReference();
				XComHQ.RemoveFromCrew(DeadUnitRef);
				XComHQ.DeadCrew.AddItem(DeadUnitRef);
				// Removed from squad in UIAfterAction
			}
			else if (UnitState.bCaptured)
			{
				//  Captured soldiers get moved to the AI HQ capture list
				if (AlienHeadquarters == none)
				{
					AlienHeadquarters = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
					AlienHeadquarters = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHeadquarters.ObjectID));
					NewGameState.AddStateObject(AlienHeadquarters);
				}

				XComHQ.RemoveFromCrew(UnitState.GetReference());
				AlienHeadquarters.CapturedSoldiers.AddItem(UnitState.GetReference());
			}

			// If dead or captured remove healing project
			if ((UnitState.IsDead() || UnitState.bCaptured) && UnitState.HasHealingProject())
			{
				foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', ProjectState)
				{
					if (ProjectState.ProjectFocus == UnitState.GetReference())
					{
						XComHQ.Projects.RemoveItem(ProjectState.GetReference());
						NewGameState.RemoveStateObject(ProjectState.ObjectID);
						break;
					}
				}
			}

			// Handle any additional unit transfers events (e.g. Analytics)
			EventManager.TriggerEvent('SoldierTacticalToStrategy', UnitState, , NewGameState);

			//  Unload backpack (loot) items from any live or recovered soldiers
			if (!UnitState.IsDead() || UnitState.bBodyRecovered)
			{
				Items = UnitState.GetAllItemsInSlot(eInvSlot_Backpack, NewGameState);
				foreach Items(ItemState)
				{
					ItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', ItemState.ObjectID));
					NewGameState.AddStateObject(ItemState);

					bRemoveItemStatus = UnitState.RemoveItemFromInventory(ItemState, NewGameState);
					`assert(bRemoveItemStatus);

					ItemState.OwnerStateObject = XComHQ.GetReference();
					XComHQ.PutItemInInventory(NewGameState, ItemState, true);

					BattleData.CarriedOutLootBucket.AddItem(ItemState.GetMyTemplateName());
				}
			}
			//  Recover regular inventory from dead but recovered units.
			if (UnitState.IsDead() && UnitState.bBodyRecovered)
			{
				Items = UnitState.GetAllInventoryItems(NewGameState, true);
				foreach Items(ItemState)
				{
					ItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', ItemState.ObjectID));
					NewGameState.AddStateObject(ItemState);

					if (UnitState.RemoveItemFromInventory(ItemState, NewGameState))           //  possible we'll have some items that cannot be removed, so don't recover them
					{
						ItemState.OwnerStateObject = XComHQ.GetReference();
						XComHQ.PutItemInInventory(NewGameState, ItemState, false); // Recovered items from recovered units goes directly into inventory, doesn't show on loot screen

						//BattleData.CarriedOutLootBucket.AddItem(ItemState.GetMyTemplateName());
					}
				}
			}

			// Tactical to Strategy transfer code which may be unique on a per-class basis
			if (!UnitState.GetSoldierClassTemplate().bUniqueTacticalToStrategyTransfer)
			{
				// Start healing injured soldiers
				if (!UnitState.IsDead() && !UnitState.bCaptured && UnitState.IsInjured() && UnitState.GetStatus() != eStatus_Healing)
				{
					UnitState.SetStatus(eStatus_Healing);

					if (!UnitState.HasHealingProject())
					{
						ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
						NewGameState.AddStateObject(ProjectState);
						ProjectState.SetProjectFocus(UnitState.GetReference(), NewGameState);
						XComHQ.Projects.AddItem(ProjectState.GetReference());
					}
					else
					{
						foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', ProjectState)
						{
							if (ProjectState.ProjectFocus == UnitState.GetReference())
							{								
								NewBlocksRemaining = UnitState.GetBaseStat(eStat_HP) - UnitState.GetCurrentStat(eStat_HP);
								if (NewBlocksRemaining > ProjectState.BlocksRemaining) // The unit was injured again, so update the time to heal
								{
									ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectHealSoldier', ProjectState.ObjectID));
									NewGameState.AddStateObject(ProjectState);

									// Calculate new wound length again, but ensure it is greater than the previous time, since the unit is more injured
									NewProjectPointsRemaining = ProjectState.GetWoundPoints(UnitState, ProjectState.ProjectPointsRemaining);

									ProjectState.ProjectPointsRemaining = NewProjectPointsRemaining;
									ProjectState.BlocksRemaining = NewBlocksRemaining;
									ProjectState.PointsPerBlock = Round(float(NewProjectPointsRemaining) / float(NewBlocksRemaining));
									ProjectState.BlockPointsRemaining = ProjectState.PointsPerBlock;
									ProjectState.UpdateWorkPerHour();
									ProjectState.StartDateTime = `STRATEGYRULES.GameTime;
									ProjectState.SetProjectedCompletionDateTime(ProjectState.StartDateTime);
								}

								break;
							}
						}
					}

					// If a soldier is gravely wounded, roll to see if they are shaken
					if (UnitState.IsGravelyInjured(ProjectState.GetCurrentNumHoursRemaining()) && !UnitState.bIsShaken && !UnitState.bIsShakenRecovered)
					{
						if (class'X2StrategyGameRulesetDataStructures'.static.Roll(XComHQ.GetShakenChance()))
						{
							UnitState.bIsShaken = true;
							UnitState.bSeenShakenPopup = false;

							//Give this unit a random scar if they don't have one already
							if (UnitState.kAppearance.nmScars == '')
							{
								UnitState.GainRandomScar();
							}

							UnitState.SavedWillValue = UnitState.GetBaseStat(eStat_Will);
							UnitState.SetBaseMaxStat(eStat_Will, 0);
						}
					}
				}

				if (!UnitState.IsDead() && !UnitState.bCaptured && UnitState.bIsShaken)
				{
					if (!UnitState.IsInjured()) // This unit was shaken but survived the mission unscathed. Check to see if they have recovered.
					{
						UnitState.MissionsCompletedWhileShaken++;
						if ((UnitState.UnitsKilledWhileShaken > 0) || (UnitState.MissionsCompletedWhileShaken >= XComHQ.GetShakenRecoveryMissions()))
						{
							//This unit has stayed healthy and killed some bad dudes, or stayed healthy for multiple missions in a row --> no longer shaken
							UnitState.bIsShaken = false;
							UnitState.bIsShakenRecovered = true;
							UnitState.bNeedsShakenRecoveredPopup = true;

							// Give a bonus to will (free stat progression roll) for recovering
							UnitState.SetBaseMaxStat(eStat_Will, UnitState.SavedWillValue + XComHQ.XComHeadquarters_ShakenRecoverWillBonus + `SYNC_RAND_STATIC(XComHQ.XComHeadquarters_ShakenRecoverWillRandBonus));
						}
					}
					else // The unit was injured on a mission while they were shaken. Reset counters. (This will also be called to init the values after shaken is set)
					{
						UnitState.MissionsCompletedWhileShaken = 0;
						UnitState.UnitsKilledWhileShaken = 0;
					}
				}

				// If the Psi Operative was training an ability before the mission continue the training automatically, or delete the project if they died
				if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
				{
					PsiProjectState = XComHQ.GetPsiTrainingProject(UnitState.GetReference());
					if (PsiProjectState != none) // A paused Psi Training project was found for the unit
					{
						if (UnitState.IsDead() || UnitState.bCaptured) // The unit died or was captured, so remove the project
						{
							XComHQ.Projects.RemoveItem(PsiProjectState.GetReference());
							NewGameState.RemoveStateObject(PsiProjectState.ObjectID);
						}
						else if (!UnitState.IsInjured()) // If the unit is uninjured, restart the training project automatically
						{
							// Get the Psi Chamber facility and staff the unit in it if there is an open slot
							FacilityState = XComHQ.GetFacilityByName('PsiChamber'); // Only one Psi Chamber allowed, so safe to do this

							for (SlotIndex = 0; SlotIndex < FacilityState.StaffSlots.Length; ++SlotIndex)
							{
								//If this slot has not already been modified (filled) in this tactical transfer, check to see if it's valid
								SlotState = XComGameState_StaffSlot(NewGameState.GetGameStateForObjectID(FacilityState.StaffSlots[SlotIndex].ObjectID));
								if (SlotState == None)
								{
									SlotState = FacilityState.GetStaffSlot(SlotIndex);

									// If this is a valid soldier slot in the Psi Lab, restaff the soldier and restart their training project
									if (!SlotState.IsLocked() && SlotState.IsSlotEmpty() && SlotState.IsSoldierSlot())
									{
										// Restart the paused training project
										PsiProjectState = XComGameState_HeadquartersProjectPsiTraining(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectPsiTraining', PsiProjectState.ObjectID));
										NewGameState.AddStateObject(PsiProjectState);
										PsiProjectState.bForcePaused = false;

										UnitInfo.UnitRef = UnitState.GetReference();
										SlotState.FillSlot(NewGameState, UnitInfo);

										break;
									}
								}
							}
						}
					}
				}
			}
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission Set Grade");
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	NewGameState.AddStateObject(BattleData);
	BattleData.SetPostMissionGrade();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}


static function CleanupProxyVips()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit OriginalUnit;
	local XComGameState_Unit ProxyUnit;
	local XComGameState NewGameState;
	local int Index;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// cleanup VIP proxies. If the proxy dies, then the original, real unit must also die
	for (Index = 0; Index < BattleData.RewardUnits.Length; Index++)
	{
		OriginalUnit = XComGameState_Unit(History.GetGameStateForObjectID(BattleData.RewardUnitOriginals[Index].ObjectID));
		ProxyUnit = XComGameState_Unit(History.GetGameStateForObjectID(BattleData.RewardUnits[Index].ObjectID));

		// If we never made a proxy (or it's an older save before proxies were a thing), just skip this unit.
		// we don't need to do anything if the player played the mission with the original unit
		if(OriginalUnit == none || OriginalUnit.ObjectID == ProxyUnit.ObjectID)
		{
			continue;
		}
		
		if(NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission VIP Proxy Cleanup");
		}

		// if the proxy dies, the original unit must also die
		if(ProxyUnit.IsDead())
		{
			OriginalUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OriginalUnit.ObjectID));
			OriginalUnit.SetCurrentStat(eStat_HP, 0);
			NewGameState.AddStateObject(OriginalUnit);
		}
		else if(OriginalUnit.IsSoldier() && ProxyUnit.IsInjured())
		{
			OriginalUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OriginalUnit.ObjectID));
			OriginalUnit.SetCurrentStat(eStat_HP, ProxyUnit.GetCurrentStat(eStat_HP));
			NewGameState.AddStateObject(OriginalUnit);
		}

		// remove the proxy from the game. We don't need it anymore
		NewGameState.RemoveStateObject(ProxyUnit.ObjectID);
	}

	if(NewGameState != none)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

// Called in UIAfterAction
static function RemoveInvalidSoldiersFromSquad()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local StateObjectReference DeadUnitRef, EmptyRef;
	local GeneratedMissionData MissionData;
	local int SquadIndex;
	local array<name> SpecialSoldierNames;
	local array<EInventorySlot> SpecialSoldierSlotsToClear, SlotsToClear, LockedSlots;
	local EInventorySlot LockedSlot;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	SpecialSoldierNames = MissionData.Mission.SpecialSoldiers;

	SpecialSoldierSlotsToClear.AddItem(eInvSlot_Armor);
	SpecialSoldierSlotsToClear.AddItem(eInvSlot_PrimaryWeapon);
	SpecialSoldierSlotsToClear.AddItem(eInvSlot_SecondaryWeapon);
	SpecialSoldierSlotsToClear.AddItem(eInvSlot_HeavyWeapon);
	SpecialSoldierSlotsToClear.AddItem(eInvSlot_Utility);
	SpecialSoldierSlotsToClear.AddItem(eInvSlot_GrenadePocket);
	SpecialSoldierSlotsToClear.AddItem(eInvSlot_AmmoPocket);
	
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		DeadUnitRef = UnitState.GetReference();
		SquadIndex = XComHQ.Squad.Find('ObjectID', DeadUnitRef.ObjectID);

		if(SquadIndex != INDEX_NONE || UnitState.bSpawnedFromAvenger)
		{
			// Cleanse Status effects
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.bUnconscious = false;
			UnitState.bBleedingOut = false;
			UnitState.bSpawnedFromAvenger = false;

			if(SquadIndex != INDEX_NONE && (UnitState.IsDead() || (UnitState.IsInjured() && !UnitState.IgnoresInjuries()) || UnitState.bCaptured || SpecialSoldierNames.Find(UnitState.GetMyTemplateName()) != INDEX_NONE))
			{
				// Remove them from the squad
				XComHQ.Squad[SquadIndex] = EmptyRef;

				// Have any special soldiers drop unique items they were given before the mission
				if (SpecialSoldierNames.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
				{
					// Reset SlotsToClear
					SlotsToClear.Length = 0;
					SlotsToClear = SpecialSoldierSlotsToClear;

					// Find the slots which are uneditable for this soldier, and remove those from the list of slots to clear
					LockedSlots = UnitState.GetSoldierClassTemplate().CannotEditSlots;
					foreach LockedSlots(LockedSlot)
					{
						if (SlotsToClear.Find(LockedSlot) != INDEX_NONE)
						{
							SlotsToClear.RemoveItem(LockedSlot);
						}
					}

					UnitState.MakeItemsAvailable(NewGameState, false, SlotsToClear);
					UnitState.bIsShaken = false;
				}
			}
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// Called in UIInventory_LootRecovered
static function AddLootToInventory()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local int idx;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Mission Loot");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	for(idx = 0; idx < XComHQ.LootRecovered.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.LootRecovered[idx].ObjectID));

		if(ItemState != none)
		{
			ItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', XComHQ.LootRecovered[idx].ObjectID));
			NewGameState.AddStateObject(ItemState);
			XComHQ.PutItemInInventory(NewGameState, ItemState);
		}
	}

	XComHQ.LootRecovered.Length = 0;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

defaultproperties
{
	StrategyMapCommand = "servertravel Avenger_Root?game=XComGame.XComHeadQuartersGame"
}
