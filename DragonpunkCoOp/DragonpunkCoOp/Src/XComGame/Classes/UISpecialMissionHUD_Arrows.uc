//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISpecialMissionHUD_Arrows.uc
//  AUTHORS: Brit Steiner, David Burchanowski
//
//  PURPOSE: Container for special mission arrows, used to point at 3D space or at 2D elements. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISpecialMissionHUD_Arrows extends UIPanel
	implements(X2VisualizationMgrObserverInterface)
	config(UI);

struct T3DArrow 
{
	var Vector      offset;     //offset for arrow point in 3D space, relative to the actor's/location's origin. 
	var Actor       kActor;
	var vector      loc;        // only used if kActor is none
	var EUIState    arrowState;
	var int         arrowCounter;
	var string		icon;
	structdefaultproperties
	{
		arrowState = eUIState_Warning; // yellow arrow by default
		arrowCounter = -1;
		icon = "";
	}
};

var const config float ScreenEdgePadding;

var array<T3DArrow>	arr3DArrows;

//=====================================================================
// 		GENERAL FUNCTIONS:
//=====================================================================

// Pseudo-Ctor
simulated function UISpecialMissionHUD_Arrows InitArrows()
{
	InitPanel();
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
	return self;
}

simulated function OnInit()
{
	super.OnInit();
	Show();
	XComPresentationLayer(screen.Owner).SubscribeToUIUpdate( Update );
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComPresentationLayer(Movie.Pres).m_kTacticalHUD, 'm_isMenuRaised', self, UpdateVisibility);

	// in case this is a load, inspect the history and make sure we restore any arrows that
	// were there when we saved
	AddExistingArrows();
}

function UpdateVisibility()
{
	//We want to hide these arrows while the shotHUD is open. 
	if( XComPresentationLayer(Movie.Pres).m_kTacticalHUD.IsMenuRaised() )
		Hide();
	else
		Show();
}

// Restores arrows from the latest history frame. For loading.
function AddExistingArrows()
{
	local XComGameStateHistory History;
	local XComGameState_IndicatorArrow Arrow;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_IndicatorArrow', Arrow)
	{   
		ProcessArrowGameStateObject(Arrow);
	}
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState_IndicatorArrow Arrow;
	
	foreach AssociatedGameState.IterateByClassType(class'XComGameState_IndicatorArrow', Arrow)
	{   
		ProcessArrowGameStateObject(Arrow);
	}
}

