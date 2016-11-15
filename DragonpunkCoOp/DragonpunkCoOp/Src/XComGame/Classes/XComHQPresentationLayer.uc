class XComHQPresentationLayer extends XComPresentationLayerBase;

var XGHQCamera						m_kCamera;
var XComStrategyMap                 m_kXComStrategyMap;

// X2 Screens
var UIAvengerHUD					m_kAvengerHUD;
var UIFacilityGrid				    m_kFacilityGrid;

var UIStrategyMap	            StrategyMap2D;

var bool m_bCanPause;    // Can the user pause the game?
var bool m_bIsShuttling; // Are we currently shuttling from one location to another via the UI navigation? 
var bool m_bInstantTransition; // Cached var when promoting a gifted soldier that hasn't yet seen the psi-promote dialog
var bool m_bWasScanning; // Used for doom camera pan effect
var bool m_bBlockNarrative; // Flag to block narrative triggers when entering or exiting the Geoscape
var bool m_bEnableFlightModeAfterStrategyMapEnter; // Used to enable flight mode as soon as the Strategy Map is created
var bool m_bDelayGeoscapeEntryEvent; // Is the Geoscape entry event being delayed
var bool m_bShowSupplyDropReminder; // Show the Supply Drop reminder upon Geoscape entry?
var bool m_bRecentStaffAvailable; // Flag if staff were recently made available, so ignore warnings
var bool m_bExitFromSimCombat; // If ExitPostMissionSequence() is occuring from a Sim Combat

var private array<StateObjectReference> NewCrewMembers;
var private array<XGScreenMgr>  m_arrScreenMgrs;  // DEPRECATED - REMOVE

var private float ForceCameraInterpTime; //Designed to be used with Push/Pop Camera interp time methods so that instant camera cuts can be enforced. Too many independent systems call in to these methods.

// keep track of which avenger room we are currently zoomed into
var private StateObjectReference CurrentFacilityRef; // For triggering on enter events after a timer, not reliable to query current room
var private StateObjectReference CICRoomRef;
var private Vector2D DoomEntityLoc; // for doom panning

var localized string m_strPsiPromoteDialogTitle;
var localized string m_strPsiPromoteDialogText;
var localized string m_strPsiPromoteNoSpaceDialogTitle;
var localized string m_strPsiPromoteNoSpaceDialogText;
var localized string m_strResearchReportTitle;
var localized string m_strResearchCodenameLabel;
var localized string m_strNewResearchLabel;
var localized string m_strNewItemsLabel;
var localized string m_strNewFacilitiesLabel;
var localized string m_strPauseShadowProjectLabel;
var localized string m_strPauseShadowProjectText;
var localized string m_strShadowProjectInProgressLabel;
var localized string m_strShadowProjectInProgressText;
var localized string m_strRoomLockedLabel;
var localized string m_strRoomLockedText;

// Preview build strings
var localized string m_strPreviewBuildTitle;
var localized string m_strPreviewBuildText;

// ParabolicFacilityTransition means we are moving from one facility to another in a camera swoop,
// in a parabolic fashion, with the 'Base' camera position in the middle.  It is required to
// look up the second facility we are moving to, so we can pre-calculate our camera path.
var private bool					  m_bParabolic;						// Means we're in a facility-to-base-to-facility parabolic camera movement, as opposed to a linear movement (such 'base' to facility).
enum ParabolicFacilityTransitionType
{
	FTT_None,                                                           // Camera is not performing a parabolic transition.
	FTT_Parabolic_In,                                                   // Moving from facility to 'base' in a facility-to-base-to-facility camera movement.  (The first half of the parabola.)
	FTT_Parabolic_Out,                                                  // Moving from 'base' to facility in a facility-to-base-to-facility camera movement.
};
var private ParabolicFacilityTransitionType	m_eParabolicFacilityTransitionType;	

var private bool m_bGeoscapeTransition; // Transitions from base to strategy map, or strategy map to base, require special camera transitions.

var private vector					  m_ParabolicFacilityTransition_Focus;
var private rotator				 	  m_ParabolicFacilityTransition_Rotation;
var private float				 	  m_ParabolicFacilityTransition_ViewDistance;
var private float				 	  m_ParabolicFacilityTransition_FOV;
var private PostProcessSettings  	  m_ParabolicFacilityTransition_PPSettings;
var private float				 	  m_ParabolicFacilityTransition_PPOverrideAlpha;

// We queue narrative events (that play trigger fades and movies) so they wait until a camera swoop is finished.
struct QueuedNarrative
{
	var XComGameState_Objective Objective;
	var Object EventData;
	var Object EventSource;
	var XComGameState GameState;
	var Name EventID;

};
var private array<QueuedNarrative> m_QueuedNarratives;

// We queue the expanding of the UIAvengerShortcuts list until the camera reaches the destination room.
struct QueuedListExpansion
{
	var int eCat;           // The index of the category tab.
	var bool bShow;         // If true, we are queuing a show; otherwise, we are queuing a hide.
	var bool bAllShortcuts; // If true, show or hide all shortcuts; if false, just show or hide the list.
};
var private array<QueuedListExpansion> m_QueuedListExpansions;
var private bool m_bQueueListExpansion; // Whether to queue list expansion or not - depends on whether the same or a different tab was selected.

// We queue screen movies (UIScreens with the Flash movie) to not load and initialize until the camera transition finishes, to prevent camera transition hitches.
struct QueuedScreenMovie
{
	var UIFacility Facility;
	var UIMovie Movie;
};
var private array<QueuedScreenMovie> m_QueuedScreenMovies;
var bool m_bAvengerListExpansionDone; // Trigger when the Avenger shortcut list expansion is done.

var float fCameraSwoopDelayTime; // Delay after a bumper is pressed, before the parabolic camera swoop begins.

var StaticMesh m_overworldCursorMesh;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             INITIALIZATION
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function Init()
{
	local Object SelfObject;

	super.Init();

	m_kCamera = Spawn( class'XGHQCamera', Owner );
	m_kXComStrategyMap = Spawn( class'XComStrategyMap', Owner );

	Init3DDisplay();
	ScreenStack.Show();

	SelfObject = self;
	`XEVENTMGR.RegisterForEvent(SelfObject, 'NewCrewNotification', NewCrewAdded, ELD_OnStateSubmitted);

	// create music object	
	//`CONTENT.RequestObjectAsync("SoundStrategyCollection.HQSoundCollection", self, OnSoundCollectionLoaded);
}

function EventListenerReturn NewCrewAdded(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit CrewUnit;

	CrewUnit = XComGameState_Unit(EventData);
	if (CrewUnit != None)
		NewCrewMembers.AddItem(CrewUnit.GetReference());

	return ELR_NoInterrupt;
}
// Called from InterfaceMgr when it's ready to rock..
simulated function InitUIScreens()
{
	`log("XComHQPresentationLayer.InitUIScreens()",,'uixcom');

	// NO narrative manager in multiplayer games! -tsmith
	// Need this initialized immediately
	if(WorldInfo.NetMode == NM_Standalone)
	{
		m_kNarrativeUIMgr = new(self) class'UINarrativeMgr';
	}

	// Poll until game data is ready.
	SetTimer( 0.2, true, 'PollForUIScreensComplete');
}

simulated function PollForUIScreensComplete()
{
	local XGStrategy kStrategy;

	kStrategy = `Game;

	m_bIsGameDataReady = kStrategy != none && `XPROFILESETTINGS != none;

	if ( m_bIsGameDataReady  )
	{
		ClearTimer( 'PollForUIScreensComplete' );
		InitUIScreensComplete();
	}
}

simulated function InitUIScreensComplete()
{
	super.InitUIScreens();
	UIWorldMessages();
	m_bPresLayerReady = true;
}

simulated function bool IsBusy()
{
	return (CAMIsBusy() || !Get2DMovie().bIsInited || !IsPresentationLayerReady());
}

event Destroyed( )
{
	local Object SelfObject;

	super.Destroyed( );

	SelfObject = self;
	`XEVENTMGR.UnRegisterFromEvent(SelfObject, 'NewCrewNotification');
}

simulated event OnCleanupWorld( )
{
	local Object SelfObject;

	super.OnCleanupWorld( );

	SelfObject = self;
	`XEVENTMGR.UnRegisterFromEvent(SelfObject, 'NewCrewNotification');
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                              UI INTERFACE
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function ClearToFacilityMainMenu(optional bool bInstant = false)
{
	local UIFacilityGrid kScreen;
	m_kFacilityGrid.DeactivateGrid();
	m_kAvengerHUD.FacilityHeader.Hide();
	kScreen = UIFacilityGrid(ScreenStack.GetScreen(class'UIFacilityGrid'));
	kScreen.bInstantInterp = bInstant;
	ScreenStack.PopUntilClass(class'UIFacilityGrid', true);
}

simulated function ClearUIToHUD(optional bool bInstant = true)
{
	//Clear any screens, like alerts, off the strategy map first. 
	ScreenStack.PopUntilClass(class'UIStrategyMap', false);

	// Now let the map exit properly. 
	if(ScreenStack.IsInStack(class'UIStrategyMap'))
	{
		m_bBlockNarrative = true;
		ExitStrategyMap(false);
	}

	//And finish the clear. 
	ClearToFacilityMainMenu(bInstant);
}

simulated private function XComStrategySoundManager GetSoundMgr() 
{ 
	return `XSTRATEGYSOUNDMGR; 
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                                  X2 UI
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function ExitPostMissionSequence()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2EventManager EventManager;
	local XComOnlineEventMgr OnlineEventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Mission ID");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.MissionRef.ObjectID = 0;
	NewGameState.AddStateObject(XComHQ);
	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent('PostMissionDone', XComHQ, XComHQ, NewGameState);
	XComHQ.ResetToDoWidgetWarnings();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	//Communication with the matinee controlling the camera
	`XCOMGRI.DoRemoteEvent('PostMissionDone');
	
	// Hack to get around unnecessary actor (InterpActor_5) existing in CIN_PostMission1.umap, which pops into view for a few frames.
	// TODO KD: Revert this change and remove the actor from the map in a future patch.
	`GAME.GetGeoscape().m_kBase.SetPostMissionSequenceVisibility(false);
	if (m_bExitFromSimCombat)
	{
		m_bExitFromSimCombat = false;

		//Set a timer that will reset the post mission map. Used to avoid conflict with the PostMissionDone remote event.
		SetTimer(`HQINTERPTIME, false, nameof(ExitPostMission_ResetMap));
	}

	// Return to the Avenger
	`XSTRATEGYSOUNDMGR.PlayBaseViewMusic();
	ClearToFacilityMainMenu();

	DisplayWarningPopups();

	// Queue new staff popup if any have been received
	DisplayNewStaffPopupIfNeeded();

	// If any soldiers are now shaken or recovered from shaken, call it out
	DisplayShakenSoldierPopups();

	// If our force is understrength, warn the player
	if (!XComHQ.AnyTutorialObjectivesInProgress() && XComHQ.GetNumberOfDeployableSoldiers() < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
	{ 
		UIForceUnderstrength();
	}

	if (!XComHQ.bHasSeenSupplyDropReminder && XComHQ.IsSupplyDropAvailable())
	{
		m_bShowSupplyDropReminder = true;
	}
	
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshFacilityPatients();
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshMemorialPolaroids();
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RefreshWantedCaptures();

	OnlineEventManager = `ONLINEEVENTMGR;
	DLCInfos = OnlineEventManager.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].OnExitPostMissionSequence();
	}
}

private function ExitPostMission_ResetMap()
{
	`GAME.GetGeoscape().m_kBase.ResetPostMissionMap(); //Reset the post mission map so that sim combat can run it over and over without issue
}

simulated function SetFacilityBuildPreviewVisibility(int MapIndex, name TemplateName, bool bVisible)
{
	`GAME.GetGeoscape().m_kBase.SetFacilityBuildPreviewVisibility(MapIndex, TemplateName, bVisible);
}

simulated function DisplayNewStaffPopupIfNeeded()
{
	local StateObjectReference NewCrewRef;
	
	foreach NewCrewMembers(NewCrewRef)
	{
		UINewStaffAvailable(NewCrewRef, true);
	}
	NewCrewMembers.Length = 0;
}

simulated function DisplayShakenSoldierPopups()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> UnitStates;
	local int idx;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (XComHQ.NeedSoldierShakenPopup(UnitStates))
	{
		for (idx = 0; idx < UnitStates.Length; idx++)
		{
			UnitState = UnitStates[idx];

			if (UnitState.bIsShaken && !UnitState.bSeenShakenPopup)
			{
				UISoldierShaken(UnitState);
			}
			else if (UnitState.bNeedsShakenRecoveredPopup)
			{
				UISoldierShakenRecovered(UnitState);
			}
		}
	}
}

simulated function DisplayWarningPopups()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime StartDateTime, CurrentTime;
	local int MinStaffRequired, NumStaff, MonthsDifference;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (!XComHQ.bHasSeenLowSuppliesPopup && XComHQ.GetSupplies() < 50)
	{
		UILowSupplies();
	}

	if (!XComHQ.bHasSeenLowIntelPopup && XComHQ.GetIntel() < class'UIUtilities_Strategy'.static.GetMinimumContactCost() && XComHQ.IsContactResearched())
	{
		UILowIntel();
	}

	// Calculate how many months have passed
	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	MonthsDifference = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime);
	
	// Only give staff warnings after the first month
	if (MonthsDifference > 0)
	{
		// If the scientist or engineer numbers are below the minimum expected values for this point in the game, give a warning
		MinStaffRequired = XComHQ.StartingScientistMinCap[`DIFFICULTYSETTING] + (XComHQ.ScientistMinCapIncrease[`DIFFICULTYSETTING] * MonthsDifference);
		NumStaff = XComHQ.GetNumberOfScientists();
		if (NumStaff < XComHQ.ScientistNeverWarnThreshold[`DIFFICULTYSETTING] && NumStaff < MinStaffRequired && class'X2StrategyGameRulesetDataStructures'.static.LessThan(XComHQ.LowScientistPopupTime, `STRATEGYRULES.GameTime))
		{
			// Reset the scientist popup timer
			XComHQ.ResetLowScientistsPopupTimer();

			if (!XComHQ.bHasSeenLowScientistsPopup)
			{
				UILowScientists();
			}
			else
			{
				UILowScientistsSmall();
			}
		}

		MinStaffRequired = XComHQ.StartingEngineerMinCap[`DIFFICULTYSETTING] + (XComHQ.EngineerMinCapIncrease[`DIFFICULTYSETTING] * MonthsDifference);
		NumStaff = XComHQ.GetNumberOfEngineers();
		if (NumStaff < XComHQ.EngineerNeverWarnThreshold[`DIFFICULTYSETTING] && NumStaff < MinStaffRequired && class'X2StrategyGameRulesetDataStructures'.static.LessThan(XComHQ.LowEngineerPopupTime, `STRATEGYRULES.GameTime))
		{
			// Reset the engineer popup timer
			XComHQ.ResetLowEngineersPopupTimer();

			if (!XComHQ.bHasSeenLowEngineersPopup)
			{
				UILowEngineers();
			}
			else
			{
				UILowEngineersSmall();
			}
		}
	}
}

//----------------------------------------------------
// STRATEGY MAP + HUD
//----------------------------------------------------
//bTransitionFromSideView is TRUE when we want to perform a smooth fly-in from the side view to the map view
function UIEnterStrategyMap(bool bSmoothTransitionFromSideView = false)
{
	m_bCanPause = false; // Do not let the player pause the game during the map transition

	if (!bSmoothTransitionFromSideView)
	{
		StrategyMap_FinishTransitionEnter();
	}
	else
	{
		//Find the CIC facility and start the camera transitioning to the starting point for 
		//for the matinee driven smooth transition
		`HQPRES.CAMLookAtRoom(GetCICRoom(), `HQINTERPTIME);

		//Set a timer that will fire when the camera has finished moving to the CIC
		SetTimer(`HQINTERPTIME, false, nameof(StrategyMap_StartTransitionEnter));
	}
	
	m_kAvengerHUD.ClearResources();
	m_kAvengerHUD.HideEventQueue();
	m_kFacilityGrid.Hide();
	m_kAvengerHUD.Shortcuts.Hide();
	m_kAvengerHUD.ToDoWidget.Hide();
}

private function StrategyMap_StartTransitionEnter()
{
	//Register to be a listener for remote events - a remote event will let us know when the matinee is done
	WorldInfo.RemoteEventListeners.AddItem(self);

	//Now that we are in the reference position in front of the CIC, start the smooth transition matinee
	//This puts the camera into cinematic mode
	`XCOMGRI.DoRemoteEvent('CIN_TransitionToMap');	
}

event OnRemoteEvent(name RemoteEventName)
{
	super.OnRemoteEvent(RemoteEventName);

	//Watch for the signal that the transition matinee is finished
	if (RemoteEventName == 'FinishedTransitionIntoMap')
	{
		WorldInfo.RemoteEventListeners.RemoveItem(self);

		//The camera and transition effects are done, fire up the strategy map now
		StrategyMap_FinishTransitionEnter();
	}
	else if (RemoteEventName == 'FinishedTransitionFromMap')
	{
		WorldInfo.RemoteEventListeners.RemoveItem(self);

		//Make sure the strategy game UI is not showing at this point
		if (StrategyMap2D != none)
			StrategyMap2D.Hide();

		//Instantly set the camera position to the CIC room position, then run a normal transition back to the grid view
		`HQPRES.CAMLookAtRoom(GetCICRoom(), 0);

		//Let the game tick to set the camera position, then wrap it up
		SetTimer(0.1f, false, nameof(StrategyMap_StartTransitionExit));
	}
	else if( RemoteEventName == 'CIN_CouncilMovieComplete' )
	{
		ShowUIForCinematics();
		m_kUIMouseCursor.Show();
		m_kAvengerHUD.Movie.Stack.PopFirstInstanceOfClass(class'UIFacility', false);
		PlayUISound(eSUISound_MenuClose);
	}
}

private function StrategyMap_FinishTransitionEnter()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_MissionCalendar CalendarState;
	local XComGameState_MissionSite MissionState;

	//Load map first, underneath the HUD.
	StrategyMap2D = Spawn(class'UIStrategyMap', self);
	ScreenStack.Push(StrategyMap2D);
	

	GetCamera().ForceEarthViewImmediately(true);
	`XSTRATEGYSOUNDMGR.PlayGeoscapeMusic();

	`GAME.GetGeoscape().m_kBase.UpdateFacilityProps();

	//Trigger the base crew to update their positions now that we know we aren't looking at them
	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.PopulateBaseRoomsWithCrew();

	m_kXComStrategyMap.EnterStrategyMap();
	m_kXComStrategyMap.UpdateVisuals();

	GetMgr(class'XGMissionControlUI').UpdateView();

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(XComHQ.bXComFullGameVictory || AlienHQ.bAlienFullGameVictory)
	{
		StrategyMap2D.SetUIState(eSMS_Flight);
		return;
	}
	if(XComHQ.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') == eObjectiveState_InProgress)
	{
		// Need to see GOp on the map
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Spawn First Tutorial GOP");
		CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
		CalendarState = XComGameState_MissionCalendar(NewGameState.CreateStateObject(class'XComGameState_MissionCalendar', CalendarState.ObjectID));
		NewGameState.AddStateObject(CalendarState);
		CalendarState.Update(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(XComHQ.StartingRegion.ObjectID));
		XComHQ.SetPendingPointOfTravel(RegionState, true);
	}
	else if(XComHQ.bNeedsToSeeFinalMission)
	{
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.GetMissionSource().DataName == 'MissionSource_Final')
			{
				break;
			}
		}

		OnMissionSelected(MissionState, true);
	}
	else
	{
		if (StrategyMap2D.HasLastSelectedMapItem())
		{
			StrategyMap2D.SelectLastSelectedMapItem();
		}
		else
		{
			`EARTH.SetViewLocation(XComHQ.Get2DLocation());
		}
	}
	
	if (m_bEnableFlightModeAfterStrategyMapEnter)
	{
		StrategyMap2D.SetUIState(eSMS_Flight);
		m_bEnableFlightModeAfterStrategyMapEnter = false;
	}

	//Set a timer that will fire when the camera has finished moving to the CIC
	SetTimer(`HQINTERPTIME, false, nameof(StrategyMap_TriggerGeoscapeEntryEvent));

	m_bCanPause = true; // The player can pause the game again
}

private function StrategyMap_TriggerGeoscapeEntryEvent()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XGGeoscape kGeoscape;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	kGeoscape = `GAME.GetGeoscape();
	
	if(!XComHQ.bNeedsToSeeFinalMission)
	{
		kGeoscape.Resume();

		// First check if we need to show doom stuff
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHQ.Update(true);
		History = `XCOMHISTORY;
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

		if(AlienHQ.PendingDoomData.Length > 0)
		{
			m_bDelayGeoscapeEntryEvent = true;
			AlienHQ.HandlePendingDoom();
		}
		else
		{
			GeoscapeEntryEvent();
		}
	}
	EndGeoscapeCameraTransition();
}

