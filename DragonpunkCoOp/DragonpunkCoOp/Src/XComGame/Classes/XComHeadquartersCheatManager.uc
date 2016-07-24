//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComHeadquartersCheatManager 
	extends XComCheatManager 
	within XComHeadquartersController;

var bool bSeeAll;

var bool bDoGlobeView;

var bool bFreeCam;
var bool bDebugAIEvents;
var name ForceAlienTemplateName;
var bool bAllowDeluge;
var bool bHideObjectives;
var bool bHideTodoWidget;
var bool bGamesComDemo;
var TDateTime DarkEventPopupTime;

var bool bDumpSkelPoseUpdates;

var int numHeadshots;

/*
exec function BaseRoomCamera( float x, float y )
{
local vector PawnTarget;

PawnTarget = Pawn.Location;
PawnTarget.X += x;
PawnTarget.Y += y;

XComHeadquartersCamera(PlayerCamera).StartRoomView( PawnTarget );
}*/

//==============================================================================
//		UI DEBUGGING
//==============================================================================

exec function ActivatePreviewBuild()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: ActivatePreviewBuild");
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.bPreviewBuild = true;
	if(AlienHQ.Actions.Find('AlienAI_EndPreviewPlaythrough') == INDEX_NONE)
	{
		AlienHQ.Actions.AddItem('AlienAI_EndPreviewPlaythrough');
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function DeactivatePreviewBuild()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: DeactivatePreviewBuild");
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.bPreviewBuild = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function MakeSoldierMIA()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Unit> AllSoldiers;
	local StateObjectReference EmptyRef;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AllSoldiers = XComHQ.GetSoldiers();

	if(AllSoldiers.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: MakeSoldierMIA");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		NewGameState.AddStateObject(AlienHQ);
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AllSoldiers[0].ObjectID));
		NewGameState.AddStateObject(UnitState);
		UnitState.bCaptured = true;
		XComHQ.RemoveFromCrew(UnitState.GetReference());

		for(idx = 0; idx < XComHQ.Squad.Length; idx++)
		{
			if(XComHQ.Squad[idx] == UnitState.GetReference())
			{
				XComHQ.Squad[idx] = EmptyRef;
				break;
			}
		}

		AlienHQ.CapturedSoldiers.AddItem(UnitState.GetReference());
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

}

exec function HealAllSoldiers()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', HealProject)
	{
		HealProject.OnProjectCompleted();
	}
}

exec function SetRegionResLevel(name RegionName, int ResLevel)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_WorldRegion RegionState;
	local EResistanceLevelType OldResLevel;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetRegionResLevel");

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if(RegionState.GetMyTemplateName() == RegionName && EResistanceLevelType(ResLevel) != RegionState.ResistanceLevel)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
			NewGameState.AddStateObject(RegionState);
			OldResLevel = RegionState.ResistanceLevel;
			RegionState.SetResistanceLevel(NewGameState, EResistanceLevelType(ResLevel));
			
			if(OldResLevel < eResLevel_Contact && RegionState.ResistanceLevel == eResLevel_Contact)
			{
				RegionState.bResLevelPopup = true;
				RegionState.CurrentMinScanDays = RegionState.MinBuildHavenDays[`DIFFICULTYSETTING];
				RegionState.CurrentMaxScanDays = REgionState.MaxBuildHavenDays[`DIFFICULTYSETTING];
				RegionState.ResetScan(RegionState.CurrentMinScanDays, RegionState.CurrentMaxScanDays);
				RegionState.m_strScanButtonLabel = Regionstate.m_strOutpostScanButtonLabel;
			}
			else if(OldResLevel < eResLevel_Outpost && RegionState.ResistanceLevel == eResLevel_Outpost)
			{
				RegionState.bResLevelPopup = true;
			}
			break;
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

exec function SetAllRegionsResLevel(int ResLevel)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_WorldRegion RegionState;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetAllRegionsResLevel");

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
		NewGameState.AddStateObject(RegionState);
		RegionState.SetResistanceLevel(NewGameState, EResistanceLevelType(ResLevel));	
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	GiveTech('ResistanceCommunications');
	GiveTech('ResistanceRadio');
	`HQPRES.StrategyMap2D.SetUIState(eSMS_Resistance);
}

exec function GetMapItemLocation(name MapItemName)
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity MapItemState;
	local string DisplayString;

	History = `XCOMHISTORY;	
	foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', MapItemState)
	{
		if (MapItemState.GetMyTemplateName() == MapItemName)
		{
			DisplayString $= MapItemState.GetMyTemplateName() $ ": (" $ MapItemState.Get2DLocation().X $ "," @ MapItemState.Get2DLocation().Y $ ")\n";
			break;
		}
	}
	
	`log(DisplayString);
}

exec function SetMapItemLocation(name MapItemName, float NewX = -1.0f, float NewY = -1.0f)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local StateObjectReference MapItemRef;
	local XComGameState_GeoscapeEntity MapItemState;
	local UIStrategyMapItem kItem;
	local Vector MapItemLocation;
	local Vector2D MapItemLoc2D;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetMapItemLocation");

	foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', MapItemState)
	{
		if (MapItemState.GetMyTemplateName() == MapItemName && NewX > 0.0f && NewY > 0.0f)
		{
			MapItemState = XComGameState_GeoscapeEntity(NewGameState.CreateStateObject(MapItemState.Class, MapItemState.ObjectID));
			NewGameState.AddStateObject(MapItemState);
			MapItemRef = MapItemState.GetReference();

			MapItemState.Location.X = NewX;
			MapItemState.Location.Y = NewY;

			MapItemLocation = MapItemState.Location;
			MapItemLoc2D.X = MapItemLocation.X;
			MapItemLoc2D.Y = MapItemLocation.Y;
			
			break;
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		foreach AllActors(class'UIStrategyMapItem', kItem)
		{
			if (kItem.GeoscapeEntityRef == MapItemRef)
			{
				// set this pin's location
				kItem.SetLoc(MapItemLoc2D);

				// set this actor's location
				kItem.SetLocation(`EARTH.ConvertEarthToWorld(MapItemLoc2D));

				kItem.MapItem3D.SetLocation(MapItemLocation);
			}
		}
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

