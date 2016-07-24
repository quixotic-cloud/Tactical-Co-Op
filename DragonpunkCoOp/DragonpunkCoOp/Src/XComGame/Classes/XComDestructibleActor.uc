class XComDestructibleActor extends XComLevelActor
	implements(Destructible, X2VisualizerInterface)
	dependson(XComDestructibleActor_Toughness)
	placeable
	native(Destruction);

cpptext
{
	virtual UBOOL ShouldTrace(UPrimitiveComponent* Primitive,AActor *SourceActor, DWORD TraceFlags);

	// jboswell: I swear it makes sense to have both of these ;)
	UBOOL CanBlockPathing(); // Can this thing block pathing based on its configuration?
	UBOOL ShouldBlockPathing(); // Should it block pathing based on its current state?

	// Supporting archetyping the events arrays	
	UBOOL ResolveChangeToActionArray( const TArray<struct FDestructibleActorEvent>& CurrArchetypeActionArray, 
									  const TArray<struct FDestructibleActorEvent>& PrevArchetypeActionArray,
									  TArray<struct FDestructibleActorEvent>& LocalActionArray,
									  INT PrevLocalSize,
									  UBOOL bForceSyncToArchetype = FALSE );
	void CleanupActionArray(TArray<struct FDestructibleActorEvent>& ArchetypeActionArray, TArray<struct FDestructibleActorEvent>& LocalActionArray); //Allows for custom manipulation of action arrays in post load. Mass changes to arrays or removing deprecated actions. 
	virtual void PreEditChange( UProperty* PropertyAboutToChange );
	virtual void PostEditChangeProperty( struct FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PostLoad();

	virtual void TickAuthoritative( FLOAT DeltaSeconds );
	virtual void TickSimulated( FLOAT DeltaSeconds );
	// destructible actors are special... so very special... -tsmith 
	virtual void TickSpecial( FLOAT DeltaSeconds );

	virtual void PostProcessDamage(const FStateObjectReference &Dmg);
	virtual void ApplyAOEDamageMaterial();
	virtual void RemoveAOEDamageMaterial();
	virtual void GetAffectedChildren(TArray<IDestructible*>& Children);
	virtual bool GetAOEBreadcrumb() { return bAOEBreadcrumb; }
	virtual int GetToughnessHealth() 
	{
		return Toughness ? Toughness->Health : ((UXComDestructibleActor_Toughness *)(UXComDestructibleActor_Toughness::StaticClass()->GetDefaultObject()))->Health;
	}
	virtual bool ShouldAOEDamageProcFriendlyFirePopup() { return false; }

public:
	virtual UBOOL ShouldReuseLightMapsForSwap() const {return bReuseOriginalMeshLightMap;}

	virtual FSphere GetBoundsSphere();
};

struct native DestructibleActorEvent
{
	var() float Time<Tooltip=Amount of time to wait after the actor takes damage before running this action>;
	var() int Turns<Tooltip=Number of turns to wait until after the actor takes damage before running this action>;
	var() instanced XComDestructibleActor_Action Action;
	var() editoronly string Comment;

	structdefaultproperties
	{
		Time = 0.0f;
	}
};

const DestructibleActorDamagedThreshold = 0.75; //If health dips below this, we will enter the damaged state

var transient int Health;
var transient bool bDamaged;
var transient bool bUsingDefaultEffects; //If TRUE, this actor's effect setup is not complete so it will use default / fallback effects
var deprecated editinline array<XComDestructibleActor_Action> DamagedActions<ToolTip="List of actions to perform when this actor takes damage greater than 25% of its health">;
var deprecated editinline array<XComDestructibleActor_Action> DestroyedActions<ToolTip="List of actions to perform when this actor takes damage equal to its health (these actions will also occur if not already damaged and there are no Annihilated events)">;

var() editinline array<DestructibleActorEvent> DamagedEvents<ToolTip="List of actions to perform when this actor takes damage greater than 25% of its health">;
var() editinline array<DestructibleActorEvent> DestroyedEvents<ToolTip="List of actions to perform when this actor takes damage equal to its health (these actions will also occur if not already damaged and there are no Annihilated events)">;
var() editinline array<DestructibleActorEvent> AnnihilatedEvents<ToolTip="List of actions to perform when this actor takes damage equal to its health and has not already been damaged">;

var() editinline array<AnimNotify_PlayParticleEffect> m_arrParticleEffects<ToolTip = "Particle Effects to play upon spawning">;
var array<ParticleSystemComponent>      m_arrRemovePSCOnDeath;

// RAM - these values are used to implement support for correct dynamic array behavior for archetype-instance editing interations - 
//       see implementations of PreEditChange, PostEditChangeProperty for details
var transient array<DestructibleActorEvent> DamagedEventsChangeBuffer; 
var transient array<DestructibleActorEvent> DestroyedEventsChangeBuffer;
var transient array<DestructibleActorEvent> AnnihilatedEventsChangeBuffer;
var transient bool InEditOperation;
var transient int DamagedEventsChangeSize;
var transient int DestroyedEventsChangeSize;
var transient int AnnihilatedEventsChangeSize;

// Used for handling save/load of event bActivate state
var array<int> DamagedEventActivates;
var array<int> DestroyedEventActivates;
var array<int> AnnihilatedEventActivates;
var array<int> DamageEventTurnToApplyDamages;
var name SavedStateName;

var() XComDestructibleActor_Toughness Toughness<ToolTip="The health/damage taking characteristics of this actor (assign from GameData/Toughness)">;
var() XComDestructibleActor_AnnihilationToughness AnnihilationToughness<ToolTip="Damage taking characteristics of this actor to move straight to destroyed when pristine">;
var() array<Actor> AffectedChildren<ToolTip="Other actors which should always be in the same state as this actor">;
var transient int TotalHealth;

var() array<MaterialInstanceConstant> m_kAOEDamageMaterial;

var transient float TimeInState;
var transient int FirstTurnInState;
var transient int TurnsInState;
var() float TimeBeforeDeath<ToolTip="How long to wait before going from Destroyed to Dead state (to let particles/sounds finish) -1 for infinite life">;

var() DynamicLightEnvironmentComponent LightEnvironment; // JMS - a DLE to use if needed (could be used on a 
														 //       mesh swap or if this is a interactive level actor

var(Collision) const bool bIgnoreForPathing; // Should this actor be ignored during path obstacle generation?
var(Collision) const bool bBlocksRampagePathing;

var(Interaction) const bool bInteractive<Tooltip="Can this object be interacted with?">;
var() const bool bDestroysSurroundingArea<Tooltip="Should this actor destroy nearby fracture chunks when it is destroyed?">;

var const array<string> StateNames;

var transient bool bDoCameraPan;
var transient bool bCameraReady;
var transient bool bDestroyBegun;
var transient bool bVisualizerLoad;
var transient bool bLoadedFromSave;
var transient bool bCurrentStateRequiresTick; // Added for the floor component to know what to return the state to

var transient StateObjectReference LastDamageStateObject;

var() bool bIgnoreSupportingFloors;
var transient int PristineOverlappedFloorTileCount;
var transient int CurrentOverlappedFloorTileCount;

var transient vector MajorTileAxis;
var transient array<TTile> AssociatedTiles;

/** Uses the original mesh's light map, instead of generating a new one for the swap mesh. */
var() bool bReuseOriginalMeshLightMap;

//=======================================================================================
//X-Com 2 Refactoring
//
//Member variables go in here, everything else will be re-evaluated to see whether it 
//needs to be moved, kept, or removed.

var transient protectedwrite int ObjectID;

var XComFracLevelActor SwappedFracActor;
var transient StaticMesh DestructionSwapMesh;

var() SkeletalMeshComponent SkeletalMeshComponent;  //Optional skeletal mesh override
var() bool bCosmeticPhysicsEnabled;                 //If TRUE, allows the Physics asset for a destructible actor to be in control - reacting to physics impulses

var() Texture2D TargetingIcon; // Icon that is used to represent this destructible when being targeted in the shot hud

var transient bool bAOEBreadcrumb;

//=======================================================================================

// Adds/Removes the actor from the pathing system as an obstacle
//simulated native function RegisterObstacle( optional bool DeferredUpdate );
//simulated native function UnregisterObstacle();

simulated event PostBeginPlay()
{
	local AnimNotify_PlayParticleEffect ParticleNotify;

	super.PostBeginPlay();

	if( DamagedEventActivates.Length == 0 && DestroyedEventActivates.Length == 0 && AnnihilatedEventActivates.Length == 0 )
	{
		bDamaged = false;
		GotoState('_Pristine');
		// Bring in the toughness value and save it
		TotalHealth = (Toughness != none) ? Toughness.Health : class'XComDestructibleActor_Toughness'.default.Health;
		Health = TotalHealth;
	}

	//Skeletal mesh overrides static mesh
	if( SkeletalMeshComponent != none )
	{
		foreach m_arrParticleEffects( ParticleNotify )
		{
			if (ParticleNotify.SocketName == '' ||
				SkeletalMeshComponent.GetSocketByName( ParticleNotify.SocketName ) != none) //RAM - don't permit particle effects to spawn and then fail to attach
			{
				ParticleNotify.TriggerNotify( SkeletalMeshComponent );
			}
		}

		CollisionComponent = SkeletalMeshComponent;

		//If we have a physics asset and bCosmeticPhysicsEnabled, start using RB physics
		if( SkeletalMeshComponent.PhysicsAsset != none && bCosmeticPhysicsEnabled )
		{			
			SkeletalMeshComponent.SetHasPhysicsAssetInstance(true);
			SkeletalMeshComponent.SetComponentRBFixed(false);
			SetPhysics(PHYS_RigidBody);			
			SkeletalMeshComponent.PhysicsWeight = 1.0f;
		}
	}
}

function bool NotifyPSCWantsRemoveOnDeath( ParticleSystemComponent PSC )
{
	m_arrRemovePSCOnDeath.AddItem( PSC );
	return true;
}

event Destroyed()
{
	local ParticleSystemComponent PSC;

	super.Destroyed();

	foreach m_arrRemovePSCOnDeath( PSC )
	{
		if (PSC != none && PSC.bIsActive)
			PSC.DeactivateSystem( );
	}
	m_arrRemovePSCOnDeath.Length = 0;

	//If we were destroyed ( this should almost never happen, but thanks to Kismet it's still possible... ) then there is some cleanup that needs to happen
	OnDestroyed(); 
}

native function OnDestroyed();

protected function XComGameState_Destructible FindExistingState(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Destructible ObjectState;
	local ActorIdentifier MyActorIdentifier;

	//For searching for matching actors across save/load
	local bool HadNameMatch;
	local XComGameState_Destructible BestObjectState;
	local bool NamesMatch, LocsMatch;

	History = `XCOMHISTORY;

	// TODO dkaplan:  this is a temporary mechanism to get these particular game state objects syncing with their associated visualizers;  
	// another pass is forthcoming to simplify the entire gamestate-visualizer sync process
	if( ObjectID > 0 )
	{
		// see if this object already exists in the NewGameState
		if( NewGameState != None )
		{
			ObjectState = XComGameState_Destructible(NewGameState.GetGameStateForObjectID(ObjectID));
		}

		// see if this object already exists in the history
		if( ObjectState == None )
		{
			ObjectState = XComGameState_Destructible(History.GetGameStateForObjectID(ObjectID));
		}

		`assert(ObjectState != None);

		return ObjectState;
	}
	else
	{
		MyActorIdentifier = GetActorId();

		// loading... see if this object already exists in the history
		HadNameMatch = false;
		BestObjectState = None;

		foreach History.IterateByClassType(class'XComGameState_Destructible', ObjectState)
		{
			//Don't consider objects which already have a visualizer besides us
			if (ObjectState.GetVisualizer() != None && ObjectState.GetVisualizer().GetActorId() != MyActorIdentifier)
				continue;

			//If the ID matches, this is definitely the match
			if (MyActorIdentifier == ObjectState.ActorId)
			{
				BestObjectState = ObjectState;
				break;
			}

			NamesMatch = (MyActorIdentifier.ActorName == ObjectState.ActorId.ActorName);
			LocsMatch = (VSizeSq(MyActorIdentifier.Location - ObjectState.ActorId.Location) < 0.0001f);

			if (NamesMatch && LocsMatch)
			{
				BestObjectState = ObjectState;
				HadNameMatch = true;
			}
			else if (LocsMatch && !HadNameMatch)
			{
				BestObjectState = ObjectState;
			}
		}

		if (BestObjectState != None)
		{
			SetObjectIDFromState(BestObjectState);
			return BestObjectState;
		}
	}

	return none;
}

