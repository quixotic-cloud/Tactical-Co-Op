//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Haven.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Haven extends XComGameState_ScanningSite
	config(GameBoard);

var int									AmountForFlyoverPopup;

var bool								bAlertOnXCOMArrival; // Show the Resistance Goods Available popup on arrival
var bool								bOpenOnXCOMArrival; // Open the Resistance Goods window on arrival

var localized string                    m_ResHQString;

var config array<int>					MinScanIntelReward;
var config array<int>					MaxScanIntelReward;
var config name							ResHQScanResource; // The name of the resource provided by scanning at the Haven

//#############################################################################################
//----------------   INTIALIZATION   ----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SetUpHavens(XComGameState StartState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Haven HavenState;

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	foreach StartState.IterateByClassType(class'XComGameState_Haven', HavenState)
	{
		// Initialize the continent this haven lives on
		HavenState.Continent = HavenState.GetWorldRegion().GetContinent().GetReference();

		if(HavenState.Region != XComHQ.StartingRegion)
		{
			HavenState.bNeedsLocationUpdate = true;
		}
		else
		{
			// Init Scan Intel Hours for the starting region
			HavenState.SetScanHoursRemaining(default.MinScanDays[`DIFFICULTYSETTING], default.MaxScanDays[`DIFFICULTYSETTING]);
			HavenState.bScanRepeatable = true;
		}
	}
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

// THIS FUNCTION SHOULD RETURN TRUE IN ALL THE SAME CASES AS Update
function bool ShouldUpdate( )
{
	local XComGameState_HeadquartersResistance ResHQ;
	local UIStrategyMap StrategyMap;

	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ( );
	StrategyMap = `HQPRES.StrategyMap2D;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (ResHQ.bIntelMode && StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass( class'UIAlert' ))
	{
		if (IsScanComplete( ))
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// IF ADDING NEW CASES WHERE bUpdated = true, UPDATE FUNCTION ShouldUpdate ABOVE
function bool Update(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local UIStrategyMap StrategyMap;
	local bool bUpdated;
	local int IntelRewardAmt;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	StrategyMap = `HQPRES.StrategyMap2D;
	bUpdated = false;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (ResHQ.bIntelMode && StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (IsScanComplete())
		{
			//Give intel reward for scanning
			IntelRewardAmt = GetScanIntelReward();

			if (IntelRewardAmt > 0)
			{
				XComHQ.AddResource(NewGameState, 'Intel', IntelRewardAmt);
				AmountForFlyoverPopup = IntelRewardAmt;
			}

			ResetScan();
			bUpdated = true;
		}
	}

	return bUpdated;
}

function HandleResistanceLevelChange(XComGameState NewGameState, EResistanceLevelType NewResLevel, EResistanceLevelType OldResLevel)
{
	local UIStrategyMapItem MapItem;
	local XComGameState_GeoscapeEntity ThisEntity;

	if(!NewGameState.GetContext().IsStartState())
	{
		// Update the tooltip on the map pin
		ThisEntity = self;

		if(`HQPRES != none && `HQPRES.StrategyMap2D != none)
		{
			MapItem = `HQPRES.StrategyMap2D.GetMapItem(ThisEntity);

			if(MapItem != none)
			{
				MapItem.GenerateTooltip(MapItem.MapPin_Tooltip);
			}
		}
	}
}

//#############################################################################################
//----------------   REWARDS   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetScanIntelReward()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int IntelReward;

	IntelReward = default.MinScanIntelReward[`DIFFICULTYSETTING] + `SYNC_RAND(default.MaxScanIntelReward[`DIFFICULTYSETTING] - default.MinScanIntelReward[`DIFFICULTYSETTING] + 1);
	
	// Check for Spy Ring Continent Bonus
	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	IntelReward += Round(float(IntelReward) * (float(ResistanceHQ.IntelRewardPercentIncrease) / 100.0));

	return IntelReward;
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function string GetDisplayName()
{
	if (GetWorldRegion().IsStartingRegion())
		return m_ResHQString;
}

function bool CanBeScanned()
{
	return (GetWorldRegion().IsStartingRegion());
}

function bool ShouldBeVisible()
{
	return (ResistanceActive() && GetWorldRegion().ResistanceLevel == eResLevel_Outpost);
}

function class<UIStrategyMapItem> GetUIClass()
{
	if (GetWorldRegion().IsStartingRegion())
		return class'UIStrategyMapItem_ResistanceHQ';
	else
		return class'UIStrategyMapItem_Haven';
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	return StaticMesh'UI_3D.Overwold_Final.RadioTower';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 1.0;
	ScaleVector.Y = 1.0;
	ScaleVector.Z = 1.0;

	return ScaleVector;
}

// Rotation adjustment for the 3D UI static mesh
function Rotator GetMeshRotator()
{
	local Rotator MeshRotation;

	MeshRotation.Roll = 0;
	MeshRotation.Pitch = 0;
	MeshRotation.Yaw = 0;

	return MeshRotation;
}

protected function bool CanInteract()
{
	return (ResistanceActive() && GetWorldRegion().IsStartingRegion());
}

//---------------------------------------------------------------------------------------
protected function bool DisplaySelectionPrompt()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// if click here and XComHQ is not in the region, fly to it
	if (XComHQ.CurrentLocation != GetReference())
	{
		return false;
	}

	return true;
}

//---------------------------------------------------------------------------------------
function DisplayResistanceGoods()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	
	if (ResistanceHQ.NumMonths > 0)
	{
		if (!ResistanceHQ.bHasSeenNewResistanceGoods)
		{
			// Flag the resistance goods as having been seen
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("New resistance HQ goods seen");
			ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
			NewGameState.AddStateObject(ResistanceHQ);
			ResistanceHQ.bHasSeenNewResistanceGoods = true;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}

		`HQPRES.UIResistanceGoods();
	}
}