exec function SetTestSeconds(float TestSeconds)
{
	`EARTH.StartOffset = TestSeconds;
}

exec function SetLinkLocLerp(name RegionAName, name RegionBName, float NewLocLerp)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_RegionLink LinkState;
	local StateObjectReference LinkRef;
	local XComGameState_WorldRegion RegionA, RegionB;
	local UIStrategyMapItem kItem;
	local Vector LinkLocation;
	local Vector2D LinkLoc2D;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetLinkLocLerp");

	foreach History.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		RegionA = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkState.LinkedRegions[0].ObjectID));
		RegionB = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkState.LinkedRegions[1].ObjectID));

		if ((RegionA.GetMyTemplateName() == RegionAName && RegionB.GetMyTemplateName() == RegionBName) ||
			(RegionA.GetMyTemplateName() == RegionBName && RegionB.GetMyTemplateName() == RegionAName))
		{
			LinkState = XComGameState_RegionLink(NewGameState.CreateStateObject(class'XComGameState_RegionLink', LinkState.ObjectID));
			NewGameState.AddStateObject(LinkState);
			LinkState.LinkLocLerp = NewLocLerp;
			LinkRef = LinkState.GetReference();
			LinkState.UpdateWorldLocation();
			LinkLocation = LinkState.GetWorldLocation();
			LinkLoc2D.X = LinkLocation.X;
			LinkLoc2D.Y = LinkLocation.Y;
			break;
		}
	}


	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		foreach AllActors(class'UIStrategyMapItem', kItem)
		{
			if (kItem.GeoscapeEntityRef == LinkRef)
			{
				kItem.SetLoc(LinkLoc2D);
				kItem.SetLocation(LinkLocation);
				kItem.MapItem3D.SetLocation(LinkLocation);
			}
		}
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}


exec function SetLinkLength(name RegionAName, name RegionBName, float NewLength)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_RegionLink LinkState;
	local StateObjectReference LinkRef;
	local XComGameState_WorldRegion RegionA, RegionB;
	local UIStrategyMapItem3D kItem;
	local Vector LinkScale;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetLinkLength");

	foreach History.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		RegionA = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkState.LinkedRegions[0].ObjectID));
		RegionB = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkState.LinkedRegions[1].ObjectID));

		if((RegionA.GetMyTemplateName() == RegionAName && RegionB.GetMyTemplateName() == RegionBName) ||
		   (RegionA.GetMyTemplateName() == RegionBName && RegionB.GetMyTemplateName() == RegionAName))
		{
			LinkState = XComGameState_RegionLink(NewGameState.CreateStateObject(class'XComGameState_RegionLink', LinkState.ObjectID));
			NewGameState.AddStateObject(LinkState);
			LinkState.LinkLength = NewLength;
			LinkRef = LinkState.GetReference();
			LinkScale = LinkState.GetMeshScale();
			break;
		}
	}


	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		foreach AllActors(class'UIStrategyMapItem3D', kItem)
		{
			if(kItem.GeoscapeEntityRef == LinkRef)
			{
				kItem.SetScale3D(LinkScale);
			}
		}
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

exec function PrintRegionLinkLengths()
{
	local XComGameStateHistory History;
	local XComGameState_RegionLink LinkState;
	local XComGameState_WorldRegion RegionA, RegionB;
	local string DisplayString;

	History = `XCOMHISTORY;
	DisplayString = "";

	foreach History.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		RegionA = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkState.LinkedRegions[0].ObjectID));
		RegionB = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkState.LinkedRegions[1].ObjectID));
		DisplayString $= RegionA.GetMyTemplateName() $ "," @ RegionB.GetMyTemplateName() @ "-" @ string(LinkState.GetLinkDistance()) $ "\n";
	}

	`log(DisplayString);
}

exec function PrintRegionLinkLocLerps()
{
	local XComGameStateHistory History;
	local XComGameState_RegionLink LinkState;
	local XComGameState_WorldRegion RegionA, RegionB;
	local string DisplayString;

	History = `XCOMHISTORY;
		DisplayString = "";

	foreach History.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		RegionA = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkState.LinkedRegions[0].ObjectID));
		RegionB = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkState.LinkedRegions[1].ObjectID));
		DisplayString $= RegionA.GetMyTemplateName() $ "," @ RegionB.GetMyTemplateName() @ "-" @ string(LinkState.GetOldWorldLocationLerp()) $ "\n";
	}

	`log(DisplayString);
}


exec function ShowAllRegionLinks()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_RegionLink LinkState;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: ShowAllRegionLinks");

	// Remove all links
	foreach History.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		NewGameState.RemoveStateObject(LinkState.ObjectID);
	}

	// Add all regions, and clear their linked regions list
	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
		NewGameState.AddStateObject(RegionState);
		RegionState.LinkedRegions.Length = 0;
	}

	// Create all links
	class'XComGameState_RegionLink'.static.CreateAllLinks(NewGameState);

	foreach NewGameState.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(LinkState.LinkedRegions[0].ObjectID));
		LinkState.Location = RegionState.Location;
		LinkState.Location.z = 0.2;
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	GiveTech('ResistanceCommunications');
	`HQPRES.StrategyMap2D.SetUIState(eSMS_Resistance);
}

