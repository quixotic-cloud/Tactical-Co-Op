//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_Region
//  AUTHOR:  Mark Nauta -- 08/2014
//  PURPOSE: This file represents a region pin on the strategy map
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_Region extends UIStrategyMapItem;

var StaticMesh RegionMesh;
const NUM_TILES = 3;
var StaticMeshComponent RegionComponents[NUM_TILES];

var public localized String m_strLockedTT;
var public localized String m_strUnlockedTT;
var public localized String m_strContactTT;
var public localized String m_strOutpostTT;
var public localized String m_strControlTT;

var public localized String m_strScanForIntelLabel;
var public localized String m_strScanForOutpostLabel; 
var public localized String m_strButtonMakeContact;

var UIButton ContactButton; 
var UIButton OutpostButton;
var UIPanel BGPanel;
var UIScanButton ScanButton;

//var UIPanel ButtonHint; //bsg-jneal (9.14.16): adding button hint for when the region is available to build an outpost
var array<float> CumulativeTriangleArea;

var string PreviousTooltipString;
simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_WorldRegion LandingSite;
	local X2WorldRegionTemplate RegionTemplate;
	local Texture2D RegionTexture;
	local Object TextureObject;
	local Vector2D CenterWorld;
	local int i;

	// Spawn the children BEFORE the super.Init because inside that super, it will trigger UpdateFlyoverText and other functions
	// which may assume these children already exist. 

	BGPanel = Spawn(class'UIPanel', self);
	ContactButton = Spawn(class'UILargeButton', self);
	OutpostButton = Spawn(class'UIButton', self);

	//ButtonHint = Spawn(class'UIPanel', self); //bsg-jneal (9.14.16): adding button hint for when the region is available to build an outpost

	super.InitMapItem(Entity);

	BGPanel.InitPanel('regionLabelBG'); // on stage
	BGPanel.ProcessMouseEvents(OnBGMouseEvent);

	//bsg-jneal (9.14.16): adding button hint for when the region is available to build an outpost
	//ButtonHint.InitPanel('consoleHint'); // on stage
	//MC.FunctionBool("SetHintIcon", class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive()); //bsg-jneal (8.30.16): no longer using the contact button for button image, call it on the main clip now
	//bsg-jneal (9.14.16): end

	ContactButton.InitButton('contactButtonMC', m_strButtonMakeContact, OnContactClicked); // on stage
	ContactButton.OnMouseEventDelegate = ContactButtonOnMouseEvent; 
	// nlong (8.9.16) TTP - 6830: This flash function displays the appropriate "accept" button according to the system
	// This is for region buttons, like establishing a resistance contact
//	ContactButton.MC.FunctionBool("SetHintIcon", class'UIUtilities_Input'.static.IsAdvanceButtonSwapActive());
	// nlong (8.9.16) TTP - 6830: end

	OutpostButton.InitButton('towerButtonMC', , OnOutpostClicked); // on stage

	ScanButton = Spawn(class'UIScanButton', self).InitScanButton();
	ScanButton.SetY(118); //This location is to stop overlapping the pin art.
	ScanButton.SetButtonIcon("");
	ScanButton.SetDefaultDelegate(OnDefaultClicked);
