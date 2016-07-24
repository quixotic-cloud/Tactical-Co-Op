//---------------------------------------------------------------------------------------
//  FILE:    AnimNotify_CinescriptEvent.uc
//  AUTHOR:  David Burchanowski  --  7/1/2014
//  PURPOSE: Allows animation to drive camera cuts in cinescript camera sequences
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class AnimNotify_CinescriptEvent extends AnimNotify
	native(Animation);

var() private string EventLabel;

cpptext
{
	// AnimNotify interface.
	virtual void Notify(class UAnimNodeSequence* NodeSeq);
	virtual FString GetEditorComment();
	virtual FColor GetEditorColor() { return FColor(244,232,164); }
}

defaultproperties
{
}