function DisableFlightModeAndTriggerGeoscapeEvent()
{
	StrategyMap2D.SetUIState(eSMS_Default);
	GeoscapeEntryEvent();
}

function GeoscapeEntryEvent()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_CampaignSettings CampaignState;
	local XComGameState NewGameState;

	// Use this event if something should be triggered after the Geoscape finishes loading (Ex: Camera pans to reveal missions)
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Entered Geoscape Event");
	`XEVENTMGR.TriggerEvent('OnGeoscapeEntry', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	History = `XCOMHISTORY;
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	if( !ResHQ.bFirstPOISpawned )
	{
		CampaignState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		if( CampaignState.bSuppressFirstTimeNarrative || ResHQ.bFirstPOIActivated )
		{
			// When beginner VO is turned off, trigger the event to spawn a POI the first time the player enters the Geoscape
			// When beginner VO is enabled, check to see if Central's dialogue has been completed, and spawn POI if it has, because it wasn't generated for some reason
			ResHQ.AttemptSpawnRandomPOI();
		}
		else
		{
			// Central's dialogue has not been completed yet, so flag ResHQ as activated so if the POI doesn't spawn, it will on the next Geoscape entry
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Flag ResHQ First POI Activated");
			ResHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
			NewGameState.AddStateObject(ResHQ);
			ResHQ.bFirstPOIActivated = true;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}

	m_bBlockNarrative = false; // Turn off the narrative block in case it never got reset
	m_bRecentStaffAvailable = false; // Turn off the recent staff available block
	m_bDelayGeoscapeEntryEvent = false;

	if (m_bShowSupplyDropReminder)
	{
		UISupplyDropReminder();
		m_bShowSupplyDropReminder = false;
	}
}

function ExitStrategyMap(bool bSmoothTransitionFromSideView = false)
{
	BeginGeoscapeCameraTransition();
	m_kXComStrategyMap.ExitStrategyMap();
	
	m_bCanPause = false; // Do not let the player cause the game during the exit transition

	if (!bSmoothTransitionFromSideView)
	{
		StrategyMap_FinishTransitionExit();
	}
	else
	{
		//Register to be a listener for remote events - a remote event will let us know when the matinee is done
		WorldInfo.RemoteEventListeners.AddItem(self);

		//Fire off the matinee transition out of the map view
		`XCOMGRI.DoRemoteEvent('CIN_TransitionFromMap');
	}
}

private function StrategyMap_StartTransitionExit()
{
	//Start the transition back to the base side view camera
	CAMLookAtNamedLocation("Base", `HQINTERPTIME);
	
	//The camera and transition effects are done, fire up the strategy map now
	SetTimer(`HQINTERPTIME, false, nameof(StrategyMap_FinishTransitionExit));
}

private function StrategyMap_FinishTransitionExit()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComWeatherControl WeatherActor;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStop");

	// We need to specifically show the elements hidden during the camera transition, because the stack changes already happened 
	// while the camera moved, and so the UI elements wouldn't get a trigger to update. 
	m_kFacilityGrid.Show();
	m_kAvengerHUD.Show();
	
	`GAME.GetGeoscape().Pause();

	m_bCanPause = true; // Allow the player to pause the game again

	// Need to update the static depth texture for the current weather actor to make sure the avenger gets rendered to it
	foreach `XWORLDINFO.AllActors(class'XComWeatherControl', WeatherActor)
	{
		WeatherActor.UpdateStaticRainDepth();
	}

	if (!m_bBlockNarrative)
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		if(XComHQ.GetObjectiveStatus('T5_M3_CompleteFinalMission') != eObjectiveState_InProgress)
		{
			if (!XComHQ.bPlayedWarningNoResearch && !XComHQ.HasResearchProject() && !XComHQ.HasShadowProject() &&
				(XComHQ.HasTechsAvailableForResearchWithRequirementsMet() || XComHQ.HasTechsAvailableForResearchWithRequirementsMet(true)))
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: No Research");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				NewGameState.AddStateObject(XComHQ);
				XComHQ.bPlayedWarningNoResearch = true;
				`XEVENTMGR.TriggerEvent('WarningNoResearch', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else if(!XComHQ.bPlayedWarningNoIncome && class'UIUtilities_Strategy'.static.GetResistanceHQ().GetSuppliesReward() <= 0)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: No Income");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				NewGameState.AddStateObject(XComHQ);
				XComHQ.bPlayedWarningNoIncome = true;
				`XEVENTMGR.TriggerEvent('WarningNoIncome', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else if (!m_bRecentStaffAvailable && !XComHQ.bPlayedWarningUnstaffedEngineer && XComHQ.GetNumberOfUnstaffedEngineers() > 0)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Unstaffed Engineer");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				NewGameState.AddStateObject(XComHQ);
				XComHQ.bPlayedWarningUnstaffedEngineer = true;
				if(XComHQ.Facilities.Length >= 12 && XComHQ.Facilities.Length <= 19 && !XComHQ.HasActiveConstructionProject())
					`XEVENTMGR.TriggerEvent('OnFacilityNag', , , NewGameState);
				else
					`XEVENTMGR.TriggerEvent('WarningUnstaffedEngineer', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else if(!XComHQ.bPlayedWarningUnstaffedScientist && XComHQ.GetNumberOfUnstaffedScientists() > 0 && XComHQ.GetFacilityByNameWithOpenStaffSlots('Laboratory') != none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Unstaffed Scientist");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				NewGameState.AddStateObject(XComHQ);
				XComHQ.bPlayedWarningUnstaffedScientist = true;
				`XEVENTMGR.TriggerEvent('WarningUnstaffedScientist', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}
	else
	{
		m_bBlockNarrative = false; // Turn off the block now that the transition is complete
	}
	EndGeoscapeCameraTransition();
}

function CameraTransitionToCIC ()
{
	`HQPRES.CAMLookAtRoom(GetCICRoom(), `HQINTERPTIME);
}

private function XComGameState_HeadquartersRoom GetCICRoom()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	if (CICRoomRef.ObjectID < 1)
	{
		foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
		{
			if (FacilityState.GetMyTemplateName() == 'CIC')
			{
				CICRoomRef = FacilityState.GetRoom().GetReference();
				break;
			}
		}
	}

	return XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(CICRoomRef.ObjectID));
}

//----------------------------------------------------
// DOOM EFFECT
//----------------------------------------------------

function float GetDoomTimerVisModifiers()
{
	return `XPROFILESETTINGS.Data.bEnableZipMode ? class'X2TacticalGameRuleset'.default.ZipModeDoomVisModifier : 1.0;
}

//---------------------------------------------------------------------------------------
function NonPanClearDoom(bool bPositive)
{
	StrategyMap2D.SetUIState(eSMS_Flight);

	if(bPositive)
	{
		StrategyMap2D.StrategyMapHUD.StartDoomRemovedEffect();
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_DecreaseScreenTear_ON");
	}
	else
	{
		StrategyMap2D.StrategyMapHUD.StartDoomAddedEffect();
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_IncreasedScreenTear_ON");
	}

	SetTimer(3.0f * GetDoomTimerVisModifiers(), false, nameof(NoPanClearDoomPt2));
}

//---------------------------------------------------------------------------------------
function NoPanClearDoomPt2()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ.ClearPendingDoom();

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(AlienHQ.PendingDoomData.Length > 0)
	{
		SetTimer(4.0f * GetDoomTimerVisModifiers(), false, nameof(NoPanClearDoomPt2));
	}
	else
	{
		SetTimer(4.0f * GetDoomTimerVisModifiers(), false, nameof(UnPanDoomFinished));
	}
}

//---------------------------------------------------------------------------------------
function DoomCameraPan(XComGameState_GeoscapeEntity EntityState, bool bPositive, optional bool bFirstFacility = false)
{
	CAMSaveCurrentLocation();
	StrategyMap2D.SetUIState(eSMS_Flight);

	// Stop Scanning
	if(`GAME.GetGeoscape().IsScanning())
	{
		StrategyMap2D.ToggleScan();
	}

	if(bPositive)
	{
		StrategyMap2D.StrategyMapHUD.StartDoomRemovedEffect();
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_DecreaseScreenTear_ON");
	}
	else
	{
		StrategyMap2D.StrategyMapHUD.StartDoomAddedEffect();
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_IncreasedScreenTear_ON");
	}

	DoomEntityLoc = EntityState.Get2DLocation();

	if(bFirstFacility)
	{
		SetTimer(3.0f * GetDoomTimerVisModifiers(), false, nameof(StartFirstFacilityCameraPan));
	}
	else
	{
		SetTimer(3.0f * GetDoomTimerVisModifiers(), false, nameof(StartDoomCameraPan));
	}
}

//---------------------------------------------------------------------------------------
function StartDoomCameraPan()
{
	// Pan to the location
	CAMLookAtEarth(DoomEntityLoc, 0.5f, `HQINTERPTIME);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_Camera_Whoosh");
	SetTimer((`HQINTERPTIME + 3.0f * GetDoomTimerVisModifiers()), false, nameof(DoomCameraPanComplete));
}

//---------------------------------------------------------------------------------------
function StartFirstFacilityCameraPan()
{
	CAMLookAtEarth(DoomEntityLoc, 0.5f, `HQINTERPTIME);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_Camera_Whoosh");
	SetTimer((`HQINTERPTIME), false, nameof(FirstFacilityCameraPanComplete));
}

//---------------------------------------------------------------------------------------
function DoomCameraPanComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ.ClearPendingDoom();

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(AlienHQ.PendingDoomData.Length > 0)
	{
		SetTimer(4.0f * GetDoomTimerVisModifiers(), false, nameof(DoomCameraPanComplete));
	}
	else
	{
		SetTimer(4.0f * GetDoomTimerVisModifiers(), false, nameof(UnpanDoomCamera));
	}
}

//---------------------------------------------------------------------------------------
function FirstFacilityCameraPanComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState NewGameState;
	local StateObjectReference EmptyRef;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fire First Facility Event");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	if(AlienHQ.PendingDoomEvent != '')
	{
		`XEVENTMGR.TriggerEvent(AlienHQ.PendingDoomEvent, , , NewGameState);
	}

	AlienHQ.PendingDoomEvent = '';
	AlienHQ.PendingDoomEntity = EmptyRef;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.GetMissionSource().bAlienNetwork)
		{
			break;
		}
	}

	StrategyMap2D.StrategyMapHUD.StopDoomAddedEffect();
	StrategyMap2D.SetUIState(eSMS_Default);
	OnMissionSelected(MissionState, false);
}

//---------------------------------------------------------------------------------------
function UnpanDoomCamera()
{
	CAMRestoreSavedLocation();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_Camera_Whoosh");
	SetTimer((`HQINTERPTIME + 3.0f * GetDoomTimerVisModifiers()), false, nameof(UnPanDoomFinished));
}

//---------------------------------------------------------------------------------------
function UnPanDoomFinished()
{
	StrategyMap2D.StrategyMapHUD.StopDoomRemovedEffect();
	StrategyMap2D.StrategyMapHUD.StopDoomAddedEffect();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Doom_Increase_and_Decrease_Off");
	StrategyMap2D.SetUIState(eSMS_Default);

	if(m_bDelayGeoscapeEntryEvent)
	{
		GeoscapeEntryEvent();
	}
}

//----------------------------------------------------
// TOP LEVEL AVENGER
//----------------------------------------------------
function UIAvengerFacilityMenu()
{
	m_kAvengerHUD = Spawn( class'UIAvengerHUD', self );
	ScreenStack.Push( m_kAvengerHUD );

	m_kFacilityGrid = Spawn( class'UIFacilityGrid', self );
	ScreenStack.Push( m_kFacilityGrid );

	// TODO: This isn't used anymore, delete it -sbatista
	//ScreenStack.Push( Spawn( class'UIStrategyDebugMenu', self ) );

	//SOUND().PlayAmbience( eAmbience_HQ );
	XComHeadquartersController(Owner).SetInputState( 'HQ_FreeMovement' );
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_AvengerNoRoom");
}

