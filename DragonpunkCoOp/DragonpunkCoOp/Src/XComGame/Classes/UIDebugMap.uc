//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_MapSetup
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: This screen provides the functionality for dynamically building a level from 
//           within a tactical battle, and restarting a battle after the level has been
//           built.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDebugMap extends UIScreen dependson(XComParcelManager, XComPlotCoverParcelManager);

enum EMapDebugMode
{
	EMapDebugMode_WorldData,
	EMapDebugMode_CachedVisibility,
	EMapDebugMode_DebugAnalytics,
	EMapDebugMode_ChallengeMode,
};

enum EProcessClickType
{
	EProcessClickType_Click,
	EProcessClickType_ShiftClick,
	EProcessClickType_None
};

struct ProcessClickData
{
	var bool    bValid;
	var bool	bDrawClickActorName;
	var Vector	ClickLocation;
	var string	ClickActorName;
	var TTile	ClickTile;
};

var XComPresentationLayer   Pres;
var XComTacticalController  TacticalController;
var XComTacticalInput       TacticalInput;

//Stored state for restoring game play when the screen is exited
var name StoredInputState;
var bool bStoredMouseIsActive;
var bool bStoredFOWState;

//Map setup managers
var XComEnvLightingManager      EnvLightingManager;
var XComTacticalMissionManager  TacticalMissionManager;
var XComParcelManager           ParcelManager;
var XComWorldData               WorldData;

//Game state objects
var XComGameStateHistory        History;
var XComGameState_BattleData    BattleDataState;
var XComGameState_ChallengeData	ChallengeModeData;

//Variables to draw the parcel / plot data to the canvas
var int CanvasDrawScale;

var EMapDebugMode       MapDebugMode;
var array<UIPanel>    AllDebugModeControls; //Used to hide all controls

//UI controls
var UIPanel		m_kAllContainer;
var UIBGBox		m_kMouseHitBG;
var UIPanel     FrameInfoContainer;
var UIBGBox		m_kCurrentFrameInfoBG;
var UIText		m_kCurrentFrameInfoTitle;
var UIText		m_kCurrentFrameInfoText;

var UIPanel     TileInfoContainer;
var UIBGBox		m_kTileInfoBG;
var UIText		m_kTileInfoText;

var UIButton	m_kStopButton;
var UIDropdown  m_kMapDebugModeDropDown;

//Map Toggling
var UIButton	m_kToggleMapButton;
var bool        bShowMap;

//Click processing
var EProcessClickType   ProcessClickType;
var ProcessClickData    ClickData[2];
var int                 LastClickTypeIndex;

//Path debugging
var UIButton	m_kButtonDebugTileUp;
var UIButton	m_kButtonDebugTileDown;
var UIButton	m_kButtonRebuildPathing;
var UIButton	m_kButtonTileDestroy;
var UIButton	m_kButtonTileFragileDestroy;
var UIButton	m_kButtonActorDamage;
var UIButton	m_kButtonActorDestroy;
var UIButton	m_kButtonSetEffect;
var UIDropdown	m_kDropDownEffectSelect;
var UICheckbox  m_kCheckbox_COVER_DebugHeight;
var UICheckbox  m_kCheckbox_COVER_DebugGround;
var UICheckbox  m_kCheckbox_COVER_DebugPeek;
var UICheckbox  m_kCheckbox_COVER_DebugWorld;
var UICheckbox  m_kCheckbox_COVER_DebugOccupancy;
var UICheckbox  m_kCheckbox_COVER_DebugClimb;

//Cahed visibility debugging
var UIDropdown	m_kDropdownDebugFOWViewer;
var UIButton	m_kButtonToggleDebugVoxelData;
var UICheckbox  m_kCheckbox_DebugGameplayData;

// Debug Analytics
var UIList		m_kAnalyticsList;

