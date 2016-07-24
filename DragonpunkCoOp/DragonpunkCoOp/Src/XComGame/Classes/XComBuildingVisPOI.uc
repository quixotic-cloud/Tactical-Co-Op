//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComBuildingVisPOI.uc
//  AUTHOR:  Jeremy Shopf 3/19/2012
//  PURPOSE: This actor encapsulates the 'point of interest' to the Building Visibility 
//				system. This used to be XCom3DCursor but the cursor has many other
//				conflicting responsibilities
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComBuildingVisPOI extends StaticMeshActor 
	native
	implements(IXComBuildingVisInterface);

//var StaticMeshComponent VisualizerMesh;
var	CylinderComponent	CylinderComponent;
var XComPawnIndoorOutdoorInfo IndoorInfo;
var XComPawnIndoorOutdoorInfo LevelTraceIndoorInfo;         // MHU - Utilized for additional Level building visibility processing
var int m_iNumLevelTraceCurrentFloorVolumes;

simulated native function TickNative(float fDeltaTime);

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	IndoorInfo = new(Self) class'XComPawnIndoorOutdoorInfo';
	IndoorInfo.BuildingVisActor = self;

	LevelTraceIndoorInfo = new(Self) class'XComPawnIndoorOutdoorInfo';
	// Should set LevelTraceIndoorInfo.BuildingVisActor here?
	LevelTraceIndoorInfo.CurrentFloorVolumes.Insert(0,16);
}

simulated function DebugVis( Canvas kCanvas, XComCheatManager kCheatManager )
{
	local Vector vScreenPos;
	local XComFloorVolume FloorVolume;
	local int i;
	local float savedX;

	if( kCheatManager.m_bDebugVis )
	{
		vScreenPos = kCanvas.Project(Location+vect(0,0,64));

		// poi often overlaps a unit, push it away
		vScreenPos.Y -= 100;
		vScreenPos.X += 100;

		kCanvas.SetDrawColor(255,255,255);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText(self.Name);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Location:"@Location);

		// Building volume
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Building:" @ self.IndoorInfo.CurrentBuildingVolume );

		// Floor volumes
		savedX = vScreenPos.X;
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Floor Volumes: "  );
		for( i=0; i<self.IndoorInfo.CurrentFloorVolumes.Length; i++ )
		{
			FloorVolume = self.IndoorInfo.CurrentFloorVolumes[i];
			kCanvas.SetPos(savedX += 100, vScreenPos.Y);
			kCanvas.DrawText( " " @ FloorVolume);
		}


		// Current floor
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Current Floor:" @ self.IndoorInfo.GetCurrentFloorNumber() );

		// Inside ?
		// 
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Inside? "@self.IndoorInfo.IsInside());

	}
}

simulated event Tick(float fDeltaTime)
{
	local array<TFocusPoints> FocusPoints;
	TickNative(fDeltaTime);

	`CAMERASTACK.GetCameraFocusPoints(FocusPoints);

	`assert(FocusPoints.Length > 0);

	SetLocation(FocusPoints[0].vFocusPoint);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	super.Touch(Other, OtherComp, HitLocation, HitNormal);

	IndoorInfo.ParentTouchedOrUntouched(Other, true);
}

event UnTouch( Actor Other )
{
	super.UnTouch(Other);

	IndoorInfo.ParentTouchedOrUntouched(Other, false);
}

// IXComBuildingVisInterface
// ===============================================================
function Actor GetActor()
{
	return self;
}

function XComPawnIndoorOutdoorInfo GetIndoorOutdoorInfo()
{
	return IndoorInfo;
}

event XComBuildingVolume GetCurrentBuildingVolumeIfInside()
{
	if (IndoorInfo.IsInside())
		return IndoorInfo.CurrentBuildingVolume;
	return none;
}

event bool IsInside()
{
	return IndoorInfo.IsInside();
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local Vector vScreenPos;
	local XCom3DCursor kCursor;
	local Vector CursorLoc;
	local XComTacticalController kTacticalController;

`if(`notdefined(FINAL_RELEASE))
	local XComCheatManager kCheatManager;
`endif

	vScreenPos.X = kCanvas.ClipX * 0.45;
	vScreenPos.Y = kCanvas.ClipY * 0.65;

	// Set position of the POI based on the cursor and camera manager
	kTacticalController = XComTacticalController(GetALocalPlayerController());
	kCursor = XCom3DCursor(kTacticalController.Pawn);

	kCanvas.SetDrawColor(255,0,0);

	vScreenPos.Y += 15.0f;
	if( false ) //`CAMERAMGR.ShouldControlVisibility() )
	{
		kCanvas.SetPos(vScreenPos.X,vScreenPos.Y);
		//kCanvas.DrawText("CAMERA POI: " @ `CAMERAMGR.m_kVisibilityLoc.X @ " " @ `CAMERAMGR.m_kVisibilityLoc.Y @ " " @ `CAMERAMGR.m_kVisibilityLoc.Z );

	}
	else if( kCursor != none )
	{
		kCanvas.SetPos(vScreenPos.X,vScreenPos.Y);

		CursorLoc = kCursor.Location;
		CursorLoc.Z = CursorLoc.Z - kCursor.GetCollisionHeight();

		kCanvas.DrawText("CURSOR POI: " @ CursorLoc.X @ " " @ CursorLoc.Y @ " " @ CursorLoc.Z );
	}

	vScreenPos.Y += 15.0f;
	kCanvas.SetPos(vScreenPos.X,vScreenPos.Y);

`if (`notdefined(FINAL_RELEASE))

	super.PostRenderFor(kPC, kCanvas, vCameraPosition, vCameraDir);

	kCheatManager = XComCheatManager( kTacticalController.CheatManager );

	if (kCheatManager != none)
	{
		DebugVis(kCanvas, kCheatManager);
	}
`endif


}


defaultproperties
{
	bStatic=FALSE
	bWorldGeometry=FALSE
	bMovable=TRUE

	// The POI is frequently following a unit so we want to match the unit's collision
	Begin Object Class=CylinderComponent Name=UnitCollisionCylinder
		CollisionRadius=14.000000
		//CollisionHeight is decided in PostBeginPlay
		CollisionHeight=64.0
		BlockNonZeroExtent=true
		BlockZeroExtent=false       // Zero extent traces should not be enabled on the collision cylinder, we use the physics asset for those. - Casey
		BlockActors=true
		CollideActors=true
		BlockRigidBody=true
		RBChannel=RBCC_Pawn
		RBCollideWithChannels=(Default=True,Pawn=False,Vehicle=True,Water=True,GameplayPhysics=True,EffectPhysics=True,Untitled1=True,Untitled2=True,Untitled3=True,Untitled4=True,Cloth=True,FluidDrain=True,SoftBody=True,FracturedMeshPart=False,BlockingVolume=True,DeadPawn=True)
		CanBlockCamera=TRUE
		HiddenGame=FALSE
	End Object
	CollisionComponent=UnitCollisionCylinder
	CylinderComponent=UnitCollisionCylinder
	Components.Add(UnitCollisionCylinder)
	//VisualizerMesh=UnitCollisionCylinder

	CollisionType=COLLIDE_TouchAll
	bCollideActors=TRUE
	bBlockActors=FALSE
	BlockRigidBody=FALSE
	bHidden=FALSE

	TickGroup=TG_PreAsyncWork

	m_iNumLevelTraceCurrentFloorVolumes = 0;
}