//	ScanButton.OnSizeRealized = OnButtonSizeRealized;

	History = `XCOMHISTORY;

	LandingSite = XComGameState_WorldRegion(History.GetGameStateForObjectID(Entity.ObjectID));
	RegionTemplate = LandingSite.GetMyTemplate();

	TextureObject = `CONTENT.RequestGameArchetype(RegionTemplate.RegionTexturePath);

	if(TextureObject == none || !TextureObject.IsA('Texture2D'))
	{
		`RedScreen("Could not load region texture" @ RegionTemplate.RegionTexturePath);
		return self;
	}

	RegionTexture = Texture2D(TextureObject);
	RegionMesh = class'Helpers'.static.ConstructRegionActor(RegionTexture);

	for( i = 0; i < NUM_TILES; ++i)
	{
		InitRegionComponent(i, RegionTemplate);
	}

	class'Helpers'.static.GenerateCumulativeTriangleAreaArray(RegionComponents[0], CumulativeTriangleArea);

	// Update the Center location based on the mesh's centroid
	CenterWorld = `EARTH.ConvertWorldToEarth(class'Helpers'.static.GetRegionCenterLocation(RegionComponents[0], true));

	if (Entity.Get2DLocation() != CenterWorld)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Region Center");
		Entity = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_GeoscapeEntity', Entity.ObjectID));
		NewGameState.AddStateObject(Entity);
		Entity.Location.X = CenterWorld.X;
		Entity.Location.Y = CenterWorld.Y;

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	
	return self;
}
simulated function OnButtonSizeRealized()
{
	return; //bsteiner do we need all of this? 
	ScanButton.SetX(-ScanButton.Width / 2.0);
	
	ContactButton.SetX(-ContactButton.Width / 2.0);
	OutpostButton.SetX(-OutpostButton.Width / 2.0 - 5.0);

	//bsg-jneal (9.14.16): adding button hint for when the region is available to build an outpost
	//ButtonHint.SetX((-ContactButton.Width / 2.0) - 34); //bsg-jneal (8.31.16): set correct position and visibility after flyover text is set as they were not properly being set before, appears to be a timing issue
	//ButtonHint.Hide();
	//bsg-jneal (9.14.16): end
}

simulated function InitRegionComponent(int idx, X2WorldRegionTemplate tmpl)
{
	local StaticMeshComponent curRegion;
	local MaterialInstanceConstant NewMaterial;

	curRegion = new(self) class'StaticMeshComponent';
	curRegion.SetAbsolute(true, true, true);
	AttachComponent(curRegion);

	RegionComponents[idx] = curRegion;

	curRegion.SetStaticMesh(RegionMesh);
	curRegion.SetTranslation(`EARTH.ConvertEarthToWorldByTile(idx, vect2d(tmpl.RegionMeshLocation.X, tmpl.RegionMeshLocation.Y)));
	curRegion.SetScale(tmpl.RegionMeshScale);

	NewMaterial = new(self) class'MaterialInstanceConstant';
	NewMaterial.SetParent(curRegion.GetMaterial(0));
	curRegion.SetMaterial(0, NewMaterial);

	NewMaterial = new(self) class'MaterialInstanceConstant';
	NewMaterial.SetParent(curRegion.GetMaterial(1));
	curRegion.SetMaterial(1, NewMaterial);

	ReattachComponent(curRegion);
}

simulated function UpdateRegion (float newX, float newY, float newScale)
{
	local int i;
	for( i = 0; i < NUM_TILES; ++i)
	{
		UpdateRegionTile(i, newX, newY, newScale);
	}
}

simulated function UpdateRegionTile (int idx, float newX, float newY, float newScale)
{
	RegionComponents[idx].SetTranslation(`EARTH.ConvertEarthToWorldByTile(idx, vect2d(newX, newY)));
	RegionComponents[idx].SetScale(newScale);
	ReattachComponent(RegionComponents[idx]);
}

simulated function bool IsResHQRegion()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return XComHQ.StartingRegion == GeoscapeEntityRef;
}

function bool ShouldDrawUI(out Vector2D screenPos)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local UIResistance kResScreen;
	kResScreen = UIResistance(`SCREENSTACK.GetScreen(class'UIResistance'));

	if( kResScreen != none && kResScreen.RegionRef == GeoscapeEntityRef )
	{
		return false;
	}
	else
	{
		if(super.ShouldDrawUI(screenPos))
		{
			History = `XCOMHISTORY;
				RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));

			return RegionState.ResistanceLevel >= eResLevel_Unlocked;
		}

		return false;
	}
}

