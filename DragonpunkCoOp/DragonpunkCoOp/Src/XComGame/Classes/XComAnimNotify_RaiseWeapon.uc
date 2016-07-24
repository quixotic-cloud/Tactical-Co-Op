//-----------------------------------------------------------
// FIRAXIS GAMES: Raise Weapon Notify
//
// Tell us when we can raise the weapon if we decide to
// (c) 2008 Firaxis Games
//-----------------------------------------------------------
class XComAnimNotify_RaiseWeapon extends AnimNotify
	native(Animation);

var() float BlendTime;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "RaiseWeapon"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{
	BlendTime = 0.1;
}
