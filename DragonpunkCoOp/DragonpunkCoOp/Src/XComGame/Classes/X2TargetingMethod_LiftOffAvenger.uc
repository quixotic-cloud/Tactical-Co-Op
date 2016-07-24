//---------------------------------------------------------------------------------------
//  FILE:    X2TargetingMethod_LiftOffAvenger.uc
//  AUTHOR:  David Burchanowski  --  8/04/2014
//  PURPOSE: Specialized targeting method to ensure that no units remain in the evac zone before activating
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_LiftOffAvenger extends X2TargetingMethod_TopDown
	config(GameCore);

var private localized string UnitsInDangerTitle;
var private localized string UnitsInDangerBody;
var private localized string AcceptMessage;
var private localized string CancelMessage;

// the actor tag of the dropzone volume
var private const config name DropzoneTag;

// path to the narrative we should play if there is a unit outside the dropzone
var private const config string WarnSoldiersOutsideDropzoneNarrativePath;

// keep track of whether we've been through the confirm dialog
var private bool Confirmed;

// true if there are soldiers outside the dropzone that will be captured if we end the mission here
var private bool SoldiersOutsideDropzone;

function Init(AvailableAction InAction)
{
	local XComNarrativeMoment WarnSoldiersOutsideDropzoneNarrative;

	super.Init(InAction);

	SoldiersOutsideDropzone = ComputeSoldiersOutsideDropzone();

	if(SoldiersOutsideDropzone)
	{
		// if there are currently soldiers outside the dropzone, play a VO to let the player know that they will be lost
		WarnSoldiersOutsideDropzoneNarrative = XComNarrativeMoment(DynamicLoadObject(WarnSoldiersOutsideDropzoneNarrativePath, class'XComNarrativeMoment'));
		if(WarnSoldiersOutsideDropzoneNarrative != none)
		{
			`PRESBASE.UINarrative(WarnSoldiersOutsideDropzoneNarrative);
		}
	}

	DirectSetTarget(0);
}

function Canceled()
{
	super.Canceled();
}

function Committed()
{
	Canceled();
}

function Update(float DeltaTime);

static function Volume FindDropzoneVolume()
{
	local Volume DropzoneVolume;

	// find the drop zone volume
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'Volume', DropzoneVolume)
	{
		if(DropzoneVolume.Tag == default.DropzoneTag)
		{
			return DropzoneVolume;
		}
	}

	return none;
}

simulated private function ConfirmLiftoff(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Confirmed = true;
		m_fnConfirmAbilityCallback();
	}

	Confirmed = false;
}

simulated private function bool ComputeSoldiersOutsideDropzone()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;

	local Volume DropzoneVolume;
	local XComGameState_Unit CheckUnitState;
	local vector UnitLocation;

	local XComGameState_Effect TestEffect;
	local XComGameState_Unit Carrier;

	DropzoneVolume = FindDropzoneVolume();
	if(DropzoneVolume == none)
	{
		// if no dropzone volume exists, then just bail
		`Redscreen("Could not find a dropzone volume to lift off from!");
		return false;
	}

	// check if any units are currently in the evac zone. We could compute this in advance, but since there are already a ton
	// of things happening when you raise the shot hud, rather than add to that frame just to it here.

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	foreach History.IterateByClassType(class'XComGameState_Unit', CheckUnitState)
	{
		if(CheckUnitState.GetTeam() == eTeam_XCom 
			&& !CheckUnitState.IsDead() 
			&& !CheckUnitState.bRemovedFromPlay
			&& !CheckUnitState.IsTurret())
		{
			UnitLocation = WorldData.GetPositionFromTileCoordinates(CheckUnitState.TileLocation);

			TestEffect = CheckUnitState.GetUnitAffectedByEffectState( class'X2AbilityTemplateManager'.default.BeingCarriedEffectName );
			if (TestEffect != None)
			{
				Carrier = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( TestEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID ) );
				UnitLocation = WorldData.GetPositionFromTileCoordinates(Carrier.TileLocation);
			}

			
			if(!DropzoneVolume.EncompassesPoint(UnitLocation))
			{
				return true;
			}
		}
	}

	return false;
}

function bool VerifyTargetableFromIndividualMethod(delegate<ConfirmAbilityCallback> fnCallback)
{
	local TDialogueBoxData kDialogData;
	local XComPresentationLayerBase PresBase;

	if (SoldiersOutsideDropzone && !Confirmed)
	{
		m_fnConfirmAbilityCallback = fnCallback;
		PresBase = XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres;

		kDialogData.eType = eDialog_Warning;
		kDialogData.strTitle = UnitsInDangerTitle;
		kDialogData.strText = UnitsInDangerBody;
		kDialogData.strAccept = AcceptMessage;
		kDialogData.strCancel = CancelMessage;
		kDialogData.fnCallback = ConfirmLiftoff;

		PresBase.UIRaiseDialog(kDialogData);

		return false;
	}

	return true;
}


