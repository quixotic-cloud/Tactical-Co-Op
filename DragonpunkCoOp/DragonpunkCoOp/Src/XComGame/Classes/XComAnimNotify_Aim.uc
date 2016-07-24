//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNotify_Aim extends AnimNotify
	native(Animation);

var() bool Enable;
var() Name ProfileName;
var() Name SocketOrBone;
var() float BlendTime; // In Seconds
var() bool ShouldTurn;

native function ManualTrigger(XComUnitPawnNativeBase UnitPawn, AnimNodeSequence NodeSeq);

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment();
	virtual FColor GetEditorColor() { return FColor(0,128,255); }
	UBOOL TestForWeapon(class UXComGameState_Item* WeaponState, class UAnimNodeSequence* NodeSeq);
}

defaultproperties
{
	Enable = true;
	ProfileName = SoldierRifle;
	SocketOrBone = AimOrigin;
	BlendTime = 0.3f;
	ShouldTurn = false;
}
