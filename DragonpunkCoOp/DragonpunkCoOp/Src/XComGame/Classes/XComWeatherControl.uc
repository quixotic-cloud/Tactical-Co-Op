//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComWeatherControl.uc
//  AUTHOR:  Jeremy Shopf -- 05/21/09
//  PURPOSE: Actor which manages particles systems, sound, etc. associated with weather
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComWeatherControl extends Actor
	native(Graphics)
	placeable;

var bool    m_bRainy;
var bool    m_bWet; // It has been raining at some point but not maybe not currently
var bool    m_bFade;
var bool    m_bFadeOut;
var bool    m_bInitialized;
var() float m_fIntensity;
var() float m_fOpacityModifier;
var float   m_fBuildingWeatherFade;
var() float m_fBuildingWeatherFadeRate;
var float   m_fEmitterDistance;
var float   m_fFadeDistance;
var float   m_fGlobalSpawnRate;
var float   m_fDT;
var bool    m_bNeedsMPInit;

// Depth capture
var Actor  BoundingActor;
var SceneCapture2DComponent m_kStaticDepthCapture;
var SceneCapture2DComponent m_kDynamicDepthCapture;
var TextureRenderTarget2D   m_kStaticDepthTexture;
var TextureRenderTarget2D   m_kDynamicDepthTexture;
var int                     m_nDynamicCaptureFrustumX;
var int                     m_nDynamicCaptureFrustumY;
var Rotator                 m_kCaptureRotator;
var vector m_kBVDimensions;
var vector m_kBVCenter;

// Lightning
var     float           m_fFlashTime;
var     Color           m_kOriginalColor;
var float           m_fOriginalBrightness;
var const float     m_fLightningFlashLength;

var float CurrentThunderClapProbability;

struct native LightningFlashPulse
{
	var float fFrequency;
	var float fIntensity;
};

var array<LightningFlashPulse>    m_kLightningFlash;

// Wind
var vector m_kWindVelocity;

// Lit Rain
var() ParticleSystem      m_kDLightTemplate;
var ParticleSystem      m_kPLightTemplate;
var ParticleSystem      m_kSLightTemplate;
var() ParticleSystem      m_kSplashTemplate;
var MaterialInterface   m_kPointLightMI;
var MaterialInterface   m_kSpotLightMI;
var() MaterialInterface   m_kDirectionalLightMI;
var() MaterialInterface   m_kSplashMI;
var() MaterialInstanceConstant m_kPuddleMIC;


struct native LightEmitterInstance
{
	var Emitter LightEmitter;
	var MaterialInstanceConstant LightEmitterMaterialConstant;
	var float fSpawnRate;
	var float fMaxLifetime;
};


var LightEmitterInstance m_kSplashEmitter;                      // Splash particle emitter
var LightEmitterInstance m_kGlobalRainEmitter;                  // "Global" rain emitter

var() SoundCue  m_sThunderClap;
var() SoundCue m_sThunderRumble;

var DominantDirectionalLight m_kDominantDirectionalLight;

enum StormIntensity_t
{
	NoStorm,
	DistantGatheringStorm,
	LightRain,
	LightStorm,
	ModerateStorm,
	SevereStorm,
	Hurricane,
	Custom
};

var() StormIntensity_t StormIntensity;
var() Color            LightningColor;
var() float            LightningIntensity;
var() float            RainOpacity<DisplayName=Rain Opacity>;
var() int              RainSoundIntensity;
var() float            ThunderClapProbability;
var() float            RainScale;

// NOTE: final native functions are automagically simulated so no need to tag them as such. -tsmith 

/** Set emission on all material instances that have the "UseRainToD? scalar parameter.
	This function is also called by the cheat manager 
*/
final native static function SetAllAsWet(bool bWet);

final native function InitEmitters();
final native function SetEmitterMaterials( Emitter ParentEmitter, MaterialInterface NewMaterialInterface );
final native function SetRainScale( float fScale );
final native function UpdateWindDirection( );
final native function float CalculateLightningIntensity( float fNormalizedFlashTime );

