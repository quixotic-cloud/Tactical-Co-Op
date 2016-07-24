//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_GetTaggedActorLocation.uc
//  AUTHOR:  David Burchanowski  --  1/28/2015
//  PURPOSE: Allows the LDs to get the location of hand placed actors in the map.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_GetTaggedActorLocation extends SequenceAction
	native;

var string ActorTag;
var vector Location;

cpptext
{
	virtual void Activated();
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Get Tagged Actor Location"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Actor Tag",PropertyName=ActorTag)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Location",PropertyName=Location,bWriteable=TRUE)
}