function bool ShouldDrawResInfo(XComGameState_WorldRegion RegionState)
{
	if( RegionState.bCanScanForContact || RegionState.HaveMadeContact() )
	{
		return true;
	}
	else if( GetStrategyMap() != none && GetStrategyMap().m_eUIState == eSMS_Resistance )
	{
		return true;
	}

	return false;
}

function UpdateFlyoverText()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local String RegionLabel;
	local String HavenLabel;
	local String StateLabel;
	local string HoverInfo;
	local int iResLevel;

	History = `XCOMHISTORY;
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));

	RegionLabel = class'UIUtilities_Text'.static.GetColoredText(RegionState.GetMyTemplate().DisplayName, GetRegionLabelColor());

	if( ShouldDrawResInfo(RegionState) )
	{
		HavenLabel = "+" $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ RegionState.GetSupplyDropReward(true);
		HavenLabel = class'UIUtilities_Text'.static.GetColoredText(HavenLabel, GetIncomeColor(RegionState.ResistanceLevel));
	}
	else
	{
		HavenLabel = "";	// Blank string will tell the supply income and region state to hide
	}
	
	HoverInfo = "";
	if( ShowContactButton() )
	{
		HoverInfo = PotentialSuppliesWithContact();
		ContactButton.Show();
	}
	else
	{
		ContactButton.Hide();
	}

	if( ShowOutpostButton() )
	{
		HoverInfo = PotentialSuppliesWithOutpost();
		
		OutpostButton.Show();
	}
	else
	{
		OutpostButton.Hide();
	}

	StateLabel = ""; //Possibly unused. 

	if( IsResHQRegion() )
	{
		iResLevel = eResLevel_Outpost + 1;
	}
	else
	{
		iResLevel = RegionState.ResistanceLevel;
	}

	SetRegionInfo(RegionLabel, HavenLabel, StateLabel, iResLevel, HoverInfo);
}

function UpdateFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local XComGameState_WorldRegion RegionState;
	local string ScanTitle;
	local string ScanTimeValue;
	local string ScanTimeLabel;
	local string ScanInfo;
	local int DaysRemaining;

	if( !bIsInited ) return; 

	super.UpdateFromGeoscapeEntity(GeoscapeEntity);

	RegionState = GetRegion();
	
	if (IsAvengerLandedHere())
	{
		ScanButton.SetButtonState(eUIScanButtonState_Expanded);

		if (RegionState.bCanScanForContact)
			ScanButton.SetButtonType(eUIScanButtonType_Contact);
		else if (RegionState.bCanScanForOutpost)
			ScanButton.SetButtonType(eUIScanButtonType_Tower);
		else
			ScanButton.SetButtonType(eUIScanButtonType_Default);
	}
	else
	{
		ScanButton.SetButtonState(eUIScanButtonState_Default);

		if (RegionState.bCanScanForContact)
			ScanButton.SetButtonType(eUIScanButtonType_Contact);
		else if( RegionState.bCanScanForOutpost )
			ScanButton.SetButtonType(eUIScanButtonType_Tower);
		else
			ScanButton.SetButtonType(eUIScanButtonType_Default);
	}

	if( RegionState.bCanScanForContact )
	{
		ScanTitle = m_strScanForIntelLabel;
		DaysRemaining = RegionState.GetNumScanDaysRemaining();
		ScanTimeValue = string(DaysRemaining);
		ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
		ScanInfo = "";
	}
	else if( RegionState.bCanScanForOutpost )
	{
		ScanTitle = m_strScanForOutpostLabel;
		DaysRemaining = RegionState.GetNumScanDaysRemaining();
		ScanTimeValue = string(DaysRemaining);
		ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
		ScanInfo = "";
	}

	ScanButton.SetText(ScanTitle, ScanInfo, ScanTimeValue, ScanTimeLabel);
	ScanButton.AnimateIcon(`GAME.GetGeoscape().IsScanning() && IsAvengerLandedHere());
	ScanButton.SetScanMeter(RegionState.GetScanPercentComplete());
	ScanButton.Realize();
}

