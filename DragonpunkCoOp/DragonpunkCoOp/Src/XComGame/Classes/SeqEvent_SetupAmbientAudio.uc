//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_SetupAmbientAudio.uc
//  AUTHOR:  David Burchanowski  --  2/11/2014
//  PURPOSE: Simple hook event for the audio guys to hook up their sound with
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

/// Note: This is a latent event. No gameplay stuff should be chained to it.
class SeqEvent_SetupAmbientAudio extends SequenceEvent;

event Activated()
{
	OutputLinks[0].bHasImpulse = true;
}

defaultproperties
{
	ObjCategory="Audio"
	ObjName="Setup Ambient Audio"
	bPlayerOnly=FALSE
	MaxTriggerCount=0	

	OutputLinks(0)=(LinkDesc="Out")
}
