//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNotify_FixupBegin extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual FString GetEditorComment() { return "Fixup Begin"; }
	virtual FColor GetEditorColor() { return FColor(0,128,255); }
}