exec function RefreshDarkEventUI()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_DarkEvent DarkEventState;
	local XComGameState_ObjectivesList ObjListState;
	

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: RefreshDarkEventUI");

	foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
	{
		break;
	}

	if(ObjListState != none)
	{
		ObjListState = XComGameState_ObjectivesList(NewGameState.CreateStateObject(class'XComGameState_ObjectivesList', ObjListState.ObjectID));
		NewGameState.AddStateObject(ObjListState);
	}
	else
	{
		ObjListState = XComGameState_ObjectivesList(NewGameState.CreateStateObject(class'XComGameState_ObjectivesList'));
		NewGameState.AddStateObject(ObjListState);
	}

	foreach History.IterateByClassType(class'XComGameState_DarkEvent', DarkEventState)
	{
		if(DarkEventState.GetMyTemplate().bNeverShowObjective || (!DarkEventState.GetMyTemplate().bInfiniteDuration && AlienHQ.ActiveDarkEvents.Find('ObjectID', DarkEventState.ObjectID) == INDEX_NONE))
		{
			ObjListState.HideObjectiveDisplay("DARKEVENTOBJECTIVE", DarkEventState.GetDisplayName());
		}
	}

	class'X2StrategyGameRulesetDataStructures'.static.UpdateObjectivesUI(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

}
exec function AccelerateDoom(optional bool bStart = true)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: AccelerateDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	if(bStart)
	{
		AlienHQ.StartAcceleratingDoom();
	}
	else
	{
		AlienHQ.StopAcceleratingDoom();
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function ThrottleDoom(optional bool bStart = true)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: ThrottleDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	
	if(bStart)
	{
		AlienHQ.StartThrottlingDoom();
	}
	else
	{
		AlienHQ.StopThrottlingDoom();
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function RemoveFortressDoom(optional int DoomToRemove = 1)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: FastForwardFortressDoomTimer");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.RemoveDoomFromFortress(NewGameState, DoomToRemove, "Cheat Removal");
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function FastForwardFortressDoomTimer()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: FastForwardFortressDoomTimer");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.FortressDoomIntervalEndTime = AlienHQ.GetCurrentTime();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function FastForwardFacilityDoomTimer()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: FastForwardFacilityDoomTimer");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.FacilityDoomIntervalEndTime = AlienHQ.GetCurrentTime();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function BuildAlienFacility()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Facilities;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: BuildFacility");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.BuildAlienFacility(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	Facilities = AlienHQ.GetValidFacilityDoomMissions();

	if(Facilities.Length > 1)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: BuildFacility Update Doom Timer");
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		NewGameState.AddStateObject(AlienHQ);
		AlienHQ.UpdateFacilityDoomHours(true);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

exec function DestroyRandomAlienFacility()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local array<XComGameState_MissionSite> Facilities;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_AlienNetwork')
		{
			Facilities.AddItem(MissionState);
		}
	}

	if(Facilities.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: DestroyRandomAlienFacility");
		MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', Facilities[`SYNC_RAND(Facilities.Length)].ObjectID));
		NewGameState.AddStateObject(MissionState);
		MissionState.GetMissionSource().OnSuccessFn(NewGameState, MissionState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

exec function TriggerEvent(name EventName)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Trigger Event");
	`XEVENTMGR.TriggerEvent(EventName, , ,NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function ResetConstructionRate()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cheat: Update XComHQ");	
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	
	// Reset the Construction Rate
	XComHQ.ConstructionRate = XComHQ.XComHeadquarters_DefaultConstructionWorkPerHour;
	XComHQ.HandlePowerOrStaffingChange(NewGameState);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function SpawnBlackMarket(optional bool bOpen = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarketState;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Spawn Black Market");
	BlackMarketState = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', BlackMarketState.ObjectID));
	NewGameState.AddStateObject(BlackMarketState);
	BlackMarketState.ShowBlackMarket(NewGameState, true);
	if (bOpen)
		BlackMarketState.OpenBlackMarket(NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function SpawnMission(name MissionSourceName, name MissionRewardName, optional name ExtraMissionRewardName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local X2MissionSourceTemplate MissionSource;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Reward RewardState;
	local array<XComGameState_Reward> MissionRewards;
	local X2RewardTemplate RewardTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(XComHQ.StartingRegion.ObjectID));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate(MissionSourceName));
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(MissionRewardName));

	if(MissionSource == none || RewardTemplate == none)
	{
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Spawn Mission");
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(RewardState);
	RewardState.GenerateReward(NewGameState, , RegionState.GetReference());
	MissionRewards.AddItem(RewardState);

	if(ExtraMissionRewardName != '')
	{
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(ExtraMissionRewardName));

		if(RewardTemplate != none)
		{
			RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
			NewGameState.AddStateObject(RewardState);
			RewardState.GenerateReward(NewGameState, , RegionState.GetReference());
			MissionRewards.AddItem(RewardState);
		}
	}

	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite'));
	NewGameState.AddStateObject(MissionState);
	MissionState.BuildMission(MissionSource, RegionState.GetRandom2DLocationInRegion(), RegionState.GetReference(), MissionRewards);

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

exec function PrintActiveObjectives()
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;
	local string ObjectiveString;

	History = `XCOMHISTORY;
	ObjectiveString = "";

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if(ObjectiveState.ObjState == eObjectiveState_InProgress)
		{
			ObjectiveState.GetMyTemplate();
			ObjectiveString $= ObjectiveState.GetMyTemplateName() $ "\n";
		}
	}

	`log(ObjectiveString);
}

exec function SpamObjectives()
{
	//We're going to start up some objectives for you.
	StartObjective('T1_M1_AutopsyACaptain', false);
	StartObjective('T1_M2_HackACaptain', false);
	StartObjective('T1_M2_S1_BuildProvingGrounds', false);
	StartObjective('T1_M2_S2_BuildSKULLJACK', false);
	StartObjective('T1_M2_S3_SKULLJACKCaptain', false);
	StartObjective('T1_M3_KillCodex', false);
	StartObjective('T1_M4_StudyCodexBrain', false);
	StartObjective('T1_M4_S1_StudyCodexBrainPt1', false);

	ForceCompleteObjective('T1_M3_KillCodex');

	PrintActiveObjectives();
}

exec function SetSoldierStat(ECharStatType eStat, float NewStat, string UnitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cheat: Set Soldier Stat");

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == 'Soldier' && UnitState.GetFullName() == UnitName)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.SetBaseMaxStat(eStat, NewStat);

			if(eStat == eStat_HP && UnitState.IsInjured())
			{
				UnitState.SetCurrentStat(eStat, (NewStat-1.0f));
			}
			else
			{
				UnitState.SetCurrentStat(eStat, NewStat);
			}
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

exec function RemoveAllPCSFromSoldier(string UnitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local array<XComGameState_Item> Items;
	local XComGameState_Item ItemState;
	local int idx, i;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cheat: Remove All PCS from Soldier");

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == 'Soldier' && UnitState.GetFullName() == UnitName)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);

			Items = UnitState.GetAllItemsInSlot(eInvSlot_CombatSim, NewGameState);

			for(i = 0; i < Items.Length; i++)
			{
				ItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', Items[i].ObjectID));
				NewGameState.AddStateObject(ItemState);
				UnitState.RemoveItemFromInventory(ItemState, NewGameState);
			}
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

exec function MakeSoldierItemsAvailable(string UnitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cheat: Make Soldier Items Available");

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == 'Soldier' && UnitState.GetFullName() == UnitName)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);

			UnitState.MakeItemsAvailable(NewGameState);
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

exec function ReequipOldSoldierItems(string UnitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cheat: Reequip Old Soldier Items");

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == 'Soldier' && UnitState.GetFullName() == UnitName)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);

			UnitState.EquipOldItems(NewGameState);
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

exec function GamescomDemo()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local array<XComGameState_Unit> AllSoldiers, InjuredSoldiers;
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState;
	local XComGameState_Objective ObjectiveState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_MissionCalendar CalendarState;
	local XComGameState_GameTime TimeState;
	local XComGameState_Skyranger SkyrangerState;
	local XComGameState_Haven HavenState, StartingHavenState;
	local array<name> SoldierClasses;
	local bool bSpecialist;
	local int idx, i, j, NumSoldiers;
	local TDateTime GOPsTime;
	local XGBase kBase;
	local Vector vLoc;
	local Vector2D v2Loc;
	local StateObjectReference EastAFRef, NorthAFRef, WestEURef, SouthAFRef, EmptyRef;
	local XComGameState_RegionLink LinkState;
	local CharacterPoolManager CharMgr;

	bGamesComDemo = true;

	// TOD
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(`STRATEGYRULES.GameTime, 6);
	`GAME.GetGeoscape().m_kDateTime = `STRATEGYRULES.GameTime;
	TimeState = XComGameState_GameTime(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Geoscape Pause");
	TimeState = XComGameState_GameTime(NewGameState.CreateStateObject(TimeState.Class, TimeState.ObjectID));
	TimeState.CurrentTime = `STRATEGYRULES.GameTime;
	NewGameState.AddStateObject(TimeState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	kBase = `GAME.GetGeoscape().m_kBase;
	`MAPS.RemoveStreamingMapByName(kBase.CurrentLightEnvironment);
	kBase.CurrentLightEnvironment = kBase.GetTimeOfDayMap();
	kBase.SkyAndLight_Level = `MAPS.AddStreamingMap(kBase.CurrentLightEnvironment, vLoc, , true);	

	// Facilities
	GiveFacility('AdvancedWarfareCenter', 3);
	GiveFacility('ProvingGround', 4);
	GiveFacility('OfficerTrainingSchool', 5);
	SetRoomFeature('SpecialRoomFeature_AlienMachinery', 6);
	SetRoomFeature('SpecialRoomFeature_AlienMachinery', 7);
	SetRoomFeature('SpecialRoomFeature_AlienDebris', 8);
	SetRoomFeature('SpecialRoomFeature_AlienDebris', 9);
	SetRoomFeature('SpecialRoomFeature_PowerCoil', 10);
	SetRoomFeature('SpecialRoomFeature_AlienDebris', 11);
	SetRoomFeature('SpecialRoomFeature_PowerCoil', 12);
	SetRoomFeature('SpecialRoomFeature_AlienMachinery', 13);
	SetRoomFeature('SpecialRoomFeature_AlienDebris', 14);
	

	// Soldiers
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', HealProject)
	{
		HealProject.OnProjectCompleted();
	}

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AllSoldiers = XComHQ.GetSoldiers();
	NumSoldiers = AllSoldiers.Length;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Adjust Soldiers");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	for(idx = 0; idx < NumSoldiers; idx++)
	{
		XComHQ.RemoveFromCrew(AllSoldiers[idx].GetReference());
		NewGameState.RemoveStateObject(AllSoldiers[idx].ObjectID);
	}

	for(idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		XComHQ.Squad[idx] = EmptyRef;
	}

	AllSoldiers.Length = 0;
	CharMgr = `CHARACTERPOOLMGR;

	// Leon Moon - Injured 1
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Leon Moon");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);
	InjuredSoldiers.AddItem(UnitState);

	// Gertrude Jensen - Injured 2
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Gertrude Jensen");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);
	InjuredSoldiers.AddItem(UnitState);

	// Liam Hendricks - Visitor 1
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Liam Hendricks");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);

	// Ji-hoon Kwon - Visitor 2
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Ji-hoon Kwon");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);

	// Angela Belafonte - Personal Trainer
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Angela Belafonte");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);

	// Olga Krumm - Sharpshooter
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Olga Krumm");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);
	XComHQ.Squad[1] = UnitState.GetReference();
	AllSoldiers.AddItem(UnitState);

	// Craig Deerborne - Grenadier
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Craig Deerborne");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);
	XComHQ.Squad[2] = UnitState.GetReference();
	AllSoldiers.AddItem(UnitState);

	// Koll Odinson - Ranger
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Koll Odinson");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);
	XComHQ.Squad[0] = UnitState.GetReference();
	AllSoldiers.AddItem(UnitState);

	// Marlena Ramirez - Specialist
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Marlena Ramirez");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);
	XComHQ.Squad[3] = UnitState.GetReference();
	AllSoldiers.AddItem(UnitState);

	// Yeremey Poltorak - Person Working Out
	UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Soldier', , "Yeremey Poltorak");
	NewGameState.AddStateObject(UnitState);
	UnitState.RandomizeStats();
	UnitState.ApplyInventoryLoadout(NewGameState);
	UnitState.SetHQLocation(eSoldierLoc_Barracks);
	XComHQ.AddToCrew(NewGameState, UnitState);

	SoldierClasses.AddItem('Sharpshooter');
	SoldierClasses.AddItem('Grenadier');
	SoldierClasses.AddItem('Ranger');

	XComHQ.SoldierClassDeck.Length = 0;
	XComHQ.SoldierClassDeck.AddItem('Specialist');
	bSpecialist = false;

	for(idx = 0; idx < AllSoldiers.Length; idx++)
	{
		UnitState = AllSoldiers[idx];

		if(SoldierClasses.Length > 0)
		{
			UnitState.SetXPForRank(3);
			UnitState.StartingRank = 3;
			for(i = 0; i < 3; i++)
			{
				// Rank up to squaddie
				if(i == 0)
				{
					UnitState.RankUpSoldier(NewGameState, SoldierClasses[0]);
					UnitState.ApplySquaddieLoadout(NewGameState);
					for(j = 0; j < UnitState.GetSoldierClassTemplate().GetAbilityTree(0).Length; ++j)
					{
						UnitState.BuySoldierProgressionAbility(NewGameState, 0, j);
					}
				}
				else
				{
					UnitState.RankUpSoldier(NewGameState, UnitState.GetSoldierClassTemplate().DataName);
					UnitState.BuySoldierProgressionAbility(NewGameState, i, 0);
				}
			}

			SoldierClasses.Remove(0, 1);
		}
		else if(!bSpecialist)
		{
			UnitState.SetXPForRank(1);
			UnitState.StartingRank = 1;
			bSpecialist = true;
		}
	}

	for(idx = 0; idx < InjuredSoldiers.Length; idx++)
	{
		UnitState = InjuredSoldiers[idx];

		if(idx == 0)
		{
			UnitState.SetCurrentStat(eStat_HP, 1.0f);
		}
		else
		{
			UnitState.SetCurrentStat(eStat_HP, 5.0f);
		}

		HealProject = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
		NewGameState.AddStateObject(HealProject);

		HealProject.SetProjectFocus(UnitState.GetReference(), NewGameState);

		UnitState.SetStatus(eStatus_Healing);
		XComHQ.Projects.AddItem(HealProject.GetReference());
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Staffing
	GiveEngineer(5, "Andy Sulzbach");
	GiveEngineer(5, "Tommy Penelli");
	GiveScientist(5, "Jacinta Krieger");

	`GAME.GetGeoscape().m_kBase.m_kCrewMgr.RepopulateBaseRoomsWithCrew();
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Clear all weapon upgrades and turn off help popups");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	XComHQ.bHasSeenCustomizationsPopup = true;

	for(idx = 0; idx < XComHQ.Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));

		if(X2WeaponUpgradeTemplate(ItemState.GetMyTemplate()) != none || ItemState.GetMyTemplate().ItemCat == 'combatsim')
		{
			XComHQ.Inventory.Remove(idx, 1);
			idx--;
		}
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	AddItem("ClipSizeUpgrade_Bsc", 1, false);
	AddItem("AimUpgrade_Bsc", 1, false);

	// Research
	GiveTech('ModularWeapons');
	GiveTech('AlienBiotech');
	AddItem("EleriumCore", 2, false);

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if(TechState.GetMyTemplateName() == 'Skulljack')
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Remove Skulljack");
			TechState = XComGameState_Tech(NewGameState.CreateStateObject(class'XComGameState_Tech', TechState.ObjectID));
			NewGameState.AddStateObject(TechState);
			TechState.bBlocked = true;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if(TechState.GetMyTemplateName() == 'AutopsyAdventOfficer')
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Remove Officer Autopsy");
			TechState = XComGameState_Tech(NewGameState.CreateStateObject(class'XComGameState_Tech', TechState.ObjectID));
			NewGameState.AddStateObject(TechState);
			TechState.bBlocked = true;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if(TechState.GetMyTemplateName() == 'ResistanceCommunications')
		{
			XComHQ.SetNewResearchProject(TechState.GetReference());

			// Get the updated project list
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			ResearchProject = XComHQ.GetCurrentResearchProject();
			
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Shorten ResComms Research Time");
			ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectResearch', ResearchProject.ObjectID));
			NewGameState.AddStateObject(ResearchProject);
			ResearchProject.ProjectPointsRemaining *= 0.5;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			
			ResearchProject.ResumeProject();
		}
	}

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if(ObjectiveState.GetMyTemplateName() == 'T1_M1_AutopsyACaptain')
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Remove Officer Autopsy Narratives");
			ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', ObjectiveState.ObjectID));
			NewGameState.AddStateObject(ObjectiveState);
			ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_CaptainAutopsyScreen");
			ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_CaptainAutopsy_Tygan");
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if(ObjectiveState.GetMyTemplateName() == 'T1_M0_FirstMission')
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Remove First Contact Narrative");
			ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', ObjectiveState.ObjectID));
			NewGameState.AddStateObject(ObjectiveState);
			ObjectiveState.AlreadyPlayedNarratives.AddItem("X2NarrativeMoments.Strategy.GP_FirstContact");
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}

	// Geoscape
	DarkEventPopupTime = `STRATEGYRULES.GameTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(DarkEventPopupTime, 264);

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Push Back GOPs spawn time");
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
	CalendarState = XComGameState_MissionCalendar(NewGameState.CreateStateObject(class'XComGameState_MissionCalendar', CalendarState.ObjectID));
	NewGameState.AddStateObject(CalendarState);
	GOPsTime = DarkEventPopupTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(GOPsTime, 24);
	CalendarState.CurrentMissionMonth[0].SpawnDate = GOPsTime;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Set Starting Region to WestEU");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	SkyrangerState = XComGameState_Skyranger(NewGameState.CreateStateObject(class'XComGameState_Skyranger', XComHQ.SkyrangerRef.ObjectID));
	NewGameState.AddStateObject(SkyrangerState);

	foreach History.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		NewGameState.RemoveStateObject(LinkState.ObjectID);
	}

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
		NewGameState.AddStateObject(RegionState);
		RegionState.SetResistanceLevel(NewGameState, eResLevel_Locked);
		RegionState.LinkedRegions.Length = 0;

		if(RegionState.GetReference() == XComHQ.StartingRegion)
		{
			StartingHavenState = XComGameState_Haven(NewGameState.CreateStateObject(class'XComGameState_Haven', RegionState.Haven.ObjectID));
			NewGameState.AddStateObject(StartingHavenState);
		}

		if(RegionState.GetMyTemplateName() == 'WorldRegion_EastAF')
		{
			EastAFRef = RegionState.GetReference();
		}
		else if(RegionState.GetMyTemplateName() == 'WorldRegion_NorthAF')
		{
			NorthAFRef = RegionState.GetReference();
		}
		else if(RegionState.GetMyTemplateName() == 'WorldRegion_WestEU')
		{
			WestEURef = RegionState.GetReference();
		}
		else if(RegionState.GetMyTemplateName() == 'WorldRegion_SouthAF')
		{
			SouthAFRef = RegionState.GetReference();
		}
	}
	
	foreach NewGameState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if(RegionState.GetReference() == EastAFRef)
		{
			HavenState = XComGameState_Haven(NewGameState.CreateStateObject(class'XComGameState_Haven', RegionState.Haven.ObjectID));
			NewGameState.AddStateObject(HavenState);
			HavenState.bNeedsLocationUpdate = false;
			XComHQ.StartingRegion = RegionState.GetReference();
			RegionState.ResistanceLevel = eResLevel_Outpost;
			RegionState.BaseSupplyDrop = XComHQ.GetStartingRegionSupplyDrop();
			RegionState.LinkedRegions.Length = 0;
			RegionState.LinkedRegions.AddItem(WestEURef);
			RegionState.LinkedRegions.AddItem(NorthAFRef);
			XComHQ.Continent = RegionState.Continent;
			XComHQ.TargetEntity = XComHQ.Continent;
			vLoc.X = 0.53f;
			vLoc.Y = 0.35f;
			HavenState.Location = vLoc;
			XComHQ.CurrentLocation = HavenState.GetReference();
			v2Loc.X = vLoc.X - 0.01f;
			v2Loc.Y = vLoc.Y - 0.01f;
			vLoc.X = v2Loc.X;
			vLoc.Y = v2Loc.Y;
			XComHQ.Location = vLoc;
			XComHQ.SourceLocation = v2Loc;
			SkyrangerState.Location = vLoc;
			SkyrangerState.SourceLocation = v2Loc;
			break;
		}
		else if(RegionState.GetReference() == NorthAFRef)
		{
			RegionState.LinkedRegions.Length = 0;
			RegionState.LinkedRegions.AddItem(EastAFRef);
			RegionState.LinkedRegions.AddItem(SouthAFRef);
			RegionState.ResistanceLevel = eResLevel_Unlocked;
			RegionState.SetScanHoursRemaining(4, 4);
		}
		else if(RegionState.GetReference() == WestEURef)
		{
			RegionState.LinkedRegions.Length = 0;
			RegionState.LinkedRegions.AddItem(EastAFRef);
			RegionState.ResistanceLevel = eResLevel_Unlocked;
			RegionState.SetScanHoursRemaining(4, 4);
		}
		else if(RegionState.GetReference() == SouthAFRef)
		{
			RegionState.LinkedRegions.Length = 0;
			RegionState.LinkedRegions.AddItem(NorthAFRef);
		}
	}

	LinkState = XComGameState_RegionLink(NewGameState.CreateStateObject(class'XComGameState_RegionLink'));
	NewGameState.AddStateObject(LinkState);
	LinkState.LinkedRegions.AddItem(EastAFRef);
	LinkState.LinkedRegions.AddItem(NorthAFRef);

	LinkState = XComGameState_RegionLink(NewGameState.CreateStateObject(class'XComGameState_RegionLink'));
	NewGameState.AddStateObject(LinkState);
	LinkState.LinkedRegions.AddItem(EastAFRef);
	LinkState.LinkedRegions.AddItem(WestEURef);

	LinkState = XComGameState_RegionLink(NewGameState.CreateStateObject(class'XComGameState_RegionLink'));
	NewGameState.AddStateObject(LinkState);
	LinkState.LinkedRegions.AddItem(NorthAFRef);
	LinkState.LinkedRegions.AddItem(SouthAFRef);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Other
	HideStrategyObjectives();
	HideTodoWidget();
	
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if(FacilityState.GetMyTemplateName() == 'PowerCore')
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Set Power To 20");
			FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewGameState.AddStateObject(FacilityState);
			FacilityState.PowerOutput = 20;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			break;
		}
	}

	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
}

function DarkEventsPopup()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_DarkEvent DarkEventState;

	DarkEventPopupTime.m_iYear = 9999;
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gamescom Demo: Dark Events");
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	foreach History.IterateByClassType(class'XComGameState_DarkEvent', DarkEventState)
	{
		if(DarkEventState.GetMyTemplateName() == 'DarkEvent_HunterClass' || DarkEventState.GetMyTemplateName() == 'DarkEvent_AlloyPadding')
		{
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);
			DarkEventState.StartActivationTimer();
			AlienHQ.ChosenDarkEvents.AddItem(DarkEventState.GetReference());
		}
		if(DarkEventState.GetMyTemplateName() == 'DarkEvent_ViperRounds')
		{
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);
			DarkEventState.StartActivationTimer();
			DarkEventState.bSecretEvent = true;
			DarkEventState.SetRevealCost();
			AlienHQ.ChosenDarkEvents.AddItem(DarkEventState.GetReference());
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`HQPRES.UIAdventOperations(true);
}

