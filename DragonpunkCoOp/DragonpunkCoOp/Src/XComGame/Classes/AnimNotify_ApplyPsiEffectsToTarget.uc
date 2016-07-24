class AnimNotify_ApplyPsiEffectsToTarget extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return TEXT("ApplyPsiTargetEffects"); }
	virtual FColor GetEditorColor() { return FColor(150,150,255); }
}

defaultproperties
{
}
