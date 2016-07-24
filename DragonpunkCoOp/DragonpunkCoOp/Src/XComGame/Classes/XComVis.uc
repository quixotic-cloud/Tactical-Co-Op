//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComVis.cpp
//  AUTHOR:  Elliot Pace
//  PURPOSE: This class is responsible for creating and updating resource(s) and binding them to the 
//           outline-edge post process effect MIC.
//           ** This does not handle a change in screen resolution.  m_kRT needs to be recreated in that case. **
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComVis extends Actor
	native;

var SceneCapture2DComponent m_kCapturePrimary;
var SceneCapture2DComponent m_kCaptureSecondary;

var XComCamera m_kCamera;
var Vector2D m_vTargetSize;
var Vector2D m_vBufferSize;

var TextureRenderTarget2D m_kRT;
var float m_fPrevFOV;
var int m_nDownsampleFactor;

var PostProcessChain m_kPPChain;
var XComEdgeEffect m_kEdgeEffect;
var MaterialInstanceConstant m_kMIC;
var Texture m_kOldTexture;

var LinearColor m_3POutlineColor;
var LinearColor m_BuildingOutlineColor;

/*
Some random notes about MICS and PostProcessEffects:

Basically.. post process effects in the post process chain are not safe to enable/disable through script.

If a post process effect is bound to a MIC and bShowInGame == false then 
- Enabling it (setting bShowInGame=true) via MaterialEffect(PPChain.FindPostProcessEffect('NameOfEffect')) has no effect and the constants of the MIC are reverted to the oringal parent.
- And not surprisingly, changing constants in the MIC through MaterialEffect.Material also has no effect.

If a post process effect bound to a MIC and bShowInGame == true then
- The MIC can be retrieved either directly 
(e.g. MIC=MaterialInstanceConstant'epacePackage.MInst_Edge') 
or through the MaterialEffect 
(e.g. MIC=(PostProcessChain'XComEngineMaterials.DefaultScenePostProcess').FindPostProcessEffect('Edge').Material).

If a post process effect bShowInGame == true then
- Disabling it in script has no effect.

-EPACE
*/

