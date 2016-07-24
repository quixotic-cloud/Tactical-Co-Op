//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_TacticalGameRule.uc
//  AUTHOR:  Ryan McFall  --  11/21/2013
//  PURPOSE: XComGameStateContexts for game rule state changes in the tactical game. Examples
//           of this sort of state change are: Units added, changes in turn phase, etc.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_TacticalGameRule extends XComGameStateContext native(Core);

enum GameRuleStateChange
{
	eGameRule_TacticalGameStart,
	eGameRule_RulesEngineStateChange,   //Called when the turn changes over to a new phase. See X2TacticalGameRuleset and its states.
	eGameRule_UnitAdded,
	eGameRule_UnitChangedTeams,
	eGameRule_ReplaySync,               //This informs the system sync all visualizers to an arbitrary state
	eGameRule_SkipTurn,
	eGameRule_SkipUnit,
	eGameRule_PlayerTurnBegin,
	eGameRule_PlayerTurnEnd,
	eGameRule_TacticalGameEnd,
	eGameRule_DemoStart,
	eGameRule_ClaimCover,
	eGameRule_UpdateAIPlayerData,
	eGameRule_UpdateAIRemoveAlertTile,
	eGameRule_UNUSED_1,
	eGameRule_UNUSED_2,
	eGameRule_UNUSED_3,
	eGameRule_MarkCorpseSeen,
	eGameRule_UseActionPoint,
	eGameRule_AIRevealWait,				// On AI patrol unit's move, Patroller is alerted to an XCom unit.   Waits for other group members to catch up before reveal.
	eGameRule_UNUSED_4,
	eGameRule_UNUSED_5,
	eGameRule_ForceSyncVisualizers,
};

