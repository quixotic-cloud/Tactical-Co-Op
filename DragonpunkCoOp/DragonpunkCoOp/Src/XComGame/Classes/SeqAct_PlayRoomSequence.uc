//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_PlayRoomSequence.uc
//  AUTHOR:  Ryan Baker  --  03/05/2012
//  PURPOSE: Implements a Kismet sequence action that can play room sequences.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_PlayRoomSequence extends SequenceAction;

var() string RoomName;

event Activated()
{
	class'SeqEvent_HQUnits'.static.PlayRoomSequence(RoomName);
	`log("Playing Room !!!!!"@RoomName);
}

defaultproperties
{
	ObjCategory="Cinematic"
	ObjName="Play Room Sequence"
	bCallHandler=false

	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="RoomName",PropertyName=RoomName)
}
