// Describes what happens when an XComProjectile impacts
// the ground. Specifies material-specific effects to trigger,
// decals, and sounds.
//
// The actual data for this class resides inside archetypes in the
// editor.
//
// TODO: This is all good code in here, but...
// The way we're using this class is to spawn this actor,
// create sounds, decals, and FX, and then immediately destroy the actor.
// Perhaps we should just make this class an object that works from the
// XComProjectile class?
//
// 04/03/2009 - Dominic Cerquetti, Firaxis Games
//
// TODO: Random angle deviations for XComMaterialDamageType
// e.g. 10 degrees is randomly 10 degrees off normal axis

class XComProjectileImpactActor extends Actor
	native(Graphics)
	hidecategories(Object);

// Pairs a bunch of impact data with a specific Material type
struct native XComMaterialDamageType
{
	// the type of material, as specified in XComPhysicalMaterialProperty
	/**
	 *  The particle effect that will play when the impact effect is triggered
	 */
	var() ParticleSystem            SurfaceImpactFX;

	/**
	 *  List of possible materials to use as decals for this impact effect
	 */
	var() editinline DecalCue       Decals;
	var() DecalProperties           PrimaryDecalProperties<ToolTip="Values to control the appearance of the 'Decals' cues">;
	var DecalProperties             TopLayerDecalProperties<ToolTip="Values to control the appearance of the 'Decals' cues">;	

	var() editinline DecalCue       SecondaryDecals<ToolTip="Specifies the decal to use as a layer underneath the one specified by 'Decals'">;	
	var() DecalProperties           SecondaryDecalProperties<ToolTip="Values to control the appearance of the 'SecondaryDecals' cues">;
	var editinline DecalCue         SubLayerDecals<ToolTip="Specifies the decal to use as a layer underneath the one specified by 'Decals'">;
	var DecalProperties             SubLayerDecalProperties<ToolTip="Values to control the appearance of the 'SubLayerDecals' cues">;	

	var() SoundCue                  ImpactSoundCue<ToolTip="Specifies a sound effect to play when a projectile impacts">;
	var() bool                      bUseDefaultDecal<ToolTip="Flags this impact type to use the default decals & settings if there are no decals assigned">;

	var() int                       SpawnDecalEveryXthHit;

	/**
	 *  Select the material type that this impact effect will be associated with
	 */
	var() EMaterialType             MaterialType;

	structdefaultproperties
	{	
		bUseDefaultDecal = false
		SpawnDecalEveryXthHit = 1
	}
};

cpptext
{
	virtual void PostLoad();
}

// Element zero in this array is the "default" material, in case we can't find one
var() array<XComMaterialDamageType> MaterialSpecificImpactData;

var() editinline DecalCue DefaultImpactDecals<ToolTip="Specify decals to use in the absence of a setting in the material specific impact data">;
var() DecalProperties DefaultImpactDecalProperties<ToolTip="Values to control the formation of the default decals">;

var int CurrentlySelectImpactIndex;

// TODO: Do we need to use both HitNormal and TraceNormal/etc here?
// Consolidate if they're identical, if possible. -Dom

// Info from the projectile
var Actor ImpactedActor;
var Vector HitLocation;
var Vector HitNormal;

// Info from our own Trace
var TraceHitInfo TraceInfo;
var vector TraceLocation;
var vector TraceNormal;
var Rotator RealRotation;
var Actor TraceActor; // warning: TraceActor doesn't work sometimes. unsure why, something with the terrain

var AudioComponent ImpactSound;

var const float DefaultDecalThickness;
var const float DefaultDecalScale;
var const float DefaultDecalBackfaceAngle;

var bool bIsPooledActor;
var bool bIsCurrentlyInUse;
var XComProjectileImpactActor ActorTemplate;

simulated native function InitImpactActorFromPool(/*XComProjectile ActorOwner*/);