exec function HideStrategyObjectives()
{
	if(`HQPRES != none)
	{
		`HQPRES.m_kAvengerHUD.Objectives.Hide();
	}

	bHideObjectives = true;
}

exec function HideTodoWidget()
{
	if(`HQPRES != none)
	{
		`HQPRES.m_kAvengerHUD.ToDoWidget.Hide();
	}

	bHideTodoWidget = true;
}

exec function SpawnUFO(optional bool bForceAttack = false)
{
	local XComGameState NewGameState;
	local XComGameState_UFO NewUFOState;
		
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Spawn UFO");	
	NewUFOState = XComGameState_UFO(NewGameState.CreateStateObject(class'XComGameState_UFO'));
	NewUFOState.OnCreation(NewGameState, false);
	NewGameState.AddStateObject(NewUFOState);
	
	if(bForceAttack)
	{
		NewUFOState.bDoesInterceptionSucceed = true;
		NewUFOState.InterceptionTime = `STRATEGYRULES.GameTime;
	}
		
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function SpawnPOI(optional bool bShowPopup = true, optional int ScanDays = -1, optional name POITemplate, optional float NewX = -1.0f, optional float NewY = -1.0f)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_PointOfInterest POIState;
	local XComGameState_HeadquartersResistance ResHQ;
	local StateObjectReference POIRef;
	local bool bFound;
	
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Spawn Random POI");
	bFound = false;

	if(POITemplate != '')
	{
		foreach History.IterateByClassType(class'XComGameState_PointOfInterest', POIState)
		{
			if(POIState.GetMyTemplateName() == POITemplate)
			{
				POIState = XComGameState_PointOfInterest(NewGameState.CreateStateObject(class'XComGameState_PointOfInterest', POIState.ObjectID));
				NewGameState.AddStateObject(POIState);
				bFound = true;
				break;
			}
		}
	}
	
	if(!bFound)
	{
		// Choose a random POI to be spawned
		ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
		POIRef = ResHQ.ChoosePOI(NewGameState);
		POIState = XComGameState_PointOfInterest(NewGameState.GetGameStateForObjectID(POIRef.ObjectID));
	}

	POIState.Spawn(NewGameState);	
	POIState.bNeedsAppearedPopup = bShowPopup;

	if (ScanDays > 0)
	{
		POIState.SetScanHoursRemaining(ScanDays, ScanDays);
	}

	if(NewX > 0.0f && NewY > 0.0f)
	{
		POIState.Location.X = NewX;
		POIState.Location.Y = NewY;
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

exec function MakeSoldierAClass(string UnitName, name ClassName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Turn Solier Into Class Cheat");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));
				
		if (UnitState != none && UnitState.GetMyTemplateName() == 'Soldier' && UnitState.GetFullName() == UnitName)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);

			UnitState.ResetSoldierRank(); // Clear their rank
			UnitState.ResetSoldierAbilities(); // Clear their current abilities
			UnitState.RankUpSoldier(NewGameState, ClassName); // The class template name
			UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

exec function MakeSoldierAPsiOp(string UnitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Turn Solier Into Class Cheat");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if (UnitState != none && UnitState.GetMyTemplateName() == 'Soldier' && UnitState.GetFullName() == UnitName)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			
			UnitState.ResetSoldierRank(); // Clear their rank
			UnitState.ResetSoldierAbilities(); // Clear their current abilities
			UnitState.RankUpSoldier(NewGameState, 'PsiOperative'); // Rank up the solder. Will also apply class if they were a Rookie.

			// Teach the soldier the ability which was associated with the project
			UnitState.BuySoldierProgressionAbility(NewGameState, `SYNC_RAND(2), `SYNC_RAND(2));

			if (UnitState.GetRank() == 1) // They were just promoted to Initiate
			{
				UnitState.ApplyBestGearLoadout(NewGameState); // Make sure the squaddie has the best gear available
			}
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

exec function RankUpPsiOp(string UnitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local SCATProgression ProgressAbility;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;
	local int idx, iName;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Turn Solier Into Class Cheat");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if (UnitState != none && UnitState.GetMyTemplateName() == 'Soldier' && UnitState.GetFullName() == UnitName && UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.RankUpSoldier(NewGameState, 'PsiOperative'); // Rank up the solder. Will also apply class if they were a Rookie.
			SoldierClassTemplate = UnitState.GetSoldierClassTemplate();

			// Teach the soldier their next psi ability
			foreach UnitState.PsiAbilities(ProgressAbility)
			{
				AbilityName = SoldierClassTemplate.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);
				if (AbilityName != '' && !UnitState.HasSoldierAbility(AbilityName))
				{
					AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
					if (AbilityTemplate != none)
					{
						// Check to make sure that soldier has any prereq abilites required, and if not then add the prereq ability instead
						if (AbilityTemplate.PrerequisiteAbilities.Length > 0)
						{
							for (iName = 0; iName < AbilityTemplate.PrerequisiteAbilities.Length; iName++)
							{
								AbilityName = AbilityTemplate.PrerequisiteAbilities[iName];
								if (!UnitState.HasSoldierAbility(AbilityName)) // if the soldier does not have the prereq ability, replace it
								{
									AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
									ProgressAbility = SoldierClassTemplate.GetSCATProgressionForAbility(AbilityName);
									break;
								}
							}
						}						
					}

					UnitState.BuySoldierProgressionAbility(NewGameState, ProgressAbility.iRank, ProgressAbility.iBranch);
					break;
				}
			}
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

// Activate a Dark Event
exec function ActivateDarkEvent(name DarkEventName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_DarkEvent DarkEventState;
	local StateObjectReference ActivatedEventRef;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_DarkEvent', DarkEventState)
	{
		if(DarkEventState.GetMyTemplateName() == DarkEventName)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Activate Dark Event");
			AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
			AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
			NewGameState.AddStateObject(AlienHQ);
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);
			ActivatedEventRef = DarkEventState.GetReference();
			DarkEventState.TimesSucceeded++;
			DarkEventState.Weight += DarkEventState.GetMyTemplate().WeightDeltaPerActivate;
			DarkEventState.Weight = Clamp(DarkEventState.Weight, DarkEventState.GetMyTemplate().MinWeight, DarkEventState.GetMyTemplate().MaxWeight);
			DarkEventState.OnActivated(NewGameState);

			if(DarkEventState.GetMyTemplate().MaxDurationDays > 0 || DarkEventState.GetMyTemplate().bLastsUntilNextSupplyDrop)
			{
				AlienHQ.ActiveDarkEvents.AddItem(DarkEventState.GetReference());
				DarkEventState.StartDurationTimer();
			}

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			break;
		}
	}

	if(ActivatedEventRef.ObjectID != 0)
	{
		`GAME.GetGeoscape().Pause();
		`HQPRES.UIDarkEventActivated(ActivatedEventRef);
	}
}

// Give a tech
exec function GiveTech(name TechName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if(TechState.GetMyTemplateName() == TechName)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Give Tech");
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			NewGameState.AddStateObject(XComHQ);
			TechState = XComGameState_Tech(NewGameState.CreateStateObject(class'XComGameState_Tech', TechState.ObjectID));
			NewGameState.AddStateObject(TechState);
			TechState.TimesResearched++;
			XComHQ.TechsResearched.AddItem(TechState.GetReference());
			TechState.bSeenResearchCompleteScreen = true;

			if(TechState.GetMyTemplate().ResearchCompletedFn != none)
			{
				TechState.GetMyTemplate().ResearchCompletedFn(NewGameState, TechState);
			}

			`XEVENTMGR.TriggerEvent('ResearchCompleted', TechState, TechState, NewGameState);

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			break;
		}
	}
}

