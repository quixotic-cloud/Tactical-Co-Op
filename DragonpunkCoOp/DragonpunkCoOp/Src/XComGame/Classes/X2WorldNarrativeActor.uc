//---------------------------------------------------------------------------------------
//  FILE:    X2WorldNarrativeActor.uc
//  AUTHOR:  David Burchanowski  --  6/2/2015
//  PURPOSE: Actor the LDs can place in the world to provide flavor text
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2WorldNarrativeActor extends PointInSpace
	placeable;

enum ESightRange
{
	ESightRange_Short,
	ESightRange_Medium,
	ESightRange_Long
};

// the narrative moment that should play when the user sees this actor
var() const XComNarrativeMoment NarrativeMoment; 

// priority of this narrative moment. If more than one can be played at a time, then we will play the one with the highest priority value.
var() const int NarrativePriority;

// Range at which the narrative will play
var() const ESightRange SightRange;

var() const bool bPlayEvenIfInterrupted;

var() const bool bPlayOnlyIfConcealed;

// Some unit in your squad must have this ability (if specified)
var() const name SomeUnitHasRequiredAbilityName;

function CreateState(XComGameState StartGameState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldNarrativeActor ObjectState;
	local TTile TileLocation;

	// if it doesn't exist, then we need to create it
	History = `XCOMHISTORY;

	// make sure this is the start state. These should only ever be created at start state!
	`assert(StartGameState == History.GetStartState());
	if(StartGameState == none)
	{
		return;
	}

	// ignore things that are outside the bounds of the level
	TileLocation = `XWORLD.GetTileCoordinatesFromPosition( Location );
	if (`XWORLD.IsTileOutOfRange( TileLocation ))
	{
		return;
	}

	// don't include these when building challenge mode maps.
	if (History.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) != none)
	{
		return;
	}
	
	ObjectState = XComGameState_WorldNarrativeActor(StartGameState.CreateStateObject(class'XComGameState_WorldNarrativeActor'));

	ObjectState.SetInitialState(self);
	StartGameState.AddStateObject(ObjectState);

	// ensure that a tracker exists as well
	if(History.GetSingleGameStateObjectForClass(class'XComGameState_WorldNarrativeTracker', true) == none)
	{
		StartGameState.AddStateObject(StartGameState.CreateStateObject(class'XComGameState_WorldNarrativeTracker'));
	}

	History.SetVisualizer(ObjectState.ObjectID, self);
}

function float SightRangeToPct()
{
	switch (SightRange)
	{
	case ESightRange_Short:
		return 0.3f;
		break;
	case ESightRange_Medium:
		return 0.6f;
		break;
	case ESightRange_Long:
		return 0.9f;
		break;
	}

	return 0.6f;
}

defaultproperties
{
	Begin Object NAME=Sprite
	Sprite=Texture2D'LayerIcons.Editor.world_narrative'
	Scale=0.25
	End Object

	SightRange=ESightRange_Medium
	bPlayEvenIfInterrupted=false

	Layer=Markup
}