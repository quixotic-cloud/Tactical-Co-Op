//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNotify_NotifyTarget extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Unit Hit"; }
	virtual FColor GetEditorColor() { return FColor(0,128,255); }
}