var GameRuleStateChange     GameRuleType;
var StateObjectReference    PlayerRef;      //Player associated with this game rule state change, if any
var StateObjectReference    UnitRef;		//Unit associated with this game rule state change, if any
var StateObjectReference    AIRef;			//AI associated with this game rule state chance, if any
var name RuleEngineNextState;               //The name of the new state that the rules engine is entering. Can be used for error checking or actually implementing GotoState

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
	local XComGameState_Unit UnitState;
	local XComGameState_Unit UpdatedUnitState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_AIPlayerData AIState, UpdatedAIState;
	local XComGameState_AIUnitData AIUnitState;
	local bool bHadActionPoints;
	local int iComponentID;
	//local bool bClaimCoverAnyChanges;		//True if the claim cover game state contains meaningful changes
	local XComGameState_Player CurrentPlayer;

	History = `XCOMHISTORY;
	NewGameState = none;
	switch(GameRuleType)
	{
	case eGameRule_SkipTurn : 
		`assert(PlayerRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);
		//Clear all action points for this player's units
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.ControllingPlayer.ObjectID == PlayerRef.ObjectID )
			{					
				UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				UpdatedUnitState.SkippedActionPoints = UpdatedUnitState.ActionPoints;
				UpdatedUnitState.ActionPoints.Length = 0;
				NewGameState.AddStateObject(UpdatedUnitState);
			}
		}
		break;
	case eGameRule_SkipUnit : 
		`assert(UnitRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);		
		UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		bHadActionPoints = UpdatedUnitState.ActionPoints.Length > 0;
		UpdatedUnitState.ActionPoints.Length = 0;//Clear all action points for this unit
		if( bHadActionPoints )
		{
			`XEVENTMGR.TriggerEvent('ExhaustedActionPoints', UpdatedUnitState, UpdatedUnitState, NewGameState);
		}
		else
		{
			`XEVENTMGR.TriggerEvent('NoActionPointsAvailable', UpdatedUnitState, UpdatedUnitState, NewGameState);
		}

		NewGameState.AddStateObject(UpdatedUnitState);
		foreach UpdatedUnitState.ComponentObjectIds(iComponentID)
		{
			if (History.GetGameStateForObjectID(iComponentID).IsA('XComGameState_Unit'))
			{
				UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', iComponentID));
				if (UpdatedUnitState != None)
				{
					UpdatedUnitState.ActionPoints.Length = 0;//Clear all action points for this unit
					NewGameState.AddStateObject(UpdatedUnitState);
				}
			}
		}
		break;
	case eGameRule_UseActionPoint:
		`assert(UnitRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);		
		UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		if (UpdatedUnitState.ActionPoints.Length > 0)
			UpdatedUnitState.ActionPoints.Remove(0, 1);
		NewGameState.AddStateObject(UpdatedUnitState);
		break;

	case eGameRule_ClaimCover:
		//  jbouscher: new reflex system does not want to do this
		//NewGameState = History.CreateNewGameState(true, self);		
		//
		//UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitRef.ObjectID));		
		//NewGameState.AddStateObject(UpdatedUnitState);
		//		
		//if( UpdatedUnitState.GetTeam() == eTeam_XCom )
		//{
		//	//This game state rule is used as an end cap for movement, so it is here that we manipulate the
		//	//reflex triggering state for AI units. Red-alert units need to have their reflex trigger flag cleared
		//	//but this needs to happen after any X-Com moves are complete
		//	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		//	{
		//		if( UnitState.GetCurrentStat(eStat_AlertLevel) > 1 && UnitState.bTriggersReflex )
		//		{				
		//			bClaimCoverAnyChanges = true;
		//			UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		//			UpdatedUnitState.bTriggersReflex = false;
		//			NewGameState.AddStateObject(UpdatedUnitState);
		//		}
		//	}
		//}
		//
		//if( !bClaimCoverAnyChanges )
		//{
		//	History.CleanupPendingGameState(NewGameState);
		//	NewGameState = none;
		//}
		break;
	case eGameRule_UpdateAIPlayerData:
		`assert(PlayerRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);
		foreach History.IterateByClassType(class'XComGameState_AIPlayerData', AIState)
		{
			if ( AIState.m_iPlayerObjectID == PlayerRef.ObjectID )
			{
				UpdatedAIState = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', AIState.ObjectID));
				UpdatedAIState.UpdateData(PlayerRef.ObjectID);
				NewGameState.AddStateObject(UpdatedAIState);
				break;
			}
		}
	break;
	case eGameRule_UpdateAIRemoveAlertTile:
		// deprecated game rule
		`RedScreen("Called deprecated game rule:eGameRule_UpdateAIRemoveAlertTile. This should not happen.");
		//`assert(AIRef.ObjectID > 0);
		//NewGameState = History.CreateNewGameState(true, self);
		//AIUnitState = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', AIRef.ObjectID));
		//if (AIUnitState.m_arrAlertTiles.Length > 0)
		//	AIUnitState.m_arrAlertTiles.Remove(0,1);
		//NewGameState.AddStateObject(AIUnitState);
		break;
	case eGameRule_PlayerTurnBegin:
		NewGameState = History.CreateNewGameState(true, self);

		// Update this player's turn counter
		CurrentPlayer = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player', PlayerRef.ObjectID));
		CurrentPlayer.PlayerTurnCount += 1;
		NewGameState.AddStateObject(CurrentPlayer);
		break;
	case eGameRule_PlayerTurnEnd:
		// simple placeholder states
		NewGameState = History.CreateNewGameState(true, self);
		break;

	case eGameRule_TacticalGameEnd:
		NewGameState = BuildTacticalGameEndGameState();
		break;

	case eGameRule_UnitChangedTeams:
		NewGameState = BuildUnitChangedTeamGameState();
		break;

	case eGameRule_MarkCorpseSeen:
		`assert( AIRef.ObjectID > 0 && UnitRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);
		AIUnitState = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', AIRef.ObjectID));
		AIUnitState.MarkCorpseSeen(UnitRef.ObjectID);
		NewGameState.AddStateObject(AIUnitState);
		break;

	case eGameRule_AIRevealWait:
		`assert(AIRef.ObjectID > 0 && UnitRef.ObjectID > 0);
		NewGameState = History.CreateNewGameState(true, self);		
		UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		UpdatedUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);//Add action point for this unit
		NewGameState.AddStateObject(UpdatedUnitState);
		break;

	case eGameRule_DemoStart:
		// simple placeholder states
		NewGameState = History.CreateNewGameState(true, self);
		break;

	case eGameRule_ForceSyncVisualizers:
		NewGameState = History.CreateNewGameState(true, self);
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UpdatedUnitState);
		}
		break;
	}

	return NewGameState;
}

