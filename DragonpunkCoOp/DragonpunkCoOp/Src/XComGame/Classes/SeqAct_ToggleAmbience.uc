class SeqAct_ToggleAmbience extends SequenceAction;

event Activated()
{
	local XComTacticalSoundManager SoundMgr;

	SoundMgr = XComTacticalSoundManager(`SOUNDMGR);

	if (InputLinks[0].bHasImpulse)
	{
		SoundMgr.StartAllAmbience();
	}
	else
	{
		SoundMgr.StopAllAmbience();
	}
}

defaultproperties
{
	ObjCategory="Sound"
	ObjName="Toggle Ambience"
	bCallHandler=true

	InputLinks(0)=(LinkDesc="Play")
	InputLinks(1)=(LinkDesc="Stop")
}