// Assumes DetectResolutionChange was called immediately previous to this
function InitResources ()
{

	local LocalPlayer LP;
	local int i, j;

	local PostProcessChain PPChain;

	//m_kRT = TextureRenderTarget2D'epacePackage.1280720';

	FillResolutionStruct();

	// When running in PIE, the SceneView isn't initialized yet
	if( m_vBufferSize.X == 0.0 && m_vBufferSize.Y == 0.0 )
	{
		m_vBufferSize.X = 1280.0;
		 m_vBufferSize.Y = 720.0;
	}

	m_kRT = class'TextureRenderTarget2D'.static.Create(m_vBufferSize.X, m_vBufferSize.Y, PF_A16B16G16R16, MakeLinearColor(0.0, 0.0, 0.0, 0.0), false, true);
	m_kRT.Filter = TF_Nearest;
	m_kRT.SRGB=false;
	//m_kRT.CompressionNoMipmaps = true;
	m_kRT.bNeedsTwoCopies = false;

	m_kCamera = XComCamera( XComTacticalController(GetALocalPlayerController()).PlayerCamera );
	m_kPPChain = PostProcessChain'XComEngineMaterials.DefaultScenePostProcess';

	m_kCapturePrimary.RenderChannels.MainScene = false;
	m_kCapturePrimary.RenderChannels.RainCollisionDynamic = false;
	m_kCapturePrimary.RenderChannels.RainCollisionStatic = false;
	m_kCapturePrimary.RenderChannels.UnitVisibility = false;
	m_kCapturePrimary.RenderChannels.Occluded = true;
	m_kCapturePrimary.RenderChannels.Occluded2 = false;
	m_kCapturePrimary.ViewMode = SceneCapView_Depth;
	m_kCapturePrimary.ColorWriteMask = eCaptureWriteMask_RB;
	m_kCapturePrimary.bIsXComEdgeCapture = true;
	m_kCapturePrimary.RenderPriority = 0;
	m_kCapturePrimary.SetFrameRate(10000.0f);


	m_kCaptureSecondary.RenderChannels.MainScene = false;
	m_kCaptureSecondary.RenderChannels.RainCollisionDynamic = false;
	m_kCaptureSecondary.RenderChannels.RainCollisionStatic = false;
	m_kCaptureSecondary.RenderChannels.UnitVisibility = false;
	m_kCaptureSecondary.RenderChannels.Occluded = false;
	m_kCaptureSecondary.RenderChannels.Occluded2 = true;
	m_kCaptureSecondary.ViewMode = SceneCapView_Depth;
	m_kCaptureSecondary.ColorWriteMask = eCaptureWriteMask_GA;
	m_kCaptureSecondary.bForceNoClear = false;
	m_kCaptureSecondary.bForceNoResolve = true;
	m_kCaptureSecondary.bIsXComEdgeCapture = true;
	m_kCaptureSecondary.RenderPriority = -1;
	m_kCaptureSecondary.SetFrameRate(10000.0f);


	LP = LocalPlayer(GetALocalPlayerController().Player);
	for(i=0;i<LP.PlayerPostProcessChains.Length;i++)
	{
		PPChain = LP.PlayerPostProcessChains[i];
		for(j=0;j<PPChain.Effects.Length;j++)
		{
			if( XComEdgeEffect(PPChain.Effects[j]) != none )
			{
				m_kEdgeEffect = XComEdgeEffect(PPChain.Effects[j]);
			}
		}
	}

	if( m_kEdgeEffect != none )
	{
		m_kEdgeEffect.m_kEdgeTexture = m_kRT;
		m_kEdgeEffect.m_kLevelVolumePosition = `XWORLD.WorldBounds.Min;
		m_kEdgeEffect.m_kLevelVolumeDimensions.X = 1.0f / (`XWORLD.NumX * class'XComWorldData'.const.WORLD_StepSize);
		m_kEdgeEffect.m_kLevelVolumeDimensions.Y = 1.0f / (`XWORLD.NumY * class'XComWorldData'.const.WORLD_StepSize);
		m_kEdgeEffect.m_kLevelVolumeDimensions.Z = 1.0f / (`XWORLD.NumZ * class'XComWorldData'.const.WORLD_FloorHeight);
	}
}

function SetOutlineType( int OutlineType )
{
	//local MaterialInstanceConstant EdgeOneOutlineColor;
	//local MaterialInstanceConstant EdgeTwoOutlineColor;
	//local MaterialInstanceConstant EdgeOneOutlineNoOverlap;

	//EdgeOneOutlineColor =  MaterialInstanceConstant'FX_Visibility.M_Edge_OneOutline';
	//EdgeTwoOutlineColor =  MaterialInstanceConstant'FX_Visibility.M_Edge_TwoOutlines';
	//EdgeOneOutlineNoOverlap =  MaterialInstanceConstant'FX_Visibility.M_Edge_NoOverlap_OneOutline';

	//switch( OutlineType )
	//{
	//case 0:
	//	m_kEdgeEffect.Material = EdgeOneOutlineColor;
	//	break;
	//case 1:
	//	m_kEdgeEffect.Material = EdgeTwoOutlineColor;
	//	break;
	//default:
	//	m_kEdgeEffect.Material = EdgeOneOutlineNoOverlap;
	//	break;
	//}

	// Either of these work:
	//m_kMIC = MaterialInstanceConstant(m_kEdgeEffect.Material);

	//m_kMIC.GetTextureParameterValue('Texture', m_kOldTexture);
	//m_kMIC.SetTextureParameterValue('Texture', m_kRT); 
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	SubscribeToOnCleanupWorld();
}

simulated function PostBeginPlay()
{
	// Uncomment this to visualize the color depth buffer
	//AddHUDOverlayActor();
}

simulated function PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir)
{
	Canvas.SetPos(0, 0);
	Canvas.DrawTile(m_kRT, 200, 200, 0, 0, m_kRT.SizeX, m_kRT.SizeY);
}

