class X2Effect_SpawnFaceless extends X2Effect_SpawnUnit;

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit CivUnitGameState;
	local XComGameState_Unit FacelessGameState;
	local int CivLifeLost;
	local EffectAppliedData ScanningData;
	local X2Effect_ScanningProtocol ScanningEffect;
	local XComGameState_Effect ScanningEffectState;

	CivUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( CivUnitGameState == none)
	{
		CivUnitGameState = XComGameState_Unit(NewGameState.CreateStateObject( class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID ));
		NewGameState.AddStateObject( CivUnitGameState );
	}
	`assert(CivUnitGameState != none);

	FacelessGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	`assert(FacelessGameState != none);

	// Do the state changes of removing it from the board
	CivUnitGameState.RemoveStateFromPlay( );

	CivLifeLost = CivUnitGameState.GetCurrentStat(eStat_HP) - CivUnitGameState.GetMaxStat(eStat_HP);
	FacelessGameState.ModifyCurrentStat(eStat_HP, CivLifeLost);

	//  carry scanning protocol forward if necessary
	ScanningEffectState = CivUnitGameState.GetUnitAffectedByEffectState(class'X2Effect_ScanningProtocol'.default.EffectName);
	if (ScanningEffectState != none)
	{
		//  need to apply the scanning protocol effect to this unit
		ScanningData = ScanningEffectState.ApplyEffectParameters;
		ScanningData.EffectRef.TemplateEffectLookupArrayIndex = 0;          //  civilian is affected by multi target effect index 1			
		ScanningEffect = X2Effect_ScanningProtocol(class'X2Effect'.static.GetX2Effect(ScanningData.EffectRef));
		if (ScanningEffect != none)
		{
			ScanningEffect.ApplyEffect(ScanningData, FacelessGameState, NewGameState);
		}
		else
		{
			`RedScreenOnce("Scanning Protocol effect not present on the ability template...? -jbouscher @gameplay");
		}
	}

	// Remove the civilian unit from play
	`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', CivUnitGameState, CivUnitGameState, NewGameState);
}

// Get the team that this unit should be added to
function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	// NOTE: This effect is currently for single player, which means the 
	// Faceless unit will always be put on the alien team. If this is to 
	// be used with an ability in MP, then this needs to change to decide
	// whose team the Faceless will span onto.
	return eTeam_Alien;
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationTrack SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationTrack EffectTargetUnitTrack)
{
	local XComGameStateHistory History;
	local X2Action_FacelessChangeForm FacelessAction;
	local X2Action_UnitToFacelessChangeForm UnitChangeAction;
	local X2Action_UpdateScanningProtocolOutline OutlineAction;

	History = `XCOMHISTORY;

	// Civilian unit actions
	`assert(EffectTargetUnitTrack.StateObject_NewState != none);

	UnitChangeAction = X2Action_UnitToFacelessChangeForm(class'X2Action_UnitToFacelessChangeForm'.static.AddToVisualizationTrack(EffectTargetUnitTrack, Context));
	UnitChangeAction.FacelessUnitReference = SpawnedUnit.GetReference();

	// The Target is the original unit so have it wait so its cin camera doesn't end
	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(EffectTargetUnitTrack, Context);

	// The Spawned unit should appear and play its change animation
	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context);

	if (SpawnedUnit.IsUnitAffectedByEffectName(class'X2Effect_ScanningProtocol'.default.EffectName))
	{
		OutlineAction = X2Action_UpdateScanningProtocolOutline(class'X2Action_UpdateScanningProtocolOutline'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context));
		OutlineAction.bEnableOutline = true;
	}

	FacelessAction = X2Action_FacelessChangeForm(class'X2Action_FacelessChangeForm'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context));
	FacelessAction.SourceUnit = XGUnit(History.GetVisualizer(EffectTargetUnit.ObjectID));
}

defaultproperties
{
	UnitToSpawnName="Faceless"
	bClearTileBlockedByTargetUnitFlag=true

	DuplicateResponse=eDupe_Ignore
}