//----------------------------------------------------
// PERSONNEL MANAGEMENT
//----------------------------------------------------
function UIPersonnel(optional EUIPersonnelType eListType = eUIPersonnel_All, optional delegate<UIPersonnel.OnPersonnelSelected> onSelected = none, optional bool RemoveScreenAfterSelection = false, optional StateObjectReference SlotRef)
{
	local UIPersonnel kPersonnelList;
	
	if(ScreenStack.IsNotInStack(class'UIPersonnel'))
	{
		kPersonnelList = Spawn( class'UIPersonnel', self );
		kPersonnelList.m_eListType = eListType;
		kPersonnelList.onSelectedDelegate = onSelected;
		kPersonnelList.m_bRemoveWhenUnitSelected = RemoveScreenAfterSelection;
		kPersonnelList.SlotRef = SlotRef;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_BuildFacility(optional delegate<UIPersonnel.OnPersonnelSelected> onSelected = none, optional X2FacilityTemplate FacilityTemplate = none, optional bool RemoveScreenAfterSelection = true, optional StateObjectReference RoomRef)
{
	local UIPersonnel_BuildFacility kPersonnelList;
	
	if(ScreenStack.IsNotInStack(class'UIPersonnel_BuildFacility'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_BuildFacility', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		kPersonnelList.m_bRemoveWhenUnitSelected = RemoveScreenAfterSelection;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_SquadSelect(delegate<UIPersonnel.OnPersonnelSelected> onSelected, XComGameState UpdateState, XComGameState_HeadquartersXCom HQState)
{
	local UIPersonnel_SquadSelect kPersonnelList;
	
	if(ScreenStack.IsNotInStack(class'UIPersonnel_SquadSelect'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_SquadSelect', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		kPersonnelList.GameState = UpdateState;
		kPersonnelList.HQState = HQState;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_BarMemorial(delegate<UIPersonnel.OnPersonnelSelected> onSelected)
{
	local UIPersonnel_BarMemorial kPersonnelList;

	if(ScreenStack.IsNotInStack(class'UIPersonnel_BarMemorial'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_BarMemorial', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_ChooseResearch(delegate<UIPersonnel.OnPersonnelSelected> onSelected, StateObjectReference StaffSlotRef)
{
	local UIPersonnel_ChooseResearch kPersonnelList;

	if(ScreenStack.IsNotInStack(class'UIPersonnel_ChooseResearch'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_ChooseResearch', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_SpecialFeature(delegate<UIPersonnel.OnPersonnelSelected> onSelected, StateObjectReference RoomRef)
{
	local UIPersonnel_SpecialFeature kPersonnelList;

	if(ScreenStack.IsNotInStack(class'UIPersonnel_SpecialFeature'))
	{
		kPersonnelList = Spawn( class'UIPersonnel_SpecialFeature', self );
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push( kPersonnelList );
	}
}

function UIPersonnel_LivingQuarters(delegate<UIPersonnel.OnPersonnelSelected> onSelected)
{
	local UIPersonnel_LivingQuarters kPersonnelList;

	if (ScreenStack.IsNotInStack(class'UIPersonnel_LivingQuarters'))
	{
		kPersonnelList = Spawn(class'UIPersonnel_LivingQuarters', self);
		kPersonnelList.onSelectedDelegate = onSelected;
		ScreenStack.Push(kPersonnelList);
	}
}

//----------------------------------------------------
// Memorial Details
//----------------------------------------------------
function UIBarMemorial_Details(StateObjectReference UnitRef)
{
	if(ScreenStack.IsNotInStack(class'UIBarMemorial_Details'))
	{
		UIBarMemorial_Details(ScreenStack.Push(Spawn(class'UIBarMemorial_Details', self), Get3DMovie())).InitMemorial(UnitRef);
	}
}


//----------------------------------------------------
// ARMORY (Soldier / Weapon Management)
//----------------------------------------------------
function UISoldierIntroCinematic(name SoldierClassName, StateObjectReference SoldierRef)
{
	if (ScreenStack.IsNotInStack(class'UISoldierIntroCinematic'))
	{
		UISoldierIntroCinematic(ScreenStack.Push(Spawn(class'UISoldierIntroCinematic', self), Get3DMovie())).InitCinematic(SoldierClassName, SoldierRef, ShowPromotionUI);
	}
}

function UIArmorIntroCinematic(name StartEventName, name StopEventName, StateObjectReference SoldierRef)
{
	local UISoldierIntroCinematic IntroCinematic;
	if (ScreenStack.IsNotInStack(class'UISoldierIntroCinematic'))
	{
		IntroCinematic = Spawn(class'UISoldierIntroCinematic', self);
		IntroCinematic.StartEventBase = string(StartEventName);
		IntroCinematic.FinishedEventName = StopEventName;
		IntroCinematic.InitCinematic('', SoldierRef);
		ScreenStack.Push(IntroCinematic);
	}
}

function UIArmory_MainMenu(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false)
{
	if(ScreenStack.IsNotInStack(class'UIArmory_MainMenu'))
		UIArmory_MainMenu(ScreenStack.Push(Spawn(class'UIArmory_MainMenu', self), Get3DMovie())).InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant);
}

function UIArmory_Loadout(StateObjectReference UnitRef, optional array<EInventorySlot> CannotEditSlots)
{
	local UIArmory_Loadout ArmoryScreen;

	if (ScreenStack.IsNotInStack(class'UIArmory_Loadout'))
	{
		ArmoryScreen = UIArmory_Loadout(ScreenStack.Push(Spawn(class'UIArmory_Loadout', self), Get3DMovie()));
		ArmoryScreen.CannotEditSlotsList = CannotEditSlots;
		ArmoryScreen.InitArmory(UnitRef);
	}
}

function UIArmory_Promotion(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	if (ScreenStack.IsNotInStack(class'UIArmory_Promotion'))
	{
		DoPromotionSequence(UnitRef, bInstantTransition);
	}
}

private function DoPromotionSequence(StateObjectReference UnitRef, bool bInstantTransition)
{
	local XComGameState_Unit UnitState;
	local name SoldierClassName;

	SoldierClassName = class'X2StrategyGameRulesetDataStructures'.static.PromoteSoldier(UnitRef);
	if (SoldierClassName == '')
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		SoldierClassName = UnitState.GetSoldierClassTemplate().DataName;
	}
	
	// The ShowPromotionUI will get triggered at the end of the class movie if it plays, or...
	if (!class'X2StrategyGameRulesetDataStructures'.static.ShowClassMovie(SoldierClassName, UnitRef))
	{
		// ...this wasn't the first time we saw this unit's new class so just show the UI
		ShowPromotionUI(UnitRef, bInstantTransition);
	}
}

function ShowPromotionUI(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	local UIArmory_Promotion PromotionUI;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
		PromotionUI = UIArmory_PromotionPsiOp(ScreenStack.Push(Spawn(class'UIArmory_PromotionPsiOp', self), Get3DMovie()));
	else
		PromotionUI = UIArmory_Promotion(ScreenStack.Push(Spawn(class'UIArmory_Promotion', self), Get3DMovie()));
	
	PromotionUI.InitPromotion(UnitRef, bInstantTransition);
}

function UIAbilityPopup(X2AbilityTemplate AbilityTemplate)
{
	local UIAbilityPopup AbilityPopup;

	if (ScreenStack.IsNotInStack(class'UIAbilityPopup'))
	{
		AbilityPopup = Spawn(class'UIAbilityPopup', self);
		ScreenStack.Push(AbilityPopup);
		AbilityPopup.InitAbilityPopup(AbilityTemplate);
	}
}

function UIArmory_Implants(StateObjectReference UnitRef)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: View PCS");
	`XEVENTMGR.TriggerEvent('OnViewPCS', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if(ScreenStack.IsNotInStack(class'UIArmory_Implants'))
		UIArmory_Implants(ScreenStack.Push(Spawn(class'UIArmory_Implants', self), Get3DMovie())).InitImplants(UnitRef);
}

function UIArmory_WeaponUpgrade(StateObjectReference UnitOrWeaponRef)
{
	if(ScreenStack.IsNotInStack(class'UIArmory_WeaponUpgrade'))
		UIArmory_WeaponUpgrade(ScreenStack.Push(Spawn(class'UIArmory_WeaponUpgrade', self), Get3DMovie())).InitArmory(UnitOrWeaponRef);
}

reliable client function UIArmory_WeaponTrait(StateObjectReference UnitOrWeaponRef,
											  string _Title, 
											  array<string> _Data, 
											  delegate<UIArmory_WeaponTrait.OnItemSelectedCallback> _onSelectionChanged,
											  delegate<UIArmory_WeaponTrait.OnItemSelectedCallback> _onItemClicked,
											  optional delegate<UICustomize.IsSoldierEligible> _eligibilityCheck,
											  optional int startingIndex = -1,
											  optional string _ConfirmButtonLabel,
											  optional delegate<UIArmory_WeaponTrait.OnItemSelectedCallback> _onConfirmButtonClicked,
											  optional bool _bAllowedToCycleSoldiers = true)
{
	local UIArmory_WeaponTrait WeaponTraitScreen; 

	if(ScreenStack.IsNotInStack(class'UIArmory_WeaponTrait'))
	{
		WeaponTraitScreen = UIArmory_WeaponTrait(ScreenStack.Push(Spawn(class'UIArmory_WeaponTrait', self), Get3DMovie()));
		WeaponTraitScreen.bAllowedToCycleSoldiers = _bAllowedToCycleSoldiers; //Set this before init to allow nav help setup to use this value 
		WeaponTraitScreen.InitArmory(UnitOrWeaponRef);
		WeaponTraitScreen.UpdateTrait(_Title, _Data, _onSelectionChanged, _onItemClicked, _eligibilityCheck, startingIndex, _ConfirmButtonLabel, _onConfirmButtonClicked);
	}
}

//----------------------------------------------------
// FACILITIES
//----------------------------------------------------

function UIRoom(optional StateObjectReference Room, optional bool bInstant = false)
{
	if (ScreenStack.IsNotInStack(class'UIRoom'))
	{
		TempScreen = Spawn(class'UIRoom', self);
		UIRoom(TempScreen).RoomRef = Room;
		UIRoom(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen);
	}
}

function UIFacility(class<UIFacility> UIClass, optional StateObjectReference Facility, optional bool bInstant = false)
{
	if(ScreenStack.IsNotInStack(UIClass))
	{
		TempScreen = Spawn(UIClass, self);
		UIFacility(TempScreen).FacilityRef = Facility;
		UIFacility(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen);
	}
}

function UIChooseResearch(optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(XComHQ.HasActiveShadowProject())
	{
		ShadowProjectInProgressPopup();
	}
	else if(ScreenStack.IsNotInStack(class'UIChooseResearch'))
	{
		TempScreen = Spawn(class'UIChooseResearch', self);
		UIChooseResearch(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIChooseShadowProject(optional bool bInstant = false)
{
	if(ScreenStack.IsNotInStack(class'UIChooseResearch'))
	{
		TempScreen = Spawn(class'UIChooseResearch', self);
		UIChooseResearch(TempScreen).SetShadowChamber();
		UIChooseResearch(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIChooseProject()
{
	if (ScreenStack.IsNotInStack(class'UIChooseProject'))
	{
		TempScreen = Spawn(class'UIChooseProject', self);
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIChooseClass(StateObjectReference UnitRef)
{
	if (ScreenStack.IsNotInStack(class'UIChooseClass'))
	{
		TempScreen = Spawn(class'UIChooseClass', self);
		UIChooseClass(TempScreen).m_UnitRef = UnitRef;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIChoosePsiAbility(StateObjectReference UnitRef, StateObjectReference StaffSlotRef)
{
	if (ScreenStack.IsNotInStack(class'UIChoosePsiAbility'))
	{
		TempScreen = Spawn(class'UIChoosePsiAbility', self);
		UIChoosePsiAbility(TempScreen).m_UnitRef = UnitRef;
		UIChoosePsiAbility(TempScreen).m_StaffSlotRef = StaffSlotRef;
		ScreenStack.Push(TempScreen);
	}
}

function UIOfficerTrainingSchool(optional StateObjectReference Facility)
{
	if(ScreenStack.IsNotInStack(class'UIOfficerTrainingSchool'))
	{
		TempScreen = Spawn(class'UIOfficerTrainingSchool', self);
		UIOfficerTrainingSchool(TempScreen).FacilityRef = Facility;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

function UIBuildFacilities(optional bool bInstant = false)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entered Build Facilities");
	`XEVENTMGR.TriggerEvent('OnEnteredBuildFacilities', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if( ScreenStack.IsNotInStack(class'UIBuildFacilities') )
	{
		TempScreen = Spawn(class'UIBuildFacilities', self);
		UIBuildFacilities(TempScreen).bInstantInterp = bInstant;
		ScreenStack.Push(TempScreen);
	}
}

//----------------------------------------------------------------
//-------------------- RESEARCH ----------------------------------
//----------------------------------------------------------------
simulated function PauseShadowProjectPopup()
{
	local TDialogueBoxData kDialogData;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGParamTag LocTag;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = XComHQ.GetCurrentShadowTech().GetDisplayName();

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = m_strPauseShadowProjectLabel;
	kDialogData.strText = `XEXPAND.ExpandString(m_strPauseShadowProjectText);
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

	kDialogData.fnCallback = PauseShadowProjectPopupCallback;
	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated function PauseShadowProjectPopupCallback(eUIAction eAction)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIFacility_ShadowChamber ShadowChamber;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if(eAction == eUIAction_Accept)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pause Shadow Project");
		XComHQ.PauseShadowProject(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		XComHQ.HandlePowerOrStaffingChange();
		TempScreen = ScreenStack.GetCurrentScreen();

		ShadowChamber = UIFacility_ShadowChamber(TempScreen);
		if(ShadowChamber != none)
		{
			m_kAvengerHUD.Shortcuts.UpdateCategories();
			m_kAvengerHUD.Shortcuts.SelectCategoryForFacilityScreen(ShadowChamber, true);
			ShadowChamber.UpdateData();
			ShadowChamber.RealizeNavHelp();
		}
	}
}

simulated public function ShadowProjectInProgressPopup()
{
	local TDialogueBoxData kDialogData;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGParamTag LocTag;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = XComHQ.GetCurrentShadowTech().GetDisplayName();

	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strShadowProjectInProgressLabel;
	kDialogData.strText = `XEXPAND.ExpandString(m_strShadowProjectInProgressText);
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	`HQPRES.UIRaiseDialog(kDialogData);
}

simulated public function RoomLockedPopup()
{
	local TDialogueBoxData kDialogData;
	
	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strRoomLockedLabel;
	kDialogData.strText = m_strRoomLockedText;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	`HQPRES.UIRaiseDialog(kDialogData);
}

function UIResearchUnlocked(array<StateObjectReference> UnlockedTechs)
{
	local UIResearchUnlocked ResearchUnlocked;

	if(ScreenStack.IsNotInStack(class'UIResearchUnlocked'))
	{
		ResearchUnlocked = Spawn(class'UIResearchUnlocked', self);
		ScreenStack.Push(ResearchUnlocked, Get3DMovie());
		ResearchUnlocked.PopulateData(UnlockedTechs);
	}
}

simulated function UIResearchComplete(StateObjectReference TechRef)
{
	local XComGameStateHistory History;
	local UIAlert Alert;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	if(TechState.GetMyTemplate().bShadowProject || TechState.GetMyTemplate().bJumpToLabs)
	{
		// Objectives handle the jump to facility after cinematics
		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
		`GAME.GetGeoscape().Pause();
	}
	else
	{
		Alert = Spawn(class'UIAlert', self);
		Alert.TechRef = TechRef;
		Alert.eAlert = eAlert_ResearchComplete;
		Alert.fnCallback = ResearchCompletePopupCB;
		Alert.EventToTrigger = 'ResearchCompletePopup';
		Alert.SoundToPlay = "Geoscape_ResearchComplete";
		ScreenStack.Push(Alert);
	}
}

simulated function ResearchCompletePopupCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	if (eAction == eUIAction_Accept)
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('PowerCore');

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();

		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Research Complete Popup Closed");
		`XEVENTMGR.TriggerEvent('OnResearchCompletePopupClosed', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

simulated function ResearchReportPopup(StateObjectReference TechRef, optional bool bInstantInterp = false)
{
	local UIResearchReport ResearchReport;
	if(ScreenStack.IsNotInStack(class'UIResearchReport'))
	{
		ResearchReport = Spawn(class'UIResearchReport', self);
		ResearchReport.bInstantInterp = bInstantInterp;
		ScreenStack.Push(ResearchReport, Get3DMovie());
		ResearchReport.InitResearchReport(TechRef);
	}
}

function UIRewardsRecap(optional bool bForce = false)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Reward Recap Event Hook");
	`XEVENTMGR.TriggerEvent('MissionRewardRecap', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if(bForce || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M1_L1_RevealBlacksiteObjective') != eObjectiveState_InProgress)
	{
		if(ScreenStack.IsNotInStack(class'UIRewardsRecap'))
		{
			ScreenStack.Push(Spawn(class'UIRewardsRecap', self), Get3DMovie());
		}
	}
}

function UIResearchArchives()
{
	if(ScreenStack.IsNotInStack(class'UIResearchArchives'))
		ScreenStack.Push(Spawn(class'UIResearchArchives', self) , Get3DMovie());
}

function UIShadowChamberArchives()
{
	if( ScreenStack.IsNotInStack(class'UIShadowChamberArchives') )
		ScreenStack.Push(Spawn(class'UIShadowChamberArchives', self) /*, Get3DMovie()*/);
}

simulated function ShadowChamberResearchReportPopup(StateObjectReference TechRef)
{
	local UIResearchReport ResearchReport;
	if( ScreenStack.IsNotInStack(class'UIResearchReport') )
	{
		ResearchReport = Spawn(class'UIResearchReport', self);
		ScreenStack.Push(ResearchReport);
		ResearchReport.InitResearchReport(TechRef);
	}
}

function UISchematicArchives()
{
	if(ScreenStack.IsNotInStack(class'UISchematicArchives'))
		ScreenStack.Push(Spawn(class'UISchematicArchives', self) , Get3DMovie());
}

function UIBuildItem()
{
	if(ScreenStack.IsNotInStack(class'UIInventory_BuildItems'))
		ScreenStack.Push(Spawn( class'UIInventory_BuildItems', self), Get3DMovie());
}

function UIChooseFacility(StateObjectReference RoomRef)
{
	if(ScreenStack.IsNotInStack(class'UIChooseFacility'))
	{
		TempScreen = Spawn(class'UIChooseFacility', self);
		UIChooseFacility(TempScreen).m_RoomRef = RoomRef;
		ScreenStack.Push(TempScreen);
	}
}

function UIFacilityUpgrade(StateObjectReference FacilityRef)
{
	local UIChooseUpgrade ChooseUpgrade;

	if(ScreenStack.IsNotInStack(class'UIChooseUpgrade'))
	{
		ChooseUpgrade = Spawn(class'UIChooseUpgrade', self);
		ChooseUpgrade.SetFacility(FacilityRef);
		ScreenStack.Push(ChooseUpgrade);
	}
}

simulated function UIViewObjectives(optional float OverrideInterpTime = -1)
{
	if(ScreenStack.IsNotInStack(class'UIViewObjectives'))
	{
		TempScreen = Spawn(class'UIViewObjectives', self);
		UIViewObjectives(TempScreen).OverrideInterpTime = OverrideInterpTime;
		ScreenStack.Push(TempScreen, Get3DMovie());
	}
}

simulated function HotlinkToViewObjectives()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local UIFacility_CIC CurrentCICScreen;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('CommandersQuarters');

	if( `GAME.GetGeoscape().IsScanning() )
		StrategyMap2D.ToggleScan();

	`HQPRES.ClearUIToHUD();

	PushCameraInterpTime(0.0f);

	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference(), true);

	// get to view objectives screen, once we're on the CIC  screen. 
	CurrentCICScreen = UIFacility_CIC(ScreenStack.GetCurrentScreen());
	if( CurrentCICScreen != none )
	{
		CurrentCICScreen.ViewObjectives();
	}

	PopCameraInterpTime();
}


simulated function HotlinkToViewDarkEvents(optional bool bShowActiveDarkEvents = false)
{
	UIAdventOperations(false, bShowActiveDarkEvents);
}


//----------------------------------------------------
// PRE-MISSION SCREENS
//----------------------------------------------------
function UISquadSelect(optional bool bNoCancel=false)
{
	local UISquadSelect SquadSelectScreen;

	if(ScreenStack.IsNotInStack(class'UISquadSelect'))
	{
		SquadSelectScreen = Spawn( class'UISquadSelect', self);
		SquadSelectScreen.bNoCancel = bNoCancel;
		ScreenStack.Push(SquadSelectScreen);
	}
}

//----------------------------------------------------
// POST-MISSION SCREENS
//----------------------------------------------------
function UIMissionSummary(TSimCombatSummaryData SummaryData) // for SimCombat only
{
	if(ScreenStack.IsNotInStack(class'UIMissionSummary'))
	{
		ScreenStack.Push( Spawn( class'UIMissionSummary', self ) );
		UIMissionSummary(ScreenStack.GetScreen(class'UIMissionSummary')).SimCombatData = SummaryData;
	}
}

function UIAfterAction(optional bool bIsSimCombat)
{
	if(ScreenStack.IsNotInStack(class'UIAfterAction'))
	{
		ScreenStack.Push( Spawn( class'UIAfterAction', self ) );
		
		// TODO @rmcfall: Remove this once intro sequence is fixed for SimCombat
		if(bIsSimCombat)
			UIAfterAction(ScreenStack.GetScreen(class'UIAfterAction')).Show();

		`XSTRATEGYSOUNDMGR.PlayAfterActionMusic();
	}
}

function UIInventory_LootRecovered()
{
	if(ScreenStack.IsNotInStack(class'UIInventory_LootRecovered'))
	{
		ScreenStack.Push( Spawn( class'UIInventory_LootRecovered', self ), Get3DMovie() );
	}
}

//----------------------------------------------------
// AVENGER SCREENS
//----------------------------------------------------
function UIInventory_Storage()
{
	if(ScreenStack.IsNotInStack(class'UIInventory_Storage'))
		ScreenStack.Push( Spawn(class'UIInventory_Storage', self), Get3DMovie() );
}

function UIInventory_Implants()
{
	if(ScreenStack.IsNotInStack(class'UIInventory_Implants'))
		ScreenStack.Push( Spawn(class'UIInventory_Implants', self), Get3DMovie() );
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                   BEGIN DEPRECATED UI (TODO: CLEANUP)
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//----------------------------------------------------
simulated function UIStrategyShell()
{
	if(ScreenStack.IsNotInStack(class'UIShellStrategy'))
		ScreenStack.Push( Spawn( class'UIShellStrategy', self ) );
}


simulated function RemoveUIDropshipBriefingHUD()
{
	ScreenStack.PopFirstInstanceOfClass( class'UIDropshipHUD' );
}

//-------------------------------------------------------------------

simulated function UIEndGame()
{
	XComHeadquartersGame(WorldInfo.Game).Uninit();
}

//----------------------------------------------------
simulated function UIFocusOnEntity(XComGameState_GeoscapeEntity Entity, optional float fZoom = 1.0f, optional float fInterpTime = 0.75f)
{
	CAMLookAtEarth(Entity.Get2DLocation(), fZoom, fInterpTime);
}

simulated function UISkyrangerArrives()
{
	local UISkyrangerArrives kScreen;

	kScreen = Spawn(class'UISkyrangerArrives', self);
	ScreenStack.Push(kScreen);
}

simulated function UIUFOAttack(XComGameState_MissionSite MissionState)
{
	local UIUFOAttack kScreen;

	kScreen = Spawn(class'UIUFOAttack', self);
	kScreen.MissionRef = MissionState.GetReference();
	ScreenStack.Push(kScreen);
}

//-------------------------------------------------------------------
simulated function UIResistance(XComGameState_WorldRegion RegionState)
{
	local UIResistance kScreen;

	kScreen = Spawn(class'UIResistance', self);
	kScreen.RegionRef = RegionState.GetReference();
	ScreenStack.Push(kScreen);
}
simulated function UIMonthlyReport()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_CouncilComm;
	Alert.fnCallback = CouncilReportAlertCB;
	Alert.SoundToPlay = "Geoscape_CouncilMonthlySummaryPopup";
	Alert.EventToTrigger = 'OnMonthlyReportAlert';
	ScreenStack.Push(Alert);
}
simulated function UIFortressReveal()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_CouncilComm;
	Alert.fnCallback = FortressRevealAlertCB;
	Alert.SoundToPlay = "Geoscape_CouncilMonthlySummaryPopup";
	Alert.EventToTrigger = 'OnFortressRevealAlert';
	ScreenStack.Push(Alert);
}
simulated function UIAdventOperations(bool bResistanceReport, optional bool bShowActiveEvents = false)
{
	local UIAdventOperations kScreen;
	local XComGameState NewGameState;

	//Check to not allow you in to this screen multiple times. 
	if( ScreenStack.GetScreen(class'UIAdventOperations') != none ) 
		return; 

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: View Dark Events");
	`XEVENTMGR.TriggerEvent('OnViewDarkEvents', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	kScreen = Spawn(class'UIAdventOperations', self);
	kScreen.bResistanceReport = bResistanceReport;
	kScreen.bShowActiveEvents = bShowActiveEvents;
	ScreenStack.Push(kScreen);
}
simulated function UIResistanceOps(StateObjectReference RegionRef)
{
	local UIResistanceOps kScreen;

	kScreen = Spawn(class'UIResistanceOps', self);
	kScreen.RegionRef = RegionRef;
	ScreenStack.Push(kScreen);
}
simulated function UIResistanceGoods()
{
	local UIResistanceGoods kScreen;

	kScreen = Spawn(class'UIResistanceGoods', self);
	ScreenStack.Push(kScreen);
}

simulated function UIBlackMarketAppearedAlert()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_BlackMarketAvailable;
	Alert.fnCallback = BMAppearedCB;
	Alert.SoundToPlay = "Geoscape_Black_Market_Found";
	ScreenStack.Push(Alert);
}
simulated function UIBlackMarketAlert()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_BlackMarket;
	Alert.fnCallback = BMAlertCB;
	Alert.SoundToPlay = "Geoscape_POIReached";
	ScreenStack.Push(Alert);
}
simulated function UIBlackMarket()
{
	local UIBlackMarket kScreen;

	kScreen = Spawn(class'UIBlackMarket', self);
	ScreenStack.Push(kScreen);
}
simulated function UIBlackMarketBuy()
{
	local UIBlackMarket_Buy kScreen;

	kScreen = Spawn(class'UIBlackMarket_Buy', self);
	ScreenStack.Push(kScreen);
}
simulated function UIBlackMarketSell()
{
	local XComGameStateHistory History;
	local UIBlackMarket_Sell kScreen;
	local XComGameState_BlackMarket BlackMarketState;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));

	kScreen = Spawn(class'UIBlackMarket_Sell', self);
	kScreen.BlackMarketReference = BlackMarketState.GetReference();
	ScreenStack.Push(kScreen);
}

simulated function UITimeSensitiveMission(XComGameState_MissionSite MissionState)
{
	local UIAlert Alert;
	local XComGameState NewGameState;

	// Trigger the popup event and also save this mission as having seen the skip warning popup
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Time Sensitive Mission");
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	NewGameState.AddStateObject(MissionState);
	MissionState.bHasSeenSkipPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_TimeSensitiveMission;
	Alert.Mission = MissionState;
	Alert.fnCallback = TimeSensitiveMissionCB;
	Alert.SoundToPlay = "Geoscape_Time_Sensitive_Mission";
	Alert.EventToTrigger = 'TimeSensitiveMission';
	ScreenStack.Push(Alert);
}

simulated function TimeSensitiveMissionCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{	
	if (eAction == eUIAction_Accept)
	{
		OnMissionSelected(AlertData.Mission);

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
	else
	{
		StrategyMap2D.ToggleScan(true); // Force the scan to start
	}
}

simulated function UIMissionExpired(XComGameState_MissionSite MissionState)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_MissionExpired;
	Alert.Mission = MissionState;
	Alert.SoundToPlay = "Geoscape_Mission_Expired";
	ScreenStack.Push(Alert);
}

simulated function OnMissionSelected(XComGameState_MissionSite MissionSite, optional bool bInstant = false)
{
	// TODO: Associate ui with mission type in template

	if( MissionSite.Source == 'MissionSource_GuerillaOp' )
	{
		GOpsAlertCB(eUIAction_Accept, None, bInstant);

		// Guerilla ops have 2 or 3 choices, open up at the correct mission
		UIMission(ScreenStack.GetCurrentScreen()).SelectMission(MissionSite);
	}
	else if( MissionSite.Source == 'MissionSource_Retaliation' )
	{
		RetaliationAlertCB(eUIAction_Accept, None, bInstant);
	}
	else if( MissionSite.Source == 'MissionSource_Council' )
	{
		CouncilMissionAlertCB(eUIAction_Accept, None, bInstant);
	}
	else if (MissionSite.Source == 'MissionSource_SupplyRaid')
	{
		SupplyRaidAlertCB(eUIAction_Accept, None, bInstant);
	}
	else if (MissionSite.Source == 'MissionSource_LandedUFO')
	{
		LandedUFOAlertCB(eUIAction_Accept, None, bInstant);
	}
	else if( MissionSite.Source == 'MissionSource_AlienNetwork' )
	{
		ProcessDoomAlertForMission(MissionSite);
	}
	else if ( MissionSite.Source == 'MissionSource_Broadcast' )
	{
		GPIntelOptionsCB(eUIAction_Accept, MissionSite.Source, None, bInstant);
	}
	else if( MissionSite.GetMissionSource().bGoldenPath )
	{
		GoldenPathCB(eUIAction_Accept, MissionSite.Source, None, bInstant );
	}
}
simulated function UIGOpsMission(optional bool bInstant = false)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_GOps;
	Alert.bInstantInterp = bInstant;
	Alert.fnCallback = GOpsAlertCB;
	Alert.SoundToPlay = "GeoscapeFanfares_GuerillaOps";
	Alert.EventToTrigger = 'OnGOpsPopup';
	ScreenStack.Push(Alert);
}
simulated function UICouncilMission(optional bool bInstant = false)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_CouncilMission;
	Alert.bInstantInterp = bInstant;
	Alert.fnCallback = CouncilMissionAlertCB;
	Alert.SoundToPlay = "Geoscape_NewResistOpsMissions";
	Alert.EventToTrigger = 'OnCouncilPopup';
	ScreenStack.Push(Alert);
}
simulated function UIRetaliationMission(optional bool bInstant = false)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_Retaliation;
	Alert.bInstantInterp = bInstant;
	Alert.fnCallback = RetaliationAlertCB;
	Alert.SoundToPlay = "GeoscapeFanfares_Retaliation";
	Alert.EventToTrigger = 'OnRetaliationPopup';
	ScreenStack.Push(Alert);
}
simulated function UISupplyRaidMission(optional bool bInstant = false)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_SupplyRaid;
	Alert.bInstantInterp = bInstant;
	Alert.fnCallback = SupplyRaidAlertCB;
	Alert.SoundToPlay = "Geoscape_Supply_Raid_Popup";
	Alert.EventToTrigger = 'OnSupplyRaidPopup';
	ScreenStack.Push(Alert);
}
simulated function UILandedUFOMission(optional bool bInstant = false)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_LandedUFO;
	Alert.bInstantInterp = bInstant;
	Alert.fnCallback = LandedUFOAlertCB;
	Alert.SoundToPlay = "Geoscape_UFO_Landed";
	Alert.EventToTrigger = 'OnLandedUFOPopup';
	ScreenStack.Push(Alert);
}
simulated function BMAppearedCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState_BlackMarket BlackMarketState;
		
	if( eAction == eUIAction_Accept )
	{
		BlackMarketState = XComGameState_BlackMarket(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));		
		BlackMarketState.AttemptSelectionCheckInterruption();

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}
simulated function BMAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	if (eAction == eUIAction_Accept)
	{
		UIBlackMarket(); // Open the Black Market screen since the scan just finished

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}
simulated function GOpsAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local UIMission_GOps kScreen;

	if( eAction == eUIAction_Accept )
	{
		if(!ScreenStack.GetCurrentScreen().IsA('UIMission_GOps'))
		{
			kScreen = Spawn(class'UIMission_GOps', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}
simulated function CouncilMissionAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local UIMission_Council kScreen;

	if( eAction == eUIAction_Accept )
	{
		if(!ScreenStack.GetCurrentScreen().IsA('UIMission_Council'))
		{
			kScreen = Spawn(class'UIMission_Council', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}

simulated function CouncilReportAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local UIResistanceReport kScreen;

	if(!ScreenStack.GetCurrentScreen().IsA('UIResistanceReport'))
	{
		kScreen = Spawn(class'UIResistanceReport', self);
		ScreenStack.Push(kScreen, Get3DMovie());
	}

	if( `GAME.GetGeoscape().IsScanning() )
		StrategyMap2D.ToggleScan();
}

simulated function FortressRevealAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Avatar Project Reveal");
	`XEVENTMGR.TriggerEvent('AvatarProjectRevealed', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function RetaliationAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local UIMission_Retaliation kScreen;

	if( eAction == eUIAction_Accept )
	{
		if(!ScreenStack.GetCurrentScreen().IsA('UIMission_Retaliation'))
		{
			kScreen = Spawn(class'UIMission_Retaliation', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}

simulated function SupplyRaidAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local UIMission_SupplyRaid kScreen;

	if (eAction == eUIAction_Accept)
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_SupplyRaid'))
		{
			kScreen = Spawn(class'UIMission_SupplyRaid', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function LandedUFOAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local UIMission_LandedUFO kScreen;

	if (eAction == eUIAction_Accept)
	{
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_LandedUFO'))
		{
			kScreen = Spawn(class'UIMission_LandedUFO', self);
			kScreen.bInstantInterp = bInstant;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function ProcessDoomAlertForMission(XComGameState_MissionSite Mission)
{
	local UIMission_AlienFacility kScreen;

	// Show the alien facility
	if(!ScreenStack.GetCurrentScreen().IsA('UIMission_AlienFacility'))
	{
		kScreen = Spawn(class'UIMission_AlienFacility', self);
		kScreen.MissionRef = Mission.GetReference();
		ScreenStack.Push(kScreen);
	}

	if( `GAME.GetGeoscape().IsScanning() )
	{
		StrategyMap2D.ToggleScan();
	}
}

simulated function DoomAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	if( eAction == eUIAction_Accept )
	{
		ProcessDoomAlertForMission(AlertData.Mission);
	}
}

simulated function HiddenDoomAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	
}

simulated function GPIntelOptionsCB(EUIAction eAction, name GPMissionType, UIAlert AlertData, optional bool bInstant = false)
{
	local UIMission_GPIntelOptions kScreen;

	if (eAction == eUIAction_Accept)
	{
		// Show the Golden Path mission with intel options
		if (!ScreenStack.GetCurrentScreen().IsA('UIMission_GPIntelOptions'))
		{
			kScreen = Spawn(class'UIMission_GPIntelOptions', self);
			kScreen.bInstantInterp = bInstant;
			kScreen.GPMissionSource = GPMissionType;
			ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function GoldenPathCB(EUIAction eAction, name GPMissionType, UIAlert AlertData, optional bool bInstant = false)
{
	local UIMission_GoldenPath kScreen;

	if( eAction == eUIAction_Accept )
	{
		// Show the Golden Path mission
		if(!ScreenStack.GetCurrentScreen().IsA('UIMission_GoldenPath'))
		{
			kScreen = Spawn(class'UIMission_GoldenPath', self);
			kScreen.bInstantInterp = bInstant;
			kScreen.GPMissionSource = GPMissionType;
			ScreenStack.Push(kScreen);
		}

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();
	}
}

simulated function GeoscapeAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	//`GAME.GetGeoscape().Resume();
}
simulated function UIMakeContact(XComGameState_WorldRegion Region)
{
	local UIAlert Alert;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Making Contact Event");
	`XEVENTMGR.TriggerEvent('MakingContact', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_Contact;
	Alert.RegionRef = Region.GetReference();
	Alert.fnCallback = Region.MakeContactCallback;
	Alert.SoundToPlay = "Geoscape_POIReveal";
		
	if (!XComHQ.CanAffordAllStrategyCosts(Region.CalcContactCost(), Region.ContactCostScalars))
	{
		Alert.EventToTrigger = 'MakingContactNoIntel';
	}
	
	ScreenStack.Push(Alert);
}
simulated function UIBuildOutpost(XComGameState_WorldRegion Region)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_Outpost;
	Alert.RegionRef = Region.GetReference();
	Alert.fnCallback = Region.BuildOutpostCallback;
	Alert.SoundToPlay = "Geoscape_POIReveal";
	ScreenStack.Push(Alert);
}

simulated function UIInstantResearchAvailable(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;
	local UIAlert Alert;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Instant Tech Available Popup Seen");
	TechState = XComGameState_Tech(NewGameState.CreateStateObject(class'XComGameState_Tech', TechRef.ObjectID));
	NewGameState.AddStateObject(TechState);
	TechState.bSeenInstantPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_InstantResearchAvailable;
	Alert.TechRef = TechRef;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function UIItemAvailable(X2ItemTemplate ItemTemplate)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_ItemAvailable;
	Alert.ItemTemplate = ItemTemplate;
	Alert.fnCallback = ItemAvailableCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function ItemAvailableCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIItemReceived(X2ItemTemplate ItemTemplate)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_ItemReceived;
	Alert.ItemTemplate = ItemTemplate;
	Alert.fnCallback = ItemReceivedCB;
	Alert.SoundToPlay = "Geoscape_ItemComplete";
	ScreenStack.Push(Alert);
}

simulated function UIProvingGroundItemReceived(X2ItemTemplate ItemTemplate, StateObjectReference TechRef)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_ItemReceivedProvingGround;
	Alert.ItemTemplate = ItemTemplate;
	Alert.TechRef = TechRef;
	Alert.fnCallback = ItemReceivedCB;
	Alert.SoundToPlay = "Geoscape_ItemComplete";
	ScreenStack.Push(Alert);
}

simulated function ItemReceivedCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIItemUpgraded(X2ItemTemplate ItemTemplate)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_ItemUpgraded;
	Alert.ItemTemplate = ItemTemplate;
	Alert.fnCallback = ItemUpgradedCB;
	Alert.SoundToPlay = "Geoscape_ItemComplete";
	ScreenStack.Push(Alert);
}

simulated function ItemUpgradedCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIItemComplete(X2ItemTemplate Template)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_ItemComplete;
	Alert.ItemTemplate = Template;
	Alert.fnCallback = ItemCompleteCB;
	Alert.SoundToPlay = "Geoscape_ItemComplete";
	ScreenStack.Push(Alert);
}

simulated function ItemCompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	if (eAction == eUIAction_Accept)
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('Storage');

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();

		`HQPRES.ClearUIToHUD();
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
		//TODO: Need to figure out how to select build item here. -bsteiner 
	}
}

simulated function UIProvingGroundProjectAvailable(StateObjectReference TechRef)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_ProvingGroundProjectAvailable;
	Alert.TechRef = TechRef;
	Alert.fnCallback = ProvingGroundProjectAvailableCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function ProvingGroundProjectAvailableCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIProvingGroundProjectComplete(StateObjectReference TechRef)
{
	local UIAlert Alert;
			
	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_ProvingGroundProjectComplete;
	Alert.TechRef = TechRef;
	Alert.fnCallback = ProvingGroundProjectCompleteCB;
	Alert.SoundToPlay = "Geoscape_ProjectComplete";
	ScreenStack.Push(Alert);
}

simulated function ProvingGroundProjectCompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Tech TechState;
	
	History = `XCOMHISTORY;
	
	if (eAction == eUIAction_Accept)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('ProvingGround');

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();

		`HQPRES.ClearUIToHUD();
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
	}
	else
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(AlertData.TechRef.ObjectID));
		TechState.DisplayTechCompletePopups();
	}
}

simulated function UIFacilityAvailable(X2FacilityTemplate FacilityTemplate)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_FacilityAvailable;
	Alert.FacilityTemplate = FacilityTemplate;
	Alert.fnCallback = FacilityAvailableCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	Alert.EventToTrigger = 'FacilityAvailablePopup';
	Alert.EventData = FacilityTemplate;
	ScreenStack.Push(Alert);
}

simulated function FacilityAvailableCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIFacilityComplete(StateObjectReference FacilityRef, StaffUnitInfo BuilderInfo)
{
	local UIAlert Alert;
	local XComGameState_FacilityXCom FacilityState;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_FacilityComplete;
	Alert.FacilityRef = FacilityRef;
	Alert.UnitInfo = BuilderInfo;
	Alert.fnCallback = FacilityCompleteCB;
	Alert.SoundToPlay = "Geoscape_FacilityComplete";
	Alert.EventToTrigger = 'FacilityCompletePopup';
	Alert.EventData = FacilityState;
	ScreenStack.Push(Alert);

	if (BuilderInfo.UnitRef.ObjectID != 0)
	{
		m_bRecentStaffAvailable = true;
	}
}

simulated function FacilityCompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	if (eAction == eUIAction_Accept)
	{
		class'UIUtilities_Strategy'.static.SelectFacility(AlertData.FacilityRef);
	}
}

simulated function UIUpgradeAvailable(X2FacilityUpgradeTemplate UpgradeTemplate)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_UpgradeAvailable;
	Alert.UpgradeTemplate = UpgradeTemplate;
	Alert.fnCallback = UpgradeAvailableCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function UpgradeAvailableCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIUpgradeComplete(X2FacilityUpgradeTemplate Template)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_UpgradeComplete;
	Alert.UpgradeTemplate = Template;
	Alert.fnCallback = UpgradeCompleteCB;
	Alert.SoundToPlay = "Geoscape_FacilityComplete";
	ScreenStack.Push(Alert);
}

