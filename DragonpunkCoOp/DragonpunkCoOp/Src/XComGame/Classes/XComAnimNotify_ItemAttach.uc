//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNotify_ItemAttach extends AnimNotify
	native(Animation);

var() Name FromSocket;
var() Name ToSocket;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Item Attach"; }
	virtual FColor GetEditorColor() { return FColor(0,128,255); }
}
