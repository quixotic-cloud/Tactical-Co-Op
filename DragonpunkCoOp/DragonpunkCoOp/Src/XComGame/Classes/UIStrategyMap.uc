//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMap
//  AUTHOR:  Sam Batista
//  PURPOSE: Screen responsible for managing 2D UI components in the StrategyMap:
//
//           UIStrategyMap_HUD
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMap extends UIX2SimpleScreen
	dependson(UINavigationHelp, UIStrategyMap_MissionIcon);

const MAX_NUM_STRATEGYICONS = 20;

enum EStrategyMapState
{
	eSMS_Default,
	eSMS_Resistance,
	eSMS_Flight,
};

struct TStrategyMapMissionItemUI
{
	var array<UIStrategyMap_MissionIcon> MissionIcons;
	var array<XComGameState_ScanningSite> ScanSites;
	var array<XComGameState_MissionSite> Missions;
};

var UIPanel ItemContainer;
var XComStrategyMap XComMap;

var UIStrategyMap_HUD StrategyMapHUD;
var UINavigationHelp NavBar;

var EStrategyMapState m_eUIState;

//var UIButton FlightButton;
//var UIButton OutpostButton;
//var UIButton ContactButton;
var TStrategyMapMissionItemUI MissionItemUI;

var UIButton DarkEventsButton; 
var UIPanel DarkEventsContainer;
var UIPanel LeftGreeble;
var UIPanel RightGreeble;

var localized string m_strStartTime;
var localized string m_strStopTime;
var localized string m_strScanDisabled;
var localized string m_strDarkEventsLabel;
var localized string m_strToggleResNet;
var localized string m_ResHQLabel;
var localized string m_MissionsLabel;
var localized string m_ScanSiteLabel;

//Lookup tables for map items.
var array<name> CachedWidgetNames;
var array<UIStrategyMapItem> CachedMapItems;

var float ZoomSpeed;
var bool m_bResNetForcedOn;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);	

	XComMap = XComHQPresentationLayer(Movie.Pres).m_kXComStrategyMap;
	if(XComMap != none)
	{
		XComMap.UIMapZoom = 0;
	}
	
	ItemContainer = Spawn(class'UIPanel', self).InitPanel(, 'StrategyMapContainer');


	NavBar =`HQPRES.m_kAvengerHUD.NavHelp;
	StrategyMapHUD = Spawn(class'UIStrategyMap_HUD', self).InitStrategyMapHUD();

	/*OutpostButton = Spawn(class'UIButton', self).InitButton(InitName, class'UIUtilities_Text'.static.GetSizedText("BUILD OUTPOST", 25), OnBuildOutpostClicked, eUIButtonStyle_HOTLINK_BUTTON);
	OutpostButton.SetPosition(0, 0);
	OutpostButton.Hide();

	ContactButton = Spawn(class'UIButton', self).InitButton(InitName, class'UIUtilities_Text'.static.GetSizedText("MAKE CONTACT", 25), OnMakeContactClicked, eUIButtonStyle_HOTLINK_BUTTON);
	ContactButton.SetPosition(0, 0);
	ContactButton.Hide();*/

	InitMissionIcons();
	
	UpdateButtonHelp();
	UpdatePopSupportAndAlert();
	UpdateMissions();
	UpdateDarkEvents();

	//We're being explicit here, because the screen will initialize and select whatever is first available, 
	//which gets weird pins selected unexpectedly. 
	if (MissionItemUI.MissionIcons.Length > 0) 
	{
		Navigator.SetSelected(MissionItemUI.MissionIcons[0]);
	}
	else
	{
		Navigator.SetSelected(StrategyMapHUD);
	}
	
	//This is always supposed to be active if we're entering this screen.
	//`GAME.GetGeoscape().Resume();

	StrategyMapHUD.mc.BeginFunctionOp("SetMissionTrayLabels");
	StrategyMapHUD.mc.QueueString(m_ResHQLabel);
	StrategyMapHUD.mc.QueueString(m_MissionsLabel);
	StrategyMapHUD.mc.QueueString(m_ScanSiteLabel);
	StrategyMapHUD.mc.EndOp();
}

