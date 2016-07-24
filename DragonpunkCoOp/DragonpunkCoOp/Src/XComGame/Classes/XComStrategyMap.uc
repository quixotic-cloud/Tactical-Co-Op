//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComStrategyMap
//  AUTHOR:  Sam Batista -- 08/2014
//  PURPOSE: This file controls strategy map logic.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComStrategyMap extends Actor
	config(GameData);

var config float fZoom_1;
var config float fZoom_2;
var config float fZoom_3;
var config float fZoom_combat;

var int           UIMapZoom;

var private StateObjectReference RecruitReference;

// TODO - figure out what to display with these
var localized string m_strMissionDifficulty;
var localized string m_strMissionFlightTime;
//var localized string m_strMissionRewards;
var localized string m_strMissionAccept;
//var localized string m_strMissionCancel;
var localized string m_strResearchComplete; 

var array<string> m_arrSoldiersKilledOnMission;
var array<string> m_arrSoldiersWoundedOnMission;
// END TODO

var privatewrite UIStrategyMap UIMap;

simulated function EnterStrategyMap()
{
	UIMap = `HQPRES.StrategyMap2D;
	UIMap.AddOnRemovedDelegate(ClearUIMapRef);

	//Give the geoscape a little time to process before we update the game board ( which may trigger pop-ups )
	SetTimer(0.33f, false, nameof(UpdateStrategyMap));
}

simulated function ClearUIMapRef(UIPanel Control)
{
	UIMap.ClearOnRemovedDelegate(ClearUIMapRef);
	UIMap = none; 
}

simulated function ExitStrategyMap()
{
	OnLoseFocus();
}

simulated function UpdateStrategyMap()
{
	UpdateGameBoard();
}

// Focus functions are triggered by the UI when the state stack is modified -sbatista
simulated function OnLoseFocus()
{
	`GAME.GetGeoscape().Pause();
}

simulated function OnReceiveFocus()
{
	`GAME.GetGeoscape().Resume();
	`HQPRES.GetCamera().ForceEarthViewImmediately(false);
}

////----------------------------------------------------------------
////----------------------------------------------------------------
//simulated public function ResistanceOpsAppearedPopup()
//{
//	local TDialogueBoxData DialogData;
//	//local XComGameStateHistory History;
//	local XComGameState NewGameState;
//	local XComGameState_MissionSite kMission;
//	local XComGameState_HeadquartersResistance ResistanceHQ;
//	//local XComGameState_HeadquartersXCom XComHQ;
//	//local XComGameState_Skyranger Skyranger;
//	//local int ProjectedFlightTime;
//
//	//History = `XCOMHISTORY;
//	//XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
//	//Skyranger = XComGameState_Skyranger(History.GetGameStateForObjectID(XComHQ.SkyrangerRef.ObjectID));
//	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
//
//	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Resistance Ops Popup Handling");
//	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
//	NewGameState.AddStateObject(ResistanceHQ);
//	ResistanceHQ.bResistanceOpsNotify = false;
//	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
//
//	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
//
//	`GAME.GetGeoscape().Pause();
//
//	DialogData.eType = eDialog_Normal;
//	DialogData.strTitle = "RESISTANCE OPS";
//	DialogData.strText = "\nCommander, we've identified several opportunities for direct action against the aliens. Each will have its own risks and potential benefits; the decision is yours.\n\nWe have leads on the following assets:\n";
//	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_MissionSite', kMission)
//	{
//		if((ResistanceHQ.IsResistanceOp(kMission)))
//		{
//			DialogData.strText $= kMission.GetMissionTypeString();
//			//DialogData.strText $= class'UIUtilities_Text'.static.GetColoredText(kMission.GetWorldRegion().GetMyTemplate().strDisplayName $ "   ", eUiState_Cash);
//			//ProjectedFlightTime = Skyranger.GetFlightTime(Skyranger.Get2DLocation(), kMission.Get2DLocation()) / 60;
//			//DialogData.strText $= class'UIUtilities_Text'.static.GetColoredText(m_strMissionFlightTime $": " $ ProjectedFlightTime @"minutes", eUIState_Highlight);
//			DialogData.strText $= "\n";
//		}
//	}
//
//	DialogData.strText $= "\nChoose carefully: ADVENT will move fast to eliminate their security breaches, so we'll only be able to undertake one of these missions.";
//	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
//	DialogData.fnCallback  = ResistanceOpsAppearedCallback;
//
//	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_NewResistOpsMissions");
//	`HQPRES.UIRaiseDialog( DialogData );
//}
//
//simulated private function ResistanceOpsAppearedCallback(eUIAction eAction)
//{
//	`GAME.GetGeoscape().Resume();
//
//	if(`GAME.GetGeoscape().IsScanning())
//		UIMap.ToggleScan();
//}




