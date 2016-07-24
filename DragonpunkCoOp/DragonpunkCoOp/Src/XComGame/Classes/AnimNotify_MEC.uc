
class AnimNotify_MEC extends AnimNotify
	native(Animation);

enum EMECEvent
{
	eMEC_LegMove,
	eMEC_ArmMove,
	eMEC_HandThud,
	eMEC_BodyThud,
	eMEC_TakeDamage,
	eMEC_Footstep,
};

var() EMECEvent Event;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment();
	virtual FColor GetEditorColor() { return FColor(0,255,0); }
}

defaultproperties
{
	
}