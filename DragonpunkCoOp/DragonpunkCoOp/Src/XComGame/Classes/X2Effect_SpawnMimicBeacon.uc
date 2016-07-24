class X2Effect_SpawnMimicBeacon extends X2Effect_SpawnUnit;

function vector GetSpawnLocation(const out EffectAppliedData ApplyEffectParameters)
{

	if(ApplyEffectParameters.AbilityInputContext.TargetLocations.Length == 0)
	{
		`Redscreen("Attempting to create X2Effect_SpawnMimicBeacon without a target location! @dslonneger");
		return vect(0,0,0);
	}

	return ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
}

// Get the team that this unit should be added to
function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetSourceUnitsTeam(ApplyEffectParameters);
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit MimicBeaconGameState, SourceUnitGameState;
	local array<XComGameState_Item> SourceInventory;
	local XComGameState_Item InventoryItem, CopiedInventoryItem;
	local X2ItemTemplate ItemTemplate;

	MimicBeaconGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	`assert(MimicBeaconGameState != none);

	SourceUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( SourceUnitGameState == none)
	{
		SourceUnitGameState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID, eReturnType_Reference));
	}
	`assert(SourceUnitGameState != none);

	SourceInventory = SourceUnitGameState.GetAllInventoryItems(, true);
	foreach SourceInventory(InventoryItem)
	{
		if (InventoryItem.bMergedOut)
		{
			continue;
		}
		
		ItemTemplate = InventoryItem.GetMyTemplate();
		CopiedInventoryItem = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
		MimicBeaconGameState.AddItemToInventory(CopiedInventoryItem, InventoryItem.InventorySlot, NewGameState);
		NewGameState.AddStateObject(CopiedInventoryItem);
	}


	// Make sure the mimic doesn't spawn with any action points this turn
	MimicBeaconGameState.ActionPoints.Length = 0;

	// UI update happens in quite a strange order when squad concealment is broken.
	// The unit which threw the mimic beacon will be revealed, which should reveal the rest of the squad.
	// The mimic beacon won't be revealed properly unless it's considered to be concealed in the first place.
	if (SourceUnitGameState.IsSquadConcealed())
		MimicBeaconGameState.SetIndividualConcealment(true, NewGameState); //Don't allow the mimic beacon to be non-concealed in a concealed squad.
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationTrack SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationTrack EffectTargetUnitTrack)
{
	local X2Action_CreateDoppelganger CopyUnitAction;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Copy the thrower unit's appearance to the mimic
	CopyUnitAction = X2Action_CreateDoppelganger(class'X2Action_CreateDoppelganger'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context));
	CopyUnitAction.OriginalUnit = XGUnit(History.GetVisualizer(EffectTargetUnit.ObjectID));
	CopyUnitAction.ShouldCopyAppearance = true;
	CopyUnitAction.bReplacingOriginalUnit = false;
}

defaultproperties
{
	UnitToSpawnName="MimicBeacon"
	bCopyTargetAppearance=true
	bKnockbackAffectsSpawnLocation=false
	EffectName="SpawnMimicBeacon"
}