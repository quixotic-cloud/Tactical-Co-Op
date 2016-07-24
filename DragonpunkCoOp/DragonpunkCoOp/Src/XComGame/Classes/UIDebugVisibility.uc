//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDebugVisibility
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: Debug screen for viewing information / visibility frames contained by
//           X2GameRulesetVisibilityManager
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDebugVisibility extends UIScreen dependson(X2TacticalGameRulesetDataStructures);

var UIPanel		m_kAllContainer;
var UIButton	m_kStopButton;
var UIBGBox		m_kMouseHitBG;

var UIPanel     FrameInfoContainer;
var UIBGBox		m_kCurrentFrameInfoBG;
var UIText		m_kCurrentFrameInfoTitle;
var UIText		m_kCurrentFrameInfoText;
var UIButton	m_kRecalcVisibilityButton;

var name StoredInputState;
var bool bStoredFOWState;

var XComTacticalController  TacticalController;
var XComTacticalInput       TacticalInput;

enum EProcessClickType
{
	eType_SelectNone,
	eType_SelectSource,
	eType_SelectTarget,
};

var bool bProcessClick;
var EProcessClickType ProcessClickType;

var StateObjectReference SourceRef;
var X2GameRulesetVisibilityInterface SourceInterface;

var StateObjectReference TargetRef;
var X2GameRulesetVisibilityInterface TargetInterface;

var bool bStoredMouseIsActive;

struct ClickInformation
{
	var StateObjectReference ClickedStateObjectRef;
	var X2GameRulesetVisibilityInterface ClickedStateObjectInterface;

	var bool bDrawingBox;   //If ClickedStateObjectInterface is none, then we draw a box around the viewpoint tile
	var Vector HitLocation;
	var TTile  HitTile;
	var bool bHasFloor;     //If bHasFloor is TRUE, it means that hte hit tile is on the ground and we should perform visibilty checks from Z+1
	var name ActorName;
};