simulated function SetUIState(EStrategyMapState eNewUIState)
{
	local bool bToggleFlight;
	if( eNewUIState == eSMS_Resistance && !XCOMHQ().IsContactResearched() )
	{
		return;
	}

	if( m_bResNetForcedOn && eNewUIState != eSMS_Flight )
	{
		return;
	}

	bToggleFlight = false;
	
	if( m_eUIState != eNewUIState )
	{
		bToggleFlight = (m_eUIState == eSMS_Flight || eNewUIState == eSMS_Flight);
		m_eUIState = eNewUIState;

		if(bToggleFlight)
		{
			m_bResNetForcedOn = false; // If the resnet was forced on, turn it off when going into Flight Mode
			OnFlightModeToggled();
		}

		XComMap.UpdateVisuals();
		UpdateRegionPins();
	}
}

simulated function OnFlightModeToggled()
{
	if (bIsFocused)
	{
		UpdateButtonHelp();
		UpdateDarkEvents();
		UpdateToDoWidget();
		UpdateResourceBar();
		UpdateObjectiveList();

		if (m_eUIState == eSMS_Flight)
		{
			HideMissionButtons();
		}
		else
		{
			UpdateMissions();
		}
	}
}

simulated function UpdateObjectiveList()
{
	local XComHQPresentationLayer PresLayer;
	PresLayer = XComHQPresentationLayer(Movie.Pres);

	if(!class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress())
	{
		if(m_eUIState == eSMS_Flight)
		{
			PresLayer.m_kAvengerHUD.Objectives.Hide();
		}
		else
		{
			PresLayer.m_kAvengerHUD.Objectives.Show();
		}
	}
}

simulated function UpdateResourceBar()
{
	local XComHQPresentationLayer PresLayer;
	PresLayer = XComHQPresentationLayer(Movie.Pres);

	if(m_eUIState == eSMS_Flight)
	{
		PresLayer.m_kAvengerHUD.HideResources();
	}
	else
	{
		PresLayer.m_kAvengerHUD.ShowResources();
	}
}

simulated function UpdateToDoWidget()
{
	local XComHQPresentationLayer PresLayer;
	PresLayer = XComHQPresentationLayer(Movie.Pres);

	if(m_eUIState == eSMS_Flight)
	{
		PresLayer.m_kAvengerHUD.ToDoWidget.Hide();
	}
	else
	{
		PresLayer.m_kAvengerHUD.ToDoWidget.Show();
	}
}

simulated function UpdateRegionPins()
{
	local UIStrategyMapItem_Region Pin;
	local XComGameState_WorldRegion Region;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', Region)
	{
		Pin = UIStrategyMapItem_Region(GetMapItem(Region));
		if( Pin != none )
		{
			Pin.UpdateFlyoverText();
		}
	}
}