native function bool ShouldHaveState();
/*
event bool ShouldHaveState( )
{
	local DestructibleActorEvent Action;
	local Vector StupidLocation;
	local TTile TileLocation;

	if (XComInteractiveLevelActor(self) != none)
	{
		return false; //Interactive objects are already tracked directly
	}

	StupidLocation = self.Location; // because unreal script is stupid (Not allowed to use 'Self' as the value for an out parameter)
	TileLocation = `XWORLD.GetTileCoordinatesFromPosition( StupidLocation );
	if (`XWORLD.IsTileOutOfRange( TileLocation ))
	{
		return false; // Object isn't actually on the map. State shouldn't be able to change.
	}

	if ((Toughness != none) && (Toughness.TargetableBy != TargetableByNone))
	{
		return true; // Targetable destructibles should be state tracked
	}

	foreach DamagedEvents( Action )
	{
		if (XComDestructibleActor_Action_DamageOverTime( Action.Action ) != none)
		{
			return true; // Destructibles that have damage over time actions should be state tracked (to have game state safe ids)
		}
	}

	return false;
}
*/
function XComGameState_Destructible GetState(optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local X2TacticalGameRuleset Rules;
	local XComGameState_Destructible ObjectState;
	local bool SubmitState;

	if (!ShouldHaveState( ))
	{
		return none;
	}

	// first check if this actor already has a state
	ObjectState = FindExistingState(NewGameState);
	if(ObjectState != none)
	{
		return ObjectState;
	}

	// if it doesn't exist, then we need to create it
	History = `XCOMHISTORY;
	SubmitState = false;

	// see if we are in the start state
	if(History.GetStartState() != none)
	{
		`assert(NewGameState == none || NewGameState == History.GetStartState()); // there should be any other game states while the start state is still active
		NewGameState = History.GetStartState();
	}
	
	// no start state or supplied game state, make our own
	if( NewGameState == none )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState();
		SubmitState = true;
	}
	
	ObjectState = XComGameState_Destructible(NewGameState.CreateStateObject(class'XComGameState_Destructible'));

	ObjectState.SetInitialState(self);
	NewGameState.AddStateObject(ObjectState);

	Rules = `TACTICALRULES;
	if( Rules != None && SubmitState )
	{
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("Failed to submit new destructible actor state.");
		}
	}

	return ObjectState;
}

function SetObjectIDFromState(XComGameState_BaseObject StateObject)
{
	//We should never get two different IDs set on us.
	`assert(ObjectID == StateObject.ObjectID || ObjectID == 0);

	ObjectID = StateObject.ObjectID;
}

