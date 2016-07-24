class SeqAct_EndDialogue extends SeqAct_Latent;

event Activated()
{
	local XComPlayerController kController;

	foreach GetWorldInfo().AllControllers(class'XComPlayerController', kController)
	{
		break;	
	}

	if (kController != none)
	{
		`log("SeqAct_EndDialogue::Activated",,'XComNarrative');
		kController.Pres.m_kNarrativeUIMgr.EndCurrentConversation();
	}   	

	OutputLinks[0].bHasImpulse = TRUE;
}

defaultproperties
{
	ObjCategory="Sound"
	ObjName="Dialogue - End"
}