var ClickInformation SourceClick;
var ClickInformation TargetClick;
var GameRulesCache_VisibilityInfo VisibilityInfo;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{		
	local XComGameStateHistory History;
	local XComGameState_BaseObject TestObject;
	local X2GameRulesetVisibilityInterface TestObjectInterface;

	super.InitScreen(InitController, InitMovie, InitName);

	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();

	m_kAllContainer         = Spawn(class'UIPanel', self);
	m_kMouseHitBG           = Spawn(class'UIBGBox', m_kAllContainer);
	m_kStopButton           = Spawn(class'UIButton', m_kAllContainer);	

	FrameInfoContainer = Spawn(class'UIPanel', self);
	m_kCurrentFrameInfoBG   = Spawn(class'UIBGBox', FrameInfoContainer);
	m_kCurrentFrameInfoTitle= Spawn(class'UIText', FrameInfoContainer);
	m_kCurrentFrameInfoText = Spawn(class'UIText', FrameInfoContainer);
	m_kRecalcVisibilityButton = Spawn(class'UIButton', FrameInfoContainer);
	
	m_kAllContainer.InitPanel('allContainer');
	m_kAllContainer.SetPosition(50, 50);
	m_kAllContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);

	FrameInfoContainer.InitPanel('InfoContainer');
	FrameInfoContainer.SetPosition(-550, 50);
	FrameInfoContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	
	m_kMouseHitBG.InitBG('mouseHit', 0, 0, Movie.UI_RES_X, Movie.UI_RES_Y);	
	m_kMouseHitBG.SetAlpha(0.00001f);
	m_kMouseHitBG.ProcessMouseEvents(OnMouseHitLayerCallback);

	m_kStopButton.InitButton('stopButton', "Stop Debugging", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	m_kStopButton.SetX(50);
	m_kStopButton.SetY(50);
	
	m_kCurrentFrameInfoBG.InitBG('infoBox', 0, 0, 500, 675);
	m_kCurrentFrameInfoTitle.InitText('infoBoxTitle', "<Empty>", true);
	m_kCurrentFrameInfoTitle.SetWidth(480);
	m_kCurrentFrameInfoTitle.SetX(10);
	m_kCurrentFrameInfoTitle.SetY(60);
	m_kCurrentFrameInfoText.InitText('infoBoxText', "<Empty>", true);
	m_kCurrentFrameInfoText.SetWidth(480);
	m_kCurrentFrameInfoText.SetX(10);
	m_kCurrentFrameInfoText.SetY(120);
		
	m_kRecalcVisibilityButton.InitButton('recalcButton', "Recalculate", OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kRecalcVisibilityButton.SetX(200);
	m_kRecalcVisibilityButton.SetY(5);	
	
	m_kAllContainer.AddOnInitDelegate(PositionButtonContainer);

	TacticalController = XComTacticalController(PC);
	TacticalInput = XComTacticalInput(TacticalController.PlayerInput);

	StoredInputState = TacticalController.GetInputState();
	TacticalController.SetInputState('Multiplayer_Inactive');

	m_kCurrentFrameInfoTitle.SetText("LMB to select SOURCE. SHIFT+LMB to select TARGET.");

	//Turn off FOW and make every actor that implements the visibility interface visible
	bStoredFOWState =  `XWORLD.bDebugEnableFOW;
	if( bStoredFOWState )
	{
		XComCheatManager(TacticalController.CheatManager).ToggleFOW();
	}

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_BaseObject', TestObject)
	{
		TestObjectInterface = X2GameRulesetVisibilityInterface(TestObject);
		if( TestObjectInterface != none )
		{
			History.GetVisualizer(TestObject.ObjectID).SetVisibleToTeams(eTeam_All);
		}
	}

	AddHUDOverlayActor();
}

simulated function PositionButtonContainer( UIPanel Control )
{
	m_kAllContainer.SetPosition(20, m_kAllContainer.mc.GetNum("_y") - 40);
}

simulated function OnButtonClicked(UIButton button)
{
	local Vector DrawDebugBoxCenter;
	local Vector DrawDebugBoxExtents;
	local array<TTile> TestObjectTiles;
	local XComWorldData WorldData;	
	local X2GameRulesetVisibilityManager VisibilityMgr;

	if ( button == m_kStopButton )
	{
		//Turn on FOW and restore the correct visibility state for the actors
		XComCheatManager(TacticalController.CheatManager).ToggleFOW();
		`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.OnVisualizationBlockComplete(none);

		if( !bStoredMouseIsActive )
		{
			Movie.DeactivateMouse();
		}

		if( bStoredFOWState )
		{
			XComCheatManager(TacticalController.CheatManager).ToggleFOW();
		}

		WorldInfo.FlushPersistentDebugLines();
		RemoveHUDOverlayActor();
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		TacticalController.SetInputState(StoredInputState);
		Movie.Stack.Pop(self);
	}
	else if(button == m_kRecalcVisibilityButton)
	{		
		VisibilityMgr = `GAMERULES.VisibilityMgr;
		if(VisibilityMgr.GetVisibilityInfo(SourceClick.ClickedStateObjectRef.ObjectID, TargetClick.ClickedStateObjectRef.ObjectID, VisibilityInfo))
		{
			WorldData = `XWORLD;			

			TestObjectTiles.Length = 0;
			SourceClick.ClickedStateObjectInterface.GetVisibilityLocation(TestObjectTiles);
			DrawDebugBoxCenter = WorldData.GetPositionFromTileCoordinates(VisibilityInfo.SourceTile);
			DrawDebugBoxCenter.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;
			DrawDebugBox(DrawDebugBoxCenter, DrawDebugBoxExtents, 0, 255, 0, true);

			TestObjectTiles.Length = 0;
			TargetClick.ClickedStateObjectInterface.GetVisibilityLocation(TestObjectTiles);
			DrawDebugBoxCenter = WorldData.GetPositionFromTileCoordinates(VisibilityInfo.DestTile);
			DrawDebugBoxCenter.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;
			DrawDebugBox(DrawDebugBoxCenter, DrawDebugBoxExtents, 0, 255, 0, true);			

			WorldData.CanSeeTileToTile(VisibilityInfo.SourceTile, VisibilityInfo.DestTile, VisibilityInfo);

			if(SourceClick.ClickedStateObjectRef.ObjectID > 0)
			{
				VisibilityInfo.SourceID = SourceClick.ClickedStateObjectRef.ObjectID;
			}

			if(TargetClick.ClickedStateObjectRef.ObjectID > 0)
			{
				VisibilityInfo.TargetID = TargetClick.ClickedStateObjectRef.ObjectID;
			}

			m_kCurrentFrameInfoText.SetText(class'X2TacticalGameRulesetDataStructures'.static.GetVisibilityInfoDebugString(VisibilityInfo));
			class'X2TacticalGameRulesetDataStructures'.static.DrawVisibilityInfoDebugPrimitives(VisibilityInfo);
		}
	}
}