exec function GiveSoldierUnlock(Name UnlockName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	//update the stored HQ to our current game state after unlocking the training
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: OTS Ability Unlock -" @ UnlockName);

	if( XComHQ.AddSoldierUnlockTemplate(NewGameState, X2SoldierUnlockTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(UnlockName))) )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}


exec function TestShaken()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: TestShaken");
	
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.GetMyTemplateName() == 'Soldier' )
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.bIsShaken = true;
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// Give the continent bonus
exec function GiveContinentBonus(name BonusName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local X2StrategyElementTemplateManager StratMgr;
	local X2GameplayMutatorTemplate Template;
	local StateObjectReference EmptyRef;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Give Continent Bonus");
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	Template = X2GameplayMutatorTemplate(StratMgr.FindStrategyElementTemplate(BonusName));

	if(Template != none && Template.OnActivatedFn != none)
	{
		Template.OnActivatedFn(NewGameState, EmptyRef);
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

// Give the continent bonus
exec function RemoveContinentBonus(name BonusName)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local X2StrategyElementTemplateManager StratMgr;
	local X2GameplayMutatorTemplate Template;
	local StateObjectReference EmptyRef;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Remove Continent Bonus");
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	Template = X2GameplayMutatorTemplate(StratMgr.FindStrategyElementTemplate(BonusName));

	if (Template != none && Template.OnDeactivatedFn != none)
	{
		Template.OnDeactivatedFn(NewGameState, EmptyRef);
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

// Psi Gift for all soldiers in crew
exec function GiveGiftToAll()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Psi Gift for All");

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));
		
		if(UnitState != none && UnitState.GetMyTemplateName() == 'Soldier')
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.bRolledForPsiGift = true;
			//UnitState.bHasPsiGift = true;
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

exec function StartLoseRevealMode()
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local int idx;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	for(idx = 0; idx < AlienHQ.Actions.Length; idx++)
	{
		if(AlienHQ.Actions[idx] == 'AlienAI_StartLoseRevealTimer')
		{
			X2AlienStrategyActionTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().
				FindStrategyElementTemplate(AlienHQ.Actions[idx])).PerformActionFn();
			break;
		}
	}
}