function XComGameState BuildTacticalGameEndGameState()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit IterateUnitState;
	local XComGameState_Unit NewUnitState;
	local XComGameState_Player VictoriousPlayer;
	local XComGameState_BattleData BattleData, NewBattleData;
	local StateObjectReference LocalPlayerRef;

	History = `XCOMHISTORY;

	NewGameState = History.CreateNewGameState(true, self);

	VictoriousPlayer = XComGameState_Player(History.GetGameStateForObjectID(PlayerRef.ObjectID));
	if (VictoriousPlayer == none)
	{
		`RedScreen("Battle ended without a winner. This should not happen.");
	}

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleData != none);

	LocalPlayerRef = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ControllingPlayer;
	NewBattleData = XComGameState_BattleData(NewGameState.CreateStateObject(BattleData.Class, BattleData.ObjectID));
	NewBattleData.SetVictoriousPlayer(VictoriousPlayer, VictoriousPlayer.ObjectID == LocalPlayerRef.ObjectID);
	NewBattleData.AwardTacticalGameEndBonuses(NewGameState);
	NewGameState.AddStateObject(NewBattleData);

	// Skip all turns 
	foreach History.IterateByClassType(class'XComGameState_Unit', IterateUnitState)
	{
		NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', IterateUnitState.ObjectID));
        NewUnitState.ActionPoints.Length = 0;
		NewGameState.AddStateObject(NewUnitState);
	}

	// notify of end game state
	`XEVENTMGR.TriggerEvent('TacticalGameEnd');

	return NewGameState;
}

function XComGameState BuildUnitChangedTeamGameState()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

	NewGameState = History.CreateNewGameState(true, self);
	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
	UnitState.SetControllingPlayer(PlayerRef);

	// Give the switched unit action points so they are ready to go
	UnitState.GiveStandardActionPoints();

	NewGameState.AddStateObject(UnitState);

	return NewGameState;
}

/// <summary>
/// Convert the ResultContext and AssociatedState into a set of visualization tracks
/// </summary>
protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{	
	local XComGameState_BattleData BattleState;
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;	

	//Process Units
	switch(GameRuleType)
	{			
	case eGameRule_TacticalGameStart :
		SyncAllVisualizers(VisualizationTracks);

		BattleState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		
		//Use the battle state object for the following actions:
		BuildTrack.StateObject_OldState = BattleState;
		BuildTrack.StateObject_NewState = BattleState;
		BuildTrack.TrackActor = none;

		class'X2Action_SyncMapVisualizers'.static.AddToVisualizationTrack(BuildTrack, self);
		class'X2Action_InitCamera'.static.AddToVisualizationTrack(BuildTrack, self);		
		class'X2Action_InitFOW'.static.AddToVisualizationTrack(BuildTrack, self);		
		class'X2Action_InitUI'.static.AddToVisualizationTrack(BuildTrack, self);
		class'X2Action_StartMissionSoundtrack'.static.AddToVisualizationTrack(BuildTrack, self);				

		// only run the mission intro in single player.
		//	we'll probably want an MP mission intro at some point...
		if( `XENGINE.IsSinglePlayerGame() )
		{
			//Only add the intro track(s) if this start state is current ( ie. we are not visualizing a saved game load )
			if( AssociatedState == History.GetStartState() && 
				BattleState.MapData.PlotMapName != "" &&
				`XWORLDINFO.IsPlayInEditor() != true &&
				BattleState.bIntendedForReloadLevel == false)
			{	
				class'X2Action_HideLoadingScreen'.static.AddToVisualizationTrack(BuildTrack, self);

				if(`TACTICALMISSIONMGR.GetActiveMissionIntroDefinition().MatineePackage != "")
				{
					class'X2Action_DropshipIntro'.static.AddToVisualizationTrack(BuildTrack, self);
					class'X2Action_UnstreamDropshipIntro'.static.AddToVisualizationTrack(BuildTrack, self);
				}
				else
				{
					// if there is no dropship intro, we need to manually clear the camera fade
					class'X2Action_ClearCameraFade'.static.AddToVisualizationTrack(BuildTrack, self);
				}
			}
		}
		else
		{			
			class'X2Action_HideLoadingScreen'.static.AddToVisualizationTrack(BuildTrack, self);
			class'X2Action_ClearCameraFade'.static.AddToVisualizationTrack(BuildTrack, self);
		}

		VisualizationTracks.AddItem(BuildTrack);

		break;
	case eGameRule_ReplaySync:		
		SyncAllVisualizers(VisualizationTracks);
		break;
	case eGameRule_UnitAdded:
		BuildUnitAddedVisualization(VisualizationTracks);
		break;
	case eGameRule_UnitChangedTeams:
		BuildUnitChangedTeamVisualization(VisualizationTracks);
		break;
	case eGameRule_PlayerTurnEnd:
		BuildEndTurnVisualization(VisualizationTracks);
		break;
	case eGameRule_PlayerTurnBegin:
		BuildBeginTurnVisualization(VisualizationTracks);
		break;
	case eGameRule_ForceSyncVisualizers:
		SyncAllVisualizers(VisualizationTracks);
		break;
	}
}