simulated function OnMouseHitLayerCallback( UIPanel control, int cmd )
{
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:		
			bProcessClick = true;

			if( TacticalInput.PressedKeys.Find('LeftShift') != INDEX_NONE )
			{
				ProcessClickType = eType_SelectTarget;
			}
			else
			{
				ProcessClickType = eType_SelectSource;
			}
			break;
	}
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local Vector2D v2MousePosition; 
	local Vector MouseWorldOrigin, MouseWorldDirection;
	local Vector vHitLocation, vHitNormal;
	local Actor HitActor;
	local XComUnitPawn UnitPawn;
	local TTile HitTile;
	local TTile HitTile_ZPos;
	local TTile HitTile_ZNeg;
	local XComGameState_BaseObject TestObject;
	local array<TTile> TestObjectTiles;
	local XComGameStateHistory History;	
	local X2GameRulesetVisibilityInterface TestObjectInterface;	
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local int Index;
	local Vector ProjectedHitLocation;
	local XComWorldData WorldData;
	local XComInteractiveLevelActor InteractiveActor;

	local Vector DrawDebugBoxCenter;	
	local Vector DrawDebugBoxExtents;	

	local ClickInformation BuildClickInformation;
	local TTile SourceTile;
	local TTile TargetTile;

	local bool bFound;

	VisibilityMgr = `GAMERULES.VisibilityMgr;

	if( bProcessClick )
	{
		bProcessClick = false;

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

			`XWORLD.GetFloorTileForPosition(vHitLocation, HitTile);
			if( HitTile.X == -1 )
			{
				HitTile = `XWORLD.GetTileCoordinatesFromPosition(vHitLocation);
				BuildClickInformation.bHasFloor = false;
			}
			else
			{
				BuildClickInformation.bHasFloor = true;
			}

			UnitPawn = XComUnitPawn(HitActor);
			if( UnitPawn != none && UnitPawn.m_kGameUnit != none )
			{
				TestObject = History.GetGameStateForObjectID(UnitPawn.m_kGameUnit.ObjectID);
				TestObjectInterface = X2GameRulesetVisibilityInterface(TestObject);				
				TestObjectTiles.Length = 0;
				TestObjectInterface.GetVisibilityLocation(TestObjectTiles);
			}
			
			InteractiveActor = XComInteractiveLevelActor(HitActor);
			if(TestObjectInterface == none && InteractiveActor != none && InteractiveActor.ObjectID > 0)
			{
				TestObject = History.GetGameStateForObjectID(InteractiveActor.ObjectID);
				TestObjectInterface = X2GameRulesetVisibilityInterface(TestObject);
				if(TestObjectInterface != none)
				{
					TestObjectTiles.Length = 0;
					TestObjectInterface.GetVisibilityLocation(TestObjectTiles);
				}
			}

			if( TestObjectInterface == none )
			{
				HitTile_ZPos = HitTile;
				HitTile_ZPos.Z += 1;

				HitTile_ZNeg = HitTile;
				HitTile_ZNeg.Z -= 1;

				foreach History.IterateByClassType(class'XComGameState_BaseObject', TestObject)
				{
					TestObjectInterface = X2GameRulesetVisibilityInterface(TestObject);
					if( TestObjectInterface != none )
					{
						bFound = false;
						TestObjectTiles.Length = 0;
						TestObjectInterface.GetVisibilityLocation(TestObjectTiles);
						for(Index = 0; Index < TestObjectTiles.length; ++Index)
						{
							if(TestObjectTiles[Index] == HitTile ||
							   TestObjectTiles[Index] == HitTile_ZPos ||
							   TestObjectTiles[Index] == HitTile_ZNeg)
							{
								bFound = true;
								break;
							}
						}

						if (bFound)
						{
							break;
						}
					}
					TestObjectInterface = none;
				}
			}			

			WorldData = `XWORLD;

			BuildClickInformation.ActorName = HitActor.Name;
			BuildClickInformation.HitLocation = vHitLocation;			
			BuildClickInformation.HitTile = HitTile;
			BuildClickInformation.bDrawingBox = TestObjectInterface == none;
			BuildClickInformation.ClickedStateObjectRef = TestObject.GetReference();
			BuildClickInformation.ClickedStateObjectInterface = TestObjectInterface;

			if( TestObjectInterface != none )
			{
				BuildClickInformation.bDrawingBox = false;
			}
			else
			{
				BuildClickInformation.bDrawingBox = true;				
				BuildClickInformation.ClickedStateObjectInterface = none;
			}

			switch(ProcessClickType)
			{
			case eType_SelectSource:
				SourceClick = BuildClickInformation;
				break;
			case eType_SelectTarget:
				TargetClick = BuildClickInformation;
				break;
			}
			
			WorldInfo.FlushPersistentDebugLines();

			DrawDebugBoxExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
			DrawDebugBoxExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
			DrawDebugBoxExtents.Z = class'XComWorldData'.const.WORLD_FloorHeight;
			
			if( SourceClick.bDrawingBox )
			{
				DrawDebugBoxCenter = `XWORLD.GetPositionFromTileCoordinates(SourceClick.HitTile);
				DrawDebugBoxCenter.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;
				DrawDebugBox(DrawDebugBoxCenter, DrawDebugBoxExtents, 255, 255, 255, true);
			}
			else
			{	
				TestObjectTiles.Length = 0;
				SourceClick.ClickedStateObjectInterface.GetVisibilityLocation(TestObjectTiles);
				DrawDebugBoxCenter = WorldData.GetPositionFromTileCoordinates(TestObjectTiles[0]);
				DrawDebugBoxCenter.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;
				DrawDebugBox(DrawDebugBoxCenter, DrawDebugBoxExtents, 0, 255, 0, true);
			}

			if( TargetClick.bDrawingBox )
			{
				DrawDebugBoxCenter = `XWORLD.GetPositionFromTileCoordinates(TargetClick.HitTile);
				DrawDebugBoxCenter.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;
				DrawDebugBox(DrawDebugBoxCenter, DrawDebugBoxExtents, 255, 255, 255, true);
			}
			else
			{	
				TestObjectTiles.Length = 0;
				TargetClick.ClickedStateObjectInterface.GetVisibilityLocation(TestObjectTiles);
				DrawDebugBoxCenter = WorldData.GetPositionFromTileCoordinates(TestObjectTiles[0]);
				DrawDebugBoxCenter.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;
				DrawDebugBox(DrawDebugBoxCenter, DrawDebugBoxExtents, 0, 255, 0, true);
			}
				
			if( SourceClick.bDrawingBox || TargetClick.bDrawingBox )
			{
				//Is either the source or the target "hypothetical" ? This means that there is no current unit standing there. In those situations we 
				//make calls to the visibility system to get visibility info for the specified tiles.
				SourceTile = SourceClick.HitTile;
				SourceTile.Z += 1;

				TargetTile = TargetClick.HitTile;
				TargetTile.Z += 1;

				WorldData.CanSeeTileToTile(SourceTile, TargetTile, VisibilityInfo);				

				if( SourceClick.ClickedStateObjectRef.ObjectID > 0 )
				{
					VisibilityInfo.SourceID = SourceClick.ClickedStateObjectRef.ObjectID;
				}

				if( TargetClick.ClickedStateObjectRef.ObjectID > 0 )
				{
					VisibilityInfo.TargetID = TargetClick.ClickedStateObjectRef.ObjectID;
				}

				m_kCurrentFrameInfoText.SetText( class'X2TacticalGameRulesetDataStructures'.static.GetVisibilityInfoDebugString(VisibilityInfo) );
				class'X2TacticalGameRulesetDataStructures'.static.DrawVisibilityInfoDebugPrimitives(VisibilityInfo);
			}
			else
			{
				//Both source and target are represented in the visibility system as viewers so there is cached visibility we can look up for their 
				//visibility relationship
				if( VisibilityMgr.GetVisibilityInfo(SourceClick.ClickedStateObjectRef.ObjectID, TargetClick.ClickedStateObjectRef.ObjectID, VisibilityInfo) )
				{
					m_kCurrentFrameInfoText.SetText( class'X2TacticalGameRulesetDataStructures'.static.GetVisibilityInfoDebugString(VisibilityInfo) );
					class'X2TacticalGameRulesetDataStructures'.static.DrawVisibilityInfoDebugPrimitives(VisibilityInfo);
				}
			}
		}
	}

	//Update the hit info text - needs to be done each post render	
	kCanvas.SetDrawColor(255, 0, 0);
	for(Index = 0; Index < VisibilityInfo.DebugTraceData.Length; ++Index)
	{
		if(VisibilityInfo.DebugTraceData[Index].bHit)
		{
			ProjectedHitLocation = kCanvas.Project(VisibilityInfo.DebugTraceData[Index].TraceHit);
			kCanvas.SetPos(ProjectedHitLocation.X, ProjectedHitLocation.Y);
			kCanvas.DrawText(string(VisibilityInfo.DebugTraceData[Index].HitActor.ObjectArchetype.Name));
		}
	}

	if( SourceClick.bDrawingBox )
	{
		ProjectedHitLocation = kCanvas.Project(SourceClick.HitLocation);
		kCanvas.SetPos(ProjectedHitLocation.X, ProjectedHitLocation.Y);
		kCanvas.SetDrawColor(255,255,255);
		kCanvas.DrawText( SourceClick.ActorName @ "(ObjectID : " @ SourceClick.ClickedStateObjectRef.ObjectID @ ")" );
	}

	if( TargetClick.bDrawingBox ) 
	{
		ProjectedHitLocation = kCanvas.Project(TargetClick.HitLocation);
		kCanvas.SetPos(ProjectedHitLocation.X, ProjectedHitLocation.Y);
		kCanvas.SetDrawColor(255,255,255);
		kCanvas.DrawText(TargetClick.ActorName @ "(ObjectID : " @ TargetClick.ClickedStateObjectRef.ObjectID @ ")");
	}
}

simulated function UpdateCurrentFrameInfoBox()
{
	local string NewText;

	NewText = "History Frame" @ XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.CurrentHistoryFrame;
	m_kCurrentFrameInfoTitle.SetText(NewText);

	NewText = `XCOMHISTORY.GetGameStateFromHistory(-1, eReturnType_Reference).GetContext().SummaryString();
	m_kCurrentFrameInfoText.SetText(NewText);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
			//OnButtonClicked(m_kCloseButton);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:		
			//OnUAccept();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	bHideOnLoseFocus = true;
}