// Helper function to prevent us from caring where we get the arrow object from and
// having to duplicate this block because of it.
function ProcessArrowGameStateObject(XComGameState_IndicatorArrow Arrow)
{
	local Vector Offset;

	if(Arrow.bRemoved)
	{
		if(Arrow.Unit != none)
		{
			RemoveArrowPointingAtActor(Arrow.Unit.GetVisualizer());
		}
		else
		{
			RemoveArrowPointingAtLocation(Arrow.Location);
		}
	}
	else // not removed in this state, so add it
	{
		Offset.Z = Arrow.Offset;
		if(Arrow.Unit != none)
		{
			AddArrowPointingAtActor(Arrow.Unit.GetVisualizer(), Offset, Arrow.ArrowColor, Arrow.CounterValue, Arrow.Icon);
		}
		else
		{
			AddArrowPointingAtLocation(Arrow.Location, Offset, Arrow.ArrowColor, Arrow.CounterValue, Arrow.Icon);
		}
	}
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle();

// Adds a new arrow pointing at an actor, or updates it if it already exists
simulated function AddArrowPointingAtActor( Actor kActor, optional vector offset, 
											optional EUIState arrowState = eUIState_Warning, 
											optional int arrowCount = -1, 
											optional string icon = "")
{
	local int index;
	local T3DArrow actorArrow; 
	
	if( kActor == none )
	{
		`log( "Failing to add a UI arrow pointer to track an actor, because the actor reference is none.");
		return;
	}

	index = arr3DArrows.Find('kActor', kActor);
	if(index != -1)
	{
		// Update data on arrow
		arr3DArrows[index].offset = offset;
		arr3DArrows[index].arrowState = arrowState;
		arr3DArrows[index].arrowCounter = arrowCount;
		arr3DArrows[index].icon = icon;
	}
	else
	{
		actorArrow.kActor = kActor;
		actorArrow.offset = offset;
		actorArrow.arrowState = arrowState;
		actorArrow.arrowCounter = arrowCount;
		actorArrow.icon = icon;
		arr3DArrows.AddItem(actorArrow );
	}
}

simulated function RemoveArrowPointingAtActor( Actor kActor )
{
	local int index;

	if( kActor == none ) 
	{
		`log( "Failing to remove a UI arrow pointer to track an actor, because the actor reference is none.");
		return;
	}

	index = arr3DArrows.Find('kActor', kActor);

	if( index != -1) 
	{
		//delete from arrTargetedArrows
		RemoveArrow( string(arr3DArrows[index].kActor.Name) );
		arr3DArrows.Remove( index, 1 );
	}
	else
	{
		`log( "Attempting to delete a 3D arrow that is not found in the arrows array. id: " $ string(kActor.Name));
	}
}

simulated function string GetIdFromLocation(vector loc)
{
	return ffloor(loc.x) $ "_" $ ffloor(loc.y) $ "_" $ ffloor(loc.z);
}

// Adds a new arrow pointing at a location, or updates it if it already exists
simulated function AddArrowPointingAtLocation( vector loc, optional vector offset, optional EUIState arrowState = eUIState_Warning, optional int arrowCount = -1, optional string icon = "" )
{
	local int index;
	local T3DArrow actorArrow; 

	index = arr3DArrows.Find('loc', loc);
	if(index != -1)
	{
		// Update data on arrow
		arr3DArrows[index].offset = offset;
		arr3DArrows[index].arrowState = arrowState;
		arr3DArrows[index].arrowCounter = arrowCount;
		arr3DArrows[index].icon = icon;
	}
	else
	{
		actorArrow.loc = loc;
		actorArrow.offset = offset;
		actorArrow.arrowState = arrowState;
		actorArrow.arrowCounter = arrowCount;
		actorArrow.icon= icon;
		arr3DArrows.AddItem( actorArrow );
	}
}

simulated function RemoveArrowPointingAtLocation( vector loc )
{
	local int index; 
	
	index = arr3DArrows.Find('loc', loc);

	if( index != -1) 
	{
		//delete from arrTargetedArrows
		RemoveArrow( GetIdFromLocation(loc) );
		arr3DArrows.Remove( index, 1 );
	}
}

simulated function Update()
{
	UpdateTargetedArrows();
}

simulated function UpdateTargetedArrows()
{
	local T3DArrow kTarget;
	local vector        targetLocation;
	local vector2D      v2ScreenCoords;
	local float         yaw;

	// Leave if Flash side isn't up.
	if( !bIsInited )
		return;
	
	if( !IsVisible() )
		return; 

	//return if no update is needed
	if( arr3DArrows.length == 0)
	{
		return;
	}

	foreach arr3DArrows( kTarget )
	{
		if(kTarget.kActor != none)
		{
			targetLocation = kTarget.kActor.Location;
		}
		else
		{
			targetLocation = kTarget.loc;
		}

		if(class'UIUtilities'.static.IsOnscreen( (targetLocation + kTarget.offset), v2ScreenCoords ) ) 
		{
			//set the arrows to vertical, pointing down to the target
			yaw = 180;
		}
		else
		{
			yaw = Atan2(0.5f - v2ScreenCoords.y, 0.5f - v2ScreenCoords.x) * RadToDeg - 90;
		}

		v2ScreenCoords = Movie.ConvertNormalizedScreenCoordsToUICoords(v2ScreenCoords.X, v2ScreenCoords.Y, true, ScreenEdgePadding);
		
		if(kTarget.kActor != none)
		{
			SetArrow( string(kTarget.kActor.name), v2ScreenCoords.x, v2ScreenCoords.y, yaw, 
					  GetArrowColor(kTarget.arrowState), GetFormattedCount(kTarget.arrowCounter, kTarget.arrowState), kTarget.icon);
		}
		else
		{
			SetArrow( GetIdFromLocation(targetLocation), v2ScreenCoords.x, v2ScreenCoords.y, yaw, 
					  GetArrowColor(kTarget.arrowState), GetFormattedCount(kTarget.arrowCounter, kTarget.arrowState), kTarget.icon);
		}
	}
}

simulated function string GetArrowColor(EUIState arrowState)
{
	switch(arrowState)
	{
	case eUIState_Normal:   return "blueArrow";
	case eUIState_Warning:  return "yellowArrow";
	case eUIState_Bad:      return "redArrow";
	case eUIState_Disabled: return "grayArrow";
	case eUIState_Good:     return "greenArrow";
	default:				return "yellowArrow";
	}
}
simulated function string GetFormattedCount(int count, EUIState arrowState)
{
	if(count < 0) return "";
	return class'UIUtilities_Text'.static.GetColoredText(string(count), int(arrowState));
}

// Send individual arrow update information over to flash
simulated function SetArrow( string id, float xloc,  float yloc, float yaw, string sColor, string sCount, string icon)
{
	Movie.ActionScriptVoid(MCPath$".SetArrow");
}

simulated function RemoveArrow( string id )
{
	Movie.ActionScriptVoid(MCPath$".RemoveArrow");
}

event Destroyed()
{
	Movie.Pres.UnsubscribeToUIUpdate( Update );
	super.Destroyed();
}

//=====================================================================
//		DEFAULTS:
//=====================================================================

defaultproperties
{
	MCName      = "arrowContainer";
	bAnimateOnInit = false;
}