//Challenge Mode Configuration Display
var UIText		m_kSquadSizeLabel;
var UIText		m_kSquadSizeConfig;
var UIText		m_kSoldierClassLabel;
var UIText		m_kSoldierClassConfig;
var UIText		m_kAlienTypeLabel;
var UIText		m_kAlienTypeConfig;
var UIText		m_kSoldierRankLabel;
var UIText		m_kSoldierRankConfig;
var UIText		m_kSoldierArmorLabel;
var UIText		m_kSoldierArmorConfig;
var UIText		m_kPrimaryWeaponsLabel;
var UIText		m_kPrimaryWeaponsConfig;
var UIText		m_kSecondaryWeaponsLabel;
var UIText		m_kSecondaryWeaponsConfig;
var UIText		m_kUtilityItemsLabel;
var UIText		m_kUtilityItemsConfig;
var UIText		m_kForceLevelLabel;
var UIText		m_kForceLevelConfig;
var UIText		m_kEnemyForcesLabel;
var UIText		m_kEnemyForcesConfig;
var array<UIPanel> AllChallengeControls;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen( InitController, InitMovie, InitName );

	m_kAllContainer         = Spawn(class'UIPanel', self);
	m_kMouseHitBG           = Spawn(class'UIBGBox', m_kAllContainer);	

	FrameInfoContainer = Spawn(class'UIPanel', self);
	m_kCurrentFrameInfoBG   = Spawn(class'UIBGBox', FrameInfoContainer);
	m_kCurrentFrameInfoTitle= Spawn(class'UIText', FrameInfoContainer);
	m_kCurrentFrameInfoText = Spawn(class'UIText', FrameInfoContainer);
	m_kStopButton           = Spawn(class'UIButton', FrameInfoContainer);
	m_kMapDebugModeDropDown = Spawn(class'UIDropdown', FrameInfoContainer);
	m_kToggleMapButton      = Spawn(class'UIButton', FrameInfoContainer);	

	TileInfoContainer = Spawn(class'UIPanel', self);
	m_kTileInfoBG = Spawn(class'UIBGBox', TileInfoContainer);
	m_kTileInfoText = Spawn(class'UIText', TileInfoContainer);
	
	m_kAllContainer.InitPanel('allContainer');
	m_kAllContainer.SetPosition(50, 50);
	m_kAllContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);

	FrameInfoContainer.InitPanel('InfoContainer');
	FrameInfoContainer.SetPosition(-550, 50);
	FrameInfoContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	
	m_kMouseHitBG.InitBG('mouseHit', 0, 0, Movie.UI_RES_X, Movie.UI_RES_Y);	
	m_kMouseHitBG.SetAlpha(0.00001f);
	m_kMouseHitBG.ProcessMouseEvents(OnMouseHitLayerCallback);

	m_kCurrentFrameInfoBG.InitBG('infoBox', 0, 0, 500, 600);
	m_kCurrentFrameInfoTitle.InitText('infoBoxTitle', "<Empty>", true);
	m_kCurrentFrameInfoTitle.SetWidth(480);
	m_kCurrentFrameInfoTitle.SetX(10);
	m_kCurrentFrameInfoTitle.SetY(60);
	m_kCurrentFrameInfoText.InitText('infoBoxText', "<Empty>", true);
	m_kCurrentFrameInfoText.SetWidth(480);
	m_kCurrentFrameInfoText.SetX(10);
	m_kCurrentFrameInfoText.SetY(50);	

	TileInfoContainer.InitPanel('TileInfoContainer');
	TileInfoContainer.SetPosition(0, 150);
	TileInfoContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);

	m_kTileInfoBG.InitBG('tileInfoBox', 0, 0, 400, 700);
	m_kTileInfoText.InitText('tileInfoText', "<Empty>", true);
	m_kTileInfoText.SetWidth(480);
	m_kTileInfoText.SetX(10);
	m_kTileInfoText.SetY(10);

	m_kStopButton.InitButton('stopButton', "Stop Debugging", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	m_kStopButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kStopButton.SetX(325);
	m_kStopButton.SetY(25);

	m_kMapDebugModeDropDown.InitDropdown('mapDebugModeDropdown', "Debug World Data", SelectMapDebugMode);
	m_kMapDebugModeDropDown.AddItem("Debug World Data");	
	m_kMapDebugModeDropDown.AddItem("Debug Cached Visibility");
	m_kMapDebugModeDropDown.AddItem("Debug Analytics");
	m_kMapDebugModeDropDown.SetSelected(0);
	m_kMapDebugModeDropDown.SetX(30);
	m_kMapDebugModeDropDown.SetY(575);

	//m_kStopButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kStopButton.SetX(10);
	m_kStopButton.SetY(25);

	m_kToggleMapButton.InitButton('toggleMapButton', "Show Map", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kToggleMapButton.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kToggleMapButton.SetX(325);
	m_kToggleMapButton.SetY(50);	

	InitializeDebugWorldDataControls();

	InitializeDebugCachedVisibilityControls();

	InitializeDebugAnalyticsControls();

	SelectMapDebugMode(m_kMapDebugModeDropDown);

	TacticalController = XComTacticalController(PC);
	TacticalInput = XComTacticalInput(TacticalController.PlayerInput);
	StoredInputState = TacticalController.GetInputState();
	TacticalController.SetInputState('Multiplayer_Inactive');

	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();

	History = `XCOMHISTORY;
	EnvLightingManager = `ENVLIGHTINGMGR;
	TacticalMissionManager = `TACTICALMISSIONMGR;
	ParcelManager = `PARCELMGR;
	WorldData = `XWORLD;

	Pres = XComPresentationLayer(PC.Pres);

	//Store off the battle data object in the start state. It will be filled out with the results of the generation process
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	ChallengeModeData = XComGameState_ChallengeData( History.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) );
	if (ChallengeModeData != none)
	{
		m_kMapDebugModeDropDown.AddItem( "Challenge Mode Config" );
		InitializeChallengeModeDataDisplay( );
	}

	bStoredFOWState =  `XWORLD.bDebugEnableFOW;
	if( bStoredFOWState )
	{
		XComCheatManager(TacticalController.CheatManager).ToggleFOW();
	}

	AddHUDOverlayActor();
}

function InitializeDebugWorldDataControls()
{
	local int PositionX;
	local int PositionY;
	local int Spacing;

	m_kButtonDebugTileUp    = Spawn(class'UIButton', FrameInfoContainer);
	m_kButtonDebugTileDown  = Spawn(class'UIButton', FrameInfoContainer);
	m_kButtonRebuildPathing = Spawn(class'UIButton', FrameInfoContainer);
	m_kButtonTileDestroy	= Spawn(class'UIButton', FrameInfoContainer);
	m_kButtonTileFragileDestroy = Spawn(class'UIButton', FrameInfoContainer);
	m_kButtonActorDestroy	= Spawn(class'UIButton', FrameInfoContainer);
	m_kButtonActorDamage	= Spawn(class'UIButton', FrameInfoContainer);
	m_kButtonSetEffect		= Spawn(class'UIButton', FrameInfoContainer);

	PositionY = 80;
	Spacing = 30;

	m_kButtonDebugTileUp.InitButton('tileUpButton', "Tile Up", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kButtonDebugTileUp.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonDebugTileUp.SetX(325);
	m_kButtonDebugTileUp.SetY(PositionY);
	AllDebugModeControls.AddItem(m_kButtonDebugTileUp);

	PositionY += Spacing;

	m_kButtonDebugTileDown.InitButton('tileDownButton', "Tile Down", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kButtonDebugTileDown.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonDebugTileDown.SetX(325);
	m_kButtonDebugTileDown.SetY(PositionY);
	AllDebugModeControls.AddItem(m_kButtonDebugTileDown);

	PositionY += Spacing;

	m_kButtonRebuildPathing.InitButton('tileRebuildButton', "Tile Rebuild", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kButtonRebuildPathing.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonRebuildPathing.SetX(325);
	m_kButtonRebuildPathing.SetY(PositionY);
	AllDebugModeControls.AddItem(m_kButtonRebuildPathing);

	PositionY += Spacing;

	m_kButtonTileDestroy.InitButton('tileDestroyButton', "Tile Destroy", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kButtonTileDestroy.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonTileDestroy.SetX(325);
	m_kButtonTileDestroy.SetY(PositionY);
	AllDebugModeControls.AddItem(m_kButtonTileDestroy);

	PositionY += Spacing;

	m_kButtonTileFragileDestroy.InitButton('tileDestroyFragileButton', "Fragile Destroy", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kButtonTileFragileDestroy.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonTileFragileDestroy.SetX(325);
	m_kButtonTileFragileDestroy.SetY(PositionY);
	AllDebugModeControls.AddItem(m_kButtonTileFragileDestroy);

	PositionY += Spacing;

	m_kButtonActorDamage.InitButton('actorDamageButton', "Actor Damage", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kButtonActorDamage.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonActorDamage.SetX(325);
	m_kButtonActorDamage.SetY(PositionY);
	AllDebugModeControls.AddItem(m_kButtonActorDamage);

	PositionY += Spacing;

	m_kButtonActorDestroy.InitButton('actorDestroyButton', "Actor Destroy", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kButtonActorDestroy.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonActorDestroy.SetX(325);
	m_kButtonActorDestroy.SetY(PositionY);
	AllDebugModeControls.AddItem(m_kButtonActorDestroy);

	PositionY += Spacing;

	m_kButtonSetEffect.InitButton( 'tileSetEffect', "Set Effect", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON );
	//m_kButtonSetFire.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonSetEffect.SetX( 325 );
	m_kButtonSetEffect.SetY( PositionY );
	AllDebugModeControls.AddItem( m_kButtonSetEffect );

	m_kDropDownEffectSelect = Spawn( class'UIDropdown', FrameInfoContainer );
	m_kDropDownEffectSelect.InitDropdown( 'tileSelectEffect', "Effect Debug" );

	m_kDropDownEffectSelect.AddItem( "X2Effect_ApplyFireToWorld" );
	m_kDropDownEffectSelect.AddItem( "X2Effect_ApplyAcidToWorld" );
	m_kDropDownEffectSelect.AddItem( "X2Effect_ApplyPoisonToWorld" );
	m_kDropDownEffectSelect.AddItem( "X2Effect_ApplySmokeToWorld" );

	m_kDropDownEffectSelect.SetSelected( 0 );
	m_kDropDownEffectSelect.SetX( 30 );
	m_kDropDownEffectSelect.SetY( PositionY );
	AllDebugModeControls.AddItem( m_kDropDownEffectSelect );

	PositionY += Spacing;

	m_kCheckbox_COVER_DebugHeight = Spawn(class'UICheckbox', FrameInfoContainer);
	AllDebugModeControls.AddItem(m_kCheckbox_COVER_DebugHeight);
	m_kCheckbox_COVER_DebugGround = Spawn(class'UICheckbox', FrameInfoContainer);
	AllDebugModeControls.AddItem(m_kCheckbox_COVER_DebugGround);
	m_kCheckbox_COVER_DebugPeek = Spawn(class'UICheckbox', FrameInfoContainer);
	AllDebugModeControls.AddItem(m_kCheckbox_COVER_DebugPeek);
	m_kCheckbox_COVER_DebugWorld = Spawn(class'UICheckbox', FrameInfoContainer);
	AllDebugModeControls.AddItem(m_kCheckbox_COVER_DebugWorld);
	m_kCheckbox_COVER_DebugOccupancy = Spawn(class'UICheckbox', FrameInfoContainer);
	AllDebugModeControls.AddItem(m_kCheckbox_COVER_DebugOccupancy);
	m_kCheckbox_COVER_DebugClimb = Spawn(class'UICheckbox', FrameInfoContainer);
	AllDebugModeControls.AddItem(m_kCheckbox_COVER_DebugClimb);

	PositionX = 280;

	m_kCheckbox_COVER_DebugHeight.InitCheckbox('m_kCheckbox_COVER_DebugHeight', "DebugHeight", false, ToggleWorldDataCheckbox);	
	m_kCheckbox_COVER_DebugHeight.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	m_kCheckbox_COVER_DebugGround.InitCheckbox('m_kCheckbox_COVER_DebugGround', "DebugGround", false, ToggleWorldDataCheckbox);	
	m_kCheckbox_COVER_DebugGround.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	m_kCheckbox_COVER_DebugPeek.InitCheckbox('m_kCheckbox_COVER_DebugPeek', "DebugPeek", false, ToggleWorldDataCheckbox);
	m_kCheckbox_COVER_DebugPeek.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	m_kCheckbox_COVER_DebugWorld.InitCheckbox('m_kCheckbox_COVER_DebugWorld', "DebugWorld", false, ToggleWorldDataCheckbox);
	m_kCheckbox_COVER_DebugWorld.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	m_kCheckbox_COVER_DebugOccupancy.InitCheckbox('m_kCheckbox_COVER_DebugOccupancy', "DebugOccupancy", false, ToggleWorldDataCheckbox);
	m_kCheckbox_COVER_DebugOccupancy.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	m_kCheckbox_COVER_DebugClimb.InitCheckbox('m_kCheckbox_COVER_DebugClimb', "DebugClimb", false, ToggleWorldDataCheckbox);
	m_kCheckbox_COVER_DebugClimb.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	//By default, occupancy is 
	m_kCheckbox_COVER_DebugOccupancy.SetChecked(true);
}

function InitializeDebugCachedVisibilityControls()
{	
	local int PositionY;
	local int FOWViewer;
	local XComUnitPawnNativeBase UnitPawn;

	m_kDropdownDebugFOWViewer    = Spawn(class'UIDropdown', FrameInfoContainer);

	PositionY = 140;

	m_kDropdownDebugFOWViewer.InitDropdown('mapFOWViewerDropdown', "FOW Viewer Debug", SelectFOWViewer);

	m_kDropdownDebugFOWViewer.AddItem("None");
	m_kDropdownDebugFOWViewer.AddItem("AllXCom");
	for( FOWViewer = 0; FOWViewer < WorldData.Viewers.Length; ++FOWViewer )
	{
		UnitPawn = XComUnitPawnNativeBase(WorldData.Viewers[FOWViewer]);
		if( UnitPawn != none )
		{
			m_kDropdownDebugFOWViewer.AddItem(WorldData.Viewers[FOWViewer]@"( Object ID:"@UnitPawn.m_kGameUnit.ObjectID@")");
		}
		else
		{
			m_kDropdownDebugFOWViewer.AddItem(string(WorldData.Viewers[FOWViewer]));
		}
		
	}
	m_kDropdownDebugFOWViewer.SetSelected(0);
	m_kDropdownDebugFOWViewer.SetX(150);
	m_kDropdownDebugFOWViewer.SetY(PositionY);	
	AllDebugModeControls.AddItem(m_kDropdownDebugFOWViewer);	
	
	PositionY += 30;

	m_kButtonToggleDebugVoxelData = Spawn(class'UIButton', FrameInfoContainer);

	m_kButtonToggleDebugVoxelData.InitButton('ButtonToggleVoxelData', "Show Blocking Voxels (OFF)", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	//m_kButtonToggleDebugVoxelData.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	m_kButtonToggleDebugVoxelData.SetX(325);
	m_kButtonToggleDebugVoxelData.SetY(PositionY);
	AllDebugModeControls.AddItem(m_kButtonToggleDebugVoxelData);	

	PositionY += 30;

	m_kCheckbox_DebugGameplayData = Spawn(class'UICheckbox', FrameInfoContainer);
	m_kCheckbox_DebugGameplayData.InitCheckbox('GameplayDataCheckbox', "Gameplay Tiledata", false, ToggleGameplayDataCheckbox);
	m_kCheckbox_DebugGameplayData.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(325, PositionY);
	AllDebugModeControls.AddItem(m_kCheckbox_DebugGameplayData);
	

	if( WorldData.bDebugVoxelData )
	{	
		m_kButtonToggleDebugVoxelData.SetText("Show Blocking Voxels (ON)");
	}
	else
	{
		m_kButtonToggleDebugVoxelData.SetText("Show Blocking Voxels (OFF)");		
	}

}

simulated function InitializeDebugAnalyticsControls( )
{
	m_kAnalyticsList = Spawn( class'UIList', FrameInfoContainer );
	m_kAnalyticsList.InitList( '', 10, 10, 460, 520 );
	AllDebugModeControls.AddItem( m_kAnalyticsList );
}

simulated function InitializeChallengeModeDataDisplay( )
{
	local int PositionY;
	local int Spacing;
	local int LabelX, ConfigX;
	local UIPanel Control;

	PositionY = 80;
	Spacing = 30;

	LabelX = 30;
	ConfigX = 200;

	m_kSquadSizeLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kSquadSizeConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kSoldierClassLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kSoldierClassConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kAlienTypeLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kAlienTypeConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kSoldierRankLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kSoldierRankConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kSoldierArmorLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kSoldierArmorConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kPrimaryWeaponsLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kPrimaryWeaponsConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kSecondaryWeaponsLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kSecondaryWeaponsConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kUtilityItemsLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kUtilityItemsConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kForceLevelLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kForceLevelConfig = Spawn(class'UIText', FrameInfoContainer);
	m_kEnemyForcesLabel = Spawn(class'UIText', FrameInfoContainer);
	m_kEnemyForcesConfig = Spawn(class'UIText', FrameInfoContainer);

	m_kSquadSizeLabel.InitText( 'SquadSizeLabel', "Squad Size:" );
	m_kSquadSizeLabel.SetX( LabelX );
	m_kSquadSizeLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSquadSizeLabel );
	m_kSquadSizeConfig.InitText( 'SquadSizeConfig', string(ChallengeModeData.SquadSizeSelectorName) );
	m_kSquadSizeConfig.SetX( ConfigX );
	m_kSquadSizeConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSquadSizeConfig );

	PositionY += Spacing;

	m_kSoldierClassLabel.InitText( 'SoldierClassLabel', "Soldier Class:" );
	m_kSoldierClassLabel.SetX( LabelX );
	m_kSoldierClassLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSoldierClassLabel );
	m_kSoldierClassConfig.InitText( 'SoldierClassConfig', string(ChallengeModeData.ClassSelectorName) );
	m_kSoldierClassConfig.SetX( ConfigX );
	m_kSoldierClassConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSoldierClassConfig );

	PositionY += Spacing;

	m_kAlienTypeLabel.InitText( 'AlienTypeLabel', "Alien Type:" );
	m_kAlienTypeLabel.SetX( LabelX );
	m_kAlienTypeLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kAlienTypeLabel );
	m_kAlienTypeConfig.InitText( 'AlienTypeConfig', string(ChallengeModeData.AlienSelectorName) );
	m_kAlienTypeConfig.SetX( ConfigX );
	m_kAlienTypeConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kAlienTypeConfig );

	PositionY += Spacing;

	m_kSoldierRankLabel.InitText( 'SoldierRankLabel', "Soldier Rank:" );
	m_kSoldierRankLabel.SetX( LabelX );
	m_kSoldierRankLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSoldierRankLabel );
	m_kSoldierRankConfig.InitText( 'SoldierRankConfig', string(ChallengeModeData.RankSelectorName) );
	m_kSoldierRankConfig.SetX( ConfigX );
	m_kSoldierRankConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSoldierRankConfig );

	PositionY += Spacing;

	m_kSoldierArmorLabel.InitText( 'SoldierArmorLabel', "Soldier Armor:" );
	m_kSoldierArmorLabel.SetX( LabelX );
	m_kSoldierArmorLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSoldierArmorLabel );
	m_kSoldierArmorConfig.InitText( 'SoldierArmorConfig', string(ChallengeModeData.ArmorSelectorName) );
	m_kSoldierArmorConfig.SetX( ConfigX );
	m_kSoldierArmorConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSoldierArmorConfig );

	PositionY += Spacing;

	m_kPrimaryWeaponsLabel.InitText( 'PrimaryWeaponsLabel', "Primary Weapons:" );
	m_kPrimaryWeaponsLabel.SetX( LabelX );
	m_kPrimaryWeaponsLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kPrimaryWeaponsLabel );
	m_kPrimaryWeaponsConfig.InitText( 'PrimaryWeaponsConfig', string(ChallengeModeData.PrimaryWeaponSelectorName) );
	m_kPrimaryWeaponsConfig.SetX( ConfigX );
	m_kPrimaryWeaponsConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kPrimaryWeaponsConfig );

	PositionY += Spacing;

	m_kSecondaryWeaponsLabel.InitText( 'SecondaryWeaponsLabel', "Secondary Weapons:" );
	m_kSecondaryWeaponsLabel.SetX( LabelX );
	m_kSecondaryWeaponsLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSecondaryWeaponsLabel );
	m_kSecondaryWeaponsConfig.InitText( 'SecondaryWeaponsConfig', string(ChallengeModeData.SecondaryWeaponSelectorName) );
	m_kSecondaryWeaponsConfig.SetX( ConfigX );
	m_kSecondaryWeaponsConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kSecondaryWeaponsConfig );

	PositionY += Spacing;

	m_kUtilityItemsLabel.InitText( 'UtilityItemsLabel', "Utility Items:" );
	m_kUtilityItemsLabel.SetX( LabelX );
	m_kUtilityItemsLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kUtilityItemsLabel );
	m_kUtilityItemsConfig.InitText( 'UtilityItemsConfig', string(ChallengeModeData.UtilityItemSelectorName) );
	m_kUtilityItemsConfig.SetX( ConfigX );
	m_kUtilityItemsConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kUtilityItemsConfig );

	PositionY += Spacing;

	m_kForceLevelLabel.InitText( 'ForceLevelLabel', "Alert & Force Level:" );
	m_kForceLevelLabel.SetX( LabelX );
	m_kForceLevelLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kForceLevelLabel );
	m_kForceLevelConfig.InitText( 'ForceLevelConfig', string(ChallengeModeData.AlertForceLevelSelectorName) );
	m_kForceLevelConfig.SetX( ConfigX );
	m_kForceLevelConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kForceLevelConfig );

	PositionY += Spacing;

	m_kEnemyForcesLabel.InitText( 'EnemyForcesLabel', "Enemy Forces:" );
	m_kEnemyForcesLabel.SetX( LabelX );
	m_kEnemyForcesLabel.SetY( PositionY );
	AllChallengeControls.AddItem( m_kEnemyForcesLabel );
	m_kEnemyForcesConfig.InitText( 'EnemyForcesConfig', string( ChallengeModeData.EnemyForcesSelectorName ) );
	m_kEnemyForcesConfig.SetX( ConfigX );
	m_kEnemyForcesConfig.SetY( PositionY );
	AllChallengeControls.AddItem( m_kEnemyForcesConfig );

	PositionY += Spacing;

	foreach AllChallengeControls( Control )
	{
		Control.Hide();
		AllDebugModeControls.AddItem( Control );
	}
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

