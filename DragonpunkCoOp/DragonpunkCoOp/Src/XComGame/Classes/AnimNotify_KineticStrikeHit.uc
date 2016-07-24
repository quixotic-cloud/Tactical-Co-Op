class AnimNotify_KineticStrikeHit extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return TEXT("KineticStrikeHit"); }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{

}