function OnGeoscapeEntityUpdated()
{
	GenerateTooltip(MapPin_Tooltip);
}
function EUIState GetIncomeColor(EResistanceLevelType eResLevel)
{
	switch( eResLevel )
	{
	case eResLevel_Contact:
	case eResLevel_Outpost:
		return eUIState_Good;
	case eResLevel_Locked:
	case eResLevel_Unlocked:
	default:
		return eUIState_Disabled;
	}
}
public function SetRegionInfo(string RegionLabel, string HavenLabel, string StateLabel, int ResistenceLevel, string HoverInformation)
{
	mc.BeginFunctionOp("SetRegionInfo");
	mc.QueueString(RegionLabel);
	mc.QueueString(HavenLabel);
	mc.QueueString(StateLabel);
	mc.QueueNumber(ResistenceLevel);
	mc.QueueString(HoverInformation);
	mc.EndOp();
}

function EUIState GetRegionLabelColor()
{
	return eUIState_Normal;
}

function UpdateVisuals()
{
	super.UpdateVisuals();
	UpdateMaterials();
}

function UpdateMaterials()
{
	local int i;
	local XComGameState_WorldRegion RegionState;
	local EResistanceLevelType eResistance;
	local bool HasAlienFacilityOrGoldenPathMission;
	local UIStrategyMap kMap;

	// These variables are being calculated outside so it doesn't have to calculate everytime that we loop.
	kMap = UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap'));
	RegionState = GetRegion();
	eResistance = RegionState.ResistanceLevel;
	HasAlienFacilityOrGoldenPathMission = RegionState.HasAlienFacilityOrGoldenPathMission();
	for( i = 0; i < NUM_TILES; ++i)
	{
		//UpdateRegionMaterial(i);
		UpdateRegionMaterial(i, kMap, RegionState, eResistance, HasAlienFacilityOrGoldenPathMission);
	}
}
//function UpdateRegionMaterial(int idx)
function UpdateRegionMaterial(int idx, UIStrategyMap kMap, XComGameState_WorldRegion RegionState, EResistanceLevelType eResistance, bool HasAlienFacilityOrGoldenPathMission)
{
	local XComGameStateHistory History;
	//local XComGameState_WorldRegion RegionState;
	local string CurrentBorderPath, CurrentInteriorPath, DesiredBorderPath, DesiredInteriorPath;
	local MaterialInstanceConstant NewMaterial;
	local Object MaterialObject;
	//local EResistanceLevelType eResistance;
	local XComGameState_HeadquartersXCom XComHQ;
	local StaticMeshComponent curRegion;
	//local UIStrategyMap kMap;
	
	curRegion = RegionComponents[idx];

	CurrentBorderPath = PathName(curRegion.GetMaterial(0));
	CurrentInteriorPath = PathName(curRegion.GetMaterial(1));

	History = `XCOMHISTORY;
	//RegionState = GetRegion();
	//
	//eResistance = RegionState.ResistanceLevel;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.bFreeContact && eResistance < eResLevel_Unlocked)
	{
		eResistance = eResLevel_Unlocked;
	}

	//kMap = UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap'));

	if(eResistance == eResLevel_Unlocked && kMap != none && kMap.m_eUIState != eSMS_Resistance)
	{
		eResistance = eResLevel_Locked;
	}

	DesiredBorderPath = class'X2StrategyGameRulesetDataStructures'.default.ResistanceLevelBorderPaths[eResistance];
	DesiredInteriorPath = class'X2StrategyGameRulesetDataStructures'.default.ResistanceLevelInteriorPaths[eResistance];

	//if(RegionState.HasAlienFacilityOrGoldenPathMission() && !RegionState.HaveMadeContact())
	if(HasAlienFacilityOrGoldenPathMission && !RegionState.HaveMadeContact())
	{
		DesiredBorderPath = class'X2StrategyGameRulesetDataStructures'.default.FullControlBorderPath;
		DesiredInteriorPath = class'X2StrategyGameRulesetDataStructures'.default.FullControlInteriorPath;
	}

	if(CurrentBorderPath != DesiredBorderPath)
	{
		MaterialObject = `CONTENT.RequestGameArchetype(DesiredBorderPath);
		if(MaterialObject != none && MaterialObject.IsA('MaterialInstanceConstant'))
		{
			NewMaterial = MaterialInstanceConstant(MaterialObject);
			curRegion.SetMaterial(0, NewMaterial);
		}
		
	}

	if(CurrentInteriorPath != DesiredInteriorPath)
	{
		MaterialObject = `CONTENT.RequestGameArchetype(DesiredInteriorPath);
		if(MaterialObject != none && MaterialObject.IsA('MaterialInstanceConstant'))
		{
			NewMaterial = MaterialInstanceConstant(MaterialObject);
			curRegion.SetMaterial(1, NewMaterial);
		}
	}
}

function GenerateTooltip(string tooltipHTML)
{
	local UITextTooltip ActiveTooltip;
	local XComGameState_WorldRegion RegionState;
	local String strIncome, strTooltip;
	local XGParamTag ParamTag;

	if( !class'UIUtilities_Strategy'.static.GetXComHQ().IsContactResearched() || `SCREENSTACK.GetScreen(class'UIResistance') != none )
	{
		return;
	}

	RegionState = GetRegion();

	if(!(RegionState.bCanScanForContact || RegionState.bCanScanForOutpost))
	{
		strIncome = class'UIUtilities_Text'.static.GetColoredText("+" $ RegionState.GetSupplyDropReward(true), GetIncomeColor(RegionState.ResistanceLevel));

		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		ParamTag.StrValue0 = RegionState.GetMyTemplate().DisplayName;
		ParamTag.StrValue1 = strIncome;

		switch(RegionState.ResistanceLevel)
		{
		case eResLevel_Contact:
		case eResLevel_Outpost:
			strTooltip = `XEXPAND.ExpandString(m_strContactTT);
			if(RegionState.ResistanceLevel == eResLevel_Outpost)
			{
				strTooltip = strTooltip $ "\n" $ m_strOutpostTT;
			}
			break;
		case eResLevel_Locked:
			strTooltip = `XEXPAND.ExpandString(m_strLockedTT);
			break;
		case eResLevel_Unlocked:
			strTooltip = `XEXPAND.ExpandString(m_strUnlockedTT);
			break;
		default:
			strTooltip = "";
			break;
		}


		if (strTooltip != PreviousTooltipString)
		{
			if (CachedTooltipID >= 0)
			{
				ActiveTooltip = UITextTooltip(Movie.Pres.m_kTooltipMgr.GetTooltipByID(CachedTooltipID));
			}

			if (ActiveTooltip == none)
			{
				CachedTooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(strTooltip, 15, 0, string(MCPath),, false,, true);
			}
			else
			{
				ActiveTooltip.SetText(strTooltip);
				ActiveTooltip.UpdateData();
			}
			
			PreviousTooltipString = strTooltip;
		}
		
		bHasTooltip = true;
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus(); //bsg-jneal (9.14.16): receive focus on the super to help set proper ui states

	//ContactButton.OnLoseFocus();
	//OutpostButton.OnLoseFocus();
	ScanButton.OnReceiveFocus();
	ContactButton.OnReceiveFocus();
	OutpostButton.OnReceiveFocus();

	/*if(`ISCONTROLLERACTIVE && ShowOutpostButton()) 
	{
		ButtonHint.Show();
	}*/
}
simulated function OnLoseFocus()
{
	//bsg-jneal (9.14.16): call lose focus on the super to help set correct animation states
	super.OnLoseFocus();

	//bsg-jneal (9.14.16): end
	ScanButton.OnLoseFocus();
	ContactButton.OnLoseFocus();
	OutpostButton.OnLoseFocus();
	//ButtonHint.Hide();
}

