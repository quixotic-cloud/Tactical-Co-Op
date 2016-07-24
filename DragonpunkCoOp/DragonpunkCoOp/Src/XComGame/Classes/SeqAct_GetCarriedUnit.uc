//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_GetCarriedUnit.uc
//  AUTHOR:  David Burchanowski  --  6/15/2016
//  PURPOSE: Gets the unit carried by another unit, if any
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_GetCarriedUnit extends SequenceAction;

var XComGameState_Unit Unit;
var XComGameState_Unit CarriedUnit;

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState_Effect BeingCarriedEffect;

	History = `XCOMHISTORY;

	if(Unit == none)
	{
		`Redscreen("SeqAct_GetCarriedUnit: No unit specified.");
		CarriedUnit = none;
		OutputLinks[0].bHasImpulse = true;
	}

	// find the unit we are carrying, if any
	BeingCarriedEffect = Unit.GetUnitApplyingEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
	if(BeingCarriedEffect != none)
	{
		CarriedUnit = XComGameState_Unit(History.GetGameStateForObjectId(BeingCarriedEffect.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	}
	else
	{
		CarriedUnit = none;
	}

	OutputLinks[0].bHasImpulse = CarriedUnit == none;
	OutputLinks[1].bHasImpulse = !OutputLinks[0].bHasImpulse;
}

defaultproperties
{
	ObjCategory = "Unit"
	ObjName = "Get Carried Unit"

	bConvertedForReplaySystem = true
	bCanBeUsedForGameplaySequence = true

	bAutoActivateOutputLinks = false

	OutputLinks(0)=(LinkDesc="No Carry")
	OutputLinks(1)=(LinkDesc="Has Carry")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit', LinkDesc="Unit", PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit', LinkDesc="Carried Unit", PropertyName=CarriedUnit, bWriteable=true)
}
