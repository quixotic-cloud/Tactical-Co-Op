//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ToggleHUDElements.uc
//  AUTHOR:  Ryan Baker  --  03/05/2012
//  PURPOSE: Implements a Kismet sequence action that can hide HUD Elements.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_ToggleHUDElements extends SequenceAction;

enum eHUDElement
{
	eHUDElement_InfoBox,
	eHUDElement_Abilities,
	eHUDElement_WeaponContainer,
	eHUDElement_StatsContainer,
	eHUDElement_Perks,
	eHUDElement_MouseControls,
	eHUDElement_Countdown
};

var() array<eHUDElement> HudElements;

defaultproperties
{
	ObjCategory="Toggle"
	ObjName="Toggle HUD Elements"
	bCallHandler=true

	InputLinks(0)=(LinkDesc="Hide")
	InputLinks(1)=(LinkDesc="UnHide")
}