// TODO: Replace eType with class<UIStrategyMapItem> -sbatista
simulated function UIStrategyMapItem GetMapItem(XComGameState_GeoscapeEntity Entity)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local UIStrategyMapItem MapItem;
	local name WidgetName;
	local int MapItemIndex;
	local XComGameState_WorldRegion Region;
	local XComGameState_GeoscapeEntity EntityState;

	WidgetName = name(Entity.GetUIWidgetName());

	MapItemIndex = CachedWidgetNames.Find(WidgetName);
	if(MapItemIndex > -1)
	{
		MapItem = CachedMapItems[MapItemIndex];
	}
	else
	{
		MapItem = Spawn(Entity.GetUIClass(), ItemContainer).InitMapItem(Entity);
		CachedWidgetNames.AddItem(WidgetName);
		CachedMapItems.AddItem(MapItem);

		// Update the Haven location after the region mesh has been generated
		Region = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(Entity.ObjectID));

		if (Region != none)
		{
			History = `XCOMHISTORY;
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entity Locations Updated");

			foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', EntityState)
			{
				if(EntityState.Region == Region.GetReference() &&EntityState.bNeedsLocationUpdate)
				{
					EntityState = XComGameState_GeoscapeEntity(NewGameState.CreateStateObject(EntityState.Class, EntityState.ObjectID));
					NewGameState.AddStateObject(EntityState);
					EntityState.Location = Region.GetRandomLocationInRegion(, , EntityState);
					EntityState.HandleUpdateLocation();
					EntityState.bNeedsLocationUpdate = false;
				}
			}

			if(NewGameState.GetNumGameStateObjects() > 0)
			{
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
			else
			{
				History.CleanupPendingGameState(NewGameState);
			}
		}
	}
	
	return MapItem;
}

simulated function UpdateButtonHelp()
{
	local int enumval;
	//local bool bAdvanceTime, bCanScan;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	NavBar.ClearButtonHelp();
	History = `XCOMHISTORY;
	//bAdvanceTime = `GAME.GetGeoscape().IsScanning();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	//bCanScan = XComHQ.IsScanningAllowedAtCurrentLocation();

	if(m_eUIState != eSMS_Flight)
	{
		// can only back out if the avenger is landed
		NavBar.AddBackButton(CloseScreen);

		if(XCOMHQ.IsContactResearched())
		{
			enumval = eButtonIconPC_Land;
			NavBar.SetButtonType("XComButtonIconPC");
			NavBar.AddLeftHelp(string(enumval), class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, OnResNetClicked, false, m_strToggleResNet);
			NavBar.SetButtonType("");
		}
				
		//if (!bCanScan)
		//{
		//	// Show the scan button, but it is disabled
		//	
		//	NavBar.AddCenterHelp(string(enumval)/*m_strStartTime*/, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, , true, m_strScanDisabled);
		//}
		//else
		//{
		//	if (!bAdvanceTime)
		//	{
		//		enumval = eButtonIconPC_Scan;
		//		NavBar.AddCenterHelp(string(enumval)/*m_strStartTime*/, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, ToggleScan, , m_strStartTime $ XComHQ.GetScanSiteLabel());
		//	}
		//	else
		//	{
		//		enumval = eButtonIconPC_Scanimate;
		//		NavBar.AddCenterHelp(string(enumval)/*m_strStopTime*/, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, ToggleScan, , m_strStopTime);
		//	}
		//}
	}
}

simulated function UpdatePopSupportAndAlert(optional StateObjectReference ContinentRef)
{
	local array<int> PopularSupportBlocks, AlertBlocks, ThresholdIndicies;
	local XComGameStateHistory History;
	local XComGameState_Continent ContinentState;

	History = `XCOMHISTORY;

	if(bIsVisible)
	{
		if(ContinentRef.ObjectID > 0)
			ContinentState = XComGameState_Continent(History.GetGameStateForObjectID(ContinentRef.ObjectID));
		else
			ContinentState = XComGameState_Continent(History.GetGameStateForObjectID(`XCOMHQ.Continent.ObjectID));

		if(ContinentState != none)
		{
			// PopularSupport Data
			ThresholdIndicies[0] = ContinentState.GetMaxResistanceLevel();

			PopularSupportBlocks = class'UIUtilities_Strategy'.static.GetMeterBlockTypes(ContinentState.GetMaxResistanceLevel(), ContinentState.GetResistanceLevel(),
																						 0,
																						 ThresholdIndicies);

			StrategyMapHUD.UpdateSupportTooltip(0, ContinentState.GetContinentBonus().DisplayName, ContinentState.GetContinentBonus().SummaryText, 
												ThresholdIndicies[0] <= ContinentState.GetMaxResistanceLevel());

			// Alert Data
			AlertBlocks.Length = 0;
		}

		StrategyMapHUD.UpdatePopularSupportMeter(PopularSupportBlocks);
		StrategyMapHUD.UpdateAlertMeter(AlertBlocks);
	}
}


simulated function ClearScanSites()
{
	MissionItemUI.ScanSites.Remove(0, MissionItemUI.ScanSites.Length);
}