private function BuildEndTurnVisualization(out array<VisualizationTrack> VisualizationTracks)
{
	local X2Action_UpdateUI UIUpdateAction;
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	local XComGameState_Player TurnEndingPlayer;

	History = `XCOMHISTORY;

	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(PlayerRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
	BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
	BuildTrack.TrackActor = History.GetVisualizer(PlayerRef.ObjectID);

	// Try to do a soldier reaction, and if nothing to react to, check if there is any hidden movement
	if(!class'X2Action_EndOfTurnSoldierReaction'.static.AddReactionToBlock(self, VisualizationTracks))
	{
		TurnEndingPlayer = XComGameState_Player(History.GetGameStateForObjectID(PlayerRef.ObjectID));
		if(TurnEndingPlayer != none 
			&& TurnEndingPlayer.GetTeam() == eTeam_XCom
			&& TurnEndingPlayer.TurnsSinceEnemySeen >= class'X2Action_HiddenMovement'.default.TurnsUntilIndicator)
		{
			class'X2Action_HiddenMovement'.static.AddHiddenMovementActionToBlock(AssociatedState, VisualizationTracks);
		}
	}

	class'X2Action_BeginTurnSignals'.static.AddBeginTurnSignalsToBlock(self, VisualizationTracks);
	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTrack(BuildTrack, self));
	UIUpdateAction.SpecificID = PlayerRef.ObjectID;
	UIUpdateAction.UpdateType = EUIUT_EndTurn;

	VisualizationTracks.AddItem(BuildTrack);
}

private function BuildBeginTurnVisualization(out array<VisualizationTrack> VisualizationTracks)
{
	local X2Action_UpdateUI UIUpdateAction;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;

	local XComGameState_Unit IterateUnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_WaitForAbilityEffect WaitAction;
	local XComGameState_Player TurnStartingPlayer;
	local float Radius;
	local float WaitDuration;


	History = `XCOMHISTORY;

	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(PlayerRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
	BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
	BuildTrack.TrackActor = History.GetVisualizer(PlayerRef.ObjectID);

	class'X2Action_BeginTurnSignals'.static.AddBeginTurnSignalsToBlock(self, VisualizationTracks);
	UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTrack(BuildTrack, self));
	UIUpdateAction.SpecificID = PlayerRef.ObjectID;
	UIUpdateAction.UpdateType = EUIUT_BeginTurn;

	VisualizationTracks.AddItem(BuildTrack);


	// For each unit on the current player's team, test if that unit is next to a tile
	// that is on fire, and if so, show a flyover for that unit.  mdomowicz 2015_07_20
	TurnStartingPlayer = XComGameState_Player(History.GetGameStateForObjectID(PlayerRef.ObjectID));
	if ( TurnStartingPlayer != none && TurnStartingPlayer.GetTeam() == eTeam_XCom )
	{
		WaitDuration = 0.1f;

		foreach History.IterateByClassType(class'XComGameState_Unit', IterateUnitState)
		{
			if (IterateUnitState.IsImmuneToDamage('Fire') || IterateUnitState.bRemovedFromPlay)
				continue;

			if ( IterateUnitState.GetTeam() == eTeam_XCom )
			{
				Radius = 2.0;
				if ( IsFireInRadiusOfUnit( Radius, XGUnit(IterateUnitState.GetVisualizer())) )
				{
					// Setup a new track for the unit
					BuildTrack = EmptyTrack;
					BuildTrack.StateObject_OldState = IterateUnitState;
					BuildTrack.StateObject_NewState = IterateUnitState;
					BuildTrack.TrackActor = IterateUnitState.GetVisualizer();

					// Add a wait action to the track.
					WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, self));
					WaitAction.ChangeTimeoutLength(WaitDuration);
					WaitDuration += 2.0f;

					// Then add a flyover to the track.
					SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, self));
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'ObjectFireSpreading', eColor_Bad, "", 1.0f, true, eTeam_None);


					// Then submit the track.
					VisualizationTracks.AddItem(BuildTrack);
				}
			}
		}
	}
}