exec function PrintCrew()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local string CrewString;

	History = `XCOMHISTORY;
	
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	CrewString = "\nXCom Crew";

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != none)
		{
			CrewString $= "\n" $ UnitState.GetName(eNameType_Full) @ "ObjectID:" @ UnitState.ObjectID;
		}
	}

	`log(CrewString);
}

exec function ToggleAIEvents() 
{
	bDebugAIEvents = !bDebugAIEvents;
}

exec function GiveFacility(name FacilityName, int MapIndex)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ, NewXComHQState;
	local XComGameState_HeadquartersRoom Room, NewRoomState;
	local XComGameState_FacilityXCom Facility;
	local X2FacilityTemplate FacilityTemplate;
	local XComGameStateHistory History;
	local StateObjectReference FacilityRef;

	History = `XCOMHISTORY;
	

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: GiveFacility");

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	Room = XComHQ.GetRoom(MapIndex);
	
	if(Room != none)
	{
		if(!Room.HasFacility())
		{
			NewRoomState = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
			FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityName));

			if(FacilityTemplate != none)
			{
				Facility = FacilityTemplate.CreateInstanceFromTemplate(NewGameState);
				FacilityRef = Facility.GetReference();
				Facility.Room = NewRoomState.GetReference();
				Facility.ConstructionDateTime = `STRATEGYRULES.GameTime;
				NewRoomState.Facility = Facility.GetReference();
				NewRoomState.ConstructionBlocked = false;
				NewRoomState.SpecialFeature = '';

				NewXComHQState = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				NewXComHQState.Facilities.AddItem(FacilityRef);

				NewGameState.AddStateObject(NewRoomState);
				NewGameState.AddStateObject(Facility);
				NewGameState.AddStateObject(NewXComHQState);

				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

				`GAME.GetGeoscape().m_kBase.RemoveRoom(MapIndex);
				`GAME.GetGeoscape().m_kBase.StreamInRoom(MapIndex, true);

				class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();

				if(FacilityTemplate.OnFacilityBuiltFn != none)
				{
					FacilityTemplate.OnFacilityBuiltFn(FacilityRef);
				}
			}
		}
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

exec function SetRoomFeature(name FeatureName, int MapIndex)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Room = XComHQ.GetRoom(MapIndex);

	if(Room != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: SetRoomFeature");
		Room = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
		NewGameState.AddStateObject(Room);
		Room.SpecialFeature = FeatureName;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`GAME.GetGeoscape().m_kBase.RemoveRoom(MapIndex);
		`GAME.GetGeoscape().m_kBase.StreamInRoom(MapIndex, true);
	}
}

exec function GiveFacilityUpgrade(name UpgradeName, optional name FacilityName = '')
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState, NewFacilityState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local int iFacility, iUpgrade;
	local bool bFoundFacility;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(FacilityName == '')
	{
		bFoundFacility = false;

		for(iFacility = 0; iFacility < XComHQ.Facilities.Length; iFacility++)
		{
			FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Facilities[iFacility].ObjectID));

			if(FacilityState != none)
			{
				for(iUpgrade = 0; iUpgrade < FacilityState.GetMyTemplate().Upgrades.Length; iUpgrade++)
				{
					if(UpgradeName == FacilityState.GetMyTemplate().Upgrades[iUpgrade])
					{
						bFoundFacility = true;
						break;
					}
				}
			}

			if(bFoundFacility)
			{
				break;
			}
		}

		if(!bFoundFacility)
		{
			return;
		}
	}
	else
	{
		FacilityState = XComHQ.GetFacilityByName(FacilityName);
	}

	if(FacilityState != none)
	{
		UpgradeTemplate = X2FacilityUpgradeTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(UpgradeName));

		if(UpgradeTemplate != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: GiveFacilityUpgrade");

			UpgradeState = UpgradeTemplate.CreateInstanceFromTemplate(NewGameState);
			NewGameState.AddStateObject(UpgradeState);

			NewFacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewGameState.AddStateObject(NewFacilityState);
			NewFacilityState.Upgrades.AddItem(UpgradeState.GetReference());

			UpgradeState.Facility = FacilityState.GetReference();
			UpgradeState.OnUpgradeAdded(NewGameState, NewFacilityState);		
			
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

exec function SetMonth( int iMonth )
{

	//class'X2StrategyGameRulesetDataStructures'.static.SetTime(GEOSCAPE().m_kDateTime, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.static.GetMonth(AI().m_kStartDate), 1, class'X2StrategyGameRulesetDataStructures'.static.GetYear(AI().m_kStartDate) );
	//
	//while(iMonth > 1) // keep it one indexed, so 1 is the first month of the game, etc
	//{
	//	class'X2StrategyGameRulesetDataStructures'.static.AddMonth(GEOSCAPE().m_kDateTime);
	//	iMonth--;
	//}
}

exec function BaseRoomCameraNamed( name RoomName, float fInterpTime )
{
	XComHeadquartersCamera(PlayerCamera).StartRoomViewNamed( RoomName, fInterpTime );
}

exec function BaseRoomList()
{
	local array<XComHQ_RoomLocation> Rooms;
	local XComHQ_RoomLocation Room;

	foreach WorldInfo.AllActors( class'XComHQ_RoomLocation', Room )
	{
		Rooms[Rooms.Length] = Room;
	}

	`log( "XComHeadquarters rooms list count: " $ Rooms.Length );

	foreach Rooms(Room)
	{
		`log( "  " $ Room.RoomName );
	}
}

