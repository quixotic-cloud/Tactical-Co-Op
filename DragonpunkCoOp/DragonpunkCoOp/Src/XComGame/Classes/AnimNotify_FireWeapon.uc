//-----------------------------------------------------------
// FIRAXIS GAMES: Fire Weapon notify
//
// Allows Weapon Firing to be triggered from a
// notify placed in the AnimSet editor
// (c) 2008 Firaxis Games
//-----------------------------------------------------------
class AnimNotify_FireWeapon extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Fire"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{

}