cpptext
{
	bool CreateGlobalEmitter();

	virtual void PreSave();

	/** Set emission on all material instances that have the "UseRainToD? scalar parameter. 
		This function is also called by the editor
	*/
	static void SetAllAsWetStaticFunction(UBOOL bWet);

	/* // For debugging
	UBOOL AXComWeatherControl::Tick( FLOAT DeltaSeconds, ELevelTick TickType )
	{
		return AActor::Tick(DeltaSeconds, TickType);
	}*/
}


// Spawn a rain emitter for the global rain
simulated event SpawnDirectionalEmitter( Vector kDirection, float fOpacity )
{
	local LinearColor tmpCol;

	// Create material instance constant
	m_kGlobalRainEmitter.LightEmitterMaterialConstant = new(self) class'MaterialInstanceConstant';
	m_kGlobalRainEmitter.LightEmitterMaterialConstant.SetParent(m_kDirectionalLightMI);

	// Calculate opacity based on brightness.. the brighter it is, the less opaque
	m_kGlobalRainEmitter.LightEmitterMaterialConstant.SetScalarParameterValue('OpacityModifier', fOpacity );

	UpdateDirectionalEmitterMIC( fOpacity );

	// Set MICs for heighmap sampling
	tmpCol = MakeLinearColor( m_kBVCenter.X,  m_kBVCenter.Y, m_kBVCenter.Z, m_kBVCenter.Z + m_kBVDimensions.Z/2.0 );
	m_kGlobalRainEmitter.LightEmitterMaterialConstant.SetVectorParameterValue('LevelBoundsCenter', tmpCol );
	tmpCol = MakeLinearColor( m_kBVDimensions.X, m_kBVDimensions.Y, m_kBVDimensions.Z, 1 );
	m_kGlobalRainEmitter.LightEmitterMaterialConstant.SetVectorParameterValue('LevelBoundsExtent', tmpCol );

	m_kGlobalRainEmitter.LightEmitterMaterialConstant.SetTextureParameterValue('OrthoDepth', m_kStaticDepthTexture );

	// Spawn the emitter
	m_kGlobalRainEmitter.LightEmitter = Spawn(class'EmitterSpawnable', self, ,);
	m_kGlobalRainEmitter.LightEmitter.ParticleSystemComponent.bAutoActivate = false;
	m_kGlobalRainEmitter.LightEmitter.bCurrentlyActive = false;
	m_kGlobalRainEmitter.LightEmitter.SetTemplate(m_kDLightTemplate, false); 
	m_kGlobalRainEmitter.LightEmitter.ParticleSystemComponent.SetActive( false );

	// Set wind velocity
	m_kGlobalRainEmitter.LightEmitter.ParticleSystemComponent.SetVectorParameter('WindVelocity', m_kWindVelocity );

	// Set the spawn rate scale
	m_kGlobalRainEmitter.LightEmitter.ParticleSystemComponent.SetFloatParameter('SpawnRateScale', m_fGlobalSpawnRate );
	m_kGlobalRainEmitter.LightEmitter.ParticleSystemComponent.SetFloatParameter('Lifetime', 0.5 );

	// Assign the material to the emitter actor
	SetEmitterMaterials( m_kGlobalRainEmitter.LightEmitter, m_kGlobalRainEmitter.LightEmitterMaterialConstant );
}

simulated function UpdateDirectionalEmitterMIC( float fOpacity )
{
	m_kGlobalRainEmitter.LightEmitterMaterialConstant.SetScalarParameterValue('OpacityModifier', fOpacity );
}

