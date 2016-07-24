//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_SaveLoadData.uc
//  AUTHOR:  Ryan McFall  --  02/06/2012
//  PURPOSE: This object's purpose is to facilitate saving and loading data to kismet variables
//           At present, all that needs to be done is to add one of these objects to the
//           kismet sequence and all your wildest dreams will come true. 
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_SaveLoadData extends SequenceAction native(Level);

event Activated(){}

defaultproperties
{
	ObjCategory="!GAMEPLAY REQUIRED!"
	ObjName="Save Load Data"
	bCallHandler = false;
}