simulated public function OnUCancel()
{
	
}

simulated public function OnLMouseDown()
{
	
}

simulated function SelectFOWViewer(UIDropdown dropdown)
{
	local int SelectedIndex;

	SelectedIndex = dropdown.SelectedItem - 2; //-1 means show all FOW viewers, -2 means none

	WorldData.DebugFOWViewer = SelectedIndex;		

	if( SelectedIndex > -2 )
	{
		WorldData.ShowFOWViewerData();
	}
	else
	{
		WorldData.HideFOWViewerData();
	}
}

simulated function SelectMapDebugMode(UIDropdown dropdown)
{	
	local int Index;

	for( Index = 0; Index < AllDebugModeControls.Length; ++Index )
	{
		AllDebugModeControls[Index].Hide();
	}

	MapDebugMode = EMapDebugMode(dropdown.selectedItem);	
	switch(MapDebugMode)
	{
	case EMapDebugMode_WorldData:
		m_kButtonDebugTileUp.Show();
		m_kButtonDebugTileDown.Show();
		m_kButtonRebuildPathing.Show();
		m_kButtonTileDestroy.Show();
		m_kButtonTileFragileDestroy.Show();
		m_kButtonActorDestroy.Show();
		m_kButtonActorDamage.Show();
		m_kButtonSetEffect.Show();
		m_kDropDownEffectSelect.Show();
		m_kCheckbox_COVER_DebugHeight.Show();
		m_kCheckbox_COVER_DebugGround.Show();
		m_kCheckbox_COVER_DebugPeek.Show();
		m_kCheckbox_COVER_DebugWorld.Show();
		m_kCheckbox_COVER_DebugOccupancy.Show();
		m_kCheckbox_COVER_DebugClimb.Show();
		m_kToggleMapButton.Show();
		break;
	case EMapDebugMode_CachedVisibility:
		UpdateFOWViewerDropdown();
		m_kDropdownDebugFOWViewer.Show();
		m_kButtonToggleDebugVoxelData.Show();
		m_kCheckbox_DebugGameplayData.Show();
		m_kToggleMapButton.Show();
		break;
	case EMapDebugMode_DebugAnalytics:
		UpdateAnalyticsDataList( );
		m_kAnalyticsList.Show();
		m_kToggleMapButton.Hide();
		break;
	case EMapDebugMode_ChallengeMode:
		for (Index = 0; Index < AllChallengeControls.Length; ++Index)
		{
			AllChallengeControls[Index].Show();
		}
		break;
	}
}

