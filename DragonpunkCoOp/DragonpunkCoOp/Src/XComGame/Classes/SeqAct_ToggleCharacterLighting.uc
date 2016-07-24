/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class SeqAct_ToggleCharacterLighting extends SequenceAction;

/** Delete objects we don't want to keep around during cinematics */
event Activated()
{
	if (InputLinks[0].bHasImpulse)
	{
		`XENGINE.SetCharacterLightRigsEnabled(true);
	}
	else if (InputLinks[1].bHasImpulse)
	{
		`XENGINE.SetCharacterLightRigsEnabled(false);
	}
}


defaultproperties
{
	ObjName="Toggle Character Lighting"
	ObjCategory="Toggle"

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")
}
