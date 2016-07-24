class SeqAct_PlayNextDialogueLine extends SeqAct_Latent;

var Actor FaceFxTarget;

event Activated()
{
	local XComPlayerController kController;

	foreach GetWorldInfo().AllControllers(class'XComPlayerController', kController)
	{
		break;	
	}

	if (kController != none)
	{
		kController.Pres.m_kNarrativeUIMgr.NextDialogueLine(FaceFxTarget);
	}   	
}

defaultproperties
{
	ObjCategory="Sound"
	ObjName="Dialogue - Play Next Line"

	InputLinks(0)=(LinkDesc="Play")
	OutputLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="FaceFxTarget",PropertyName=FaceFxTarget)
}