// Spawn an emitter that will handle splashes on the ground
simulated event SpawnSplashEmitter()
{
	local LinearColor tmpCol;
	// Spawn the emitter and rotate it to be aligned with the z-axis of the cylinder
	m_kSplashEmitter.LightEmitter = Spawn(class'EmitterSpawnable', self, , , );
	m_kSplashEmitter.LightEmitter.ParticleSystemComponent.bAutoActivate = false;
	m_kSplashEmitter.LightEmitter.bCurrentlyActive = false;
	m_kSplashEmitter.LightEmitter.SetTemplate(m_kSplashTemplate, false);
	m_kSplashEmitter.LightEmitter.ParticleSystemComponent.SetActive( false );

	// Create a new material instance constant
	m_kSplashEmitter.LightEmitterMaterialConstant = new(self) class'MaterialInstanceConstant';
	m_kSplashEmitter.LightEmitterMaterialConstant.SetParent(m_kSplashMI);

	tmpCol = MakeLinearColor( m_kBVCenter.X,  m_kBVCenter.Y, m_kBVCenter.Z, m_kBVCenter.Z + m_kBVDimensions.Z/2.0 );
	m_kSplashEmitter.LightEmitterMaterialConstant.SetVectorParameterValue('LevelBoundsCenter', tmpCol );
	tmpCol = MakeLinearColor( m_kBVDimensions.X, m_kBVDimensions.Y, m_kBVDimensions.Z, 1 );
	m_kSplashEmitter.LightEmitterMaterialConstant.SetVectorParameterValue('LevelBoundsExtent', tmpCol );

	m_kSplashEmitter.LightEmitterMaterialConstant.SetTextureParameterValue('OrthoDepth', m_kStaticDepthTexture );
	m_kSplashEmitter.LightEmitterMaterialConstant.SetTextureParameterValue('DynamicOrthoDepth', m_kDynamicDepthTexture );
	

	// Assign the material to the emitter actor
	SetEmitterMaterials( m_kSplashEmitter.LightEmitter, m_kSplashEmitter.LightEmitterMaterialConstant );
}

simulated function UpdateSplashEmitterMIC( float fOpacity )
{
	// Calculate opacity based on brightness.. the brighter it is, the less opaque
	m_kSplashEmitter.LightEmitterMaterialConstant.SetScalarParameterValue('OpacityModifier', fOpacity );
}

simulated function TriggerFlash()
{
	if( m_kDominantDirectionalLight != none )
	{
		m_kOriginalColor = m_kDominantDirectionalLight.LightComponent.LightColor;
		m_fOriginalBrightness = m_kDominantDirectionalLight.LightComponent.Brightness;
		m_fFlashTime = m_fLightningFlashLength;
		InitializeLightningFlash( m_kLightningFlash );
	}
}

// Define a series of sine functions for the lightning flash
simulated function InitializeLightningFlash( array<LightningFlashPulse> kLightningFlash )
{
	local int i;
	local LightningFlashPulse kNewPulse;

	// Insert flash pulses into lightning flash
	for( i=0; i<5; i++ )
	{
		kNewPulse.fIntensity = (FRand()*0.5+0.5);
		kNewPulse.fFrequency = FRand();
		m_kLightningFlash.AddItem( kNewPulse );
	}
}

simulated function OnTimeOfDayChange()
{


}

// Toggle rain, updating all emitters
simulated function ToggleRain()
{
	if( m_bInitialized )
	{
		m_bRainy = !m_bRainy;

		// Enable/Disable all light emitters
		m_kGlobalRainEmitter.LightEmitter.ParticleSystemComponent.SetActive( m_bRainy );

		// Toggle splash emitter
		m_kSplashEmitter.LightEmitter.ParticleSystemComponent.SetActive( m_bRainy );

		m_kDynamicDepthCapture.SetEnabled(TRUE);
		m_kStaticDepthCapture.SetEnabled(TRUE);
	}
}

function OnThunderClapLoaded(Object LoadedArchetype)
{
	m_sThunderClap = SoundCue(LoadedArchetype);
}

function OnThunderRumbleLoaded(Object LoadedArchetype)
{
	m_sThunderRumble = SoundCue( LoadedArchetype );
}

simulated function SetThunderClapProbability( float fThunderClapProbability )
{
	if(fThunderClapProbability > 1.0f)
		CurrentThunderClapProbability = 1.0f;

	if (fThunderClapProbability > 0.0f)
	{
		`CONTENT.RequestGameArchetype("SoundAmbience.ThunderClap", self, OnThunderClapLoaded, true);
		`CONTENT.RequestGameArchetype("SoundAmbience.ThunderRumble", self, OnThunderRumbleLoaded, true);
	}

	CurrentThunderClapProbability = fThunderClapProbability;
}

simulated function TriggerThunderClapSound()
{

	if (m_sThunderClap != none)
		PlaySound(m_sThunderClap);

	SetTimerForNextThunder();
}