//simulated function UpdateUFOFlyovers(float fDeltaT)
//{
//	local XComGameStateHistory History;
//	local XComGameState_WorldRegion RegionState;
//	local UIStrategyMapItem MapItem; 
//	local Vector2D TmpVector;
//
//	UFOFlyoverTimer += fDeltaT;
//	History = `XCOMHISTORY;
//
//		foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
//	{
//		if((!IsZoomedIn() || (RegionState.IsAvengerRegion() && IsZoomedIn())) && RegionState.bHasUFO)
//		{
//			if(IsZoomedIn())
//			{
//				UFOFlyoverInterval = (4.0 - float(RegionState.UFOChance/4));
//
//				if(UFOFlyoverInterval <= 0)
//				{
//					UFOFlyoverInterval = 0.5;
//				}
//			}
//			else
//			{
//				UFOFlyoverInterval = 4.0;
//			}
//
//			if(UFOFlyoverTimer >= UFOFlyoverInterval)
//			{
//				UFOFlyoverTimer = 0;
//				MapItem = UIMap.GetMapItem(name("UFO_Flyover_" $ UFOFlyoverCounter), MI_flyover);
//				UFOFlyoverCounter++;
//				if(`HQPRES.IsOnscreen(`EARTH.ConvertEarthToWorld(RegionState.GetRandom2DLocationInRegion()), TmpVector))
//				{
//					MapItem.SetNormalizedPosition(TmpVector);
//					MapItem.SetLabel(class'UIUtilities_Text'.static.GetColoredText("UFO HUNTING", eUIState_Bad));
//					MapItem.Show();
//				}
//				else
//					MapItem.Hide();
//
//				MapItem.SetExpiration(3);
//			}
//		}
//	}
//}
//

//----------------------------------------------------------------
//----------------------------------------------------------------
//----- Strategy Refactor ----------------------------------------
//----------------------------------------------------------------
//----------------------------------------------------------------

// Entry point for ticking Geoscape Entities which need to poll for time-based events
simulated function UpdateGameBoard()
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity Entity;
	local array<XComGameState_GeoscapeEntity> AllEntities;
	local int EntityIndex;

	History = `XCOMHISTORY;

	// Skip updates while an interaction is in progress
	if (!InteractionInProgress())
	{
		// TODO: there may be something screwy with this iterator not being able to safely handle additions/removals 
		// mid-iteration
		foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', Entity)
		{
			AllEntities.AddItem(Entity);
		}

		for (EntityIndex = 0; EntityIndex < AllEntities.Length; ++EntityIndex)
		{
			Entity = AllEntities[EntityIndex];
			// Check again for interactions b/c movie or popup may have triggered
			if (Entity != None && !InteractionInProgress())
			{
				Entity.UpdateGameBoard();
			}
		}
	}
}

function bool InteractionInProgress()
{
	local XGGeoscape Geoscape;
	local XComGameState StartState;

	Geoscape = `GAME.GetGeoscape();
	StartState = `XCOMHISTORY.GetStartState();
	return (Geoscape == none || Geoscape.IsPaused() || StartState != none);
}

// #######################################################################
// Geoscape update any moving objects (avenger, skyranger, UFOs?)
// #######################################################################
simulated function UpdateMovers(float fDeltaT)
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity Entity;
	local array<XComGameState_GeoscapeEntity> AllEntities;
	local int EntityIndex;

	History = `XCOMHISTORY;

		// Skip updates while an interaction is in progress
	if (!InteractionInProgress())
	{
		// TODO: there may be something screwy with this iterator not being able to safely handle additions/removals 
		// mid-iteration
		foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', Entity)
		{
			AllEntities.AddItem(Entity);
		}

		for (EntityIndex = 0; EntityIndex < AllEntities.Length; ++EntityIndex)
		{
			Entity = AllEntities[EntityIndex];
			// Check again for interactions b/c movie or popup may have triggered
			if (Entity != None && !InteractionInProgress())
			{
				Entity.UpdateMovement(fDeltaT);
				Entity.UpdateRotation(fDeltaT);
			}
		}
	}
}

// #######################################################################
// Geoscape visuals
// #######################################################################
simulated function UpdateVisuals()
{
	local XComGameState_GeoscapeEntity Entity;
	local UIStrategyMapItem MapItem;

	if (UIMap != None) //only update visuals when the map is actually being displayed
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_GeoscapeEntity', Entity)
		{
			MapItem = UIMap.GetMapItem(Entity);

			if (MapItem != none)
			{
				MapItem.UpdateVisuals();
			}
		}
		// Flush the UI command queue so positioning of UI elements is updated immediately
		UIMap.Movie.ProcessQueuedCommands();
	}
}

//----------------------------------------------------------------

defaultproperties
{
}
