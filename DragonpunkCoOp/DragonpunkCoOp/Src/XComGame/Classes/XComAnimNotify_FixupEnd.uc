//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNotify_FixupEnd extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual FString GetEditorComment() { return "Fixup End"; }
	virtual FColor GetEditorColor() { return FColor(0,128,255); }
}