simulated function UpgradeCompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	if (eAction == eUIAction_Accept)
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('Storage');
		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();

		`HQPRES.ClearUIToHUD();
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
	}
}

simulated function UINewStaffAvailable(StateObjectReference UnitRef, optional bool bIgnoreRemove = false)
{
	local XComGameState_Unit UnitState;
	local UIAlert Alert;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	Alert = Spawn(class'UIAlert', `HQPRES);
	if (UnitState.IsAnEngineer())
		Alert.eAlert = eAlert_NewStaffAvailable;
	else
		Alert.eAlert = eAlert_NewStaffAvailableSmall;
	Alert.UnitInfo.UnitRef = UnitRef;
	Alert.fnCallback = NewStaffAvailableCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	Alert.EventToTrigger = 'StaffAdded';
	Alert.EventData = UnitState;
			
	ScreenStack.Push(Alert);

	if (!bIgnoreRemove)
	{
		NewCrewMembers.RemoveItem(UnitRef);
	}

	m_bRecentStaffAvailable = true;
}

simulated function UIStaffInfo(StateObjectReference UnitRef, optional bool bIgnoreRemove = false)
{
	local XComGameState_Unit UnitState;
	local UIAlert Alert;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_StaffInfo;
	Alert.UnitInfo.UnitRef = UnitRef;
	Alert.fnCallback = NewStaffAvailableCB;
	Alert.EventData = UnitState;

	ScreenStack.Push(Alert);
}