// Handle mouse hover special behavior

simulated function OnMouseIn()
{
	local XComGameState_WorldRegion RegionState;

	RegionState = GetRegion();

	if (GetStrategyMap() != none && !RegionState.HaveMadeContact() && GetStrategyMap().m_eUIState != eSMS_Flight)
	{
		GetStrategyMap().SetUIState(eSMS_Resistance);
	}
	super.OnMouseIn();
}

// Clear mouse hover special behavior

simulated function OnMouseOut()
{
	local XComGameState_WorldRegion RegionState;

	RegionState = GetRegion();

	if(GetStrategyMap() != none && !RegionState.HaveMadeContact() && GetStrategyMap().m_eUIState != eSMS_Flight)
	{
		GetStrategyMap().SetUIState(eSMS_Default);
	}
	super.OnMouseOut();
}

// --------------------------------------------------------------------------------------
simulated function OnChildMouseEvent(UIPanel control, int cmd)
{
	//local array<string> EmptyArgs; 

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		OnMouseIn();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		OnMouseOut();
		break;
	default:
		break;
	}
}

simulated function OnBGMouseEvent(UIPanel control, int cmd)
{
	local array<string> EmptyArgs;
	//Connect this to the base map item mouse behavior. 
	EmptyArgs.length = 0;
	super.OnMouseEvent(cmd, EmptyArgs);
	//Do nothing, per Jake. But, maybe this will come back. -bsteiner 6/2/2015 
}

