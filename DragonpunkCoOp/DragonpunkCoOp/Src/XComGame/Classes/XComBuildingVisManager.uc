// stores information about the bounds this xcom pawn is inside/outside of

class XComBuildingVisManager extends Actor
	dependson(X2Camera)
	native(Level);

/*************** Floor Hiding Variables ***************/

struct native IndoorOutdoorInfo
{
	var vector vFocusPoint;
	var XComBuildingVolume kBuildingVolume;
	var int iLowerFloorToReveal;
};

struct native FloorReveals
{
	var int iLowerFloor;
};

var array<TFocusPoints> m_aFocusPoints;
var array<Actor> FocusActors;

var native Map{AXComBuildingVolume*, FFloorReveals} CurrentLevelReveals;

/*************** Trace Variables ***************/

// These arrays are for the XTraceAndHideXComHideableFlaggedLevelActors function,
var array<Actor> m_aHiddenActors;

// This is the number of elements in m_aHiddenActors that are not NULL.
var int m_iNumberOfHiddenActors;

var bool m_bPrimaryFocusOn;

/*************** CutoutBox Variables ***************/

var array<Actor> m_aHiddenCutoutActors;

var int m_iNumberOfHiddenCutoutActors;

var float m_fPrimaryTraceExtents;
var float m_fSecondaryTraceExtents;

/*************** Periphery Hiding Variables ***************/

var bool m_bPeripheryInitialized;
var array<XComPeripheryHidingVolume> m_aPeripheryVolumes;

/*************** Enable Flags ***************/

var bool m_bEnableBuildingVisibility;
var bool m_bEnableCutoutBox;
var bool m_bEnablePeripheryHiding;

var vector m_vCameraLocation;
var vector m_vCutoutBoxLocation;

var bool m_bIsHidingCinematicLayer;

cpptext
{
	virtual void TickSpecial(FLOAT DeltaTime);

	void CheckFloorsToHide();
	void LevelVolumeTraceForUnit(struct FIndoorOutdoorInfo& Unit, const FVector& vCameraLocation);

	void MouseObscuringActorHiding();

	void CutoutBoxHiding();
}

simulated event PreBeginPlay()
{
	Super.PreBeginPlay();

	m_aHiddenActors.Insert(0, 32);
}