native function UpdateRenderVisibility();
native function GetBoundsForRenderVisUpdate(out vector Min, out vector Max);

native simulated function bool ShouldIgnoreForCover();

//Examines the lists of events and copies events from the default destructible actor in situations where no events are specified
native function ValidateEvents();

event bool DamageWillDestroy( int DamageAmount )
{
	local int Damaged, Destroyed;

	GetNewHealth( self, Health, DamageAmount, Damaged, Destroyed );

	// handle fragile things like windows
	if ((Toughness != none && Toughness.bFragile) && (Damaged == 1))
	{
		Destroyed = 1;
	}

	return (Destroyed == 1);
}

// Booleans can't be out parameters, so make them ints instead.  Stupid Unreal
simulated static function int GetNewHealth( const XComDestructibleActor Destructible, int CurrentHealth, int DamageAmount, optional out int GotoDamaged, optional out int GotoDestroyed )
{
	local int NewHealth;
	local bool bFragile;

	GotoDamaged = 0;
	GotoDestroyed = 0;

	NewHealth = CurrentHealth;

	if (Destructible.IsTargetable())
	{
		NewHealth -= DamageAmount;
	}
	else
	{
		bFragile = (Destructible.Toughness != none && Destructible.Toughness.bFragile);

		if (Destructible.IsInState( '_Pristine' ) && (Destructible.AnnihilationToughness != none) && (DamageAmount >= Destructible.AnnihilationToughness.Health))
		{
			GotoDestroyed = 1;
			NewHealth = 0;
		}
		else if (DamageAmount >= CurrentHealth)
		{
			if (Destructible.IsInState( '_Pristine' ) && (Destructible.DamagedEvents.Length > 0))
			{
				GotoDamaged = 1;
			}
			else
			{
				GotoDestroyed = 1;
				NewHealth = 0;
			}
		}
		else if (bFragile && Destructible.IsInState( '_Pristine' ) && (Destructible.DamagedEvents.Length > 0))
		{
			GotoDamaged = 1;
		}
	}

	return NewHealth;
}

