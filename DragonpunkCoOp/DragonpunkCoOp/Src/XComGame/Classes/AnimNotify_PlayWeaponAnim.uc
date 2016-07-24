//-----------------------------------------------------------
// FIRAXIS GAMES: Play Weapon Anim notify
//
// Allows Weapons to play animations via a notify
// (c) 2008 Firaxis Games
//-----------------------------------------------------------
class AnimNotify_PlayWeaponAnim extends AnimNotify
	native(Animation);

var() Name AnimName;
var() bool Looping;
var() bool Additive;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "WeaponAnim"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{
	Looping = false
	Additive = false
}
