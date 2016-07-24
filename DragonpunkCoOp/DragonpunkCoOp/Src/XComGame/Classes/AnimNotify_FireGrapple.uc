class AnimNotify_FireGrapple extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return TEXT("Fire Grapple"); }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{
	
}