simulated function ApplyDamageToMe(XComGameState_EnvironmentDamage Dmg)
{	
	local bool bFragile, bInvincible, bTargetable, bSuccumbsToDamage, bIsDestructibleObjective;
	local int DamageAmount;
	local XComGameState_EnvironmentDamage DamageEvent;
	local float PhysicsForceMagnitude;
	local vector PhysicsForceVector;
	local int GotoDamaged, GotoDestroyed;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;


	DamageEvent = Dmg;

	bFragile = (Toughness != none && Toughness.bFragile);
	bInvincible = (Toughness != none && Toughness.bInvincible);
	bTargetable = (Toughness != none && Toughness.TargetableBy != TargetableByNone);
	bSuccumbsToDamage = bInvincible && Toughness.bSuccumbsToDamage;
	bIsDestructibleObjective = (History.GetGameStateComponentForObjectID(ObjectID, class'XComGameState_ObjectiveInfo') != none);

	if (IsInState('_Destroyed') || IsInState('Dead') || IsInState('_DestructionStarted') || (bInvincible && !bSuccumbsToDamage) || (!bFragile && DamageEvent.bAffectFragileOnly))
		return;

	if (bSuccumbsToDamage && DamageEvent.DamageTypeTemplateName != Toughness.SuccumbsToDamageType)
		return;

	DamageAmount = DamageEvent.DamageAmount;

	if (bTargetable) // Targetable and fragile things use health as a bucket
	{
		// Sync to the health value from the already modified gamestate
		Health = XComGameState_Destructible(History.GetGameStateForObjectID( ObjectID )).Health;
		`log("Targetable XComDestructibleActor " @ self @ " synced health from gamestate." @ Health @ " units of health remain.",,'XComWorldData');

		if (Health <= 0)
		{
			LastDamageStateObject = DamageEvent.GetReference( );
			GoToState( '_DestructionStarted' );
		}
		else if (!IsInState('_Damaged')) 
		{
			if ((Health <= (TotalHealth * DestructibleActorDamagedThreshold)) || bFragile || bIsDestructibleObjective)
			{
				LastDamageStateObject = DamageEvent.GetReference( );
				GotoState( '_DamageStarted' );
			}
		}
	}
	else // other destructibles use health/toughness as a gating mechanism
	{
		Health = GetNewHealth( self, Health, DamageAmount, GotoDamaged, GotoDestroyed );

		if (GotoDamaged == 1)
		{
			LastDamageStateObject = DamageEvent.GetReference( );
			GotoState( '_DamageStarted' );
		}
		else if (GotoDestroyed == 1)
		{
			LastDamageStateObject = DamageEvent.GetReference( );
			GoToState( '_DestructionStarted' );
		}
	}

	//Apply forces if we are using rigid body physics
	if( Health > 0 && Physics == PHYS_RigidBody )
	{
		PhysicsForceMagnitude = Dmg.PhysImpulse;

		if( Dmg.bRadialDamage )
		{			
			SkeletalMeshComponent.AddRadialImpulse(Dmg.HitLocation, Dmg.DamageRadius, PhysicsForceMagnitude, RIF_Constant);
		}
		else
		{
			PhysicsForceVector = Dmg.Momentum;
			BumpPhysics(Dmg.HitLocation, PhysicsForceVector, PhysicsForceMagnitude);
		}		
	}
}

simulated function bool IsReadyToExplode()
{
	if (IsInState('_Damaged') && !Toughness.bFragile && !Toughness.bInvincible && HasRadialDamage())
		return true;
	return false;
}

simulated function bool IsTargetable()
{
	if (Toughness != none && Toughness.TargetableBy != TargetableByNone)
	{
		return true;
	}

	return false;
}

event bool HasRadialDamage()
{
	local DestructibleActorEvent kEvent;

	foreach DestroyedEvents(kEvent)
	{
		if( kEvent.Action != none  && kEvent.Action.IsA('XComDestructibleActor_Action_RadialDamage'))
		{
			return true;
		}
	}

	return false;
}

event bool DestructionEmptiesTile()
{
	local DestructibleActorEvent kEvent;
	local XComDestructibleActor_Action_SwapStaticMesh SwapAction;

	// Check a few types to see if the destruction events will cause the object to disappear from the tile data instead of changing to a different mesh
	// if more types are added to this loop (or perhaps if the action specific checks become too complicated), 
	//    we should consider adding an interface to XComDestructibleActor_Action to delegate to instead.
	foreach DestroyedEvents( kEvent )
	{
		if (kEvent.Action != none)
		{
			if (kEvent.Action.IsA('XComDestructibleActor_Action_Hide'))
			{
				return true;
			}
			else if (kEvent.Action.IsA('XComDestructibleActor_Action_SwapStaticMesh'))
			{
				SwapAction = XComDestructibleActor_Action_SwapStaticMesh( kEvent.Action );
				if (SwapAction.bDisableCollision || (SwapAction.MeshCue == none) || (SwapAction.MeshCue.Pick() == none))
				{
					return true;
				}
			}
		}
	}

	return false;
}

simulated event DestructibleTakeDamage(XComGameState_EnvironmentDamage DamageEvent)
{
	local bool TargetableDamage;

	TargetableDamage = Toughness != none && Toughness.TargetableBy != TargetableByNone;

	if(TargetableDamage == DamageEvent.bTargetableDamage) // targetable objects don't take normal environment damage, they are targeted the same way units are
	{
		ApplyDamageToMe(DamageEvent);	
	}
}

simulated event TakeCollateralDamage(Actor FromActor, int DamageAmount)
{
	
}

event bool IsGlassMaterial(PhysicalMaterial TestMaterial)
{
	local XComPhysicalMaterialProperty PhysMaterial;
	
	if(TestMaterial != none)
	{
		PhysMaterial = XComPhysicalMaterialProperty(TestMaterial.GetPhysicalMaterialProperty(class'XComPhysicalMaterialProperty'));
		if(PhysMaterial != none && PhysMaterial.MaterialType == MaterialType_Glass)
		{
			return true;
		}
	}

	return false;
}

simulated native function DisableCollision();

// Only used by lightmass to bake swap mesh lightmaps
native function UpdateSMCWithSwapMeshes();

simulated native function SetStaticMesh(StaticMesh NewMesh, optional Vector NewTranslation, optional rotator NewRotation, optional vector NewScale3D);

//Allow the actor to be set with a skeletal mesh
simulated native function SetSkeletalMesh(SkeletalMesh InSkeletalMesh);

simulated native function PreTriggerEvents(const out array<DestructibleActorEvent> Events);			// trigger action code for changes to self/tile data
simulated native function ResponseTriggerEvents(const out array<DestructibleActorEvent> Events);	// trigger action code that may submit new gamestates

// Returns the number of events that haven't been activated
simulated native function int TriggerEvents(const out array<DestructibleActorEvent> Events);

simulated native function CleanupEvents(const out array<DestructibleActorEvent> Events);

// Returns the number of events that haven't finished ticking
simulated native function int TickEvents(const out array<DestructibleActorEvent> Events, float DeltaTime);

simulated native function DamageSurroundingArea();

simulated native function bool GetDesiredTickState();

simulated native function SyncDamageStateToChildren(Name NewState);

//Performs a radial impulse against this actor's physics
simulated native function BumpPhysics(const out vector Position, const out vector Direction, float ForceMagnitude, optional bool bDebugLineCheck = false);

/// X2VisualizerInterface
event OnAddedToVisualizerTrack();
event OnRemovedFromVisualizerTrack();
event OnVisualizationBlockStarted(const out VisualizationBlock StartedBlock);
event SetTimeDilation(float TimeDilation, optional bool bComingFromDeath/*=false*/);
event VerifyTrackSyncronization();
function BuildAbilityEffectsVisualization(XComGameState VisualizeGameState, out VisualizationTrack InTrack);
function int GetNumVisualizerTracks();

event vector GetShootAtLocation(EAbilityHitResult HitResult, StateObjectReference Shooter)
{
	return GetTargetingFocusLocation();
}

event vector GetTargetingFocusLocation()
{
	local Vector SkeletalMeshOrigin;

	if(StaticMeshComponent.StaticMesh != none)
	{
		return StaticMeshComponent.Bounds.Origin;
	}
	else if(SkeletalMeshComponent.SkeletalMesh != none)
	{
		// for whatever reason skeletal mesh bounds are relative to the model origin
		SkeletalMeshOrigin = SkeletalMeshComponent.SkeletalMesh.Bounds.Origin + SkeletalMeshComponent.Translation * Vector(Rotation);
		
		if(!SkeletalMeshComponent.AbsoluteTranslation)
		{
			SkeletalMeshOrigin += Location;
		}
		
		return SkeletalMeshOrigin;
	}
	else
	{
		return Location;
	}
}

event vector GetUnitFlagLocation()
{
	return GetTargetingFocusLocation();
}

event StateObjectReference GetVisualizedStateReference()
{
	local StateObjectReference Reference;

	Reference.ObjectID = ObjectID;
	return Reference;
}

simulated event TriggerActionRespones( ) // trigger state actions that may want to submit new gamestates
{
}

//-----------------------------------------------------------------------------
// States
//-----------------------------------------------------------------------------

auto simulated state _Pristine
{
	ignores Tick;

	simulated event BeginState(Name PreviousStateName)
	{
		if( !bCosmeticPhysicsEnabled )
		{
			SetTickIsDisabled(true);
			bCurrentStateRequiresTick=false;
		}
		else
		{
			SetTickIsDisabled(false);
			bCurrentStateRequiresTick=true;
		}
	}

	simulated event EndState(Name NextStateName)
	{
		SetTickIsDisabled(false);
		bCurrentStateRequiresTick=true;
	}
}

simulated state _DamageState
{
	simulated event BeginState(Name PreviousStateName)
	{
		local Name StateName; StateName = GetStateName();

		bVisualizerLoad = `XWORLD.bSyncingVisualizer;

		`assert( LastDamageStateObject.ObjectID != 0 || bVisualizerLoad );

		TimeInState = 0;
		`log(self.Name @ "entering" @ StateName @ "from" @ PreviousStateName, , 'DevDestruction');

		SyncDamageStateToChildren(StateName);
	}
}