function OnContactClicked(UIButton Button)
{
	`HQPRES.UIMakeContact(GetRegion());
}

function ContactButtonOnMouseEvent(UIPanel Panel, int Cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		OnMouseIn();
		break;

	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		OnMouseOut();
		break;
	}
}

function OnOutpostClicked(UIButton Button)
{
	`HQPRES.UIBuildOutpost(GetRegion());
}

function OnDefaultClicked()
{
	GetRegion().AttemptSelectionCheckInterruption();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return true;
	}

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		if (ShowContactButton())
		{
			OnContactClicked(ContactButton);
		}
		else if (ShowOutpostButton())
		{
			OnOutpostClicked(OutpostButton);
		}
		else if (IsAvengerLandedHere())
		{
			ScanButton.ClickButtonScan();
		}
		else
		{
			OnDefaultClicked();
		}

		return true;		
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function bool IsSelectable()
{
	return !IsResHQRegion() && 
		(ScanButton.GetButtonType() == eUIScanButtonType_Default || 
		ScanButton.GetButtonType() == eUIScanButtonType_Contact ||
		ScanButton.GetButtonType() == eUIScanButtonType_Tower) &&
		((ShowOutpostButton() || ShowContactButton()) ||
		(GetRegion().bCanScanForOutpost || GetRegion().bCanScanForContact));
}
simulated function bool ShowOutpostButton()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().IsOutpostResearched() && GetRegion().ResistanceLevel == eResLevel_Contact && !GetRegion().bCanScanForOutpost;
}

simulated function bool ShowContactButton()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().IsContactResearched() && GetRegion().ResistanceLevel == eResLevel_Unlocked && !GetRegion().bCanScanForContact;
}

simulated function XComGameState_WorldRegion GetRegion()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
}

simulated function string PotentialSuppliesWithContact()
{
	return ("+" $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ GetRegion().GetSupplyDropReward(true));
}
simulated function string PotentialSuppliesWithOutpost()
{
	return ("+" $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ GetRegion().GetSupplyDropReward(, true));
}

simulated function int GetRandomTriangle()
{
	local int Tri;
	local int ArrLength;
	local float RandomArea;

	ArrLength = CumulativeTriangleArea.Length;
	if (ArrLength <= 0) return 0;

	RandomArea = `SYNC_FRAND() * CumulativeTriangleArea[ArrLength - 1];
	for (Tri = 0; Tri < ArrLength - 1; ++Tri)
	{
		if (CumulativeTriangleArea[Tri] > RandomArea) break;
	}

	return Tri;
}

defaultproperties
{
	bDisableHitTestWhenZoomedOut = false;

	bProcessesMouseEvents = false;
}