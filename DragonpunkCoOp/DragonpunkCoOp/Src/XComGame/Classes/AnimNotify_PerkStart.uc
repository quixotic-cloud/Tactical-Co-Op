//-----------------------------------------------------------
// FIRAXIS GAMES: Perk Start anim notify
//
// Allows perk effects to be triggered from a
// notify placed in the AnimSet editor
// (c) 2008 Firaxis Games
//-----------------------------------------------------------
class AnimNotify_PerkStart extends AnimNotify
	native(Animation);

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Start Perk Activations"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{

}