simulated state _DamageStarted extends _DamageState
{
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		bDamaged = true;

		PreTriggerEvents( DamagedEvents );
	}
}

simulated state _Damaged extends _DamageState
{
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		if (!bLoadedFromSave)
		{
			FirstTurnInState = `TACTICALGRI.GetCurrentPlayerTurn();
		}
		TriggerEventClass(class'SeqEvent_DestructibleStatusChanged', self, 0);
	}

	simulated function Tick(float DeltaTime)
	{
		TimeInState += DeltaTime;
		TurnsInState = `TACTICALGRI.GetCurrentPlayerTurn() - FirstTurnInState;

		TriggerEvents(DamagedEvents);
		TickEvents(DamagedEvents, DeltaTime);
	}

	simulated event EndState(Name NextStateName)
	{
		CleanupEvents(DamagedEvents);
	}

	simulated event TriggerActionRespones( ) // trigger state actions that may want to submit new gamestates
	{
		ResponseTriggerEvents( DamagedEvents );
	}
}

simulated state _DestructionStarted extends _DamageState
{
	simulated event BeginState(Name PreviousStateName)
	{
		local box Bounds;
		local vector BoundsExtents;

		super.BeginState(PreviousStateName);

		GetComponentsBoundingBox( Bounds );
		BoundsExtents = Bounds.Max - Bounds.Min;
		if (vsize( BoundsExtents ) > 0.0f)
		{
			`log("XComDestructibleActor " @ self @ " setting potential fire at " @ ((Bounds.Max + Bounds.Min) / 2.0f), , 'XComWorldData');
			`XWORLD.PotentialFireColumns.AddItem( (Bounds.Max + Bounds.Min) / 2.0f );
		}
		else
		{
			`log("XComDestructibleActor " @ self @ " setting potential fire at " @ Location @ "(Bounds are invalid)", , 'XComWorldData');
			`XWORLD.PotentialFireColumns.AddItem( Location );
		}

		ValidateEvents();

		if (ConsiderForOccupancy( ))
		{
			`XWORLD.AddDestructiblesPlacedOnTop( self, LastDamageStateObject );
		}

		// Use destroyed events when health is reduced to zero and there are no annihilated events
		// regardless of previous state. This preserves the previous behavior for most destructible actors.
		if(bDamaged || AnnihilatedEvents.Length <= 0)
		{
			PreTriggerEvents(DestroyedEvents);
		}
		// Use annihilated events if present and health is reduced to zero only when the previous state is pristine (currently only for trees).
		else
		{
			PreTriggerEvents(AnnihilatedEvents);
		}
	}

	simulated event TriggerActionRespones( ) // trigger state actions that may want to submit new gamestates
	{
		// Use destroyed events when health is reduced to zero and there are no annihilated events
		// regardless of previous state. This preserves the previous behavior for most destructible actors.
		if(bDamaged || AnnihilatedEvents.Length <= 0)
		{
			ResponseTriggerEvents(DestroyedEvents);
		}
		// Use annihilated events if present and health is reduced to zero only when the previous state is pristine (currently only for trees).
		else
		{
			ResponseTriggerEvents(AnnihilatedEvents);
		}
	}
}

simulated state _Destroyed extends _DamageState
{
	simulated event BeginState(Name PreviousStateName)
	{
		bDestroyBegun = false;
		super.BeginState(PreviousStateName);	
		if (!bDoCameraPan)
			BeginDestroyed();
	}

	simulated function BeginDestroyed()
	{
		if (!bLoadedFromSave)
		{
			Health = 0; // Force health, in case this is a child being forced into this state
			FirstTurnInState = `TACTICALGRI.GetCurrentPlayerTurn();
		}
		TriggerEventClass(class'SeqEvent_DestructibleStatusChanged', self, 1);
		
		//// If the damage event is allowed to cause area damage and this is not a fragile actor
		//// destroy any nearby frac chunks -- jboswell
		//if (LastDamage.bCausesSurroundingAreaDamage && (Toughness == none || !Toughness.bFragile) && bDestroysSurroundingArea)
		//{
		//	DamageSurroundingArea();
		//}		
		bDestroyBegun = true;
	}

	simulated function Tick(float DeltaTime)
	{
		local int RemainingEvents;
		local ParticleSystemComponent PSC;

		if (bDestroyBegun)
		{
			TimeInState += DeltaTime;
			TurnsInState = `TACTICALGRI.GetCurrentPlayerTurn() - FirstTurnInState;

			// Use destroyed events when health is reduced to zero and there are no annihilated events
			// regardless of previous state. This preserves the previous behavior for most destructible actors.
			if(bDamaged || AnnihilatedEvents.Length <= 0)
			{
				TriggerEvents(DestroyedEvents);
				RemainingEvents = TickEvents(DestroyedEvents, DeltaTime);
			}
			// Use annihilated events if present and health is reduced to zero only when the previous state is pristine (currently only for trees).
			else
			{
				TriggerEvents(AnnihilatedEvents);
				RemainingEvents = TickEvents(AnnihilatedEvents, DeltaTime);
			}

			foreach m_arrRemovePSCOnDeath( PSC )
			{
				if (PSC != none && PSC.bIsActive)
					PSC.DeactivateSystem( );
			}
			m_arrRemovePSCOnDeath.Length = 0;
		
			if (RemainingEvents == 0 && (TimeBeforeDeath > 0 && TimeInState >= TimeBeforeDeath))
			{
				GotoState('Dead');
			}
		}
	}

	simulated event EndState(Name NextStateName)
	{
		if(bDamaged || AnnihilatedEvents.Length <= 0)
		{
			CleanupEvents(DestroyedEvents);
		}
		else
		{
			CleanupEvents(AnnihilatedEvents);
		}

		bVisualizerLoad = false;
	}

Begin:

	if (bDoCameraPan)
	{
		while (!bCameraReady)
			Sleep(0.1f);
		BeginDestroyed();
	}
}

simulated state Dead
{
	ignores Tick;

	simulated event BeginState(Name PreviousStateName)
	{
		// Disable physics and collision 
		// RAM - only disable physics if the object is actually gone...
		if( StaticMeshComponent == none )
		{
			SetPhysics(PHYS_None);		
		}

		// Disable ticking
		SetTickIsDisabled(true);
		bCurrentStateRequiresTick=false;
		
		// no longer setting bTearOff because we are also no longer replicating Actor properties, bSkipActorPropertyReplication=true,
		// to prevent collision being turned off prematurely by damage on server. when bTearOff=true the server closes the actor channel,
		// however, since bSkipActorPropertyReplication=true that value never gets replicated to the client so when the channel closes
		// the client deletes the actor instead of just letting it hang around detached from the server sim. -tsmith 
		//// Make this object irrelevant to the network
		//if(Role == ROLE_Authority)
		//{
		//	bTearOff = true;
		//}
	}
}

function string GetMyHUDIcon()
{
	if(TargetingIcon != none)
	{
		return class'Object'.static.PathName(TargetingIcon);
	}
	else
	{
		return "";
	}
}

function EUIState GetMyHUDIconColor()
{
	return eUIState_Bad; 
}


defaultproperties
{	
	Health = 1;
	TotalHealth = 1;
	TimeBeforeDeath=10.0f

	begin object name=StaticMeshComponent0
		WireframeColor=(R=0,G=255,B=128,A=255)
		BlockRigidBody=true
		RBChannel=RBCC_GameplayPhysics
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
		// LightEnvironment=MyLightEnvironment
		bUsePrecomputedShadows=false //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=FALSE,bInitialized=TRUE)//Bake Static Lights, Zel
		bReceiverOfDecalsEvenIfHidden=TRUE // Prevent decals getting deleted when hiding this actor through building vis system.
		//CollideActors=TRUE
		CastShadow=TRUE
	end object	

	begin object class=SkeletalMeshComponent name=SkeletalMeshComponent0
		bOwnerNoSee=FALSE

		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
		BlockRigidBody=true

		bUpdateSkelWhenNotRendered = false

		bSyncActorLocationToRootRigidBody=false;
		RBChannel=RBCC_Pawn
		RBCollideWithChannels=(Default=True,Pawn=True,Vehicle=True,Water=True,GameplayPhysics=True,EffectPhysics=True,Untitled1=True,Untitled2=True,Untitled3=True,Untitled4=True,Cloth=True,FluidDrain=True,SoftBody=True,FracturedMeshPart=True)		
	end object

	Components.Add(SkeletalMeshComponent0);	
	SkeletalMeshComponent = SkeletalMeshComponent0;

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyNEWLightEnvironment
		bEnabled=false     // precomputed lighting is used until the static mesh is changed
		bCastShadows=false // there will be a static shadow so no need to cast a dynamic shadow
		bSynthesizeSHLight=false
		bSynthesizeDirectionalLight=true; // get rid of this later if we can
		bDynamic=false     // using a static light environment to save update time
		bForceNonCompositeDynamicLights=TRUE // needed since we are using a static light environment
		bUseBooleanEnvironmentShadowing=FALSE
		TickGroup=TG_DuringAsyncWork
	End Object
	LightEnvironment=MyNEWLightEnvironment;
	Components.Add(MyNEWLightEnvironment);

	bStatic = false; // jboswell: or else mesh swapping doesn't work.
	bMovable = false; //Allows the physics to be non-fixed / simulated

	bEdShouldSnap=true
	bWorldGeometry=true
	bGameRelevant=true
	bPathColliding=false
	Physics=PHYS_None // jboswell: updated by states

	bCollideWorld=false
	bProjTarget=true
	bBlockActors=true
	bCollideActors=true

	bNoEncroachCheck=true
	bBlocksTeleport=true
	bBlocksNavigation=true

	bCanClimbOver=false
	bCanClimbOnto=false

	bInteractive=false
	bDestroysSurroundingArea=true

	// network variables -tsmith 
	// NOTE: we are no longer replicating Destructible actors because there are far too many in each level and none of the data
	// in the destructibles was being replicated. we can however replicate a reference to the actor because they are place in the levels.
	// so if in the future we need to replicate info we can do it through some sort of manager class. -tsmith 
	m_bNoDeleteOnClientInitializeActors=true
	RemoteRole=ROLE_None 

	SupportedEvents.Add(class'SeqEvent_DestructibleStatusChanged')

	InitialState = "_Pristine"

	StateNames[0] = "_Pristine"
	StateNames[1] = "_DamageStarted"
	StateNames[2] = "_Damaged"
	StateNames[3] = "_DestructionStarted"
	StateNames[4] = "_Destroyed"
	StateNames[5] = "Dead"

	bDamaged = false;

	bLoadedFromSave=false
	bCurrentStateRequiresTick=false
	bReuseOriginalMeshLightMap=false

	SwappedFracActor=none
	DestructionSwapMesh=none

	TargetingIcon=Texture2D'UILibrary_Common.TargetIcons.target_barrel'

	PristineOverlappedFloorTileCount = 0
	CurrentOverlappedFloorTileCount = 0

	bAOEBreadcrumb = false
	bBlocksRampagePathing = false
	bIgnoreSupportingFloors =  false
}
