class SeqAct_ToggleFOW extends SequenceAction;

var bool bToggle;

event Activated()
{	
	`XWORLD.InitializeAllViewersToHaveSeenFog(bToggle);
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Reveal Map"
	bCallHandler=false
	
	VariableLinks(0)=(ExpectedType=class'SeqVar_Bool',LinkDesc="Reveal Map ( FOW Never Seen to Have Seen )",PropertyName=bToggle)
}

