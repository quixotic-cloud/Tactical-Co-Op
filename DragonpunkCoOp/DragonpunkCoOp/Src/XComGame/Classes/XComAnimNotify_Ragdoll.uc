//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNotify_Ragdoll extends AnimNotify
	native(Animation);

var() vector TranslationImpulse;
var() vector RotationImpulse;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Ragdoll"; }
	virtual FColor GetEditorColor() { return FColor(0,128,255); }
}

defaultproperties
{
	TranslationImpulse = (X = 0, Y = 0, Z = 0)
	RotationImpulse = (X = 0, Y = 0, Z = 0)
}