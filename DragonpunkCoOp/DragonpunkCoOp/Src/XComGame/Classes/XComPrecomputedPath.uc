class XComPrecomputedPath extends Actor
		native(Weapon)
		config(GameCore);

const MAXPRECOMPUTEDPATHKEYFRAMES    = 128;     
const MAX_CB_OFFSET = 192.0f;

struct native XKeyframe
{
	var float   fTime;
	var Vector  vLoc;
	var Rotator rRot;
	var bool bValid;
};

// blaster bomb configs
var bool                          m_bBlasterBomb;
var config float                  BlasterBombSpeed;
var config array<ETraversalType>  BlasterBombTraversals;
var private const config float BlasterBombMaxCost; // in meters

var XKeyframe                     akKeyframes[MAXPRECOMPUTEDPATHKEYFRAMES];
var int                           iNumKeyframes;
var bool                          bAllValidKeyframeDataReplicated;
var int                           iLastExtractedKeyframe;
var InterpCurveVector	          kSplineInfo;
var float                         fEmitterTimeStep;
var XComWeapon                    kCurrentWeapon;
var array<ProjectileTouchEvent>	  TouchEvents; //Built as the grenade creates its trajectory. Picked up later and stored in a result context.

//This class is in transition - it is used by both the UI and the X2 visualizer system which 
//have competing ideas on where the target is. This boolean + vector combination is used by the
//visualizer system
var bool                          bUseOverrideTargetLocation;
var vector                        OverrideTargetLocation;

var bool						  bUseOverrideSourceLocation;
var vector						  OverrideSourceLocation;

var XComRenderablePathComponent   kRenderablePath;
var const string                  PathingRibbonMaterialName;
var bool                          bSplineDirty;

var repnotify ETeam               eComputePathForTeam;
var bool                          bOnlyDrawIfFriendlyToLocalPlayer;
var bool                          m_bValid;
var float                         m_fTime;
var bool						  bNoSpinUntilBounce;

var PrecomputedPathData           m_WeaponPrecomputedPathData;

var bool						  m_bIsUnderhandToss;

var bool						  bOverrideSourceTargetFromSocketLocation;
var Name						  m_SocketNameForSourceLocation;

// keep track of the last targeted location, so we don't keep updating if the target doesn't change
var vector LastTargetLocation;

native simulated function UpdateWeaponProjectilePhysics(XComWeapon kWeapon, float dT);
native simulated function BuildSpline();
native simulated function SetEmitterTimeStep(float fTimeStep);
native simulated function CalculateBlasterBombTrajectoryToTarget();

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	kRenderablePath = new class'XComRenderablePathComponent';	
	kRenderablePath.iPathLengthOffset = -2;
	kRenderablePath.fEmitterTimeStep = fEmitterTimeStep;
	kRenderablePath.fRibbonWidth = 1.25f;
	kRenderablePath.bTranslucentIgnoreFOW = true;
	kRenderablePath.PathType = eCU_NoConcealment;

	kRenderablePath.SetMaterial(Material(DynamicLoadObject(PathingRibbonMaterialName,class'Material')));
	kRenderablePath.SetHidden(TRUE);

	AttachComponent(kRenderablePath);
}