exec function CameraZoom( float Zoom )
{
	XComHeadquartersCamera(PlayerCamera).SetZoom( Zoom );
}

exec function GiveResource(string resourceType, int amount)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: AddResource");
	if(name(resourceType) == 'Doom')
	{
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		NewGameState.AddStateObject(AlienHQ);
		AlienHQ.ModifyDoom(amount);
		`HQPRES.StrategyMap2D.StrategyMapHUD.SetDoomMessage("Cheat Doom", (amount < 0));
	}
	else
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.AddResource(NewGameState, name(resourceType), amount);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function GiveMeTonsOfResources(int amount = 9999)
{
	GiveResource("Money", amount);
	GiveResource("Elerium", amount);
	GiveResource("Alloys", amount);
	GiveResource("Engineers", amount);
	GiveResource("Scientists", amount);
	GiveResource("Power", amount);
}


exec function DoPostInterrogation()
{
	local XGNarrative kNarr;
	
	if (Outer.Pres.m_kNarrative == none)
	{
		kNarr = spawn(class'XGNarrative');
		kNarr.InitNarrative();
		Outer.Pres.SetNarrativeMgr(kNarr);
	}

	//Outer.Pres.UINarrative(XComNarrativeMoment'NarrativeMoment.PostInterrogation', none,,,`HQ.m_kBase.GetFacility3DLocation(eFacility_AlienContain));
}


exec function TestItemCard()
{
	`HQGAME.GetItemCard();
}

exec function DebugAnims( optional bool bEnable = true, optional bool bEnableDisplay = false, optional Name pawnName = '' )
{
	bDebugAnims = bEnable;              // Enables animation logging to internal memory buffer.
	bDebugAnimsPawn = bEnable;

	bDisplayAnims = bEnableDisplay;      // Displays logged animations to screen.

	if( pawnName == 'all' )
	{
		pawnName = '';
	}

	m_DebugAnims_TargetName = pawnName;   // Debugs ONE unit only. Will write to screen && std-out.
}

exec function BuildOutpost( string strContinent )
{
}

exec function AIInfiltrate( string strCountry )
{
	
}

exec function AIBuildBase( string strContinent )
{
	
}

exec function AIRetaliate()
{
	
}

exec function AIRetaliateInstant()
{
	
}

exec function ToggleGlobe()
{
	bDoGlobeView = !bDoGlobeView;
}

exec function OutputGlobeCoord()
{
/*`if (`notdefined(FINAL_RELEASE))
	local vector2d vloc;

	vloc = `EARTH.ToEarthCoords( PlayerCamera.CameraCache.POV.Location );

	`log("GlobeCoord: " $vloc.x $","$vloc.y);
`endif*/
}


function XGGeoscape GEOSCAPE()
{
	return XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGamecore().GetGeoscape();
}
function XComHQPresentationLayer PRES()
{
	return `HQPRES;
}

exec function FacilityStressTest()
{

}

exec function HQFreeCam()
{
	bFreeCam = !bFreeCam;
	`log("FreeCam is now " $ bFreeCam);
}

exec function ForceAlienType_Sectoid()          {	ForceAlienType( 'Sectoid' );                }
exec function ForceAlienType_SectoidCommander() {	ForceAlienType( 'SectoidCommander' );	    }
exec function ForceAlienType_Floater()     		{   ForceAlienType( 'Floater' );                }
exec function ForceAlienType_HeavyFloater()		{   ForceAlienType( 'FloaterHeavy' );          }
exec function ForceAlienType_Muton()       		{   ForceAlienType( 'Muton' );                  }
exec function ForceAlienType_MutonElite()  		{   ForceAlienType( 'MutonElite' );            }
exec function ForceAlienType_MutonBerserker()   {   ForceAlienType( 'MutonBerserker' );        }
exec function ForceAlienType_ThinMan()     		{   ForceAlienType( 'Thinman' );                }
exec function ForceAlienType_Elder()       		{   ForceAlienType( 'Ethereal' );                  }
exec function ForceAlienType_EtherealUber()     {   ForceAlienType( 'EtherealUber' );           }
exec function ForceAlienType_Cyberdisc()   		{   ForceAlienType( 'Cyberdisc' );              }
exec function ForceAlienType_Chryssalid()  		{   ForceAlienType( 'Chryssalid' );             }
exec function ForceAlienType_Sectopod()    		{   ForceAlienType( 'Sectopod' );               }
exec function ForceAlienType_Drone()    		{   ForceAlienType( 'Drone' );                  }
exec function ForceAlienType_Zombie()       	{   ForceAlienType( 'Zombie' );					}
exec function ForceAlienType_Outsider()       	{   ForceAlienType( 'Outsider' );				}
exec function ForceAlienType_Mechtoid()       	{   ForceAlienType( 'Mechtoid' );				}
exec function ForceAlienType_MechtoidAlt()      {   ForceAlienType( 'Mechtoid_Alt' );			}
exec function ForceAlienType_Seeker()           {   ForceAlienType( 'Seeker' );			}
exec function ForceAlienType_ExaltOperative()	{   ForceAlienType( 'ExaltOperative' );			}
exec function ForceAlienType_ExaltSniper()	    {   ForceAlienType( 'ExaltSniper' );			}
exec function ForceAlienType_ExaltHeavy()	    {   ForceAlienType( 'ExaltHeavy' );			}
exec function ForceAlienType_ExaltMedic()	    {   ForceAlienType( 'ExaltMedic' );			}
exec function ForceAlienType_ExaltEliteOperative()	{   ForceAlienType( 'ExaltEliteOperative' );			}
exec function ForceAlienType_ExaltEliteSniper()	    {   ForceAlienType( 'ExaltEliteSniper' );			}
exec function ForceAlienType_ExaltEliteHeavy()	    {   ForceAlienType( 'ExaltEliteHeavy' );			}
exec function ForceAlienType_ExaltEliteMedic()	    {   ForceAlienType( 'ExaltEliteMedic' );			}
exec function ForceAlienType_None()             {   ForceAlienType(); }
function ForceAlienType( name _ForceAlienTemplateName='' )
{
	ForceAlienTemplateName=_ForceAlienTemplateName;
}


exec function DumpEventJournal()
{
	
}

exec function AllowDeluge()
{
	bAllowDeluge = true;
}

exec function SilenceNewbieMoments()
{
	//Outer.Pres.m_kNarrative.m_bSilenceNewbieMoments = true;
	//Outer.Pres.m_kNarrative.DoSilenceNewbieMoments();
}

exec function LaunchTacticalMission(optional int NumSoldiers = 4)
{
	local XGStrategy StrategyActor;

	foreach WorldInfo.AllActors(class'XGStrategy', StrategyActor)
	{
		break;
	}

	StrategyActor.LaunchTacticalBattle();
}

exec function SpawnMissionOnMap(string rewardType, int amount)
{
	//local X2RewardTemplate RewardTemplate;
	//local XComGameState_Reward RewardState;
	//local array<XComGameState_Reward> MissionRewards;
	//local XComGameState NewGameState;
	//local XComGameState_MissionSite Mission;
	//local XComGameStateHistory History;
	//local XComGameState_HeadquartersXCom XComHQ;
	//local XComGameState_WorldRegion WorldRegionState;
	//
	//History = `XCOMHISTORY;
	//
	//NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Cheat Mission");
	//
	//RewardTemplate = X2RewardTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(name(rewardType)));
	//
	//if(RewardTemplate == none)
	//{
	//	History.CleanupPendingGameState(NewGameState);
	//	`log("Could not find mission of reward type:"@ rewardType);
	//	return;
	//}
	//
	//RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	//RewardState.GenerateReward(NewGameState);
	//RewardState.Quantity = amount;
	//NewGameState.AddStateObject(RewardState);
	//MissionRewards.AddItem(RewardState);
	//
	//XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	//WorldRegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(XComHQ.LandingRegion.ObjectID));
	//
	//Mission = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite'));
	//Mission.BuildMission("Cheat", WorldRegionState.GetRandom2DLocationInRegion(), WorldRegionState.GetReference(), MissionRewards, true);
	//NewGameState.AddStateObject(Mission);
	//`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function SetCurvature(float fAmt)
{
	`EARTH.SetCurvature(fAmt);
}

exec function SetPitch(float fAmt)
{
	`EARTH.SetPitch(fAmt);
}

exec function HQInventory()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom HQState;
	local XComGameState_Item InvItem;
	local int i;

	History = `XCOMHISTORY;
	HQState = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	`assert(HQState != none);

	`log("=== HQ Inventory ===");
	for (i = 0; i < HQState.Inventory.Length; ++i)
	{
		InvItem = XComGameState_Item(History.GetGameStateForObjectID(HQState.Inventory[i].ObjectID));
		`log(string(InvItem.Quantity) @ InvItem.GetMyTemplate().GetItemFriendlyName());
	}
	`log("=== end inventory (" $ HQState.Inventory.Length @ "items) ===");
}

exec function AddItem(string strItemTemplate, optional int Quantity = 1, optional bool bLoot = false)
{
	local X2ItemTemplateManager ItemManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState NewGameState;
	local XComGameState_Item ItemState;
	local XComGameState_HeadquartersXCom HQState;
	local XComGameStateHistory History;

	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemManager.FindItemTemplate(name(strItemTemplate));
	if (ItemTemplate == none)
	{
		`log("No item template named" @ strItemTemplate @ "was found.");
		return;
	}
	History = `XCOMHISTORY;
	HQState = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	`assert(HQState != none);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Item Cheat: Create Item");
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);
	ItemState.Quantity = Quantity;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Item Cheat: Complete");
	HQState = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(HQState.Class, HQState.ObjectID));
	HQState.AddItemToHQInventory(ItemState);
	NewGameState.AddStateObject(HQState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("Added item" @ strItemTemplate @ "object id" @ ItemState.ObjectID);
}