simulated function TriggerThunderAndLightning()
{
	local bool bThunderClap;

	SetTimerForNextThunder();

	if (CurrentThunderClapProbability <= 0.0f) // thunder disabled
		return;

	bThunderClap = FRand() <= CurrentThunderClapProbability;
	
	if (!bThunderClap)
	{
		if( m_sThunderRumble != none )
		{
			PlaySound( m_sThunderRumble );
		}
	}
	else
	{
		TriggerFlash();
		ClearTimer('TriggerThunderAndLightning');
		SetTimer(2 * FRand(),false,'TriggerThunderClapSound');
	}
}

simulated function SetTimerForNextThunder()
{
	local float BaseTime;
	BaseTime = 10.0f;

	if (CurrentThunderClapProbability > 0.0f)
	{
		BaseTime -= CurrentThunderClapProbability * BaseTime;
	}

	ClearTimer('TriggerThunderAndLightning');
	SetTimer(BaseTime + BaseTime * 2 * FRand(),false,'TriggerThunderAndLightning');
}

// Set current storm intensity
simulated function SetStormIntensity( StormIntensity_t NewStormIntensity, int NewRainSoundIntensity, float NewThunderClapProbability, float NewRainScale )
{
	local bool bNeedsRain;

	StormIntensity = NewStormIntensity;
	RainSoundIntensity = NewRainSoundIntensity;
	ThunderClapProbability = NewThunderClapProbability;
	RainScale = NewRainScale;

	if (m_bInitialized)
	{
		bNeedsRain = NewStormIntensity != NoStorm && NewStormIntensity != DistantGatheringStorm;

		if ((bNeedsRain && !m_bRainy) || (!bNeedsRain && m_bRainy))
			ToggleRain();

		switch(NewStormIntensity)
		{
			case NoStorm:
				SetThunderClapProbability(-1);
				SetRainScale(0);
				// SetState for audio
				SetState('Weather', 'NoRain');
				break;
			case DistantGatheringStorm:
				SetThunderClapProbability(0);
				SetRainScale(0);
				SetState('Weather', 'NoRain');
				break;
			case LightRain:
				SetThunderClapProbability(-1);
				SetRainScale(0.5);
				SetState('Weather', 'NoRain');
				break;
			case LightStorm:
				SetThunderClapProbability(0.25f);
				SetRainScale(0.5);
				SetState('Weather', 'Rain');
				break;
			case ModerateStorm:
				SetThunderClapProbability(0.5f);
				SetRainScale(1);
				SetState('Weather', 'Rain');
				break;
			case SevereStorm:
				SetThunderClapProbability(0.75f);
				SetRainScale(2.5);
				SetState('Weather', 'Rain');
				break;
			case Hurricane:
				SetThunderClapProbability(0.9f);
				SetRainScale(6);
				SetState('Weather', 'Rain');
				break;
			case Custom:
				SetThunderClapProbability(ThunderClapProbability);
				SetRainScale(RainScale);
				if (ThunderClapProbability > 0.0f)
				{
					SetState('Weather', 'Rain');
				}
				else
				{
					SetState('Weather', 'NoRain');
				}
			default:
				return;
		}

		SetTimerForNextThunder();
	}
	else
	{
		`log("Unable to set storm intensity, because the weather controller has not been initialized.");
	}
}

// Set the directional light's intensity based on lighting flash timing
simulated function LightningRenderUpdate( float fDt )
{
	local float fNormalizedFlashTime;
	local float fIntensity;

	// If lightning's flashing, stop (debug hack)
	if( m_fFlashTime > 0.0 )
	{
		m_fFlashTime -= fDt;
		fNormalizedFlashTime = m_fFlashTime/m_fLightningFlashLength;

		// Lerp color		
		fIntensity = Lerp( m_fOriginalBrightness, FClamp(m_fOriginalBrightness*LightningIntensity, 0.0, 155.0), FClamp(CalculateLightningIntensity(fNormalizedFlashTime)**3, 0.0, 1.0)+0.4 );
		m_kDominantDirectionalLight.LightComponent.SetLightProperties( fIntensity, LightningColor );
	}
	else
	{
		m_kDominantDirectionalLight.LightComponent.SetLightProperties(m_fOriginalBrightness, m_kOriginalColor);
	}
}

simulated function PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	if( m_bInitialized )
	{
		Canvas.SetPos(0, 0);
		Canvas.DrawTile(m_kStaticDepthTexture, 400, 400, 0, 0, m_kStaticDepthTexture.SizeX, m_kStaticDepthTexture.SizeY);

		Canvas.SetPos( 600, 0);
		Canvas.DrawTile(m_kDynamicDepthTexture, 400, 400, 0, 0, m_kDynamicDepthTexture.SizeX, m_kDynamicDepthTexture.SizeY);
	}

}

simulated function SetupRenderTextures()
{
	local EPixelFormat TextureFormat;
	
	//if(WorldInfo.IsConsoleBuild(CONSOLE_PS3))
	TextureFormat = PF_R32F;

	m_kStaticDepthTexture = /*ScriptedTexture*/(class'TextureRenderTarget2D'.static.Create(512, 512, TextureFormat, MakeLinearColor(1, 1, 1, 1), false, true, false, self));
	m_kStaticDepthTexture.SRGB = false;
	m_kStaticDepthTexture.Filter = TF_Nearest;
	m_kStaticDepthTexture.bNeedsTwoCopies = false;

	m_kDynamicDepthTexture = /*ScriptedTexture*/(class'TextureRenderTarget2D'.static.Create(256, 256, TextureFormat, MakeLinearColor(1, 1, 1, 1), false, true, false, self));
	m_kDynamicDepthTexture.SRGB = false;
	m_kDynamicDepthTexture.Filter = TF_Nearest;
	m_kDynamicDepthTexture.bNeedsTwoCopies = false;

	if( m_kStaticDepthTexture == none || m_kDynamicDepthTexture == none )
	{
		`warn( "Error initializing Weather Depth render textures" );
	}
}