function UpdateFOWViewerDropdown()
{
	local int FOWViewer;
	local XComUnitPawnNativeBase UnitPawn;

	m_kDropdownDebugFOWViewer.Clear();
	m_kDropdownDebugFOWViewer.AddItem("None");
	m_kDropdownDebugFOWViewer.AddItem("AllXCom");
	for( FOWViewer = 0; FOWViewer < WorldData.Viewers.Length; ++FOWViewer )
	{
		UnitPawn = XComUnitPawnNativeBase(WorldData.Viewers[FOWViewer]);
		if( UnitPawn != none )
		{
			m_kDropdownDebugFOWViewer.AddItem(WorldData.Viewers[FOWViewer]@"( Object ID:"@UnitPawn.m_kGameUnit.ObjectID@")");
		}
		else
		{
			m_kDropdownDebugFOWViewer.AddItem(string(WorldData.Viewers[FOWViewer]));
		}

	}
	m_kDropdownDebugFOWViewer.SetSelected(0);
}

function UpdateAnalyticsDataList( )
{
	local XComGameState_Analytics Analytics;
	local bool IncludeGlobal, IncludeTactical, IncludeUnits;
	local AnalyticEntry Entry;
	local UIListItemString ListItem;
	local float Diff;
	local string DiffString;

	IncludeGlobal = true;
	IncludeTactical = false;
	IncludeUnits = false;

	m_kAnalyticsList.ClearItems( );

	Analytics = XComGameState_Analytics( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
	if (Analytics != none)
	{
		if (`XANALYTICS.PrevDebugAnalytics == none)
		{
			`XANALYTICS.PrevDebugAnalytics = Analytics; // make there always be a valid reference
		}

		if (IncludeGlobal)
		{
			foreach Analytics.IterateGlobalAnalytics( Entry, IncludeUnits )
			{
				Diff = Entry.Value - `XANALYTICS.PrevDebugAnalytics.GetFloatValue( Entry.Key );
				if (Diff == 0)
				{
					DiffString = "";
				}
				else
				{
					DiffString = "(" $ (Diff > 0 ? "+" : "") $ Diff $ ")";
				}

				ListItem = Spawn( class'UIListItemString', m_kAnalyticsList.itemContainer );
				ListItem.InitListItem( "Campaign: "$Entry.Key$": "$Entry.Value$DiffString );
			}
		}

		if (IncludeTactical)
		{
			foreach Analytics.IterateTacticalAnalytics( Entry, IncludeUnits )
			{
				Diff = Entry.Value - `XANALYTICS.PrevDebugAnalytics.GetTacticalFloatValue( Entry.Key );
				if (Diff == 0)
				{
					DiffString = "";
				}
				else
				{
					DiffString = "(" $( Diff > 0 ? "+" : "" ) $ Diff $ ")";
				}

				ListItem = Spawn( class'UIListItemString', m_kAnalyticsList.itemContainer );
				ListItem.InitListItem( "Tactical: "$Entry.Key$": "$Entry.Value$DiffString );
			}
		}

		`XANALYTICS.PrevDebugAnalytics = Analytics; // make there always be a valid reference
	}
}

function ToggleGameplayDataCheckbox(UICheckbox checkboxControl)
{
	WorldData.bDebugGameplayFOWData = checkboxControl.bChecked;
}

simulated function ToggleWorldDataCheckbox(UICheckbox checkboxControl)
{
	if( checkboxControl == m_kCheckbox_COVER_DebugHeight )
	{
		if( m_kCheckbox_COVER_DebugHeight.bChecked )
		{
			WorldData.SetDebugCoverFlag(EScriptCOVER_DebugHeight);		
		}
		else
		{
			WorldData.UnsetDebugCoverFlag(EScriptCOVER_DebugHeight);
		}
	}
	else if( checkboxControl == m_kCheckbox_COVER_DebugGround )
	{
		if( m_kCheckbox_COVER_DebugGround.bChecked )
		{
			WorldData.SetDebugCoverFlag(EScriptCOVER_DebugGround);		
		}
		else
		{
			WorldData.UnsetDebugCoverFlag(EScriptCOVER_DebugGround);
		}
	}
	else if( checkboxControl == m_kCheckbox_COVER_DebugPeek )
	{
		if( m_kCheckbox_COVER_DebugPeek.bChecked )
		{
			WorldData.SetDebugCoverFlag(EScriptCOVER_DebugPeek);		
		}
		else
		{
			WorldData.UnsetDebugCoverFlag(EScriptCOVER_DebugPeek);
		}
	}
	else if( checkboxControl == m_kCheckbox_COVER_DebugWorld )
	{
		if( m_kCheckbox_COVER_DebugWorld.bChecked )
		{
			WorldData.SetDebugCoverFlag(EScriptCOVER_DebugWorld);		
		}
		else
		{
			WorldData.UnsetDebugCoverFlag(EScriptCOVER_DebugWorld);
		}
	}
	else if( checkboxControl == m_kCheckbox_COVER_DebugOccupancy )
	{
		if( m_kCheckbox_COVER_DebugOccupancy.bChecked )
		{
			WorldData.SetDebugCoverFlag(EScriptCOVER_DebugOccupancy);		
		}
		else
		{
			WorldData.UnsetDebugCoverFlag(EScriptCOVER_DebugOccupancy);
		}
	}
	else if( checkboxControl == m_kCheckbox_COVER_DebugClimb )
	{
		if( m_kCheckbox_COVER_DebugClimb.bChecked )
		{
			WorldData.SetDebugCoverFlag(EScriptCOVER_DebugClimb);		
		}
		else
		{
			WorldData.UnsetDebugCoverFlag(EScriptCOVER_DebugClimb);
		}
	}
}

simulated function SetEffectOnClickTile( )
{
	local XComGameState NewGameState;
	local array<VolumeEffectTileData> InitialFireTileDatas;
	local XComGameState_WorldEffectTileData FireTileUpdate;
	local array<TileIsland> TileIslands;
	local array<TileParticleInfo> FireTileParticleInfos;
	local array<TilePosPair> Tiles;
	local TilePosPair FireTile;
	local VolumeEffectTileData InitialFireTileData;
	local int Index;

	FireTile.Tile = ClickData[ LastClickTypeIndex ].ClickTile;
	FireTile.WorldPos = WorldData.GetPositionFromTileCoordinates( FireTile.Tile );
	Tiles.AddItem( FireTile );

	NewGameState = `XCOMHISTORY.CreateNewGameState( true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext( ) );

	FireTileUpdate = XComGameState_WorldEffectTileData( NewGameState.CreateStateObject( class'XComGameState_WorldEffectTileData' ) );
	FireTileUpdate.WorldEffectClassName = name(m_kDropDownEffectSelect.GetSelectedItemText());
	FireTileUpdate.PreSizeTileData( 1 );

	InitialFireTileData.NumTurns = 2;
	InitialFireTileData.Intensity = InitialFireTileData.NumTurns;
	InitialFireTileData.EffectName = FireTileUpdate.WorldEffectClassName;
	InitialFireTileDatas.AddItem( InitialFireTileData );

	TileIslands = class'X2Effect_World'.static.CollapseTilesToPools( Tiles, InitialFireTileDatas );
	class'X2Effect_World'.static.DetermineFireBlocks( TileIslands, Tiles, FireTileParticleInfos );

	for (Index = 0; Index < Tiles.Length; ++Index)
	{
		FireTileUpdate.AddInitialTileData( Tiles[ Index ], InitialFireTileDatas[ Index ], FireTileParticleInfos[ Index ] );
	}

	NewGameState.AddStateObject( FireTileUpdate );

	`TACTICALRULES.SubmitGameState( NewGameState );
}

simulated function OnButtonClicked(UIButton button)
{
	//local vector WorldPosition;

	if ( button == m_kStopButton )
	{	
		if( bStoredFOWState )
		{
			XComCheatManager(TacticalController.CheatManager).ToggleFOW();
		}

		Movie.Stack.Pop(self);
	}
	else if ( button == m_kToggleMapButton )
	{
		bShowMap = !bShowMap;

		if( bShowMap )
		{
			m_kToggleMapButton.SetText("Hide Map");
		}
		else
		{
			m_kToggleMapButton.SetText("Show Map");
		}
	}
	else if ( button == m_kButtonDebugTileUp )
	{
		ClickData[LastClickTypeIndex].ClickTile.Z += 1;
		if( ClickData[LastClickTypeIndex].ClickTile.Z >= WorldData.NumZ )
		{
			ClickData[LastClickTypeIndex].ClickTile.Z = WorldData.NumZ - 1;
		}
		RedrawClickBoxes();
	}
	else if ( button == m_kButtonDebugTileDown )
	{
		ClickData[LastClickTypeIndex].ClickTile.Z -= 1;
		if( ClickData[LastClickTypeIndex].ClickTile.Z < 0 )
		{
			ClickData[LastClickTypeIndex].ClickTile.Z = 0;
		}
		RedrawClickBoxes();
	}
	else if ( button == m_kButtonRebuildPathing )
	{
		WorldInfo.FlushPersistentDebugLines();
		WorldData.DebugRebuildTileData( ClickData[LastClickTypeIndex].ClickTile );
		RedrawClickBoxes(false);
		TacticalController.GetActiveUnit( ).m_kReachableTilesCache.ForceCacheUpdate( );
	}
	else if ( button == m_kButtonTileDestroy )
	{
		WorldInfo.FlushPersistentDebugLines();
		WorldData.DebugDestroyTile( ClickData[LastClickTypeIndex].ClickTile );
		RedrawClickBoxes(false);
		TacticalController.GetActiveUnit( ).m_kReachableTilesCache.ForceCacheUpdate( );
	}
	else if (button == m_kButtonTileFragileDestroy)
	{
		WorldInfo.FlushPersistentDebugLines();
		WorldData.DebugDestroyTile( ClickData[ LastClickTypeIndex ].ClickTile, , true );
		RedrawClickBoxes(false);
		TacticalController.GetActiveUnit( ).m_kReachableTilesCache.ForceCacheUpdate( );
	}
	else if (button == m_kButtonActorDestroy)
	{
		WorldInfo.FlushPersistentDebugLines();
		WorldData.DebugDestroyTile( ClickData[LastClickTypeIndex].ClickTile, true );
		RedrawClickBoxes(false);
		TacticalController.GetActiveUnit( ).m_kReachableTilesCache.ForceCacheUpdate( );
	}
	else if (button == m_kButtonActorDamage)
	{
		WorldData.DebugDamageOccupier( ClickData[LastClickTypeIndex].ClickTile );
		TacticalController.GetActiveUnit( ).m_kReachableTilesCache.ForceCacheUpdate( );
	}
	else if (button == m_kButtonSetEffect)
	{
		SetEffectOnClickTile( );
	}
	else if ( button == m_kButtonToggleDebugVoxelData )
	{
		if( WorldData.bDebugVoxelData )
		{	
			WorldData.HideVisibilityVoxels();
			m_kButtonToggleDebugVoxelData.SetText("Show Blocking Voxels (OFF)");
		}
		else
		{
			WorldData.ShowVisibilityVoxels();
			m_kButtonToggleDebugVoxelData.SetText("Show Blocking Voxels (ON)");		
		}
	}
}

simulated function OnRemoved()
{
	super.OnRemoved();
	
	if( !bStoredMouseIsActive )
	{
		Movie.DeactivateMouse();
	}

	WorldInfo.FlushPersistentDebugLines();
	RemoveHUDOverlayActor();
	//Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	TacticalController.SetInputState(StoredInputState);	
}

simulated function OnMouseHitLayerCallback( UIPanel control, int cmd )
{
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:	
			if( TacticalInput.PressedKeys.Find('LeftShift') != INDEX_NONE )
			{
				ProcessClickType = EProcessClickType_ShiftClick;
			}
			else
			{
				ProcessClickType = EProcessClickType_Click;
			}
			break;
	}
}

simulated private function GetPlotRenderBounds(out Vector2D UpperLeft, optional out Vector2D Dimension)
{
	local Vector2D ViewportSize;

	UpperLeft.X = 350;
	UpperLeft.Y = 350;

	class'Engine'.static.GetEngine().GameViewport.GetViewportSize(ViewportSize);

	CanvasDrawScale = (ViewportSize.X - m_kCurrentFrameInfoBG.width - 500) / `XWORLD.NumX;
	CanvasDrawScale = Min(CanvasDrawScale, (ViewportSize.Y - 100) / `XWORLD.NumY);

	Dimension.X = `XWORLD.NumX * CanvasDrawScale;
	Dimension.Y = `XWORLD.NumY * CanvasDrawScale;
}

simulated private function GetParcelRenderBounds(XComParcel Parcel, out Vector2D UpperLeft, optional out Vector2D Dimension)
{
	local Vector2D PlotCorner;
	local IntPoint OutParcelBoundsMin;
	local IntPoint OutParcelBoundsMax;

	GetPlotRenderBounds(PlotCorner);
	Parcel.GetTileBounds(OutParcelBoundsMin, OutParcelBoundsMax);

	UpperLeft.X = (float(OutParcelBoundsMin.X) * CanvasDrawScale) + PlotCorner.X;
	UpperLeft.Y = (float(OutParcelBoundsMin.Y) * CanvasDrawScale) + PlotCorner.Y;

	Dimension.X = (OutParcelBoundsMax.X - OutParcelBoundsMin.X)  * CanvasDrawScale;
	Dimension.Y = (OutParcelBoundsMax.Y - OutParcelBoundsMin.Y) * CanvasDrawScale;
}

simulated private function Vector2D GetSpawnRenderLocation(XComGroupSpawn Spawn)
{
	local Vector2D PlotCorner;
	local TTile TileLoc;
	local Vector2D Result;

	GetPlotRenderBounds(PlotCorner);
	TileLoc = `XWORLD.GetTileCoordinatesFromPosition(Spawn.Location);

	Result.X = (float(TileLoc.X) * CanvasDrawScale) + PlotCorner.X;
	Result.Y = (float(TileLoc.Y) * CanvasDrawScale) + PlotCorner.Y;

	return Result;
}

simulated function RedrawClickBoxes(bool bFlushDebugLines=true)
{
	local Vector DrawDebugBoxCenter;	
	local Vector DrawDebugBoxExtents;	
	local string DebugTileDataString;
	local bool   bTestTraceValid;
	local int    Index;
	local VoxelRaytraceCheckResult CheckResult;

	if(bFlushDebugLines)
	{
		WorldInfo.FlushPersistentDebugLines();
	}

	DebugTileDataString = WorldData.GetTileDebugString_StaticFlags(ClickData[LastClickTypeIndex].ClickTile);	
	m_kTileInfoText.SetHTMLText(class'UIUtilities_Text'.static.GetSizedText(DebugTileDataString, 13));

	WorldData.ClearDebugTiles();
	WorldData.AddDebugTile(ClickData[LastClickTypeIndex].ClickTile);

	if(ClickData[0].ClickTile == ClickData[1].ClickTile)
	{
		ClickData[0].bValid = true;
		ClickData[1].bValid = false;
	}

	bTestTraceValid = true;
	for( Index = 0; Index < 2; ++Index )
	{
		bTestTraceValid = bTestTraceValid && ClickData[Index].bValid;

		if( ClickData[Index].bValid )
		{
			DrawDebugBoxExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
			DrawDebugBoxExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
			DrawDebugBoxExtents.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;
			
			DrawDebugBoxCenter = `XWORLD.GetPositionFromTileCoordinates(ClickData[Index].ClickTile);			
			DrawDebugBox(DrawDebugBoxCenter, DrawDebugBoxExtents, 255, 255, 255, true);
		}
	}

	if( bTestTraceValid )
	{
		CheckResult.bDebug = true;
		WorldData.VoxelRaytrace_Tiles( ClickData[0].ClickTile, ClickData[1].ClickTile, CheckResult );
	}
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local int Index;

	//Mouse picking variables
	local Vector2D v2MousePosition; 
	local Vector MouseWorldOrigin, MouseWorldDirection;
	local Vector vHitLocation, vHitNormal;
	local Actor HitActor;

	//Mouse pick drawing	
	local Vector DrawDebugHitBoxExtents;
	local Vector ProjectedClickLocation;
	
	//Map drawing variables
	local XComParcel IterateParcel;	
	local float Highlight;
	local Vector2D ScreenLocation_PlotCorner;
	local Vector2D PlotSize;
	local Vector2D ParcelUpperLeft;
	local Vector2D ParcelDimension;
	local Vector2D ScreenLocation_SoldierSpawn;

	//Objective parcel handling
	local Vector ScreenLocation_ObjectiveParcelCenter;
	
	if( ProcessClickType != EProcessClickType_None )
	{
		LastClickTypeIndex = int(ProcessClickType);

		// Grab the current mouse location.
		v2MousePosition = LocalPlayer(TacticalController.Player).ViewportClient.GetMousePosition();

		// Deproject the mouse position and store it in the cached vectors
		kCanvas.DeProject(v2MousePosition, MouseWorldOrigin, MouseWorldDirection);

		// Use XTrace as this accounts for building cut-outs
		HitActor = `XTRACEMGR.XTrace(eXTrace_AllActors, vHitLocation, vHitNormal, 
									 MouseWorldOrigin + (MouseWorldDirection * 100000.0f), MouseWorldOrigin, vect(0,0,0));
		if( HitActor != none )
		{
			History = `XCOMHISTORY;			

			`XWORLD.GetFloorTileForPosition(vHitLocation, ClickData[LastClickTypeIndex].ClickTile);
			if( ClickData[LastClickTypeIndex].ClickTile.X == -1 )
			{
				ClickData[LastClickTypeIndex].ClickTile = `XWORLD.GetTileCoordinatesFromPosition(vHitLocation);
			}	

			ClickData[LastClickTypeIndex].bValid = true;

			RedrawClickBoxes();

			DrawDebugHitBoxExtents.X = 5.0f;
			DrawDebugHitBoxExtents.Y = 5.0f;
			DrawDebugHitBoxExtents.Z = 5.0f;

			ClickData[LastClickTypeIndex].ClickLocation = vHitLocation;
			ClickData[LastClickTypeIndex].ClickActorName = HitActor.WorldInfo.GetMapName() $ "." $ string(HitActor.Name) $ "\n" $ string(HitActor.ObjectArchetype.Name);
			DrawDebugBox(ClickData[LastClickTypeIndex].ClickLocation, DrawDebugHitBoxExtents, 255, 255, 255, true);

			ClickData[LastClickTypeIndex].bDrawClickActorName = true;
		}

		ProcessClickType = EProcessClickType_None;
	}

	for( Index = 0; Index < 2; ++Index )
	{
		if( ClickData[Index].bDrawClickActorName )
		{
			ProjectedClickLocation = kCanvas.Project(ClickData[Index].ClickLocation);
			kCanvas.SetPos(ProjectedClickLocation.X, ProjectedClickLocation.Y);
			kCanvas.SetDrawColor(255,255,255);
			kCanvas.DrawText( ClickData[Index].ClickActorName );
		}
	}
	

	if( bShowMap )
	{
		GetPlotRenderBounds(ScreenLocation_PlotCorner, PlotSize);
		
		//Draw rectangles for the parcels
		for( Index = 0; Index < BattleDataState.MapData.ParcelData.Length; ++Index )
		{
			IterateParcel = ParcelManager.arrParcels[ BattleDataState.MapData.ParcelData[Index].ParcelArrayIndex ];
			GetParcelRenderBounds(IterateParcel, ParcelUpperLeft, ParcelDimension);

			kCanvas.SetPos(ParcelUpperLeft.X, ParcelUpperLeft.Y);

			Highlight = 1.0f;

			if( IterateParcel == ParcelManager.ObjectiveParcel )
			{
				ScreenLocation_ObjectiveParcelCenter.X = ParcelUpperLeft.X + (ParcelDimension.X  * 0.5f);
				ScreenLocation_ObjectiveParcelCenter.Y = ParcelUpperLeft.Y + (ParcelDimension.Y  * 0.5f);
				kCanvas.SetDrawColor(205 * Highlight, 50 * Highlight, 50 * Highlight, 200);
			}
			else
			{
				kCanvas.SetDrawColor(50 * Highlight, 50 * Highlight, 205 * Highlight, 200);				
			}	

			if( `MAPS.IsLevelLoaded(name(BattleDataState.MapData.ParcelData[Index].MapName), true) )
			{
				kCanvas.DrawRect( ParcelDimension.X, ParcelDimension.Y);
			}
			else
			{
				kCanvas.DrawBox( ParcelDimension.X, ParcelDimension.Y);
			}
		}

		//Draw text for the parcels
		for( Index = 0; Index < ParcelManager.arrParcels.Length; ++Index )
		{
			IterateParcel = ParcelManager.arrParcels[ BattleDataState.MapData.ParcelData[Index].ParcelArrayIndex ];
			GetParcelRenderBounds(IterateParcel, ParcelUpperLeft, ParcelDimension);

			kCanvas.SetPos(ParcelUpperLeft.X, ParcelUpperLeft.Y);
			kCanvas.SetDrawColor(255, 255, 255);
			kCanvas.DrawText(BattleDataState.MapData.ParcelData[Index].MapName@(IterateParcel == ParcelManager.ObjectiveParcel ? "\n(Objective:"@TacticalMissionManager.ActiveMission.MissionName@")" : "" ));
		}

		//If the map has finished generating, show objective / spawn information if it is available
		if( !ParcelManager.IsGeneratingMap() )
		{
			if( ParcelManager.SoldierSpawn != none )
			{
				ScreenLocation_SoldierSpawn = GetSpawnRenderLocation(ParcelManager.SoldierSpawn);

				kCanvas.SetPos(ScreenLocation_SoldierSpawn.X, ScreenLocation_SoldierSpawn.Y);
				kCanvas.SetDrawColor(255, 255, 255);
				kCanvas.DrawRect(CanvasDrawScale * 3, CanvasDrawScale * 3); // 3x3 tile spawn
				kCanvas.DrawText("Spawn");

				kCanvas.SetDrawColor(0, 255, 0);
				kCanvas.Draw2DLine(ScreenLocation_SoldierSpawn.X, ScreenLocation_SoldierSpawn.Y, 
									ScreenLocation_ObjectiveParcelCenter.X, ScreenLocation_ObjectiveParcelCenter.Y,
									kCanvas.DrawColor);
			}
		}		

		//Draw the plot rect last so that its text is not overwritten by parcel / exit rectangles
		kCanvas.SetPos(ScreenLocation_PlotCorner.X, ScreenLocation_PlotCorner.Y);
		kCanvas.SetDrawColor(50, 180, 50, 80);
		kCanvas.DrawRect(PlotSize.X, PlotSize.Y);

		kCanvas.SetPos(ScreenLocation_PlotCorner.X, ScreenLocation_PlotCorner.Y);
		kCanvas.SetDrawColor(255, 255, 255);
		kCanvas.DrawText(BattleDataState.MapData.PlotMapName);
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
	CanvasDrawScale = 4
}