simulated function ClearDarkEvents()
{
	if( DarkEventsContainer != none )
	{
		DarkEventsContainer.Hide();
		DarkEventsContainer.Destroy();
	}
	
	DarkEventsContainer	= none;
}

simulated function HideDarkEventsButton()
{
	if( DarkEventsContainer != none )
	{
		DarkEventsContainer.Hide();
	}
}

simulated function bool ShowDarkEventsButton()
{
	local XComHeadquartersCheatManager CheatMgr;

	if(m_eUIState == eSMS_Flight)
	{
		return false;
	}

	CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);

	if(CheatMgr != none && CheatMgr.bGamesComDemo)
	{
		return false;
	}

	return (ALIENHQ().ChosenDarkEvents.Length > 0 || ALIENHQ().ActiveDarkEvents.Length > 0);
}

simulated function UpdateDarkEvents()
{
	ClearDarkEvents();

	if(ShowDarkEventsButton())
	{
		AddDarkEventsButton();
	}
}

simulated function AddDarkEventsButton()
{
	//Tie the doom button to the doom display, which will anchor and look tidy automatically.
	if( DarkEventsContainer == none )
	{
		DarkEventsContainer = Spawn(class'UIPanel', self).InitPanel();
		DarkEventsContainer.AnchorTopCenter();
		DarkEventsContainer.bAnimateOnInit = false;
		DarkEventsContainer.Hide();
		
		LeftGreeble = Spawn(class'UIPanel', DarkEventsContainer);
		LeftGreeble.InitPanel(, 'leftDoomGreeble').SetPosition(-5, 5); //flash visuals
		RightGreeble = Spawn(class'UIPanel', DarkEventsContainer);
		RightGreeble.InitPanel(, 'rightDoomGreeble').SetY(5);

		DarkEventsButton = Spawn(class'UIButton', DarkEventsContainer);
		DarkEventsButton.LibID = 'X2DarkEventsButton'; 
		DarkEventsButton.bAnimateOnInit = false;
		DarkEventsButton.InitButton();
		DarkEventsButton.SetColor(class'UIUtilities_Colors'.const.BAD_HTML_COLOR); // specially overwritten to handle the text specifically. 
		DarkEventsButton.SetText(m_strDarkEventsLabel);
		DarkEventsButton.ProcessMouseEvents( OnDarkEventsClicked );
		DarkEventsButton.OnSizeRealized = OnDarkEventsButtonSizeRealized;
	}
	else
	{
		OnDarkEventsButtonSizeRealized();
	}
}

simulated function OnDarkEventsButtonSizeRealized()
{
	DarkEventsContainer.Hide();

	if( class'UIUtilities_Strategy'.static.GetAlienHQ().AtMaxDoom() )
		DarkEventsContainer.SetY(112); //relative, beneath the Doom Counter. 
	else if( class'UIUtilities_Strategy'.static.GetAlienHQ().GetCurrentDoom() > 0 || class'UIUtilities_Strategy'.static.GetAlienHQ().bHasSeenDoomMeter)
		DarkEventsContainer.SetY(76); //relative, beneath the Doom Bar. 
	else 
		DarkEventsContainer.SetY(0); //relative, beneath the Doom Bar. 

	DarkEventsContainer.SetX(-0.5 * DarkEventsButton.Width);
	RightGreeble.SetX(DarkEventsButton.Width + 5);
	DarkEventsContainer.Show();
}