// This function is based off the implementation of TeamInRadiusOfUnit() in 
// XComWorlData.uc   mdomowicz 2015_07_20
function bool IsFireInRadiusOfUnit( int tile_radius, XGUnit Unit)
{
	local XComWorldData WorldData;
	local array<TilePosPair> OutTiles;
	local float Radius;
	local vector Location;
	local TilePosPair TilePair;
	local TTile TileLocation;

	WorldData = `XWORLD;

	Radius = tile_radius * WorldData.WORLD_StepSize;

	Location = Unit.Location;
	Location.Z += tile_radius * WorldData.WORLD_FloorHeight;

	TileLocation = WorldData.GetTileCoordinatesFromPosition( Unit.Location );

	WorldData.CollectFloorTilesBelowDisc( OutTiles, Location, Radius );

	foreach OutTiles( TilePair )
	{
		if (abs( TilePair.Tile.Z - TileLocation.Z ) > tile_radius)
		{
			continue;
		}

		if ( WorldData.TileContainsFire( TilePair.Tile ) )
		{
			return true;
		}
	}

	return false;
}

private function BuildUnitAddedVisualization(out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	
	History = `XCOMHISTORY;

	if( UnitRef.ObjectID != 0 )
	{
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
		BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
		BuildTrack.TrackActor = History.GetVisualizer(UnitRef.ObjectID);
		class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTrack(BuildTrack, self);
		VisualizationTracks.AddItem(BuildTrack);
	}
	else
	{
		`Redscreen("Added unit but no unit state specified! Talk to David B.");
	}
}

private function BuildUnitChangedTeamVisualization(out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	
	History = `XCOMHISTORY;

	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = History.GetGameStateForObjectID(UnitRef.ObjectID, eReturnType_Reference, AssociatedState.HistoryIndex);
	class'X2Action_SwapTeams'.static.AddToVisualizationTrack(BuildTrack, self);

	VisualizationTracks.AddItem(BuildTrack);
}

private function SyncAllVisualizers(out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local XComGameState_BaseObject VisualizedObject;
	local XComGameStateHistory History;
	local XComGameState_AIPlayerData AIPlayerDataState;
	local XGAIPlayer kAIPlayer;
	local X2Action_SyncMapVisualizers MapVisualizer;
	local XComGameState_BattleData BattleState;
	local int x;

	History = `XCOMHISTORY;

	// Sync the map first so that the tile data is in the proper state for all the individual SyncVisualizer calls
	BattleState = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = BattleState;
	BuildTrack.StateObject_NewState = BattleState;
	MapVisualizer = X2Action_SyncMapVisualizers( class'X2Action_SyncMapVisualizers'.static.AddToVisualizationTrack( BuildTrack, self ) );
	VisualizationTracks.AddItem( BuildTrack );

	MapVisualizer.Syncing = true;

	foreach AssociatedState.IterateByClassType(class'XComGameState_BaseObject', VisualizedObject)
	{
		if(X2VisualizedInterface(VisualizedObject) != none)
		{
			BuildTrack = EmptyTrack;
			BuildTrack.StateObject_OldState = VisualizedObject;
			BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
			BuildTrack.TrackActor = History.GetVisualizer(BuildTrack.StateObject_NewState.ObjectID);
			class'X2Action_SyncVisualizer'.static.AddToVisualizationTrack(BuildTrack, self);

			X2VisualizedInterface(VisualizedObject).AppendAdditionalSyncActions( BuildTrack );

			// force all these actions being used for save/load to just run to completion.
			// timing is irrelevant
			for (x = 0; x < BuildTrack.TrackActions.Length; ++x)
			{
				BuildTrack.TrackActions[x].ForceImmediateTimeout( );
			}

			VisualizationTracks.AddItem( BuildTrack );
		}
	}

	kAIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if (kAIPlayer.m_iDataID == 0)
	{
		foreach AssociatedState.IterateByClassType(class'XComGameState_AIPlayerData', AIPlayerDataState)
		{
			kAIPlayer.m_iDataID = AIPlayerDataState.ObjectID;
			break;
		}
	}
}

/// <summary>
/// Override to return TRUE for the XComGameStateContexts to show that the associated state is a start state
/// </summary>
event bool IsStartState()
{
	return GameRuleType == eGameRule_TacticalGameStart;
}

/// <summary>
/// Returns a short description of this context object
/// </summary>
function string SummaryString()
{
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local XComGameState_Unit UnitState;
	local XComGameState_AIUnitData AIState;
	local string GameRuleString;

	History = `XCOMHISTORY;

	GameRuleString = string(GameRuleType);
	if( RuleEngineNextState != '' )
	{
		GameRuleString = string(RuleEngineNextState);
	}

	if( PlayerRef.ObjectID > 0 )
	{
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(PlayerRef.ObjectID));
		GameRuleString @= "'"$PlayerState.GetGameStatePlayerName()$"' ("$PlayerRef.ObjectID$")";
	}

	if( UnitRef.ObjectID > 0 )
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		GameRuleString @= "'"$UnitState.GetFullName()$"' ("$UnitRef.ObjectID$")";
	}

	if( AIRef.ObjectID > 0 )
	{
		AIState = XComGameState_AIUnitData(History.GetGameStateForObjectID(AIRef.ObjectID));
		if( AIState.m_iUnitObjectID > 0 )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIState.m_iUnitObjectID));
			GameRuleString @= "'"$UnitState.GetFullName()$"'["$UnitState.ObjectID$"] ("$AIRef.ObjectID$")";
		}
	}

	return GameRuleString;
}

