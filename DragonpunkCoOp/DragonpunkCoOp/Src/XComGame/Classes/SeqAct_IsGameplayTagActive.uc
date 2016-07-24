///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_IsGameplayTagActive.uc
//  AUTHOR:  Dan Kaplan  --  8/17/15
//  PURPOSE: Action to determine if a gameplay tag is currently active
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_IsGameplayTagActive extends SequenceAction;

var() Name TagToQuery; // The tag that we are check to see if it is present

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if( XComHQ != None && XComHQ.TacticalGameplayTags.Find(TagToQuery) != INDEX_NONE )
	{
		OutputLinks[0].bHasImpulse = true;
		OutputLinks[1].bHasImpulse = false;
	}
	else
	{
		OutputLinks[0].bHasImpulse = false;
		OutputLinks[1].bHasImpulse = true;
	}
}

defaultproperties
{
	ObjName="Is Gameplay Tag Active"
	ObjCategory="Scripting"
	bCallHandler=false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	OutputLinks(0)=(LinkDesc="Yes")
	OutputLinks(1)=(LinkDesc="No")
}