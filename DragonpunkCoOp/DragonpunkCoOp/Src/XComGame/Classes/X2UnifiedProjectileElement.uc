//---------------------------------------------------------------------------------------
//  FILE:    X2UnifiedProjectileElement.uc
//  AUTHOR:  Ryan McFall  --  9/12/2014
//  PURPOSE: Represents an element of a projectile being displayed by X2UnifiedProjectile
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2UnifiedProjectileElement extends Object editinlinenew native( Weapon )
	hidecategories( Movement, Display, Attachment, Actor, Collision, Physics, Debug, Object, Advanced );

enum ProjectileType
{
	eProjectileType_Traveling,
	eProjectileType_Ranged,
	eProjectileType_RangedConstant,
};

enum OncePerVolleySetting
{
	eOncePerVolleySetting_None,
	eOncePerVolleySetting_Start,
	eOncePerVolleySetting_End,
};

struct native ProjectileSpread
{
	var()	float HorizontalSpread<ToolTip = "Indicates a maximum random spread angle in degrees">;
	var()	float VerticalSpread<ToolTip = "Indicates a maximum random spread angle in degrees">;
};

//Core settings / variables
var() string						Comment<ToolTip="Use this field to comment on the purpose of this projectile element. Not used in-game.">;
var() ParticleSystem                UseParticleSystem<ToolTip="Assigns a particle effect to this projectile component">;
var() float							ParticleScale<ToolTip="Scale of the particle system">;
var() EmitterInstanceParameterSet   DefaultParticleSystemInstanceParameterSet<ToolTip="Instance parameters that will be fed into UseParticleSystem unless overridden below">;
var() ProjectileType                UseProjectileType<ToolTip="Indicates what type of projectile effect this component will use">;
var() name                          MuzzleSocketName<ToolTip="Indicates the name of the muzzle socket this projectile should come from. Defaults to 'gun_fire'">;
var() bool							bPlayWeaponAnim<ToolTip="If TRUE, this projectile element will trigger the fire animation of its weapon to play">;
var() float							MaxTravelDistanceParam<ToolTip="Value to cap the 'Traveled_Distance' particle param for best looking effect">;
var() float                         MaxTravelTime<ToolTip="If non-zero, the Travel Speed will be effectively increased so that it never takes longer than this much time to reach the target.">;

var(AttachedMesh) SkeletalMesh		AttachSkeletalMesh<ToolTip="Assigns a mesh to this projectile component">;
var(AttachedMesh) AnimTree		    AttachAnimTree<ToolTip="Anim tree the skeletal mesh should use, if set">;
var(AttachedMesh) AnimSet		    AttachAnimSet<ToolTip="Anim set for the attached skeletal mesh">;
var(AttachedMesh) bool              CopyWeaponAppearance<ToolTip="All patterns and colors from the weapon firing the projectile will be copied onto the attached mesh.">;

//ProjectileQuantitySettings   
var(ProjectileSpreadSettings)		int ProjectileCount<ToolTip="Defaults to 1 if this value is set greater 1 then the system will fire multiple instances of this element. Eg. shotgun">;
var(ProjectileSpreadSettings)		bool ApplySpread<ToolTip="Apply spread settings to projectiles of this element">;
var(ProjectileSpreadSettings)		float LongRangeDistance<EditCondition=ApplySpread|ToolTip="Distance (in UE3 units) to consider as 'Long Range' for this element">;
var(ProjectileSpreadSettings)		ProjectileSpread ShortRangeSpread<EditCondition=ApplySpread|ToolTip="Spread settings to interpolate from at distances below LongRangeDistance">;
var(ProjectileSpreadSettings)		ProjectileSpread LongRangeSpread<EditCondition=ApplySpread|ToolTip="Spread settings to interpolate to at distances below LongRangeDistance (and use directly at higer distances)">;
var(ProjectileSpreadSettings)		float MissShotScale<EditCondition=ApplySpread|ToolTip = "Amount to scale the spread for Missed Shots">;
var(ProjectileSpreadSettings)		float SuppressionShotScale<EditCondition=ApplySpread|ToolTip="Amount to scale the spread for Suppression Shots">;
var(ProjectileSpreadSettings)		float CriticalHitScale<EditCondition=ApplySpread|ToolTip="Amount to scale the spread for Critical Hits">;