simulated function string ToString()
{
	local string strRep;
	local int i;

	strRep = self @ `ShowVar(iNumKeyframes) $ "\n";
	for(i = 0; i < iNumKeyframes; i++)
	{
		strRep $= "     akKeyframes["$i$"]=" $ akKeyframes[i].vLoc @ akKeyframes[i].rRot @ akKeyframes[i].fTime @ akKeyframes[i].bValid $ "\n";
	}
	strRep $= "\n";

	return strRep;
}

// Enables this actor's tick function which begins drawing the path
simulated function ActivatePath(XComWeapon kWeapon, ETeam eForTeam, const out PrecomputedPathData PrePathData)
{
	bOverrideSourceTargetFromSocketLocation = false;
	bUseOverrideSourceLocation = false;
	SetupPath(kWeapon, eForTeam, PrePathData);
	kRenderablePath.SetHidden(FALSE);
	LastTargetLocation.Z = -1000; // force a rebuild of the grenade path
}

simulated function SetupPath(XComWeapon kWeapon, ETeam eForTeam, const out PrecomputedPathData PrePathData)
{
	eComputePathForTeam = eForTeam;
	kCurrentWeapon = kWeapon;
	m_WeaponPrecomputedPathData = PrePathData;
}

simulated function vector GetEndPosition()
{
	assert(iNumKeyFrames > 0);
	return akKeyframes[iNumKeyframes-1].vLoc;
}

simulated function float GetEndTime()
{
	assert(iNumKeyFrames > 0);
	return akKeyframes[iNumKeyframes-1].fTime;
}

simulated function SetWeaponAndTargetLocation(XComWeapon kWeapon, ETeam eForTeam, vector TargetLocation, const out PrecomputedPathData PrePathData)
{
	eComputePathForTeam = eForTeam;
	kCurrentWeapon = kWeapon;
	bUseOverrideTargetLocation = true;
	OverrideTargetLocation = TargetLocation;

	m_WeaponPrecomputedPathData = PrePathData;
}

function ClearOverrideTargetLocation()
{
	bUseOverrideTargetLocation = false;
}

//Enable projectile to start from given socket name
simulated function SetFiringFromSocketPosition(Name SocketName)
{
	m_SocketNameForSourceLocation = SocketName;
	bOverrideSourceTargetFromSocketLocation = true;
	bUseOverrideSourceLocation = true;
}

// Extract an interpolated keyframe 
simulated function XKeyframe ExtractInterpolatedKeyframe(float fTime)
{
	local int           iKeyframeA;
	local int           iKeyframeB;
	local XKeyframe     KeyframeResult;
	local float         fInterpAmt;
	local float         fTimeDelta;

	iLastExtractedKeyframe = 0;
	while (akKeyframes[iLastExtractedKeyframe].fTime < fTime && iLastExtractedKeyframe < iNumKeyframes)
		iLastExtractedKeyframe += 1;

	if (iLastExtractedKeyframe == 0)
	{
		KeyframeResult.fTime = akKeyframes[iLastExtractedKeyframe].fTime; 
		KeyframeResult.vLoc = akKeyframes[iLastExtractedKeyframe].vLoc; 
		KeyframeResult.rRot = akKeyframes[iLastExtractedKeyframe].rRot;
		return KeyframeResult;
	}

	if (iLastExtractedKeyframe >= iNumKeyframes)
	{
		KeyframeResult.fTime = akKeyframes[iNumKeyframes-1].fTime; 
		KeyframeResult.vLoc = akKeyframes[iNumKeyframes-1].vLoc; 
		KeyframeResult.rRot = akKeyframes[iNumKeyframes-1].rRot;
		return KeyframeResult;
	}

	iKeyframeA = iLastExtractedKeyframe-1;
	iKeyframeB = iLastExtractedKeyframe;

	fTimeDelta = (akKeyframes[iKeyframeB].fTime - akKeyframes[iKeyframeA].fTime);
	fInterpAmt = (fTime - akKeyframes[iKeyframeA].fTime)/(fTimeDelta != 0.0 ? fTimeDelta : 1.0);

	KeyframeResult.fTime = fTime;
	KeyframeResult.vLoc = VLerp(akKeyframes[iKeyframeA].vLoc, akKeyframes[iKeyframeB].vLoc, fInterpAmt);
	KeyframeResult.rRot = RLerp(akKeyframes[iKeyframeA].rRot, akKeyframes[iKeyframeB].rRot, fInterpAmt);

	return KeyframeResult;

}

// returns whether we have finished moving along the path
simulated function bool MoveAlongPath(float fTime, Actor pActor)
{
	local XKeyframe KF;

	KF = ExtractInterpolatedKeyframe(fTime);

	pActor.SetLocation(KF.vLoc);
	pActor.SetRotation(KF.rRot);

	if (fTime >= akKeyframes[iNumKeyframes-1].fTime)
		return true;
	else return false;

}

// Clear the path graphics
simulated function ClearPathGraphics()
{
	kRenderablePath.SetHidden(TRUE);
}

simulated function DrawPath()
{
	if(!bOnlyDrawIfFriendlyToLocalPlayer 
		|| GetALocalPlayerController().IsTeamFriendly(eComputePathForTeam)
		|| XComTacticalCheatManager(GetALocalPlayerController().CheatManager).bForceGrenade)
	{
		BuildSpline();
	}
}

simulated function UpdateTrajectory()
{
	local Rotator MuzzleRotation; //unused, can be taken out if needed
	//Start trajectory from socket location, by SetFiringFromSocketPosition Chang You Wong 2015-6-8
	if(bOverrideSourceTargetFromSocketLocation)
	{
		SkeletalMeshComponent(kCurrentWeapon.Mesh).GetSocketWorldLocationAndRotation(m_SocketNameForSourceLocation, OverrideSourceLocation, MuzzleRotation);
	}
	CalculateTrajectoryToTarget(m_WeaponPrecomputedPathData);
}

simulated event Tick(float DeltaTime)
{	
	local float PathLength;

	if(kRenderablePath.HiddenGame)
	{
		return;
	}
	if (m_bBlasterBomb)
	{
		CalculateBlasterBombTrajectoryToTarget();
	}
	else
	{
		UpdateTrajectory();
	}

	DrawPath();

	if( bSplineDirty || true)
	{
		PathLength = akKeyframes[iNumKeyframes - 1].fTime - akKeyframes[0].fTime;
		kRenderablePath.UpdatePathRenderData(kSplineInfo,PathLength,none,`CAMERASTACK.GetCameraLocationAndOrientation().Location);
		bSplineDirty = FALSE;
	}
}

simulated native function CalculateTrajectoryToTarget(PrecomputedPathData PrePathData);

cpptext
{
	UBOOL IterateBuildTrajectory(const FVector &CurrentLocation, const FVector &TargetLocation, const FPrecomputedPathData &WeaponPrecomputedPath);
};


defaultproperties
{
	fEmitterTimeStep = 0.03

	//RemoteRole=ROLE_SimulatedProxy
	//bAlwaysRelevant=true
	RemoteRole = ROLE_None
	bAlwaysRelevant = false

	bUseOverrideSourceLocation = false

	bOnlyDrawIfFriendlyToLocalPlayer = true
	eComputePathForTeam = eTeam_None

	iNumKeyframes = -1

	PathingRibbonMaterialName = "UI_3D.CursorSet.CursorRibbon"

	bSplineDirty = FALSE
	m_bIsUnderhandToss = false
}

