//---------------------------------------------------------------------------------------
//  FILE:    AnimNotify_CosmeticUnit.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class AnimNotify_CosmeticUnit extends AnimNotify
	native(Animation);

var() private name AnimationName;
var() private bool Looping;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Cosmetic Unit"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{

}