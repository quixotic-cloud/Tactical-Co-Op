//---------------------------------------------------------------------------------------
//  FILE:    X2SquadVisiblePoint.uc
//  AUTHOR:  David Burchanowski  --  7/6/2015
//  PURPOSE: Actor the LDs can place in the world to provide visiblity triggers for scripting
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2SquadVisiblePoint extends PointInSpace
	placeable;

var() const name RemoteEventToTrigger;

var() const bool XComTriggers;  
var() const bool AliensTrigger;  
var() const bool CiviliansTrigger;
var() const int MaxTriggerCount;

function CreateState(XComGameState StartGameState)
{
	local XComGameStateHistory History;
	local XComGameState_SquadVisiblePoint ObjectState;

	// if it doesn't exist, then we need to create it
	History = `XCOMHISTORY;

	// make sure this is the start state. These should only ever be created at start state!
	`assert(StartGameState == History.GetStartState());
	if(StartGameState == none)
	{
		return;
	}
	
	ObjectState = XComGameState_SquadVisiblePoint(StartGameState.CreateStateObject(class'XComGameState_SquadVisiblePoint'));

	ObjectState.SetInitialState(self);
	StartGameState.AddStateObject(ObjectState);

	// we don't need to set ourself as the visualizer for this state. We exist solely as fire-and-forget markup so that
	// LDs can put the visiblility triggers in the world
}

defaultproperties
{
	Begin Object NAME=Sprite
		Sprite=Texture2D'LayerIcons.squad_visible'
		Scale=0.25
	End Object

	XComTriggers=true
	MaxTriggerCount=1
	Layer=Markup
}