function bool HasResistanceGoods()
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();

	if (ResistanceHQ.NumMonths > 0)
	{
		return true;
	}
	
	return false;
}

function bool HasSeenNewResGoods()
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();

	if (ResistanceHQ.NumMonths > 0)
	{
		return ResistanceHQ.bHasSeenNewResistanceGoods;
	}
	
	return true;
}


function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_Haven HavenState;
	local bool bSuccess;

	if (ShouldUpdate())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Haven");

		HavenState = XComGameState_Haven(NewGameState.CreateStateObject(class'XComGameState_Haven', ObjectID));
		NewGameState.AddStateObject(HavenState);

		bSuccess = HavenState.Update(NewGameState);
		`assert( bSuccess );

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	if (AmountForFlyoverPopup > 0)
	{
		FlyoverPopup();
	}
}

//---------------------------------------------------------------------------------------
function DestinationReached()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_Haven HavenState;

	super.DestinationReached();

	// Activate any benefit while the Avenger is located at ResHQ
	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	ResistanceHQ.OnXCOMArrives();
	
	if (bAlertOnXCOMArrival && !ResistanceHQ.bHasSeenNewResistanceGoods)
	{
		`HQPRES.UINewResHQGoodsAvailable();
	}
	else if (bOpenOnXCOMArrival)
	{
		DisplayResistanceGoods();
	}

	// Reset the flags if either were true
	if (bAlertOnXCOMArrival || bOpenOnXCOMArrival)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear ResHQ Haven on Arrival Flags");
		HavenState = XComGameState_Haven(NewGameState.CreateStateObject(class'XComGameState_Haven', ObjectID));
		NewGameState.AddStateObject(HavenState);
		HavenState.bAlertOnXCOMArrival = false;
		HavenState.bOpenOnXCOMArrival = false;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function OnXComLeaveSite()
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	super.OnXComLeaveSite();

	// Remove any benefit while the Avenger is located at ResHQ
	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	ResistanceHQ.OnXCOMLeaves();
}

simulated function OutpostBuiltCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (!XComHQ.bHasSeenSupplyDropReminder && XComHQ.IsSupplyDropAvailable())
	{
		`HQPRES.UISupplyDropReminder();
	}

	`GAME.GetGeoscape().Resume();
}

//---------------------------------------------------------------------------------------
simulated public function FlyoverPopup()
{
	local XComGameState NewGameState;
	local XComGameState_Haven HavenState;
	local string FlyoverResourceName;
	local Vector2D MessageLocation; 
		
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Flyover_Intel");

	FlyoverResourceName = class'UIUtilities_Strategy'.static.GetResourceDisplayName(ResHQScanResource, AmountForFlyoverPopup);
	MessageLocation = Get2DLocation();
	MessageLocation.Y -= 0.006; //scoot above the pin
	`HQPRES.GetWorldMessenger().Message(FlyoverResourceName $ " +" $ AmountForFlyoverPopup, `EARTH.ConvertEarthToWorld(MessageLocation), , , , , , , , 2.0);
	`HQPRES.m_kAvengerHUD.UpdateResources();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Flyover Popup");
	HavenState = XComGameState_Haven(NewGameState.CreateStateObject(class'XComGameState_Haven', self.ObjectID));
	NewGameState.AddStateObject(HavenState);
	HavenState.AmountForFlyoverPopup = 0;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function string GetUIButtonTooltipTitle()
{
	return class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetDisplayName()$":" @ GetWorldRegion().GetDisplayName());
}

simulated function string GetUIButtonTooltipBody()
{
	return m_strScanButtonLabel; //Res HQ should not show time remaining on scans, only display name & bonus
}

simulated function string GetUIButtonIcon()
{
	return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_ResHQ";
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bCheckForOverlaps = false;
}