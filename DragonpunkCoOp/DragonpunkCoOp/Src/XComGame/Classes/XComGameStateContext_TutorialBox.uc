//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_TutorialBox.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Context for showing a tutorial popup box
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameStateContext_TutorialBox extends XComGameStateContext;

enum TutorialBoxType
{
	TutorialBoxType_Modal, // fullscreen control stealing box, optionally with image
	TutorialBoxType_Blade, // blade type, possibly anchored to a unit
};

// The tutorial text is also stored in the localized objective text list. Tutorial boxes
// are just an alternative way to display it. This line is used for the title at the top
// of the box
var privatewrite int TitleObjectiveTextIndex;

// The tutorial text is also stored in the localized objective text list. Tutorial boxes
// are just an alternative way to display it.
var privatewrite int ObjectiveTextIndex;

var privatewrite TutorialBoxType BoxType;

// Unique identifier to associate with this message, so we can remove it later
var privatewrite string MessageID;

// image to use with this box. Only sensible for modal boxes
var privatewrite string ImagePath;

// If true, indicates that we should remove the message box with the specified id, and not add it
var privatewrite bool Remove;

// Optional, will anchor a blade message to the specified object
var StateObjectReference ObjectToAnchorTo;

// optional, will anchor the blade message to the specified location
var vector AnchorLocation;

// If specified, uses this string instead of looking it up using the indices
var string ExplicitTitle;

// If specified, uses this string instead of looking it up using the indices
var string ExplicitText;

// If true and a tutorial blade, the blade will be hidden when entering the shot hud
var bool HideBladeInShotHud;

static function AddModalTutorialBoxToHistory(int InTitleObjectiveTextIndex, int InObjectiveTextIndex, optional string InImagePath = "")
{
	local XComGameStateContext_TutorialBox Context;
	local X2TacticalGameRuleset Rules;

	Context = new class'XComGameStateContext_TutorialBox';
	Context.BoxType = TutorialBoxType_Modal;
	Context.TitleObjectiveTextIndex = InTitleObjectiveTextIndex;
	Context.ObjectiveTextIndex = InObjectiveTextIndex;
	Context.ImagePath = InImagePath;

	Rules = `TACTICALRULES;
	Rules.SubmitGameStateContext(Context);
}

static function AddModalTutorialBoxToHistoryExplicit(string InTitle, string InText, optional string InImagePath = "")
{
	local XComGameStateContext_TutorialBox Context;
	local X2TacticalGameRuleset Rules;

	Context = new class'XComGameStateContext_TutorialBox';
	Context.BoxType = TutorialBoxType_Modal;
	Context.ExplicitTitle = InTitle;
	Context.ExplicitText = InText;
	Context.ImagePath = InImagePath;

	Rules = `TACTICALRULES;
	Rules.SubmitGameStateContext(Context);
}

static function AddBladeTutorialBoxToHistory(string ID, 
											 int InObjectiveTextIndex, 
											 optional StateObjectReference InObjectToAnchorTo, 
											 optional string InAnchorActorTag,
											 optional bool InHideBladeInShotHud = false)
{
	local XComGameStateContext_TutorialBox Context;
	local Actor ActorIt;
	local X2TacticalGameRuleset Rules;
	local name AnchorTagName;

	Context = new class'XComGameStateContext_TutorialBox';
	Context.BoxType = TutorialBoxType_Blade;
	Context.MessageID = ID;
	Context.ObjectiveTextIndex = InObjectiveTextIndex;
	Context.ObjectToAnchorTo = InObjectToAnchorTo;
	Context.HideBladeInShotHud = InHideBladeInShotHud;

	if(InAnchorActorTag != "")
	{
		AnchorTagName = name(InAnchorActorTag);
		foreach `XWORLDINFO.AllActors(class'Actor', ActorIt)
		{
			if(ActorIt.Tag == AnchorTagName)
			{
				Context.AnchorLocation = ActorIt.Location;
				break;
			}
		}
	}

	Rules = `TACTICALRULES;
	Rules.SubmitGameStateContext(Context);
}

static function RemoveBladeTutorialBoxFromHistory(string ID)
{
	local XComGameStateContext_TutorialBox Context;
	local X2TacticalGameRuleset Rules;

	Context = new class'XComGameStateContext_TutorialBox';
	Context.MessageID = ID;
	Context.Remove = true;

	Rules = `TACTICALRULES;
	Rules.SubmitGameStateContext(Context);
}

function XComGameState ContextBuildGameState()
{
	local XComGameStateHistory History;

	super.ContextBuildGameState();

	// everything waits for the box
	SetVisualizationFence(true);

	// we don't actually modify the history, we just need to add a marker frame so the visualizer knows when to show the textbox.
	History = `XCOMHISTORY;
	return History.CreateNewGameState(true, self);
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local VisualizationTrack Track;

	class'X2Action_ShowTutorialPopup'.static.AddToVisualizationTrack(Track, self);
	
	// the visualizer complains if there is no associated state for a track, so just put it on a player state
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		Track.StateObject_OldState = PlayerState;
		Track.StateObject_NewState = PlayerState;
		break;
	}

	VisualizationTracks.AddItem(Track);
}

defaultproperties
{
	TitleObjectiveTextIndex=-1
}

