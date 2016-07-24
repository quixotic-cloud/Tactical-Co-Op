class X2Effect_ParthenogenicPoison extends X2Effect_SpawnUnit;

var localized string ParthenogenicPoisonText;

var name ParthenogenicPoisonType;
var name ParthenogenicPoisonCocoonSpawnedName;
var name AltUnitToSpawnName;

var private name DiedWithParthenogenicPoisonTriggerName;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local XComGameStateHistory History;
	local XComHumanPawn HumanPawn;

	History = `XCOMHISTORY;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	`assert(TargetUnit != none);

	HumanPawn = XComHumanPawn(XGUnit(History.GetVisualizer(TargetUnit.ObjectID)).GetPawn());
	if( HumanPawn != None )
	{
		UnitToSpawnName = AltUnitToSpawnName;
	}

	if (TargetUnit != none && !TargetUnit.IsAlive())
	{
		// The target died from the ability attaching this effect
		// The cocoon spawn should happen now
		super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	
	if (EffectApplyResult == 'AA_Success' && BuildTrack.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, ParthenogenicPoisonText, '', eColor_Bad);
	}
}

simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit PoisonedUnit;
	local bool bContinueTicking;
	local X2Effect_ParthenogenicPoison PoisonTemplate;

	bContinueTicking = super.OnEffectTicked(ApplyEffectParameters, kNewEffectState, NewGameState, FirstApplication);

	PoisonTemplate = X2Effect_ParthenogenicPoison(kNewEffectState.GetX2Effect());
	if( (PoisonTemplate != none) && !PoisonTemplate.bInfiniteDuration && (kNewEffectState.iTurnsRemaining <= 0) )
	{
		// If the effect is not infinite and there are no more turns remaining, check to see if the poisoned unit has died
		PoisonedUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		if( PoisonedUnit == none )
		{
			PoisonedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		}

		if( (PoisonedUnit != none) && PoisonedUnit.IsDead() )
		{
			// If the unit dies on a tick, trigger the spawn
			super.OnEffectAdded(ApplyEffectParameters, PoisonedUnit, NewGameState, kNewEffectState);
		}
	}

	return bContinueTicking;
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const int TickIndex, XComGameState_Effect EffectState)
{
}

simulated function SetPoisonDamageDamage()
{
	local X2Effect_ApplyWeaponDamage PoisonDamage;

	PoisonDamage = GetPoisonDamage();
	PoisonDamage.EffectDamageValue = class'X2Item_DefaultWeapons'.default.Chryssalid_ParthenogenicPoison_BaseDamage;
}

simulated function X2Effect_ApplyWeaponDamage GetPoisonDamage()
{
	return X2Effect_ApplyWeaponDamage(ApplyOnTick[0]);
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit EffectTargetUnit;
	local XComGameStateHistory History;
	local Object EffectObj;

	super.RegisterForEvents(EffectGameState);

	History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	EffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	// Register for the required events
	EventMgr.RegisterForEvent(EffectObj, DiedWithParthenogenicPoisonTriggerName, EffectGameState.OnUnitDiedWithParthenogenicPoison, ELD_OnStateSubmitted,, EffectTargetUnit);
}

function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetSourceUnitsTeam(ApplyEffectParameters, true);
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit DeadUnitGameState, NewUnitGameState;
	local bool bAddDeadUnit;
	local X2EventManager EventManager;
	local XComUnitPawn PawnVisualizer;

	EventManager = `XEVENTMGR;

	bAddDeadUnit = false;
	DeadUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( DeadUnitGameState == none)
	{
		bAddDeadUnit = true;
		DeadUnitGameState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	}
	`assert(DeadUnitGameState != none);

	NewUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	`assert(NewUnitGameState != none);

	// The Dead unit's Loot is lost
	DeadUnitGameState.bBodyRecovered = false;

	DeadUnitGameState.RemoveUnitFromPlay();

	if( bAddDeadUnit )
	{
		NewGameState.AddStateObject(DeadUnitGameState);
	}

	// Record the DeadUnitGameState's ID so the cocoon knows who spawned it
	NewUnitGameState.m_SpawnedCocoonRef = DeadUnitGameState.GetReference();

	PawnVisualizer = XGUnit(NewUnitGameState.GetVisualizer()).GetPawn();
	PawnVisualizer.RagdollFlag = eRagdoll_Never;

	// Remove the dead unit from play
	EventManager.TriggerEvent('UnitRemovedFromPlay', DeadUnitGameState, DeadUnitGameState, NewGameState);

	EventManager.TriggerEvent(default.ParthenogenicPoisonCocoonSpawnedName, NewUnitGameState, NewUnitGameState);
}

simulated function X2Action AddX2ActionsForVisualization_Death(out VisualizationTrack BuildTrack, XComGameStateContext Context)
{
	local X2Action AddAction;

	AddAction = class'X2Action'.static.CreateVisualizationActionClass( class'X2Action_DeathWithParthenogenicPoison', Context, BuildTrack.TrackActor );
	BuildTrack.TrackActions.AddItem( AddAction );

	return AddAction;
}

function bool DoesEffectAllowUnitToBleedOut(XComGameState_Unit UnitState) {return false; }
function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState) {return false; }

defaultproperties
{
	EffectName="ParthenogenicPoisonEffect"
	UnitToSpawnName="ChryssalidCocoon"
	AltUnitToSpawnName="ChryssalidCocoonHuman"
	bClearTileBlockedByTargetUnitFlag=true
	bCopyTargetAppearance=true

	ParthenogenicPoisonType="ParthenogenicPoison"
	ParthenogenicPoisonCocoonSpawnedName="ParthenogenicPoisonCocoonSpawned"

	DiedWithParthenogenicPoisonTriggerName="UnitDied"

	Begin Object Class=X2Effect_ApplyWeaponDamage Name=PoisonDamage
		bAllowFreeKill=false
		bIgnoreArmor=true
		DamageTypes.Add("ParthenogenicPoison")
	End Object

	ApplyOnTick.Add(PoisonDamage)

	DamageTypes.Add("ParthenogenicPoison");
}