// Initialize the Scene Capture actor according to the bounding volume associated with the weathercontroller
simulated function InitDepthCapture()
{
	local Box       kBoundingBox;
	local Vector    kCapturePosition;
	local XComRainVolume kRainVolume;
	local Vector    kExplorationMin;
	local Vector    kExplorationMax;

	// Large mag. init BB values
	kExplorationMin.X = 99999999;
	kExplorationMin.Y = 99999999;
	kExplorationMin.Z = 99999999;
	kExplorationMax.X = -99999999;
	kExplorationMax.Y = -99999999;
	kExplorationMax.Z = -99999999;

	if( BoundingActor == none )
	{
		// Find bounds of all exploration volumes
		foreach AllActors(class'XComRainVolume', kRainVolume)
		{
			kRainVolume.GetComponentsBoundingBox(kBoundingBox);
			kExplorationMin.X = FMin( kExplorationMin.X, kBoundingBox.Min.X );
			kExplorationMin.Y = FMin( kExplorationMin.Y, kBoundingBox.Min.Y );
			kExplorationMin.Z = FMin( kExplorationMin.Z, kBoundingBox.Min.Z );

			kExplorationMax.X = FMax( kExplorationMax.X, kBoundingBox.Max.X );
			kExplorationMax.Y = FMax( kExplorationMax.Y, kBoundingBox.Max.Y );
			kExplorationMax.Z = FMax( kExplorationMax.Z, kBoundingBox.Max.Z );

			//`warn( "min : " @ kExplorationMin.x @ " " @ kExplorationMin.y  @" " @ kExplorationMin.z );
			//`warn( "max : " @ kExplorationMax.x @ " " @ kExplorationMax.y @ " " @ kExplorationMax.z );
		}
	}
	else
	{
		BoundingActor.GetComponentsBoundingBox( kBoundingBox );
		kExplorationMin = kBoundingBox.Min;
		kExplorationMax = kBoundingBox.Max;
	}	

	m_kBVCenter = (kExplorationMin + kExplorationMax)/2.0;
	m_kBVDimensions = kExplorationMax - kExplorationMin;

	// Offset capture actor so that it is at the Z-extent of the bounding box
	kCapturePosition = m_kBVCenter;
	kCapturePosition.Z += m_kBVDimensions.Z/2.0;

	// Should be rotated facing down
	m_kCaptureRotator.Pitch = 270.0*65535.0f / 360.0f; // Convert degrees to fixed point rep. 
	m_kCaptureRotator.Roll = 0.0;
	m_kCaptureRotator.Yaw = 270.0*65535.0f / 360.0f;   // Convert degrees to fixed point rep. 

	SetupRenderTextures();

	// ============== Static scene's depth capture
	//if( m_bRainy )
	//{
		// Create an actor to capture the static scene's depth image
		m_kStaticDepthCapture.ViewMode = SceneCapView_Depth;
		m_kStaticDepthCapture.RenderChannels.RainCollisionStatic = true;
		m_kStaticDepthCapture.RenderChannels.MainScene = false;
		m_kStaticDepthCapture.SetFrameRate(0.0);

		// Set camera parameters to contain the bounding area of BoundingActor
 		m_kStaticDepthCapture.SetCaptureParameters( m_kStaticDepthTexture,
								m_kStaticDepthCapture.FieldOfView, 1, m_kBVDimensions.Z, m_kBVDimensions.X/2.0,
								m_kBVDimensions.Y/2.0 );

		m_kStaticDepthCapture.SetView( kCapturePosition, m_kCaptureRotator );
		m_kStaticDepthCapture.ClearColor = MakeColor(255,255,255,255);

		AttachComponent(m_kStaticDepthCapture);


		// ============== Dynamic scene's depth capture
		m_kDynamicDepthCapture.ViewMode = SceneCapView_Depth;
		m_kDynamicDepthCapture.RenderChannels.RainCollisionStatic = false;
		m_kDynamicDepthCapture.RenderChannels.RainCollisionDynamic = true;
		m_kDynamicDepthCapture.RenderChannels.MainScene = false;
		m_kDynamicDepthCapture.SetFrameRate(33.0);

		// Set camera parameters to contain the bounding area of BoundingActor
 		m_kDynamicDepthCapture.SetCaptureParameters( m_kDynamicDepthTexture,
								m_kDynamicDepthCapture.FieldOfView, 1, m_kBVDimensions.Z, m_nDynamicCaptureFrustumX,
								m_nDynamicCaptureFrustumY );

		m_kDynamicDepthCapture.SetView( kCapturePosition, m_kCaptureRotator );
		m_kDynamicDepthCapture.ClearColor = MakeColor(255,255,255,255);

		AttachComponent(m_kDynamicDepthCapture);

		m_kStaticDepthCapture.SetEnabled(false);
		m_kDynamicDepthCapture.SetEnabled(false);
	//}

}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	m_bInitialized = false;

	if (class'Engine'.static.GetCurrentWorldInfo().GRI == none)
	{
		m_bNeedsMPInit = true;
	}
}