simulated function SpawnDecal()
{		
	local PrimitiveComponent DecalPrimitiveComponent;
	local XComUnitPawn HitPawn;
	local DecalProperties kUseDecalProperties;
	local DecalCue        kUseDecalCue;	
	local float           kDepthBias;

	if (CurrentlySelectImpactIndex == -1)
		return;

	// This is used to not spawn decals upon every hit. Each decal data sets how often a decal should spawn.
	if( WorldInfo != none )
	{
		// Handle Overflow.
		if( WorldInfo.DecalSpawnAccumulator >= 32000 )
			WorldInfo.DecalSpawnAccumulator = 0;

		if( MaterialSpecificImpactData[CurrentlySelectImpactIndex].SpawnDecalEveryXthHit != 0 &&
			WorldInfo.DecalSpawnAccumulator % MaterialSpecificImpactData[CurrentlySelectImpactIndex].SpawnDecalEveryXthHit != 0 )
		{
			WorldInfo.DecalSpawnAccumulator++;
			return;
		}
	}

	if (MaterialSpecificImpactData[CurrentlySelectImpactIndex].Decals != none )
	{		
		kUseDecalCue = MaterialSpecificImpactData[CurrentlySelectImpactIndex].Decals;
		kUseDecalProperties = MaterialSpecificImpactData[CurrentlySelectImpactIndex].PrimaryDecalProperties;
	}
	else if( MaterialSpecificImpactData[CurrentlySelectImpactIndex].bUseDefaultDecal )
	{
		kUseDecalCue = DefaultImpactDecals;
		kUseDecalProperties = DefaultImpactDecalProperties;
	}

	if( ImpactedActor != none )
	{
		HitPawn = XComUnitPawn(ImpactedActor);
		if( HitPawn != none )
		{
			DecalPrimitiveComponent = TraceInfo.HitComponent;	
		}
	}	

	kDepthBias = (FRand() + 1) * class'DecalComponent'.Default.DepthBias;

	if( HitPawn != none )
	{
		if( WorldInfo != none && kUseDecalCue != none )
			WorldInfo.DecalSpawnAccumulator++;

		class'DecalCue'.static.SpawnDecalFromCue( WorldInfo.MyDecalManager, 
												  kUseDecalCue, 
												  kUseDecalProperties, 
												  kDepthBias,
												  TraceLocation, 
												  Rotator(-TraceNormal),
												  DecalPrimitiveComponent, 
												  true, 
												  true,
												  TraceInfo);
		
		// RAM - Did the pawn die from this hit? If so then MELT THEIR FACE.
		if( !HitPawn.IsAliveAndWell() )
		{
			class'DecalCue'.static.SpawnDecalFromCue( WorldInfo.MyDecalManager, 
													  kUseDecalCue, 
													  kUseDecalProperties,
													  kDepthBias,
													  TraceLocation, 
													  Rotator(-TraceNormal),
													  HitPawn.m_kHeadMeshComponent, 
													  true, 
													  true,
													  TraceInfo);
		}
	}
	else
	{
		if( WorldInfo != none && (kUseDecalCue != none || MaterialSpecificImpactData[CurrentlySelectImpactIndex].SecondaryDecals != none) )
			WorldInfo.DecalSpawnAccumulator++;

		class'DecalCue'.static.SpawnDecalFromCue( WorldInfo.MyDecalManager, 
												  kUseDecalCue, 
												  kUseDecalProperties, 
												  kDepthBias,
												  TraceLocation, 
												  Rotator(-TraceNormal) );

		class'DecalCue'.static.SpawnDecalFromCue( WorldInfo.MyDecalManager, 
												  MaterialSpecificImpactData[CurrentlySelectImpactIndex].SecondaryDecals, 
												  MaterialSpecificImpactData[CurrentlySelectImpactIndex].SecondaryDecalProperties,
												  kDepthBias,
												  TraceLocation, 
												  Rotator(-TraceNormal) );
	}
}

simulated function DestroyImpactActor()
{
	if( bIsPooledActor )
	{
		bIsCurrentlyInUse = false;
		SetTickIsDisabled(true);
	}
	else
	{
		Destroy();
	}
}