simulated function NewStaffAvailableCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIClearRoomComplete(StateObjectReference RoomRef, X2SpecialRoomFeatureTemplate Template, array<StaffUnitInfo> BuilderInfoList)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_ClearRoomComplete;
	Alert.RoomRef = RoomRef;
	Alert.SpecialRoomFeatureTemplate = Template;
	Alert.BuilderInfoList = BuilderInfoList;
	Alert.fnCallback = ClearRoomCompleteCB;
	Alert.SoundToPlay = "Geoscape_FacilityComplete";
	ScreenStack.Push(Alert);

	m_bRecentStaffAvailable = true;
}

simulated function ClearRoomCompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersRoom Room;

	if (eAction == eUIAction_Accept)
	{
		History = `XCOMHISTORY;
		Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(AlertData.RoomRef.ObjectID));
		
		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();

		// If "View Room" is selected, return to the Facility Grid and select the room for facility construction
		`HQPRES.ClearUIToHUD();
		`HQPRES.CAMLookAtRoom(Room, 0);
		`HQPRES.UIChooseFacility(Room.GetReference());
	}
}

simulated function UIClassEarned(StateObjectReference UnitRef)
{
	local UIAlert Alert;
	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_SoldierPromoted;
	Alert.UnitInfo.UnitRef = UnitRef;
	Alert.fnCallback = TrainingCompleteCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function UITrainingComplete(StateObjectReference UnitRef)
{
	local UIAlert Alert;
	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_TrainingComplete;
	Alert.UnitInfo.UnitRef = UnitRef;
	Alert.fnCallback = TrainingCompleteCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function TrainingCompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	
	// Flag the new class popup as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Promotion Callback");
	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AlertData.UnitInfo.UnitRef.ObjectID));
	NewGameState.AddStateObject(UnitState);
	UnitState.bNeedsNewClassPopup = false;
	`XEVENTMGR.TriggerEvent('UnitPromoted', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);

	if (!m_kAvengerHUD.Movie.Stack.HasInstanceOf(class'UIArmory_Promotion')) // If we are already in the promotion screen, just close this popup
	{
		if (eAction == eUIAction_Accept)
		{
			GoToArmoryPromotion(AlertData.UnitInfo.UnitRef, true);
		}
	}
}

simulated function GoToArmoryPromotion(StateObjectReference UnitRef, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom ArmoryState;
	
	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ArmoryState = XComHQ.GetFacilityByName('Hangar');
	ArmoryState.GetMyTemplate().SelectFacilityFn(ArmoryState.GetReference(), true);

	UIArmory_MainMenu(UnitRef,,,,,, bInstant);
	UIArmory_Promotion(UnitRef, bInstant);
}

simulated function UIPsiTrainingComplete(StateObjectReference UnitRef, X2AbilityTemplate AbilityTemplate)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_PsiTrainingComplete;
	Alert.UnitInfo.UnitRef = UnitRef;
	Alert.AbilityTemplate = AbilityTemplate;
	Alert.fnCallback = PsiTrainingCompleteCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function PsiTrainingCompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	if (eAction == eUIAction_Accept)
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		
		if (XComHQ.bHasSeenFirstPsiOperative || XComHQ.SeenClassMovies.Find('PsiOperative') != INDEX_NONE)
		{
			GoToPsiChamber(AlertData.UnitInfo.UnitRef, true);
		}
		else
		{
			GoToArmoryPromotion(AlertData.UnitInfo.UnitRef, true);
		}
	}
}

simulated function GoToPsiChamber(StateObjectReference UnitRef, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom PsiChamberState;
	local StaffUnitInfo UnitInfo;
	local UIFacility CurrentFacilityScreen;
	local int emptyStaffSlotIndex;

	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	PsiChamberState = XComHQ.GetFacilityByName('PsiChamber');
	PsiChamberState.GetMyTemplate().SelectFacilityFn(PsiChamberState.GetReference(), true);

	if (PsiChamberState.GetNumEmptyStaffSlots() > 0) // First check if there are any open staff slots
	{
		// get to choose scientist screen (from staff slot)
		CurrentFacilityScreen = UIFacility(m_kAvengerHUD.Movie.Stack.GetCurrentScreen());
		emptyStaffSlotIndex = PsiChamberState.GetEmptySoldierStaffSlotIndex();
		if (CurrentFacilityScreen != none && emptyStaffSlotIndex > -1)
		{
			// Only allow the unit to be selected if they are valid
			UnitInfo.UnitRef = UnitRef;
			if (PsiChamberState.GetStaffSlot(emptyStaffSlotIndex).ValidUnitForSlot(UnitInfo))
			{
				CurrentFacilityScreen.SelectPersonnelInStaffSlot(emptyStaffSlotIndex, UnitInfo);
			}
		}
	}
}

simulated function UIPsiLabIntro(X2FacilityTemplate Template)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert Alert;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the Psi Lab alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenPsiLabIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Psi Lab Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.bHasSeenPsiLabIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		Alert = Spawn(class'UIAlert', `HQPRES);
		Alert.eAlert = eAlert_PsiLabIntro;
		Alert.FacilityTemplate = Template;
		Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
		Alert.fnCallback = PsiLabIntroCB;
		ScreenStack.Push(Alert);
	}
}

simulated function PsiLabIntroCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
}

simulated function UIPsiOperativeIntro(StateObjectReference UnitRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert Alert;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the customizations alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenPsiOperativeIntroPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Psi Operative Intro alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.bHasSeenPsiOperativeIntroPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		Alert = Spawn(class'UIAlert', `HQPRES);
		Alert.eAlert = eAlert_PsiOperativeIntro;
		Alert.UnitInfo.UnitRef = UnitRef;
		Alert.fnCallback = PsiOperativeIntroCB;
		ScreenStack.Push(Alert);
	}
}

simulated function PsiOperativeIntroCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	GoToPsiChamber(AlertData.UnitInfo.UnitRef);
}

simulated function UIBuildSlotOpen(StateObjectReference RoomRef)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_BuildSlotOpen;
	Alert.RoomRef = RoomRef;
	Alert.fnCallback = AssignBuildStaffCB;
	Alert.SoundToPlay = "Geoscape_FacilityComplete";
	ScreenStack.Push(Alert);
}

simulated function UIClearRoomSlotOpen(StateObjectReference RoomRef)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_ClearRoomSlotOpen;
	Alert.RoomRef = RoomRef;
	Alert.fnCallback = AssignBuildStaffCB;
	Alert.SoundToPlay = "Geoscape_FacilityComplete";
	ScreenStack.Push(Alert);
}

simulated function AssignBuildStaffCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_StaffSlot BuildSlotState, UnitSlotState;
	local array<XComGameState_StaffSlot> AdjacentGhostCreatingSlots;
	local XComGameState_Unit UnitState;
	local StateObjectReference StaffRef;
	local StaffUnitInfo UnitInfo;

	if (eAction == eUIAction_Accept)
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(AlertData.RoomRef.ObjectID));
		BuildSlotState = RoomState.GetBuildSlot(RoomState.GetEmptyBuildSlotIndex());
		AdjacentGhostCreatingSlots = BuildSlotState.GetAdjacentGhostCreatingStaffSlots();

		// Cycle through all crew members looking for the unstaffed engineer or scientist to fill the slot, and place them there
		foreach XComHQ.Crew(StaffRef)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StaffRef.ObjectID));
			UnitSlotState = UnitState.GetStaffSlot();
			UnitInfo.UnitRef = StaffRef;

			// Only assign a ghost unit if there are adjacent slots with available ghosts next to the build slot's room
			if (AdjacentGhostCreatingSlots.Length > 0)
			{
				if (AdjacentGhostCreatingSlots.Find(UnitSlotState) != INDEX_NONE && UnitSlotState.AvailableGhostStaff > 0)
				{
					UnitInfo.bGhostUnit = true;
				}
			}
			
			// Only allow staffing if this unit is creating available ghost units, or if they are available themselves, and are valid for the slot
			if ((UnitSlotState == none || UnitInfo.bGhostUnit) && BuildSlotState.ValidUnitForSlot(UnitInfo))
			{
				AssignStaff(BuildSlotState, UnitInfo);
				break;
			}
		}

		XComHQ.HandlePowerOrStaffingChange();
	}
}

simulated function UIStaffSlotOpen(StateObjectReference FacilityRef, X2StaffSlotTemplate StaffSlotTemplate)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_StaffSlotOpen;
	Alert.FacilityRef = FacilityRef;
	Alert.StaffSlotTemplate = StaffSlotTemplate;
	Alert.fnCallback = AssignFacilityStaffCB;
	Alert.SoundToPlay = "Geoscape_FacilityComplete";
	ScreenStack.Push(Alert);
}

simulated function AssignFacilityStaffCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState, UnitSlotState;
	local array<XComGameState_StaffSlot> AdjacentGhostCreatingSlots;
	local XComGameState_Unit UnitState;
	local StateObjectReference StaffRef;
	local StaffUnitInfo UnitInfo;

	if (eAction == eUIAction_Accept)
	{		
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(AlertData.FacilityRef.ObjectID));
		StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());
		AdjacentGhostCreatingSlots = StaffSlotState.GetAdjacentGhostCreatingStaffSlots();

		// Cycle through all crew members looking for the unstaffed engineer or scientist to fill the slot, and place them there
		foreach XComHQ.Crew(StaffRef)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StaffRef.ObjectID));
			UnitSlotState = UnitState.GetStaffSlot();
			UnitInfo.UnitRef = StaffRef;

			// Only assign a ghost unit if there are adjacent slots with available ghosts next to the staff slot's room
			if (AdjacentGhostCreatingSlots.Length > 0)
			{
				if (AdjacentGhostCreatingSlots.Find(UnitSlotState) != INDEX_NONE && UnitSlotState.AvailableGhostStaff > 0)
				{
					UnitInfo.bGhostUnit = true;
				}
			}
			
			// Only allow staffing if this unit is creating available ghost units, or if they are available themselves, and are valid for the slot
			if ((UnitSlotState == none || UnitInfo.bGhostUnit) && StaffSlotState.ValidUnitForSlot(UnitInfo))
			{
				AssignStaff(StaffSlotState, UnitInfo);
				break;
			}
		}
		
		XComHQ.HandlePowerOrStaffingChange();
	}
}

simulated function AssignStaff(XComGameState_StaffSlot StaffSlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersRoom Room;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fill Staff Slot");
	StaffSlotState.FillSlot(NewGameState, UnitInfo);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	// If the unit just added is a ghost, update its location to its new staff slot before passing to the Alerts
	if (UnitInfo.bGhostUnit)
	{
		UnitInfo.GhostLocation = StaffSlotState.GetReference();
	}

	// Trigger the appropriate popup to tell the player about the benefit they have received by filling this staff slot
	Room = StaffSlotState.GetRoom();
	if (Room != none)
	{
		if (Room.ClearingRoom)
		{
			`HQPRES.UIClearRoomSlotFilled(Room.GetReference(), UnitInfo);
		}
		else if (Room.UnderConstruction)
		{
			`HQPRES.UIConstructionSlotFilled(Room.GetReference(), UnitInfo);
		}
	}
	else
	{
		`HQPRES.UIStaffSlotFilled(StaffSlotState.GetFacility().GetReference(), StaffSlotState.GetMyTemplate(), UnitInfo);
	}
}