simulated function InitBoundingActor()
{
	local XComLevelVolume LevelVolume;

	foreach AllActors(class'XComLevelVolume', LevelVolume)
	{
		BoundingActor = LevelVolume;
	}
}

simulated function Init()
{
	if( m_kDominantDirectionalLight != none )
	{
		//Find the Level volume to use as the bounding actor
		InitBoundingActor();

		// Spawn depth capture actor 
		InitDepthCapture();

		// Set up all particle emitters
		InitEmitters();

		m_kOriginalColor = m_kDominantDirectionalLight.LightComponent.LightColor;
		m_fOriginalBrightness = m_kDominantDirectionalLight.LightComponent.Brightness;

		m_bInitialized = true;

		SetTimerForNextThunder();
		SetStormIntensity(StormIntensity, RainSoundIntensity, ThunderClapProbability, RainScale);
	}
}

// Update scene capture actor and MICs that need updated ortho frustum data
//
//      Vector CameraPosition    Position of the game gamera
simulated function UpdateDynamicRainDepth( Vector CameraPosition )
{
	local Vector CapturePosition;
	local LinearColor tmpCol;

	CapturePosition = CameraPosition;
	CapturePosition.Z = m_kBVCenter.Z + m_kBVDimensions.Z/2.0; // Put camera at the top of the rain volume bounding box

	m_kDynamicDepthCapture.SetView( CapturePosition, m_kCaptureRotator );
	AttachComponent( m_kDynamicDepthCapture );

	// Update the dynamic depth map project parameters in the splash effect
	tmpCol = MakeLinearColor( CapturePosition.X,  CapturePosition.Y, m_kBVCenter.Z, m_kBVCenter.Z + m_kBVDimensions.Z/2.0 );
	m_kSplashEmitter.LightEmitterMaterialConstant.SetVectorParameterValue('CameraBoundsCenter', tmpCol);
	tmpCol = MakeLinearColor( m_nDynamicCaptureFrustumX, m_nDynamicCaptureFrustumY, m_kBVDimensions.Z, 1 );
	m_kSplashEmitter.LightEmitterMaterialConstant.SetVectorParameterValue('CameraBoundsExtent', tmpCol );
	m_kSplashEmitter.LightEmitterMaterialConstant.SetTextureParameterValue('DynamicOrthoDepth', m_kDynamicDepthTexture );
}

