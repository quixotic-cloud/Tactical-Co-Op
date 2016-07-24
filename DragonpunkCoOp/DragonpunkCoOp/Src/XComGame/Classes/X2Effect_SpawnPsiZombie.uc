class X2Effect_SpawnPsiZombie extends X2Effect_SpawnUnit;

var localized string ZombieFlyoverText;

var privatewrite name TurnedZombieName;

var name AnimationName;
var name AltUnitToSpawnName;
var float StartAnimationMinDelaySec;
var float StartAnimationMaxDelaySec;

function name GetUnitToSpawnName(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit TargetUnitState;
	local XComGameStateHistory History;
	local XComHumanPawn HumanPawn;
	local name UnitName;

	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`assert(TargetUnitState != none);

	UnitName = UnitToSpawnName;
	HumanPawn = XComHumanPawn(XGUnit(History.GetVisualizer(TargetUnitState.ObjectID)).GetPawn());
	if( HumanPawn != None )
	{
		UnitName = AltUnitToSpawnName;
	}

	return UnitName;
}

function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetSourceUnitsTeam(ApplyEffectParameters);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit DeadUnit;
	local XGUnit DeadUnitActor;
	local XComWorldData World;
	local TTile TileLocation;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	// Move the gamestate to the same position as the pawn
	DeadUnit = XComGameState_Unit(kNewTargetState);
	if( DeadUnit != none )
	{
		// TODO: This needs work. If a unit is standing on a building and ragdolls off
		// the sectoid cannot actually see the unit on the ground but instead sees
		// it on the roof. The visualizer also moves the unit upto the roof.
		World = `XWORLD;

		DeadUnitActor = XGUnit(DeadUnit.GetVisualizer());
		World.GetFloorTileForPosition(DeadUnitActor.Location, TileLocation);
		DeadUnit.SetVisibilityLocation(TileLocation);
	}
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit ZombieGameState, DeadUnitGameState;
	local bool bAddDeadUnit;
	local EffectAppliedData NewEffectParams;
	local X2Effect SireZombieEffect;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	ZombieGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	`assert(ZombieGameState != none);

	bAddDeadUnit = false;
	DeadUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( DeadUnitGameState == none )
	{
		bAddDeadUnit = true;
		DeadUnitGameState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	}
	`assert(DeadUnitGameState != none);

	if (DeadUnitGameState.bReadOnly)
	{
		`RedScreen("X2Effect_SpawnPsiZombie: This cannot run on a read only object: " $DeadUnitGameState.ObjectID);
	}

	// The zombie can't become a zombie once dead and save the dead unit's ref so it can be accessed later
	ZombieGameState.SetUnitFloatValue(TurnedZombieName, 1, eCleanup_BeginTactical);

	// Link the source and zombie
	NewEffectParams = ApplyEffectParameters;
	NewEffectParams.EffectRef.ApplyOnTickIndex = INDEX_NONE;
	NewEffectParams.EffectRef.LookupType = TELT_AbilityTargetEffects;
	NewEffectParams.EffectRef.SourceTemplateName = class'X2Ability_Sectoid'.default.SireZombieLinkName;
	NewEffectParams.EffectRef.TemplateEffectLookupArrayIndex = 0;
	NewEffectParams.TargetStateObjectRef = ZombieGameState.GetReference();

	SireZombieEffect = class'X2Effect'.static.GetX2Effect(NewEffectParams.EffectRef);
	`assert(SireZombieEffect != none);
	SireZombieEffect.ApplyEffect(NewEffectParams, ZombieGameState, NewGameState);

	// Don't allow the dead unit to become a zombie again
	DeadUnitGameState.SetUnitFloatValue(TurnedZombieName, 1, eCleanup_BeginTactical);

	// Remove the dead unit from play
	EventManager.TriggerEvent('UnitRemovedFromPlay', DeadUnitGameState, DeadUnitGameState, NewGameState);

	// Make sure the zombie doesn't spawn with any action points this turn
	ZombieGameState.ActionPoints.Length = 0;

	if( bAddDeadUnit )
	{
		NewGameState.AddStateObject(DeadUnitGameState);
	}

	EventManager.TriggerEvent('UnitMoveFinished', ZombieGameState, ZombieGameState, NewGameState);
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationTrack SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationTrack EffectTargetUnitTrack)
{
	local X2Action_SendInterTrackMessage SendMessageAction;
	local X2Action_CreateDoppelganger CopyDeadUnitAction;
	local X2Action_ReanimateCorpse Action;
	local XComGameStateHistory History;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameState_Effect SpawnZombieEffect;

	History = `XCOMHISTORY;

	// Add the action to send a message to the zombie unit
	`assert(EffectTargetUnitTrack.StateObject_NewState != none);
	SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(EffectTargetUnitTrack, Context));
	SendMessageAction.SendTrackMessageToRef = SpawnedUnit.GetReference();

	// The Target is the original unit so have it wait so its cin camera doesn't end
	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(EffectTargetUnitTrack, Context);

	// Setup the zombie actions
	SpawnZombieEffect = EffectTargetUnit.GetUnitAffectedByEffectState(EffectName);
	`assert(SpawnZombieEffect != none);

	// Copy the dead unit's appearance to the zombie
	CopyDeadUnitAction = X2Action_CreateDoppelganger(class'X2Action_CreateDoppelganger'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context));
	CopyDeadUnitAction.bWaitForOriginalUnitMessage = true;
	CopyDeadUnitAction.OriginalUnit = XGUnit(History.GetVisualizer(EffectTargetUnit.ObjectID));
	CopyDeadUnitAction.ReanimatorAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(SpawnZombieEffect.ApplyEffectParameters.AbilityInputContext.AbilityRef.ObjectID));
	CopyDeadUnitAction.ShouldCopyAppearance = SpawnedUnit.GetMyTemplateName() == UnitToSpawnName || SpawnedUnit.GetMyTemplateName() == AltUnitToSpawnName;
	CopyDeadUnitAction.StartAnimationMinDelaySec = StartAnimationMinDelaySec;
	CopyDeadUnitAction.StartAnimationMaxDelaySec = StartAnimationMaxDelaySec;

	Action = X2Action_ReanimateCorpse(class'X2Action_ReanimateCorpse'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context));
	Action.ReanimationName = AnimationName;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, ZombieFlyoverText, '', eColor_Bad, , 2.0f, true);
}

defaultproperties
{
	UnitToSpawnName="PsiZombie"
	AltUnitToSpawnName="PsiZombieHuman"
	TurnedZombieName="TurnedIntoZombie"
	EffectName="SpawnZombieEffect"
	AnimationName="HL_GetUp"
	bClearTileBlockedByTargetUnitFlag=true
	bCopyTargetAppearance=true
	StartAnimationMinDelaySec=0.0f
	StartAnimationMaxDelaySec=0.0f
}