simulated function UIClearRoomSlotFilled(StateObjectReference RoomRef, StaffUnitInfo UnitInfo)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_ClearRoomSlotFilled;
	Alert.RoomRef = RoomRef;
	Alert.UnitInfo = UnitInfo;
	Alert.fnCallback = ClearRoomSlotFilledCB;
	Alert.SoundToPlay = "StrategyUI_Staff_Assign";
	ScreenStack.Push(Alert);
}

simulated function ClearRoomSlotFilledCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIConstructionSlotFilled(StateObjectReference RoomRef, StaffUnitInfo UnitInfo)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_BuildSlotFilled;
	Alert.RoomRef = RoomRef;
	Alert.UnitInfo = UnitInfo;
	Alert.fnCallback = ConstructionSlotFilledCB;
	Alert.SoundToPlay = "StrategyUI_Staff_Assign";
	ScreenStack.Push(Alert);
}

simulated function ConstructionSlotFilledCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIStaffSlotFilled(StateObjectReference FacilityRef, X2StaffSlotTemplate StaffSlotTemplate, StaffUnitInfo UnitInfo)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_StaffSlotFilled;
	Alert.FacilityRef = FacilityRef;
	Alert.StaffSlotTemplate = StaffSlotTemplate;
	Alert.UnitInfo = UnitInfo;
	Alert.fnCallback = StaffSlotFilledCB;
	Alert.SoundToPlay = "StrategyUI_Staff_Assign";
	ScreenStack.Push(Alert);
}

simulated function StaffSlotFilledCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function SuperSoldierAlert(StateObjectReference UnitRef, delegate<UIAlert.AlertCallback> CallbackFunction, string StaffPicture)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_SuperSoldier;
	Alert.UnitInfo.UnitRef = UnitRef;
	Alert.fnCallback = CallbackFunction;
	Alert.SoundToPlay = "SuperSoldier";
	ScreenStack.Push(Alert);

	Alert.LibraryPanel.MC.FunctionString("UpdateImage", StaffPicture);
}

simulated function UISoldierShaken(XComGameState_Unit UnitState)
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;
	local UIAlert Alert;

	// Flag the research report as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit shaken alert seen");
	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.GetReference().ObjectID));
	NewGameState.AddStateObject(NewUnitState);
	NewUnitState.bSeenShakenPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_SoldierShaken;
	Alert.UnitInfo.UnitRef = UnitState.GetReference();
	Alert.fnCallback = SoldierShakenCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp"; // TODO: Should be negative sound
	Alert.EventToTrigger = 'OnSoldierShakenPopup';
	ScreenStack.Push(Alert);
}

simulated function SoldierShakenCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UISoldierShakenRecovered(XComGameState_Unit UnitState)
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;
	local UIAlert Alert;

	// Flag the research report as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit recovered from shaken alert seen");
	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.GetReference().ObjectID));
	NewGameState.AddStateObject(NewUnitState);
	NewUnitState.bNeedsShakenRecoveredPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_SoldierShakenRecovered;
	Alert.UnitInfo.UnitRef = UnitState.GetReference();
	Alert.fnCallback = SoldierShakenRecoveredCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function SoldierShakenRecoveredCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIWeaponUpgradesAvailable()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert Alert;

	// Flag the customizations alert as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Weapon upgrades alert seen");
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.bHasSeenWeaponUpgradesPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_WeaponUpgradesAvailable;
	Alert.fnCallback = WeaponUpgradesAvailableCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function WeaponUpgradesAvailableCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UISoldierCustomizationsAvailable()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert Alert;
	
	// Flag the customizations alert as having been seen
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Soldier customizations alert seen");
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.bHasSeenCustomizationsPopup = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_CustomizationsAvailable;
	Alert.fnCallback = SoldierCustomizationsCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	ScreenStack.Push(Alert);
}

simulated function SoldierCustomizationsCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIForceUnderstrength()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert Alert;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_ForceUnderstrength;
	Alert.fnCallback = ForceUnderstrengthCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp"; // TODO: Should be negative sound

	if (XComHQ.GetNumberOfDeployableSoldiers() == 0)
	{
		Alert.EventToTrigger = 'WarningNoSoldiers';
	}
	else if (XComHQ.GetNumberOfDeployableSoldiers() < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
	{
		Alert.EventToTrigger = 'WarningNotEnoughSoldiers';
	}

	ScreenStack.Push(Alert);
}

simulated function ForceUnderstrengthCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIWoundedSoldiersAllowed()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_WoundedSoldiersAllowed;
	Alert.fnCallback = WoundedSoldiersAllowedCB;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp"; // TODO: Should be warning sound
	Alert.EventToTrigger = 'OnWoundedSoldiersAllowed';
	ScreenStack.Push(Alert);
}

simulated function WoundedSoldiersAllowedCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UILaunchMissionWarning(XComGameState_MissionSite MissionState)
{
	local XComGameState NewGameState;
	local UIAlert Alert;
	
	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!MissionState.bHasSeenLaunchMissionWarning)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Launch Mission Warning Seen");
		MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
		NewGameState.AddStateObject(MissionState);
		MissionState.bHasSeenLaunchMissionWarning = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_LaunchMissionWarning;
	Alert.fnCallback = LaunchMissionWarningCB;
	Alert.Mission = MissionState;
	Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp"; // TODO: Should be warning sound
	ScreenStack.Push(Alert);
}

simulated function LaunchMissionWarningCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{

}

simulated function UIDarkEventActivated(StateObjectReference DarkEventRef)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_DarkEvent;
	Alert.DarkEventRef = DarkEventRef;
	Alert.fnCallback = DarkEventActivatedCB;
	Alert.SoundToPlay = "GeoscapeAlerts_ADVENTControl";
	ScreenStack.Push(Alert);
}

simulated function DarkEventActivatedCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event Dark Event Popup Closed");
	`XEVENTMGR.TriggerEvent('OnDarkEventPopupClosed', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

simulated function UIPointOfInterestAlert(StateObjectReference POIRef)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_NewScanningSite;
	Alert.POIRef = POIRef;
	Alert.fnCallback = POIAlertCB;
	Alert.SoundToPlay = "Geoscape_POIReveal";
	ScreenStack.Push(Alert);
}

simulated function POIAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState_PointOfInterest POIState;
	local XComGameState NewGameState;
	
	if (eAction == eUIAction_Accept || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M10_IntroToBlacksite') == eObjectiveState_InProgress)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event POI Selected");
		`XEVENTMGR.TriggerEvent('OnPOISelected', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);

		POIState = XComGameState_PointOfInterest(`XCOMHISTORY.GetGameStateForObjectID(AlertData.POIRef.ObjectID));
		POIState.AttemptSelectionCheckInterruption();

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIPointOfInterestCompleted(StateObjectReference POIRef)
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_ScanComplete;
	Alert.POIRef = POIRef;
	Alert.fnCallback = POICompleteCB;
	Alert.SoundToPlay = "Geoscape_POIReached";
	ScreenStack.Push(Alert);
}

simulated function POICompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_PointOfInterest POIState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("POI Complete Reset");
	ResHQ.AttemptSpawnRandomPOI(NewGameState); // Attempt to spawn a new random POI
	
	// Reset the POI that was just completed, prevents two of the same type in a row
	POIState = XComGameState_PointOfInterest(NewGameState.CreateStateObject(class'XComGameState_PointOfInterest', AlertData.POIRef.ObjectID));
	NewGameState.AddStateObject(POIState);
	POIState.ResetPOI(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if (!XComHQ.bHasSeenSupplyDropReminder && XComHQ.IsSupplyDropAvailable())
	{
		UISupplyDropReminder();
	}

	if (eAction == eUIAction_Cancel)
	{
		class'UIUtilities_Strategy'.static.GetXComHQ().ReturnToResistanceHQ();

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIResourceCacheAppearedAlert()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_ResourceCacheAvailable;
	Alert.fnCallback = ResourceCacheAlertCB;
	Alert.SoundToPlay = "Geoscape_POIReveal";
	ScreenStack.Push(Alert);
}

simulated function ResourceCacheAlertCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState_ResourceCache CacheState;

	if (eAction == eUIAction_Accept)
	{
		CacheState = XComGameState_ResourceCache(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));
		CacheState.AttemptSelectionCheckInterruption();

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
	else
	{
		`GAME.GetGeoscape().Pause();
	}
}

simulated function UIResourceCacheCompleteAlert()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_ResourceCacheComplete;
	Alert.fnCallback = ResourceCacheCompleteCB;
	Alert.SoundToPlay = "Geoscape_POIReached";
	ScreenStack.Push(Alert);
}

simulated function ResourceCacheCompleteCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	if (eAction == eUIAction_Cancel)
	{
		class'UIUtilities_Strategy'.static.GetXComHQ().ReturnToResistanceHQ(false, true);

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
	else if (!class'UIUtilities_Strategy'.static.GetResistanceHQ().bHasSeenNewResistanceGoods)
	{
		UINewResHQGoodsAvailable();
	}
}

simulated function UIUFOInboundAlert(StateObjectReference UFORef)
{
	local UIAlert Alert;
	
	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_UFOInbound;
	Alert.UFORef = UFORef;
	Alert.fnCallback = UFOInboundCB;
	Alert.SoundToPlay = "Geoscape_UFO_Inbound";
	Alert.EventToTrigger = 'OnUFOEvasive';
	ScreenStack.Push(Alert);
}

simulated function UFOInboundCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	class'UIUtilities_Strategy'.static.GetXComHQ().StartUFOChase(AlertData.UFORef);
}

simulated function UIUFOEvadedAlert()
{
	local UIAlert Alert;
	
	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_UFOEvaded;
	Alert.fnCallback = ReturnToPreviousLocationCB;
	Alert.SoundToPlay = "Geoscape_UFO_Evaded";
	Alert.EventToTrigger = 'OnUFOEvaded';
	ScreenStack.Push(Alert);
}

simulated function ReturnToPreviousLocationCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{	
	if (eAction == eUIAction_Accept)
	{
		class'UIUtilities_Strategy'.static.GetXComHQ().ReturnToSavedLocation();

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UIContinentBonus(StateObjectReference ContinentRef)
{
	local UIAlert kAlert;

	`GAME.GetGeoscape().Pause();
	kAlert = Spawn(class'UIAlert', self);
	kAlert.eAlert = eAlert_ContinentBonus;
	kAlert.ContinentRef = ContinentRef;
	kAlert.fnCallback = GeoscapeAlertCB;
	kAlert.SoundToPlay = "Geoscape_Popup_Positive";
	ScreenStack.Push(kAlert);
}

simulated function UINewResHQGoodsAvailable()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_HelpResHQGoods;
	Alert.fnCallback = NewResHQGoodsAvailableCB;
	Alert.SoundToPlay = "Geoscape_PopularSupportThreshold";
	Alert.EventToTrigger = 'OnHelpResHQ';
	ScreenStack.Push(Alert);
}

simulated function NewResHQGoodsAvailableCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	if (eAction == eUIAction_Accept)
	{
		class'UIUtilities_Strategy'.static.GetXComHQ().ReturnToResistanceHQ(true, false);

		if (`GAME.GetGeoscape().IsScanning())
			StrategyMap2D.ToggleScan();
	}
}

simulated function UILowIntel()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert kAlert;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenLowIntelPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Low Intel Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.bHasSeenLowIntelPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	
	kAlert = Spawn(class'UIAlert', self);
	kAlert.eAlert = eAlert_LowIntel;
	kAlert.fnCallback = LowWarningCB;
	kAlert.SoundToPlay = "Geoscape_DoomIncrease";
	ScreenStack.Push(kAlert);
}

simulated function UILowSupplies()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert kAlert;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenLowSuppliesPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Low Supplies Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.bHasSeenLowSuppliesPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	
	kAlert = Spawn(class'UIAlert', self);
	kAlert.eAlert = eAlert_LowSupplies;
	kAlert.fnCallback = LowWarningCB;
	kAlert.SoundToPlay = "Geoscape_DoomIncrease";
	ScreenStack.Push(kAlert);
}

simulated function UILowScientists()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert kAlert;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	kAlert = Spawn(class'UIAlert', self);

	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenLowScientistsPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Low Scientists Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.bHasSeenLowScientistsPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		kAlert.EventToTrigger = 'WarningNeedMoreScientists';
	}

	kAlert.eAlert = eAlert_LowScientists;
	kAlert.fnCallback = LowWarningCB;
	kAlert.SoundToPlay = "Geoscape_DoomIncrease";
	ScreenStack.Push(kAlert);
}

simulated function UILowEngineers()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert kAlert;


	// Flag the warning alert as having been seen and show it, otherwise do nothing
	if (!XComHQ.bHasSeenLowEngineersPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Low Engineers Warning Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.bHasSeenLowEngineersPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		//Moved the spawn on the alert to inside the bHasSeenLowEngineersPopup check to avoid accidentally spawning double alerts
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

		kAlert = Spawn(class'UIAlert', self);;
		kAlert.EventToTrigger = 'WarningNeedMoreEngineers';

	
		kAlert.eAlert = eAlert_LowEngineers;
		kAlert.fnCallback = LowWarningCB;
		kAlert.SoundToPlay = "Geoscape_DoomIncrease";
		ScreenStack.Push(kAlert);
	}
}

simulated function LowWarningCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
}

simulated function UILowScientistsSmall()
{
	local UIAlert kAlert;
	
	kAlert = Spawn(class'UIAlert', self);
	kAlert.eAlert = eAlert_LowScientistsSmall;
	kAlert.fnCallback = LowScientistsSmallCB;
	kAlert.SoundToPlay = "Geoscape_DoomIncrease";
	kAlert.EventToTrigger = 'WarningNeedMoreScientists';
	ScreenStack.Push(kAlert);
}

simulated function LowScientistsSmallCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	if (eAction == eUIAction_Accept)
	{
		UILowScientists();
	}
}

simulated function UILowEngineersSmall()
{
	local UIAlert kAlert;

	kAlert = Spawn(class'UIAlert', self);
	kAlert.eAlert = eAlert_LowEngineers;
	kAlert.fnCallback = LowEngineersSmallCB;
	kAlert.SoundToPlay = "Geoscape_DoomIncrease";
	kAlert.EventToTrigger = 'WarningNeedMoreEngineers';
	ScreenStack.Push(kAlert);
}

simulated function LowEngineersSmallCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	if (eAction == eUIAction_Accept)
	{
		UILowEngineers();
	}
}

simulated function UISupplyDropReminder()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert kAlert;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (!XComHQ.bHasSeenSupplyDropReminder)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Supply Drop Reminder Seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.bHasSeenSupplyDropReminder = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	kAlert = Spawn(class'UIAlert', self);
	kAlert.eAlert = eAlert_SupplyDropReminder;
	kAlert.SoundToPlay = "Geoscape_POIReveal";
	ScreenStack.Push(kAlert);
}