// Update static depth capture
simulated event UpdateStaticRainDepth()
{
	if( m_bRainy )
	{
		m_kStaticDepthCapture.SetFrameRate(0.0);
		AttachComponent(m_kStaticDepthCapture);
	}
}

// Enable/Fade/Disable weather decals
simulated event UpdateWeatherDecals()
{
	local XComWeatherDecalActor kDecalActor;
	local bool bSetHidden;

	// Determine if all decals should be hidden
	if( m_fGlobalSpawnRate <= 0.0 && !m_bWet )
	{
		bSetHidden = true;
	}
	else
	{
		bSetHidden = false;
	}

	// Update the decals
	foreach AllActors(class'XComWeatherDecalActor', kDecalActor)
	{
		kDecalActor.SetHidden(bSetHidden);
	}
}

simulated event Tick(float dt)
{
	local Vector CameraPosition;
	local XCom3DCursor kCursor;
	local XComPlayerController kLocalPC;
	local bool bShouldFadeOut;

	m_fDT = dt;

	if( m_bInitialized )
	{
		OnTimeOfDayChange(); // This only needs to happen on timeofday change. currently here for debug

		LightningRenderUpdate(dt);

		// Get the player controller and camera
		foreach WorldInfo.LocalPlayerControllers( class 'XComPlayerController', kLocalPC )
		{
			if( kLocalPC.Player != none )
			{
				break;
			}
		}

		// If it's raining, peform emitter fading
		if( m_bRainy )
		{
			CameraPosition = kLocalPC.PlayerCamera.ViewTarget.POV.Location;

			//// Loop over all lights and enable/disable them based on distance
			//for (i=0;i<m_SpawnedStaticEmitters.Length;i++)
			//{
			//	EmitterDistance = m_SpawnedStaticEmitters[i].LightEmitter.Location - CameraPosition;
				
			//	// Only enable if the system is disabled
			//	if( VSize( EmitterDistance ) > m_fEmitterDistance )
			//	{
			//		m_SpawnedStaticEmitters[i].LightEmitter.ParticleSystemComponent.SetActive(false);
			//	}
			//	else
			//	{
			//		if( !m_SpawnedStaticEmitters[i].LightEmitter.ParticleSystemComponent.bIsActive )
			//		{
			//			m_SpawnedStaticEmitters[i].LightEmitter.ParticleSystemComponent.SetActive(true);
			//		}
			//	}

			//	// Set the emitters' alpha fade value by its distance
			//	fAlphaFade = 1.0 - FClamp( (VSize( EmitterDistance ) - m_fFadeDistance)/(m_fEmitterDistance - m_fFadeDistance), 0.0, 1.0 );
			//	m_SpawnedStaticEmitters[i].LightEmitterMaterialConstant.SetScalarParameterValue('Fade', fAlphaFade );
			//}

			UpdateDynamicRainDepth( CameraPosition );
		}

		// Procedural wind
		UpdateWindDirection( );

		// This is really cheap, so just do it every frame.
		bShouldFadeOut = false;
		if (kLocalPC.IsA('XComTacticalController'))
		{
			kCursor = XCom3DCursor(XComTacticalController(kLocalPC).Pawn);
				// If inside and not on the roof.
			if ( kCursor.IndoorInfo.IsInside() && !kCursor.IndoorInfo.IsOnRoof() )
			{
				bShouldFadeOut = true;
			}
		}
		if (bShouldFadeOut)
			StartFadingOutParticles();
		else
			StartFadingInParticles();

		if( m_bFade )
		{
			FadeParticles();
		}
	}
	else if (m_bNeedsMPInit && class'Engine'.static.GetCurrentWorldInfo().GRI != none)
	{
		// Deferred init until we have a GRI
		Init();
		m_bNeedsMPInit = false;
	}
}