function bool FillResolutionStruct()
{
	local ScriptSceneView kSceneView;
	local XComLocalPlayer kLocalPlayer;
	local XComTacticalController kTacticalController;
	
	kTacticalController = XComTacticalController(GetALocalPlayerController());
	if (kTacticalController == none)
		return false;

	kLocalPlayer = XComLocalPlayer(kTacticalController.Player);
	if (kLocalPlayer == none)
		return false;

	kSceneView = kLocalPlayer.SceneView;
	if (kSceneView == none)
		return false;

	m_vTargetSize.X = kSceneView.SizeX;
	m_vTargetSize.Y = kSceneView.SizeY;
	m_vBufferSize.X = kSceneView.BackBufferSizeX;
	m_vBufferSize.Y = kSceneView.BackBufferSizeY;

	return true;
}

function bool DetectResolutionChange()
{
	FillResolutionStruct();

	// Info has not been filled out yet, don't try to recreate the buffer.
	if( m_kCapturePrimary.TargetWidth == 0 || m_kCapturePrimary.TargetHeight == 0 )
	{
		return false;
	}

	if( m_kCapturePrimary.TargetWidth*m_nDownsampleFactor != m_vTargetSize.X || m_kCapturePrimary.TargetHeight*m_nDownsampleFactor != m_vTargetSize.Y || m_kRT.SizeX != m_vBufferSize.X || m_kRT.SizeY != m_vBufferSize.Y )
	{
		return true;
	}

	return false;
}


function Tick (float DeltaTime)
{
	local float AdjustedFOV;
	local bool bResolutionChanged;
	local bool bMapRequiresDownsampledOutlineDepth;
	local bool bShouldRenderDownsampledDepth;
	local bool bPreviousTargeting;
	local WorldInfo WI;

	bMapRequiresDownsampledOutlineDepth = FALSE;

	WI = Class'WorldInfo'.static.GetWorldInfo();

	if (WI != none)
	{
		bMapRequiresDownsampledOutlineDepth = WI.UseDownsampledOutlineDepth;
	}

	super.Tick(DeltaTime);

	m_kCamera = XComCamera(XComTacticalController(GetALocalPlayerController()).PlayerCamera);

	if (m_kCamera != none && m_kRT !=none && m_kEdgeEffect != none )
	{
		bResolutionChanged = DetectResolutionChange();

		if( bResolutionChanged )
			InitResources();

		bPreviousTargeting = m_kEdgeEffect.m_bTargeting;
		if( `CAMERASTACK.ShowTargetingOutlines() )
		{
			m_kEdgeEffect.m_kOutlineColor = m_3POutlineColor;
			m_kEdgeEffect.m_bTargeting = true;
		}
		else
		{
			m_kEdgeEffect.m_kOutlineColor = m_BuildingOutlineColor;
			m_kEdgeEffect.m_bTargeting = false;
		}

		if( bPreviousTargeting != m_kEdgeEffect.m_bTargeting )
			OnUpdateThirdPersonMode();

		// Figure out if we should be using a downsampled version of outline/cutout depth
		if( !m_kEdgeEffect.m_bTargeting && bMapRequiresDownsampledOutlineDepth )
		{
			bShouldRenderDownsampledDepth = TRUE;
		}
		else
		{
			bShouldRenderDownsampledDepth = FALSE;
		}

		SetLocation(m_kCamera.CameraCache.POV.Location);
		SetRotation(m_kCamera.CameraCache.POV.Rotation);

		// Set the downsample factor on the postprocess effect
		m_nDownsampleFactor = bShouldRenderDownsampledDepth ? 2 : 1;
		m_kEdgeEffect.m_nDownsampleFactor = m_nDownsampleFactor;

		// FOV is our desired FOV for the width of a 16:9 monitor.
		AdjustedFOV = m_kCamera.CameraCache.POV.FOV;

		if( m_kCamera.bConstrainAspectRatio )
		{
			m_kCapturePrimary.SetCaptureParameters(m_kRT, AdjustedFOV, 1.0f, 10000.0f,,,0,0,m_vTargetSize.X/m_nDownsampleFactor, m_vTargetSize.Y/m_nDownsampleFactor, LocalPlayer(GetALocalPlayerController().Player).AspectRatioAxisConstraint, m_kCamera.ConstrainedAspectRatio );
			m_kCaptureSecondary.SetCaptureParameters(m_kRT, AdjustedFOV, 1.0f, 10000.0f, , , 0, 0, m_vTargetSize.X / m_nDownsampleFactor, m_vTargetSize.Y / m_nDownsampleFactor, LocalPlayer(GetALocalPlayerController().Player).AspectRatioAxisConstraint, m_kCamera.ConstrainedAspectRatio);
		}
		else
		{
			m_kCapturePrimary.SetCaptureParameters(m_kRT, AdjustedFOV, 1.0f, 10000.0f, , , 0, 0, m_vTargetSize.X / m_nDownsampleFactor, m_vTargetSize.Y / m_nDownsampleFactor, LocalPlayer(GetALocalPlayerController().Player).AspectRatioAxisConstraint, 0);
			m_kCaptureSecondary.SetCaptureParameters(m_kRT, AdjustedFOV, 1.0f, 10000.0f, , , 0, 0, m_vTargetSize.X / m_nDownsampleFactor, m_vTargetSize.Y / m_nDownsampleFactor, LocalPlayer(GetALocalPlayerController().Player).AspectRatioAxisConstraint, 0);
		}

		m_fPrevFOV = m_kCamera.CameraCache.POV.FOV;

		if(m_kEdgeEffect != none)
		{
			m_kEdgeEffect.m_kMaxSceneDepth = (m_kCapturePrimary.ProjMatrix.ZPlane.Z*-1.0f)/(1.0f-m_kCapturePrimary.ProjMatrix.ZPlane.Z);	
		}

		DetachComponent(m_kCaptureSecondary);
		AttachComponent(m_kCaptureSecondary);

		DetachComponent(m_kCapturePrimary);
		AttachComponent(m_kCapturePrimary);
	}
}

// Updates UI changes specific to third person targeting. Since targeting leaves most of the UI intact,
// we need to special handle just the bits we want
simulated function OnUpdateThirdPersonMode()
{
	local XGUnit Unit;

	if( `CAMERASTACK.ShowTargetingOutlines() )
	{		
		foreach AllActors( class'XGUnit', Unit )
		{
			if( Unit.m_kDiscMesh != none )
				Unit.m_kDiscMesh.SetHidden(TRUE);
		}
	}
	else 
	{
		foreach AllActors( class'XGUnit', Unit )
		{
			Unit.RefreshUnitDisc();
		}
	}
}


simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
	RemoveReferences();
}

