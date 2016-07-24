//-----------------------------------------------------------
// FIRAXIS GAMES: Lower Weapon Notify
//
// Tell us when we can lower the weapon if we decide to
// (c) 2008 Firaxis Games
//-----------------------------------------------------------
class XComAnimNotify_LowerWeapon extends AnimNotify
	native(Animation);

var() float BlendTime;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "LowerWeapon"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{
	BlendTime = 0.1;
}