/// <summary>
/// Returns a string representation of this object.
/// </summary>
native function string ToString() const;
//***************************************************

static function XComGameStateContext_TacticalGameRule BuildContextFromGameRule(GameRuleStateChange GameRule)
{
	local XComGameStateContext_TacticalGameRule StateChangeContext;

	StateChangeContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	StateChangeContext.GameRuleType = GameRule;

	return StateChangeContext;
}

/// <summary>
/// This creates a minimal start state with a battle data object and three players - one Human and two AI(aliens, civilians). Returns the new game state
/// and also provides an optional out param for the battle data for use by the caller
/// </summary>
static function XComGameState CreateDefaultTacticalStartState_Singleplayer(optional out XComGameState_BattleData CreatedBattleDataObject)
{
	local XComGameStateHistory History;
	local XComGameState StartState;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState_BattleData BattleDataState;
	local XComGameState_Player XComPlayerState;
	local XComGameState_Player EnemyPlayerState;
	local XComGameState_Player CivilianPlayerState;
	local XComGameState_Cheats CheatState;

	History = `XCOMHISTORY;

	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);

	BattleDataState = XComGameState_BattleData(StartState.CreateStateObject(class'XComGameState_BattleData'));
	BattleDataState.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );
	BattleDataState = XComGameState_BattleData(StartState.AddStateObject(BattleDataState));
	
	XComPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_XCom);
	XComPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());
	StartState.AddStateObject(XComPlayerState);

	EnemyPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Alien);
	EnemyPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.PlayerTurnOrder.AddItem(EnemyPlayerState.GetReference());
	StartState.AddStateObject(EnemyPlayerState);

	CivilianPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Neutral);
	CivilianPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
	BattleDataState.CivilianPlayerRef = CivilianPlayerState.GetReference();
	StartState.AddStateObject(CivilianPlayerState);

	// create a default cheats object
	CheatState = XComGameState_Cheats(StartState.CreateStateObject(class'XComGameState_Cheats'));
	StartState.AddStateObject(CheatState);

	CreatedBattleDataObject = BattleDataState;
	return StartState;
}

/// <summary>
/// This creates a minimal start state with a battle data object and two players. Returns the new game state
/// and also provides an optional out param for the battle data for use by the caller
/// </summary>
static function XComGameState CreateDefaultTacticalStartState_Multiplayer(optional out XComGameState_BattleDataMP CreatedBattleDataObject)
{
	local XComGameStateHistory History;
	local XComGameState StartState;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState_BattleDataMP BattleDataState;
	local XComGameState_Player XComPlayerState;
	local XComGameState_Cheats CheatState;

	History = `XCOMHISTORY;

	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);

	BattleDataState = XComGameState_BattleDataMP(StartState.CreateStateObject(class'XComGameState_BattleDataMP'));
	BattleDataState.BizAnalyticsSessionID = `FXSLIVE.GetGUID( );
	BattleDataState = XComGameState_BattleDataMP(StartState.AddStateObject(BattleDataState));
	
	XComPlayerState = XComGameState_Player(StartState.CreateStateObject(class'XComGameState_Player'));
	XComPlayerState.PlayerClassName = Name( "XGPlayer" );
	XComPlayerState.TeamFlag = eTeam_One;
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());
	StartState.AddStateObject(XComPlayerState);

	XComPlayerState = XComGameState_Player(StartState.CreateStateObject(class'XComGameState_Player'));
	XComPlayerState.PlayerClassName = Name( "XGPlayer" );
	XComPlayerState.TeamFlag = eTeam_Two;
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());
	StartState.AddStateObject(XComPlayerState);

	// create a default cheats object
	CheatState = XComGameState_Cheats(StartState.CreateStateObject(class'XComGameState_Cheats'));
	StartState.AddStateObject(CheatState);
	
	CreatedBattleDataObject = BattleDataState;
	return StartState;
}

function OnSubmittedToReplay(XComGameState SubmittedGameState)
{
	local XComGameState_Unit UnitState;

	if (GameRuleType == eGameRule_ReplaySync)
	{
		foreach SubmittedGameState.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
		{
			UnitState.SetVisibilityLocation(UnitState.TileLocation);

			if (!UnitState.GetMyTemplate( ).bIsCosmetic && !UnitState.bRemovedFromPlay)
			{
				`XWORLD.SetTileBlockedByUnitFlag(UnitState);
			}
		}
	}
}

// Debug-only function used in X2DebugHistory screen.
function bool HasAssociatedObjectID(int ID)
{
	return UnitRef.ObjectID == ID;
}
