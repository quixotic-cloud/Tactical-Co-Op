class SeqAct_GetSoundManager extends SequenceAction;

var XComSoundManager SoundMgr;

event Activated()
{
	local XComTacticalGRI TacticalGRI;
	
	SoundMgr = `SOUNDMGR;
	if(SoundMgr == none)
	{
		//If there isn't a sound manager, make one
		TacticalGRI = `TACTICALGRI;
		if(`TACTICALGRI != none)
		{
			TacticalGRI.SoundManager = class'WorldInfo'.static.GetWorldInfo().Spawn(TacticalGRI.SoundManagerClassToSpawn, TacticalGRI);
			TacticalGRI.SoundManager.Init();
		}
	}
}

defaultproperties
{
	ObjName="Get Sound Manager"
	ObjCategory="Sound"
	bCallHandler=false
	bAutoActivateOutputLinks=true
	
	bConvertedForReplaySystem = true
	bCanBeUsedForGameplaySequence = true

	VariableLinks.Empty;	
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="SoundMgr",PropertyName=SoundMgr,bWriteable=true)
}