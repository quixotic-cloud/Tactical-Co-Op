//-----------------------------------------------------------
// FIRAXIS GAMES: Play Socket Anim Notify
//
// Allows Socketed items to play animations via a notify
// (c) 2008 Firaxis Games
//-----------------------------------------------------------
class XComAnimNotify_PlaySocketAnim extends AnimNotify
	native(Animation);

var() Name AnimName;
var() Name SocketName;
var() bool Looping;
var() bool Additive;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "SocketAnim"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{
	Looping = false
	Additive = false
}
