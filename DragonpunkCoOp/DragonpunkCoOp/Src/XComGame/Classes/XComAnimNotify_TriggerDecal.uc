//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComAnimNotify_TriggerDecal extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Fire Decal Projectile"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

function native NotifyUnit( XComUnitPawnNativeBase XComPawn );