// Level up all soldiers
exec function LevelUpBarracks(optional int Ranks = 1)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx, i, RankUps, NewRank;
	local name SoldierClassName;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rankup Soliers Cheat");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != none && UnitState.IsSoldier() && UnitState.GetRank() < (class'X2ExperienceConfig'.static.GetMaxRank() - 1))
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			NewRank = UnitState.GetRank() + Ranks;

			if(NewRank >= class'X2ExperienceConfig'.static.GetMaxRank())
			{
				NewRank = (class'X2ExperienceConfig'.static.GetMaxRank());
			}

			RankUps = NewRank - UnitState.GetRank();

			for(i = 0; i < RankUps; i++)
			{
				SoldierClassName = '';
				if(UnitState.GetRank() == 0)
				{
					SoldierClassName = XComHQ.SelectNextSoldierClass();
				}

				UnitState.RankUpSoldier(NewGameState, SoldierClassName);

				if(UnitState.GetRank() == 1)
				{
					UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
					UnitState.ApplyBestGearLoadout(NewGameState); // Make sure the squaddie has the best gear available
				}
			}

			UnitState.StartingRank = NewRank;
			UnitState.SetXPForRank(NewRank);
		}
	}

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

// Level up all non-soldiers
exec function LevelUpCrew(optional int Levels = 1)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rankup Soliers Cheat");

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() != 'Soldier')
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.SetSkillLevel(UnitState.GetSkillLevel() + Levels);
		}
	}

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

exec function GiveScientist(optional int SkillLevel = 5, optional string UnitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local CharacterPoolManager CharMgr;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Give Scientist Cheat");

	CharMgr = `CHARACTERPOOLMGR;

	if(UnitName != "")
	{
		UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Scientist', , UnitName);
	}
	else
	{
		UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_Mixed, 'Scientist');
	}
	
	UnitState.SetSkillLevel(SkillLevel);
	NewGameState.AddStateObject(UnitState);

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.AddToCrew(NewGameState, UnitState);
	XComHQ.HandlePowerOrStaffingChange(NewGameState);

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	`HQPRES.UINewStaffAvailable(UnitState.GetReference());
}

exec function GiveEngineer(optional int SkillLevel = 5, optional string UnitName)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local CharacterPoolManager CharMgr;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Give Engineer Cheat");

	CharMgr = `CHARACTERPOOLMGR;

	if(UnitName != "")
	{
		UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_PoolOnly, 'Engineer', , UnitName);
	}
	else
	{
		UnitState = CharMgr.CreateCharacter(NewGameState, eCPSM_Mixed, 'Engineer');
	}

	UnitState.SetSkillLevel(SkillLevel);
	NewGameState.AddStateObject(UnitState);

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.AddToCrew(NewGameState, UnitState);
	XComHQ.HandlePowerOrStaffingChange(NewGameState);

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	`HQPRES.UINewStaffAvailable(UnitState.GetReference());
}

exec function SetForceLevel(int ForceLevel)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHEAT: Set Force Level");

	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.ForceLevel = ForceLevel;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

exec function ShowForceLevel()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	OutputMsg("Force Level:" @ string(AlienHQ.GetForceLevel()));
}

function FillHeadTexture()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local int i;
	local StateObjectReference ObjRef;
	local X2ImageCaptureManager ImageCaptureManager;
	local Texture2D HeadTexture;
	
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ImageCaptureManager = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());

	for( i = 0; i < XComHQ.Crew.Length; i++ )
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		ObjRef = Unit.GetReference();
		HeadTexture = ImageCaptureManager.GetStoredImage(ObjRef, name("SoldierPictureWanted"$ObjRef.ObjectID));
		if( i < `XENGINE.HeadsTexture.NumTextures && HeadTexture != none )
		{
			`XENGINE.HeadsTexture.SetTexture(i, HeadTexture);
		}
	}
	`XENGINE.HeadsTexture.UpdateResourceScript();
	OutputMsg("Captured heads");
}

function OnSoldierHeadCaptureFinished(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local Texture2D SoldierPicture;
	local X2ImageCaptureManager ImageCaptureManager;

	ImageCaptureManager = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	
	SoldierPicture = RenderTarget.ConstructTexture2DScript(ImageCaptureManager, "SoldierPictureWanted"$ReqInfo.UnitRef.ObjectID, false, false, true);
	ImageCaptureManager.StoreImage(ReqInfo.UnitRef, SoldierPicture, name("SoldierPictureWanted"$ReqInfo.UnitRef.ObjectID));
	numHeadshots--;
	if( numHeadshots == 0 )
	{
		FillHeadTexture();
	}
}

exec function CaptureSoldiersHeads()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StateObjectReference> m_arrSoldiers;
	local int i;
	local XComGameState_Unit Unit;
	local X2ImageCaptureManager ImageCaptureManager;
	local StateObjectReference ObjRef;
	local bool bHasImage;
	local bool bWaitOnRender;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ImageCaptureManager = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());

	bWaitOnRender = false;

	for( i = 0; i < XComHQ.Crew.Length; i++ )
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		ObjRef = Unit.GetReference();
		bHasImage = ImageCaptureManager.HasStoredImage(ObjRef, name("SoldierPictureWanted"$ObjRef.ObjectID));
		if( Unit.IsAlive() && !bHasImage )
		{
			if( Unit.GetMyTemplateName() == 'Soldier' )
			{
				m_arrSoldiers.AddItem(ObjRef);
				numHeadshots++;
				`GAME.StrategyPhotographer.AddHeadshotRequest(m_arrSoldiers[i], 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Head_Armory', 256, 256, OnSoldierHeadCaptureFinished);
				bWaitOnRender = true;
			}
		}
	}

	if( !bWaitOnRender )
	{
		FillHeadTexture();
	}
}

exec function DV1()
{
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_a');
}

exec function DV2()
{
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_Hallway');
}

exec function DV3()
{
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_b');
}

function OnVolunteerMatineeIsVisible(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	//`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_a');
	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_Hallway');
	//`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.GP_DarkVolunteerPT2_b');
}

exec function DV123()
{
	`MAPS.AddStreamingMap("CIN_TP_Dark_Volunteer_pt2_Hallway_Narr", vect(0, 0, 0), Rot(0, 0, 0), true, false, true, OnVolunteerMatineeIsVisible);
}



DefaultProperties
{
	bDoGlobeView=true
	bDebugAIEvents=false
}