simulated function OnDarkEventsClicked(UIPanel Panel, int Cmd)
{
	if( Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
	{
		`GAME.GetGeoscape().Pause();
		HQPRES().UIAdventOperations(false);
	}
}

simulated function ClearMissions()
{
	MissionItemUI.Missions.Remove(0, MissionItemUI.Missions.Length);
}


simulated function OnBuildOutpostClicked(UIButton Button)
{
	HQPRES().UIBuildOutpost(XCOMHQ().GetWorldRegion());
}

simulated function OnMakeContactClicked(UIButton Button)
{
	HQPRES().UIMakeContact(XCOMHQ().GetWorldRegion());
}

simulated function OnResNetClicked()
{
	if( m_bResNetForcedOn )
	{
		m_bResNetForcedOn = false;	// Ordering of these statements matters
		SetUIState(eSMS_Default);
	}
	else
	{
		SetUIState(eSMS_Resistance);
		m_bResNetForcedOn = true;
	}
}

simulated function HideMissionButtons()
{
	local int i;
	
	i = 0;

	while(i < MAX_NUM_STRATEGYICONS)
	{
		MissionItemUI.MissionIcons[i].Hide();
		i++;
	}

	StrategyMapHUD.mc.BeginFunctionOp("AnimateMissionTrayOut");
	StrategyMapHUD.mc.EndOp();
}

simulated function UpdateMissions()
{
	local array<XComGameState_ScanningSite> arrScanSites;
	local XComGameState_ScanningSite ScanSite;
	local XComGameState_MissionSite MissionSite;
	local int i, numScanSites, numMissions;
	local XComGameStateHistory History;
	local bool bGuerillaAdded;
	
	ClearMissions();
	ClearScanSites();

	if(m_eUIState == eSMS_Flight)
	{
		return;
	}

	numScanSites = 1;
	
	History = `XCOMHISTORY;
	StrategyMapHUD.mc.BeginFunctionOp("AnimateMissionTrayIn");
	StrategyMapHUD.mc.EndOp();

	// TODO, add the missions in a sorted order
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionSite)
	{
		// Is this mission active
		if( MissionSite.Available )
		{
			if( MissionSite.Source == 'MissionSource_GuerillaOp')
			{
				if( !bGuerillaAdded )
				{
					// Don't add multiple Guerrilla Op missions
					MissionItemUI.Missions.AddItem(MissionSite);
					bGuerillaAdded = true;
				}
			}
			else if(MissionSite.Source == 'MissionSource_Final')
			{
				if(!MissionSite.bNotAtThreshold)
				{
					MissionItemUI.Missions.AddItem(MissionSite);
				}
			}
			else
			{
				MissionItemUI.Missions.AddItem(MissionSite);
			}
		}	
	}

	// Apply sorting to missions
	MissionItemUI.Missions.Sort(SortMissionsUnlocked);
	MissionItemUI.Missions.Sort(SortMissionsType);

	arrScanSites = XCOMHQ().GetAvailableScanningSites();
	arrScanSites.Sort(SortScanSitesType);

	if( arrScanSites.Length > 0 )
	{
		foreach arrScanSites(ScanSite)
		{
			if(i < MAX_NUM_STRATEGYICONS)
			{
				i++;
				if(ScanSite.IsA('XComGameState_Haven'))
				{
					MissionItemUI.MissionIcons[0].SetScanSite(ScanSite);
					MissionItemUI.MissionIcons[0].AS_SetAlert( !XComGameState_Haven(ScanSite).HasSeenNewResGoods() );
				}
				else
				{
					MissionItemUI.MissionIcons[numScanSites].SetScanSite(ScanSite);

					if (ScanSite.IsA('XComGameState_BlackMarket'))
					{
						MissionItemUI.MissionIcons[numScanSites].AS_SetAlert(!XComGameState_BlackMarket(ScanSite).bHasSeenNewGoods);
					}

					numScanSites++;
				}
			}
			else
			{
				`RedScreenOnce("Too many Scan Sites, increase size of MAX_NUM_STRATEGYICONS in UIStrategyMap");
			}
		}
	}

	foreach MissionItemUI.Missions(MissionSite)
	{
		if(i < MAX_NUM_STRATEGYICONS)
		{
			MissionItemUI.MissionIcons[i].SetMissionSite(MissionSite);
			i++;
			numMissions++;
		}
		else
		{
			`RedScreenOnce("Too many Missions, increase size of MAX_NUM_STRATEGYICONS in UIStrategyMap");
		}
	}

	for(i = 0; i < MAX_NUM_STRATEGYICONS; i++ )
	{
		if(i < numScanSites+numMissions)
		{
			MissionItemUI.MissionIcons[i].SetSortedPosition(numScanSites, numMissions);
		}
		else
		{
			MissionItemUI.MissionIcons[i].Hide();
		}
	}

	StrategyMapHUD.mc.BeginFunctionOp("SetMissionTrayWidth");
	StrategyMapHUD.mc.QueueNumber(numScanSites - 1);
	StrategyMapHUD.mc.QueueNumber(numMissions);
	StrategyMapHUD.mc.EndOp();

	MissionItemUI.ScanSites = arrScanSites;

	Navigator.SelectFirstAvailableIfNoCurrentSelection();
}

function int SortMissionsUnlocked(XComGameState_MissionSite MissionA, XComGameState_MissionSite MissionB)
{
	local XComGameState_WorldRegion RegionA, RegionB;

	RegionA = MissionA.GetWorldRegion();
	RegionB = MissionB.GetWorldRegion();
	
	if (RegionA.ResistanceLevel > RegionB.ResistanceLevel)
	{
		return 1;
	}
	else if (RegionA.ResistanceLevel < RegionB.ResistanceLevel)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortMissionsType(XComGameState_MissionSite MissionA, XComGameState_MissionSite MissionB)
{
	local X2MissionSourceTemplate MissionASource, MissionBSource;

	MissionASource = MissionA.GetMissionSource();
	MissionBSource = MissionB.GetMissionSource();

	// First sort alien facility missions
	if (MissionASource.bAlienNetwork && !MissionBSource.bAlienNetwork)
	{
		return -1;
	}
	else if (!MissionASource.bAlienNetwork && MissionBSource.bAlienNetwork)
	{
		return 1;
	}
	else
	{
		// Then Golden Path missions
		if (MissionASource.bGoldenPath && !MissionBSource.bGoldenPath)
		{
			return -1;
		}
		else if (!MissionASource.bGoldenPath && MissionBSource.bGoldenPath)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
}

function int SortScanSitesType(XComGameState_ScanningSite ScanSiteA, XComGameState_ScanningSite ScanSiteB)
{
	local bool SiteAResource, SiteBResource, SiteARegion, SiteBRegion, SiteABlackMarket, SiteBBlackMarket;

	SiteABlackMarket = ScanSiteA.IsA('XComGameState_BlackMarket');
	SiteBBlackMarket = ScanSiteB.IsA('XComGameState_BlackMarket');
	SiteAResource = ScanSiteA.IsA('XComGameState_ResourceCache');
	SiteBResource = ScanSiteB.IsA('XComGameState_ResourceCache');
	SiteARegion = ScanSiteA.IsA('XComGameState_WorldRegion');
	SiteBRegion = ScanSiteB.IsA('XComGameState_WorldRegion');

	// First Black Market
	if (SiteABlackMarket && !SiteBBlackMarket)
	{
		return 1;
	}
	else if (!SiteABlackMarket && SiteBBlackMarket)
	{
		return -1;
	}
	else
	{
		// Then Supply Drop
		if (SiteAResource && !SiteBResource)
		{
			return 1;
		}
		else if (!SiteAResource && SiteBResource)
		{
			return -1;
		}
		else
		{
			// Then World Regions
			if (SiteARegion && !SiteBRegion)
			{
				return 1;
			}
			else if (!SiteARegion && SiteBRegion)
			{
				return -1;
			}
			else
			{
				return 0;
			}
		}
	}
}

simulated function InitMissionIcons()
{
	local int i;

	for( i = 0; i < MAX_NUM_STRATEGYICONS; i++)
	{
		MissionItemUI.MissionIcons.AddItem(Spawn(class'UIStrategyMap_MissionIcon', self).InitMissionIcon(i));
		MissionItemUI.MissionIcons[i].SetSortedPosition(0, 0);//this will spread the icons out based on the number we have
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local XComEarth Geoscape;
	local float OldZoom;

	// No input during flight mode
	if(m_eUIstate == eSMS_Flight)
	{
		return true;
	}

	// Only pay attention to presses or repeats; ignoring other input types
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	Geoscape = `EARTH;
	OldZoom = Geoscape.fTargetZoom;

	if (cmd >= class'UIUtilities_Input'.const.FXS_KEY_1 && cmd <= class'UIUtilities_Input'.const.FXS_KEY_0)
	{

	}

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			TryExiting();
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			if (XCOMHQ().IsScanningAllowedAtCurrentLocation())
				ToggleScan();
			break;
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
			Geoscape.SetCurrentZoomLevel(Geoscape.fTargetZoom - ZoomSpeed);
			break;
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
			Geoscape.SetCurrentZoomLevel(Geoscape.fTargetZoom + ZoomSpeed);
			break;
		default:
			return super.OnUnrealCommand(cmd, arg);
	}

	if(Geoscape.fTargetZoom != OldZoom)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_Zoom_Tick");
	}

	return true;	
}

simulated function TryExiting()
{
	if(`GAME.GetGeoscape().IsScanning())
		ToggleScan();
	else if(m_eUIState != eSMS_Flight)
		CloseScreen();
}

simulated function ToggleScan(optional bool bForceScan=false)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local XGGeoscape Geoscape;
	local bool bAdvanceTime, bTimeSensitiveMission;

	Geoscape = `GAME.GetGeoscape();

	bAdvanceTime = !Geoscape.IsScanning();

	// If attempting to start a scan, if there is a time sensitive mission on the map warn the player that it could be skipped
	if (bAdvanceTime && !bForceScan)
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
				if (MissionState.Expiring && !MissionState.bHasSeenSkipPopup)
				{
					bTimeSensitiveMission = true;
					break;
				}
			}

		if (bTimeSensitiveMission && MissionState != none)
		{
			`HQPRES.UITimeSensitiveMission(MissionState);
		}
	}

	// If we are trying to pause, or if there is no time sensitive mission, then scan as normal
	if (!bAdvanceTime || !bTimeSensitiveMission || bForceScan)
	{
		XCOMHQ().ToggleSiteScanning(bAdvanceTime);

		if (bAdvanceTime)
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_TimeForwardScan");
			Geoscape.m_fTimeScale = Geoscape.TWELVE_HOURS;
		}
		else
		{
			Geoscape.m_fTimeScale = Geoscape.ONE_MINUTE;
		}
	}

	//...then refresh the button help so it switches labels
	UpdateButtonHelp();
}