//ProjectileTravelSettings
var(ProjectileTravelSettings)       bool bCanDamageFragile<ToolTip="If set to TRUE, this projectile will damage fragile actors it passes through while it is in flight / exists">;
var(ProjectileTravelSettings)       bool bCanDamageNonFragile<ToolTip="If set to TRUE, this flag indicates that this projectile can destroy regular destructible actors">;
var(ProjectileTravelSettings)		bool bTriggerHitReact<ToolTip="If set to TRUE, this flag indicates that this projectile should cause the target to react (take damage anim, die anim, etc.)">;
var(ProjectileTravelSettings)       float TravelSpeed<ToolTip="Defines how fast the projectile will appear to move towards the target. May alter position or parameters depending on particle type.">;
var(ProjectileTravelSettings)       float MaximumTrailLength<ToolTip="If non-zero, caps the Trail_Distance particle parameter">;	
var(ProjectileTravelSettings)		vector MicroMissileOffset[3]<ToolTip="Specific offset for the MicroMissile">;
var(ProjectileTravelSettings)		float MicroMissileAdditionalRandomOffset<ToolTip="Additional Random offset scalar">;

//ProjectileHitMissSettings
var(ProjectileHitMissSettings)      bool bPlayOnHit<ToolTip="If set to TRUE, this flag indicates that this projectile element should play on hits">;
var(ProjectileHitMissSettings)      EmitterInstanceParameterSet PlayOnHitOverrideInstanceParameterSet<ToolTip="Overrides instance parameters if the projectile is a hit">;
var(ProjectileHitMissSettings)      bool bPlayOnMiss<ToolTip="If set to TRUE, this flag indicates that this projectile element should play on misses">;
var(ProjectileHitMissSettings)      EmitterInstanceParameterSet PlayOnMissOverrideInstanceParameterSet<ToolTip="Overrides instance parameters if the projectile is a hit">;
var(ProjectileHitMissSettings)      bool bPlayOnSuppress<ToolTip="If set to TRUE, this flag indicates that this projectile element should play during suppression fire">;
var(ProjectileHitMissSettings)      EmitterInstanceParameterSet PlayOnSuppressOverrideInstanceParameterSet<ToolTip="Overrides instance parameters if the projectile is a hit">;

//ProjectileImpactSettings
var(ProjectileImpactSettings)       ParticleSystem PlayEffectOnDeath<ToolTip="Specifies an effect to play when this projectile collides / stops">;
var(ProjectileImpactSettings)       EmitterInstanceParameterSet PlayEffectOnDeathInstanceParameterSet<ToolTip="Instance parameters for the play on death particle system">;
var(ProjectileImpactSettings)       bool bAlignPlayOnDeathToSurface<ToolTip="If PlayOnDeath is set, a TRUE setting here will align the particle system to the normal of the surface it hits">;
var(ProjectileImpactSettings)       XComProjectileImpactActor UseImpactActor<ToolTip="If filled in, the projectile component will spawn this impact actor when it strikes the target">;
var(ProjectileImpactSettings)       ParticleSystem PlayEffectOnTransitHit_Enter<ToolTip = "Specifies an effect to play when this projectile collides with objects while in transit">;
var(ProjectileImpactSettings)       EmitterInstanceParameterSet PlayEffectOnTransitHitInstanceParameterSet_Enter<ToolTip = "Instance parameters for the play on death particle system">;
var(ProjectileImpactSettings)       XComProjectileImpactActor TransitImpactActor_Enter<ToolTip = "If filled in, specifies impact actors to use when the projectile is in transit / on the way to the target">;
var(ProjectileImpactSettings)       ParticleSystem PlayEffectOnTransitHit_Exit<ToolTip = "Specifies an effect to play when this projectile collides with objects while in transit">;
var(ProjectileImpactSettings)       EmitterInstanceParameterSet PlayEffectOnTransitHitInstanceParameterSet_Exit<ToolTip = "Instance parameters for the play on death particle system">;
var(ProjectileImpactSettings)       XComProjectileImpactActor TransitImpactActor_Exit<ToolTip = "If filled in, specifies impact actors to use when the projectile is in transit / on the way to the target">;