simulated function OnParticleSystemFinished(ParticleSystemComponent FinishedComponent)
{
	//give component back to pool, otherwise pool will think it is still in use
	WorldInfo.MyEmitterPool.OnParticleSystemFinished(FinishedComponent);

	if (ImpactSound != none)
		ImpactSound.FadeOut(0.5f, 0.0f);

	DestroyImpactActor();
}

simulated function bool SpawnEffect()
{
	local ParticleSystemComponent PSC;

	if (CurrentlySelectImpactIndex == -1 || MaterialSpecificImpactData[CurrentlySelectImpactIndex].SurfaceImpactFX == none)
		return false;

	PSC = WorldInfo.MyEmitterPool.SpawnEmitter( MaterialSpecificImpactData[CurrentlySelectImpactIndex].SurfaceImpactFX, TraceLocation, RealRotation );
	
	if (PSC == none)
		return false;
	
	PSC.OnSystemFinished = OnParticleSystemFinished;
	return true;

	// DrawDebugLine( TraceLocation, TraceLocation + (TraceNormal * 10), 0, 255, 0, True);
	// DrawDebugLine( TraceLocation, TraceLocation + (TraceNormal * 3), 255, 0, 0, True);

	// DrawDebugSphere(TraceLocation, 10, 32, 0,0,255,true);
}

simulated function bool CalcMaterialAtHitPosition()
{
	local XComPhysicalMaterialProperty PhysMaterial;
	local int i;	
	local Rotator RotateBy90Degrees;

	// need to do this because particles orient in +Z direction
	RotateBy90Degrees.Pitch = 16384; // e.g. (90.0f degrees * 65535.0f / 360.0f);
	RealRotation = RotateBy90Degrees + rotator(-TraceNormal);

	CurrentlySelectImpactIndex = -1;

	
	if(TraceInfo.PhysMaterial != none)
		PhysMaterial = XComPhysicalMaterialProperty(TraceInfo.PhysMaterial.GetPhysicalMaterialProperty(class'XComPhysicalMaterialProperty'));

	if(PhysMaterial != none)
	{
		for(i = 0; i < MaterialSpecificImpactData.Length; ++i)
		{
			if(MaterialSpecificImpactData[i].MaterialType == PhysMaterial.MaterialType)
			{
				CurrentlySelectImpactIndex = i;
				break;
			}
		}
	}	

	if (CurrentlySelectImpactIndex == -1)
	{
		// We failed to get a good material off the terrain, just use the first entry
		// so we play _something_.  This should never happen unless there are data errors.

		//`log("WARNING: Material type not found during Trace for weapon impact, using default material (fix the map)");

		if (MaterialSpecificImpactData.Length == 0)
		{
			return false;
		}

		// use the first one first.
		CurrentlySelectImpactIndex = 0;

		// totally make a guess, look for 'dirt'
		/*for (i = 0; i < MaterialSpecificImpactData.Length; ++i)
		{
			if (MaterialSpecificImpactData[i].MaterialType == MaterialType_Dirt)
			{
				CurrentlySelectImpactIndex = i;
			}
		}*/
	}

	return true;
}

simulated function PlayImpactSound()
{
	if (CurrentlySelectImpactIndex == -1 || MaterialSpecificImpactData[CurrentlySelectImpactIndex].ImpactSoundCue == none)
		return;

	ImpactSound = CreateAudioComponent(MaterialSpecificImpactData[CurrentlySelectImpactIndex].ImpactSoundCue, true, false);
}

simulated function Init()
{
	if (!CalcMaterialAtHitPosition())
	{
		DestroyImpactActor();
		return;
	}

	SpawnDecal();
	PlayImpactSound();

	if (!SpawnEffect())
	{
		if (ImpactSound != none)
			ImpactSound.FadeOut(0.5f, 0.0f);

		DestroyImpactActor();
	}
}

defaultproperties
{
	CurrentlySelectImpactIndex = 0
	DefaultDecalThickness = 50
	DefaultDecalScale = 100
	DefaultDecalBackfaceAngle = 0.001f

	bIsPooledActor=false
	bIsCurrentlyInUse=false
}