simulated function UIPowerCoilShielded()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIAlert kAlert;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (!XComHQ.bHasSeenPowerCoilShieldedPopup)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Power Coil Shielded alert seen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.bHasSeenPowerCoilShieldedPopup = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		kAlert = Spawn(class'UIAlert', self);
		kAlert.eAlert = eAlert_PowerCoilShielded;
		kAlert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
		ScreenStack.Push(kAlert);
	}
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                   GAME ENDING POPUPS
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// Preview build functions
simulated function PreviewBuildComplete()
{
	local TDialogueBoxData kData;

	kData.strTitle = m_strPreviewBuildTitle;
	kData.strText = m_strPreviewBuildText;
	kData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kData.eType = eDialog_Normal;
	kData.fnCallback = PreviewBuildCompleteCallback;

	UIRaiseDialog(kData);
}

simulated function PreviewBuildCompleteCallback(eUIAction eAction)
{
	ClearUIToHUD();
	UIEndGame();
	`XCOMHISTORY.ResetHistory();
	ConsoleCommand("disconnect");
}

simulated public function UIDoomTimer()
{
	local UIAlert Alert;

	Alert = Spawn(class'UIAlert', self);
	Alert.eAlert = eAlert_AlienVictoryImminent;
	Alert.fnCallback = DoomTimerCB;
	Alert.SoundToPlay = "Geoscape_DoomIncrease";
	Alert.EventToTrigger = 'OnFinalCountdown';
	ScreenStack.Push(Alert);
}

simulated private function DoomTimerCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();
}

simulated public function UIYouLose()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlayLossMusic();	

	UIEndGameStats(false);
}

simulated public function UIYouWin()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlayCreditsMusic();
	
	UIEndGameStats(true);
}

simulated function UIEndGameStats(bool bWon)
{
	local UIEndGameStats StatsScreen;
	StatsScreen = Spawn(class'UIEndGameStats', self);
	StatsScreen.bGameWon = bWon;
	ScreenStack.Push(StatsScreen);
}

simulated private function Disconnect()
{
	`XCOMHISTORY.ResetHistory();
	ConsoleCommand("disconnect");
}

//----------------------------------------------------
//----------------------------------------------------
// DATA SCREEN MANAGER 
// Use this to access a manager. Automatically creates the manager if not already live. 
// This is the standard access for the managers, unless 
public function XGScreenMgr GetMgr( class<actor> kMgrClass, optional IScreenMgrInterface kInterface = none, optional int iView = -1, optional bool bIgnoreIfDoesNotExist = false )
{
	local XGScreenMgr kMgr; 

	// IF we find a manager already activated, use the live one. 
	foreach m_arrScreenMgrs(kMgr)
	{
		if( kMgr.Class != kMgrClass ) continue; 
		
		if( kInterface != none )
			kMgr.m_kInterface = kInterface; 

		if( iView != -1 )
			kMgr.GoToView( iView );

		return kMgr;
	}

	if (!bIgnoreIfDoesNotExist)
	{
		// ELSE the manager type was not found, 
		// so create the desired manager type before linking to it.
		kMgr = XGScreenMgr(Spawn( kMgrClass, self ));
		m_arrScreenMgrs.AddItem( kMgr );
		if( kInterface == none ) `log("HQPres.GetMgr() received kInterface == 'none' while trying to create a new manager '"$ kMgrClass $"'. This shouldn't happen.",,'uixcom');
		kMgr.m_kInterface = kInterface; 
		kMgr.Init( iView );
	}

	return kMgr; 	
}

// Use when you need to preform a manager and set particular information within the normal sequence, ex. before Init(). 
// - only use manager which has been spawned to this pres layer as Owner,
// - assigned an interface,
// - not a class type already in use,
// - already initted.
// Returns true if adding was successful. 
public function bool AddPreformedMgr( XGScreenMgr kMgr )
{
	local XGScreenMgr currentMgr;

	// Check that this type is not already in use 
	foreach m_arrScreenMgrs(currentMgr)
	{
		if( kMgr.Class == currentMgr.Class )
		{
			`log("XComHQPres:AddPreformedMgr(): Trying to add a pre-formed manager, but manager of that type has been found in the screen managers array. '" $kMgr.Class $"'. Removing old one and adding new one.",,'uixcom');
			m_arrScreenMgrs.RemoveItem( currentMgr );
		}
	}

	// Check that the mgr has been assigned an interface properly. 
	if( kMgr.m_kInterface == none )
	{
		`log("XComHQPres:AddPreformedMgr(): kMgr does not have an interface assigned. '" $kMgr $"'",,'uixcom');
		return false;
	}

	//CHeck that the mgr is owned by the HQPres.
	if( kMgr.Owner != self )
	{
		`log("XComHQPres:AddPreformedMgr(): kMgr isn't assigned to the HQPres layer as owner. '" $kMgr $"'",,'uixcom');
		return false;
	}

	// No way to currently verify is has been initted. 

	// Passed all checks, so add to the array and report success. 
	m_arrScreenMgrs.AddItem( kMgr );	
	return true; 	
}

public function bool RemoveMgr( class<actor> kMgrClass )
{
	local XGScreenMgr kMgr; 

	foreach m_arrScreenMgrs(kMgr)
	{
		if( kMgr.Class != kMgrClass ) continue; 

		// Remove the manager from array and destroy it cleanly.
		m_arrScreenMgrs.RemoveItem( kMgr ); 
		kMgr.Destroy();
		return true;
	}

	// ELSE: 
	`log( "UIScreenDataMgr attempted to remove a manager type '" $ string(kMgrClass) $"', but item was not found ",,'uixcom');
	return false; 
}

// Use to see if there's a valid mgr already in teh system. 
public function bool IsMgrRegistered( class<actor> kMgrClass )
{
	local XGScreenMgr kMgr;

		// IF we find a manager already activated, use the live one. 
	foreach m_arrScreenMgrs(kMgr)
	{
		if( kMgr.Class == kMgrClass )
			return true;
	}
	return false;
}
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             END DEPRECATED UI
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//----------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             GAME INTERFACE
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function bool IsGameplayOptionEnabled(EGameplayOption option) 
{
	return `GAME.m_arrSecondWave[option] > 0;
}

//----------------------------------------------------
//----------------------------------------------------

simulated function bool AllowSaving()
{
	return super.AllowSaving();
}

simulated function bool ISCONTROLLED()
{
	return `GAME.m_bControlledStart;
}

//----------------------------------------------------
//----------------------------------------------------
function PostFadeForBeginCombat()
{
}

simulated function OnPauseMenu(bool bOpened)
{
	
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             CAMERA INTERFACE
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

simulated function XComHeadquartersCamera GetCamera()
{
	return XComHeadquartersCamera(XComHeadquartersController(Owner).PlayerCamera);
}

simulated function bool CAMIsBusy()
{
	return m_kCamera != none && m_kCamera.IsBusy();
}

reliable client function CAMLookAtEarth( vector2d v2Location, optional float fZoom = 1.0f, optional float fInterpTime = 0.75f )
{
	XComHeadquartersCamera(XComHeadquartersController(Owner).PlayerCamera).NewEarthView(fInterpTime);
	`EARTH.SetViewLocation(v2Location);
	`EARTH.SetCurrentZoomLevel(fZoom);

	//m_kCamera.LookAtEarth( v2Location, fZoom, bCut );
	//GetCamera().FocusOnEarthLocation(v2Location, fZoom, fInterpTime);
}

reliable client function CAMSaveCurrentLocation()
{
	`EARTH.SaveViewLocation();
	`EARTH.SaveZoomLevel();
}

reliable client function CAMRestoreSavedLocation(optional float fInterpTime = 0.75f)
{
	`EARTH.RestoreSavedViewLocation();
	`EARTH.RestoreSavedZoomLevel(); //1.0f is the default zoom level
	if(ScreenStack.IsInStack(class'UIStrategyMap'))
	{
		XComHeadquartersCamera(XComHeadquartersController(Owner).PlayerCamera).NewEarthView(fInterpTime); //0.75 is the default interp time
	}
}

reliable client function CAMLookAt( vector vLocation, optional bool bCut )
{
	//m_kCamera.LookAt( vLocation, bCut );
}

// 1.0f is normal game zoom
reliable client function CAMZoom( float fZoom )
{
	m_kCamera.Zoom( fZoom );
}

reliable client function LookAtSelectedRoom(XComGameState_HeadquartersRoom RoomStateObject, 
	optional float InterpTime = 2.0)
{
	local int GridIndex;
	local int RoomRow;
	local int RoomColumn;
	local string CameraName;
	local XComGameState_FacilityXCom FacilityStateObject;

	if (RoomStateObject.MapIndex >= 3 && RoomStateObject.MapIndex <= 14)
	{
		GridIndex = RoomStateObject.MapIndex - 3;
		RoomRow = (GridIndex / 3) + 1;
		RoomColumn = (GridIndex % 3) + 1;

		CameraName = "AddonCam" $ "_R" $ RoomRow $ "_C" $ RoomColumn;
	}
	else
	{
		FacilityStateObject = 
			XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(RoomStateObject.Facility.ObjectID));
		CameraName = "UIDisplayCam_"$FacilityStateObject.GetMyTemplateName();
	}

	m_kFacilityGrid.LookAtSelectedRoom();
	GetCamera().SetInitialFocusToCamera(name(CameraName));
}
//<workshop> PARABOLIC_CAMERA_FACILITY_TRANSITION AMS 2015/11/05
//INS:
// NOTE_TO_INTEGRATOR: The sister function is CAMSetFacilityTransitionForRoom, all changes should be duplicated there.
//</workshop>
function CAMLookAtRoom(XComGameState_HeadquartersRoom RoomStateObject, optional float fInterpTime = 2 )
{	
	local int GridIndex;
	local int RoomRow;
	local int RoomColumn;
	local string CameraName;
	local XComGameState_FacilityXCom FacilityStateObject;
	local XComHeadquartersCheatManager CheatMgr;

	`log("CAMLookAtRoom" @ RoomStateObject @ fInterpTime,,'DebugHQCamera');

	if( RoomStateObject.MapIndex >= 3 && RoomStateObject.MapIndex <= 14 )
	{
		//If this room is part of the build facilities grid, use the grid location
		//to look at it

		GridIndex = RoomStateObject.MapIndex - 3;
		RoomRow = (GridIndex / 3) + 1;
		RoomColumn = (GridIndex % 3) + 1;

		CAMLookAtHQTile( RoomColumn, RoomRow, fInterpTime );
	}
	else
	{
		FacilityStateObject = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(RoomStateObject.Facility.ObjectID));

		CheatMgr = XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager);
		if( CheatMgr != None && CheatMgr.bGamesComDemo && FacilityStateObject.GetMyTemplateName() == 'CommandersQuarters' )
		{
			CameraName = "UIDisplayCam_ResistanceScreen";
			`XCOMGRI.DoRemoteEvent('CIN_ShowCouncil');

			HideUIForCinematics();
			m_kUIMouseCursor.Hide();

			if( WorldInfo.RemoteEventListeners.Find(self) == INDEX_NONE )
			{
				WorldInfo.RemoteEventListeners.AddItem(self);
			}
		}
		else
		{
			CameraName = "UIDisplayCam_"$FacilityStateObject.GetMyTemplateName();
		}

		//This room is one of the default facilities, or special - use the custom named camera
		CAMLookAtNamedLocation(CameraName, ForceCameraInterpTime < 0.0f ? fInterpTime : ForceCameraInterpTime);
	}
}

reliable client function CAMLookAtHorizon( vector2d v2LookAt )
{
	`log("CAMLookAtHorizon",,'DebugHQCamera');
	m_kCamera.LookAtHorizon( v2LookAt );
}

// NOTE_TO_INTEGRATOR: The sister function is CAMSetFacilityTransitionForNamedLocation, all changes should be duplicated there.
reliable client function CAMLookAtNamedLocation( string strLocation, optional float fInterpTime = 2, optional bool bSkipBaseViewTransition )
{
	// Pan Camera to active room
	`log("CAMLookAtNamedLocation" @ strLocation @ fInterpTime,,'DebugHQCamera');
	GetCamera().StartRoomViewNamed(name(strLocation), ForceCameraInterpTime < 0.0f ? fInterpTime : ForceCameraInterpTime, bSkipBaseViewTransition);
}

//Use push/pop camera interp time within the same method, always
function PushCameraInterpTime(float NewValue)
{
	ForceCameraInterpTime = NewValue;
}

function PopCameraInterpTime()
{
	ForceCameraInterpTime = -1.0f;
}

// NOTE_TO_INTEGRATOR: The sister function is CAMSetFacilityTransitionForHQTile, all changes should be duplicated there.
// Look at an expansion tile
reliable client function CAMLookAtHQTile( int x, int y, optional float fInterpTime = 2 )
{
	local string strLocation, strRow, strColumn;
	`log("CAMLookAtHQTile" @ x @ y @ fInterpTime,,'DebugHQCamera');

	strLocation = "AddonCam";

	strRow = "_R"$y;
	strColumn = "_C"$x;

	strLocation $= strRow;
	strLocation $= strColumn;

	// Pan Camera to specified base tile
	GetCamera().StartRoomViewNamed( name(strLocation), fInterpTime );
}

// PARABOLIC_CAMERA_FACILITY_TRANSITION AMS 2015/11/05
// FacilityTransition means we are moving from one facility to another in a camera swoop,
// in a parabolic fashion, with the 'Base' camera position in the middle.  It is required to
// look up the second facility we are moving to, so we can pre-calculate our camera path.
//INS:

// Sets the facility destination, based on the FacilityRef of the room we are moving to, and
// tell the camera that we are moving from the first facility towards the 'Base' camera position.
reliable client function SetFacilityTransition(StateObjectReference FacilityRef, bool Parabolic)
{
	`log("SetFacilityTransition "$FacilityRef.ObjectID,,'DebugHQCamera');

	CAMSetFacilityTransitionForRoom(GetFacilityAvenger(FacilityRef).GetRoom());

	m_eParabolicFacilityTransitionType = FTT_Parabolic_In;
	m_bParabolic = Parabolic;

}

// Transitions between base to strategy map, or strategy map to base, require two camera transitions, so we call these from the triggered events.
reliable client function BeginGeoscapeCameraTransition()
{
	`log("XComHQPresentationLayer::BeginGeoscapeCameraTransition",,'DebugHQCamera');
	m_bGeoscapeTransition = true;
}

// Transitions between base to strategy map, or strategy map to base, require two camera transitions, so we call these from the triggered events.
reliable client function EndGeoscapeCameraTransition()
{
	`log("XComHQPresentationLayer::EndGeoscapeCameraTransition",,'DebugHQCamera');
	m_bGeoscapeTransition = false;
	ReachedFacilityTransition();
}

reliable client function OnCameraInterpolationComplete()
{
	local XComHeadquartersCamera Camera;

	Camera = GetCamera();
	`log("XComHQPresentationLayer::OnCameraInterpolationComplete" @ `ShowVar(m_bParabolic) @ `ShowVar(m_bGeoscapeTransition) @ `ShowVar(Camera.CurrentRoom),,'DebugHQCamera');

	if (m_bParabolic) // From facility to 'base' to facility.
	{
		if (EnteringParabolicFacilityTransition()) // Halfway through the parabolic camera transition.
		{
			`log("was EnteringParabolicFacilityTransition",,'DebugHQCamera');
			
			m_eParabolicFacilityTransitionType = FTT_Parabolic_Out; // Finished the first half of the parabola, now onto the second.

			PlayQueuedNarrative(); // Start playing the queued narrative now that we're half-way through the parabolic camera transition.
		}
		else if (`HQPRES.ExitingParabolicFacilityTransition()) // Finished the parabolic camera transition.
		{
			`log("was ExitingParabolicFacilityTransition",,'DebugHQCamera');
		
			// The .001 seconds allow any processor-heavy UI initialization triggered by ReachedFacilityTransition to happen
			// next frame, so the camera can fully-reach the destination before any hitches occur.
			SetTimer( 0.001f, false, 'ReachedFacilityTransition' );
		}
	}
	else if (m_bGeoscapeTransition) // Transitions between base to strategy map, or strategy map to base, require special camera transitions.
	{
		m_kCamera.Camera().bHasOldCameraState = false; // Tell the HQCamera to stop interpolating, because the camera transition is done.

		// Note: The call to ReachedFacilityTransform happens in EndGeoscapeCameraTransition().
	}
	else // From 'base' to facility.
	{
		// The .001 seconds allow any processor-heavy UI initialization triggered by ReachedFacilityTransition to happen
		// next frame, so the camera can fully-reach the destination before any hitches occur.
		SetTimer( 0.001f, false, 'ReachedFacilityTransition' );
	}
}