//ProjectileAttachmentSettings
var(RangedProjectileAttachmentSettings)   bool bAttachToSource<ToolTip="Checking this option attaches the projectile component to the source of the projectile">;
var(RangedProjectileAttachmentSettings)   bool bAttachToTarget<ToolTip="Checking this option forces the target location to continuously update ( tracks movement )">;	
var(RangedProjectileAttachmentSettings)   Name TargetAttachSocket<EditCondition=bAttachToTarget|ToolTip="When attaching to target, it will anchor the projectile to this socket on the target.">;
var(RangedProjectileAttachmentSettings)   bool bLockOrientationToMuzzle<ToolTip="Checking this forces projectile effect to align with the muzzle node on the firing weapon">;
var(RangedProjectileAttachmentSettings)   bool bContinuousDistanceUpdates;
var(RangedProjectileAttachmentSettings)   float MinImpactInterval<EditCondition=bContinuousDistanceUpdates|ToolTip="Minimum number of seconds between playing impact events for this continuous projectile.">;
var(RangedProjectileAttachmentSettings)   float MultiImpactWindowLength<EditCondition=bContinuousDistanceUpdates|ToolTip="Maximum number of seconds that after firing that impact events are allowed (0 means play impacts for the whole life of the projectile)">;

//ProjectileVolleySettings
var(ProjectileVolleySettings)       OncePerVolleySetting UseOncePerVolleySetting<ToolTip="Controls whether this projectile component fires with each shot of a volley. Otherwise it fires only once based on the delay value below">;	
var(ProjectileVolleySettings)       float OncePerVolleyDelay<ToolTip="Time in seconds from the beginning or ending of the volley that this projectile component should fire">;		

//ProjectileCustomEffectSettings
var(ProjectileCustomEffectSettings) bool bIsCustomDefinition<ToolTip="If TRUE indicates this component of the projectile effect is meant to be called via a 'custom volley' in animation">;	
var(ProjectileCustomEffectSettings) int CustomID<EditCondition=bIsCustomDefinition|ToolTip="The ID that the custom volley notify in animation will use to refer to this projectile component">;

//ProjectileSoundEffectSettings
var(ProjectileSoundEffectSettings)  AkEvent FireSound<ToolTip="If set, will trigger a sound when this projectile element is fired">;
var(ProjectileSoundEffectSettings)  AkEvent DeathSound<ToolTip="This sound will play when the projectile dies">;

var(ProjectileReturnToSourceSettings)	bool ReturnsToSource<ToolTip="If set, projectile will return to it's source after reaching it's destination">;
var(ProjectileReturnToSourceSettings)	float TimeOnTarget<EditCondition=ReturnsToSource|ToolTip="How long to remain at the target before turning around">;
var(ProjectileReturnToSourceSettings)	float ReturnSpeed<EditCondition=ReturnsToSource|ToolTip="How fast the projectile should travel back to it's source">;

DefaultProperties
{	
	UseProjectileType=eProjectileType_Traveling
	MuzzleSocketName="gun_fire"
	bPlayWeaponAnim=false
	ProjectileCount=1
	bCanDamageFragile=true
	bCanDamageNonFragile=true
	bTriggerHitReact=false
	TravelSpeed=1000
	MaximumTrailLength=0.0
	bPlayOnHit=true	
	bPlayOnMiss=true	
	bPlayOnSuppress=true	
	bAlignPlayOnDeathToSurface=false
	bAttachToSource=false
	bAttachToTarget=false
	bLockOrientationToMuzzle=false		
	UseOncePerVolleySetting=eOncePerVolleySetting_None
	OncePerVolleyDelay=0.0
	bIsCustomDefinition=false
	CustomID=-1
	MissShotScale=1.5;
	SuppressionShotScale=2.0;
	CriticalHitScale=0.5;

	ApplySpread=false;
	ParticleScale=1.0
	MaxTravelDistanceParam=3000.0
}