simulated function StartFadingInParticles()
{
	if( m_fBuildingWeatherFade < 1.0 )
	{
		m_bFade = true;
		m_bFadeOut = false;
	}
}

simulated function StartFadingOutParticles()
{
	if( m_fBuildingWeatherFade > 0.0 )
	{
		m_bFade = true;
		m_bFadeOut = true;
	}
}


simulated function FadeParticles()
{
	//`log(m_fBuildingWeatherFade);
	if( m_bFadeOut )
	{
		m_fBuildingWeatherFade = FClamp( m_fBuildingWeatherFade - m_fBuildingWeatherFadeRate * m_fDT, 0.0, 1.0 );
		UpdateSplashEmitterMIC( m_fBuildingWeatherFade );
	}
	else
	{
		m_fBuildingWeatherFade = FClamp( m_fBuildingWeatherFade + m_fBuildingWeatherFadeRate * m_fDT, 0.0, 1.0 );
		UpdateSplashEmitterMIC( m_fBuildingWeatherFade );
	}

	if( m_fBuildingWeatherFade <= 0.0 && m_fBuildingWeatherFade >= 1.0 )
	{
		m_bFade = false;
	}
}

defaultproperties
{
	m_bRainy=false;
	m_bWet=false;
	m_bFadeOut=true;
	m_bFade=false;
	m_bInitialized=false;
	m_fGlobalSpawnRate=0.0;
	m_fEmitterDistance=3500.0;
	m_fFadeDistance=1500.0;
	m_fOpacityModifier=6.0;
	m_fBuildingWeatherFade=1.0;
	m_fBuildingWeatherFadeRate=1.0;
	m_kWindVelocity=(X=300,Y=0.0,Z=0.0);
	m_fLightningFlashLength=0.4;
	m_nDynamicCaptureFrustumX = 1000;
	m_nDynamicCaptureFrustumY = 1000;

	m_kDLightTemplate=ParticleSystem'FX_Weather.Particles.RainDirectional';
	m_kSplashTemplate=ParticleSystem'FX_Weather.Particles.P_Splashes';
	m_kDirectionalLightMI=MaterialInterface'FX_Weather.Materials.RaindropsDirectional';
	m_kSplashMI=MaterialInterface'FX_Weather.Materials.MPar_Splashes';
	m_kPuddleMIC = MaterialInstanceConstant'FX_Weather.Materials.M_PuddleDecalINST';
	BoundingActor=none;

	LightningColor=(R=76,G=103,B=245,A=255);
	LightningIntensity=5.0;
	RainOpacity=1.0;

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_Actor'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite)

	// 2D scene capture 
	Begin Object Class=SceneCapture2DComponent Name=SceneCapture2DComponent0
		bSkipUpdateIfOwnerOccluded=false
		MaxUpdateDist=0.0
		MaxStreamingUpdateDist=0.0
		bUpdateMatrices=false
		NearPlane=10000
		FarPlane=1
	End Object
	m_kStaticDepthCapture=SceneCapture2DComponent0	

	Begin Object Class=SceneCapture2DComponent Name=SceneCapture2DComponent1
		bSkipUpdateIfOwnerOccluded=false
		MaxUpdateDist=0.0
		MaxStreamingUpdateDist=0.0
		bUpdateMatrices=false
		NearPlane=10000
		FarPlane=1
	End Object
	m_kDynamicDepthCapture=SceneCapture2DComponent1

	// we are spawned if an instance hasnt been placed in the level so we can't be static or no delete -tsmith 
	bStatic=false
	bNoDelete=false

	// network variables -tsmith
	m_bNoDeleteOnClientInitializeActors=true

	RemoteRole=ROLE_Authority
}