event bool GetDataFromScript(float DeltaTime)
{
	local array<TFocusPoints> OldFocusPoints;
	local XComTacticalCheatManager TCM;
	local XComTacticalController TacticalController;
	local X2CameraStack CameraStack;
	local XComWorldData WorldData;
	local bool CameraAllowsCutdown;
	local int i, OldFocusIndex;
	local vector FocusPoint;
	local TPOV CameraPOV;
	local vector CameraDir;
	local bool bHideCinematicLayer;
	local float CinematicLayerAngle;
	local float fFloorZ;
	local bool bDisableFocusPointExpiration;
	local TFocusPoints ActorFocusPoint;

	WorldData = `XWORLD;

	OldFocusPoints = m_aFocusPoints;
	m_aFocusPoints.Remove(0, m_aFocusPoints.Length);

	m_bEnableBuildingVisibility = false;
	m_bEnableCutoutBox = false;
	m_bEnablePeripheryHiding = false;

	// Throws accessed nones!
	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	if (TacticalController == none || TacticalController.PlayerCamera == none )
		return false;

	CameraStack = `CAMERASTACK;

	if( CameraStack == none )
		return false;

	CameraAllowsCutdown = CameraStack.AllowBuildingCutdown();

	TCM = XComTacticalCheatManager(TacticalController.CheatManager);
	if( TCM != none )
	{
		m_bEnableBuildingVisibility = TCM.m_bEnableBuildingVisibility_Cheat && CameraAllowsCutdown;
		m_bEnableCutoutBox = TCM.m_bEnableCutoutBox_Cheat && CameraAllowsCutdown;
		m_bEnablePeripheryHiding = TCM.m_bEnablePeripheryHiding_Cheat && CameraAllowsCutdown;
	}
	else
	{
		m_bEnableBuildingVisibility = CameraAllowsCutdown;
		m_bEnableCutoutBox = CameraAllowsCutdown;
		m_bEnablePeripheryHiding = CameraAllowsCutdown;
	}	

	CameraPOV = CameraStack.GetCameraLocationAndOrientation();
	CameraDir = vector(CameraPOV.Rotation);
	m_vCameraLocation = CameraPOV.Location;

	CameraStack.GetCameraFocusPoints(m_aFocusPoints);
	m_bPrimaryFocusOn = CameraStack.GetCameraIsPrimaryFocusOn();

	for (i = 0; i < FocusActors.Length; i++)
	{
		ActorFocusPoint.vFocusPoint = FocusActors[i].Location;
		ActorFocusPoint.vCameraLocation = ActorFocusPoint.vFocusPoint - (CameraDir * 9999.0f);
		ActorFocusPoint.fCutoutHeightLimit = 0.0;
		ActorFocusPoint.fDelay = 0.0;

		// this focus point needs to be at the front of the array for highest priority
		m_aFocusPoints.InsertItem(0, ActorFocusPoint);
	}

	for (i = 0; i < m_aFocusPoints.Length; i++)
	{
		if (WorldData != none)
		{
			FocusPoint = m_aFocusPoints[i].vFocusPoint;
			//Ensure Focus Points are at least 64 units off the floor.
			fFloorZ = WorldData.GetFloorZForPosition(FocusPoint, false);
			fFloorZ = fFloorZ + 75.0;
			m_aFocusPoints[i].fCutoutHeightLimit = fFloorZ;
		}
		else
		{
			m_aFocusPoints[i].fCutoutHeightLimit = 0;
		}

		for (OldFocusIndex = 0; OldFocusIndex < OldFocusPoints.Length; OldFocusIndex++)
		{
			if (VSizeSq(m_aFocusPoints[i].vFocusPoint - OldFocusPoints[OldFocusIndex].vFocusPoint) < 25.0f // 5 Units
				&& VSizeSq(m_aFocusPoints[i].vCameraLocation - OldFocusPoints[OldFocusIndex].vCameraLocation) < 25.0f)
			{
				OldFocusPoints.Remove(OldFocusIndex, 1);
				break;
			}
		}
	}

	bDisableFocusPointExpiration = CameraStack.DisableFocusPointExpiration();
	for (i = 0; i < OldFocusPoints.Length; i++)
	{
		OldFocusPoints[i].fDelay -= DeltaTime;
		if (OldFocusPoints[i].fDelay > 0.0 || bDisableFocusPointExpiration)
			m_aFocusPoints.AddItem(OldFocusPoints[i]);
	}

	if (TCM != none && TCM.m_bShowPOILocations_Cheat)
	{
		for (i = 0; i < m_aFocusPoints.Length; i++)
		{
			`SHAPEMGR.DrawSphere(m_aFocusPoints[i].vFocusPoint, vect(25, 25, 25), MakeLinearColor(1, 0, 0, 1));
		}
	}

	CinematicLayerAngle = 55.0 / 180.0 * PI;
	bHideCinematicLayer = Acos(CameraDir dot vect(0, 0, -1)) < CinematicLayerAngle;
	if( bHideCinematicLayer != m_bIsHidingCinematicLayer )
	{
		m_bIsHidingCinematicLayer = bHideCinematicLayer;
		ToggleCinematicLayerVisibility(m_bIsHidingCinematicLayer);
	}

	return true;	
}

simulated function ToggleCinematicLayerVisibility(bool bHideLayer)
{
	local XComLevelActor LevelActor;

	foreach AllActors(class'XComLevelActor', LevelActor)
	{
		if( LevelActor.bHideInNonCinematicViews )
		{
			LevelActor.SetHidden(bHideLayer);
		}
	}
}

function AddFocusActorViaKismet(Actor FocusActor)
{
	FocusActors.AddItem(FocusActor);
}

function RemoveFocusActorViaKismet(Actor FocusActor)
{
	local int i;

	for (i = 0; i < FocusActors.Length; i++)
	{
		if (FocusActors[i] == FocusActor)
		{
			FocusActors.Remove(i, 1);
			break;
		}
	}
}

defaultproperties
{
	m_iNumberOfHiddenActors=0
	m_fPrimaryTraceExtents = 48
	m_fSecondaryTraceExtents = 0

	m_bEnableBuildingVisibility=true
	m_bEnableCutoutBox=true
	m_bEnablePeripheryHiding=true

	m_bIsHidingCinematicLayer=false

	m_bPeripheryInitialized=false
}