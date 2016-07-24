//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNotify_LookAt extends AnimNotify
	native(Animation);

var() float Weight;
var() float BlendTime; // In Seconds

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Look At"; }
	virtual FColor GetEditorColor() { return FColor(0,128,255); }
}

defaultproperties
{
	Weight = 1.0f;
	BlendTime = 0.3f;
}
