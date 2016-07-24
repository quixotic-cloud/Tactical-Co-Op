//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_EvacZoneDestroyed.uc
//  AUTHOR:  Russell Aasland  --  7/11/2015
//  PURPOSE: Event for handling when an evac zone is destroyed
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_EvacZoneDestroyed extends SeqEvent_GameEventTriggered;

var() private ETeam Team;

function EventListenerReturn EventTriggered( Object EventData, Object EventSource, XComGameState GameState, Name InEventID )
{
	local XComGameState_EvacZone EvacZone;

	EvacZone = XComGameState_EvacZone( EventSource );

	if (EvacZone.Team == Team)
	{
		CheckActivate( EvacZone.GetVisualizer(), none );
	}

	return ELR_NoInterrupt;
}

defaultproperties
{
	ObjName="Evac Zone Destroyed"
	EventID="EvacZoneDestroyed"
}