function RemoveReferences ()
{
	if (m_kMIC != none)
		m_kMIC.SetTextureParameterValue('Texture', m_kOldTexture);
}

defaultproperties
{
	Begin Object Class=SceneCapture2DComponent Name=SceneCapture2DComponent0
		ColorWriteMask=eCaptureWriteMask_RB
		ClearColor = (R = 0, G = 0, B = 0, A = 0)
		bForceNoClear=true;
	End Object
	Begin Object Class=SceneCapture2DComponent Name=SceneCapture2DComponent1
		ColorWriteMask=eCaptureWriteMask_GA
		ClearColor=(R=0,G=0,B=0,A=0)
		bForceNoResolve=true;
	End Object

	TickGroup=TG_PostUpdateWork
	m_fPrevFOV=-1.0
	m_kCapturePrimary=SceneCapture2DComponent0	
	m_kCaptureSecondary=SceneCapture2DComponent1

	Components.Add(SceneCapture2DComponent1)
	Components.Add(SceneCapture2DComponent0)

	m_BuildingOutlineColor=(R=0.99,G=0.95,B=0.79,A=1.0)
	//m_BuildingOutlineColor=(R=0.404,G=0.909,B=0.929,A=1.0)
	//m_3POutlineColor=(R=0.933,G=0.109,B=0.145,A=1.0)
	m_3POutlineColor=(R=1,G=0.0,B=0.0,A=1.0)

	m_nDownsampleFactor=2
}
