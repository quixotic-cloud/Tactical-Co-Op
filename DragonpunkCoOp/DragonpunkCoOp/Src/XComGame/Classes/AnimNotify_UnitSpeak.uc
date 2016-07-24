
class AnimNotify_UnitSpeak extends AnimNotify
	native(Animation)
	dependson(XGGameData);

var() name SpeechEvent;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Speak"; }
	virtual FColor GetEditorColor() { return FColor(0,0,255); }
}

defaultproperties
{
}
