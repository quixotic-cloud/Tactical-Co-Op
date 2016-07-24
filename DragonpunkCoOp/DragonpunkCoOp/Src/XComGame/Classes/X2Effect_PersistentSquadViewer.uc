class X2Effect_PersistentSquadViewer extends X2Effect_Persistent;

var bool bUseWeaponRadius;      //  Expects source weapon to exist and to use its radius for the viewer's sight.
var float ViewRadius;
var bool bUseSourceLocation;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit SourceUnit;
	local XComGameState_SquadViewer ViewerState;
	local XComGameState_Item SourceWeaponState;
	local XComGameState_Ability AbilityState;
	local Vector ViewerLocation;
	local TTile ViewerTile;

	History = `XCOMHISTORY;
	// sanity check the incoming data
	if (bUseSourceLocation)
	{
		SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		if (SourceUnit == none)
		{
			`Redscreen("Attempting to create X2Effect_PersistentSquadViewer with no source unit! -jbouscher @gameplay");
			return;
		}
		ViewerTile = SourceUnit.TileLocation;
	}	
	else
	{
		if(ApplyEffectParameters.AbilityInputContext.TargetLocations.Length == 0)
		{
			`Redscreen("Attempting to create X2Effect_PersistentSquadViewer without a target location! -jbouscher @gameplay");
			return;
		}
		ViewerLocation = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
		ViewerTile = `XWORLD.GetTileCoordinatesFromPosition(ViewerLocation);
	}

	// create the viewer state
	ViewerState = XComGameState_SquadViewer(NewGameState.CreateStateObject(class'XComGameState_SquadViewer'));
	`assert(ViewerState != none);
	
	// fill it out
	ViewerState.AssociatedPlayer = ApplyEffectParameters.PlayerStateObjectRef;		
	ViewerState.SetVisibilityLocation(ViewerTile);

	if (bUseWeaponRadius)
	{
		SourceWeaponState = XComGameState_Item(History.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
		`assert(SourceWeaponState != none);
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		`assert(AbilityState != none);
		//  weapon radius is meters, but the viewer expects tiles
		ViewerState.ViewerRadius = SourceWeaponState.GetItemRadius(AbilityState) * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize;
	}	
	else
	{
		ViewerState.ViewerRadius = ViewRadius;
	}

	NewGameState.AddStateObject(ViewerState);

	// save a reference to the object we just created, so that we can remove it later
	NewEffectState.CreatedObjectReference = ViewerState.GetReference();
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_SquadViewer Viewer;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	Viewer = XComGameState_SquadViewer(History.GetGameStateForObjectID(RemovedEffectState.CreatedObjectReference.ObjectID));	

	if(Viewer == none)
	{
		`Redscreen("X2Effect_PersistentSquadViewer::OnEffectRemoved: Could not find associated viewer object to remove!");
		return;
	}

	NewGameState.RemoveStateObject(RemovedEffectState.CreatedObjectReference.ObjectID);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Effect EffectState, VisualizeEffect;
	local XComGameState_SquadViewer SquadViewer;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.GetX2Effect() == self)
		{
			VisualizeEffect = EffectState;
			break;
		}
	}
	if (VisualizeEffect == none)
	{
		`RedScreen("Could not find Squad Viewer effect - FOW will not be lifted. Author: jbouscher Contact: @gameplay");
		return;
	}
	SquadViewer = XComGameState_SquadViewer(VisualizeGameState.GetGameStateForObjectID(EffectState.CreatedObjectReference.ObjectID));
	if (SquadViewer == none)
	{
		`RedScreen("Could not find Squad Viewer game state - FOW will not be lifted. Author: jbouscher Contact: @gameplay");
		return;
	}
	SquadViewer.FindOrCreateVisualizer(VisualizeGameState);
	SquadViewer.SyncVisualizer(VisualizeGameState);     //  @TODO - use an action instead, but the incoming track will not have the right object to sync
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local XComGameState_SquadViewer SquadViewer;
	local X2Action_AbilityPerkDurationEnd PerkEnded;

	SquadViewer = XComGameState_SquadViewer(`XCOMHISTORY.GetGameStateForObjectID(RemovedEffect.CreatedObjectReference.ObjectID));
	if (SquadViewer != none)
	{
		SquadViewer.DestroyVisualizer();        //  @TODO - use an action instead
	}

	PerkEnded = X2Action_AbilityPerkDurationEnd( class'X2Action_AbilityPerkDurationEnd'.static.AddToVisualizationTrack( BuildTrack, VisualizeGameState.GetContext() ) );
	PerkEnded.EndingEffectState = RemovedEffect;
}

DefaultProperties
{
	bUseWeaponRadius = true;
}