// Tells the camera we have reached the end of the facility transition.
reliable client function ReachedFacilityTransition()
{
	`log("ReachedFacilityTransition",,'DebugHQCamera');

	// If there is a queued fade-to-black or movie, play it. 
	PlayQueuedNarrative();
	PlayQueuedListExpansions();
	PlayQueuedScreenMovie();
	
	m_eParabolicFacilityTransitionType = FTT_None;
	m_bParabolic = false;
	m_bQueueListExpansion = false;

	m_kCamera.Camera().bHasOldCameraState = false; // Tell the HQCamera to stop interpolating, because the camera transition is done.

	//<workshop> RESOURCE_HEADER_DISPLAYING_IN_GEOSCAPE_FIX kmartinez 2016-06-15
	//INS:
	// We're updating the resources here, because we don't display them unless we're done transitioning.(kmartinez)
	m_kAvengerHUD.UpdateResources();
	`HQPRES.GetUIComm().RefreshAnchorListener();
	//</workshop>
}

reliable client function XComGameState_FacilityXCom GetFacilityAvenger(StateObjectReference FacilityRef)
{
	return XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
}

// Means the camera is swooping from the first facility to the 'Base' camera position. (First half of the parabola.)
reliable client function bool EnteringParabolicFacilityTransition()
{
	return m_bParabolic && m_eParabolicFacilityTransitionType == FTT_Parabolic_In;
}

// Means the camera has reached the 'Base' camera position and is swooping to the second facility. (Second half of the parabola.)
reliable client function bool ExitingParabolicFacilityTransition()
{
	return m_bParabolic && m_eParabolicFacilityTransitionType == FTT_Parabolic_Out;
}


// Block user input when the camera is transitioning or fullscreen video is playing.
reliable client function bool NonInterruptiveEventsOccurring()
{
	local XComHeadquartersCamera Camera;

	Camera = GetCamera();

	return m_bParabolic ||                                   // handles transition between rooms
		m_bGeoscapeTransition ||                             // handles transition to / from strategy map
	    (Camera != None && (Camera.IsMoving() && Camera.bHasOldCameraState) && 
		 Camera.CurrentRoom != 'UIDisplayCam_CIC' &&
		 Camera.CurrentRoom != 'UIBlueprint_CustomizeMenu' &&
		 Camera.CurrentRoom != 'UIBlueprint_CustomizeHead' &&
		 Camera.CurrentRoom != 'UIBlueprint_CustomizeLegs' &&
		 Camera.CurrentRoom != 'FacilityBuildCam' &&
		 Camera.CurrentRoom != 'PreM_UIDisplayCam_SquadSelect' && 
		 Camera.CurrentRoom != 'UIDisplayCam_ResistanceScreen' && 
		 Camera.CurrentRoom != 'Base') ||                    // handle any camera movement to / from rooms
	    (`XENGINE.IsAnyMoviePlaying() && 
		 !class'XComEngine'.static.IsLoadingMoviePlaying()); // blocks HQ and screen input while a movie (other than the loading screen) is playing
}

// Because the new strategy camera code is suspected of a bug, this will help diagnose, in that case, why
// non-interruptive events are occurring, if indeed this system is the one blocking events.
reliable client function DiagnoseWhyNonInterruptiveEventsAreOccurring()
{
	local XComHeadquartersCamera Camera;
	local bool bCameraIsMoving;
	local bool bIsAnyMoviePlaying;
	
	Camera = GetCamera();
	bCameraIsMoving = Camera.IsMoving();
	bIsAnyMoviePlaying = `XENGINE.IsAnyMoviePlaying();
	`log("XXX DiagnoseWhyNonInterruptiveEventsAreOccurring" @ `ShowVar(m_bParabolic) @ `ShowVar(m_bGeoscapeTransition) @ `ShowVar(bCameraIsMoving) @ `ShowVar(Camera.bHasOldCameraState) @ `ShowVar(Camera) @ `ShowVar(Camera.CurrentRoom) @ `ShowVar(bIsAnyMoviePlaying));
}

function EventListenerReturn OnNarrativeEventTrigger(XComGameState_Objective Objective, Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local QueuedNarrative NewQueuedNarrative;

	`log("XComHQPresentationLayer::OnNarrativeEventTrigger:" @ Objective @ EventData @ EventSource @ GameState @ EventID,,'DebugHQCamera');

	// If the camera is moving between facilities, queue it to play after the transition.
	// Otherwise, just play the fade.
	if (m_bParabolic)
	{
		NewQueuedNarrative.Objective = Objective;
		NewQueuedNarrative.EventData = EventData;
		NewQueuedNarrative.EventSource = EventSource;
		NewQueuedNarrative.GameState = GameState;
		NewQueuedNarrative.EventID = EventID;
		m_QueuedNarratives.AddItem(NewQueuedNarrative);

		`log("Adding Queued Narrative",,'DebugHQCamera');
		return ELR_NoInterrupt;
		//</workshop>
	}

	return Objective.DoNarrativeEventTrigger(EventData, EventSource, GameState, EventID);
}

// Play all queued movies, then empty the queue.
simulated function PlayQueuedNarrative()
{
	local int i;
	local QueuedNarrative NewQueuedNarrative;

	`log("PlayQueuedNarrative",,'DebugHQCamera');

	for (i = 0; i < m_QueuedNarratives.Length; ++i)
	{
		NewQueuedNarrative = m_QueuedNarratives[i];
		
		NewQueuedNarrative.Objective.DoNarrativeEventTrigger(NewQueuedNarrative.EventData, NewQueuedNarrative.EventSource, NewQueuedNarrative.GameState, NewQueuedNarrative.EventID);
	}
	m_QueuedNarratives.Length = 0;
}

// Show or hide avenger shortcut list, or all shortcuts, according to the arguments we stored.
// eCat - the index of the category tab
// bShow - if true, we are queuing a show; otherwise, we are queuing a hide
// bAllShortcuts - if true, show or hide all shortcuts; if false, just show or hide the list
simulated private function DoAvengerListExpansion(int eCat, bool bShow, bool bAllShortcuts)
{
	if (bShow)
	{
		if (bAllShortcuts)
			m_kAvengerHUD.Shortcuts.DoShow();
		else
			m_kAvengerHUD.Shortcuts.DoShowList(eCat);
	}
	else
	{
		if (bAllShortcuts)
			m_kAvengerHUD.Shortcuts.DoHide();
		else
			m_kAvengerHUD.Shortcuts.DoHideList();
	}
}

// Show avenger shortcut list, or queue the list expansion of the camera is in transit.
// eCat - the index of the category tab
// bShow - if true, we are queuing a show; otherwise, we are queuing a hide
// bAllShortcuts - if true, show or hide all shortcuts; if false, just show or hide the list
simulated function ShowAvengerShortcutList(int eCat, bool bShow, bool bAllShortcuts)
{
	local QueuedListExpansion NewQueuedListExpansion;

	`log("XComHQPresentationLayer::ShowAvengerShortcutList:" @ eCat,,'DebugHQCamera');

	if (!bShow)
	{
		// Do the hiding now, since hiding should always be immediate, even if there's a 
		// camera transition.  However, queue it as well, since hides and shows often come in sets
		// and it may need to be reapplied to the end of a show-hide queue.
		DoAvengerListExpansion(eCat, bShow, bAllShortcuts);
	}

	// If the camera is moving between facilities, queue it to play after the transition.
	// Also, note m_bQueueListExpansion handles the case in which we select a new category the frame before
	// the camera transition has started, and the events still need to be queued.
	// Otherwise, just do the list expansion event.
	if (m_bQueueListExpansion || NonInterruptiveEventsOccurring() )
	{
		NewQueuedListExpansion.eCat = eCat;
		NewQueuedListExpansion.bShow = bShow;
		NewQueuedListExpansion.bAllShortcuts = bAllShortcuts;
		m_QueuedListExpansions.AddItem(NewQueuedListExpansion);

		// Testing: 
		//   bShow - so we can set m_bAvengerListExpansionDone when list expansions are waiting to be done.
		//   NonInterruptiveEventsOccurring() - so this does not trigger during the loading screen and prevent loading.     
		if (bShow) // && NonInterruptiveEventsOccurring())
			m_bAvengerListExpansionDone = false;

		`log("Adding Queued List Expansion" @ NewQueuedListExpansion.eCat @ NewQueuedListExpansion.bShow @ NewQueuedListExpansion.bAllShortcuts,,'DebugHQCamera');
		return;
	}

	// If not queued, just show or hide the list immediately.
	`log("Showing avenger shortcut list (non-queued)",,'DebugHQCamera');
	if (bShow)
	{
		DoAvengerListExpansion(eCat, bShow, bAllShortcuts);
	}
}

simulated function ClearQueuedListExpansions()
{
	m_QueuedListExpansions.Length = 0;
}

// Play all queued avenger shortcut list expansions, then empty the queue.
simulated function PlayQueuedListExpansions()
{
	local int i;
	local QueuedListExpansion NewQueuedListExpansion;
	local bool bDoShowListFound;
	local bool bDoShowFound;
	
	`log("PlayQueuedListExpansions",,'DebugHQCamera');

	// Optimize the m_QueuedListExpansions by filtering out all but the last DoShowList,
	// as it is the most expensive, and the index it takes indicates the index of the list 
	// item to be selected - obviously no more than one can be selected.
	// Also Remove all but the last DoShow.
	for (i = m_QueuedListExpansions.Length - 1; i >= 0; --i)
	{
		NewQueuedListExpansion = m_QueuedListExpansions[i];

		if (NewQueuedListExpansion.bShow && !NewQueuedListExpansion.bAllShortcuts)
		{
			if (!bDoShowListFound)
			{
				bDoShowListFound = true; // The last DoShowList of the list has been encountered.
			}
			else
			{
				m_QueuedListExpansions.Remove(i, 1); // A redundant DoShowList has been found, remove it.
			}
		}
		else if (NewQueuedListExpansion.bShow && NewQueuedListExpansion.bAllShortcuts)
		{
			if (!bDoShowFound)
			{
				bDoShowFound = true; // The last DoShow of the list has been encountered.
			}
			else
			{
				m_QueuedListExpansions.Remove(i, 1); // A redundant DoShow has been found, remove it.
			}
		}
	}

	for (i = 0; i < m_QueuedListExpansions.Length; ++i)
	{
		NewQueuedListExpansion = m_QueuedListExpansions[i];

		`log("Playing queued list expansion" @ NewQueuedListExpansion.eCat,,'DebugHQCamera');
		DoAvengerListExpansion(NewQueuedListExpansion.eCat, NewQueuedListExpansion.bShow, NewQueuedListExpansion.bAllShortcuts);
	}
	m_QueuedListExpansions.Length = 0;

	// Allow .5 seconds for the list expansion to complete before triggering that it is done.
	if (!m_bAvengerListExpansionDone)
		SetTimer(0.5, false, 'TriggerAvengerListExpansionDone');
}

function TriggerAvengerListExpansionDone()
{
	`log("TriggerAvengerListExpansionDone",,'DebugHQCamera');
	m_bAvengerListExpansionDone = true;
}

function bool CrewSpawningShouldWaitForPendingListExpansion()
{
	return !m_bAvengerListExpansionDone && !`XENGINE.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying();
}

// Notifies us when an Avenger shortcut tab is selected, so we can know whether to queue Avenger list expansion or not.
function SelectAvengerShortcut(int NewShortcutTab, int CurrentShortcutTab)
{
	// Queue list expansion events in this case, since we will be transition from one room to another within a frame or two.
	m_bQueueListExpansion = (NewShortcutTab != CurrentShortcutTab);
}

// Load a UI screen, or queue its loading while the camera is in transit.
// Screen - the UIScreen
// Movie - the Flash movie
simulated function LoadUIScreen(UIScreen Screen, UIMovie Movie)
{
	local UIFacility Facility;
	//local QueuedScreenMovie ScreenMovie;
	
	`log("LoadUIScreen" @ `ShowVar(Screen) @ `ShowVar(Movie),,'DebugHQCamera');

	Facility = UIFacility(Screen);
	/*if (Facility != None && !Facility.bInstantInterp) //Disabled this change for instant transitions, as it broke many UIAlert callbacks - BET 2016-06-28
	{
		// Queue the loading and initialization of the UIScreen and the associated Flash movie.
		ScreenMovie.Facility = Facility;
		ScreenMovie.Movie = Movie;
		m_QueuedScreenMovies.AddItem(ScreenMovie);
	}
	else
	{*/
		ScreenStack.LoadUIScreen(Screen, Movie);
	/*}*/
	if( Facility != None ) // bsg-dforrest (7.15.16): null access warnings
	{
		// Play the camera transition right away.
		Facility.HQCamLookAtThisRoom();
	}	
}

// Play all queued screen movies, then empty the queue.
simulated function PlayQueuedScreenMovie()
{
	local int i;
	local QueuedScreenMovie ScreenMovie;

	`log("PlayQueuedScreenMovie",,'DebugHQCamera');

	for (i = 0; i < m_QueuedScreenMovies.Length; ++i)
	{
		ScreenMovie = m_QueuedScreenMovies[i];

		`log("Playing queued ScreenMovie:" @ `ShowVar(ScreenMovie.Facility) @ `ShowVar(ScreenMovie.Movie),,'DebugHQCamera');
		ScreenStack.LoadUIScreen(ScreenMovie.Facility, ScreenMovie.Movie);
	}
	m_QueuedScreenMovies.Length = 0;
}

// Gets all the camera properties of the second facility we are moving toward.
function GetFacilityTransition(out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha)
{
	out_Focus 			= m_ParabolicFacilityTransition_Focus;
	out_Rotation 		= m_ParabolicFacilityTransition_Rotation;
	out_ViewDistance 	= m_ParabolicFacilityTransition_ViewDistance;
	out_FOV 			= m_ParabolicFacilityTransition_FOV;
	out_PPSettings 		= m_ParabolicFacilityTransition_PPSettings;
	out_PPOverrideAlpha = m_ParabolicFacilityTransition_PPOverrideAlpha;
}

// NOTE: The sister function to CAMLookAtNamedLocation, except it sets the second facility camera properties.
reliable client function private CAMSetFacilityTransitionForNamedLocation( string strLocation )
{
	`log("CAMSetFacilityTransitionForNamedLocation" @ strLocation,,'DebugHQCamera');

	GetCamera().GetViewFromCameraName(none, name(strLocation), m_ParabolicFacilityTransition_Focus, m_ParabolicFacilityTransition_Rotation, m_ParabolicFacilityTransition_ViewDistance, m_ParabolicFacilityTransition_FOV, m_ParabolicFacilityTransition_PPSettings, m_ParabolicFacilityTransition_PPOverrideAlpha );
}

// NOTE: The sister function to CAMLookAtHQTile, except it sets the second facility camera properties.
reliable client function private CAMSetFacilityTransitionForHQTile( int x, int y )
{
	local string strLocation, strRow, strColumn;


	`log("CAMSetFacilityTransitionForHQTile" @ x @ y,,'DebugHQCamera');

	strLocation = "AddonCam";

	strRow = "_R"$y;
	strColumn = "_C"$x;

	strLocation $= strRow;
	strLocation $= strColumn;

	// Pan Camera to specified base tile
	GetCamera().GetViewFromCameraName( none, name(strLocation), m_ParabolicFacilityTransition_Focus, m_ParabolicFacilityTransition_Rotation, m_ParabolicFacilityTransition_ViewDistance, m_ParabolicFacilityTransition_FOV, m_ParabolicFacilityTransition_PPSettings, m_ParabolicFacilityTransition_PPOverrideAlpha );
}

// NOTE: The sister function to CAMLookAtRoom, except it sets the second facility camera properties.
reliable client function private CAMSetFacilityTransitionForRoom( XComGameState_HeadquartersRoom RoomStateObject)
{
	local int GridIndex;
	local int RoomRow;
	local int RoomColumn;
	local string CameraName;
	local XComGameState_FacilityXCom FacilityStateObject;

	`log("CAMSetFacilityTransitionForRoom" @ RoomStateObject ,,'DebugHQCamera');

	if( RoomStateObject.MapIndex >= 3 && RoomStateObject.MapIndex <= 14 )
	{
		//If this room is part of the build facilities grid, use the grid location
		//to look at it

		GridIndex = RoomStateObject.MapIndex - 3;
		RoomRow = (GridIndex / 3) + 1;
		RoomColumn = (GridIndex % 3) + 1;

		CAMSetFacilityTransitionForHQTile( RoomColumn, RoomRow );
	}
	else
	{
		FacilityStateObject = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(RoomStateObject.Facility.ObjectID));

		CameraName = "UIDisplayCam_"$FacilityStateObject.GetMyTemplateName();

		//This room is one of the default facilities, or special - use the custom named camera
		CAMSetFacilityTransitionForNamedLocation(CameraName );
	}
}
//</workshop>

defaultproperties
{
	m_eUIMode = eUIMode_Strategy;
	m_bIsShuttling = false;
	m_bCanPause = true;
	ForceCameraInterpTime = -1.0

	m_bExitFromSimCombat = false
	fCameraSwoopDelayTime = -1.0
	m_bAvengerListExpansionDone = true;

	// hack to prevent hitchiness in Geoscape view
	m_overworldCursorMesh = StaticMesh'XB0_XCOM2_OverworldIcons.IconSelection''
}