simulated function CloseScreen()
{
	local XComHQPresentationLayer HQPres; 

	if( `GAME.GetGeoscape().CanExit() )
	{	
		HQPres = XComHQPresentationLayer(Movie.Pres);
		Movie.Stack.Pop(self);
		HQPres.m_kAvengerHUD.Hide();
		HQPres.StrategyMap2D = none;
		HQPres.ExitStrategyMap(true);
		HQPres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(MCPath));
	}
}


simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	StrategyMapHUD.Hide(); //Specifically hide, since we're leaving this screen active in general, so the pins are visible. 
	XComMap.OnLoseFocus();
	`HQPRES.m_kEventNotices.Hide();
	`HQPRES.m_kAvengerHUD.HideEventQueue();
	HideMissionButtons();
	HideDarkEventsButton();
	NavBar.ClearButtonHelp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Show();
	
	//It may be the case that we're receiving focus after the player has lost the game, as they are about to be kicked back to the main menu.
	//In this case, all of the HQ objects have been cleaned up - don't try to update.
	if (`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true) == None)
		return;

	XComMap.OnReceiveFocus();
	StrategyMapHUD.UpdateData();
	StrategyMapHUD.Show();
	UpdateMissions();
	UpdateButtonHelp();
	UpdateDarkEvents();
	UpdateToDoWidget();
}

simulated function OnRemoved()
{
	super.OnRemoved();
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(MCPath));
	`GAME.GetGeoscape().OnExitMissionControl();
	`HQPRES.m_kEventNotices.Hide();
}

//----------------------------------------------------------------

DefaultProperties
{
	InputState = eInputState_Evaluate;
	Package = "/ package/gfxStrategyMap/StrategyMap";
	ZoomSpeed = 0.085
	bHideOnLoseFocus = false; 
}
