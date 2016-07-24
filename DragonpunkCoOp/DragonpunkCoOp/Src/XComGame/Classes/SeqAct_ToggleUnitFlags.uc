//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ToggleUnitFlags.uc
//  AUTHOR:  Ryan Baker  --  03/05/2012
//  PURPOSE: Implements a Kismet sequence action that can hide Flag Elements.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_ToggleUnitFlags extends SequenceAction;

defaultproperties
{
	ObjCategory="Toggle"
	ObjName="Toggle Unit Flags"
	bCallHandler=true

	InputLinks(0)=(LinkDesc="Show")
	InputLinks(1)=(LinkDesc="Hide")
}
